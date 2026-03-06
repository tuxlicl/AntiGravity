$ErrorActionPreference = "Stop"

Write-Host "======================================================"
Write-Host "1. PREPARANDO ENTORNO, MODULOS Y LIMPIANDO CACHE ROTA"
Write-Host "======================================================"

if (!(Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host "Detectado Modulo Azure (Az.Accounts) faltante. Instalando (puede tardar un minuto)..."
    Install-Module -Name Az.Accounts -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
}
Import-Module Az.Accounts

Write-Host "Limpiando cache MSAL corrupta en macOS (Bug de Object Reference)..."
if (Test-Path "$HOME/.mg") { Remove-Item -Path "$HOME/.mg" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "$HOME/.IdentityService") { Remove-Item -Path "$HOME/.IdentityService" -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "======================================================"
Write-Host "2. AUTENTICACION (Se requerira Device Code 3 veces)"
Write-Host "======================================================"
Write-Host "Autenticando en Microsoft Graph (Entra ID)..."
# Descartando sesiones previas si las hay
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -UseDeviceAuthentication -Scopes "User.Read.All", "Group.Read.All", "AuditLog.Read.All", "Policy.Read.All", "RoleManagement.Read.Directory", "SecurityEvents.Read.All", "DeviceManagementConfiguration.Read.All", "Organization.Read.All"

Write-Host ""
Write-Host "Autenticando en Exchange Online..."
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Connect-ExchangeOnline -Device

Write-Host ""
Write-Host "Autenticando en Azure..."
Disconnect-AzAccount -ErrorAction SilentlyContinue
Connect-AzAccount -UseDeviceAuthentication

Write-Host "======================================================"
Write-Host "3. EXTRACCION DE DATOS"
Write-Host "======================================================"
$ReportPath = "/Users/claudio/Antigravity/m365_azure_report.md"
"## Microsoft 365 Architecture & Identity Export" > $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Tenant & Domains..."
"### 1. Tenant Overview" >> $ReportPath
$org = Get-MgOrganization | Select-Object Id, DisplayName, TenantType, CountryLetterCode
"**Tenant ID:** $($org.Id)" >> $ReportPath
"**Name:** $($org.DisplayName)" >> $ReportPath
"**Country:** $($org.CountryLetterCode)" >> $ReportPath
"" >> $ReportPath
"**Domains:**" >> $ReportPath
Get-MgDomain | ForEach-Object { "- $($_.Id) (Verified: $($_.IsVerified), Default: $($_.IsDefault))" } >> $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Usuarios..."
"### 2. Identity Inventory (Users)" >> $ReportPath
$allUsers = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, UserType
$guestCount = ($allUsers | Where-Object { $_.UserType -eq 'Guest' }).Count
$enabledCount = ($allUsers | Where-Object { $_.AccountEnabled -eq $true }).Count
"- Total Users: $($allUsers.Count)" >> $ReportPath
"- Active Users: $enabledCount" >> $ReportPath
"- Guest Users: $guestCount" >> $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Roles de Administrador Global..."
"### 3. Administrative Roles (Global Admins)" >> $ReportPath
$roles = Get-MgDirectoryRole -All
$gaRole = $roles | Where-Object { $_.RoleTemplateId -eq "62e90394-69f5-4237-9190-012177145e10" }
if ($gaRole) {
    try {
        $gaMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id
        foreach ($m in $gaMembers) {
            $u = Get-MgUser -UserId $m.Id -ErrorAction SilentlyContinue
            if ($u) { "- $($u.DisplayName) ($($u.UserPrincipalName))" >> $ReportPath }
        }
    }
    catch { "- Lacking permissions to read role members" >> $ReportPath }
}
"" >> $ReportPath

Write-Host "-> Extrayendo Aplicaciones y Service Principals..."
"### 4. Registered Applications" >> $ReportPath
$apps = Get-MgApplication -Top 500
"- Total App Registrations: $($apps.Count)" >> $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Politicas de Acceso Condicional..."
"### 5. Conditional Access Policies" >> $ReportPath
try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -All
    if ($caPolicies.Count -gt 0) {
        foreach ($p in $caPolicies) {
            "- **$($p.DisplayName)** (State: $($p.State))" >> $ReportPath
        }
    }
    else {
        "- No policies found." >> $ReportPath
    }
}
catch {
    "- Lacking permissions or Premium P1/P2 license to read CA policies." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo Exchange Online..."
"### 6. Exchange Online Configurations" >> $ReportPath
try {
    $domains = Get-AcceptedDomain
    "- Accepted Domains: $(($domains | Select-Object -ExpandProperty Name) -join ', ')" >> $ReportPath
    $rules = Get-TransportRule
    "- Transport Rules Count: $($rules.Count)" >> $ReportPath
    
    $outbound = Get-HostedOutboundSpamFilterPolicy
    "- Outbound Spam Policies: $($outbound.Count)" >> $ReportPath
    
    $antiPhish = Get-AntiPhishPolicy
    "- Anti-Phish Policies: $($antiPhish.Count)" >> $ReportPath
}
catch {
    "- Could not read Exchange properties." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo Azure Governance..."
"### 7. Azure Subscriptions" >> $ReportPath
try {
    $subs = Get-AzSubscription
    if ($subs) {
        foreach ($sub in $subs) {
            "- **$($sub.Name)** (Id: $($sub.Id), State: $($sub.State))" >> $ReportPath
        }
    }
    else {
        "- No subscriptions returned." >> $ReportPath
    }
}
catch {
    "- No Azure subscriptions found or missing permissions." >> $ReportPath
}
"" >> $ReportPath

Write-Host "======================================================"
Write-Host "EXTRACCION COMPLETADA CON EXITO."
Write-Host "Reporte preliminar guardado en $ReportPath"
Write-Host "======================================================"
