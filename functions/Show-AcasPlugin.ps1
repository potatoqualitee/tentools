function Show-AcasPlugin {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER PluginId
        Parameter description

    .EXAMPLE
        PS> Get-Acas

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$PluginId,
        [switch]$EnableException
    )
    process {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $connection
                }
            }
        }

        foreach ($connection in $collection) {
            $Plugin = Invoke-AcasRequest -SessionObject $connection -Path "/plugins/plugin/$($PluginId)" -Method 'Get'

            if ($Plugin -is [psobject]) {
                if ($Plugin.name -ne $null) {
                    # Parse Attributes
                    $Attributes = [ordered]@{}

                    foreach ($Attribute in $Plugin.attributes) {
                        # Some attributes have multiple values, i.e. osvdb. This causes errors when adding duplicates
                        If ($Attributes.Keys -contains $Attribute.attribute_name) {
                            $Attributes[$Attribute.attribute_name] += ", $($Attribute.attribute_value)"
                        } Else {
                            $Attributes.add("$($Attribute.attribute_name)", "$($Attribute.attribute_value)")
                        }
                    }
                    $PluginProps = [ordered]@{}
                    $PluginProps.Add('Name', $Plugin.name)
                    $PluginProps.Add('PluginId', $Plugin.id)
                    $PluginProps.Add('FamilyName', $Plugin.family_name)
                    $PluginProps.Add('Attributes', $Attributes)
                    $PluginProps.Add('SessionId', $connection.SessionId)
                    $PluginObj = New-Object -TypeName psobject -Property $PluginProps
                    $PluginObj.pstypenames[0] = 'Nessus.Plugin'
                    $PluginObj
                }
            }
        }
    }
}