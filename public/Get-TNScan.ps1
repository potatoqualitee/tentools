function Get-TNScan {
    <#
    .SYNOPSIS
        Gets a list of scans

    .DESCRIPTION
        Gets a list of scans

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER FolderId
        Description for FolderId

    .PARAMETER Status
        Description for Status

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNScan

        Gets a list of scans

#>

    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]$FolderId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Completed', 'Imported', 'Running', 'Paused', 'Canceled')]
        [string]$Status,
        [switch]$EnableException
    )
    begin {
        if ($FolderId) {
            $params = @{ }
            $params.Add('folder_id', $FolderId)
        }
    }
    process {
        foreach ($session in $SessionObject) {
            if ($FolderId) {
                $scans = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/scans' -Method GET -Parameter $params
            } else {
                $scans = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/scans' -Method GET
            }

            if ($scans.scans) {
                if ($Status) {
                    $scans.scans | ConvertFrom-TNRestResponse | Where-Object { $PSItem.Status -eq $Status -and $PSItem.Type -eq "Usable" }
                } else {
                    $scans.scans | ConvertFrom-TNRestResponse | Where-Object Type -eq Usable
                }
            } elseif ($scans) {
                if ($Status) {
                    $scans | ConvertFrom-TNRestResponse | Where-Object { $PSItem.Status -eq $Status -and $PSItem.Type -eq "Usable" }
                } else {
                    $scans | ConvertFrom-TNRestResponse | Where-Object Type -eq Usable
                }
            }
        }
    }
}