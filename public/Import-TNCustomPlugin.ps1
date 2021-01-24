function Import-TNCustomPlugin {
    <#
    .SYNOPSIS
        Imports a list of custom plugins

    .DESCRIPTION
        Imports a list of custom plugins

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER FilePath
        The path to the policy file

    .PARAMETER NoRename
        By default, this command will remove "Imported Nessus Policy - " from the title of the imported file. Use this switch to keep the whole name "Imported Nessus Policy - Title of Policy"

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Import-TNPolicy -FilePath C:\temp\policy.nessus

        Imports C:\temp\policy.nessus

    .EXAMPLE
        PS C:\> Import-TNPolicy -FilePath C:\temp\policy.nessus, C:\temp\policy2.nessus

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
        [switch]$NoRename,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $files = Get-ChildItem -Path $FilePath

            foreach ($file in $files.FullName) {
                $body = $file | Publish-File -Session $session -EnableException:$EnableException

                $params = @{
                    SessionObject = $session
                    Method        = "POST"
                    Path          = "customPlugins/active/process"
                    Parameter     = $body
                    ContentType   = "application/json"
                }

                if ($NoRename) {
                    Invoke-TnRequest @params | ConvertFrom-TNRestResponse
                } else {
                    $results = Invoke-TnRequest @params | ConvertFrom-TNRestResponse
                    # change the name
                    $name = $results.Name.Replace("Imported Nessus Policy - ","")
                    $body = @{ name = $name }

                    $params = @{
                        SessionObject = $session
                        Method        = "PATCH"
                        Path          = "/policy/$($results.id)"
                        Parameter     = $body
                        ContentType   = "application/json"
                    }
                    Invoke-TnRequest @params | ConvertFrom-TNRestResponse | Select-Object -ExcludeProperty Preferences -Property *
                }
            }
        }
    }
}