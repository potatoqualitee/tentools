function Register-TNLicense {
    <#
    .SYNOPSIS
        Registers license

    .DESCRIPTION
        Registers license

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER FilePath
        The path to the license file

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-ChildItem "C:\sc\RID#12345;SERVER1;SecurityCenter-5.1-1024IPs.key" | Register-TNLicense

        Updates the license from "C:\sc\RID#12345;SERVER1;SecurityCenter-5.1-1024IPs.key"

    .EXAMPLE
        PS C:\> Register-TNLicense -FilePath "C:\sc\RID#12345;SERVER1;SecurityCenter-5.1-1024IPs.key"

        Updates the license from "C:\sc\RID#12345;SERVER1;SecurityCenter-5.1-1024IPs.key"
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
                $body = $file | Publish-File -Session $session -EnableException:$EnableException -Type Report

                $params = @{
                    SessionObject = $session
                    Method        = "POST"
                    Path          = "/config/license/register"
                    Parameter     = $body
                    ContentType   = "application/json"
                }

                Invoke-TnRequest @params | ConvertFrom-TNRestResponse
            }
        }
    }
}