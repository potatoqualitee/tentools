function New-TNQuery {
    <#
    .SYNOPSIS
        Creates new queries

    .DESCRIPTION
        Creates new queries

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target query

    .PARAMETER Description
        Description for Description

    .PARAMETER Type
        The type of query

    .PARAMETER AuthType
        Description for AuthType

    .PARAMETER Query
        The query object (from Get-Query) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER QueryHash
        Description for QueryHash

    .PARAMETER PrivilegeEscalation
        Description for PrivilegeEscalation

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> $params = @{
              Name = "Windows Scanner Account"
              Type = "windows"
              AuthType = "password"
              Query = "ad\nessus"
        }
        PS C:\> New-TNQuery @params -Verbose

        Creates a new Windows query for ad\nessus

    .EXAMPLE
        PS C:\> $params = @{
              Name = "Linux Scanner Account"
              Type = "ssh"
              AuthType = "password"
              Query = "acasaccount"
              PrivilegeEscalation = "sudo"
        }

        PS C:\> New-TNQuery @params -Verbose

        Creates a new SSH query for acasaccount and sets the escalation type to sudo


    .EXAMPLE
        PS C:\> $credhash = @{
                dbType = "SQL Server"
                SQLServerAuthType = "SQL"
            }

        PS C:\> $params = @{
              Name = "SQL Server sqladmin"
              Type = "database"
              AuthType = "password"
              Query = "sqladmin"
              QueryHash = $credhash
        }

        PS C:\> New-TNQuery @params -Verbose

        Creates a new SQL Server query for SQL Login sqladmin

    .EXAMPLE
        PS C:\> $credhash = @{
                dbType = "SQL Server"
                SQLServerAuthType = "Windows"
            }

        PS C:\> $params = @{
              Name = "SQL Server sqladmin"
              Type = "database"
              AuthType = "password"
              Query = "ad\sqladmin"
              QueryHash = $credhash
        }

        PS C:\> New-TNQuery @params -Verbose

        Creates a new SQL Server query for Windows ad\sqladmin

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet("Vulnerability", "Alert", "All", "Lce", "Mobile", "Ticket", "User")]
        [string]$Type = "Vulnerability",
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Tool = "sumid",
        [hashtable]$FilterHash,
        [ValidateSet("acceptRiskStatus", "asset", "assetID", "auditFile", "auditFileID", "baseCVSSScore", "benchmarkName", "cceID", "cpe", "cveID", "cvssV3BaseScore", "cvssV3Vector", "cvssVector", "dataFormat", "daysMitigated", "daysToMitigated", "dnsName", "exploitAvailable", "exploitFrameworks", "family", "familyID", "firstSeen", "iavmID", "ip", "lastMitigated", "lastSeen", "mitigatedStatus", "msbulletinID", "outputAssets", "patchPublished", "pluginID", "pluginModified", "pluginName", "pluginPublished", "pluginText", "pluginType", "policy", "policyID", "port", "protocol", "recastRiskStatus", "repository", "repositoryIDs", "responsibleUser", "responsibleUserIDs", "severity", "stigSeverity", "tcpport", "udpport", "uuid", "vprScore", "vulnPublished", "xref")]
        [string]$FilterName,
        [ValidateSet("=", "!=", "<=", ">=")]
        [string]$Operator,
        [string]$Value,
        [switch]$EnableException
    )
    begin {
        if ($Type -notin "windows", "ssh" -and -not $PSBoundParameters.QueryHash) {
            Stop-PSFFunction -Message "You must specify a QueryHash when Type is $Type"
            return
        }
        if ($AuthType -eq "certificate" -and -not $PSBoundParameters.QueryHash) {
            Stop-PSFFunction -Message "You must specify a QueryHash when AuthType is $AuthType"
            return
        }

        switch ($Type) {
            "Vulnerability" { $querytype = "vuln" }
            default { $querytype = $Type.ToLower() }
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }

        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            <#
            "=", "!=", "<=", ">="

            name         : Hello There
            description  :
            context      :
            status       : -1
            createdTime  : 0
            modifiedTime : 0
            groups       : {}
            type         : vuln
            tool         : sumid
            sourceType   :
            filters      : {@{id=asset; filterName=asset; operator==; isPredefined=True; value=}}
            vulnTool     : sumid


            "browseColumns" : <string> DEFAULT "",
            "browseSortColumn" : <string> DEFAULT "",
            "browseSortDirection" : <string> "ASC", "DESC" DEFAULT "ASC",
            #>
            # Note: sourceType will always be null. Current functionality doesn't accept sourceType parameter, and will always set it to default QUERY_NOT_TREND (null)
            if (-not $PSBoundParameters.QueryHash) {
                $body = @{
                    name        = $Name
                    description = $Description
                    type        = $querytype
                    tool        = $tooltype
                    sourceType  = $null
                    filters     = $filters
                    vulnTool    = "sumid"
                }
            } else {
                $body = $PSBoundParameters.QueryHash
                $body.Add("name", $Name)
                $body.Add("description", $Description)
                $body.Add("type", $Type)
                $body.Add("authType", $AuthType)


                if ($PSBoundParameters.Query) {
                    if ($Type -eq "windows" -and $Query.UserName -match "\\") {
                        $domain, $username = $Query.UserName -split "\\"
                        $body.Add("domain", $domain)
                    } else {
                        $username = $Query.UserName
                    }

                    if ($Type -eq "ssh") {
                        $body.Add("privilegeEscalation", $PrivilegeEscalation.ToLower())
                    }

                    if ($Type -notin "database") {
                        $body.Add("username", $username)
                    } else {
                        $body.Add("login", $username)
                    }
                }

                $params = @{
                    SessionObject   = $session
                    Path            = "/query"
                    Method          = "POST"
                    Parameter       = $body
                    EnableException = $EnableException
                }

                Invoke-TNRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}