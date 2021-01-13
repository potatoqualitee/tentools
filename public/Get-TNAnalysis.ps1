function Get-TNAnalysis {
    [CmdletBinding()]
    param (
        [int]$QueryId,
        [string[]] $Filter = @(),
        [ValidateSet("sumip", "sumclassa", "sumclassb", "sumport", "sumprotocol", "sumid", "sumseverity", "sumfamily", "listvuln", "vulndetails", "listwebclients", "listwebservers", "listos", "iplist", "listmailclients", "listservices", "listsshservers", "sumasset", "vulnipsummary", "vulnipetail", "sumcve", "summsbulletin", "sumiavm", "listofsoftware", "sumdnsname", "cveipdetail", "iavmipdetail", "sumcce", "cceipdetail", "sumremediation", "sumuserresponsibility", "popcount", "trend")]
        [string]$Tool = "listvuln",
        [ValidateSet("cumulative", "individual", "patched")]
        [string]$SourceType = "cumulative",
        [int]$ScanID,
        [int]$StartOffSet,
        [int]$EndOffset,
        [string]$SortBy,
        [ValidateSet("asc", "desc")]
        [string]$SortDirection = "asc"
    )
    begin {
        $body = @{}
    }
    process {
        if ($SortBy) {
            $body.sortField = $SortBy
            $body.sortDir = $SortDirection
        }

        $filterstring = $Filter -join ","

        $query = @{
            filters     = $filterstring
            context     = "analysis"
            type        = "vuln"
            tool        = $Tool
            subtype     = $sourceType
            scanID      = $ScanID
            view        = "all"
            startOffset = $startOffset
            endOffset   = $endOffset
        }

        <#
        query
            name          :
            description   :
            context       :
            status        : - 1
            createdTime   : 0
            modifiedTime  : 0
            groups        : {}
            type          : vuln
            tool          : sumiavm
            sourceType    : cumulative
            startOffset   : 0
            endOffset     : 50
            filters       : {}
            sortColumn    : severity
            sortDirection : desc
            vulnTool      : sumiavm
        #>

        if ($QueryId) {
            $query.id = $QueryId
        }

        $body.query = $query
        $body.sourceType = $SourceType
        $body.scanID = $ScanID
        $body.type = "vuln"

        Invoke-TNRequest -Path "/analysis" -Method POST -Parameter $body
    }
}