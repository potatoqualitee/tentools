function Get-TNSystemLog {
    <#
    .SYNOPSIS
       Gets the system log

    .DESCRIPTION
        Gets the system log

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER StartOffSet
        The record to start at. Defaults to 0.

    .PARAMETER EndOffset
        The record to end at. Defaults to 100.

    .PARAMETER Value
        Managed by a Program of Record. False by default.

    .PARAMETER Date
        Managed by a Program of Record. False by default.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNReportAttribute

        Adds a report attribute for DISA ARF

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [int]$StartOffSet = 0,
        [int]$EndOffset = 100,
        [string]$Value,
        [datetime]$Date = (Get-Date),
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            #$user = Get-TNUser | Where-Object username -eq $session.UserName
            $query = @{
                type        = "scLog"
                tool        = "scLog"
                startOffset = $StartOffSet
                endOffset   = $EndOffset
                filters     = { @{
                        id          = "date"
                        filterName  = "date"
                        operator    = "="
                        type        = "scLog"
                        sPredefined = "True"
                        value       = $Value
                    } }
                scLogTool   = "scLog"
            }

            $body = @{
                query      = $query
                sourceType = "scLog"
                type       = "scLog"
                date       = (Get-Date -Year $Date.Year -Month $Date.Month -Format yyyyMM)
            }

            $params = @{
                SessionObject   = $session
                Path            = "/analysis"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            $all = Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            $all.Results | Select-Object -Property * -ExcludeProperty rawLog | Add-Member -MemberType NoteProperty -Name TotalRecords -Value $all.TotalRecords -PassThru
        }
    }
}