function Get-TenPluginRule {
    <#
    .SYNOPSIS
        Gets a list of all Nessus plugin rules

    .DESCRIPTION
        Gets a list of all Nessus plugin rules

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenService.

    .PARAMETER Detail
        Does an additional lookup on each rule, to return the plugin name. Helpfule when reporting

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TenPluginRule -SessionId 0
        Gets all defined plugin rules

    .EXAMPLE
        PS> Get-TenPluginRule -SessionId 0 -Detail
        Gets all defined plugin rules with details

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
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
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            $rules = Invoke-TenRequest -SessionObject $session -Path '/plugin-rules' -Method 'Get'

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
                    $plugin = (Get-TenPlugin -SessionId $session.SessionId -PluginId $rule.plugin_id).Name
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
                } | Select-DefaultView -ExcludeProperty SessionId
            }
        }
    }
}