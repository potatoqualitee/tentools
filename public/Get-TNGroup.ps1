function Get-TNGroup {
<#
    .SYNOPSIS
        Gets a list of groups

    .DESCRIPTION
        Gets a list of groups

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNGroup

        Gets a list of groups

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
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if ($session.MultiUser) {
                if ($session.sc) {
                    $params = @{
                        SessionObject = $session
                        Path          = "/group?expand=details"
                        Method        = "GET"
                    }
                } else {
                    $params = @{
                        SessionObject = $session
                        Path          = "/groups"
                        Method        = "GET"
                    }
                }

                Invoke-TNRequest @params | ConvertFrom-TNRestResponse

            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users" -Continue
            }
        }
    }
}