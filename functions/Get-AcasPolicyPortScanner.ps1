function Get-AcasPolicyPortScanner {
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
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [switch]$EnableException
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
            }
            catch {
                Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}