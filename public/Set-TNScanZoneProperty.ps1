function Set-TNScanZoneProperty {
    <#
    .SYNOPSIS
        Sets a scan zone property

    .DESCRIPTION
        Sets a scan zone property

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the scan zone or scan zones to update

    .PARAMETER Description
        The description of the scan zone

    .PARAMETER IPrange
        Specifies the IP address range of vulnerability data that you want to view in the offline scan zone. For example, to view all data from the exported scan zone file, specify a range that includes all data in that scan zone.

        Type the range as a comma-delimited list of IP addresses, IP address ranges, and/or CIDR blocks.

        Note that this value will overwrite all previous IP ranges.

    .PARAMETER Scanner
        Specifies which scanners are part of the scan zone.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Set-TNScanZoneProperty -Name "All Computers" -DaysTrending 100

       Sets days trending to 100 for the "All Computers" scan zone

    .EXAMPLE
        PS C:\> Set-TNScanZoneProperty -Name "All Computers" -Scanner Acme -TrendWithRaw

        Adds access to the Acme organization and sets days trending to 365 for the "All Computers" scan zone

        name              description ipList       scanners
#>

    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [string]$Description,
        [string[]]$IPRange,
        [string[]]$Scanner,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $scanzones = Get-TNScanZone | Where-Object Name -eq $Name

            foreach ($scanzone in $scanzones) {
                $scanzoneid = $scanzone.id
                try {
                    $body = @{}
                    if ($PSBoundParameters.Description) {
                        $body["description"] = $Description
                    }

                    if ($PSBoundParameters.IPRange) {
                        $body["ipRange"] = ($IPRange -join ", ")
                    }

                    if ($PSBoundParameters.Scanner) {
                        $nessus = Get-TNScanner -Name $Scanner
                        if ($nessus) {
                            $nessusbody = [pscustomobject]@{scanners = @(@{id = $nessus.id }) } | ConvertTo-Json

                            $params = @{
                                SessionObject   = $session
                                Path            = "/zone/$scanzoneid"
                                Method          = "PATCH"
                                ContentType     = "application/json"
                                Parameter       = $nessusbody
                                EnableException = $EnableException
                            }

                            $null = Invoke-TNRequest @params
                        } else {
                            Stop-PSFFunction -Message "Scanner $nessusanization could not be found for $scanzone on $($session.Uri)" -Continue
                        }
                    }

                    $params = @{
                        SessionObject   = $session
                        Path            = "/zone/$scanzoneid"
                        Method          = "PATCH"
                        ContentType     = "application/json"
                        Parameter       = $body
                        EnableException = $EnableException
                    }

                    $null = Invoke-TNRequest @params
                    Get-TNScanZone | Where-Object Name -eq $Name
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}