function Save-TNScapFile {
    <#
	.SYNOPSIS
    Saves SCAP files from https://public.cyber.mil/stigs/scap/

	.DESCRIPTION
    Saves SCAP files from https://public.cyber.mil/stigs/scap/

	.PARAMETER Path
    Specify a path to save the files

    #>
    [CmdletBinding()]
    param (
        [String]$Path = $pwd
    )
    process {
        $scap = Invoke-WebRequest -Uri https://public.cyber.mil/stigs/scap/
        $links = ($scap.Links | Where-Object Href -match Benchmark.zip).Href

        # Progress makes it so slow, disable
        $ProgressPreference = "SilentlyContinue"
        foreach ($link in $links) {
            $filename = Split-Path $link -Leaf
            Invoke-WebRequest -Uri $link -OutFile "$Path\$filename"
            Get-ChildItem "$Path\$filename"
        }
    }
}