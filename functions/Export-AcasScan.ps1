function Export-AcasScan {
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

    .PARAMETER OutFile
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
        PS> Get-Acas
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$ScanId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [ValidateSet('Nessus', 'HTML', 'PDF', 'CSV', 'DB')]
        [string]$Format,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String]$OutFile,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch]$PSObject,
        [Parameter(Position = 3, ValueFromPipelineByPropertyName)]
        [ValidateSet('Vuln_Hosts_Summary', 'Vuln_By_Host',
            'Compliance_Exec', 'Remediations',
            'Vuln_By_Plugin', 'Compliance', 'All')]
        [string[]]$Chapters,
        [Parameter(Position = 4, ValueFromPipelineByPropertyName)]
        [Int32]$HistoryID,
        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring]$Password,
        [switch]$EnableException
    )
    process {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $connection
                }
            }
        }

        $ExportParams = @{ }

        if ($Format -eq 'DB' -and $Password) {
            $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
            $ExportParams.Add('password', $Credential.GetNetworkCredential().Password)
        }

        if ($Format) {
            $ExportParams.Add('format', $Format.ToLower())
        }

        if ($Chapters) {
            if ($Chapters -contains 'All') {
                $ExportParams.Add('chapters', 'vuln_hosts_summary;vuln_by_host;compliance_exec;remediations;vuln_by_plugin;compliance')
            }
            else {
                $ExportParams.Add('chapters', $Chapters.ToLower())
            }
        }

        foreach ($connection in $collection) {
            if ($HistoryId) {
                $path = "/scans/$($ScanId)/export?history_id=$($HistoryId)"
            }
            else {
                $path = "/scans/$($ScanId)/export"
            }

            Write-PSFMessage -Level Verbose -Mesage "Exporting scan with Id of $($ScanId) in $($Format) format."
            $FileID = Invoke-AcasRequest -SessionObject $connection -Path $path  -Method 'Post' -Parameter $ExportParams
            if ($FileID -is [psobject]) {
                $FileStatus = ''
                while ($FileStatus.status -ne 'ready') {
                    try {
                        $FileStatus = Invoke-AcasRequest -SessionObject $connection -Path "/scans/$($ScanId)/export/$($FileID.file)/status"  -Method 'Get'
                        Write-PSFMessage -Level Verbose -Mesage "Status of export is $($FileStatus.status)"
                    }
                    catch {
                        break
                    }
                    Start-Sleep -Seconds 1
                }
                if ($FileStatus.status -eq 'ready' -and $Format -eq 'CSV' -and $PSObject.IsPresent) {
                    Write-PSFMessage -Level Verbose -Mesage "Converting report to PSObject"
                    Invoke-AcasRequest -SessionObject $connection -Path "/scans/$($ScanId)/export/$($FileID.file)/download" -Method 'Get' | ConvertFrom-Csv
                }
                elseif ($FileStatus.status -eq 'ready') {
                    Write-PSFMessage -Level Verbose -Mesage "Downloading report to $($OutFile)"
                    Invoke-AcasRequest -SessionObject $connection -Path "/scans/$($ScanId)/export/$($FileID.file)/download" -Method 'Get' -OutFile $OutFile
                }
            }
        }
    }
}