function Remove-TNQuery {
    <#
    .SYNOPSIS
        Removes a list of queries

    .DESCRIPTION
        Removes a list of queries

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The ID of the target query

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Remove-TNQuery

        Removes a list of queries

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }
            foreach ($queryname in $Name) {
                $id = (Get-TNQuery | Where-Object Name -eq $queryname).Id
                if ($id) {
                    Write-PSFMessage -Level Verbose -Message "Deleting query with id $id"
                    Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/query/$id" -Method Delete | ConvertFrom-TNRestResponse
                }
            }
        }
    }
}