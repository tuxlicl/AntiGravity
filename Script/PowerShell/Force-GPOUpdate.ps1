<#
.SYNOPSIS
    Forces a Group Policy update on a list of remote computers or members of an AD Group.

.DESCRIPTION
    This script uses Invoke-GPUpdate to trigger a GPO update on multiple target servers within the vialactea.local domain.
    It can target specific computers or all computer members of a given Active Directory group.

.PARAMETER ComputerNames
    An array of computer names to target for the GPO update.

.PARAMETER GroupName
    The name of the AD Group whose computer members will be targeted.

.PARAMETER GPOName
    The name of the specific GPO you are targeting (used for logging and verification).

.PARAMETER Credential
    The domain admin credentials to use for the operation.

.EXAMPLE
    .\Force-GPOUpdate.ps1 -GroupName "Servers-Critical-Updates" -GPOName "Vialactea-Security-Hardening"
#>

[CmdletBinding(DefaultParameterSetName = "Manual")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Manual", HelpMessage = "Lista de nombres de servidores (ej. SRV01, SRV02)")]
    [string[]]$ComputerNames,

    [Parameter(Mandatory = $true, ParameterSetName = "ADGroup", HelpMessage = "Nombre del grupo de AD que contiene los equipos")]
    [string]$GroupName,

    [Parameter(Mandatory = $false, HelpMessage = "Nombre de la GPO específica a la que se hace referencia")]
    [string]$GPOName,

    [Parameter(Mandatory = $false)]
    [pscredential]$Credential
)

process {
    # Si no se proveen credenciales, se solicitan de forma segura
    if (-not $PSBoundParameters.ContainsKey('Credential')) {
        Write-Verbose "Solicitando credenciales de Domain Admin..."
        $Credential = Get-Credential -Message "Por favor, ingrese las credenciales de Domain Admin para vialactea.local"
    }

    # Verificar módulo de Active Directory si se usa GroupName
    if ($PSCmdlet.ParameterSetName -eq "ADGroup") {
        if (-not (Get-Module -ListAvailable ActiveDirectory)) {
            throw "El módulo de PowerShell 'ActiveDirectory' es necesario para buscar grupos."
        }
        
        Write-Host "Buscando miembros del grupo: $GroupName..." -ForegroundColor Cyan
        try {
            $groupMembers = Get-ADGroupMember -Identity $GroupName -Recursive -Credential $Credential | Where-Object { $_.objectClass -eq "computer" }
            if (-not $groupMembers) {
                Write-Warning "No se encontraron equipos en el grupo '$GroupName'."
                return
            }
            $ComputerNames = $groupMembers.Name
            Write-Host "Se encontraron $($ComputerNames.Count) equipos en el grupo." -ForegroundColor Green
        }
        catch {
            throw "Error al buscar el grupo '$GroupName': $($_.Exception.Message)"
        }
    }

    if ($GPOName) {
        Write-Host "Objetivo: Forzar aplicación de GPO '$GPOName'" -ForegroundColor Yellow
    }

    $results = foreach ($computer in $ComputerNames) {
        Write-Host "Iniciando GPO Update en: $computer..." -ForegroundColor Cyan
        
        try {
            # Se usa Invoke-GPUpdate que es el estándar moderno para forzar actualizaciones remotas
            Invoke-GPUpdate -Computer $computer -Force -ErrorAction Stop
            
            Write-Host "[OK] Actualización enviada exitosamente a $computer" -ForegroundColor Green
            [PSCustomObject]@{
                ComputerName = $computer
                Status       = "Success"
                Timestamp    = Get-Date
                Error        = $null
            }
        }
        catch {
            Write-Warning "Fallo al actualizar GPO en ${computer}: $($_.Exception.Message)"
            [PSCustomObject]@{
                ComputerName = $computer
                Status       = "Failed"
                Timestamp    = Get-Date
                Error        = $_.Exception.Message
            }
        }
    }

    # Mostrar resumen
    Write-Host "`n--- Resumen de Operación ---" -ForegroundColor Yellow
    if ($GPOName) { Write-Host "GPO Referenciada: $GPOName" }
    if ($GroupName) { Write-Host "Grupo de AD: $GroupName" }
    
    $results | Format-Table -AutoSize
}
