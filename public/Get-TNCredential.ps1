function Get-TNCredential {
    <#
    .SYNOPSIS
        Gets a credential

    .DESCRIPTION
        Gets a credential

    .PARAMETER Name
        Parameter description

    .PARAMETER ZoneSelection
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS>  Get-TNCredential

    #>
    [CmdletBinding()]
    param
    (
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/credential?filter=usable&fields=name,tags,description,typeFields,createdTime,groups,name,type,owner,ownerGroup,groups,modifiedTime,canManage,canUse,tags"
                Method          = "GET"
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}