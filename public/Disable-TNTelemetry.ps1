function Disable-TNTelemetry {
    <#
    .SYNOPSIS
        Disables telemetry

    .DESCRIPTION
        Disables telemetry

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Connect-TNServer -ComputerName acas -Credential admin -Type tenable.sc
        PS C:\> Disable-TNTelemetry
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session

            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $body = @{ "TelemetryEnabled" = "false" }

            $params = @{
                SessionObject = $session
                Method        = "PATCH"
                Path          = "/configSection/4"
                Parameter     = $body
                ContentType   = "application/json"
            }

            Invoke-TnRequest @params | ConvertFrom-TNRestResponse | Select-Object ServerUri, TelemetryEnabled
        }
    }
}