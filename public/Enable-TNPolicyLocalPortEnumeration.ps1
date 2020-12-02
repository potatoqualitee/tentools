function Enable-TNPolicyLocalPortEnumeration {
<#
    .SYNOPSIS
        Enables a list of policy local port enumerations

    .DESCRIPTION
        Enables a list of policy local port enumerations
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER PolicyId
        The ID of the target policy
        
    .PARAMETER ScanMethods
        Description for ScanMethods
        
    .PARAMETER VerifyOpenPorts
        Description for VerifyOpenPorts
        
    .PARAMETER ScanOnlyIfLocalFails
        Description for ScanOnlyIfLocalFails
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Enable-TNPolicyLocalPortEnumeration

        Enables a list of policy local port enumerations
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
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
            { $scanners['wmi_netstat_scanner'] = 'yes' }

            if ($scanner -eq 'SSHNetstat')
            { $scanners['ssh_netstat_scanner'] = 'yes' }

            if ($scanner -eq 'SNMPScanner')
            { $scanners['snmp_scanner'] = 'yes' }
        }

        if ($VerifyOpenPorts)
        { $scanners['verify_open_ports'] = 'yes' }

        if ($ScanOnlyIfLocalFails)
        { $scanners['only_portscan_if_enum_failed'] = 'yes' }

        $Settings = @{settings = $scanners }
        $SettingsJson = ConvertTo-Json -InputObject $Settings -Compress
    }
    process {
        foreach ($session in $SessionObject) {
            foreach ($policy in $PolicyId) {
                $params = @{
                    SessionObject   = $session
                    Path            = "/policies/$policy"
                    Method          = 'PUT'
                    ContentType     = 'application/json'
                    Parameter       = $SettingsJson
                    EnableException = $EnableException
                }

                $null = Invoke-TNRequest @params
                Get-TNPolicyLocalPortEnumeration -PolicyId $policy
            }
        }
    }
}