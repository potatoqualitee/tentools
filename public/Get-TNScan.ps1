function Get-TNScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER FolderId
        Parameter description

    .PARAMETER Status
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>

    [CmdletBinding()]
    param
    (
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
        foreach ($session in (Get-TNSession)) {
            if ($FolderId) {
                $scans = Invoke-TNRequest -SessionObject $session -Path '/scans' -Method GET -Parameter $params
            } else {
                $scans = Invoke-TNRequest -SessionObject $session -Path '/scans' -Method GET
            }

            if ($Status) {
                $scans.scans | ConvertFrom-TNRestResponse | Where-Object Status -eq $Status
            } else {
                $scans.scans | ConvertFrom-TNRestResponse
            }
        }
    }
}