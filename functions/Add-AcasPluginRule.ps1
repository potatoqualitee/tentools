function Add-AcasPluginRule {
    <#
            .SYNOPSIS
            Creates a new Nessus plugin rule

            .DESCRIPTION
            Can be used to alter report output for various reasons. i.e. vulnerability acceptance, verified
            false-positive on non-credentialed scans, alternate mitigation in place, etc...

            .PARAMETER SessionId
            ID of a valid Nessus session

            .PARAMETER PluginId
            ID number of the plugin which would you like altered

            .PARAMETER ComputerName
            Name, IP address, or Wildcard (*), which defines the the host(s) affected by the rule

            .PARAMETER Type
            Severity level you would like future scan reports to display for the defined host(s)

            .PARAMETER Expiration
            Date/Time object, which defines the time you would like the rule to expire

            .EXAMPLE
            Add-AcasPluginRule -SessionId 0 -PluginId 15901 -ComputerName 'WebServer' -Type Critical
            Creates a rule that changes the default severity of 'Medium', to 'Critical' for the defined computer and plugin ID

            .EXAMPLE
            $WebServers | % {Add-AcasPluginRule -SessionId 0 -PluginId 15901 -ComputerName $_ -Type Critical}
            Creates a rule for a list computers, using the defined options
    #>
    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true, Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true, Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PluginId,

        [Parameter(Mandatory = $false, Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('IPAddress', 'IP', 'Host')]
        [String]
        $ComputerName = '*',

        [Parameter(Mandatory = $true, Position = 3,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info', 'Exclude')]
        [String]
        $Type,

        [Parameter(Mandatory = $false, Position = 4,
            ValueFromPipelineByPropertyName = $true)]
        [datetime]
        $Expiration
    )

    begin {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }

    process {
        foreach ($Connection in $ToProcess) {
            $dtExpiration = $null

            If ($Expiration) {

                $dtExpiration = (New-TimeSpan -Start $origin -end $Expiration).TotalSeconds.ToInt32($null)
            }

            $dicType = @{
                'Critical' = 'recast_critical'
                'High'     = 'recast_high'
                'Medium'   = 'recast_medium'
                'Low'      = 'recast_low'
                'Info'     = 'recast_info'
                'Exclude'  = 'exclude'
            }

            $strType = $dicType[$Type]

            $pRulehash = @{
                'plugin_id' = $PluginId
                'host'      = $ComputerName
                'type'      = $strType
                'date'      = $dtExpiration
            }

            $pRuleJson = ConvertTo-Json -InputObject $pRulehash -Compress

            InvokeNessusRestRequest -SessionObject $Connection -Path '/plugin-rules' -Method 'Post' `
                -Parameter $pRuleJson -ContentType 'application/json'
        }
    }
}