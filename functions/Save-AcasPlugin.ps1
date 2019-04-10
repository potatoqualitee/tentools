function Save-AcasPlugin {
    <#
	.SYNOPSIS
    Saves ACAS plugin files from https://patches.csd.disa.mil/CollectionInfo.aspx?id=552

	.DESCRIPTION
    The SecurityCenter feed contains updates to templates used in SecurityCenter. Active plugins are used by the Nessus scanners and passive plugins are used by the Passive Vulnerability Scanner.
    These files are downloaded from https://patches.csd.disa.mil/CollectionInfo.aspx?id=552. This site is configured to accept only the Department of Defense (DoD) Common Access Card (CAC) or an External Certification Authority (ECA) PKI token. You will need to register on the site if you haven't yet.
    PoshRSJob is required for this function. Run "Install-Module -Name PoshRSJob -Scope CurrentUser" to install it.

	.PARAMETER Path
    Specify a path to save the files

    .NOTES
    Going to add force parameter and a file existance check

    #>
    [CmdletBinding()]
    param (
        [String]$Path = $PWD,
        [switch]$EnableException
    )

    begin {
        $CertificateThumbprint = [System.Security.Cryptography.X509Certificates.X509Certificate2[]](Get-ChildItem Cert:\CurrentUser\My | Where-Object FriendlyName -like "*ID Certificate*") | Select-Object -ExpandProperty Thumbprint
        try {
            Import-Module PoshRSJob -ErrorAction Stop
        }
        catch {
            $message = "Failed to load module, PoshRSJob is required for this function.
                        Install the module by running: 'Install-Module -Name PoshRSJob -Scope CurrentUser'"
            Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
        }

        #Enabling TLS 1.2
        if ([Net.ServicePointManager]::SecurityProtocol -notlike '*TLS12*') {
            Write-Output "Setting Security Protocol to TLS 1.2"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }
    }

    process {
        [string]$FolderName = Get-Date -f MMddyyyy
        $OutPath = $path + $FolderName

        Write-Output "Prompting for CAC PIN"
        $ACASFiles = Get-ACASFiles

        if (Test-Path -Path $outpath) {
            Write-Output "Output folder exists"
        }
        else {
            $null = New-Item -Path $Path -Name $Foldername -ItemType directory
        }

        $FilesToDownload = $ACASFiles | Where-Object { $_.FileName -notlike "*diff*" -and $_.FileName -notlike "*md5*" } | Sort-Object length
        if ($FilesToDownload.count -ge 1) {
            Write-Output "Found $($FilesToDownload.count) files to download."
        }
        if ($FilesToDownload.count -ge 3) {
            Write-Warning "More than 2 files found. Limited to 2 at a time. When the next download is started you may be prompted for your PIN again."
        }

        #scriptblock for splitting into seperate jobs
        $ScriptBlock = {
            $ProgressPreference = 'SilentlyContinue'
            $CertificateThumbprint = [System.Security.Cryptography.X509Certificates.X509Certificate2[]](Get-ChildItem Cert:\CurrentUser\My | Where-Object FriendlyName -like "*ID Certificate*") | Select-Object -ExpandProperty Thumbprint
            $null = Invoke-WebRequest -CertificateThumbprint $CertificateThumbprint -Uri "https://patches.csd.disa.mil/PkiLogin/Default.aspx"-SessionVariable DISALogin
            $remote = $_.DownloadLink
            [string]$target = $Using:OutPath + "\" + $($_.FileName)
            Invoke-WebRequest -CertificateThumbprint $CertificateThumbprint -Uri $remote -OutFile $target -WebSession $DISALogin
        }

        foreach ($File in $FilesToDownload) {
            $FileLength = [math]::round($File.Length / 1mb)
            Write-Output "Queueing download of $($file.FileName) which was last updated on $($file.PostedDate) and is $($FileLength)MB"
        }

        $FilesToDownload | Start-RSjob -ScriptBlock $ScriptBlock -Throttle 2 | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob | Remove-RSJob

        #make sure file hashes match what is reported on website
        Write-Output "Checking file hashes"

        $FilesToCheck = Get-ChildItem -literalpath $outpath
        foreach ($Check in $FilesToCheck) {
            Write-Output "Checking hash on $($Check.Name)"
            $GetFileHash = Get-FileHash -Path $Check.FullName
            foreach ($ACASFile in $ACASFiles) {
                if ($Check.Name -eq $ACASFile.FileName) {
                    if ($Acasfile.SHA256 -eq $GetFileHash.Hash) {
                        Write-Output "Hash on $($Check.Name) was valid"
                    }
                    else {
                        Write-Warning "Hash on $($Check.Name) was not valid"
                    }
                }
            }
        }
    }
}