<#
# Autor              : Claudio Aliste Requena
# Email              : aliste.claudio@gmail.com
# Fecha creación     : 01/03/2023
# Fecha modificación : 03/09/2024
# Propósito          : Generar informe de AD entregando información de Usuarios, Grupos, OU y GPO.
# Versión            : 4.1 (Arreglo de Propiedades GPO originales, Tablas Colorizadas por sección y Highlight Admin)
# ***** DISCLAIMER ******: En caso de hacerle una mejora, informar para tener el script actualizado
# ***** DISCLAIMER 2 *****: No me hago responsable del mal uso de este script, es de uso netamente interno y para auditar cuentas y configuraciones en un entorno de Active Directory.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "C:\AD_Audit\AD_Audit_Report.html"
)

begin {
    $currentDateTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    $reportDir       = Split-Path -Path $ReportPath -Parent
    
    if (-not (Test-Path -Path $reportDir)) {
        Write-Verbose "Creando directorio $reportDir..."
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    # ------------------------------------------------------------------
    # CSS CORPORATIVO, MULTICOLOR Y TABLAS CEBRA
    # ------------------------------------------------------------------
    $HtmlBuilder = [System.Text.StringBuilder]::new()
    $HtmlBuilder.AppendLine(@"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Auditoría de Active Directory</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f0f2f5; color: #333; }
        .container { max-width: 1400px; margin: auto; background: #ffffff; padding: 30px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); border-radius: 8px; }
        
        /* Cabeceras y Títulos */
        h1 { color: #2c3e50; text-align: center; border-bottom: 3px solid #34495e; padding-bottom: 15px; margin-bottom: 30px; font-size: 30px; }
        h2 { margin-top: 50px; border-bottom: 2px solid #bdc3c7; padding-bottom: 5px; font-size: 22px; page-break-before: always; }
        h3 { color: #34495e; margin-bottom: 5px; font-size: 16px; font-weight: bold; }
        
        /* Sección de Resumen */
        .summary-box { background-color: #f8f9fa; border: 1px solid #dee2e6; border-left: 6px solid #2980b9; padding: 25px; margin-bottom: 30px; border-radius: 6px; }
        .summary-list { list-style-type: none; padding-left: 10px; margin: 0 0 15px 0; }
        .summary-list li { margin-bottom: 8px; font-size: 15px; border-bottom: 1px dashed #ced4da; padding-bottom: 4px; }
        .metric { font-weight: bold; color: #e74c3c; float: right; margin-right: 50px; font-size: 16px; }
        
        /* Estilos Base de Tablas */
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 13.5px; border-radius: 5px; overflow: hidden; box-shadow: 0 0 10px rgba(0,0,0,0.05); }
        th, td { border: 1px solid #dee2e6; padding: 12px 15px; text-align: left; }
        th { color: #ffffff; font-weight: 600; text-transform: uppercase; font-size: 12.5px; letter-spacing: 0.5px; }
        
        /* Cebra Fuerte (Líneas Alternadas) */
        tr:nth-child(even) { background-color: #f8f9fa; }
        tr:hover { background-color: #e9ecef; transition: background-color 0.2s; }
        
        /* Colores Temáticos por Sección */
        .title-users { color: #2980b9; }
        .table-users th { background-color: #2980b9; } /* Azul */
        
        .title-groups { color: #27ae60; }
        .table-groups th { background-color: #27ae60; } /* Verde */
        
        .title-gpos { color: #8e44ad; }
        .table-gpos th { background-color: #8e44ad; } /* Morado */
        
        .title-ous { color: #7f8c8d; }
        .table-ous th { background-color: #7f8c8d; } /* Gris */
        
        /* Alertas y Highlights */
        .admin-row { background-color: #fff3cd !important; color: #856404; font-weight: bold; border-left: 5px solid #ffc107; }
        .admin-row:hover { background-color: #ffe69c !important; }
        .alert-gpo { color: #e74c3c; font-weight: bold; }
        
        /* Pie de página */
        footer { margin-top: 50px; text-align: center; color: #6c757d; font-size: 13px; border-top: 1px solid #ced4da; padding-top: 25px; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Auditoría Interna de Active Directory</h1>
"@) | Out-Null
}

process {
    Write-Host "Realizando extracciones y cálculos en AD..." -ForegroundColor Green
    
    # ------------------------------------------------------------------
    # 1. RECOPILACIÓN
    # ------------------------------------------------------------------
    $userProps = @('DisplayName','EmailAddress','MemberOf','Description','Office','Homepage','Enabled','Created','PasswordLastSet','LastLogonDate','AccountExpirationDate','PasswordNeverExpires', 'SamAccountName')
    $users = Get-ADUser -Filter * -Properties $userProps -ErrorAction Stop

    $totalUsers = $users.Count
    $domainAdminsCount = 0
    $serviceAccountsCount = 0
    $genericAccountsCount = 0

    foreach ($u in $users) {
        if ($u.MemberOf -match "CN=Domain Admins") { $domainAdminsCount++ }
        elseif ($u.SamAccountName -match "^(svc|srv|sql|iis)_" -or $u.Description -match "service|servicio") { $serviceAccountsCount++ } 
        elseif ($u.SamAccountName -match "^(admin|usr|test|prueba)_" -or ($u.Enabled -eq $true -and -not $u.DisplayName)) { $genericAccountsCount++ }
    }

    $groups = Get-ADGroup -Filter * -Properties Description, GroupScope -ErrorAction Stop
    $totalGroups = $groups.Count
    $groupTypes = $groups | Group-Object GroupScope | Sort-Object Count -Descending

    $ous = Get-ADOrganizationalUnit -Filter * -ErrorAction Stop
    $totalOUs = $ous.Count

    $gpos = Get-GPO -All -ErrorAction Stop
    $totalGPOs = $gpos.Count

    # ------------------------------------------------------------------
    # 2. ESCRITURA DEL RESUMEN
    # ------------------------------------------------------------------
    $HtmlBuilder.AppendLine(@"
        <div class="summary-box">
            <h3>Usuarios:</h3>
            <ul class="summary-list">
                <li>Total de usuarios <span class="metric">$totalUsers</span></li>
                <li>Total de Administradores de Dominio <span class="metric">$domainAdminsCount</span></li>
                <li>Total de Cuentas de servicio <span class="metric">$serviceAccountsCount</span></li>
                <li>Total de Cuentas genericas <span class="metric">$genericAccountsCount</span></li>
            </ul>

            <h3>Grupos:</h3>
            <ul class="summary-list">
                <li>Total de Grupos <span class="metric">$totalGroups</span></li>
"@) | Out-Null
    
    foreach ($type in $groupTypes) {
        $HtmlBuilder.AppendLine("                <li>&nbsp;&nbsp;➥ $($type.Name) <span class=`"metric`">$($type.Count)</span></li>") | Out-Null
    }

    $HtmlBuilder.AppendLine(@"
            </ul>

            <ul class="summary-list" style="margin-top: 25px;">
                <li><h3>Total de OU <span class="metric">$totalOUs</span></h3></li>
                <li><h3>Total de GPO <span class="metric">$totalGPOs</span></h3></li>
            </ul>
        </div>
"@) | Out-Null

    # ------------------------------------------------------------------
    # 3. TABLA DE USUARIOS (AZUL)
    # ------------------------------------------------------------------
    Write-Host "Generando tabla de Usuarios..." -ForegroundColor Cyan
    $HtmlBuilder.AppendLine("<h2 class=`"title-users`">1. Detalle de Usuarios</h2>") | Out-Null
    $HtmlBuilder.AppendLine("<table class=`"table-users`"><tr><th>Nombre</th><th>SamAccountName</th><th>Descripción</th><th>Office</th><th>Estado</th><th>Creación</th><th>Pass. Last Set</th><th>Last Logon</th><th>Pass. Never Exp.</th><th>Grupos</th></tr>") | Out-Null
    
    foreach ($user in $users) {
        $created    = if ($user.Created) { $user.Created.ToString("dd/MM/yyyy") } else { "N/A" }
        $pwdLastSet = if ($user.PasswordLastSet) { $user.PasswordLastSet.ToString("dd/MM/yyyy") } else { "N/A" }
        $lastLogon  = if ($user.LastLogonDate) { $user.LastLogonDate.ToString("dd/MM/yyyy") } else { "N/A" }
        $groupsStr  = if ($user.MemberOf) { ($user.MemberOf -replace '^CN=([^,]+).+$', '$1') -join ', ' } else { "Ninguno" }
        $statusStr  = if ($user.Enabled) { "Activo" } else { "Inactivo" }
        
        $isDomainAdmin = ($user.MemberOf -match "CN=Domain Admins")
        $rowClass = if ($isDomainAdmin) { " class=`"admin-row`"" } else { "" }

        $HtmlBuilder.AppendLine("<tr$rowClass><td>$($user.DisplayName)</td><td>$($user.SamAccountName)</td><td>$($user.Description)</td><td>$($user.Office)</td><td>$statusStr</td><td>$created</td><td>$pwdLastSet</td><td>$lastLogon</td><td>$($user.PasswordNeverExpires)</td><td>$groupsStr</td></tr>") | Out-Null
    }
    $HtmlBuilder.AppendLine("</table>") | Out-Null

    # ------------------------------------------------------------------
    # 4. TABLA DE GRUPOS (VERDE)
    # ------------------------------------------------------------------
    Write-Host "Generando tabla de Grupos..." -ForegroundColor Cyan
    $HtmlBuilder.AppendLine("<h2 class=`"title-groups`">2. Detalle de Grupos</h2>") | Out-Null
    $HtmlBuilder.AppendLine("<table class=`"table-groups`"><tr><th>Nombre</th><th>SamAccountName</th><th>Scope</th><th>Descripción</th></tr>") | Out-Null
    foreach ($group in $groups) {
        $HtmlBuilder.AppendLine("<tr><td>$($group.Name)</td><td>$($group.SamAccountName)</td><td>$($group.GroupScope)</td><td>$($group.Description)</td></tr>") | Out-Null
    }
    $HtmlBuilder.AppendLine("</table>") | Out-Null

    # ------------------------------------------------------------------
    # 5. TABLA DE GPOs (MORADO) - ¡Corregido el error de nombre de propiedad!
    # ------------------------------------------------------------------
    Write-Host "Generando tabla de GPOs..." -ForegroundColor Cyan
    $HtmlBuilder.AppendLine("<h2 class=`"title-gpos`">3. Detalle de GPOs</h2>") | Out-Null
    $HtmlBuilder.AppendLine("<table class=`"table-gpos`"><tr><th>Nombre</th><th>Owner</th><th>Creado</th><th>Modificado</th><th>Auditoría / Estado</th></tr>") | Out-Null
    
    foreach ($gpo in $gpos) {
        $gpoStatusAlert = ""
        
        # Ojo aquí: Propiedad real es CreationTime, no CreatedTime
        if ($null -ne $gpo.CreationTime) { 
            $createdStr = $gpo.CreationTime.ToString('dd/MM/yyyy HH:mm') 
        } else { 
            $createdStr = "N/A"
            $gpoStatusAlert += "<span class=`"alert-gpo`">⚠️ HUÉRFANA / NULA</span> "
        }
        
        # Ojo aquí: Propiedad real es ModificationTime, no ModifiedTime
        $modifiedStr = if ($null -ne $gpo.ModificationTime) { $gpo.ModificationTime.ToString('dd/MM/yyyy HH:mm') } else { "N/A" }

        if ($gpo.GpoStatus -eq "AllSettingsDisabled") {
            $gpoStatusAlert += "[Desactivada]"
        } elseif ($gpo.GpoStatus -ne "AllSettingsEnabled") {
            $gpoStatusAlert += "[Parcial: $($gpo.GpoStatus)]"
        }

        $HtmlBuilder.AppendLine("<tr><td>$($gpo.DisplayName)</td><td>$($gpo.Owner)</td><td>$createdStr</td><td>$modifiedStr</td><td>$gpoStatusAlert</td></tr>") | Out-Null
    }
    $HtmlBuilder.AppendLine("</table>") | Out-Null

    # ------------------------------------------------------------------
    # 6. TABLA VINCULACIÓN OU-GPO (GRIS)
    # ------------------------------------------------------------------
    Write-Host "Generando matriz OU y GPOs..." -ForegroundColor Cyan
    $HtmlBuilder.AppendLine("<h2 class=`"title-ous`">4. Grupos y GPOs Asociadas a OU</h2>") | Out-Null
    $HtmlBuilder.AppendLine("<table class=`"table-ous`"><tr><th>Organizational Unit (OU)</th><th>GPOs Aplicadas Físicamente</th></tr>") | Out-Null
    foreach ($ou in $ous) {
        $linkedGPOs = Get-GPInheritance -Target $ou.DistinguishedName | Select-Object -ExpandProperty GpoLinks
        if ($linkedGPOs) {
            $gpoNames = ($linkedGPOs.DisplayName) -join ", "
            $HtmlBuilder.AppendLine("<tr><td>$($ou.Name)</td><td>$gpoNames</td></tr>") | Out-Null
        }
    }
    $HtmlBuilder.AppendLine("</table>") | Out-Null
}

end {
    # ------------------------------------------------------------------
    # PIE DE PÁGINA
    # ------------------------------------------------------------------
    $HtmlBuilder.AppendLine(@"
        <footer>
            <strong>Programado por: Claudio Aliste Requena</strong><br>
            Ingeniero de Infraestructura TI & Cloud<br><br>
            <em>Generado el: $currentDateTime</em>
        </footer>
    </div> <!-- End Container -->
</body>
</html>
"@) | Out-Null

    Write-Host "Guardando el reporte en disco..." -ForegroundColor Yellow
    try {
        Set-Content -Path $ReportPath -Value $HtmlBuilder.ToString() -Encoding UTF8 -Force
        Write-Host "Auditoría completada exitosamente." -ForegroundColor Green
        Start-Process $ReportPath
    } catch {
        Write-Error "Error guardando HTML: $_"
    }
}
