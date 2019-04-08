function Copy-AcasPolicy {
    <#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER SessionId
Parameter description

.PARAMETER PolicyId
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
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PolicyId

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
            $CopiedPolicy = InvokeNessusRestRequest -SessionObject $Connection -Path "/policies/$($PolicyId)/copy" -Method 'Post'
            $PolProp = [ordered]@{}
            $PolProp.Add('Name', $CopiedPolicy.name)
            $PolProp.Add('PolicyId', $CopiedPolicy.id)
            $PolProp.Add('SessionId', $Connection.SessionId)
            $CopiedObj = [PSCustomObject]$PolProp
            $CopiedObj.pstypenames.insert(0, 'Nessus.PolicyCopy')
            $CopiedObj
        }
    }
    end {
    }
}