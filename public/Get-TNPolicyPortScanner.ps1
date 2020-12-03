function Get-TNPolicyPortScanner {
<#
    .SYNOPSIS
        Gets a list of policy port scanners

    .DESCRIPTION
        Gets a list of policy port scanners
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER PolicyId
        The ID of the target policy
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNPolicyPortScanner

        Gets a list of policy port scanners
        
#>
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [switch]$EnableException
    )
    process {
        foreach ($policy in $PolicyId) {
            try {
                $policydetail = Get-TNPolicyDetail -PolicyId $policy
                [pscustomobject]@{
                    PolicyId   = $policy
                    SYNScanner = $policydetail.settings.syn_scanner
                    UDPScanner = $policydetail.settings.udp_scanner
                    TCPScanner = $policydetail.settings.tcp_scanner
                }
            } catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}