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
        [int]
        $FamilyId
    )

    begin {
    }
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
            $FamilyDetails = InvokeNessusRestRequest -SessionObject $Connection -Path "/plugins/families/$($FamilyId)" -Method 'Get'
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