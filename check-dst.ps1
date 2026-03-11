<#
.SYNOPSIS
    Valida la configuración de Horario de Verano (DST) y las próximas transiciones.
.DESCRIPTION
    Este script analiza la zona horaria del sistema, verifica si el ajuste automático está habilitado 
    en el registro y calcula las fechas exactas del próximo cambio de hora (invierno/verano).
    Ideal para entornos OT donde la interfaz gráfica puede estar restringida o no mostrar info detallada.
.EXAMPLE
    .\Get-NextDSTTransition.ps1
#>

[CmdletBinding()]
param()

Process {
    try {
        Write-Host "--- Verificación de Configuración de Tiempo (Red OT/SCADA) ---" -ForegroundColor Cyan
        
        # 1. Obtener Info de Zona Horaria Actual
        $tz = [System.TimeZoneInfo]::Local
        $now = Get-Date

        Write-Host "`n[+] Información del Sistema:"
        Write-Host "    - Zona Horaria Actual: $($tz.DisplayName)"
        Write-Host "    - Fecha/Hora Actual:   $($now.ToString('dd/MM/yyyy HH:mm:ss'))"
        Write-Host "    - Ajuste DST Activo:   $($tz.IsDaylightSavingTime($now))"
        Write-Host "    - Offset UTC Actual:   $($tz.GetUtcOffset($now).TotalHours) horas"

        # 2. Verificar Registro de Windows (DynamicDaylightTimeDisabled)
        # 0 = Habilitado (Cambia solo), 1 = Deshabilitado (No cambia)
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
        $dstDisabled = Get-ItemProperty -Path $regPath -Name "DynamicDaylightTimeDisabled" -ErrorAction SilentlyContinue
        
        Write-Host "`n[+] Estado del Registro de Windows:"
        if ($null -ne $dstDisabled) {
            $status = if ($dstDisabled.DynamicDaylightTimeDisabled -eq 1) { "DESHABILITADO (No cambiará automáticamente)" } else { "HABILITADO (Cambiará automáticamente)" }
            $color = if ($dstDisabled.DynamicDaylightTimeDisabled -eq 1) { "Yellow" } else { "Green" }
            Write-Host "    - Ajuste Automático: $status" -ForegroundColor $color
        }
        else {
            Write-Host "    - Ajuste Automático: No se encontró la llave de registro (valor por defecto es Habilitado)."
        }

        # 3. Calcular Próximas Transiciones
        Write-Host "`n[+] Próximos Cambios Programados (Reglas de Sistema):"
        $rules = $tz.GetAdjustmentRules()
        $year = $now.Year

        # Filtrar reglas para el año actual
        $currentRule = $rules | Where-Object { $_.DateStart.Year -le $year -and $_.DateEnd.Year -ge $year }

        if ($null -eq $currentRule) {
            Write-Host "    [!] No se encontraron reglas de transición para el año $year." -ForegroundColor Red
        }
        else {
            # Función local para convertir reglas relativas a fechas fijas
            function Get-TransitionDate($transition, $year) {
                if ($transition.IsFixedDateRule) {
                    return Get-Date -Year $year -Month $transition.Month -Day $transition.Day -Hour $transition.TimeOfDay.Hour -Minute $transition.TimeOfDay.Minute -Second 0
                }
                else {
                    $firstDayOfMonth = Get-Date -Year $year -Month $transition.Month -Day 1
                    $dayOfWeek = $transition.DayOfWeek
                    $weekInMonth = $transition.Week # 5 significa la última semana
                    
                    $targetDay = $firstDayOfMonth
                    while ($targetDay.DayOfWeek -ne $dayOfWeek) {
                        $targetDay = $targetDay.AddDays(1)
                    }
                    
                    $transitionDate = $targetDay.AddDays(($weekInMonth - 1) * 7)
                    
                    # Si calculamos la 5ta semana y nos pasamos de mes, volver 7 días
                    if ($transitionDate.Month -ne $transition.Month) {
                        $transitionDate = $transitionDate.AddDays(-7)
                    }
                    
                    return $transitionDate.AddHours($transition.TimeOfDay.Hour).AddMinutes($transition.TimeOfDay.Minute)
                }
            }

            $dstStart = Get-TransitionDate $currentRule.DaylightTransitionStart $year
            $dstEnd = Get-TransitionDate $currentRule.DaylightTransitionEnd $year

            # Determinar cuál es la siguiente
            if ($now -lt $dstEnd -and $now -gt $dstStart) {
                Write-Host "    - Próximo cambio (Invierno): $($dstEnd.ToString('dddd, dd MMMM yyyy HH:mm'))" -ForegroundColor Cyan
                Write-Host "      (El reloj se atrasará 1 hora)"
            }
            elseif ($now -lt $dstStart) {
                Write-Host "    - Próximo cambio (Verano):   $($dstStart.ToString('dddd, dd MMMM yyyy HH:mm'))" -ForegroundColor Cyan
                Write-Host "      (El reloj se adelantará 1 hora)"
            }
            else {
                # Ya pasamos los cambios de este año, mostrar el primero del próximo
                $dstStartNext = Get-TransitionDate $currentRule.DaylightTransitionStart ($year + 1)
                Write-Host "    - Próximo cambio ($($year + 1)): $($dstStartNext.ToString('dddd, dd MMMM yyyy HH:mm'))"
            }
        }

        Write-Host "`n--- Fin de Verificación ---" -ForegroundColor Cyan

    }
    catch {
        Write-Error "Error ejecutando la verificación: $($_.Exception.Message)"
    }
}
