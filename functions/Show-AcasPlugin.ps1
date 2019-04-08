function Show-AcasPlugin {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER SessionId
Parameter description

.PARAMETER PluginId
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

    [CmdletBinding()]
    Param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PluginId
    )
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        foreach ($Connection in $ToProcess) {
            $Plugin = InvokeNessusRestRequest -SessionObject $Connection -Path "/plugins/plugin/$($PluginId)" -Method 'Get'

            if ($Plugin -is [psobject]) {
                if ($Plugin.name -ne $null) {
                    # Parse Attributes
                    $Attributes = [ordered]@{}

                    foreach ($Attribute in $Plugin.attributes) {
                        # Some attributes have multiple values, i.e. osvdb. This causes errors when adding duplicates
                        If ($Attributes.Keys -contains $Attribute.attribute_name) {
                            $Attributes[$Attribute.attribute_name] += ", $($Attribute.attribute_value)"
                        }
                        Else {
                            $Attributes.add("$($Attribute.attribute_name)", "$($Attribute.attribute_value)")
                        }
                    }
                    $PluginProps = [ordered]@{}
                    $PluginProps.Add('Name', $Plugin.name)
                    $PluginProps.Add('PluginId', $Plugin.id)
                    $PluginProps.Add('FamilyName', $Plugin.family_name)
                    $PluginProps.Add('Attributes', $Attributes)
                    $PluginProps.Add('SessionId', $Connection.SessionId)
                    $PluginObj = New-Object -TypeName psobject -Property $PluginProps
                    $PluginObj.pstypenames[0] = 'Nessus.Plugin'
                    $PluginObj
                }

            }
        }
    }
}