function Add-AcasGroupUser {
    <#
    .SYNOPSIS
        Adds a user to a group

    .DESCRIPTION
        Adds a user to a group

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER GroupId
        Parameter description

    .PARAMETER UserId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Add-AcasGroupUser

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [Int32]$GroupId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 2)]
        [Int32]$UserId,
        [switch]$EnableException
    )
    process {
        $collection = @()
        foreach ($id in $SessionId) {
            $sessions = $script:NessusConn
            foreach ($session in $sessions) {
                if ($session.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }

        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $serverparams = @{
                SessionObject   = $session
                Path            = '/server/properties'
                Method          = 'GET'
                EnableException = $EnableException
            }

            $server = Invoke-AcasRequest @serverparams

            if ($server.capabilities.multi_user -eq 'full' -or $null -eq $server) {
                $params = @{
                    SessionObject   = $session
                    Path            = "/groups/$($GroupId)/users"
                    Method          = 'POST'
                    Parameter       = @{'user_id' = $UserId }
                    EnableException = $EnableException
                }
                Invoke-AcasRequest @params
            }
            else {
                Write-PSFMessage -Level Warning -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}