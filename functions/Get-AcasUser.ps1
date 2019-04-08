function Get-AcasUser {
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
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = @()
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

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

            $Users = InvokeNessusRestRequest -SessionObject $Connection -Path '/users' -Method 'Get'

            if ($Users -is [psobject]) {
                $Users.users | ForEach-Object -process {
                    $UserProperties = [ordered]@{}
                    $UserProperties.Add('Name', $_.name)
                    $UserProperties.Add('UserName', $_.username)
                    $UserProperties.Add('Email', $_.email)
                    $UserProperties.Add('UserId', $_.id)
                    $UserProperties.Add('Type', $_.type)
                    $UserProperties.Add('Permission', $PermissionsId2Name[$_.permissions])
                    $UserProperties.Add('LastLogin', $origin.AddSeconds($_.lastlogin).ToLocalTime())
                    $UserProperties.Add('SessionId', $Connection.SessionId)
                    $UserObj = New-Object -TypeName psobject -Property $UserProperties
                    $UserObj.pstypenames[0] = 'Nessus.User'
                    $UserObj
                }
            }
        }

    }
    end {}
}