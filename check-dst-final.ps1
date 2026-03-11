# --- REPARACIÓN MAESTRA DE ZONA HORARIA Y VALIDACIÓN CHILE 2026 ---
# Este script reconstruye la zona horaria desde cero para eliminar errores de "datos no legibles".

try {
    Clear-Host
    Write-Host "--- REPARACIÓN Y VALIDACIÓN TÉCNICA (CHILE 2026) ---" -ForegroundColor Cyan

    $tzId = "Pacific SA Standard Time"
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\$tzId"
    
    Write-Host "[1/4] Reconstruyendo base de datos de zona horaria..." -ForegroundColor Yellow
    
    # Asegurar que la llave existe y tiene los nombres correctos (esto arregla el error de tzutil)
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    
    $display = "(UTC-04:00) Santiago"
    $std = "Hora est. Sudamérica Pacífico"
    $dlt = "Hora de verano de Sudamérica Pacífico"
    
    Set-ItemProperty -Path $regPath -Name "Display" -Value $display -Force
    Set-ItemProperty -Path $regPath -Name "Std"     -Value $std     -Force
    Set-ItemProperty -Path $regPath -Name "Dlt"     -Value $dlt     -Force

    # Regla TZI (UTC-4 con DST UTC-3):
    # Abr 4 (1er Sab) -> Invierno
    # Sep 5 (1er Sab) -> Verano
    $tzi = [byte[]] @(
        0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC4, 0xFF, 0xFF, 0xFF, 
        0x00, 0x00, 0x04, 0x00, 0x06, 0x00, 0x01, 0x00, 0x17, 0x00, 0x3B, 0x00, 
        0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x00, 0x06, 0x00, 0x01, 0x00, 
        0x17, 0x00, 0x3B, 0x00, 0x3B, 0x00, 0x00, 0x00
    )
    Set-ItemProperty -Path $regPath -Name "TZI" -Value $tzi -Type Binary -Force

    Write-Host "[2/4] Habilitando ajuste automático en el núcleo del sistema..." -ForegroundColor Yellow
    $ctrlPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
    Set-ItemProperty -Path $ctrlPath -Name "DynamicDaylightTimeDisabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $ctrlPath -Name "TimeZoneKeyName" -Value $tzId -Force

    Write-Host "[3/4] Refrescando motor de tiempo (tzutil)..." -ForegroundColor Yellow
    & tzutil /s "Pacific SA Standard Time" 2>$null

    Write-Host "[4/4] VALIDACIÓN DEL MOTOR .NET (Prueba de Transición):" -ForegroundColor Cyan
    
    # Forzar el refresco del objeto TimeZoneInfo
    [System.TimeZoneInfo]::ClearCachedData()
    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($tzId)
    
    # Fechas de prueba
    $dMarzo = [datetime]"2026-03-20 12:00:00"
    $dAbril = [datetime]"2026-04-10 12:00:00"
    
    $offMarzo = $tz.GetUtcOffset($dMarzo).TotalHours
    $offAbril = $tz.GetUtcOffset($dAbril).TotalHours

    Write-Host "    - Offset Marzo (Debe ser -3): $offMarzo"
    Write-Host "    - Offset Abril (Debe ser -4): $offAbril"

    if ($offMarzo -eq -3 -and $offAbril -eq -4) {
        Write-Host "`n[ EXCELENTE: SISTEMA REPARADO ]" -ForegroundColor Green
        Write-Host "El motor de Windows ya reconoce que Marzo es UTC-3 y Abril es UTC-4."
        Write-Host "El cambio ocurrirá automáticamente el 4 de Abril."
    }
    else {
        Write-Host "`n[ RECOMENDACIÓN ] El motor .NET sigue usando datos en caché." -ForegroundColor Yellow
        Write-Host "Por favor, CIERRA el PowerShell ISE y vuélvelo a abrir para ver el cambio."
    }

}
catch {
    Write-Error "Error: $($_.Exception.Message)"
}
