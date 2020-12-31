function Get-TNScanResult {
    <#
    .SYNOPSIS
        Gets a list of scan results

    .DESCRIPTION
        Gets a list of scan results

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER ScanId
        The ID of the target scan

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNScanResult -ScanId 10

        Gets a list of scan results for ScanID 10

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32]$ScanId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Nessus not supported" -Continue
            }

            if (-not $ScanId) {
                $path = "/scanResult?filter=*&optimizeCompletedScans=true&fields=canUse,canManage,owner,groups,ownerGroup,status,name,details,diagnosticAvailable,importStatus,createdTime,startTime,finishTime,importStart,importFinish,running,totalIPs,scannedIPs,completedIPs,completedChecks,totalChecks,dataFormat,downloadAvailable,downloadFormat,repository,resultType,resultSource,scanDuration"
            } else {
                $path = "/scanResult/$($ScanId)?fields=name,description,diagnosticAvailable,owner,ownerGroup,importStatus,importStart,importFinish,importDuration,ioSyncStatus,ioSyncStart,ioSyncFinish,ioSyncDuration,totalIPs,scannedIPs,completedIPs,completedChecks,totalChecks,status,jobID,errorDetails,downloadAvailable,dataFormat,finishTime,downloadFormat,scanID,running,importErrorDetails,ioSyncErrorDetails,initiatorID,startTime,repository,details,timeoutAction,rolloverSchedule,progress,dataSourceID,resultType,resultSource,scanDuration&expand=details,credentials"
            }

            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path $path -Method GET | ConvertFrom-TNRestResponse
        }
    }
}