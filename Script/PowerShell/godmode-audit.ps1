$ErrorActionPreference = "Continue"

Write-Host "======================================================"
Write-Host "MODO: Microsoft 365 + Azure Connected Tenant Auditor"
Write-Host "VERSIÓN: God Mode Architect v2.0 (Direct Tool Access)"
Write-Host "======================================================"

# 1. Reset de Sesiones
Write-Host "1. LIMPIANDO CONEXIONES PREVIAS..."
Disconnect-MgGraph -ErrorAction SilentlyContinue
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Disconnect-AzAccount -ErrorAction SilentlyContinue

# 2. Configuración del Objetivo (Fesanco)
$TargetTenant = "72d4e0ad-c185-4554-890d-f22b2d8901c4"
Write-Host "OBJETIVO: $TargetTenant"

# 3. Autenticación Triple (Firefox Enforced)
function Open-Firefox {
    param([string]$Url)
    Write-Host "Abriendo Firefox en: $Url"
    /usr/bin/open -a "Firefox" "$Url"
}

Write-Host "`n2. AUTENTICACIÓN MULTI-WORKLOAD..."

# --- 3.1 Microsoft Graph ---
Write-Host "-> Paso 1: Microsoft Graph (Identidad)..."
$clientId = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
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
Write-Host "`n-> Paso 2: Exchange Online (EXO)..."
Connect-ExchangeOnline -Device -Organization $TargetTenant

# --- 3.3 Azure Account ---
Write-Host "`n-> Paso 3: Azure PowerShell (Az)..."
Connect-AzAccount -UseDeviceAuthentication -TenantId $TargetTenant

Write-Host "`n3. EJECUTANDO BARRIDO GOD-MODE (READ-ONLY)..."
$ReportPath = "/Users/claudio/Antigravity/godmode_audit_data.md"
"## Auditoría God Mode: Fesanco" > $ReportPath
"ID: $TargetTenant | Fecha: $(Get-Date)" >> $ReportPath
"---------------------------------------" >> $ReportPath

$headers = @{ "Authorization" = "Bearer $tokenGraph" }

# --- [AUDIT SECTION: IDENTITY] ---
Write-Host "-> Extrayendo Identidad Profunda..."
try {
    $org = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/organization" -Headers $headers).value[0]
    "### 1. Tenant Overview" >> $ReportPath
    "- Cloud: $($org.displayName) (CL)" >> $ReportPath
    $domains = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/domains" -Headers $headers).value
    "#### Dominios" >> $ReportPath
    foreach ($d in $domains) { "- $($d.id) (Auth: $($d.authenticationType))" >> $ReportPath }
    
    # Conditional Access (Critical)
    $ca = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" -Headers $headers).value
    "### 2. Acceso Condicional (Zero Trust)" >> $ReportPath
    if ($ca.Count -eq 0) { "- [CRITICO] 0 Políticas de CA detectadas." >> $ReportPath }
    else { foreach ($p in $ca) { "- $($p.displayName) (Estado: $($p.state))" >> $ReportPath } }
}
catch { "### Identidad: Error de Acceso." >> $ReportPath }

# --- [AUDIT SECTION: EXCHANGE] ---
Write-Host "-> Extrayendo Exchange Online..."
try {
    $rules = Get-TransportRule | Select-Object Name, Priority, State
    "### 3. Exchange Online (Mailing)" >> $ReportPath
    foreach ($r in $rules) { "- Rule: $($r.Name) ($($r.State))" >> $ReportPath }
}
catch {}

# --- [AUDIT SECTION: AZURE] ---
Write-Host "-> Extrayendo Azure Infrastructure..."
try {
    $subs = Get-AzSubscription
    "### 4. Gobernanza Azure" >> $ReportPath
    foreach ($s in $subs) { "- Subscription: $($s.Name) ($($s.Id))" >> $ReportPath }
}
catch {}

# --- [AUDIT SECTION: SECURITY] ---
Write-Host "-> Extrayendo Postura de Seguridad Defender..."
try {
    $score = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/security/secureScores?`$top=1" -Headers $headers).value[0]
    "### 5. Microsoft Defender Score" >> $ReportPath
    "- Secure Score: $($score.currentScore) / $($score.maxScore)" >> $ReportPath
}
catch {}

Write-Host "======================================================"
Write-Host "AUDITORIA GOD-MODE FINALIZADA EXITOSAMENTE."
Write-Host "Data cruda guardada en: $ReportPath"
Write-Host "======================================================"
