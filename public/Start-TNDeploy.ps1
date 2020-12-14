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

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Start-TNDeploy

        Starts a list of deploys

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [int]$Port,
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$AdministratorCredential,
        [string]$LicensePath,
        [switch]$AcceptSelfSignedCert,
        [Parameter(Mandatory)]
        [ValidateSet("tenable.sc", "Nessus")]
        [string]$ServerType,
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$SecurityManagerCredential,
        [Parameter(Mandatory)]
        [string]$Organization,
        [Parameter(Mandatory)]
        [string]$Repository,
        [string]$ScanZone = "All Computers",
        [hashtable]$ScanCredentialHash,
        [Parameter(Mandatory)]
        [string[]]$IpRange,
        [Parameter(Mandatory)]
        [string[]]$PolicyFilePath,
        [string[]]$ScanFilePath,
        [switch]$EnableException
    )
    begin {
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $started = Get-Date
        $PSDefaultParameterValues["*:EnableException"] = $true
    }
    process {
        foreach ($computer in $ComputerName) {
            $stepCounter = 0
            if ($LicensePath) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Initializing $computer"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Initializing $computer"
                    $splat = @{
                        ComputerName = $computer
                        Credential   = $Credential
                        LicensePath  = $LicensePath
                    }
                    Initialize-TNServer @splat
                } catch {
                    Stop-PSFunction -EnableException:$EnableException -Message "Initialization failed for $computer" -Continue
                }
            }

            # Connect
            try {
                Write-PSFMessage -Level Verbose -Message "Connecting to $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer"
                $null = Connect-TNServer -ComputerName $computer -Credential $AdministratorCredential -Type $ServerType
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Connect failed for $computer" -Continue
            }

            # Org
            try {
                Write-PSFMessage -Level Verbose -Message "Creating an organization on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating an organization on $computer"
                $null = New-TNOrganization -Name $Organization
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Creation of organization failed for $computer" -Continue
            }

            # Repository
            try {
                Write-PSFMessage -Level Verbose -Message "Creating a repository on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating a repository on $computer"
                $null = New-TNRepository -Name $Repository -IpRange $IpRange
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Creation of repository failed for $computer" -Continue
            }

            # Organization User
            try {
                Write-PSFMessage -Level Verbose -Message "Creating an organization user on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating an organization user on $computer"
                $null = New-TNOrganizationUser -Organization $Organization -Credential $SecurityManagerCredential
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Creation of organization user $($SecurityManagerCredential.Username) failed for $computer" -Continue
            }

            # Scanner Credentials
            if ($ScanCredentialHash) {
                Write-PSFMessage -Level Verbose -Message "Creating credentials on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating credentials on $computer"
                try {
                    $null = New-TNCredential -Name "Windows Domain User" -Description "The user that has access to run scans on Windows computers" -AuthType password -Type windows -Credential windowsuser
                } catch {
                    Stop-PSFunction -EnableException:$EnableException -Message "Credential creation failed for $computer" -Continue
                }
            }

            # Scan Zone
            try {
                Write-PSFMessage -Level Verbose -Message "Creating scan zones on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating scan zones on $computer"
                $null = New-TNScanZone -Name $ScanZone -IPRange $IpRange -Description "All organization computers"
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Creation of scan zone failed for $computer" -Continue
            }

            # Report Attribute
            try {
                Write-PSFMessage -Level Verbose -Message "Creating DISA report attribute on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating DISA report attribute on $computer"
                $null = New-TNReportAttribute -Name DISA
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "DISA report attribute creation failed for $computer" -Continue
            }

            # Import policy
            try {
                Write-PSFMessage -Level Verbose -Message "Importing policies on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Importing policies on $computer"
                $null = Import-TNPolicy -FilePath $PolicyFilePath
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Policy import failed for $computer" -Continue
            }

            # Scans!
            try {
                Write-PSFMessage -Level Verbose -Message "Creating scans on $computer"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Creating scans on $computer"
                $null = New-TNScan -Auto -Target $IpRange
            } catch {
                Stop-PSFunction -EnableException:$EnableException -Message "Policy import failed for $computer" -Continue
            }

            Write-Progress -Activity "Finished deploying $computer for $ServerType" -Completed
        }
    }
    end {
        $totalTime = ($elapsed.Elapsed.toString().Split(".")[0])
        Write-PSFMessage -Level Verbose -Message "Export started: $started"
        Write-PSFMessage -Level Verbose -Message "Export completed: $(Get-Date)"
        Write-PSFMessage -Level Verbose -Message "Total Elapsed time: $totalTime"
    }
}