function Save-TNReportResult {
    <#
    .SYNOPSIS
        Saves a report result

    .DESCRIPTION
        Saves a report result

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER InputObject
        The report result

    .PARAMETER Path
        The directory to save the report result

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNReport | Get-TNReportResult | Save-TNReportResult -Path C:\temp

        Saves all report results to C:\temp

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
                $filename = Join-Path -Path $Path -ChildPath "$($file.Name.Split([IO.Path]::GetInvalidFileNameChars()) -join '')-$($file.Id)-reportresults.zip"
                Write-PSFMessage -Level Verbose -Message "Downloading $($file.Name) to $filename"
                $params = @{
                    EnableException = $true
                    Method          = "POST"
                    Path            = "/report/$($file.id)/download"
                    Parameter       = @{
                        id   = $file.Id
                        name = $file.Name
                    }
                }
                try {
                    Invoke-TNRequest @params -OutFile $filename
                    Get-ChildItem -Path $filename
                } catch {
                    Stop-PSFFunction -Message $PSItem -ErrorRecord $PSItem -EnableException:$EnableException
                }
            }
        }
    }
}