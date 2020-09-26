function Set-TenSslCertificate {
    <#
    .SYNOPSIS
        Creates a new admin the Nessus website then establishes a connection using those credentials

    .DESCRIPTION
    Creates a new admin the Nessus website

    .PARAMETER ComputerName
        Target Nessus Server IP Address or FQDN

    .PARAMETER Port
        Port number of the Nessus web service. Defaults to 8834.

    .PARAMETER Credential
        Credential for connecting to the Nessus Server

    .PARAMETER UseDefaultCredential
        Use current credential for connecting to the Nessus Server

    .PARAMETER AcceptSelfSignedCert
        Accept self signed cert

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Initialize-TenServer -ComputerName acas -Credential admin
    #>
    [CmdletBinding()]
    param
    (
        [string[]]$ComputerName,
        [int]$Port = 22,
        [Management.Automation.PSCredential]$Credential,
        [string]$SslCertPath,
        [string]$SslKeyPath,
        [string]$CaCertPath,
        [ValidateSet("tenable.sc", "Nessus")]
        [string[]]$Type = @("tenable.sc", "Nessus"),
        [ValidateSet("docker", "SSH", "WinRM")]
        [string]$Method = "SSH",
        [string] $SshHostKeyFingerprint,
        [switch]$AcceptAnyKey,
        [switch]$EnableException
    )

    process {

        if ($PSEdition -eq "Core") {
            Add-Type -Path "$ModuleRoot/bin/WinSCPnetCore.dll"
        } else {
            Add-Type -Path "$ModuleRoot/bin/WinSCPnet.dll"
        }
        write-warning done
        return
        foreach ($computer in $ComputerName) {
            if ($Method -eq "SSH") {
                try {
                    # Setup session options
                    $session = New-Object WinSCP.SessionOptions -Property @{
                        Protocol                                     = [WinSCP.Protocol]::Sftp
                        HostName                                     = $computer
                        UserName                                     = $Credential.UserName
                        Password                                     = $Credential.GetNetworkCredential().Password
                        GiveUpSecurityAndAcceptAnySshHostKey         = $AcceptAnyKey
                        GiveUpSecurityAndAcceptAnyTlsHostCertificate = $AcceptAnyKey
                        SshHostKeyFingerprint                        = $SshHostKeyFingerprint
                        Port                                         = $Port
                    }

                    $session = New-Object WinSCP.Session
                    $session.Open($session)

                    $txt = Get-Content -Path $SslCertPath -Raw
                    if ($txt -notmatch "-----BEGIN CERTIFICATE-----" -and $txt -notmatch "-----END CERTIFICATE-----") {
                        Stop-PSFFunction -Message "$SslCertPath does not appear to be a valid cert (must contain the text -----BEGIN CERTIFICATE----- and -----END CERTIFICATE-----)"
                        return

                    }

                    $txt = Get-Content -Path $SslKeyPath -Raw
                    if ($txt -notmatch "KEY") {
                        Stop-PSFFunction -Message "$SslKeyPath does not appear to be a valid key (must contain the text 'KEY')"
                        return
                    }

                    if ("Nessus" -in $Type) {
                        $results = $session.PutFiles($SslCertPath, "/opt/nessus/com/nessus/CA/servercert.pem")
                        $results = $session.PutFiles($SslKeyPath, "/opt/nessus/com/nessus/CA/serverkey.pem")
                        if ($CaCertPath) {
                            $results = $session.PutFiles($SslKeyPath, "/opt/nessus/com/nessus/CA/cacert.pem")
                            $results = $session.PutFiles($CaCertPath, "/opt/nessus/lib/nessus/plugins/custom_CA.inc")
                        }
                    }

                    if ("tenable.sc" -in $Type) {
                        $results = $session.PutFiles($SslCertPath, "/opt/sc/support/conf/SecurityCenter.crt")
                        $results = $session.PutFiles($SslKeyPath, "/opt/sc/support/conf/SecurityCenter.key")
                        if ($CaCertPath) {
                            $results = $session.PutFiles($CaCertPath, "/tmp/custom_CA.inc")
                            #PLUGIN_SET = "205004261330"
                            #PLUGIN_FEED = "Custom"
                            $dumpCommand = ""
                            $session.ExecuteCommand($dumpCommand).Check()
                        }
                        if ($CaCertPlugin) {
                            $results = $session.PutFiles($CaCertPlugin, "/opt/sc/support/conf/SecurityCenter.key")
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
                }
            } finally {
                # Disconnect, clean up
                $session.Dispose()
            }
        } else {

        }
    }
}