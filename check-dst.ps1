# --- CONFIGURACIÓN ---
$FixRules = $true # Ponlo en $true para aplicar el arreglo a abril 2026

try {
    Clear-Host
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host "--- Verificación y Arreglo de Tiempo (Chile 2026) ---" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    
    $tz = [System.TimeZoneInfo]::Local
    $now = Get-Date
    $y = $now.Year
    $rules = $tz.GetAdjustmentRules()
    $currentRule = $rules | Where-Object { $_.DateStart.Year -le $y -and $_.DateEnd.Year -ge $y }

    Write-Host "`n[+] Configuración Actual:"
    Write-Host "    - ID Zona Horaria:   $($tz.Id)"
    Write-Host "    - Nombre:            $($tz.DisplayName)"
    Write-Host "    - Fecha/Hora Local:  $($now.ToString('dd/MM/yyyy HH:mm:ss'))"
    Write-Host "    - Offset UTC Actual: $($tz.GetUtcOffset($now).TotalHours) horas"

    if ($null -ne $currentRule) {
        # Función para calcular fechas de transición
        function Get-TransitionDate($t, $yearVal) {
            if ($t.IsFixedDateRule) { return Get-Date -Year $yearVal -Month $t.Month -Day $t.Day -Hour $t.TimeOfDay.Hour -Minute $t.TimeOfDay.Minute -Second 0 }
            $d = Get-Date -Year $yearVal -Month $t.Month -Day 1
            while ($d.DayOfWeek -ne $t.DayOfWeek) { $d = $d.AddDays(1) }
            $res = $d.AddDays(($t.Week - 1) * 7)
            if ($res.Month -ne $t.Month) { $res = $res.AddDays(-7) }
            return $res.AddHours($t.TimeOfDay.Hour).AddMinutes($t.TimeOfDay.Minute)
        }

        # En Chile: abril es el fin de verano (atrasa reloj) y sept/oct es el inicio (adelanta reloj)
        $winterStart = Get-TransitionDate $currentRule.DaylightTransitionEnd $y
        $summerStart = Get-TransitionDate $currentRule.DaylightTransitionStart $y

        Write-Host "`n[+] Reglas en el sistema para el año ${y}:" -ForegroundColor White
        Write-Host "    - Inicio INVIERNO (UTC-4): $($winterStart.ToString('dddd, dd MMMM yyyy HH:mm'))"
        Write-Host "    - Inicio VERANO   (UTC-3): $($summerStart.ToString('dddd, dd MMMM yyyy HH:mm'))"

        if ($winterStart.Month -ne 4) {
            Write-Host "`n[!] ALERTA: El cambio a invierno NO está en Abril (Muestra mes $($winterStart.Month))." -ForegroundColor Red
        }
        else {
            Write-Host "`n[OK] El cambio de invierno está correctamente en Abril." -ForegroundColor Green
        }
    }

    if ($FixRules) {
        Write-Host "`n[!] Aplicando Patch Chile 2026 en Registro..." -ForegroundColor Yellow
        # Binario oficial Chile 2026: Abril 4 (Invierno) y Septiembre 5 (Verano)
        $bin = [byte[]] @(0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC4, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x04, 0x00, 0x06, 0x00, 0x01, 0x00, 0x17, 0x00, 0x3B, 0x00, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x00, 0x06, 0x00, 0x01, 0x00, 0x17, 0x00, 0x3B, 0x00, 0x3B, 0x00, 0x00, 0x00)
        $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\Pacific SA Standard Time\Dynamic DST"
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "2026" -Value $bin -Type Binary -Force
        
        Write-Host "[OK] Parche aplicado con éxito." -ForegroundColor Green
        Write-Host "`n[PASO FINAL] Ejecuta este comando abajo para refrescar el sistema:" -ForegroundColor Cyan
        Write-Host "tzutil /s ""Pacific SA Standard Time""" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "Error de ejecución: $($_.Exception.Message)"
}
