function Get-TNPluginRule {
<#
    .SYNOPSIS
        Gets a list of plugin rules

    .DESCRIPTION
        Gets a list of plugin rules
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER PluginId
        The ID of the target plugin
        
    .PARAMETER Detail
        Description for Detail
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNPluginRule

        Gets a list of plugin rules
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName)]
        [int32[]]$PluginId,
        [Switch]$Detail,
        [switch]$EnableException
    )

    begin {
        $dicTypeRev = @{
            'recast_critical' = 'Critical'
            'recast_high'     = 'High'
            'recast_medium'   = 'Medium'
            'recast_low'      = 'Low'
            'recast_info'     = 'Info'
            'exclude'         = 'Exclude'
        }
    }

    process {
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }

            $rules = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/plugin-rules' -Method GET

            foreach ($rule in $rules.plugin_rules) {
                if ($PSBoundParameters.PluginId -and ($rule.plugin_id -notin $PluginId)) {
                    continue
                }
                $dtExpiration = $null

                If ($rule.date) {
                    $dtExpiration = $origin.AddSeconds($rule.date).ToLocalTime()
                }

                If ($Detail) {
                    # Significant increase in web requests!
                    # Provides the rule name in the returned object
                    $plugin = (Get-TNPlugin -SessionId $session.SessionId -PluginId $rule.plugin_id).Name
                } else {
                    $plugin = $null
                }

                [pscustomobject]@{
                    Id          = $rule.id
                    Host        = $rule.host
                    PluginId    = $rule.plugin_id
                    Expiration  = $dtExpiration
                    Type        = $dicTypeRev[$rule.type]
                    Owner       = $rule.owner
                    Owner_ID    = $rule.owner_id
                    Shared      = $rule.shared
                    Permissions = $rule.user_permissions
                    Plugin      = $plugin
                    SessionId   = $session.SessionId
                }
            }
        }
    }
}