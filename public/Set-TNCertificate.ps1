function Set-TNCertificate {
    <#
    .SYNOPSIS
        Sets certificates for both Nessus and Tenable.sc. Note,this stops and restarts services.

    .DESCRIPTION
        Sets certificates for both Nessus and Tenable.sc. Note,this stops and restarts services.

        This command only works when the destination server is running linux

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
        [string]$ComputerName,
        [parameter(Mandatory)]
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
        [string]$SshHostKeyFingerprint,
        [switch]$AcceptAnyThumbprint,
        [securestring]$SecurePrivateKeyPassphrase,
        [string]$SshPrivateKeyPath,
        [switch]$EnableException
    )
    begin {
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
    }
    process {
        if ($Method -ne "SSH") {
            Stop-PSFFunction -EnableException:$EnableException -Message "Only SSH and Linux are supported at this time"
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

        try {
            Write-PSFMessage -Level Verbose -Message "Connecting to $ComputerName"

            $connection = New-SSHSession -Port $SshPort
            $stream = $connection.Session.CreateShellStream("PS-SSH", 0, 0, 0, 0, 1000)

            $null = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for $($Credential.UserName):" -SecureAction $Credential.Password


            if ($SshHostKeyFingerprint) {
                $connection.SshHostKeyFingerprint = $SshHostKeyFingerprint
            }

            if ($SecurePrivateKeyPassphrase) {
                $connection.SecurePrivateKeyPassphrase = $SecurePrivateKeyPassphrase
            }
            if ($SshPrivateKeyPath) {
                $connection.SshPrivateKeyPath = $SshPrivateKeyPath
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $ComputerName"

            if ("Nessus" -in $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping the nessus service"
                Write-PSFMessage -Level Verbose -Message "Stopping nessusd"
                $command = "service nessusd stop"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding files to Nessus"

                Write-PSFMessage -Level Verbose -Message "Backing up files if they exist"
                $command = "[ -f /opt/nessus/com/nessus/CA/servercert.pem ] && mv /opt/nessus/com/nessus/CA/servercert.pem /opt/nessus/com/nessus/CA/servercert.bak"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                $command = "[ -f /opt/nessus/var/nessus/CA/serverkey.pem ] && mv /opt/nessus/var/nessus/CA/serverkey.pem /opt/nessus/com/nessus/CA/serverkey.bak"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId

                Write-PSFMessage -Level Verbose -Message "Uploading $CertPath to /opt/nessus/com/nessus/CA/servercert.pem"
                $null = Set-SCPItem -Destination /tmp -Path $CertPath
                $command = "mv /tmp/servercert.pem /opt/nessus/com/nessus/CA/"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId

                Write-PSFMessage -Level Verbose -Message "Uploading $KeyPath to /opt/nessus/var/nessus/CA/serverkey.pem"
                $null = Set-SCPItem -Destination /tmp -Path $KeyPath
                $command = "mv /tmp/serverkey.pem /opt/nessus/var/nessus/CA/"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId

                $command = "chown tns:tns /opt/nessus/com/nessus/CA/servercert.pem"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId

                $command = "chown tns:tns /opt/nessus/var/nessus/CA/serverkey.pem"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId

                if ($CaCertPath) {
                    Write-PSFMessage -Level Verbose -Message "Uploading $CaCertPath to /opt/nessus/lib/nessus/plugins/custom_CA.inc"
                    $null = Set-SCPItem -Destination /tmp -Path $CaCertPath
                    $command = "mv /tmp/custom_CA.inc /opt/nessus/lib/nessus/plugins/"
                    $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                    $command = "chown tns:tns /opt/nessus/lib/nessus/plugins/custom_CA.inc"
                    $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                }
            }
            if ("tenable.sc" -in $Type) {
                Write-PSFMessage -Level Verbose -Message "Stopping securitycenter"
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Stopping securitycenter"
                $command = "service SecurityCenter stop"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Adding files to tenable.sc"
                Write-PSFMessage -Level Verbose -Message "Uploading $CertPath to /opt/sc/support/conf/SecurityCenter.crt"
                $null = Set-SCPItem -Destination /tmp -Path $ScCertPath
                $command = "mv /tmp/SecurityCenter.crt /opt/sc/support/conf/"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId


                Write-PSFMessage -Level Verbose -Message "Uploading $KeyPath to /opt/sc/support/conf/SecurityCenter.key"
                $null = Set-SCPItem -Destination /tmp -Path $ScKeyPath
                $command = "mv /tmp/SecurityCenter.key /opt/sc/support/conf/"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId


                if ($CaCertPath) {
                    Write-PSFMessage -Level Verbose -Message "Uploading $CaCertPath to /tmp/custom_CA.inc"

                    $command = "[ -f /tmp/custom_CA.inc ] && rm -rf /tmp/custom_CA.inc"
                    $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                    $null = Set-SCPItem -Destination "/tmp/" -Path $CaCertPath
                }

                if ($CaCertPath) {
                    Write-PSFMessage -Level Verbose -Message "Installing CA cert on securitycenter"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Installing CA cert on securitycenter"
                    $command = "/opt/sc/support/bin/php /opt/sc/src/tools/installCA.php /tmp/custom_CA.inc"
                    try {
                        $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                    } catch {
                        # seems like it works but then it gives an error so catch it
                    }
                }

                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting securitycenter"
                Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                $command = "service SecurityCenter start"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
            }

            if ("Nessus" -in $Type) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "service nessusd start"
                $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
            }

            [pscustomobject]@{
                ComputerName = $ComputerName
                Success      = $true
            }
        } catch {
            $record = $_
            if ("Nessus" -in $Type -and $connection) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the nessus service"
                Write-PSFMessage -Level Verbose -Message "Starting nessusd"
                $command = "service nessusd start"
                try {
                    $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                } catch {
                    # don't care
                }
            }

            if ("tenable.sc" -in $Type -and $connection) {
                Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Starting the securitycenter service"
                Write-PSFMessage -Level Verbose -Message "Starting securitycenter"
                $command = "service SecurityCenter start"
                try {
                    $null = Invoke-SSHCommand -Command $command -SessionId $connection.SessionId
                } catch {
                    # don't care
                }
                $null = $connection | Remove-SSHSession -ErrorAction SilentlyContinue
            }

            Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername" -ErrorRecord $record -Continue
        }

    }
}