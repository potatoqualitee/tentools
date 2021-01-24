function Start-TNReport {
    <#
    .SYNOPSIS
        Starts a list of reports

    .DESCRIPTION
        Starts a list of reports

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER ReportId
        The ID of the target report

    .PARAMETER AlternateTarget
        Description for AlternateTarget

    .PARAMETER Wait
        Wait for report to finish before outputting results

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNReport | Start-TNReport

        Starts every report asynchronously

    .EXAMPLE
        PS C:\> Get-TNReport | Where-Object Id -eq 3 | Start-TNReport -Wait

        Starts a specific report and waits for the report to finish before outputting the results

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        # Nessus session Id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("id")]
        [int32]$ReportId,
        [switch]$Wait,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Nessus not supported" -Continue
            }
            if ($session.sc) {
                $params = @{
                    SessionObject   = $session
                    EnableException = $EnableException
                    Path            = "/reportDefinition/$ReportId/launch"
                    Method          = "POST"
                    Parameter       = $paramJson
                }
                $result = (Invoke-TNRequest @params).ReportResult | ConvertFrom-TNRestResponse

                $path = "/report/$($result.id)?filter=usable&fields=name,type,ownerGroup,owner,status,startTime,finishTime,completedSteps,totalSteps,running,canManage,canUse"
                $params = @{
                    SessionObject   = $session
                    EnableException = $EnableException
                    Path            = $path
                    Method          = "GET"
                }
                if (-not $Wait) {
                    Invoke-TNRequest @params | ConvertFrom-TNRestResponse
                } else {
                    $progress = Invoke-TNRequest @params | ConvertFrom-TNRestResponse
                    while ($progress.status -ne "Completed") {
                        Start-Sleep -Seconds 1
                        $progress = Invoke-TNRequest @params | ConvertFrom-TNRestResponse
                        $total = $progress.totalSteps
                        $completed = $progress.completedSteps
                        if ($total -eq -1) {
                            $message = "Status: Pending"
                            Write-ProgressHelper -Activity "Running $($result.Name)" -Message $message -ExcludePercent
                        } elseif ($total -eq $completed) {
                            $message = "Status: Completing"
                            Write-ProgressHelper -TotalSteps $total -StepNumber $completed -Activity "Running $($result.Name)" -Message $message -ExcludePercent
                        } else {
                            $message = "Status: $($progress.status) step $completed of $total steps"
                            Write-ProgressHelper -TotalSteps $total -StepNumber $completed -Activity "Running $($result.Name)" -Message $message
                        }
                    }
                    Invoke-TNRequest @params | ConvertFrom-TNRestResponse
                }
            }
        }
    }
}