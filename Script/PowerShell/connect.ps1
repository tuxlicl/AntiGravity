Connect-MgGraph -Scopes "User.Read.All","Group.Read.All","AuditLog.Read.All","Policy.Read.All","RoleManagement.Read.Directory","SecurityEvents.Read.All","DeviceManagementConfiguration.Read.All","Organization.Read.All", "CrossTenantInformation.ReadBasic.All"
Connect-ExchangeOnline
Connect-AzAccount
Set-Content -Path "/Users/claudio/Antigravity/auth_success.txt" -Value "AUTH_SUCCESS"
