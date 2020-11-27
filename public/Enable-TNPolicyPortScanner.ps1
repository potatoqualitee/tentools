function Enable-TNPolicyPortScanner {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER ScanMethods
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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

        foreach ($session in $SessionObject) {
            foreach ($policy in $PolicyId) {
                $params = @{
                    SessionObject   = $session
                    Path            = "/policies/$policy"
                    Method          = 'PUT'
                    ContentType     = 'application/json'
                    Parameter       = $settingsJson
                    EnableException = $EnableException
                }

                $null = Invoke-TNRequest @params
                Get-TNPolicyPortScanner -PolicyId $policy
            }
        }
    }
}