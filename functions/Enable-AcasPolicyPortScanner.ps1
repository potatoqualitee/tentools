function Enable-AcasPolicyPortScanner {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .PARAMETER ScanMethods
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
        [int32[]]$PolicyId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [ValidateSet('TCP', 'SYN', 'UDP')]
        [string[]]$ScanMethods
    )
    begin {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        if ($SessionId -notin $sessions) {
            Stop-PSFFunction -Message "SessionId $($SessionId) is not present in the current sessions."
            return
        }
        $Session = Get-AcasSession -SessionId $SessionId

        $Scanners = @{}
        foreach ($Scanner in $ScanMethods) {
            if ($Scanner -eq 'TCP')
            {$Scanners['tcp_scanner'] = 'yes'}

            if ($Scanner -eq 'UDP')
            {$Scanners['udp_scanner'] = 'yes'}

            if ($Scanner -eq 'SYN')
            {$Scanners['syn_scanner'] = 'yes'}
        }

        $Settings = @{'settings' = $Scanners}
        $SettingsJson = ConvertTo-Json -InputObject $Settings -Compress
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }
        foreach ($PolicyToChange in $PolicyId) {
            $RequestParams = @{
                'SessionObject' = $Session
                'Path'          = "/policies/$($PolicyToChange)"
                'Method'        = 'PUT'
                'ContentType'   = 'application/json'
                'Parameter'     = $SettingsJson
            }

            Invoke-AcasRequest @RequestParams | Out-Null
            Get-AcasPolicyPortScanner -SessionId $SessionId -PolicyId $PolicyToChange

        }
    }
}