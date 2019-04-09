function Enable-AcasPolicyLocalPortEnumeration {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .PARAMETER ScanMethods
    Parameter description

    .PARAMETER VerifyOpenPorts
    Parameter description

    .PARAMETER ScanOnlyIfLocalFails
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
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
        [ValidateSet('WMINetstat', 'SSHNetstat', 'SNMPScanner')]
        [string[]]$ScanMethods,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$VerifyOpenPorts,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$ScanOnlyIfLocalFails,
        [switch]$EnableException
    )

    begin {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        if ($SessionId -notin $sessions) {
            throw "SessionId $($SessionId) is not present in the current sessions."
        }
        $Session = Get-AcasSession -SessionId $SessionId

        $Scanners = @{}
        foreach ($Scanner in $ScanMethods) {
            if ($Scanner -eq 'WMINetstat')
            {$Scanners['wmi_netstat_scanner'] = 'yes'}

            if ($Scanner -eq 'SSHNetstat')
            {$Scanners['ssh_netstat_scanner'] = 'yes'}

            if ($Scanner -eq 'SNMPScanner')
            {$Scanners['snmp_scanner'] = 'yes'}
        }

        if ($VerifyOpenPorts)
        {$Scanners['verify_open_ports'] = 'yes'}

        if ($ScanOnlyIfLocalFails)
        {$Scanners['only_portscan_if_enum_failed'] = 'yes'}

        $Settings = @{'settings' = $Scanners}
        $SettingsJson = ConvertTo-Json -InputObject $Settings -Compress
    }
    process {
        foreach ($PolicyToChange in $PolicyId) {
            $RequestParams = @{
                'SessionObject' = $Session
                'Path'          = "/policies/$($PolicyToChange)"
                'Method'        = 'PUT'
                'ContentType'   = 'application/json'
                'Parameter'     = $SettingsJson
            }

            Invoke-AcasRequest @RequestParams | Out-Null
            Get-AcasPolicyLocalPortEnumeration -SessionId $SessionId -PolicyId $PolicyToChange

        }
    }
}