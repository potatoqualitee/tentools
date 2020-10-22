function New-TNFolder {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER Name
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            $folder = Invoke-TNRequest -SessionObject $session -Path '/folders' -Method 'Post' -Parameter @{'name' = $Name }
            Get-TNFolder | Where-Object FolderId -eq $folder.id
        }
    }
}