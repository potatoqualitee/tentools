function Add-TNPluginRule {
    <#
    .SYNOPSIS
        Creates a new Nessus plugin rule

    .DESCRIPTION
        Can be used to alter report output for various reasons. i.e. vulnerability acceptance, verified
        false-positive on non-credentialed scans, alternate mitigation in place, etc...

    .PARAMETER PluginId
        ID number of the plugin which would you like altered

    .PARAMETER ComputerName
        Name, IP address, or Wildcard (*), which defines the the host(s) affected by the rule

    .PARAMETER Type
        Severity level you would like future scan reports to display for the defined host(s)

    .PARAMETER Expiration
        Date/Time object, which defines the time you would like the rule to expire

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Add-TNPluginRule -PluginId 15901 -ComputerName 'WebServer' -Type Critical

        Creates a rule that changes the default severity of 'Medium', to 'Critical' for the defined computer and plugin ID

    .EXAMPLE
        PS> $WebServers | % {Add-TNPluginRule -PluginId 15901 -ComputerName $_ -Type Critical}

        Creates a rule for a list computers, using the defined options
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$PluginId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('IPAddress', 'IP', 'Host')]
        [String]$ComputerName = '*',
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info', 'Exclude')]
        [String]$Type,
        [Parameter(ValueFromPipelineByPropertyName)]
        [datetime]$Expiration,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            $dtExpiration = $null

            If ($Expiration) {
                $dtExpiration = (New-TimeSpan -Start $script:origin -end $Expiration).TotalSeconds.ToInt32($null)
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

            $params = @{
                SessionObject   = $session
                Path            = '/plugin-rules'
                Method          = 'Post'
                Parameter       = $pRuleJson
                ContentType     = 'application/json'
                EnableException = $EnableException
            }

            $null = Invoke-TNRequest @params
            Get-TNPluginRule | Select-Object -Last 1 # probably a bad idea :D
        }
    }
}