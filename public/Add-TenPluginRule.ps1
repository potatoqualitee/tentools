function Add-TenPluginRule {
    <#
    .SYNOPSIS
        Creates a new Nessus plugin rule

    .DESCRIPTION
        Can be used to alter report output for various reasons. i.e. vulnerability acceptance, verified
        false-positive on non-credentialed scans, alternate mitigation in place, etc...

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenService.

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
        PS> Add-TenPluginRule -SessionId 0 -PluginId 15901 -ComputerName 'WebServer' -Type Critical

        Creates a rule that changes the default severity of 'Medium', to 'Critical' for the defined computer and plugin ID

    .EXAMPLE
        PS> $WebServers | % {Add-TenPluginRule -SessionId 0 -PluginId 15901 -ComputerName $_ -Type Critical}

        Creates a rule for a list computers, using the defined options
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$PluginId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [Alias('IPAddress', 'IP', 'Host')]
        [String]$ComputerName = '*',
        [Parameter(Mandatory, Position = 3, ValueFromPipelineByPropertyName)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info', 'Exclude')]
        [String]$Type,
        [Parameter(Position = 4, ValueFromPipelineByPropertyName)]
        [datetime]$Expiration,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {

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

            $params = @{
                SessionObject   = $session
                Path            = '/plugin-rules'
                Method          = 'Post'
                Parameter       = $pRuleJson
                ContentType     = 'application/json'
                EnableException = $EnableException
            }

            Invoke-TenRequest @params
        }
    }
}