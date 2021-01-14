function Save-TNAuditFile {
    <#
	.SYNOPSIS
    Saves audit files from https://www.tenable.com/downloads/download-all-compliance-audit-files

	.DESCRIPTION
    Saves audit files from https://www.tenable.com/downloads/download-all-compliance-audit-files

	.PARAMETER Path
    Specify a path to save the files

    #>
    [CmdletBinding()]
    param (
        [String]$Path = $pwd
    )
    process {
        Write-ProgressHelper -StepNumber 1 -TotalSteps 1 -Activity "Downloading audit files from tenable.com" -Message "Downloading"

        $file = "$Path\audits.tar.gz"
        # Progress makes it so slow, disable
        $ProgressPreference = "SilentlyContinue"
        $null = Invoke-WebRequest -Uri "https://www.tenable.com/downloads/api/v1/public/pages/download-all-compliance-audit-files/downloads/7472/download?i_agree_to_tenable_license_agreement=true" -OutFile "$Path\audits.tar.gz"

        Write-Progress -Completed -Activity "Downloading audit files from tenable.com"

        $null = tar -xvzf $file -C $Path *>$null
        Remove-Item $file
        Get-ChildItem "$Path\portal_audits"
    }
}