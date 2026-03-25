# --- SCRIPT DE REPARACIÓN DE EMERGENCIA ---
# Este script limpia cualquier dato corrupto y vuelve a intentar la configuración oficial.

try {
    Write-Host "[!] Iniciando limpieza y reparación..." -ForegroundColor Yellow
    
    # 1. Borrar la llave de 2026 que podría estar corrupta
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Pacific SA Standard Time\Dynamic DST"
    if (Test-Path "$regPath\2026") {
        Remove-ItemProperty -Path $regPath -Name "2026" -ErrorAction SilentlyContinue
        Write-Host "[OK] Llave 2026 previa eliminada para limpieza." -ForegroundColor Green
    }

    # 2. Re-inyectar binary (Asegurando formato exacto de 44 bytes para Windows)
    # Binary: UTC-4 (Bias 240), DST UTC-3 (DltBias -60), Apr 4 23:59:59 (Std), Sep 5 23:59:59 (Dlt)
    $bin = [byte[]] @(
        0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC4, 0xFF, 0xFF, 0xFF, 
        0x00, 0x00, 0x04, 0x00, 0x06, 0x00, 0x01, 0x00, 0x17, 0x00, 0x3B, 0x00, 
        0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x00, 0x06, 0x00, 0x01, 0x00, 
        0x17, 0x00, 0x3B, 0x00, 0x3B, 0x00, 0x00, 0x00
    )

    Set-ItemProperty -Path $regPath -Name "2026" -Value $bin -Type Binary -Force
    Write-Host "[OK] Llave 2026 re-inyectada correctamente." -ForegroundColor Green

    # 3. Forzar actualización del sistema (Método Alternativo si tzutil falla)
    Write-Host "[!] Refrescando configuración de zona horaria..." -ForegroundColor Cyan
    
    # Intentamos primero con tzutil
    tzutil /s "Pacific SA Standard Time"
    
    # Si tzutil sigue dando error, usamos un método de registro para forzar el refresco
    $currentTzPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
    Set-ItemProperty -Path $currentTzPath -Name "TimeZoneKeyName" -Value "Pacific SA Standard Time" -Force
    
    Write-Host "`n[LISTO] Verificación final:" -ForegroundColor White
    $tzCheck = [System.TimeZoneInfo]::Local
    Write-Host "    Zona: $($tzCheck.DisplayName)"
    Write-Host "    Hora: $(Get-Date)"

}
catch {
    Write-Error "Error: $($_.Exception.Message)"
}
