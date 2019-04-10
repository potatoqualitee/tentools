function Get-AcasUser {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }
    }
    process {


        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {

            $Users = Invoke-AcasRequest -SessionObject $session -Path '/users' -Method 'Get'

            if ($Users -is [psobject]) {
                $Users.users | ForEach-Object -process {
                    $UserProperties = [ordered]@{ }
                    $UserProperties.Add('Name', $_.name)
                    $UserProperties.Add('UserName', $_.username)
                    $UserProperties.Add('Email', $_.email)
                    $UserProperties.Add('UserId', $_.id)
                    $UserProperties.Add('Type', $_.type)
                    $UserProperties.Add('Permission', $permidenum[$_.permissions])
                    $UserProperties.Add('LastLogin', $origin.AddSeconds($_.lastlogin).ToLocalTime())
                    $UserProperties.Add('SessionId', $session.SessionId)
                    $UserObj = New-Object -TypeName psobject -Property $UserProperties
                    $UserObj.pstypenames[0] = 'Nessus.User'
                    $UserObj
                }
            }
        }

    }
    end { }
}