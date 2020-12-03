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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Target,
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
        [switch]$EnableException
    )
    begin {
        $enabled = $Disabled -eq $false
    }
    process {
        foreach ($session in $SessionObject) {

            if ($session.sc) {
                $targets = $Target -join ","
                $repository = @{ id = (Get-TNRepository | Select-Object -First 1).Id }

                switch ($PSCmdlet.ParameterSetName) {
                    "Auto" {
                        $policies = Get-TNPolicy
                        foreach ($policy in $policies) {
                            $body = @{
                                name        = $policy.Name
                                description = $Description
                                type        = "policy"
                                policy      = @{ id = $policy.Id }
                                ipList      = $targets
                                repository  = $repository
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
                $targets = $Target -join ","

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