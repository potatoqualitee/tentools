function Disable-TNPolicyPortScanner {
<#
    .SYNOPSIS
        Disables a list of policy port scanners

    .DESCRIPTION
        Disables a list of policy port scanners
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER PolicyId
        The ID of the target policy
        
    .PARAMETER ScanMethods
        Description for ScanMethods
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Disable-TNPolicyPortScanner

        Disables a list of policy port scanners
        
#>
    [CmdletBinding()]
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
            { $scanners['tcp_scanner'] = 'no' }

            if ($scanner -eq 'UDP')
            { $scanners['udp_scanner'] = 'no' }

            if ($scanner -eq 'SYN')
            { $scanners['syn_scanner'] = 'no' }
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