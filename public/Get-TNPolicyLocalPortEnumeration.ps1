function Get-TNPolicyLocalPortEnumeration {
    <#
    .SYNOPSIS
        Gets a list of policy local port enumerations

    .DESCRIPTION
        Gets a list of policy local port enumerations

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNPolicyLocalPortEnumeration -PolicyId 10

        Gets a list of policy local port enumerations for the policy with ID 10

#>
    [CmdletBinding()]
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
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            foreach ($policy in $PolicyId) {
                try {
                    $policydetail = Get-TNPolicyDetail -PolicyId $policy
                    [pscustomobject]@{
                        PolicyId             = $policy
                        WMINetstat           = $policydetail.settings.wmi_netstat_scanner
                        SSHNetstat           = $policydetail.settings.ssh_netstat_scanner
                        SNMPScanner          = $policydetail.settings.snmp_scanner
                        VerifyOpenPorts      = $policydetail.settings.verify_open_ports
                        ScanOnlyIfLocalFails = $policydetail.settings.only_portscan_if_enum_failed
                    } | ConvertFrom-TNRestResponse
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}