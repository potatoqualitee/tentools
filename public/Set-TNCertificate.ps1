function Set-TNCertificate {
    <#
    .SYNOPSIS
        Sets certificates for both Nessus and Tenable.sc. Note,this stops and restarts services.

    .DESCRIPTION
        Sets certificates for both Nessus and Tenable.sc. Note,this stops and restarts services.

        This command only works when the destination server is running linux

    .PARAMETER ComputerName
        Target Nessus or Tenable.sc IP Address or FQDN

    .PARAMETER Credential
        The credential to login. This user must have access to restart services and replace keys.

        Basically, the user must have access.

    .PARAMETER SshSession
        If you use a private key to connect to your server, use New-SshSession to configure what you need and pass it to SShSession instead of using ComputerName and Credential

    .PARAMETER Port
        Port number of the Nessus SSH service. Defaults to 22.

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

    .PARAMETER AcceptAnyThumbprint
        Give up security and accept any SSH host key. To be used in exceptional situations only, when security is not required. To set, use Posh-SSH commands.

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
        [object]$SshSession,
        [object]$SftpSession,
        [string]$ComputerName,
        [Management.Automation.PSCredential]$Credential,
        [parameter(Mandatory)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$CertPath,
        [parameter(Mandatory)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$KeyPath,
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$CaCertPath,
        [ValidateSet("tenable.sc", "Nessus")]
        [string[]]$Type = @("tenable.sc", "Nessus"),
        [ValidateSet("SSH", "WinRM")]
        [string]$Method = "SSH",
        [int]$SshPort = 22,
        [switch]$AcceptAnyThumbprint,
        [switch]$EnableException
    )
    process {
        if ($Method -ne "SSH") {
            Stop-PSFFunction -EnableException:$EnableException -Message "Only SSH and Linux are supported at this time"
            return
        }

        if ((-not $PSBoundParameters.SshSession -and -not $PSBoundParameters.SftpSession) -and -not ($PSBoundParameters.ComputerName -and $PSBoundParameters.Credential)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify either SshSession and SftpSession or ComputerName and Credential"
            return
        }

        # Set default parameter values
        $PSDefaultParameterValues['*-SSH*:ErrorAction'] = "Stop"
        $PSDefaultParameterValues['*-SCP*:ErrorAction'] = "Stop"
        $PSDefaultParameterValues['*-SCP*:Credential'] = $Credential
        $PSDefaultParameterValues['*-SSH*:Credential'] = $Credential
        $PSDefaultParameterValues['*-SSH*:ComputerName'] = $ComputerName
        $PSDefaultParameterValues['*-SCP*:ComputerName'] = $ComputerName
        $PSDefaultParameterValues['*-SCP*:AcceptKey'] = [bool]$AcceptAnyThumbprint
        $PSDefaultParameterValues['*-SSH*:AcceptKey'] = [bool]$AcceptAnyThumbprint

        # The SCP copy relies on the name being right, so "rename" it in temp
        $temp = [System.IO.Path]::GetTempPath()

        Copy-Item -Path $CertPath -Destination (Join-Path -Path $temp -ChildPath servercert.pem) -Force
        Copy-Item -Path $CertPath -Destination (Join-Path -Path $temp -ChildPath SecurityCenter.crt) -Force
        $CertPath = Join-Path -Path $temp -ChildPath servercert.pem
        $ScCertPath = Join-Path -Path $temp -ChildPath SecurityCenter.crt

        Copy-Item -Path $KeyPath -Destination (Join-Path -Path $temp -ChildPath serverkey.pem) -Force
        Copy-Item -Path $KeyPath -Destination (Join-Path -Path $temp -ChildPath SecurityCenter.key) -Force
        $KeyPath = Join-Path -Path $temp -ChildPath serverkey.pem
        $ScKeyPath = Join-Path -Path $temp -ChildPath SecurityCenter.key

        if ($CaCertPath) {
            Copy-Item -Path $CaCertPath -Destination (Join-Path -Path $temp -ChildPath custom_CA.inc) -Force
            $CaCertPath = Join-Path -Path $temp -ChildPath custom_CA.inc
        }

        $stepCounter = 0
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

        try {
            Write-PSFMessage -Level Verbose -Message "Connecting to $ComputerName"

            if (-not $PSBoundParameters.SshSession) {
                $SshSession = New-SSHSession -Port $SshPort
            }
            if (-not $PSBoundParameters.SftpSession) {
                $SftpSession = New-SFTPSession -ComputerName $ComputerName -Credential $Credential -Port $SshPort
            }

            $PSDefaultParameterValues['*-SCP*:SessionId'] = $SshSession.SessionId
            $PSDefaultParameterValues['*-SSH*:SessionId'] = $SshSession.SessionId
            $PSDefaultParameterValues['*-SFTP*:SFTPSession'] = $SftpSession
            $PSDefaultParameterValues['*-SFTP*:Force'] = $true

            If ($PSBoundParameters.Credential -and $Credential.UserName -ne "root") {
                $stream = $SshSession.Session.CreateShellStream("PS-SSH", 0, 0, 0, 0, 1000)
                Write-PSFMessage -Level Verbose -Message "Logging in using sudo"
                $results = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo ls" -ExpectString "[sudo] password for $($Credential.UserName):" -SecureAction $Credential.Password

                Write-PSFMessage -Level Verbose -Message "Sudo: $results"
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $ComputerName"

            if ("Nessus" -in $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping the nessus service"
                Write-PSFMessage -Level Verbose -Message "Stopping nessusd"
                $command = "sudo service nessusd stop"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding files to Nessus"

                Write-PSFMessage -Level Verbose -Message "Backing up files if they exist"
                $command = "sudo [ -f /opt/nessus/com/nessus/CA/servercert.pem ] && sudo mv /opt/nessus/com/nessus/CA/servercert.pem /opt/nessus/com/nessus/CA/servercert.bak"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
                $command = "sudo [ -f /opt/nessus/var/nessus/CA/serverkey.pem ] && sudo mv /opt/nessus/var/nessus/CA/serverkey.pem /opt/nessus/com/nessus/CA/serverkey.bak"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Write-PSFMessage -Level Verbose -Message "Uploading $CertPath to /opt/nessus/com/nessus/CA/servercert.pem"
                $null = Set-SFTPItem -Destination /tmp -Path $CertPath
                $command = "sudo mv /tmp/servercert.pem /opt/nessus/com/nessus/CA/"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Write-PSFMessage -Level Verbose -Message "Uploading $KeyPath to /opt/nessus/var/nessus/CA/serverkey.pem"
                $null = Set-SFTPItem -Destination /tmp -Path $KeyPath
                $command = "sudo mv /tmp/serverkey.pem /opt/nessus/var/nessus/CA/"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                $command = "chown tns:tns /opt/nessus/com/nessus/CA/servercert.pem"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                $command = "chown tns:tns /opt/nessus/var/nessus/CA/serverkey.pem"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                if ($CaCertPath) {
                    Write-PSFMessage -Level Verbose -Message "Uploading $CaCertPath to /opt/nessus/lib/nessus/plugins/custom_CA.inc"
                    $null = Set-SFTPItem -Destination /tmp -Path $CaCertPath
                    $command = "sudo mv /tmp/custom_CA.inc /opt/nessus/lib/nessus/plugins/"
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -ne 1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                    $command = "chown tns:tns /opt/nessus/lib/nessus/plugins/custom_CA.inc"
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -ne 1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                }
            }
            if ("tenable.sc" -in $Type) {
                Write-PSFMessage -Level Verbose -Message "Stopping securitycenter"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping securitycenter"
                $command = "sudo service SecurityCenter stop"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding files to tenable.sc"
                Write-PSFMessage -Level Verbose -Message "Uploading $CertPath to /opt/sc/support/conf/SecurityCenter.crt"
                $null = Set-SFTPItem -Destination /tmp -Path $ScCertPath
                $command = "sudo mv /tmp/SecurityCenter.crt /opt/sc/support/conf/"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }


                Write-PSFMessage -Level Verbose -Message "Uploading $KeyPath to /opt/sc/support/conf/SecurityCenter.key"
                $null = Set-SFTPItem -Destination /tmp -Path $ScKeyPath
                $command = "sudo mv /tmp/SecurityCenter.key /opt/sc/support/conf/"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }


                if ($CaCertPath) {
                    Write-PSFMessage -Level Verbose -Message "Uploading $CaCertPath to /tmp/custom_CA.inc"

                    $command = "sudo [ -f /tmp/custom_CA.inc ] && sudo rm -rf /tmp/custom_CA.inc"
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -ne 1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                    $null = Set-SFTPItem -Destination "/tmp/" -Path $CaCertPath
                }

                if ($CaCertPath) {
                    Write-PSFMessage -Level Verbose -Message "Installing CA cert on securitycenter"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Installing CA cert on securitycenter"
                    $command = "sudo /opt/sc/support/bin/php /opt/sc/src/tools/installCA.php /tmp/custom_CA.inc"
                    try {
                        $results = Invoke-SSHCommand -Command $command
                        if ($results.ExitStatus -ne 1) {
                            Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                        }
                    } catch {
                        # seems like it works but then it gives an error so catch it
                    }
                }

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting securitycenter"
                Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                $command = "sudo service SecurityCenter start"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
            }

            if ("Nessus" -in $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "sudo service nessusd start"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -ne 1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
            }
            [pscustomobject]@{
                ComputerName = $ComputerName
                Success      = $true
            }
        } catch {
            $record = $_
            if ("Nessus" -in $Type -and $SshSession) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "sudo service nessusd start"
                try {
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -ne 1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                } catch {
                    # don't care
                }
            }

            if ("tenable.sc" -in $Type -and $SshSession) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the securitycenter service"
                Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                $command = "sudo service SecurityCenter start"
                try {
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -ne 1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                } catch {
                    # don't care
                }
            }

            Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername" -ErrorRecord $record -Continue
        } finally {
            if (-not $PSBoundParameters.SshSession -and $SshSession.SessionId) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Logging out from SSH"
                Write-PSFMessage -Level Verbose -Message "Logging out from SSH"
                $null = Remove-SSHSession -SessionId $SshSession.SessionId -ErrorAction Ignore
            }
            if (-not $PSBoundParameters.SftpSession -and $SftpSession.SessionId) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Logging out from FTP"
                Write-PSFMessage -Level Verbose -Message "Logging out from FTP"
                $null = Remove-SFTPSession -SessionId $SftpSession.SessionId -ErrorAction Stop
            }
        }
    }
}