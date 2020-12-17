function Set-TNScanProperty {
    <#
    .SYNOPSIS
        Sets a scan property

    .DESCRIPTION
        Sets a scan property

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the scan or scans to update

    .PARAMETER ScanCredential
        Specifies which scan credentials are part of the scan

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Set-TNScanProperty -Name "Host Discovery" -ScanCredential "Windows Scanner Account", "Linux Scanner Account"

        Adds "Windows Scanner Account" and "Linux Scanner Account" credentials to the Host Discovery scan
#>

    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$ScanCredential,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $Scans = Get-TNScan | Where-Object Name -eq $Name

            foreach ($scan in $Scans) {
                $scanid = $scan.id
                try {
                    if ($PSBoundParameters.ScanCredential) {
                        $creds = Get-TNCredential -Name $ScanCredential
                        if ($creds) {
                            $allcreds = @()
                            foreach ($cred in $creds) {
                                $allcreds += @{ id = $cred.id }
                            }
                            $credbody = [pscustomobject]@{credentials = @($allcreds) } | ConvertTo-Json

                            $params = @{
                                SessionObject   = $session
                                Path            = "/scan/$scanid"
                                Method          = "PATCH"
                                ContentType     = "application/json"
                                Parameter       = $credbody
                                EnableException = $EnableException
                            }

                            $null = Invoke-TNRequest @params
                        } else {
                            Stop-PSFFunction -Message "Scanner $nessusanization could not be found for $Scan on $($session.Uri)" -Continue
                        }
                    }
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }

            Get-TNScan | Where-Object Name -eq $Name
        }
    }
}