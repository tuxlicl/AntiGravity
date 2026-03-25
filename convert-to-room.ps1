$ErrorActionPreference = "Stop"

Write-Host "=============================================="
Write-Host " CONVERTIR BUZON A SALA (ROOM) - CHILQUINTA"
Write-Host "=============================================="

# Verificamos si ya hay una sesión de Exchange abierta
try {
    Get-Mailbox -ResultSize 1 -ErrorAction Stop | Out-Null
    Write-Host "[x] Ya tienes una sesión activa de Exchange Online."
} catch {
    Write-Host "[!] No se detectó conexión activa a Exchange. Conectando..."
    Connect-ExchangeOnline -Device -Organization "chilquinta.cl"
}

Write-Host "`nPor favor, ingresa los correos de las salas que acabas de licenciar."
$email1 = Read-Host "Correo de la PRIMERA sala (ej: sala1@chilquinta.cl)"
$email2 = Read-Host "Correo de la SEGUNDA sala (ej: sala2@chilquinta.cl)"

if ([string]::IsNullOrWhiteSpace($email1) -and [string]::IsNullOrWhiteSpace($email2)) {
    Write-Host "No ingresaste correos. Saliendo..."
    exit
}

if (-not [string]::IsNullOrWhiteSpace($email1)) {
    Write-Host "`n-> Convirtiendo $email1 a buzón de tipo Room..."
    try {
        Set-Mailbox -Identity $email1 -Type Room
        Write-Host "   ¡Exito! $email1 ahora es una sala."
    } catch {
        Write-Host "   [ERROR] No se pudo convertir $email1. Puede que el buzón aún se esté provisionando en la nube. Espera 5 mins e intenta de nuevo."
        Write-Host "   Detalle del error: $($_.Exception.Message)"
    }
}

if (-not [string]::IsNullOrWhiteSpace($email2)) {
    Write-Host "`n-> Convirtiendo $email2 a buzón de tipo Room..."
    try {
        Set-Mailbox -Identity $email2 -Type Room
        Write-Host "   ¡Exito! $email2 ahora es una sala."
    } catch {
        Write-Host "   [ERROR] No se pudo convertir $email2."
        Write-Host "   Detalle del error: $($_.Exception.Message)"
    }
}

Write-Host "`n=============================================="
Write-Host " PROCESO COMPLETADO"
Write-Host " Si salió '[Exito]', ya puedes ir al portal de M365"
Write-Host " y QUITARLES la licencia a las dos cuentas."
Write-Host "=============================================="
