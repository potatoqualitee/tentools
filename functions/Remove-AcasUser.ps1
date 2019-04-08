function Remove-AcasUser {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER UserId
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$UserId
    )

    begin {
        $ToProcess = @()
        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }
    }
    process {
        foreach ($Connection in $ToProcess) {
            foreach ($uid in $UserId) {
                Write-PSFMessage -Level Verbose -Mesage "Deleting user with Id $($uid)"
                InvokeNessusRestRequest -SessionObject $Connection -Path "/users/$($uid)" -Method 'Delete'
            }
        }
    }
}