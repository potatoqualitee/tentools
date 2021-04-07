function Import-TNAudit {
    <#
    .SYNOPSIS
        Imports audit files

    .DESCRIPTION
        Imports audit files

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER FilePath
        The path to the audit file

    .PARAMETER NoRename
        By default, this command will remove "Imported Nessus Policy - " from the title of the imported file. Use this switch to keep the whole name "Imported Nessus Policy - Title of Policy"

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-ChildItem C:\temp\portal_audits\DISA*v2r1* -Recurse  | Import-TNAudit

        Imports all .audit files matching DISA v2r2
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$FilePath,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $files = Get-ChildItem -Path $FilePath

            foreach ($file in $files.FullName) {
                $body = $file | Publish-File -Session $session -EnableException:$EnableException -Type Audit

                $params = @{
                    SessionObject = $session
                    Method        = "POST"
                    Path          = "/auditFile"
                    Parameter     = $body
                    ContentType   = "application/json"
                }

                Invoke-TnRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}