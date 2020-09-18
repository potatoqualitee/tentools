function Get-ScGroup {
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
    [OutputType([int])]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            $serverparams = @{
                SessionObject   = $session
                Path            = '/server/properties'
                Method          = 'GET'
                EnableException = $EnableException
            }

            $server = Invoke-ScRequest @serverparams

            if ($server.capabilities.multi_user -eq 'full') {
                $groupparams = @{
                    SessionObject = $session
                    Path          = '/groups'
                    Method        = 'GET'
                }

                $groups = Invoke-ScRequest @groupparams
                foreach ($group in $groups.groups) {
                    [pscustomobject]@{ 
                        Name        = $group.name
                        GroupId     = $group.id
                        Permissions = $group.permissions
                        UserCount   = $group.user_count
                        SessionId   = $session.SessionId
                    } | Select-DefaultView -ExcludeProperty SessionId
                }
            }
            else {
                Write-PSFMessage -Level Warning -Message "Server for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}