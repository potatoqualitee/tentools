function Get-TNFolder {
    <#
    .Synopsis
        Gets folders configured on a Nessus Server.

    .DESCRIPTION
        Gets folders configured on a Nessus Server.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Get-TNFolder

        Name    : My Scans
        Id      : 2
        Type    : main
        Default : 1
        Unread  : 5

        Name    : Trash
        Id      : 3
        Type    : trash
        Default : 0
        Unread  :

        Name    : Test Folder 2
        Id      : 10
        Type    : custom
        Default : 0
        Unread  : 0
    #>
    [CmdletBinding()]
    param
    (
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported" -Continue
            }
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/folders' -Method GET |
                ConvertFrom-TNRestResponse
        }
    }
}