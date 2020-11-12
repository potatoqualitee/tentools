function Get-TNScanZone {
    <#
    .SYNOPSIS
        Gets a scan zone

    .DESCRIPTION
        Gets a scan zone

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS>  Get-TNScanZone

    #>
    [CmdletBinding()]
    param
    (
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/zone?fields=name,description,ipList,createdTime,ranges,scanners,name,activeScanners,totalScanners,modifiedTime,canUse,canManage,SCI"
                Method          = "GET"
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}