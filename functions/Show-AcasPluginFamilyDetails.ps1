function Show-AcasPluginFamilyDetails {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER FamilyId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int]$FamilyId
    )
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }

        foreach ($connection in $ToProcess) {
            $FamilyDetails = InvokeNessusRestRequest -SessionObject $connection -Path "/plugins/families/$($FamilyId)" -Method 'Get'
            if ($FamilyDetails -is [Object]) {
                $DetailProps = [ordered]@{}
                $DetailProps.Add('Name', $FamilyDetails.name)
                $DetailProps.Add('FamilyId', $FamilyDetails.id)
                $DetailProps.Add('Plugins', $FamilyDetails.plugins)
                $FamilyObj = New-Object -TypeName psobject -Property $DetailProps
                $FamilyObj.pstypenames[0] = 'Nessus.PluginFamilyDetails'
                $FamilyObj
            }
        }
    }
}