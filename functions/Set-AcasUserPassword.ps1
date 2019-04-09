function Set-AcasUserPassword {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER UserId
    Parameter description

    .PARAMETER Password
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
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$UserId,
        [Parameter(Mandatory, Position = 3, ValueFromPipelineByPropertyName)]
        [securestring]$Password
    )

    begin {
        $ToProcess = @()
        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }
    }
    process {
        foreach ($connection in $ToProcess) {
            foreach ($uid in $UserId) {
                Write-PSFMessage -Level Verbose -Mesage "Updating user with Id $($uid)"
                $pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
                $params = @{'password' = $pass}
                $paramJson = ConvertTo-Json -InputObject $params -Compress
                InvokeNessusRestRequest -SessionObject $connection -Path "/users/$($uid)/chpasswd" -Method 'PUT' -Parameter $paramJson -ContentType 'application/json'

            }
        }
    }
}