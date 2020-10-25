function Get-TNServerStatus {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

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
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            # only show if it's called from the command line
            if ((Get-PSCallStack).Count -eq 2) {
                if ($session.sc) {
                    Stop-PSFFunction -Message "tenable.sc not supported" -Continue
                }
            }
            Invoke-TNRequest -SessionObject $session -Path '/server/status' -Method GET
        }
    }
}