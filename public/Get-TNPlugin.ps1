function Get-TNPlugin {
    <#
    .SYNOPSIS
        Gets a list of plugins

    .DESCRIPTION
        Gets a list of plugins

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PluginId
        The ID of the target plugin

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNPlugin -PluginId 10

        Gets the plugin with the id of 10

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [int32]$PluginId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if ($PluginId) {
                foreach ($plugin in (Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/plugins/plugin/$PluginId" -Method GET)) {
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