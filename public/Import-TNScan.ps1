function Import-TNScan {
    <#
    .SYNOPSIS
        Imports a list of scans

    .DESCRIPTION
        Imports a list of scans

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER FilePath
        Description for FilePath

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Import-TNScan -FilePath C:\temp\scan.nessus

        Imports C:\temp\scan.nessus

    .EXAMPLE
        PS C:\> Import-TNScan -FilePath C:\temp\scan.nessus, C:\temp\scan2.nessus

        Imports C:\temp\scan.nessus and C:\temp\scan2.nessus

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
            if ($session.sc) {
                Stop-PSFFunction -Message "tenable.sc not supported :(" -Continue
            }
            $files = Get-ChildItem -Path $FilePath

            foreach ($file in $files.FullName) {
                $body = $file | Publish-File -Session $session -EnableException:$EnableException

                Invoke-TnRequest -Method Post -Path "/scans/import" -Parameter $body -ContentType "application/json" -SessionObject $session |
                    ConvertFrom-TNRestResponse
            }
        }
    }
}