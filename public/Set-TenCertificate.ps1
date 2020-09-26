function Set-TenCertificate {
    <#
    .SYNOPSIS
        Creates a new admin the Nessus website then establishes a connection using those credentials

    .DESCRIPTION
    Creates a new admin the Nessus website

    .PARAMETER ComputerName
        Target Nessus Server IP Address or FQDN

    .PARAMETER Port
        Port number of the Nessus SSH service. Defaults to 22.

    .PARAMETER Credential

    .PARAMETER CertPath

    .PARAMETER KeyPath

    .PARAMETER CaCertPath

    .PARAMETER Type

    .PARAMETER Method

    .PARAMETER SshHostKeyFingerprint

    .PARAMETER AcceptAnyThumbprint
        Give up security and accept any SSH host key. To be used in exceptional situations only, when security is not required. When set, log files will include warning about insecure connection. To maintain security, use SshHostKeyFingerprint.

    .PARAMETER SecurePrivateKeyPassphrase

    .PARAMETER SshPrivateKeyPath

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Set-TenCertificate -ComputerName acas -Credential admin
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory)]
        [string]$CertPath,
        [Parameter(Mandatory)]
        [string]$KeyPath,
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
        [string]$EnableException
    )
    process {
        $txt = Get-Content -Path $CertPath -Raw
        if ($txt -notmatch "-----BEGIN CERTIFICATE---- - " -and $txt -notmatch "-----END CERTIFICATE---- - ") {
            Stop-PSFFunction -Message "$CertPath does not appear to be a valid cert (must contain the text -----BEGIN CERTIFICATE---- - and -----END CERTIFICATE---- - )"
            return

        }

        $txt = Get-Content -Path $KeyPath -Raw
        if ($txt -notmatch "KEY") {
            Stop-PSFFunction -Message "$KeyPath does not appear to be a valid key (must contain the text 'KEY')"
            return
        }

        foreach ($computer in $ComputerName) {
            if ($Method -eq "SSH") {
                try {
                    if ($PSEdition -eq "Core") {
                        Add-Type -Path "$ModuleRoot/bin/WinSCPnetCore.dll"
                    } else {
                        Add-Type -Path "$ModuleRoot/bin/WinSCPnet.dll"
                    }
                    # Setup session options
                    $session = New-Object WinSCP.SessionOptions -Property @{
                        Protocol                             = [WinSCP.Protocol]::Scp
                        HostName                             = $computer
                        UserName                             = $Credential.UserName
                        SecurePassword                       = $Credential.Password
                        GiveUpSecurityAndAcceptAnySshHostKey = $AcceptAnyThumbprint
                        SshHostKeyFingerprint                = $SshHostKeyFingerprint
                        PortNumber                           = $Port
                        SecurePrivateKeyPassphrase           = $SecurePrivateKeyPassphrase
                        SshPrivateKeyPath                    = $SshPrivateKeyPath
                    }

                    $session = New-Object WinSCP.Session
                    $session.Open($session)

                    $transferOptions = New-Object WinSCP.TransferOptions
                    $transferOptions.TransferMode = [WinSCP.TransferMode]::Ascii

                    if ("Nessus" -in $Type) {
                        $results = $session.PutFiles($CertPath, "/opt/nessus/com/nessus/CA/servercert.pem", $false, $transferOptions)
                        $results = $session.PutFiles($KeyPath, "/opt/nessus/com/nessus/CA/serverkey.pem", $false, $transferOptions)
                        if ($CaCertPath) {
                            $results = $session.PutFiles($CaCertPath, "/opt/nessus/lib/nessus/plugins/custom_CA.inc", $false, $transferOptions)
                        }
                    }

                    if ("tenable.sc" -in $Type) {
                        $results = $session.PutFiles($CertPath, "/opt/sc/support/conf/SecurityCenter.crt", $false, $transferOptions)
                        $results = $session.PutFiles($KeyPath, "/opt/sc/support/conf/SecurityCenter.key", $false, $transferOptions)
                        if ($CaCertPath) {
                            $results = $session.PutFiles($CaCertPath, "/tmp/custom_CA.inc", $false, $transferOptions)
                            $pluginset = 'PLUGIN_SET = "201704261330";'
                            $pluginfeed = 'PLUGIN_FEED = "Custom"'
                            $command = "cat $pluginset > /tmp/custom_feed_info.inc"
                            $session.ExecuteCommand($command).Check()
                            $command = "cat $pluginfeed >> /tmp/custom_feed_info.inc"
                            $session.ExecuteCommand($command).Check()
                            $command = "tar -zcvf /tmp/upload_this.tar.gz /tmp/custom_feed_info.inc /tmp/custom_CA.inc"
                            $temppath = [IO.Path]::GetTempPath()
                            $transferOptions = New-Object WinSCP.TransferOptions
                            $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
                            $results = $session.GetFiles("/tmp/upload_this.tar.gz", "$temppath/upload_this.tar.gz")
                        }
                    }

                    # Throw on any error
                    $results.Check()

                    # Print results
                    foreach ($result in $results.Transfers) {
                        Write-PSFMessage -Level Verbose -Message "Download of $($result.FileName) succeeded"
                    }
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername" -ErrorRecord $_ -Continue
                } finally {
                    # Disconnect, clean up
                    $session.Dispose()
                }
            }
        }
    }
}