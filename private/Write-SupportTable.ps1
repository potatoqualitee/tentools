Function Write-SupportTable {
    "| Command | Nessus | tenable.sc
| --- | --- | --- |"

    $files = Get-ChildItem -Recurse C:\github\tentools\public\*.ps1

    foreach ($file in $files) {
        $name = $file.basename
        $text = (Get-ChildItem $file | Get-Content -Raw).Trim()

        if ($text -match "tenable.sc not supported") {
            "| $name | x | |"
        } elseif ($text -match "Only tenable.sc supported") {
            "| $name | | x |"
        } elseif ($text -match "Nessus not supported") {
            "| $name | | x |"
        } else {
            "| $name | x | x |"
        }
    }
}