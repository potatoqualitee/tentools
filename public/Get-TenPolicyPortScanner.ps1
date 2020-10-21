function Get-TenPolicyPortScanner {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER PolicyId
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [switch]$EnableException
    )
    process {
        foreach ($policy in $PolicyId) {
            try {
                $policydetail = Get-TenPolicyDetail -PolicyId $policy
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