function Get-TNReportResult {
    <#
    .SYNOPSIS
        Gets a list of report results

    .DESCRIPTION
        Gets a list of report results

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER ReportId
        The ID of the target report

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNReport -ReportId 10

        Gets report results for ReportID 10

    .EXAMPLE
        PS C:\> Get-TNReport | Get-TNReportResult

        Gets report results for every scan

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32]$ReportId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Nessus not supported" -Continue
            }

            if (-not $ReportId) {
                $path = "/report?filter=usable&fields=name,type,ownerGroup,owner,status,startTime,finishTime,completedSteps,totalSteps,running,canManage,canUse"
            } else {
                $path = "/report/$($ReportId)?filter=usable&fields=name,type,ownerGroup,owner,status,startTime,finishTime,completedSteps,totalSteps,running,canManage,canUse"
            }

            try {
                $results = Invoke-TNRequest -SessionObject $session -EnableException -Path $path -Method GET | ConvertFrom-TNRestResponse
                # don't return empty results
                if ($results.Running) {
                    $results
                }
            } catch {
                if ($PSItem -match "does not exist") {
                    Stop-PSFFunction -EnableException:$EnableException -Message $PSItem -ErrorRecord $PSItem
                }
            }
        }
    }
}