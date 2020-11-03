function Add-TNGroupUser {
    <#
    .SYNOPSIS
        Adds a user to a group

    .DESCRIPTION
        Adds a user to a group

    .PARAMETER GroupId
        Parameter description

    .PARAMETER UserId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Add-TNGroupUser

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Group,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Username,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32]$GroupId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32[]]$UserId,
        [switch]$EnableException
    )
    begin {
        if (-not $PSBoundParameters.Group -and -not $PSBoundParameters.GroupId) {
            Stop-PSFFunction -Message "You must specify either Group or GroupId"
            return
        }
        if (-not $PSBoundParameters.Username -and -not $PSBoundParameters.UserId) {
            Stop-PSFFunction -Message "You must specify either Username or UserId"
            return
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }

        foreach ($session in (Get-TNSession)) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            if ($Group) {
                $GroupId = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/groups' -Method GET | ConvertFrom-TNRestResponse |
                    Where-Object name -in $Group | Select-Object -ExpandProperty Id
            }
            if ($Username) {
                $UserId += Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/users' -Method GET | ConvertFrom-TNRestResponse |
                    Where-Object username -in $Username | Select-Object -ExpandProperty Id
            }
            if ($session.MultiUser) {
                foreach ($id in $UserId) {
                    write-warning sup
                    $params = @{
                        SessionObject   = $session
                        Path            = "/groups/$GroupId/users"
                        Method          = 'POST'
                        Parameter       = @{ 'user_id' = $id }
                        EnableException = $EnableException
                    }
                    Invoke-TNRequest @params
                }
            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users" -Continue
            }
        }
    }
}