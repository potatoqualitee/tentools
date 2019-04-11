function Get-AcasSessionInfo {
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
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            Write-PSFMessage -Level Verbose -Message "Removing server session $($id)"
            
            $RestMethodParams = @{
                Method          = 'Get'
                'URI'           = "$($session.URI)/session"
                'Headers'       = @{'X-Cookie' = "token=$($session.Token)" }
                'ErrorVariable' = 'NessusSessionError'
            }
            $SessInfo = Invoke-RestMethod @RestMethodParams
            [pscustomobject]@{ 
                Id         = $SessInfo.id
                Name       = $SessInfo.name
                UserName   = $SessInfo.UserName
                Email      = $SessInfo.Email
                Type       = $SessInfo.Type
                Permission = $permidenum[$SessInfo.permissions]
                LastLogin  = $origin.AddSeconds($SessInfo.lastlogin).ToLocalTime()
                Groups     = $SessInfo.groups
                Connectors = $SessInfo.connectors
            }
        }
    }
}