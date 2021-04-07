function New-TNScan {
    <#
    .SYNOPSIS
        Creates new scans

    .DESCRIPTION
        Creates new scans

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target scan

    .PARAMETER PolicyUUID
        The UUID of the target policy

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER Target
        Description for Target

    .PARAMETER ScanCredentialHash
        Optional ScanCredentialHash to use with -Auto

    .PARAMETER Disabled
        Description for Disabled

    .PARAMETER Description
        Description for Description

    .PARAMETER FolderId
        Description for FolderId

    .PARAMETER ScannerId
        Description for ScannerId

    .PARAMETER Email
        The email address of the target user

    .PARAMETER CreateDashboard
        Description for CreateDashboard

    .PARAMETER Auto
        Description for Auto

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNScan

        Creates new scans

#>
    [CmdletBinding(DefaultParameterSetName = "Policy")]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ParameterSetName = "Template", ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = "Policy", ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(Mandatory, ParameterSetName = "Template", ValueFromPipelineByPropertyName)]
        [string]$PolicyUUID,
        [Parameter(Mandatory, ParameterSetName = "Policy", ValueFromPipelineByPropertyName)]
        [int]$PolicyId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$TargetIpRange,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$TargetAsset,
        [Parameter(ValueFromPipelineByPropertyName)]
        [psobject[]]$ScanCredentialHash,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$Disabled,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int]$FolderId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int]$ScannerId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Email,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$CreateDashboard,
        [Parameter(Mandatory, ParameterSetName = "Auto", ValueFromPipelineByPropertyName)]
        [switch]$Auto,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Repository,
        [switch]$EnableException
    )
    begin {
        $enabled = $Disabled -eq $false
    }
    process {
        if (-not $PSBoundParameters.TargetIpRange -and -not $PSBoundParameters.TargetAsset) {
            Stop-PSFFunction -Message "You must specify either TargetIpRange or TargetAsset"
            return
        }
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session

            if ($session.sc) {
                if ($TargetIpRange) {
                    $iptargets = $TargetIpRange -join ","
                } else {
                    $assets = Get-TNAsset -Name $TargetAsset
                    $array = @()
                    foreach ($asset in $assets) {
                        $array += @{ id = $asset.Id }
                    }
                }

                switch ($PSCmdlet.ParameterSetName) {
                    "Auto" {
                        $repos = Get-TNRepository
                        $policies = Get-TNPolicy
                        foreach ($policy in $policies) {
                            if ($ScanCredentialHash) {
                                $allcreds = @()
                                foreach ($cred in $ScanCredentialHash) {
                                    $allcreds += @{ id = $cred.id }
                                }
                            }
                            if ($Repository) {
                                $repositoryhash = @{ id = ($repos | Where-Object Name -eq $Repository | Select-Object -First 1).Id }
                            } else {
                                if ($policy.PolicyTemplate.Name -eq 'SCAP and OVAL Auditing') {
                                    $repo = $repos | Where-Object Name -match Audit | Select-Object -First 1
                                    if (-not $repo) {
                                        $repo = $repos | Select-Object -First 1
                                    }
                                    $repositoryhash = @{ id = $repo.Id }
                                } else {
                                    $repositoryhash = @{ id = ($repos | Select-Object -First 1).Id }
                                }
                            }

                            Write-PSFMessage -Level Verbose -Message "Adding scan for $($policy.Name)"
                            $body = @{
                                name        = $policy.Name
                                description = $Description
                                type        = "policy"
                                policy      = @{ id = $policy.Id }
                                ipList      = $iptargets
                                assets      = $array
                                repository  = $repositoryhash
                                credentials = @($allcreds)
                            }
                            $params = @{
                                SessionObject = $session
                                Path          = "/scan"
                                Method        = "POST"
                                ContentType   = "application/json"
                                Parameter     = $body
                            }

                            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
                        }
                    }
                }
            } else {
                # Join emails as a single comma separated string.
                $emails = $Email -join ","

                # Join targets as a single comma separated string.
                $targets = ($TargetIpRange, $TargetAsset -join ",").TrimEnd(",")

                # Build Scan JSON
                $settings = @{
                    name         = $Name
                    text_targets = $targets
                    enabled      = $enabled
                }

                if ($PSBoundParameters.FolderId) { $settings.Add("folder_id", $FolderId) }
                if ($PSBoundParameters.ScannerId) { $settings.Add("scanner_id", $ScannerId) }
                if ($PSBoundParameters.Email) { $settings.Add("emails", $emails) }
                if ($PSBoundParameters.Description) { $settings.Add("description", $Description) }
                if ($CreateDashboard) { $settings.Add("use_dashboard", $true) }
                if ($PSBoundParameters.PolicyId) { $settings.Add("policy_id", $PolicyId) }

                switch ($PSCmdlet.ParameterSetName) {
                    "Template" {
                        Write-PSFMessage -Level Verbose -Message "Using Template with UUID of $($PolicyUUID)"
                        $scanhash = [pscustomobject]@{
                            uuid     = $PolicyUUID
                            settings = $settings
                        }

                        $json = ConvertTo-Json -InputObject $scanhash -Compress

                        $params = @{
                            SessionObject = $session
                            Path          = "/scans"
                            Method        = "POST"
                            ContentType   = "application/json"
                            Parameter     = $json
                        }

                        (Invoke-TNRequest @params).scan | ConvertFrom-TNRestResponse
                    }

                    "Policy" {
                        $polUUID = $null
                        $policies = Get-TNPolicy
                        foreach ($policy in $policies) {
                            if ($policy.PolicyId -eq $PolicyId) {
                                Write-PSFMessage -Level Verbose -Message "Using Policy with UUID of $($policy.PolicyUUID)"
                                $polUUID = $policy.PolicyUUID
                            }
                        }

                        if ($null -eq $polUUID) {
                            Stop-PSFFunction -EnableException:$EnableException -Message "Policy specified does not exist in session." -Continue
                        } else {
                            $scanhash = [pscustomobject]@{
                                uuid     = $polUUID
                                settings = $settings
                            }
                        }


                        $json = ConvertTo-Json -InputObject $scanhash -Compress

                        $params = @{
                            SessionObject = $session
                            Path          = "/scans"
                            Method        = "POST"
                            ContentType   = "application/json"
                            Parameter     = $json
                        }

                        (Invoke-TNRequest @params).scan | ConvertFrom-TNRestResponse
                    }

                    "Auto" {
                        Stop-PSFFunction -EnableException:$EnableException -Message "You cannot use Auto with Nessus" -Continue
                    }
                }
            }
        }
    }
}