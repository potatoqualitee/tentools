$script:ModuleRoot = $PSScriptRoot
function Import-ModuleFile {
    [CmdletBinding()]
    Param (
        [string]
        $Path
    )

    if ($doDotSource) { . $Path }
    else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($Path))), $null, $null) }
}

# Detect whether at some level dotsourcing was enforced
if ($acas_dotsourcemodule) { $script:doDotSource }

# Import all internal functions
foreach ($function in (Get-ChildItem "$ModuleRoot\private\" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

# Import all public functions
foreach ($function in (Get-ChildItem "$ModuleRoot\public" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}


if ( -not (Test-Path variable:Script:NessusConn )) {
    $script:NessusConn = New-Object System.Collections.ArrayList
}

# Variables
$script:permidenum = @{
    16  = 'Read-Only'
    32  = 'Regular'
    64  = 'Administrator'
    128 = 'Sysadmin'
}

$script:permenum = @{
    'Read-Only'     = 16
    'Regular'       = 32
    'Administrator' = 64
    'Sysadmin'      = 128
}

$script:severity = @{
    0 = 'Info'
    1 = 'Low'
    2 = 'Medium'
    3 = 'High'
    4 = 'Critical'
}

# to help switch between Nessus and tenable.sc
$script:replace = @{
    users   = 'user'
    folders = 'folder'
    groups  = 'group'
    scans   = 'scan'
}

$script:querytool = @{
    Alert         = "alertName", "createdEndTime", "createdStartTime", "createdTimeFrame", "description", "didTriggerLastEvaluation", "lastEvaluatedEndTime", "lastEvaluatedStartTime", "lastEvaluatedTimeFrame", "lastTriggeredEndTime", "lastTriggeredStartTime", "lastTriggeredTimeFrame", "modifiedEndTime", "modifiedStartTime", "modifiedTimeFrame"
    Lce           = "listdata", "sumasset", "sumclassa", "sumclassb", "sumclassc", "sumdate", "sumevent", "sumevent2", "sumip", "sumport", "sumprotocol", "sumsensor", "sumtime", "sumtype", "sumuser", "syslog", "timedist"
    Mobile        = "listvuln", "sumdeviceid", "summdmuser", "summodel", "sumoscpe", "sumpluginid", "vulndetails"
    Ticket        = "listtickets", "sumassignee", "sumclassification", "sumcreator", "sumstatus"
    User          = "listusers", "sumgroup", "sumrole"
    Vulnerability = "iplist", "listmailclients", "listos", "listservices", "listsoftware", "listsshservers", "listvuln", "listwebclients", "listwebservers", "sumasset", "sumcce", "sumclassa", "sumclassb", "sumclassc", "sumcve", "sumdnsname", "sumfamily", "sumiavm", "sumid", "sumip", "summsbulletin", "sumport", "sumprotocol", "sumremediation", "sumseverity", "sumuserresponsibility", "vulndetails", "vulnipdetail", "vulnipsummary"
}

$script:origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

$PSDefaultParameterValues['*:UseBasicParsing'] = $true
$PSDefaultParameterValues['*:TimeoutSec'] = 300

Register-ArgumentCompleter -ParameterName Tool -CommandName New-TNQuery -ScriptBlock {
    param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
    $list = "alertName", "createdEndTime", "createdStartTime", "createdTimeFrame", "description", "didTriggerLastEvaluation", "lastEvaluatedEndTime", "lastEvaluatedStartTime", "lastEvaluatedTimeFrame", "lastTriggeredEndTime", "lastTriggeredStartTime", "lastTriggeredTimeFrame", "modifiedEndTime", "modifiedStartTime", "modifiedTimeFrame", "listdata", "sumasset", "sumclassa", "sumclassb", "sumclassc", "sumdate", "sumevent", "sumevent2", "sumip", "sumport", "sumprotocol", "sumsensor", "sumtime", "sumtype", "sumuser", "syslog", "timedist", "listvuln", "sumdeviceid", "summdmuser", "summodel", "sumoscpe", "sumpluginid", "vulndetails", "listtickets", "sumassignee", "sumclassification", "sumcreator", "sumstatus", "listusers", "sumgroup", "sumrole", "iplist", "listmailclients", "listos", "listservices", "listsoftware", "listsshservers", "listvuln", "listwebclients", "listwebservers", "sumasset", "sumcce", "sumclassa", "sumclassb", "sumclassc", "sumcve", "sumdnsname", "sumfamily", "sumiavm", "sumid", "sumip", "summsbulletin", "sumport", "sumprotocol", "sumremediation", "sumseverity", "sumuserresponsibility", "vulndetails", "vulnipdetail", "vulnipsummary"
    $list | Where-Object { $PSItem -like "$WordToComplete*" } | Select-Object -Unique | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($PSItem, $PSItem, "ParameterName", $PSItem)
    }
}
# | Where-Object $PSItem -like "$WordToComplete*"