function Get-TNScanResult {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER ScanId
        Parameter description

    .PARAMETER HistoryId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Nessus not supported" -Continue
            }

            if (-not $ScanId) {
                $path = "/scanResult?filter=*&optimizeCompletedScans=true&fields=canUse,canManage,owner,groups,ownerGroup,status,name,details,diagnosticAvailable,importStatus,createdTime,startTime,finishTime,importStart,importFinish,running,totalIPs,scannedIPs,completedIPs,completedChecks,totalChecks,dataFormat,downloadAvailable,downloadFormat,repository,resultType,resultSource,scanDuration"
            } else {
                $path = "/scanResult/$($ScanId)?fields=name,description,diagnosticAvailable,owner,ownerGroup,importStatus,importStart,importFinish,importDuration,ioSyncStatus,ioSyncStart,ioSyncFinish,ioSyncDuration,totalIPs,scannedIPs,completedIPs,completedChecks,totalChecks,status,jobID,errorDetails,downloadAvailable,dataFormat,finishTime,downloadFormat,scanID,running,importErrorDetails,ioSyncErrorDetails,initiatorID,startTime,repository,details,timeoutAction,rolloverSchedule,progress,dataSourceID,resultType,resultSource,scanDuration,canManage,canUse&expand=details,credentials"
            }

            Invoke-TNRequest -SessionObject $session -Path $path -Method GET | ConvertFrom-TNRestResponse
        }
    }
}