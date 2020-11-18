function New-TNScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER Name
        Parameter description

    .PARAMETER PolicyUUID
        Parameter description

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER Target
        Parameter description

    .PARAMETER Enabled
        Parameter description

    .PARAMETER Description
        Parameter description

    .PARAMETER FolderId
        Parameter description

    .PARAMETER ScannerId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TNServer.

    .PARAMETER Email
        Parameter description

    .PARAMETER CreateDashboard
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding(DefaultParameterSetName = "Policy")]
    param
    (
        [Parameter(Mandatory, ParameterSetName = "Template", ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = "Policy", ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(Mandatory, ParameterSetName = "Template", ValueFromPipelineByPropertyName)]
        [string]$PolicyUUID,
        [Parameter(Mandatory, ParameterSetName = "Policy", ValueFromPipelineByPropertyName)]
        [int]$PolicyId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Target,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [bool]$Enabled,
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
        [Parameter(Mandatory, ParameterSetName = "All", ValueFromPipelineByPropertyName)]
        [switch]$AllPolicies,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {

            # Join emails as a single comma separated string.
            $emails = $email -join ","

            # Join targets as a single comma separated string.
            $targets = $target -join ","

            # Build Scan JSON
            $settings = @{
                name         = $Name
                text_targets = $targets
            }

            if ($FolderId) { $settings.Add("folder_id", $FolderId) }
            if ($ScannerId) { $settings.Add("scanner_id", $ScannerId) }
            if ($Email.Length -gt 0) { $settings.Add("emails", $emails) }
            if ($Description.Length -gt 0) { $settings.Add("description", $Description) }
            if ($CreateDashboard) { $settings.Add("use_dashboard", $true) }
            if ($PolicyId) { $settings.Add("policy_id", $PolicyId) }

            switch ($PSCmdlet.ParameterSetName) {
                "Template" {
                    Write-PSFMessage -Level Verbose -Message "Using Template with UUID of $($PolicyUUID)"
                    $scanhash = [pscustomobject]@{
                        uuid     = $PolicyUUID
                        settings = $settings
                    }

                    $json = ConvertTo-Json -InputObject $scanhash -Compress

                    $serverparams = @{
                        SessionObject = $session
                        Path          = "/scans"
                        Method        = "POST"
                        ContentType   = "application/json"
                        Parameter     = $json
                    }

                    (Invoke-TNRequest @serverparams).scan | ConvertFrom-TNRestResponse
                }

                "Policy" {
                    $polUUID = $null
                    $policies = Get-TNPolicy
                    foreach ($policy in $policies) {
                        if ($policy.PolicyId -eq $PolicyId) {
                            Write-PSFMessage -Level Verbose -Message "Using Poicy with UUID of $($policy.PolicyUUID)"
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

                    $serverparams = @{
                        SessionObject = $session
                        Path          = "/scans"
                        Method        = "POST"
                        ContentType   = "application/json"
                        Parameter     = $json
                    }

                    (Invoke-TNRequest @serverparams).scan | ConvertFrom-TNRestResponse
                }

                "All" {
                    $polUUID = $null
                    $policies = Get-TNPolicy
                    foreach ($policy in $policies) {
                        if ($policy.PolicyId -eq $PolicyId) {
                            Write-PSFMessage -Level Verbose -Message "Using Poicy with UUID of $($policy.PolicyUUID)"
                            $polUUID = $policy.PolicyUUID
                        }

                        if ($null -eq $polUUID) {
                            Stop-PSFFunction -EnableException:$EnableException -Message "Policy specified does not exist in session." -Continue
                        } else {
                            $scanhash = [pscustomobject]@{
                                uuid     = $polUUID
                                settings = $settings
                            }

                            $json = ConvertTo-Json -InputObject $scanhash -Compress

                            $serverparams = @{
                                SessionObject = $session
                                Path          = "/scans"
                                Method        = "POST"
                                ContentType   = "application/json"
                                Parameter     = $json
                            }

                            (Invoke-TNRequest @serverparams).scan | ConvertFrom-TNRestResponse
                        }
                    }
                }
            }
        }
    }