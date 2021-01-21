function Save-TNScanResult {
    <#
    .SYNOPSIS
        Saves a scan result

    .DESCRIPTION
        Saves a scan result

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target credential

    .PARAMETER InputObject
        Description for InputObject

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Save-TNScanResult

        Saves a scan result

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [parameter(Mandatory)]
        [string]$Path,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }
            foreach ($file in $InputObject) {
                $filename = "$Path\$($file.Name)-$($file.Id).nessus"
                Write-PSFMessage -Level Verbose -Message "Downloading $($file.Name) to $filename"
                $params = @{
                    EnableException = $EnableException
                    Method          = "POST"
                    Path            = "/scanResult/$($file.id)/download"
                    Parameter       = @{ downloadType = "v2" }
                }
                Invoke-TNRequest @params -OutFile $filename
                Get-ChildItem -Path $filename
            }
        }
    }
}