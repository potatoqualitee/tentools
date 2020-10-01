function Get-TenPlugin {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER PluginId
        Parameter description

    .EXAMPLE
        PS> Get-Ten

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, Mandatory)]
        [int32]$PluginId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            foreach ($plugin in (Invoke-TenRequest -SessionObject $session -Path "/plugins/plugin/$PluginId" -Method 'Get')) {
                $attributes = [ordered]@{ }
                foreach ($attribute in $plugin.attributes) {
                    # Some attributes have multiple values, i.e. osvdb. This causes errors when adding duplicates
                    if ($attributes.Keys -contains $attribute.attribute_name) {
                        $attributes[$attribute.attribute_name] += ", $($attribute.attribute_value)"
                    } else {
                        $attributes.add("$($attribute.attribute_name)", "$($attribute.attribute_value)")
                    }
                }
                [pscustomobject]@{
                    Name       = $plugin.name
                    PluginId   = $plugin.id
                    FamilyName = $plugin.family_name
                    Attributes = $attributes
                    SessionId  = $session.SessionId
                } | Select-DefaultView -Property Name, PluginId, FamilyName, Attributes
            }

            if ($PluginId) {
                foreach ($plugin in (Invoke-TenRequest -SessionObject $session -Path "/plugins/plugin/$($PluginId)" -Method 'Get')) {
                    $attributes = [ordered]@{ }
                    foreach ($attribute in $plugin.attributes) {
                        # Some attributes have multiple values, i.e. osvdb. This causes errors when adding duplicates
                        if ($attributes.Keys -contains $attribute.attribute_name) {
                            $attributes[$attribute.attribute_name] += ", $($attribute.attribute_value)"
                        } else {
                            $attributes.add("$($attribute.attribute_name)", "$($attribute.attribute_value)")
                        }
                    }
                    [pscustomobject]@{
                        Name       = $plugin.name
                        PluginId   = $plugin.id
                        FamilyName = $plugin.family_name
                        Attributes = $attributes
                        SessionId  = $session.SessionId
                    }
                }
            }
        }
    }
}