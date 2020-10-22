function Disable-TNPolicyLocalPortEnumeration {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER ScanMethods
        Parameter description

    .PARAMETER VerifyOpenPorts
        Parameter description

    .PARAMETER ScanOnlyIfLocalFails
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('WMINetstat', 'SSHNetstat', 'SNMPScanner')]
        [string[]]$ScanMethods,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$VerifyOpenPorts,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$ScanOnlyIfLocalFails,
        [switch]$EnableException
    )

    begin {
        $scanners = @{ }
        foreach ($scanner in $ScanMethods) {
            if ($scanner -eq 'WMINetstat')
            { $scanners['wmi_netstat_scanner'] = 'no' }

            if ($scanner -eq 'SSHNetstat')
            { $scanners['ssh_netstat_scanner'] = 'no' }

            if ($scanner -eq 'SNMPScanner')
            { $scanners['snmp_scanner'] = 'no' }
        }

        if ($VerifyOpenPorts)
        { $scanners['verify_open_ports'] = 'no' }

        if ($ScanOnlyIfLocalFails)
        { $scanners['only_portscan_if_enum_failed'] = 'no' }

        $settings = @{settings = $scanners }
        $settingsJson = ConvertTo-Json -InputObject $settings -Compress
    }
    process {
        foreach ($session in (Get-TNSession)) {
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
                Get-TNPolicyLocalPortEnumeration -PolicyId $policy
            }
        }
    }
}