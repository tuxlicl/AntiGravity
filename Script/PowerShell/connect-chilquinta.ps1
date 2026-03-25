$ErrorActionPreference = "Continue"

Write-Host "======================================================"
Write-Host " CONECTANDO AL TENANT DE CHILQUINTA (M365)"
Write-Host "======================================================"

$TenantDomain = "chilquinta.cl"

Write-Host "1. Limpiando sesiones y caché antigua para evitar conflictos..."
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Disconnect-MgGraph -ErrorAction SilentlyContinue
if (Test-Path "$HOME/.mg") { Remove-Item -Path "$HOME/.mg" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "$HOME/.IdentityService") { Remove-Item -Path "$HOME/.IdentityService" -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "`n2. Conectando a Exchange Online (Buzones, Reglas, etc.)"
Write-Host "   -> Sigue las instrucciones para autenticarte en tu navegador..."
Connect-ExchangeOnline -Device -Organization $TenantDomain

Write-Host "`n3. Conectando a Microsoft Graph (Usuarios, Entra ID, Licencias)"
Write-Host "   -> Sigue las instrucciones para autenticarte en tu navegador..."
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "MailboxSettings.ReadWrite" -UseDeviceAuthentication -TenantId $TenantDomain

Write-Host "`n======================================================"
Write-Host " ¡CONECTADO EXITOSAMENTE! "
Write-Host " Ya puedes correr comandos para modificar cuentas."
Write-Host "======================================================"
Write-Host "Ejemplos:"
Write-Host "- Para Exchange: Set-Mailbox -Identity 'usuario@chilquinta.cl' -... "
Write-Host "- Para Entra ID: Update-MgUser -UserId 'usuario@chilquinta.cl' -... "
