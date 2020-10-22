function Get-TNPlugin {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER PluginId
        Parameter description

    .EXAMPLE
        PS> Get-TN

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [int32]$PluginId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if ($PluginId) {
                foreach ($plugin in (Invoke-TNRequest -SessionObject $session -Path "/plugins/plugin/$PluginId" -Method GET)) {
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
                    }
                }
            }
        }
    }
}