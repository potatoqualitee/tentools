function Get-TNPolicyLocalPortEnumeration {
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
        PS> Get-TN
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
        foreach ($session in (Get-TNSession)) {
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
                    }
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}