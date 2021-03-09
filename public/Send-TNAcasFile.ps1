function Send-TNAcasFile {
    <#
    .SYNOPSIS
        Uploads files to the server - useful for uploading RPMs to /opt/acas/var

    .DESCRIPTION
        Uploads files to the server - useful for uploading RPMs to /opt/acas/var

        This command only works when the destination server is running linux

    .PARAMETER ComputerName
        Target Nessus or Tenable.sc IP Address or FQDN

    .PARAMETER Credential
        The credential to login. This user must have access to restart services and replace keys.

        Basically, the user must have access.

    .PARAMETER SshSession
        If you use a private key to connect to your server, use New-SshSession to configure what you need and pass it to SShSession instead of using ComputerName and Credential

    .PARAMETER SftpSession
        If you use a private key to connect to your server, use New-SftpSession to configure what you need and pass it to SShSession instead of using ComputerName and Credential

    .PARAMETER SshPort
        Port number of the Nessus SSH service. Defaults to 22.

    .PARAMETER FilePath
        The path to the local file

    .PARAMETER Destination
        The path to upload to on the remote host. Defaults to /opt/acas/var/

    .PARAMETER AcceptAnyThumbprint
        Give up security and accept any SSH host key. To be used in exceptional situations only, when security is not required. To set, use Posh-SSH commands.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Send-TNAcasFile -ComputerName securitycenter.ad.local -Credential acasadmin -FilePath C:\temp\Nessus-8.9.0-es6.x86_64.rpm

        Uploads Nessus-8.9.0-es6.x86_64.rpm to /opt/acas/var to securitycenter.ad.local and a credential which has sudo access

    .EXAMPLE
        PS> Get-ChildItem C:\temp\*.rpm | Send-TNAcasFile -ComputerName securitycenter.ad.local -Credential $cred

        Uploads all RPMs in C:\temp to /opt/acas/var to securitycenter.ad.local and a credential which has sudo access
    #>
    [CmdletBinding()]
    param
    (
        [object]$SshSession,
        [object]$SftpSession,
        [string]$ComputerName,
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [Alias("FullName")]
        [string[]]$FilePath,
        [int]$SshPort = 22,
        [string]$Destination = "/opt/acas/var",
        [switch]$AcceptAnyThumbprint,
        [switch]$EnableException
    )
    process {
        if ((-not $PSBoundParameters.SshSession -and -not $PSBoundParameters.SftpSession) -and -not ($PSBoundParameters.ComputerName -and $PSBoundParameters.Credential)) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify either SshSession and SftpSession or ComputerName and Credential"
            return
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
            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $ComputerName"

            if (-not $PSBoundParameters.SshSession) {
                $SshSession = New-SSHSession -Port $SshPort
            }

            $PSDefaultParameterValues['*-SCP*:SessionId'] = $SshSession.SessionId
            $PSDefaultParameterValues['*-SSH*:SessionId'] = $SshSession.SessionId

            If ($PSBoundParameters.Credential -and $Credential.UserName -ne "root") {
                $sudo = "sudo"
                $stream = $SshSession.Session.CreateShellStream("PS-SSH", 0, 0, 0, 0, 1000)
                Write-PSFMessage -Level Verbose -Message "Logging in using $sudo"
                $results = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for $($Credential.UserName):" -SecureAction $Credential.Password
                $null = $stream.Read()
                Write-PSFMessage -Level Verbose -Message "Sudo: $results"
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $ComputerName"

            if (-not $PSBoundParameters.SftpSession) {
                $SftpSession = New-SFTPSession -ComputerName $ComputerName -Credential $Credential -Port $SshPort
            }

            $PSDefaultParameterValues['*-SFTP*:SFTPSession'] = $SftpSession

            foreach ($file in $FilePath) {
                $basename = Split-Path -Path $file -Leaf
                $filename = "/tmp/$basename"

                try {
                    Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Uploading files to Nessus"
                    Write-PSFMessage -Level Verbose -Message "Uploading files to Nessus"
                    $null = Set-SFTPItem -Destination /tmp -Path $file -ErrorAction Stop
                    $failure = $false
                } catch {
                    $failure = $true
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername. Couldn't upload $file" -ErrorRecord $PSItem -Continue
                }

                $results = Invoke-SecureShellCommand -Stream $stream -StepCounter ($stepcounter++) -Message "Moving from /tmp to $Destination" -Command "$sudo mv $filename $Destination"

                if ($results -match "mv") {
                    Write-PSFMessage -Level Verbose -Message $results
                } else {
                    $results = "Success"
                }

                if ($stream -and $results -eq "Success" -and -not $failure) {
                    do {
                        Start-Sleep 1
                        $running = Invoke-SecureShellCommand -Stream $stream -StepCounter ($stepcounter++) -Message "Waiting for move to complete" -Command "ps aux | grep mv | grep $filename | grep -v grep"
                    } until ($null -eq $running)
                }

                $Destination = $Destination.TrimEnd("/")
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    FileName     = "$Destination/$basename"
                    Result       = $results
                }
            }
        } catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure for $computername" -ErrorRecord $PSItem
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