function Set-TNRepositoryProperty {
    <#
    .SYNOPSIS
        Sets a repository property

    .DESCRIPTION
        Sets a repository property

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the repository or repositories to update

    .PARAMETER Description
        The description of the repository

    .PARAMETER IPrange
        Specifies the IP address range of vulnerability data that you want to view in the offline repository. For example, to view all data from the exported repository file, specify a range that includes all data in that repository.

        Type the range as a comma-delimited list of IP addresses, IP address ranges, and/or CIDR blocks.

        Note that this value will overwrite all previous IP ranges.

    .PARAMETER Organization
        Specifies which organizations have access to the vulnerability data stored in the repository.

        If groups are configured for the organization, Tenable.sc prompts you to grant or deny access to all of the groups in the organization. For more granular control, grant access within the settings for that group.

    .PARAMETER DaysTrending
        Specifies the number of days of cumulative vulnerability data that you want Tenable.sc to display in dashboard and report vulnerability trending displays.

    .PARAMETER TrendWithRaw
        When enabled, Tenable.sc includes vulnerability text in periodic snapshots of .nessus data for vulnerability trending purposes.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Set-TNRepositoryProperty -Name "All Computers" -DaysTrending 100

        Adds port 1433-1434 to Policy with Id 32


    .EXAMPLE
        PS C:\> Get-TNPolicy -Name "Host Scans" | Set-TNRepositoryProperty -Port 1433,1434

        Adds port 1433-1434 to Host Scans policy
#>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        [string]$Description,
        [string[]]$IPRange,
        [string]$Organization,
        [int]$DaysTrending,
        [switch]$TrendWithRaw,
        [switch]$EnableTrending,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $repos = Get-TNRepository -Name $Name

            foreach ($repo in $repos) {
                $repoid = $repo.id
                try {
                    $body = @{}
                    if ($PSBoundParameters.Description) {
                        $body["description"] = $Description
                    }

                    if ($PSBoundParameters.IPRange) {
                        $body["ipRange"] = ($IPRange -join ", ")
                    }

                    if ($PSBoundParameters.Organization) {
                        $org = Get-TNOrganization -Name $Organization
                        if ($org) {
                            $orgbody = [pscustomobject]@{organizations = @(@{id = $org.id }) } | ConvertTo-Json

                            $params = @{
                                SessionObject   = $session
                                Path            = "/repository/$repoid"
                                Method          = "PATCH"
                                ContentType     = "application/json"
                                Parameter       = $orgbody
                                EnableException = $EnableException
                            }

                            $null = Invoke-TNRequest @params
                        } else {
                            Stop-PSFFunction -Message "Organization $organization could not be found for $repo on $($session.Uri)" -Continue
                        }
                    }

                    if ($PSBoundParameters.DaysTrending) {
                        $body["trendingDays"] = $DaysTrending
                    }

                    if ($PSBoundParameters.TrendWithRaw) {
                        $body["trendWithRaw"] = $TrendWithRaw.ToLower()
                    }

                    if ($PSBoundParameters.EnableTrending) {
                        $body["enableTrending"] = $EnableTrending.ToLower()
                    }

                    $params = @{
                        SessionObject   = $session
                        Path            = "/repository/$repoid"
                        Method          = "PATCH"
                        ContentType     = "application/json"
                        Parameter       = $body
                        EnableException = $EnableException
                    }

                    $null = Invoke-TNRequest @params
                    Get-TNRepository -Name $Name
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}