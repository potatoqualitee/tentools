function Save-TNPlugin {
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
        $thumbprint = [System.Security.Cryptography.X509Certificates.X509Certificate2[]](Get-ChildItem Cert:\CurrentUser\My | Where-Object FriendlyName -like "*ID Certificate*") | Select-Object -ExpandProperty Thumbprint
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        [string]$FolderName = Get-Date -f MMddyyyy
        $OutPath = $path + $FolderName

        Write-PSFMessage -Level Verbose -Message "Prompting for CAC PIN"
        $acasfiles = Get-TNFiles

        if (Test-Path -Path $outpath) {
            Write-PSFMessage -Level Verbose -Message "Output folder exists"
        } else {
            $null = New-Item -Path $Path -Name $Foldername -ItemType directory
        }

        $filestodownload = $acasfiles | Where-Object { $PSItem.FileName -notlike "*diff*" -and $PSItem.FileName -notlike "*md5*" } | Sort-Object length
        if ($filestodownload.count -ge 1) {
            Write-PSFMessage -Level Verbose -Message "Found $($filestodownload.count) files to download"
        }
        if ($filestodownload.count -ge 3) {
            Write-PSFMessage -Level Verbose -Message "More than 2 files found. Limited to 2 at a time. When the next download is started you may be prompted for your PIN again"
        }

        #scriptblock for splitting into seperate jobs
        $ScriptBlock = {
            $ProgressPreference = 'SilentlyContinue'
            $thumbprint = [System.Security.Cryptography.X509Certificates.X509Certificate2[]](Get-ChildItem Cert:\CurrentUser\My | Where-Object FriendlyName -like "*ID Certificate*") | Select-Object -ExpandProperty Thumbprint
            $null = Invoke-WebRequest -CertificateThumbprint $thumbprint -Uri "https://patches.csd.disa.mil/PkiLogin/Default.aspx" -SessionVariable websession
            $remote = $PSItem.DownloadLink
            [string]$target = Join-Path -Path $Using:OutPath -ChildPath $PSItem.FileName
            Invoke-WebRequest -CertificateThumbprint $thumbprint -Uri $remote -OutFile $target -WebSession $websession
        }

        foreach ($File in $filestodownload) {
            $FileLength = [math]::round($File.Length / 1mb)
            Write-PSFMessage -Level Verbose -Message "Queueing download of $($file.FileName) which was last updated on $($file.PostedDate) and is $($FileLength)MB"
        }

        $filestodownload | Start-RSjob -ScriptBlock $ScriptBlock -Throttle 2 | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob | Remove-RSJob

        #make sure file hashes match what is reported on website
        Write-PSFMessage -Level Verbose -Message "Checking file hashes"

        $filestocheck = Get-ChildItem -LiteralPath $outpath
        foreach ($file in $filestocheck) {
            Write-PSFMessage -Level Verbose -Message "Checking hash on $($file.Name)"
            $filehash = Get-FileHash -Path $file.FullName
            foreach ($acasfile in $acasfiles) {
                if ($file.Name -eq $acasfile.FileName) {
                    if ($acasfile.SHA256 -eq $filehash.Hash) {
                        Write-PSFMessage -Level Verbose -Message "Hash on $($file.Name) was valid"
                    } else {
                        Write-PSFMessage -Level Verbose -Message "Hash on $($file.Name) was not valid"
                    }
                }
            }
            Get-ChildItem -Path $file.FullName
        }
    }
}