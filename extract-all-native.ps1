$ErrorActionPreference = "Stop"

Write-Host "======================================================"
Write-Host "1. OBTENIENDO TOKEN DE MICROSOFT GRAPH (NATIVO)"
Write-Host "======================================================"
$clientId = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
$tenantId = "common"

# 1) Iniciar Device Code Flow
$deviceCodeParams = @{
    client_id = $clientId
    scope     = "https://graph.microsoft.com/.default offline_access"
}
$deviceCodeResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode" -Method Post -Body $deviceCodeParams
Write-Host "Por favor, entra a $($deviceCodeResponse.verification_uri) e ingresa el codigo: $($deviceCodeResponse.user_code)"
Write-Host "Esperando autenticacion en el navegador (no presiones nada aquí)..."

# 2) Polling hasta que el usuario se autentique
$token = $null
while ($null -eq $token) {
    Start-Sleep -Seconds $deviceCodeResponse.interval
    try {
        $tokenParams = @{
            client_id   = $clientId
            grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
            device_code = $deviceCodeResponse.device_code
        }
        # SkipHttpErrorCheck previene que PowerShell lance excepciones rojas por HTTP 400
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $tokenParams -SkipHttpErrorCheck
        
        if ($tokenResponse.error -eq "authorization_pending") {
            # El usuario aun esta en la web, seguimos esperando en silencio
            continue
        }
        elseif ($tokenResponse.access_token) {
            # ¡Exito!
            $token = $tokenResponse.access_token
        }
        else {
            # Otro error inesperado
            throw "Error obteniendo token: $($tokenResponse.error_description)"
        }
    }
    catch {
        # Si la version de PowerShell es antigua y no soporta SkipHttpErrorCheck, caemos aca
        $errMsg = $_.ToString() + $_.ErrorDetails.Message
        if ($errMsg -match "authorization_pending") {
            continue
        }
        throw $_
    }
}
Write-Host "TOKEN GRAPH OBTENIDO EXITOSAMENTE."
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "======================================================"
Write-Host "2. AUTENTICANDO EXCHANGE Y AZURE"
Write-Host "======================================================"
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

Write-Host "-> Extrayendo Tenant & Domains (vía REST)..."
"### 1. Tenant Overview" >> $ReportPath
$orgReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/organization" -Headers $headers -Method Get
$org = $orgReq.value[0]
"**Tenant ID:** $($org.id)" >> $ReportPath
"**Name:** $($org.displayName)" >> $ReportPath
"**Country:** $($org.countryLetterCode)" >> $ReportPath
"" >> $ReportPath
"**Domains:**" >> $ReportPath
$domainsReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/domains" -Headers $headers -Method Get
$domainsReq.value | ForEach-Object { "- $($_.id) (Verified: $($_.isVerified), Default: $($_.isDefault))" } >> $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Usuarios (vía REST)..."
"### 2. Identity Inventory (Users)" >> $ReportPath
$allUsers = @()
$url = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,accountEnabled,userType"
while ($url) {
    try {
        $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $allUsers += $res.value
        $url = $res.'@odata.nextLink'
    }
    catch {
        $url = $null # Romper loop si falla
    }
}
$guestCount = ($allUsers | Where-Object { $_.userType -eq 'Guest' }).Count
$enabledCount = ($allUsers | Where-Object { $_.accountEnabled -eq $true }).Count
"- Total Users: $($allUsers.Count)" >> $ReportPath
"- Active Users: $enabledCount" >> $ReportPath
"- Guest Users: $guestCount" >> $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Aplicaciones y SPs (vía REST)..."
"### 4. Registered Applications" >> $ReportPath
try {
    $appsReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/applications?`$top=500" -Headers $headers -Method Get
    "- Total App Registrations: $($appsReq.value.Count)" >> $ReportPath
}
catch {
    "- Could not read App Registrations (permissions issue)." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo Politicas de Acceso Condicional (vía REST)..."
"### 5. Conditional Access Policies" >> $ReportPath
try {
    $caReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" -Headers $headers -Method Get
    if ($caReq.value.Count -gt 0) {
        foreach ($p in $caReq.value) {
            "- **$($p.displayName)** (State: $($p.state))" >> $ReportPath
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
    $domainsObj = Get-AcceptedDomain
    "- Accepted Domains: $(($domainsObj | Select-Object -ExpandProperty Name) -join ', ')" >> $ReportPath
    $rules = Get-TransportRule
    "- Transport Rules Count: $($rules.Count)" >> $ReportPath
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
