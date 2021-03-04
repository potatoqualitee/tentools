function Backup-TNServer {
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
        PS> Backup-TNServer -ComputerName securitycenter.ad.local -Credential acasadmin -CertPath C:\sc\cert.pem -KeyPath C:\sc\serverkey.key

        Logs into securitycenter.ad.local with the acasadmin credential and installs cert.pem and serverkey.key to both nessus and securitycenter.

    .EXAMPLE
        PS> # export cert to pfx without extended properties
        PS> openssl pkcs12 -in nessus.pfx -nokeys -out cert.pem
        PS> openssl pkcs12 -in nessus.pfx -nocerts -out serverkey.pem -nodes
        PS> openssl rsa -in serverkey.pem -out serverkey.key
        PS> Backup-TNServer -ComputerName securitycenter -Credential acasadmin -CertPath C:\sc\cert.pem -KeyPath C:\sc\serverkey.key -Verbose -AcceptAnyThumbprint
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
        [string]$Path,
        [ValidateSet("tenable.sc", "Nessus")]
        [string[]]$Type = @("tenable.sc", "Nessus"),
        [int]$SshPort = 22,
        [switch]$AcceptAnyThumbprint,
        [switch]$EnableException
    )
    process {
        if ((-not $PSBoundParameters.SshSession -and -not $PSBoundParameters.SftpSession) -and -not ($PSBoundParameters.ComputerName -and $PSBoundParameters.Credential)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify either SshSession and SftpSession or ComputerName and Credential"
            return
        }


        if ($PSBoundParameters.Credential -and $Credential.UserName -ne "root") {
            $sudo = "sudo"
            Write-PSFMessage -Level Warning -Message "root seems required :( I couldn't get sudo to work but you may have more luck"
        }

        # Set default parameter values
        $PSDefaultParameterValues['*-SCP*:Timeout'] = 1000000
        $PSDefaultParameterValues['*-SSH*:Timeout'] = 1000000
        $PSDefaultParameterValues['*-SSH*:ErrorAction'] = "Stop"
        $PSDefaultParameterValues['*-SCP*:ErrorAction'] = "Stop"
        $PSDefaultParameterValues['*-SCP*:Credential'] = $Credential
        $PSDefaultParameterValues['*-SSH*:Credential'] = $Credential
        $PSDefaultParameterValues['*-SSH*:ComputerName'] = $ComputerName
        $PSDefaultParameterValues['*-SCP*:ComputerName'] = $ComputerName
        $PSDefaultParameterValues['*-SCP*:AcceptKey'] = [bool]$AcceptAnyThumbprint
        $PSDefaultParameterValues['*-SSH*:AcceptKey'] = [bool]$AcceptAnyThumbprint

        try {
            Write-PSFMessage -Level Verbose -Message "Connecting to $ComputerName"

            if (-not $PSBoundParameters.SshSession) {
                $SshSession = New-SSHSession -Port $SshPort
            }

            $PSDefaultParameterValues['*-SCP*:SessionId'] = $SshSession.SessionId
            $PSDefaultParameterValues['*-SSH*:SessionId'] = $SshSession.SessionId

            If ($PSBoundParameters.Credential -and $Credential.UserName -ne "root") {
                $stream = $SshSession.Session.CreateShellStream("PS-SSH", 0, 0, 0, 0, 1000)
                Write-PSFMessage -Level Verbose -Message "Logging in using $sudo"
                $results = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "$sudo su -" -ExpectString "[$sudo] password for $($Credential.UserName):" -SecureAction $Credential.Password
                Write-PSFMessage -Level Verbose -Message "Sudo: $results"
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $ComputerName"

            if ("Nessus" -in $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping the nessus service"
                Write-PSFMessage -Level Verbose -Message "Stopping nessusd"
                $command = "$sudo service nessusd stop"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Backing up Nessus files"

                Write-PSFMessage -Level Verbose -Message "Zipping up Nessus files. This will take a few moments."
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Zipping up Nessus files"
                $command = "echo '$sudo tar -pzcf /tmp/nessus_backup.tar.gz /opt/nessus' > ~/nessusbackup.sh; chmod +x ~/nessusbackup.sh; ~/nessusbackup.sh"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                if (-not $PSBoundParameters.SftpSession) {
                    $SftpSession = New-SFTPSession -ComputerName $ComputerName -Credential $Credential -Port $SshPort
                }

                $PSDefaultParameterValues['*-SFTP*:SFTPSession'] = $SftpSession
                $PSDefaultParameterValues['*-SFTP*:Force'] = $true

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Downloading files from Nessus"
                Write-PSFMessage -Level Verbose -Message "Downloading files from Nessus"
                try {
                    $null = Get-SFTPItem -Destination $Path -Path /tmp/nessus_backup.tar.gz -ErrorAction Stop
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername. Couldn't download /tmp/nessus_backup.tar.gz" -ErrorRecord $record
                    return
                }

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Removing backup files from nessus"
                Write-PSFMessage -Level Verbose -Message "Removing backup files from nessus"

                $command = "$sudo rm -rf /tmp/nessus_backup.tar.gz"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Get-ChildItem (Join-Path -Path $Path -ChildPath nessus_backup.tar.gz)
            }

            if ("tenable.sc" -in $Type) {
                Write-PSFMessage -Level Verbose -Message "Stopping securitycenter"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping securitycenter"
                $command = "$sudo service SecurityCenter stop"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                if ("nessus" -notin $Type) {
                    # already stopped
                    Write-PSFMessage -Level Verbose -Message "Stopping nessusd"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping nessusd"
                    $command = "$sudo service nessusd stop"
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -notin 0,1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                }

                Write-PSFMessage -Level Verbose -Message "Stopping all tns processes"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping all tns processes"
                $command = "$sudo killall -u tns"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Write-PSFMessage -Level Verbose -Message "Stopping all httpd processes"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping all httpd processes"
                $command = "$sudo killall httpd"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Write-PSFMessage -Level Verbose -Message "Zipping up tenable.sc files. This may take a while."
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Zipping up tenable.sc files"
                $command = "$sudo tar -pzcf /tmp/sc_backup.tar.gz /opt/sc"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Downloading files from tenable.sc"
                Write-PSFMessage -Level Verbose -Message "Downloading files from tenable.sc"
                try {
                    $null = Get-SFTPItem -Destination $Path -Path /tmp/sc_backup.tar.gz -ErrorAction Stop
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername. Couldn't download /tmp/sc_backup.tar.gz" -ErrorRecord $record
                    return
                }

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Removing backup files from tenable.sc"
                Write-PSFMessage -Level Verbose -Message "Removing backup files from tenable.sc"

                $command = "$sudo rm -rf /tmp/sc_backup.tar.gz"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }

                Get-ChildItem (Join-Path -Path $Path -ChildPath sc_backup.tar.gz)
            }

            if ("Nessus" -in $Type -and "tenable.sc" -notin $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "$sudo service nessusd start"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
            }

            if ("tenable.sc" -in $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "$sudo service nessusd start"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the SecurityCenter service"
                Write-PSFMessage -Level Verbose -Message "Starting SecurityCenter"
                $command = "$sudo service SecurityCenter start"
                $results = Invoke-SSHCommand -Command $command
                if ($results.ExitStatus -notin 0,1) {
                    Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                }
            }
        } catch {
            $record = $_
            if ("Nessus" -in $Type -and $SshSession) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "$sudo service nessusd start"
                try {
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -notin 0,1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                } catch {
                    # don't care
                }
            }

            if ("tenable.sc" -in $Type -and $SshSession) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the securitycenter service"
                Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                $command = "$sudo service SecurityCenter start"
                try {
                    $results = Invoke-SSHCommand -Command $command
                    if ($results.ExitStatus -notin 0,1) {
                        Write-PSFMessage -Level Warning -Message "Command '$command' failed with exit status $($results.ExitStatus)"
                    }
                } catch {
                    # don't care
                }
            }

            Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername" -ErrorRecord $record
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