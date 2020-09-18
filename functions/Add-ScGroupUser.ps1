function Add-ScGroupUser {
    <#
    .SYNOPSIS
        Adds a new Nessus plugin rule

    .DESCRIPTION
        Can be used to alter report output for various reasons. i.e. vulnerability acceptance, verified
        false-positive on non-credentialed scans, alternate mitigation in place, etc...

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER GroupId
        Parameter description

    .PARAMETER UserId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Add-ScGroupUser

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [Int32]$UserId,
        [switch]$EnableException
    )
    process {
        $collection = @()
        foreach ($id in $SessionId) {
            $sessions = $global:NessusConn
            foreach ($session in $sessions) {
                if ($session.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }

        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            $serverparams = @{
                SessionObject   = $session
                Path            = '/server/properties'
                Method          = 'GET'
                EnableException = $EnableException
            }

            $server = Invoke-ScRequest @serverparams

            if ($server.capabilities.multi_user -eq 'full') {
                $params = @{
                    SessionObject   = $session
                    Path            = "/groups/$($GroupId)/users"
                    Method          = 'POST'
                    Parameter       = @{'user_id' = $UserId }
                    EnableException = $EnableException
                }
                Invoke-ScRequest @params
            }
            else {
                Write-PSFMessage -Level Warning -Message "Server for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}