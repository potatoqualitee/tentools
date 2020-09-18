function Get-ScUser {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Sc
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
            $Users = Invoke-ScRequest -SessionObject $session -Path '/users' -Method 'Get'
            $Users.users | ForEach-Object -process {
                [pscustomobject]@{ 
                    Name       = $_.name
                    UserName   = $_.username
                    Email      = $_.email
                    UserId     = $_.id
                    Type       = $_.type
                    Permission = $permidenum[$_.permissions]
                    LastLogin  = $origin.AddSeconds($_.lastlogin).ToLocalTime()
                    SessionId  = $session.SessionId
                }
            }
        }
    }
}