﻿function Edit-TNPluginRule {
    <#
    .SYNOPSIS
        Edits a list of plugin rules

    .DESCRIPTION
        Edits a list of plugin rules

        Can be used to change a previously defined, scan report altering rule

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Id
        Description for Id

    .PARAMETER PluginId
        The ID of the target plugin

    .PARAMETER ComputerName
        Name, IP address, or Wildcard (*), which defines the the host(s) affected by the rule

    .PARAMETER Type
        The type of plugin rule

    .PARAMETER Expiration
        Description for Expiration

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Edit-TNPluginRule -Id 500 -ComputerName 'YourComputer' -Expiration (([datetime]::Now).AddDays(10)) -Type Low

        Will edit a plugin rule with an ID of 500, to have a new computer name. Rule expires in 10 days

    .EXAMPLE
        PS C:\> Get-TNPluginRule | Edit-TNPluginRule -Type Info

        Will alter all rules to now have a serverity of 'Info'

    .EXAMPLE
        PS C:\> Get-TNPluginRule | ? {$_.Host -eq 'myComputer'} | Edit-TNPluginRule -Type 'High'

        Will find all plugin rules that match the computer name, and set their severity to high
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$Id,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$PluginId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('IPAddress', 'IP', 'Host')]
        [String]$ComputerName = '*',
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info', 'Exclude')]
        [String]$Type,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Object]$Expiration, #TODO: Validate the Expiration date, but still allow nulls
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session

            $dtExpiration = $null

            If ($Expiration) {
                $dtExpiration = (New-TimeSpan -Start $origin -end $Expiration -ErrorAction SilentlyContinue).TotalSeconds.ToInt32($null)
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
            }

            If ($dtExpiration) {
                $pRulehash.Add('date', $dtExpiration)
            }

            $pRuleJson = ConvertTo-Json -InputObject $pRulehash -Compress

            $params = @{
                SessionObject   = $session
                Path            = ('/plugin-rules/{0}' -f $Id)
                Method          = 'Put'
                Parameter       = $pRuleJson
                ContentType     = "application/json"
                EnableException = $EnableException
            }

            Invoke-TNRequest @params
        }
    }
}