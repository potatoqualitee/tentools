function Get-AcasPluginRule {
    <#
    .SYNOPSIS
    Gets a list of all Nessus plugin rules

    .DESCRIPTION
    Gets a list of all Nessus plugin rules

    .PARAMETER SessionId
    ID of a valid Nessus session

    .PARAMETER Detail
    Does an additional lookup on each rule, to return the plugin name. Helpfule when reporting

    .EXAMPLE
    Get-AcasPluginRule -SessionId 0
    Gets all defined plugin rules

    .EXAMPLE
    Get-AcasPluginRule -SessionId 0 -Detail
    Gets all defined plugin rules with details

    .OUTPUTS
    Returns a PSObject with basic rule info, or returns PSObject with base info + plugin name
    #>


    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$PluginId,
        [Switch]$Detail

    )

    begin {

        function Limit-PluginRule {
            param
            (
                [Object]
                [Parameter(ValueFromPipeline)]
                $InputObject
            )

            process {
                if ($InputObject.PluginID -eq $PluginId) {
                    $InputObject
                }
            }
        }

        $dicTypeRev = @{
            'recast_critical' = 'Critical'
            'recast_high'     = 'High'
            'recast_medium'   = 'Medium'
            'recast_low'      = 'Low'
            'recast_info'     = 'Info'
            'exclude'         = 'Exclude'
        }

        $collection = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $collection += $connection
                }
            }
        }

        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }

    process {
        foreach ($connection in $collection) {
            $pRules = Invoke-AcasRequest -SessionObject $connection -Path '/plugin-rules' -Method 'Get'

            if ($pRules -is [psobject]) {
                foreach ($pRule in $pRules.plugin_rules) {
                    $dtExpiration = $null

                    If ($pRule.date) {
                        $dtExpiration = $origin.AddSeconds($pRule.date).ToLocalTime()
                    }



                    $pRuleProps = [Ordered]@{}
                    $pRuleProps.add('ID', $pRule.id)
                    $pRuleProps.add('Host', $pRule.host)
                    $pRuleProps.add('PluginId', $pRule.plugin_id)

                    # Significant increase in web requests!
                    If ($Detail) {
                        # Provides the rule name in the returned object
                        $objPluginDetails = Show-AcasPlugin -SessionId $SessionId -PluginId $pRule.plugin_id
                        $pRuleProps.add('Plugin', $objPluginDetails.Name)
                    }

                    $pRuleProps.add('Expiration', $dtExpiration)
                    $pRuleProps.add('Type', $dicTypeRev[$pRule.type])
                    $pRuleProps.add('Owner', $pRule.owner)
                    $pRuleProps.add('Owner_ID', $pRule.owner_id)
                    $pRuleProps.add('Shared', $pRule.shared)
                    $pRuleProps.add('Permissions', $pRule.user_permissions)
                    $pRuleProps.add('SessionId', $connection.SessionId)
                    $pRuleObj = New-Object -TypeName psobject -Property $pRuleProps
                    $pRuleObj.pstypenames[0] = 'Nessus.PluginRules'

                    If ($PluginId) {
                        $pRuleObj | Limit-PluginRule
                    } Else {
                        $pRuleObj
                    }
                }
            }
        }
    }
}