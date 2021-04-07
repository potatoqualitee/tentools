function Start-TNScan {
    <#
    .SYNOPSIS
        Starts a list of scans

    .DESCRIPTION
        Starts a list of scans

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER ScanId
        The ID of the target scan

    .PARAMETER AlternateTarget
        Description for AlternateTarget

    .PARAMETER Wait
        Wait for scan to finish before outputting results

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNScan | Start-TNScan

        Starts every scan asynchronously

    .EXAMPLE
        PS C:\> Get-TNScan | Where-Object Id -eq 3 | Start-TNScan -Wait

        Starts a specific scan and waits for the scan to finish before outputting the results

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        # Nessus session Id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("id")]
        [int32]$ScanId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$AlternateTarget,
        [switch]$Wait,
        [switch]$EnableException
    )
    begin {
        $params = @{ }

        if ($AlternateTarget) {
            $params.Add('alt_targets', $AlternateTarget)
        }
        $paramJson = ConvertTo-Json -InputObject $params -Compress
    }
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if ($session.sc) {
                $params = @{
                    SessionObject   = $session
                    EnableException = $EnableException
                    Path            = "/scan/$ScanId/launch"
                    Method          = "POST"
                    Parameter       = $paramJson
                }
                $result = (Invoke-TNRequest @params).ScanResult | ConvertFrom-TNRestResponse
                $path = "/scanResult/$($result.Id)?fields=name,description,diagnosticAvailable,owner,ownerGroup,importStatus,importStart,importFinish,importDuration,ioSyncStatus,ioSyncStart,ioSyncFinish,ioSyncDuration,totalIPs,scannedIPs,completedIPs,completedChecks,totalChecks,status,jobID,errorDetails,downloadAvailable,dataFormat,finishTime,downloadFormat,scanID,running,importErrorDetails,ioSyncErrorDetails,initiatorID,startTime,repository,details,timeoutAction,rolloverSchedule,progress,dataSourceID,resultType,resultSource,scanDuration,canManage,canUse"
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
                        $total = $progress.totalChecks
                        $completed = $progress.completedChecks
                        $completedips = $progress.CompletedIPs
                        $totalips = $progress.TotalIPs
                        if ($total -eq -1) {
                            $message = "Status: Pending"
                            Write-ProgressHelper -Activity "Running $($result.Name)" -Message $message -ExcludePercent
                        } elseif ($total -eq $completed) {
                            $message = "Status: Importing results into repository. Scanned $completedips of $totalips IPs"
                            Write-ProgressHelper -TotalSteps $total -StepNumber $completed -Activity "Running $($result.Name)" -Message $message -ExcludePercent
                        } else {
                            $message = "Status: $($progress.status) step $completed of $total steps for $totalips computers"
                            Write-ProgressHelper -TotalSteps $total -StepNumber $completed -Activity "Running $($result.Name)" -Message $message
                        }
                    }
                    Invoke-TNRequest @params | ConvertFrom-TNRestResponse
                }
            } else {

                if ($wait) {
                    throw "Wait not supported in Nessus, only tenable.sc"
                }
                foreach ($scans in (Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId/launch" -Method POST -Parameter $paramJson -ContentType "application/json")) {
                    [pscustomobject]@{
                        ScanUUID  = $scans.scan_uuid
                        ScanId    = $ScanId
                        SessionId = $session.SessionId
                    }
                }
            }
        }
    }
}