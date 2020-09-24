function Enable-TenPolicyPortScanner {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER ScanMethods
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Ten
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
        [string[]]$ScanMethods,
        [switch]$EnableException
    )
    begin {
        $scanners = @{ }
        foreach ($scanner in $ScanMethods) {
            if ($scanner -eq 'TCP')
            { $scanners['tcp_scanner'] = 'yes' }

            if ($scanner -eq 'UDP')
            { $scanners['udp_scanner'] = 'yes' }

            if ($scanner -eq 'SYN')
            { $scanners['syn_scanner'] = 'yes' }
        }

        $settings = @{settings = $scanners }
        $settingsJson = ConvertTo-Json -InputObject $settings -Compress
    }
    process {

        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            foreach ($policy in $PolicyId) {
                $params = @{
                    SessionObject   = $session
                    Path            = "/policies/$($policy)"
                    Method          = 'PUT'
                    ContentType     = 'application/json'
                    Parameter       = $settingsJson
                    EnableException = $EnableException
                }

                $null = Invoke-TenRequest @params
                Get-TenPolicyPortScanner -SessionId $session.SessionId -PolicyId $policy
            }
        }
    }
}