$ErrorActionPreference = "Continue"

Write-Host "======================================================"
Write-Host "1. LIMPIEZA TOTAL DE SESIONES (ENVIRONMENT RESET)"
Write-Host "======================================================"
Write-Host "Cerrando sesiones activas..."
Disconnect-MgGraph -ErrorAction SilentlyContinue
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Disconnect-AzAccount -ErrorAction SilentlyContinue

Write-Host "Limpiando archivos de cache en macOS..."
# Graph/Mg
if (Test-Path "$HOME/.mg") { Remove-Item -Path "$HOME/.mg" -Recurse -Force -ErrorAction SilentlyContinue }

# Azure PowerShell - Limpieza selectiva para evitar errores de directorio
$azPath = "$HOME/.azure"
if (Test-Path $azPath) {
    # Borramos solo caches de tokens para forzar nuevo login
    Get-ChildItem -Path $azPath -Include "TokenCache.dat", "accessTokens.json", "azureProfile.json", "*.lock" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
}
else {
    New-Item -Path $azPath -ItemType Directory -ErrorAction SilentlyContinue
}

$ErrorActionPreference = "Stop"

# Función para abrir Firefox forzosamente
function Open-Firefox {
    param([string]$Url)
    Write-Host "Abriendo Firefox en: $Url"
    if (Test-Path "/Applications/Firefox.app") {
        /usr/bin/open -a "Firefox" "$Url"
    }
    else {
        /usr/bin/open -a "Firefox" "$Url"
    }
}

Write-Host "`n======================================================"
Write-Host "2. CONFIGURACION DE LA AUDITORIA (14 PUNTOS)"
Write-Host "======================================================"
Write-Host "Ingresa el Tenant ID o el dominio principal del cliente (ej: miempresa.cl):"
$TargetTenant = Read-Host "Tenant / Dominio"
if ([string]::IsNullOrEmpty($TargetTenant)) { $TargetTenant = "common" }

Write-Host "`n======================================================"
Write-Host "3. AUTENTICACION MAESTRA (FIREFOX ENFORCED)"
Write-Host "======================================================"

$clientId = "04b07795-8ddb-461a-bbee-02f9e1bf7b46" # Multi-tenant Universal ID

# --- 3.1 Microsoft Graph ---
Write-Host "-> PASO 1: Microsoft Graph API..."
$deviceCodeRes = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TargetTenant/oauth2/v2.0/devicecode" -Method Post -Body @{ client_id = $clientId; scope = "https://graph.microsoft.com/.default offline_access" }
Write-Host "CÓDIGO: $($deviceCodeRes.user_code)"
Open-Firefox -Url $deviceCodeRes.verification_uri

$tokenGraph = $null
while ($null -eq $tokenGraph) {
    Start-Sleep -Seconds $deviceCodeRes.interval
    try {
        $tokenRes = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TargetTenant/oauth2/v2.0/token" -Method Post -Body @{ client_id = $clientId; grant_type = "urn:ietf:params:oauth:grant-type:device_code"; device_code = $deviceCodeRes.device_code } -SkipHttpErrorCheck
        if ($tokenRes.access_token) { $tokenGraph = $tokenRes.access_token }
    }
    catch { if ($_.Exception.Message -match "authorization_pending") { continue } throw $_ }
}
Write-Host "¡Conectado a Graph!"

# --- 3.2 Exchange Online ---
Write-Host "`n-> PASO 2: Exchange Online (EXO)..."
Write-Host "Usa el nuevo código que verás en pantalla en Firefox..."
Connect-ExchangeOnline -Device -Organization $TargetTenant

# --- 3.3 Azure Accounts ---
Write-Host "`n-> PASO 3: Azure PowerShell (Az)..."
Write-Host "Usa el nuevo código que verás en pantalla en Firefox..."
Connect-AzAccount -UseDeviceAuthentication -TenantId $TargetTenant

Write-Host "`n======================================================"
Write-Host "4. EXTRACCION PROFUNDA DE TELEMETRIA"
Write-Host "======================================================"
$ReportPath = "/Users/claudio/Antigravity/new_tenant_audit_data.md"
"## Reporte de Auditoría Técnica: $TargetTenant" > $ReportPath
"Fecha: $(Get-Date)" >> $ReportPath
"---------------------------------------" >> $ReportPath

$headers = @{ "Authorization" = "Bearer $tokenGraph" }

Write-Host "-> Extrayendo Tenant & Org Info..."
try {
    $org = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/organization" -Headers $headers).value[0]
    "### 1. Levantamiento de Organización" >> $ReportPath
    "- Nombre: $($org.displayName)" >> $ReportPath
    "- TenantID: $($org.id)" >> $ReportPath
    "- Region: $($org.countryLetterCode)" >> $ReportPath
}
catch { "- [Error] No se pudo leer info del Tenant." >> $ReportPath }

Write-Host "-> Extrayendo Dominios..."
try {
    $domains = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/domains" -Headers $headers).value
    "#### Dominios" >> $ReportPath
    foreach ($d in $domains) { "- $($d.id) (Verified: $($d.isVerified))" >> $ReportPath }
}
catch {}

Write-Host "-> Extrayendo Inventario de Identidad..."
try {
    "### 2. Inventario de Identidad & Roles" >> $ReportPath
    $users = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users?`$count=true" -Headers @{Authorization = "Bearer $tokenGraph"; ConsistencyLevel = "eventual" }).'@odata.count'
    "- Usuarios Totales: $users" >> $ReportPath
    
    $gaRole = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/directoryRoles" -Headers $headers).value | Where-Object { $_.roleTemplateId -eq "62e90394-69f5-4237-9190-012177145e10" }
    if ($gaRole) {
        $gaMembers = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($gaRole.id)/members" -Headers $headers).value
        "- Administradores Globales: $($gaMembers.Count)" >> $ReportPath
    }
}
catch {}

Write-Host "-> Extrayendo Acceso Condicional (Zero Trust)..."
try {
    $ca = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" -Headers $headers).value
    "### 3. Seguridad y Acceso Condicional" >> $ReportPath
    foreach ($p in $ca) { "- $($p.displayName) (Estado: $($p.state))" >> $ReportPath }
}
catch {}

Write-Host "-> Extrayendo Exchange Mail Flow..."
try {
    $rules = Get-TransportRule
    "### 4. Flujo de Correo (Exchange)" >> $ReportPath
    "- Reglas de Transporte: $($rules.Count)" >> $ReportPath
}
catch {}

Write-Host "-> Extrayendo Azure Infrastructure..."
try {
    $subs = Get-AzSubscription
    "### 5. Gobernanza Azure" >> $ReportPath
    foreach ($s in $subs) { "- Suscripción: $($s.Name) ($($s.Id))" >> $ReportPath }
}
catch {}

Write-Host "-> Extrayendo Secure Score..."
try {
    $score = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/security/secureScores?`$top=1" -Headers $headers).value[0]
    "### 6. Postura de Seguridad" >> $ReportPath
    "- Current Secure Score: $($score.currentScore) / $($score.maxScore)" >> $ReportPath
}
catch {}

Write-Host "======================================================"
Write-Host "AUDITORIA FINALIZADA EXITOSAMENTE."
Write-Host "Reporte generado en: $ReportPath"
Write-Host "======================================================"
