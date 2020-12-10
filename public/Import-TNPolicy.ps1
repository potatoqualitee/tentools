function Import-TNPolicy {
    <#
    .SYNOPSIS
        Imports a list of policies

    .DESCRIPTION
        Imports a list of policies

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER FilePath
        Description for FilePath

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Import-TNPolicy -FilePath C:\temp\policy.nessus

        Imports C:\temp\policy.nessus

    .EXAMPLE
        PS C:\> Import-TNPolicy -FilePath C:\temp\policy.nessus, C:\temp\policy2.nessus,

        Imports C:\temp\policy.nessus and C:\temp\policy2.nessus
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$FilePath,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            foreach ($file in $FilePath) {
                $body = $file | Publish-File -Session $session -EnableException:$EnableException

                $params = @{
                    SessionObject = $session
                    Method        = "POST"
                    Path          = "/policies/import"
                    Parameter     = $body
                    ContentType   = "application/json"
                }

                Invoke-TnRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}