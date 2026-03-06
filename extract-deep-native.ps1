$ErrorActionPreference = "Stop"

Write-Host "======================================================"
Write-Host "1. OBTENIENDO TOKEN DE MICROSOFT GRAPH (NATIVO)"
Write-Host "======================================================"
$clientId = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
$tenantId = "common"

$deviceCodeParams = @{
    client_id = $clientId
    scope     = "https://graph.microsoft.com/.default offline_access"
}
$deviceCodeResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode" -Method Post -Body $deviceCodeParams
Write-Host "Por favor, entra a $($deviceCodeResponse.verification_uri) e ingresa el codigo: $($deviceCodeResponse.user_code)"
Write-Host "Esperando autenticacion en el navegador (no presiones nada aquí)..."

$token = $null
while ($null -eq $token) {
    Start-Sleep -Seconds $deviceCodeResponse.interval
    try {
        $tokenParams = @{
            client_id   = $clientId
            grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
            device_code = $deviceCodeResponse.device_code
        }
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $tokenParams -SkipHttpErrorCheck
        
        if ($tokenResponse.error -eq "authorization_pending") {
            continue
        }
        elseif ($tokenResponse.access_token) {
            $token = $tokenResponse.access_token
        }
        else {
            throw "Error obteniendo token: $($tokenResponse.error_description)"
        }
    }
    catch {
        $errMsg = $_.ToString() + $_.ErrorDetails.Message
        if ($errMsg -match "authorization_pending") { continue }
        throw $_
    }
}
Write-Host "TOKEN GRAPH OBTENIDO EXITOSAMENTE."
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "======================================================"
Write-Host "2. EXTRACCION PROFUNDA DE WORKLOADS (REST API)"
Write-Host "======================================================"
$ReportPath = "/Users/claudio/Antigravity/m365_deep_report.md"
"## Microsoft 365 Deep Assessment Export (Workloads & Security)" > $ReportPath
"" >> $ReportPath

Write-Host "-> Extrayendo Privileged Roles (Global Admins)..."
"### 1. Privileged Roles (Global Admins)" >> $ReportPath
try {
    $rolesReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/directoryRoles" -Headers $headers -Method Get
    $gaRole = $rolesReq.value | Where-Object { $_.roleTemplateId -eq "62e90394-69f5-4237-9190-012177145e10" }
    
    if ($gaRole) {
        $gaMembersReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($gaRole.id)/members" -Headers $headers -Method Get
        foreach ($m in $gaMembersReq.value) {
            "- **$($m.displayName)** ($($m.userPrincipalName))" >> $ReportPath
        }
    }
}
catch {
    "- Could not read Global Admins." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo Microsoft Defender Secure Score..."
"### 2. Microsoft Defender (Secure Score)" >> $ReportPath
try {
    $scoreReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/security/secureScores?`$top=1" -Headers $headers -Method Get
    if ($scoreReq.value.Count -gt 0) {
        $currentScore = $scoreReq.value[0].currentScore
        $maxScore = $scoreReq.value[0].maxScore
        $percentage = [math]::Round(($currentScore / $maxScore) * 100, 2)
        "- **Overall Secure Score:** $percentage% ($currentScore / $maxScore)" >> $ReportPath
        "- **Active Controls:** $($scoreReq.value[0].activeUserControlCount)" >> $ReportPath
    }
    else {
        "- Secure Score not calculated or not available." >> $ReportPath
    }
}
catch {
    "- Could not read Secure Score (requires SecurityReader)." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo SharePoint Online & OneDrive..."
"### 3. SharePoint & OneDrive Settings" >> $ReportPath
try {
    $spoReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/admin/sharepoint/settings" -Headers $headers -Method Get
    "- Sharing Capability: $($spoReq.sharingCapability)" >> $ReportPath
    "- Require Guest SignIn: $($spoReq.isRequireSignInEnabled)" >> $ReportPath
    "- Legacy Auth Allowed: $($spoReq.isLegacyAuthProtocolsEnabled)" >> $ReportPath
    "- Is Unmanaged Sync Allowed: $($spoReq.isUnmanagedSyncAppForTenantRestricted)" >> $ReportPath
}
catch {
    "- Could not read SharePoint settings." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo Intune Devices & Compliance..."
"### 4. Endpoint Management (Intune)" >> $ReportPath
try {
    $devicesReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices" -Headers $headers -Method Get
    $totalDevices = $devicesReq.value.Count
    $compliantDevices = ($devicesReq.value | Where-Object { $_.complianceState -eq 'compliant' }).Count
    "- Total Managed Devices (Enrolled): $totalDevices" >> $ReportPath
    "- Compliant Devices: $compliantDevices" >> $ReportPath
    
    $policiesReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" -Headers $headers -Method Get
    "- Compliance Policies Count: $($policiesReq.value.Count)" >> $ReportPath
}
catch {
    "- Could not read Intune Managed Devices." >> $ReportPath
}
"" >> $ReportPath

Write-Host "-> Extrayendo Microsoft Purview Labels..."
"### 5. Microsoft Purview (Information Protection)" >> $ReportPath
try {
    $labelsReq = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/informationProtection/policy/labels" -Headers $headers -Method Get
    if ($labelsReq.value.Count -gt 0) {
        foreach ($l in $labelsReq.value) {
            "- Label: **$($l.name)** (Tooltip: $($l.tooltip))" >> $ReportPath
        }
    }
    else {
        "- No Sensitivity Labels published." >> $ReportPath
    }
}
catch {
    "- Could not read Purview Information Protection Labels." >> $ReportPath
}
"" >> $ReportPath

Write-Host "======================================================"
Write-Host "EXTRACCION PROFUNDA COMPLETADA CON EXITO."
Write-Host "Reporte guardado en $ReportPath"
Write-Host "======================================================"
