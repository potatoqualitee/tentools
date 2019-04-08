function Get-AcasPolicyLocalPortEnumeration {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32]
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32[]]
        $PolicyId
    )

    begin {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        if ($SessionId -notin $sessions) {
            throw "SessionId $($SessionId) is not present in the current sessions."
        }
        $Session = Get-AcasSession -SessionId $SessionId
    }
    process {
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
            } catch {
                throw $_
            }

        }
    }
    end {
    }
}