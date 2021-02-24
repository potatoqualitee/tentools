function Start-TNDeploy {
    <#
    .SYNOPSIS
        Deploys tenable.sc

    .DESCRIPTION
        Deploys tenable.sc

    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server

    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.

    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER LicensePath
        Description for LicensePath

    .PARAMETER AcceptSelfSignedCert
        Accept self-signed certs

    .PARAMETER Type
        The type of deploy

    .PARAMETER SecurityManagerCredential
        Description for SecurityManagerCredential

    .PARAMETER Scanner
        The hostname of the scanner or scanners to add

    .PARAMETER ScannerCredential
        The username and password used to add the scanners

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> $splat = @{
            ComputerName = "securitycenter"
            AdministratorCredential = (Get-Credential admin)
            LicensePath = ""
            AcceptSelfSignedCert = ""
            SecurityManagerCredential = ""
            Organization = ""
            Repository = ""
            ScanZone = "All Computers"
            ScanCredentialHash = ""
            IpRange = ""
            PolicyFilePath = ""
            ScanFilePath = ""
            EnableException = ""
        }

        PS C:\> Start-TNDeploy

        Starts a list of deploys

    .EXAMPLE
        $admincred = Get-Credential admin
        $secmancred = Get-Credential secmancred

        $splat = @{
        ComputerName = "securitycenter"
        AdministratorCredential = $admincred
        SecurityManagerCredential = $secmancred
        Organization = "Acme"
        Repository = "All Computers"
        ScanZone = "All Computers"
        IpRange = "192.168.0.0/24"
        PolicyFilePath = "C:\nessus\library\policy.nessus",
        ScanFilePath = "C:\nessus\library\scan.nessus","C:\nessus\library\scan2.nessus"
    }

        PS C:\> Start-TNDeploy -Verbose

#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int]$Port,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [psobject]$AdministratorCredential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$LicensePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$AcceptSelfSignedCert,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [psobject]$SecurityManagerCredential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Scanner,
        [Parameter(ValueFromPipelineByPropertyName)]
        [psobject]$ScannerCredential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$InitializeScanner,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Organization,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Repository,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ScanZone = "All Computers",
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$ScanCredentialHash,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$IpRange,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$PolicyFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$ScanFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$AuditFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$DashboardFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$AssetFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$ReportFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$FeedFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$PluginFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$EnableException
    )
    begin {
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $started = Get-Date
        $PSDefaultParameterValues["*:EnableException"] = $true
        $servertype = "tenable.sc"


        if ($AcceptSelfSignedCert) {
            $PSDefaultParameterValues['*-TN*:AcceptSelfSignedCert'] = $true
        }
    }
    process {
        if ($PSBoundParameters.Scanner -and -not $PSBoundParameters.ScannerCredential) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must provide a ScannerCredential when specifying a Scanner"
            return
        }

        if ($PSBoundParameters.PolicyFilePath -and -not $PSBoundParameters.FeedFilePath) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must provide a FeedFilePath when specifying a PolicyFilePath. Not sure why, but no Policy File uploads work without an initial feed update."
            return
        }

        if ($PSBoundParameters.InitializeScanner -and -not $PSBoundParameters.ScannerCredential) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must provide a ScannerCredential when specifying a InitializeScanner"
            return
        }

        if ($AdministratorCredential -isnot [pscredential]) {
            $AdministratorCredential = Get-Credential $AdministratorCredential -Message "Enter the username and password for the administrator credential on the $servertype server"
        }

        if ($PSBoundParameters.ScannerCredential -and $ScannerCredential -isnot [pscredential]) {
            $ScannerCredential = Get-Credential $ScannerCredential -Message "Enter the administrator username and password for the Nessus scanner"
        }

        if ($SecurityManagerCredential -isnot [pscredential]) {
            $SecurityManagerCredential = Get-Credential $SecurityManagerCredential -Message "Enter the username and password for the Security Manager credential for the organization $Organization"
        }

        foreach ($computer in $ComputerName) {
            $stepCounter = 0
            $output = @{
                ComputerName = $computer
                ServerType   = "tenable.sc"
            }
            if ($LicensePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Initializing $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Initializing $computer"
                    if ($InitializeScanner -and $ScannerCredential) {
                        $splat = @{
                            ComputerName    = $computer
                            Credential      = $ScannerCredential
                            Type            = "Nessus"
                            ManagedScanner  = $true
                            EnableException = $true
                            ErrorAction     = "Stop"
                        }

                        $null = Initialize-TNServer @splat
                    }
                    $splat = @{
                        ComputerName    = $computer
                        Credential      = $AdministratorCredential
                        LicensePath     = $LicensePath
                        Type            = "tenable.sc"
                        EnableException = $true
                        ErrorAction     = "Stop"
                    }

                    $null = Initialize-TNServer @splat
                    $output["LicensePath"] = $LicensePath
                    $output["Administrator"] = $AdministratorCredential.Username
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Initialization failed for $computer" -Continue
                }
            }

            # Connect as admin
            try {
                Write-PSFMessage -Level Verbose -Message "Connecting to $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer"
                $null = Connect-TNServer -ComputerName $computer -Credential $AdministratorCredential -Type $servertype
                $null = Connect-TNServer -Type tenable.sc -Credential $AdministratorCredential -ComputerName securitycenter
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Connect failed for $computer" -Continue
            }

            # Scanner Credentials
            if ($ScanCredentialHash) {
                Write-PSFMessage -Level Verbose -Message "Creating credentials on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating credentials on $computer"
                try {
                    foreach ($scancred in $ScanCredentialHash) {
                        if ($scancred -is [hashtable]) {
                            $null = New-TNCredential @scancred
                        } else {
                            $splat = ConvertTo-Hashtable $scancred
                            $null = New-TNCredential @splat
                        }
                    }
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Credential creation failed for $computer" -Continue
                }

                $output["ScanCredential"] = $ScanCredentialHash.Name
            }

            # Org
            try {
                Write-PSFMessage -Level Verbose -Message "Creating an organization on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating an organization on $computer"
                $null = New-TNOrganization -Name $Organization
                $output["Organization"] = $Organization
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Creation of organization failed for $computer" -Continue
            }

            # Repository
            try {
                Write-PSFMessage -Level Verbose -Message "Creating a repository on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating a repository on $computer"
                $null = New-TNRepository -Name $Repository -IpRange $IpRange
                $output["Repository"] = $Repository
                $output["IpRange"] = $IpRange
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Creation of repository failed for $computer" -Continue
            }

            # Add org to repository
            try {
                Write-PSFMessage -Level Verbose -Message "Adding organization $Organization to repository $Repository on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding organization $Organization to repository $Repository on $computer"
                $null = Set-TNRepositoryProperty -Name $Repository -Organization $Organization
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Creation of repository failed for $computer" -Continue
            }

            # Organization User
            try {
                Write-PSFMessage -Level Verbose -Message "Creating an organization user on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating an organization user on $computer"
                $null = New-TNOrganizationUser -Organization $Organization -Credential $SecurityManagerCredential
                $output["SecurityManager"] = $SecurityManagerCredential.UserName
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Creation of organization user $($SecurityManagerCredential.Username) failed for $computer" -Continue
            }

            # Scanner
            if ($Scanner) {
                if ($InitializeScanner) { Start-Sleep 3 }
                try {
                    foreach ($scannername in $scanner) {
                        Write-PSFMessage -Level Verbose -Message "Adding scanner $scannername"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding scanner $scannername"
                        $splat = @{
                            ComputerName = $scannername
                            Credential   = $ScannerCredential
                        }
                        $null = Add-TNScanner @splat
                    }
                    $output["Scanner"] = $Scanner
                    $output["ScannerCredential"] = $ScannerCredential.Username
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Failed to add scanners" -Continue
                }
            }

            # Scan Zone
            try {
                Write-PSFMessage -Level Verbose -Message "Creating scan zones on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating scan zones on $computer"
                $null = New-TNScanZone -Name $ScanZone -IPRange $IpRange -Description "All organization computers"
                $output["ScanZone"] = $ScanZone

                if ($PSBoundParameters.Scanner) {
                    $null = Set-TNScanZoneProperty -Name $ScanZone -Scanner $Scanner
                }
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Creation of scan zone failed for $computer" -Continue
            }



            # Update Feed
            if ($FeedFilePath) {
                Write-PSFMessage -Level Verbose -Message "Updating feed on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Updating feed on $computer"
                try {
                    $null = Update-TNPluginFeed -Type Feed -FilePath $FeedFilePath -Wait
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Feed update failed for $computer" -Continue
                }

                $output["FeedFilePath"] = $FeedFilePath
            }

            # Update active plugins
            if ($PluginFilePath) {
                Write-PSFMessage -Level Verbose -Message "Updating active plugins on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Updating active plugins on $computer"
                try {
                    $null = Update-TNPluginFeed -Type ActivePlugin -FilePath $PluginFilePath -Wait
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Feed update failed for $computer" -Continue
                }

                $output["PluginFilePath"] = $PluginFilePath
            }


            # Import policy
            if ($PSBoundParameters.PolicyFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Importing policies from $PolicyFilePath on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing policies from $PolicyFilePath on $computer"
                    $results = Import-TNPolicy -FilePath $PolicyFilePath -EnableException:$EnableException
                    $output["ImportedPolicy"] = $results.Name
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Policy import failed for $computer" -Continue
                }
            }

            # Connect as security manager
            try {
                $null = Remove-TNSession -SessionId 0
                Write-PSFMessage -Level Verbose -Message "Connecting to $computer as $($SecurityManagerCredential.Username)"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer"
                $null = Connect-TNServer -ComputerName $computer -Credential $SecurityManagerCredential -Type $servertype
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Connect failed for $computer as $($SecurityManagerCredential.Username)" -Continue
            }

            # Report Attribute
            try {
                Write-PSFMessage -Level Verbose -Message "Creating DISA report attribute on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating DISA report attribute on $computer"
                $null = New-TNReportAttribute -Name DISA
                $output["ReportAttribute"] = "DISA"
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "DISA report attribute creation failed for $computer" -Continue
            }

            # Import report
            if ($PSBoundParameters.ReportFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Importing reports from $ReportFilePath on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing reports from $ReportFilePath on $computer"
                    $results = Import-TNReport -FilePath $ReportFilePath
                    $output["ImportedReport"] = $results.Name
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Report import failed for $computer" -Continue
                }
            }

            # Import audits
            if ($PSBoundParameters.AuditFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Importing audits from $AuditFilePath on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing audits from $AuditFilePath on $computer"
                    $results = Import-TNAudit -FilePath $AuditFilePath
                    $output["ImportedAudit"] = $results.Name


                    Write-PSFMessage -Level Verbose -Message "Converting audits to policies on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Converting audits to policies on $computer"
                    $results = New-TNPolicy -Auto
                    $output["AuditPolicy"] = $results.Name
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Converting audits to policies failed for $computer" -Continue
                }
            }

            # Import dashboard
            if ($PSBoundParameters.DashboardFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Importing dashboards from $DashboardFilePath on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing dashboards from $DashboardFilePath on $computer"
                    $results = Import-TNDashboard -FilePath $DashboardFilePath
                    $output["ImportedDashboard"] = $results.Name
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Dashboard import failed for $computer" -Continue
                }
            }

            # Import asset
            if ($PSBoundParameters.AssetFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Importing assets from $AssetFilePath on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing assets from $AssetFilePath on $computer"
                    $results = Import-TNAsset -FilePath $AssetFilePath
                    $output["ImportedAsset"] = $results.Name
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Asset import failed for $computer" -Continue
                }
            }

            # Auto Scans!
            if ($PSBoundParameters.PolicyFilePath -or $PSBoundParameters.AuditFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Creating scans on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating scans on $computer"
                    $scans = New-TNScan -Auto -TargetIpRange $IpRange
                    $output["Scans"] = $scans.Name
                    if ($PSBoundParameters.ScanCredentialHash) {
                        $null = Set-TNScanProperty -Name $scans.Name -ScanCredential $ScanCredentialHash.Name
                    }
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Scan creation failed for $computer" -Continue
                }
            }

            if ($PSBoundParameters.ScanFilePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Importing scans on $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing scans on $computer"
                    $results = Import-TNScan -FilePath $ScanFilePath
                    $output["ImportedScans"] = $results.Name
                    foreach ($scanname in $results.Name) {
                        if ($PSBoundParameters.ScanCredentialHash) {
                            $null = Set-TNScanProperty -Name $scans.Name -ScanCredential $ScanCredentialHash.Name
                        }
                        if ($PSBoundParameters.Repository) {
                            $null = Set-TNScanProperty -Name $scans.Name -Repository $Repository
                        }
                        if ($PSBoundParameters.IpRange) {
                            $null = Set-TNScanProperty -Name $scans.Name -IpRange $IpRange
                        }
                    }
                } catch {
                    Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Scan import failed for $computer" -Continue
                }
            }

            # Create ASR Report
            try {
                Write-PSFMessage -Level Verbose -Message "Creating DISA ASR report on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating DISA ASR report on $computer"
                $null = New-TNDisaAsrReport -Name "DISA ASR" -Description "DISA Detailed Asset Summary Reporting"
                $output["DISADetailedASR"] = "DISA ASR"
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Policy import failed for $computer" -Continue
            }

            Write-Progress -Activity "Finished deploying $computer for $servertype" -Completed

            $output["Status"] = "Success"
            [pscustomobject]$output | ConvertFrom-TNRestResponse
        }
    }
    end {
        $totalTime = ($elapsed.Elapsed.toString().Split(".")[0])
        Write-PSFMessage -Level Verbose -Message "Export started: $started"
        Write-PSFMessage -Level Verbose -Message "Export completed: $(Get-Date)"
        Write-PSFMessage -Level Verbose -Message "Total Elapsed time: $totalTime"
    }
}