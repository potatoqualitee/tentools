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
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        # Nessus User Id
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32[]]
        $UserId,

        [Parameter(Mandatory = $true,
            Position = 3,
            ValueFromPipelineByPropertyName = $true)]
        [securestring]
        $Password
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
                Write-Verbose -Message "Updating user with Id $($uid)"
                $pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
                $params = @{'password' = $pass}
                $paramJson = ConvertTo-Json -InputObject $params -Compress
                InvokeNessusRestRequest -SessionObject $Connection -Path "/users/$($uid)/chpasswd" -Method 'PUT' -Parameter $paramJson -ContentType 'application/json'

            }
        }
    }
}