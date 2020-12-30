function ConvertFrom-TNRestResponse {
    <#
    .SYNOPSIS
        Converts Nessus and tenable.sc responses to a readable, PowerShell-styled format

    .DESCRIPTION
        Converts Nessus and tenable.sc responses to a readable, PowerShell-styled format

    .PARAMETER InputObject
        The rest response to parse from pipeline

    .EXAMPLE
        PS C:\> $session = Connect-TNServer -ComputerName nessus -Credential admin
        PS C:\> $params = @{
                    SessionObject   = $session
                    Path            = "/folders"
                    Method          = "GET"
                    EnableException = $EnableException
                }
        PS C:\> Invoke-TNRequest @params | ConvertFrom-TNRestResponse

        Connects to https://nessus:8834 using the admin credential, gets the results in JSON format then converts to PowerShell styled output

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]$InputObject,
        [switch]$ExcludeEmptyResult
    )
    begin {
        function Convert-Name ($string) {
            if ($string -match "_") {
                $whole = @()
                $split = $string -split "_"
                foreach ($name in $split) {
                    $first = $name.Substring(0, 1).ToUpperInvariant()
                    $rest = $name.Substring(1, $name.length - 1)
                    $whole += "$first$rest"
                }
                $string = -join $whole
            }
            return $string
        }

        function Convert-Value {
            param (
                [string]$Key,
                $Value
            )
            if ($Key -notmatch 'date' -and $Key -notmatch 'time') {
                if ("$Value".StartsWith("{@{")) {
                    return $Value | ConvertFrom-TNRestResponse
                } else {
                    return $Value
                }
            } elseif ([double]::TryParse($value,[ref]$null)) {
                if ($Value -cnotlike "*T*") {
                    return $script:origin.AddSeconds($Value).ToLocalTime()
                } else {
                    return [datetime]::ParseExact($Value, "yyyyMMddTHHmmss",
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::None)
                }
            } else {
                return $Value
            }
        }

        function Convert-Row {
            param (
                [object[]]$Object,
                [string]$Type
            )
            # get columns to convert to camel case
            if ($null -eq $Object) {
                return
            }
            try {
                $fields = $Object | Get-Member -Type NoteProperty -ErrorAction Stop | Sort-Object Name
            } catch {
                return
            }

            foreach ($row in $Object) {
                if (-not $session) {
                    $tempsession = Get-TNSession
                    if ($tempsession.SessionId.Count -eq 1) {
                        $session = $tempsession
                    }
                }

                if ($session) {
                    $uri = [uri]$session.Uri
                    $hash = @{
                        ServerUri = "$($uri.Host):$($uri.Port)"
                    }
                } else {
                    $hash = @{}
                }

                if ($Type) {
                    $hash["Type"] = $Type
                }

                if ($script:includeid) {
                    $hash["Id"] = $script:includeid
                }

                foreach ($name in $fields.Name) {
                    # Proper case first letter, tenable takes care of the rest
                    $first = $name.Substring(0, 1).ToUpperInvariant()
                    $rest = $name.Substring(1, $name.length - 1)
                    $column = "$first$rest"

                    # some columns need special attention
                    switch ($column) {
                        "Shared" {
                            $hash["Shared"] = $(if ($row.shared -eq 1) { $true } elseif ($row.shared -eq 0) { $false } else { $row.shared })
                        }
                        "Status" {
                            $hash["Status"] = $(if ($row.status -eq 1) { $true } elseif ($row.status -eq 0) { $false } else { $row.status })
                        }
                        "User_permissions" {
                            $hash["UserPermissions"] = $permidenum[$row.user_permissions]
                        }
                        { $PSItem -match "Modifi" } {
                            $value = Convert-Value -Key $column -Value $row.$column
                            $hash["Modified"] = $value
                        }
                        { $PSItem -match "Creat" } {
                            $value = Convert-Value -Key $column -Value $row.$column
                            $hash["Created"] = $value
                        }
                        { $PSItem -match "Last.Login" -or $PSItem -eq "LastLogin" } {
                            $value = $script:origin.AddSeconds($row.$column).ToLocalTime()
                            $hash["LastLogin"] = $value
                        }
                        default {
                            # remove _, cap all words
                            $key = Convert-Name $column
                            $value = Convert-Value -Key $column -Value $row.$column
                            $hash[$key] = $value
                        }
                    }
                }

                # Set column order
                $order = New-Object System.Collections.ArrayList
                $keys = $hash.Keys
                if ($session) {
                    $null = $order.Add("ServerUri")
                }
                if ('Id' -in $keys) {
                    $null = $order.Add("Id")
                }
                if ($Type) {
                    $null = $order.Add("Type")
                }
                if ('Username' -in $keys) {
                    $null = $order.Add("Username")
                }
                if ('Title' -in $keys) {
                    $null = $order.Add("Title")
                }
                if ('Name' -in $keys) {
                    $null = $order.Add("Name")
                }
                if ('Description' -in $keys) {
                    $null = $order.Add("Description")
                }
                foreach ($column in ($keys | Sort-Object | Where-Object { $PSItem -notin "ServerUri", "Id", "Type", "Name", "Description", "Title", "Username" })) {
                    $null = $order.Add($column)
                }

                Write-Debug "Columns: $order"
                Write-Debug "Count: $($hash.Count)"
                [pscustomobject]$hash | Select-Object -Property $order
            }
        }
    }
    process {
        if ($null -eq $InputObject -or ($ExcludeEmptyResult -and $InputObject.type -eq "regular")) {
            return
        }
        foreach ($object in $InputObject) {
            Write-Debug "Processing object"

            # determine if it has an inner field to extract
            $fields = $object | Get-Member -Type NoteProperty

            # IF EVERY ONE HAS MULTIPLES INSIDE
            if ($fields.Count -eq 0) {
                Write-Verbose "Found no inner objects"
                if ($object.StartsWith("{")) {
                    $object = $object.Replace("\","\\") | ConvertFrom-Json
                    $fields = $object | Get-Member -Type NoteProperty
                } elseif ($object.StartsWith("@{")) {
                    $object = $object.Substring(2, $object.Length - 3) -split ';' | ConvertFrom-StringData | ConvertTo-PSCustomObject
                    $fields = $object | Get-Member -Type NoteProperty
                } else {
                    try {
                        $object = $object | ConvertFrom-Json -ErrorAction Stop
                        $fields = $object | Get-Member -Type NoteProperty -ErrorAction Stop
                    } catch {
                        # nothing
                    }
                }
            }

            if ($fields.Count -eq 1) {
                Write-Verbose "Found one inner object"
                $name = $fields.Name
                Convert-Row -Object $object.$name -Type $null
            } else {
                Write-Verbose "Found multiple inner objects"
                $result = $true
                foreach ($definition in $fields.Definition) {
                    if (-not $definition.Contains("Object[]")) {
                        $result = $false
                    }
                }
                if ($result) {
                    foreach ($field in $fields) {
                        $name = (Get-Culture).TextInfo.ToTitleCase($field.Name)
                        Convert-Row -Object $object.$name -Type $name
                    }
                } else {
                    Convert-Row -Object $object
                }
            }
        }
    }
}