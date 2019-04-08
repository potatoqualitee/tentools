function New-AcasFolder {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER SessionId
    Parameter description
    
    .PARAMETER Name
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
        [string]
        $Name
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
            $Folder = InvokeNessusRestRequest -SessionObject $Connection -Path '/folders' -Method 'Post' -Parameter @{'name' = $Name}

            if ($Folder -is [psobject]) {
                Get-AcasFolder -SessionId $Connection.sessionid | Where-Object {
                    $_.FolderId -eq $Folder.id
                }
            }
        }
    }
}