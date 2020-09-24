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


if (!(Test-Path variable:Script:NessusConn )) {
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

$script:origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

$PSDefaultParameterValues['*:UseBasicParsing'] = $true