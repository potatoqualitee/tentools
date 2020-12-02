Function Write-Help {
    function Get-Header ($text) {
        $start = $text.IndexOf('<#')
        $text.SubString(0, $start - 2)
    }

    function Format-Help ($text) {
        $name = $file.basename
        $command = Get-Command $name
        $verb = $command.Verb

        switch ($verb) {
            "Get"
        }
        "    .SYNOPSIS"
        "        The synopsis for $name"


    }

    function Get-Body ($text) {
        $end = $text.IndexOf('#>')
        $text.SubString($end, $text.Length - $end)
    }

    $files = Get-ChildItem -Recurse C:\github\tentools\public\*.ps1

    foreach ($file in $files) {
        write-warning "$file"
        $text = ($file | Get-Content -Raw).Trim()
        Set-Content -Path $file.FullName -Encoding UTF8 -Value (Get-Header $text).TrimEnd()
        Add-Content -Path $file.FullName -Encoding UTF8 -Value "<#".Trim()
        Add-Content -Path $file.FullName -Encoding UTF8 -Value (Format-Help $text)
        Add-Content -Path $file.FullName -Encoding UTF8 -Value (Get-Body $text).TrimEnd() -NoNewline
    }
}