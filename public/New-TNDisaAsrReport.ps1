function New-TNDisaAsrReport {
    <#
    .SYNOPSIS
       Adds a report attribute for DISA ARF

    .DESCRIPTION
        Adds a report attribute for DISA ARF

        https://docs.tenable.com/tenablesc/Content/Reports/ReportAttributes.htm

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        Name of the DISA ARF

    .PARAMETER Description
        Description for Description

    .PARAMETER Type
        The type of report attribute

    .PARAMETER PorManaged
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
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Name,
        [string]$Description,
        [ValidateSet("arf")]
        [string]$Type = "arf",
        [switch]$EnableException
    )
    process {
        if (Test-PSFFunctionInterrupt) { return }

        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $body = @{
                context  = "report"
                type     = "vuln"
                tool     = "sumid"
                vulnTool = "sumid"
            }

            $params = @{
                SessionObject   = $session
                Path            = "/query"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            $result = Invoke-TNRequest @params | ConvertFrom-TNRestResponse

            $definition = @{
                columns    = { @{name = "all" } }
                dataSource = @{ queryID = $result.id ; querySourceType = "cumulative"; querySourceView = "all" }
                dataPoints = 2147483647
                asrInfo    = @{ content = "plugin"; format = "detail"; includeARF = "true" }
            }

            $arf = Get-TNReportAttribute -Name DISA

            if (-not $arf) {
                $null = New-TNReportAttribute -Name DISA
                $arf = Get-TNReportAttribute -Name DISA
            }

            $schedule = @{
                repeatRule = "FREQ = TEMPLATE;INTERVAL = 1"
                type       = "template"
                enabled    = "true"
            }

            $body = @{
                name         = $Name
                description  = $Description
                type         = "asr"
                definition   = $definition
                schedule     = $schedule
                styleFamily  = @{id = 5; name = "Plain,Letter" }
                attributeSet = @{id = $arf.Id; name = $arf.Name; type = "arf" }
            }

            $params = @{
                SessionObject   = $session
                Path            = "/reportDefinition"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}