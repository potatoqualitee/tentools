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
        PS C:\> New-TNReportAttribute

        Adds a report attribute for DISA ARF

#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [int]$QueryId,
        [psobject[]] $Filter = @(),
        [ValidateSet("sumip", "sumclassa", "sumclassb", "sumport", "sumprotocol", "sumid", "sumseverity", "sumfamily", "listvuln", "vulndetails", "listwebclients", "listwebservers", "listos", "iplist", "listmailclients", "listservices", "listsshservers", "sumasset", "vulnipsummary", "vulnipetail", "sumcve", "summsbulletin", "sumiavm", "listofsoftware", "sumdnsname", "cveipdetail", "iavmipdetail", "sumcce", "cceipdetail", "sumremediation", "sumuserresponsibility", "popcount", "trend")]
        [string]$Tool = "listvuln",
        [ValidateSet("cumulative", "individual", "patched")]
        [string]$SourceType = "cumulative",
        [int]$ScanID,
        [int]$StartOffSet = 0,
        [int]$EndOffset = 100,
        [string]$SortBy,
        [ValidateSet("asc", "desc")]
        [string]$SortDirection = "asc"
    )
    begin {
        $body = @{}
        <#
        totalRecords             : 69
        returnedRecords          : 69
#>

        if ($SortBy) {
            $body.sortField = $SortBy
            $body.sortDir = $SortDirection
        }

        $query = @{
            filters     = $Filter -join ","
            context     = "analysis"
            type        = "vuln"
            tool        = $Tool
            subtype     = $SourceType
            scanID      = $SourceType
            view        = "all"
            startOffset = $StartOffSet
            endOffset   = $EndOffset
        }

        if ($QueryId) {
            $query.id = $QueryId
        }

        $body.query = $query
        $body.sourceType = $SourceType
        $body.scanID = $ScanID
        $body.type = "vuln"

    }
    process {
        foreach ($session in $SessionObject) {

            $params = @{
                SessionObject = $session
                Path          = "/analysis"
                Method        = "POST"
                Parameter     = $body
            }

            foreach ($result in (Invoke-TNRequest @params)) {
                $result.results | Add-Member -MemberType NoteProperty -Name TotalResults -Value $result.totalRecords -PassThru | ConvertFrom-TNRestResponse
            }
        }
    }
}