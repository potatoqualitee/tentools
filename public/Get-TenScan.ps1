function Get-TenScan {
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
        PS> Get-Ten
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
        $params = @{ }

        if ($FolderId) {
            $params.Add('folder_id', $FolderId)
        }
    }
    process {
        foreach ($session in (Get-TenSession)) {
            $scans = Invoke-TenRequest -SessionObject $session -Path '/scans' -Method GET -Parameter $params

            if ($Status) {
                $scans | ConvertFrom-Response | Where-Object { $_.status -eq $Status.ToLower() }
            } else {
                $scans | ConvertFrom-Response
            }
        }
    }
}