Function Write-Help {
    function Get-Header ($text) {
        $start = $text.IndexOf('<#')
        $text.SubString(0, $start - 2)
    }

    function Format-Help ($text) {
        $name = $file.basename
        $command = Get-Command $name
        $verb = $command.Verb
        $noun = $command.Noun.TrimStart("TN")
        $noun = ($noun -csplit "([A-Z][a-z]+)" | Where-Object { $_ }) -join " "
        $noun = $noun.ToLower()

        switch ($verb) {
            "Add" {
                $synopsis = "$($verb)s a $($noun)s"
            }
            "Connect" {
                $synopsis = "$($verb)s to a Nessus or tenable.sc server"
            }
            "ConvertFrom" {
                $synopsis = "Converts Nessus and tenable.sc responses to a readable format"
            }
            "Copy" {
                $synopsis = "Copies a list of $($noun)s"
            }
            "Initalize" {
                $synopsis = "Initalizes a new Nessus or tenable.sc server with username/password and license"
            }
            "New" {
                $synopsis = "Creates new $($noun)s"
            }
            "Wait" {
                $synopsis = "Waits for a Nessus server to be ready"
            }
            default {
                # Get, Disable, Edits, Enables, Exports
                $synopsis = "$($verb)s a list of $($noun)s"
            }
        }

        "    .SYNOPSIS"
        "        $synopsis"

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