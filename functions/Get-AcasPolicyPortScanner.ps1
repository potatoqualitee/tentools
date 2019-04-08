function Get-AcasPolicyPortScanner {
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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId
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
                    'PolicyId'   = $PolicyToChange
                    'SYNScanner' = $Policy.settings.syn_scanner
                    'UDPScanner' = $Policy.settings.udp_scanner
                    'TCPScanner' = $Policy.settings.tcp_scanner
                }
                $PolSettingsObj = [PSCustomObject]$UpdateProps
                $PolSettingsObj.pstypenames.insert(0, 'Nessus.PolicySetting')
                $PolSettingsObj
            } catch {
                Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}