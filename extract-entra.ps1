$ErrorActionPreference = "Stop"

$ReportPath = "/Users/claudio/Antigravity/m365_azure_report.md"
"## Microsoft 365 Architecture & Identity Export" > $ReportPath
"" >> $ReportPath

# 1. Tenant & Domains
"### 1. Tenant Overview" >> $ReportPath
$org = Get-MgOrganization | Select-Object Id, DisplayName, TenantType, CountryLetterCode
"**Tenant ID:** $($org.Id)" >> $ReportPath
"**Name:** $($org.DisplayName)" >> $ReportPath
"**Country:** $($org.CountryLetterCode)" >> $ReportPath
"" >> $ReportPath
"**Domains:**" >> $ReportPath
Get-MgDomain | ForEach-Object { "- $($_.Id) (Verified: $($_.IsVerified), Default: $($_.IsDefault))" } >> $ReportPath
"" >> $ReportPath

# 2. Users Overview
"### 2. Identity Inventory (Users)" >> $ReportPath
$allUsers = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, UserType
$guestCount = ($allUsers | Where-Object { $_.UserType -eq 'Guest' }).Count
$enabledCount = ($allUsers | Where-Object { $_.AccountEnabled -eq $true }).Count
"- Total Users: $($allUsers.Count)" >> $ReportPath
"- Active Users: $enabledCount" >> $ReportPath
"- Guest Users: $guestCount" >> $ReportPath
"" >> $ReportPath

# 3. Admins & Roles
"### 3. Administrative Roles (Global Admins)" >> $ReportPath
$roles = Get-MgDirectoryRole -All
$gaRole = $roles | Where-Object { $_.RoleTemplateId -eq "62e90394-69f5-4237-9190-012177145e10" } # Global Admin Template ID
if ($gaRole) {
    $gaMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id
    foreach ($m in $gaMembers) {
        $u = Get-MgUser -UserId $m.Id -ErrorAction SilentlyContinue
        if ($u) { "- $($u.DisplayName) ($($u.UserPrincipalName))" >> $ReportPath }
    }
}
"" >> $ReportPath

# 4. Applications and Service Principals
"### 4. Registered Applications & Service Principals" >> $ReportPath
$apps = Get-MgApplication -Top 500
$sps = Get-MgServicePrincipal -Top 500
"- Total App Registrations: $($apps.Count)" >> $ReportPath
"- Total Enterprise Apps (Service Principals): $($sps.Count)" >> $ReportPath
"" >> $ReportPath

# 5. Conditional Access Policies
"### 5. Conditional Access Policies" >> $ReportPath
$caPolicies = Get-MgIdentityConditionalAccessPolicy -All
if ($caPolicies.Count -gt 0) {
    foreach ($p in $caPolicies) {
        "- **$($p.DisplayName)** (State: $($p.State)) - MFA Required: $($p.GrantControls.BuiltInControls -contains 'mfa')" >> $ReportPath
    }
}
else {
    "- No Conditional Access Policies found (or lack of permissions/licensing)." >> $ReportPath
}
"" >> $ReportPath

Write-Host "Entra ID details exported to $ReportPath"
