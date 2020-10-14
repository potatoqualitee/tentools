function ConvertFrom-Response {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]$InputObject
    )
    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        foreach ($object in $InputObject) {
            Write-Debug "Processing object"
            # determine if it has an inner field to extract
            $field = $object | Get-Member -Type NoteProperty
            if ($field.Count -eq 1) {
                Write-Debug "Found inner object"
                $name = $field.Name
                $object = $object.$name
            }

            # get columns to convert to camel case
            $fields = $object | Get-Member -Type NoteProperty | Sort-Object Name

            foreach ($row in $object) {
                $hash = @{}
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
                        "No_target" {
                            $hash["NoTarget"] = $row.no_target
                        }
                        "User_permissions" {
                            $hash["UserPermission"] = $row.user_permissions
                        }
                        "Owner_id" {
                            $hash["UserId"] = $row.owner_id
                        }
                        "Last_modification_date" {
                            $hash["Modified"] = $origin.AddSeconds($row.last_modification_date).ToLocalTime()
                        }
                        "modifiedTime" {
                            $hash["Modified"] = $origin.AddSeconds($row.modifiedTime).ToLocalTime()
                        }
                        "Creation_date" {
                            $hash["Created"] = $origin.AddSeconds($row.creation_date).ToLocalTime()
                        }
                        "CreatedTime" {
                            $hash["Created"] = $origin.AddSeconds($row.createdTime).ToLocalTime()
                        }
                        default {
                            $hash[$column] = $row.$column
                        }
                    }
                }

                # Set column order
                $order = New-Object System.Collections.ArrayList
                $keys = $hash.Keys

                if ('Id' -in $keys) {
                    $null = $order.Add("Id")
                }
                if ('Name' -in $keys) {
                    $null = $order.Add("Name")
                }
                if ('Description' -in $keys) {
                    $null = $order.Add("Description")
                }
                foreach ($column in ($keys | Where-Object { $PSItem -notin "Id", "Name", "Description" })) {
                    $null = $order.Add($column)
                }

                Write-Debug "Columns: $order"
                Write-Debug "Count: $($hash.Count)"
                [pscustomobject]$hash | Select-Object -Property $order
            }
        }
    }
}