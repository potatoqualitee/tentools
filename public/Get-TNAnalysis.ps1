function Get-TNAnalysis {
    <#
    .SYNOPSIS
       Gets things like Vulnerability Analysis

    .DESCRIPTION
       Gets things like Vulnerability Analysis

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER QueryId
        The ID of the Query you want to run

    .PARAMETER Filter
        A filter

    .PARAMETER Tool
        The tool parameter

    .PARAMETER SourceType
        The source type

    .PARAMETER ScanID
        The scan ID

    .PARAMETER StartOffSet
        The source type

    .PARAMETER EndOffset
        The source type

    .PARAMETER SortBy
        The source type

    .PARAMETER SortDirection
        The source type

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNAnalysis -Tool listos

        List Operating Systems

    .EXAMPLE
        PS C:\> $filters = @(
                        @{
                            filterName = 'pluginID'
                            operator   = '='
                            value      = '11936, 1'
                        }
                        @{
                            filterName = 'pluginText'
                            operator   = '='
                            value      = 'Linux'
                        }
                    )

        PS C:\> Get-TNAnalysis -Tool sumip -SourceType cumulative -Filter $filters

        Get details of Linux computers and thier IP address

#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [int]$QueryId,
        [psobject[]]$Filter,
        [ValidateSet("sumip", "sumclassa", "sumclassb", "sumport", "sumprotocol", "sumid", "sumseverity", "sumfamily", "listvuln", "vulndetails", "listwebclients", "listwebservers", "listos", "iplist", "listmailclients", "listservices", "listsshservers", "sumasset", "vulnipsummary", "vulnipetail", "sumcve", "summsbulletin", "sumiavm", "listofsoftware", "sumdnsname", "cveipdetail", "iavmipdetail", "sumcce", "cceipdetail", "sumremediation", "sumuserresponsibility", "popcount", "trend")]
        [string]$Tool = "listvuln",
        [ValidateSet("cumulative", "individual", "patched")]
        [string]$SourceType = "cumulative",
        [int]$ScanID,
        [int]$StartOffSet = 0,
        [int]$EndOffset = 100,
        [string]$SortBy,
        [ValidateSet("asc", "desc")]
        [string]$SortDirection = "desc"
    )
    begin {
        $body = @{
            sourceType = $SourceType
            type       = "vuln"
        }

        $query = @{
            startOffset = $StartOffSet
            endOffset   = $EndOffset
        }

        if ($SourceType -eq "cumulative") {
            if (-not $SortBy) {
                switch ($Tool) {
                    "listos" { $SortBy = "count" }
                    "sumip" {
                        $SortBy = "score"
                        $query.sortColumn = "score"
                        $query.sortDirection = "desc"
                    }
                }
            }
            $body.sortField = $SortBy
            $body.sortDir = "desc"
            $body.type = "vuln"
            $body.sourceType = $SourceType
            $query.type = "vuln"
            $query.tool = $Tool
            $query.vulnTool = $Tool
            $query.sourceType = $SourceType
        } else {
            $query.type = "vuln"
            $query.tool = $Tool
            $query.subtype = $SourceType
            $query.view = "all"
        }

        if ($Filter) {
            $query.filters = $Filter
        }

        if ($SortBy) {
            $body.sortField = $SortBy
            $body.sortDir = $SortDirection
        }

        if ($QueryId) {
            $query.id = $QueryId
        }

        if ($ScanId) {
            $body.scanID = $ScanID
            $query.scanID = $ScanID
        }
        $body.query = $query
    }
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                SessionObject = $session
                Path          = "/analysis"
                Method        = "POST"
                Body          = $body | ConvertTo-Json -Depth 5
            }

            foreach ($result in (Invoke-TNRequest @params)) {
                $result.results | Add-Member -MemberType NoteProperty -Name TotalResults -Value $result.totalRecords -PassThru | ConvertFrom-TNRestResponse
            }
        }
    }
}