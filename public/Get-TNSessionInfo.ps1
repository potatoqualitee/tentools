function Get-TNSessionInfo {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            Write-PSFMessage -Level Verbose -Message "Removing server session $id"

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