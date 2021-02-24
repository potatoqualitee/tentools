function Set-TNCertificate {
    <#
    .SYNOPSIS
        Sets certificates for both Nessus and Tenable.sc. Note,this stops and restarts services.

    .DESCRIPTION
        Sets certificates for both Nessus and Tenable.sc. Note,this stops and restarts services.

        This command only works on a Windows machine with WinSCP installed and ony works when the destination server is running linux

    .PARAMETER ComputerName
        Target Nessus or Tenable.sc IP Address or FQDN

    .PARAMETER Port
        Port number of the Nessus SSH service. Defaults to 22.

    .PARAMETER Credential
        The credential to login. This user must have access to restart services and replace keys.

    .PARAMETER CertPath
        The path to the public certificate

    .PARAMETER KeyPath
        The path to the private key

    .PARAMETER CaCertPath
        The path to the CA public key

    .PARAMETER Type
        Nessus or Tenable.sc. Defaults to both.

    .PARAMETER Method
        Transfer method - SSH or WinRM. Currently, only SSH is implemented.

    .PARAMETER SshHostKeyFingerprint
        Fingerprint of SSH server host key (or several alternative fingerprints separated by semicolon). It makes WinSCP automatically accept host key with the fingerprint. Use SHA-256 fingerprint of the host key. Use AcceptAnyThumbprint if needed.

    .PARAMETER AcceptAnyThumbprint
        Give up security and accept any SSH host key. To be used in exceptional situations only, when security is not required. When set, log files will include warning about insecure connection. To maintain security, use SshHostKeyFingerprint.

    .PARAMETER SecurePrivateKeyPassphrase
        Encrypted passphrase for encrypted private keys and client certificates. Use instead of PrivateKeyPassphrase to reduce a number of unencrypted copies of the passphrase in memory.

    .PARAMETER SshPrivateKeyPath
        Full path to SSH private key file.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Set-TNCertificate -ComputerName securitycenter.ad.local -Credential acasadmin -CertPath C:\sc\cert.pem -KeyPath C:\sc\serverkey.key

        Logs into securitycenter.ad.local with the acasadmin credential and installs cert.pem and serverkey.key to both nessus and securitycenter.

    .EXAMPLE
        PS> # export cert to pfx without extended properties
        PS> openssl pkcs12 -in nessus.pfx -nokeys -out cert.pem
        PS> openssl pkcs12 -in nessus.pfx -nocerts -out serverkey.pem -nodes
        PS> openssl rsa -in serverkey.pem -out serverkey.key
        PS> Set-TNCertificate -ComputerName securitycenter -Credential acasadmin -CertPath C:\sc\cert.pem -KeyPath C:\sc\serverkey.key -Verbose -AcceptAnyThumbprint
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [parameter(Mandatory)]
        [string]$CertPath,
        [parameter(Mandatory)]
        [string]$KeyPath,
        [string]$CaCertPath,
        [ValidateSet("tenable.sc", "Nessus")]
        [string[]]$Type = @("tenable.sc", "Nessus"),
        [ValidateSet("SSH", "WinRM")]
        [string]$Method = "SSH",
        [int]$SshPort,
        [string]$SshHostKeyFingerprint,
        [switch]$AcceptAnyThumbprint,
        [securestring]$SecurePrivateKeyPassphrase,
        [string]$SshPrivateKeyPath,
        [switch]$EnableException
    )
    process {
        if (-not ($winscp = Get-Command WinScp)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "WinScp must be installed to run this command"
            return
        }

        if (-not (Test-Path -Path $CertPath)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$CertPath does not exist"
            return
        }

        if (-not (Test-Path -Path $KeyPath)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$KeyPath does not exist"
            return
        }

        if ($PSBoundParameters.CaCertPath -and -not (Test-Path -Path $CaCertPath)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$CaCertPath does not exist"
            return
        }

        $CertPath = Resolve-Path -Path $CertPath
        $KeyPath = Resolve-Path -Path $KeyPath


        if ($PSBoundParameters.CaCertPath) {
            $CaCertPath = Resolve-Path -Path $CaCertPath
        }

        $txt = Get-Content -Path $CertPath -Raw
        if ($txt -notmatch "-----BEGIN CERTIFICATE-----" -and $txt -notmatch "-----END CERTIFICATE-----") {
            Stop-PSFFunction -EnableException:$EnableException -Message "$CertPath does not appear to be a valid cert (must contain the text -----BEGIN CERTIFICATE----- and -----END CERTIFICATE-----)"
            return

        }

        $txt = Get-Content -Path $KeyPath -Raw
        if ($txt -notmatch "KEY") {
            Stop-PSFFunction -EnableException:$EnableException -Message "$KeyPath does not appear to be a valid key (must contain the text 'KEY')"
            return
        }

        foreach ($computer in $ComputerName) {
            $results += @()
            $stepCounter = 0
            if ($Method -eq "SSH") {
                try {
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Loading up WinSCP"

                    $dir = "C:\Program Files (x86)\WinSCP\"
                    if (-not (Test-Path -Path $dir)) {
                        $dir = Split-Path -Path $winscp.Source
                    }

                    $dll = Join-Path -Path $dir -ChildPath WinSCPnet.dll

                    if (-not (Test-Path -Path $dir)) {
                        Stop-PSFFunction -EnableException:$EnableException -Message "Can't find WinSCPnet.dll :("
                        return
                    } else {
                        Add-Type -Path $dll
                    }

                    Write-PSFMessage -Level Verbose -Message "Loaded WinSCP and parsed text files, looks good"

                    # Setup session options
                    $winscpsessionOptions = New-Object WinSCP.SessionOptions -Property @{
                        Protocol                             = [WinSCP.Protocol]::Sftp
                        HostName                             = $computer
                        UserName                             = $Credential.UserName
                        SecurePassword                       = $Credential.Password
                        GiveUpSecurityAndAcceptAnySshHostKey = $AcceptAnyThumbprint
                    }

                    if ($SshHostKeyFingerprint) {
                        $winscpsessionOptions.SshHostKeyFingerprint = $SshHostKeyFingerprint
                    }
                    if ($SshPort) {
                        $winscpsessionOptions.PortNumber = $SshPort
                    }
                    if ($SecurePrivateKeyPassphrase) {
                        $winscpsessionOptions.SecurePrivateKeyPassphrase = $SecurePrivateKeyPassphrase
                    }
                    if ($SshPrivateKeyPath) {
                        $winscpsessionOptions.SshPrivateKeyPath = $SshPrivateKeyPath
                    }

                    Write-PSFMessage -Level Verbose -Message "Setup session options for WinSCP"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $computer"
                    $winscpsession = New-Object WinSCP.Session
                    $winscpsession.Open($winscpsessionOptions)

                    $transferOptions = New-Object WinSCP.TransferOptions
                    $transferOptions.TransferMode = [WinSCP.TransferMode]::Ascii
                    $transferOptions.OverwriteMode = [WinSCP.OverwriteMode ]::Overwrite

                    if ("Nessus" -in $Type) {
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping the nessus service"
                        Write-PSFMessage -Level Verbose -Message "Stopping nessusd"
                        $command = "service nessusd stop"
                        $null = $winscpsession.ExecuteCommand($command).Check()
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding files to Nessus"

                        Write-PSFMessage -Level Verbose -Message "Backing up files if they exist"
                        $command = "[ -f /opt/nessus/com/nessus/CA/servercert.pem ] && mv /opt/nessus/com/nessus/CA/servercert.pem /opt/nessus/com/nessus/CA/servercert.bak"
                        $null = $winscpsession.ExecuteCommand($command).Check()
                        $command = "[ -f /opt/nessus/var/nessus/CA/serverkey.pem ] && mv /opt/nessus/var/nessus/CA/serverkey.pem /opt/nessus/com/nessus/CA/serverkey.bak"
                        $null = $winscpsession.ExecuteCommand($command).Check()

                        Write-PSFMessage -Level Verbose -Message "Uploading $CertPath to /opt/nessus/com/nessus/CA/servercert.pem"
                        $results += $winscpsession.PutFiles($CertPath, "/opt/nessus/com/nessus/CA/servercert.pem", $false, $transferOptions)

                        Write-PSFMessage -Level Verbose -Message "Uploading $KeyPath to /opt/nessus/var/nessus/CA/serverkey.pem"
                        $results += $winscpsession.PutFiles($KeyPath, "/opt/nessus/var/nessus/CA/serverkey.pem", $false, $transferOptions)


                        $command = "chown tns:tns /opt/nessus/com/nessus/CA/servercert.pem"
                        $null = $winscpsession.ExecuteCommand($command).Check()

                        $command = "chown tns:tns /opt/nessus/var/nessus/CA/serverkey.pem"
                        $null = $winscpsession.ExecuteCommand($command).Check()

                        if ($CaCertPath) {
                            Write-PSFMessage -Level Verbose -Message "Uploading $CaCertPath to /opt/nessus/lib/nessus/plugins/custom_CA.inc"
                            $results += $winscpsession.PutFiles($CaCertPath, "/opt/nessus/lib/nessus/plugins/custom_CA.inc", $false, $transferOptions)
                            $command = "chown tns:tns /opt/nessus/lib/nessus/plugins/custom_CA.inc"
                            $null = $winscpsession.ExecuteCommand($command).Check()
                        }
                    }
                    if ("tenable.sc" -in $Type) {
                        Write-PSFMessage -Level Verbose -Message "Stopping securitycenter"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping securitycenter"
                        $command = "service SecurityCenter stop"
                        $null = $winscpsession.ExecuteCommand($command).Check()
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding files to tenable.sc"
                        Write-PSFMessage -Level Verbose -Message "Uploading $CertPath to /opt/sc/support/conf/SecurityCenter.crt"
                        $results += $winscpsession.PutFiles($CertPath, "/opt/sc/support/conf/SecurityCenter.crt", $false, $transferOptions)

                        Write-PSFMessage -Level Verbose -Message "Uploading $KeyPath to /opt/sc/support/conf/SecurityCenter.key"
                        $results += $winscpsession.PutFiles($KeyPath, "/opt/sc/support/conf/SecurityCenter.key", $false, $transferOptions)
                        if ($CaCertPath) {
                            Write-PSFMessage -Level Verbose -Message "Uploading $CaCertPath to /tmp/custom_CA.inc"
                            $results += $winscpsession.PutFiles($CaCertPath, "/tmp/custom_CA.inc", $false, $transferOptions)
                        }

                        if ($CaCertPath) {
                            Write-PSFMessage -Level Verbose -Message "Installing CA cert on securitycenter"
                            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Installing CA cert on securitycenter"
                            $command = "/opt/sc/support/bin/php /opt/sc/src/tools/installCA.php /tmp/custom_CA.inc"
                            try {
                                $null = $winscpsession.ExecuteCommand($command).Check()
                            } catch {
                                # seems like it works but then it gives an error so catch it
                                # i am unsure if removing .Check() waits for the command to run, so I'll just leave it in and catch
                            }
                        }

                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting securitycenter"
                        Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                        $command = "service SecurityCenter start"
                        $null = $winscpsession.ExecuteCommand($command).Check()
                    }

                    if ("Nessus" -in $Type) {
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                        Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                        $command = "service nessusd start"
                        $null = $winscpsession.ExecuteCommand($command).Check()
                    }


                    foreach ($result in $results) {
                        [pscustomobject]@{
                            ComputerName = $computer
                            FileName     = $result.Transfers.FileName
                            Destination  = $result.Transfers.Destination
                            ErrorMessage = $result.Transfers.Error
                            Failures     = $result.Failures
                            Success      = $result.IsSuccess
                        }
                    }
                } catch {
                    $record = $_
                    if ("Nessus" -in $Type -and $winscpsession.Opened) {
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                        Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                        $command = "service nessusd start"
                        try {
                            $null = $winscpsession.ExecuteCommand($command).Check()
                        } catch {
                            # don't care
                        }
                    }

                    if ("tenable.sc" -in $Type -and $winscpsession.Opened) {
                        Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the securitycenter service"
                        Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                        $command = "service SecurityCenter start"
                        try {
                            $null = $winscpsession.ExecuteCommand($command).Check()
                        } catch {
                            # don't care
                        }
                    }

                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername" -ErrorRecord $record -Continue
                }
            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only SSH and Linux are supported at this time"
                return
            }
            if ($winscpsession.Opened) {
                $winscpsession.Close()
                $winscpsession.Dispose()
            }
        }
    }
}