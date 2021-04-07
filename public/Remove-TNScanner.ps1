function Remove-TNScanner {
    <#
    .SYNOPSIS
        Removes a list of scanners

    .DESCRIPTION
        Removes a list of scanners

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target organization

    .PARAMETER InputObject
        Description for InputObject

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Remove-TNScanner -Name nessus2

        Removes a scanner with the name nessus2
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }
            if (-not $InputObject) {
                $InputObject = Get-TNScanner -Name $Name
                if (-not $InputObject) {
                    Stop-PSFFunction -Message "Scanner $Name does not in exist at $($session.URI)" -Continue
                }
            }

            foreach ($scanner in $InputObject) {
                $params = @{
                    SessionObject   = $session
                    EnableException = $EnableException
                    Method          = "DELETE"
                    Path            = "/scanner/$($scanner.Id)"
                }
                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}