function Get-AcasPluginFamily {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER SessionId
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId = @()
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
            $Families = InvokeNessusRestRequest -SessionObject $Connection -Path '/plugins/families' -Method 'Get'
            if ($Families -is [Object[]]) {
                foreach ($Family in $Families) {
                    $FamilyProps = [ordered]@{}
                    $FamilyProps.add('Name', $Family.name)
                    $FamilyProps.add('Id', $Family.id)
                    $FamilyProps.add('Count', $Family.count)
                    $FamilyObj = New-Object -TypeName psobject -Property $FamilyProps
                    $FamilyObj.pstypenames[0] = 'Nessus.PluginFamily'
                    $FamilyObj

                }
            }
        }
    }
    end {
    }
}