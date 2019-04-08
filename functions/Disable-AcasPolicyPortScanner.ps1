function Disable-AcasPolicyPortScanner {
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
        $PolicyId,

        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('TCP', 'SYN', 'UDP')]
        [string[]]
        $ScanMethods
    )

    begin {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        if ($SessionId -notin $sessions) {
            throw "SessionId $($SessionId) is not present in the current sessions."
        }
        $Session = Get-AcasSession -SessionId $SessionId

        $Scanners = @{}
        foreach ($Scanner in $ScanMethods) {
            if ($Scanner -eq 'TCP')
            {$Scanners['tcp_scanner'] = 'no'}

            if ($Scanner -eq 'UDP')
            {$Scanners['udp_scanner'] = 'no'}

            if ($Scanner -eq 'SYN')
            {$Scanners['syn_scanner'] = 'no'}
        }

        $Settings = @{'settings' = $Scanners}
        $SettingsJson = ConvertTo-Json -InputObject $Settings -Compress
    }
    process {
        foreach ($PolicyToChange in $PolicyId) {
            $RequestParams = @{
                'SessionObject' = $Session
                'Path'          = "/policies/$($PolicyToChange)"
                'Method'        = 'PUT'
                'ContentType'   = 'application/json'
                'Parameter'     = $SettingsJson
            }

            InvokeNessusRestRequest @RequestParams | Out-Null
            Get-AcasPolicyPortScanner -SessionId $SessionId -PolicyId $PolicyToChange

        }
    }
    end {
    }
}