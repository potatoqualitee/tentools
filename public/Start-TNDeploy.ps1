function Start-TNDeploy {
    <#
    .SYNOPSIS
        Starts a list of deploys

    .DESCRIPTION
        Starts a list of deploys

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
            ServerType = ""
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

        $admincred = Get-Credential admin2
        $secmancred = Get-Credential secmancred2
        $splat = @{
        ComputerName = "securitycenter"
        AdministratorCredential = $admincred
        ServerType = "tenable.sc"
        SecurityManagerCredential = $secmancred
        Organization = "Acme"
        Repository = "All Computers"
        ScanZone = "All Computers"
        IpRange = "192.168.0.0/24"
        PolicyFilePath = "C:\nessus\library\policy.nessus"
    }
    Start-TNDeploy -Verbose

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int]$Port,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Management.Automation.PSCredential]$AdministratorCredential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$LicensePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$AcceptSelfSignedCert,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet("tenable.sc", "Nessus")]
        [string]$ServerType,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Management.Automation.PSCredential]$SecurityManagerCredential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Scanner,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Management.Automation.PSCredential]$ScannerCredential,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Organization,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Repository,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ScanZone = "All Computers",
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$ScanCredentialHash,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$IpRange,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$PolicyFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$ScanFilePath,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$EnableException
    )
    begin {
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $started = Get-Date
        $PSDefaultParameterValues["*:EnableException"] = $true
    }
    process {
        if ($PSBoundParameters.Scanner -and -not $PSBoundParameters.ScannerCredential) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must provide a ScannerCredential when specifying a Scanner"
            return
        }

        foreach ($computer in $ComputerName) {
            $stepCounter = 0
            $output = @{
                ComputerName = $computer
                ServerType   = $ServerType
            }
            if ($LicensePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Initializing $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Initializing $computer"
                    $splat = @{
                        ComputerName = $computer
                        Credential   = $AdministratorCredential
                        LicensePath  = $LicensePath
                    }
                    Initialize-TNServer @splat
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
                $null = Connect-TNServer -ComputerName $computer -Credential $AdministratorCredential -Type $ServerType
                $null = Connect-TNServer -Type tenable.sc -Credential $AdministratorCredential -ComputerName securitycenter
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Connect failed for $computer" -Continue
            }

            if ($Scanner) {
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

            # Import policy
            try {
                Write-PSFMessage -Level Verbose -Message "Importing policies on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing policies on $computer"
                $results = Import-TNPolicy -FilePath $PolicyFilePath
                $output["ImportedPolicy"] = $results.Name
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Policy import failed for $computer" -Continue
            }

            # Connect as security manager
            try {
                $null = Remove-TNSession -SessionId 0
                Write-PSFMessage -Level Verbose -Message "Connecting to $computer as $($SecurityManagerCredential.Username)"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer"
                $null = Connect-TNServer -ComputerName $computer -Credential $SecurityManagerCredential -Type $ServerType
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

            # Scans!
            try {
                Write-PSFMessage -Level Verbose -Message "Creating scans on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating scans on $computer"
                $scans = New-TNScan -Auto -Target $IpRange
                $output["Scans"] = $scans.Name

                if ($PSBoundParameters.ScanCredentialHash) {
                    $null = Set-TNScanProperty -Name $scans.Name -ScanCredential $ScanCredentialHash.Name
                }
            } catch {
                Stop-PSFFunction -ErrorRecord $_ -EnableException:$EnableException -Message "Scan creation failed for $computer" -Continue
            }

            Write-Progress -Activity "Finished deploying $computer for $ServerType" -Completed

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