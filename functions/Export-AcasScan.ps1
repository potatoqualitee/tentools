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

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32]
        $ScanId,

        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Nessus', 'HTML', 'PDF', 'CSV', 'DB')]
        [string]
        $Format,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [String]
        $OutFile,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [Switch]
        $PSObject,

        [Parameter(Mandatory = $false,
            Position = 3,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Vuln_Hosts_Summary', 'Vuln_By_Host',
            'Compliance_Exec', 'Remediations',
            'Vuln_By_Plugin', 'Compliance', 'All')]
        [string[]]
        $Chapters,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipelineByPropertyName = $true)]
        [Int32]
        $HistoryID,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [securestring]
        $Password

    )

    begin {
    }
    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        $ExportParams = @{}

        if ($Format -eq 'DB' -and $Password) {
            $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
            $ExportParams.Add('password', $Credentials.GetNetworkCredential().Password)
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

        foreach ($Connection in $ToProcess) {
            if ($HistoryId) {
                $path = "/scans/$($ScanId)/export?history_id=$($HistoryId)"
            } else {
                $path = "/scans/$($ScanId)/export"
            }

            Write-Verbose -Message "Exporting scan with Id of $($ScanId) in $($Format) format."
            $FileID = InvokeNessusRestRequest -SessionObject $Connection -Path $path  -Method 'Post' -Parameter $ExportParams
            if ($FileID -is [psobject]) {
                $FileStatus = ''
                while ($FileStatus.status -ne 'ready') {
                    try {
                        $FileStatus = InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/export/$($FileID.file)/status"  -Method 'Get'
                        Write-Verbose -Message "Status of export is $($FileStatus.status)"
                    } catch {
                        break
                    }
                    Start-Sleep -Seconds 1
                }
                if ($FileStatus.status -eq 'ready' -and $Format -eq 'CSV' -and $PSObject.IsPresent) {
                    Write-Verbose -Message "Converting report to PSObject"
                    InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/export/$($FileID.file)/download" -Method 'Get' | ConvertFrom-CSV
                } elseif ($FileStatus.status -eq 'ready') {
                    Write-Verbose -Message "Downloading report to $($OutFile)"
                    InvokeNessusRestRequest -SessionObject $Connection -Path "/scans/$($ScanId)/export/$($FileID.file)/download" -Method 'Get' -OutFile $OutFile
                }
            }
        }
    }
    end {
    }
}