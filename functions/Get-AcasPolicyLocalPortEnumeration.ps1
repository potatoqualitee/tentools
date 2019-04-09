function Get-AcasPolicyLocalPortEnumeration {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [switch]$EnableException
    )

    process {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        foreach ($id in $SessionId) {
            if ($id -notin $sessions) {
                Stop-PSFFunction -Message "SessionId $($id) is not present in the current sessions."
            }
       
            $Session = Get-AcasSession -SessionId $id

            foreach ($PolicyToChange in $PolicyId) {
                try {
                    $Policy = Get-AcasPolicyDetail -SessionId $Session.SessionId -PolicyId $PolicyToChange
                    $UpdateProps = [ordered]@{
                        'PolicyId'             = $PolicyToChange
                        'WMINetstat'           = $Policy.settings.wmi_netstat_scanner
                        'SSHNetstat'           = $Policy.settings.ssh_netstat_scanner
                        'SNMPScanner'          = $Policy.settings.snmp_scanner
                        'VerifyOpenPorts'      = $Policy.settings.verify_open_ports
                        'ScanOnlyIfLocalFails' = $Policy.settings.only_portscan_if_enum_failed
                    }
                    $PolSettingsObj = [PSCustomObject]$UpdateProps
                    $PolSettingsObj.pstypenames.insert(0, 'Nessus.PolicySetting')
                    $PolSettingsObj
                }
                catch {
                    Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}