function Get-TNPolicyPortRange {
    <#
    .SYNOPSIS
        Gets a list of policy port ranges

    .DESCRIPTION
        Gets a list of policy port ranges

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNPolicyPortRange -PolicyID 10, 11

        Gets a list of policy port ranges fpr policies with ID of 10 and 11

#>
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32[]]$PolicyId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            foreach ($policy in $PolicyId) {
                try {
                    $policydetail = Get-TNPolicyDetail -PolicyId $policy
                    if ($policydetail.settings) {
                        if ($policydetail.settings.portscan_range) {
                            [pscustomobject]@{
                                Name      = $policydetail.name
                                PolicyId  = $policy
                                PortRange = $policydetail.settings.portscan_range
                            } | ConvertFrom-TNRestResponse
                        } else {
                            # i feel like i'm doing this wrong
                            $port = (($policydetail.settings.discovery.groups | Where-Object name -eq network_discovery).sections.inputs | Where-Object id -eq portscan_range).default
                            [pscustomobject]@{
                                Name      = $policydetail.name
                                PolicyId  = $policy
                                PortRange = $port
                            } | ConvertFrom-TNRestResponse
                        }
                    } else {
                        [pscustomobject]@{
                            Name      = $policydetail.name
                            PolicyId  = $policy
                            PortRange = $policydetail.preferences.portscan_range
                        } | ConvertFrom-TNRestResponse
                    }
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}