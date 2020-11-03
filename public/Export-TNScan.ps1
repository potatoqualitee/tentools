function Export-TNScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        Parameter description

    .PARAMETER ScanId
        Parameter description

    .PARAMETER Format
        Parameter description

    .PARAMETER Path
        Parameter description

    .PARAMETER PSObject
        Parameter description

    .PARAMETER Chapters
        Parameter description

    .PARAMETER HistoryID
        Parameter description

    .PARAMETER Password
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Position = 2)]
        [ValidateSet('Nessus', 'HTML', 'PDF', 'CSV', 'DB')]
        [string]$Format = 'PDF',
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String]$Path,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch]$PSObject,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Vuln_Hosts_Summary', 'Vuln_By_Host',
            'Compliance_Exec', 'Remediations',
            'Vuln_By_Plugin', 'Compliance', 'All')]
        [string[]]$Chapters,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int32]$HistoryID,
        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring]$Password,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Name,
        [securestring]$Credential,
        [switch]$EnableException
    )
    begin {
        $ExportParams = @{ }

        if ($Format -eq 'DB' -and ($Password -or $Credential)) {
            if (-not $Credential) {
                $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
            }
            $ExportParams.Add('password', $Credential.GetNetworkCredential().Password)
        }

        if ($Format) {
            $ExportParams.Add('format', $Format.ToLower())
        }

        if ($Chapters) {
            if ($Chapters -contains 'All') {
                $ExportParams.Add('chapters', 'vuln_hosts_summary;vuln_by_host;compliance_exec;remediations;vuln_by_plugin;compliance')
            } else {
                $ExportParams.Add('chapters', $Chapters.ToLower())
            }
        }

        if (-not (Test-Path -Path $Path)) {
            $null = New-Item -Type Directory -Path $Path
        }
    }
    process {
        foreach ($session in (Get-TNSession)) {
            if ($HistoryId) {
                $urlpath = "/scans/$ScanId/export?history_id=$HistoryId"
            } else {
                $urlpath = "/scans/$ScanId/export"
            }

            Write-PSFMessage -Level Verbose -Message "Exporting scan with Id of $ScanId in $($Format) format"

            foreach ($fileid in (Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path $urlpath -Method 'Post' -Parameter $ExportParams)) {
                $FileStatus = ''
                while ($FileStatus.status -ne 'ready') {
                    try {
                        $FileStatus = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId/export/$($fileid.file)/status" -Method GET
                        Write-PSFMessage -Level Verbose -Message "Status of export is $($FileStatus.status)"
                    } catch {
                        break
                    }
                    Start-Sleep -Seconds 1
                }
                if ($FileStatus.status -eq 'ready' -and $Format -eq 'CSV' -and $PSObject.IsPresent) {
                    Write-PSFMessage -Level Verbose -Message "Converting report to PSObject"
                    Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId/export/$($fileid.file)/download" -Method GET | ConvertFrom-Csv
                } elseif ($FileStatus.status -eq 'ready') {
                    Write-PSFMessage -Level Verbose -Message "Downloading report to $($Path)"
                    $filepath = Resolve-PSFPath -Path "$path\$name-$scanid.$($Format.ToLower())" -NewChild
                    Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/scans/$ScanId/export/$($fileid.file)/download" -Method GET -OutFile $filepath
                }
                Get-ChildItem -Path $Path
            }
        }
    }
}