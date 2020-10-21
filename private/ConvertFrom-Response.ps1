function ConvertFrom-Response {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]$InputObject
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
                [string]$Value
            )
            if ($Key -notmatch 'date' -and $Key -notmatch 'time') {
                return $Value
            } else {
                $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
                if ($Value -cnotlike "*T*") {
                    return $origin.AddSeconds($Value).ToLocalTime()
                } else {
                    return [datetime]::ParseExact($Value, "yyyyMMddTHHmmss",
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::None)
                }
            }
        }

        function Convert-Row {
            param (
                [object[]]$Object,
                [string]$Type
            )
            # get columns to convert to camel case
            if ($null -eq $Object) {
                return $null
            }
            $fields = $Object | Get-Member -Type NoteProperty | Sort-Object Name

            foreach ($row in $Object) {
                $uri = [uri]$session.Uri
                $hash = @{
                    ServerUri = "$($uri.Host):$($uri.Port)"
                }
                if ($Type) {
                    $hash["Type"] = $Type
                }
                foreach ($name in $fields.Name) {
                    # Proper case first letter, tenable takes care of the rest
                    $first = $name.Substring(0, 1).ToUpperInvariant()
                    $rest = $name.Substring(1, $name.length - 1)
                    $column = "$first$rest"

                    # some columns need special attention
                    switch ($column) {
                        "Shared" {
                            $hash["Shared"] = $(if ($row.shared -eq 1) { $true } else { $false })
                        }
                        "User_permissions" {
                            $hash["UserPermissions"] = $permidenum[$row.user_permissions]
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
                $null = $order.Add("ServerUri")
                if ('Id' -in $keys) {
                    $null = $order.Add("Id")
                }
                if ($Type) {
                    $null = $order.Add("Type")
                }
                if ('Name' -in $keys) {
                    $null = $order.Add("Name")
                }
                if ('Description' -in $keys) {
                    $null = $order.Add("Description")
                }
                foreach ($column in ($keys | Where-Object { $PSItem -notin "ServerUri", "Id", "Type", "Name", "Description" })) {
                    $null = $order.Add($column)
                }

                Write-Debug "Columns: $order"
                Write-Debug "Count: $($hash.Count)"
                [pscustomobject]$hash | Select-Object -Property $order
            }
        }
    }
    process {
        if ($null -eq $InputObject) {
            return
        }
        foreach ($object in $InputObject) {
            Write-Debug "Processing object"

            # determine if it has an inner field to extract
            $fields = $object | Get-Member -Type NoteProperty

            # IF EVERY ONE HAS MULTIPLES INSIDE
            if ($fields.Count -eq 1) {
                Write-Verbose "Found one inner object"
                $name = $fields.Name
                # figure out why this is failing
                Convert-Row -Object $object.$name -Type $null
            } else {
                Write-Verbose "Found multiple inner objects"
                $result = $true
                foreach ($definition in $fields.Definition) {
                    if (-not $definition.StartsWith("Object[]")) {
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