function New-AcasScan {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Name
    Parameter description

    .PARAMETER PolicyUUID
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .PARAMETER Target
    Parameter description

    .PARAMETER Enabled
    Parameter description

    .PARAMETER Description
    Parameter description

    .PARAMETER FolderId
    Parameter description

    .PARAMETER ScannerId
    Parameter description

    .PARAMETER Email
    Parameter description

    .PARAMETER CreateDashboard
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding(DefaultParameterSetName = 'Policy')]
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
        [string]
        $Name,

        [Parameter(Mandatory = $true,
            Position = 2,
            ParameterSetName = 'Template',
            ValueFromPipelineByPropertyName = $true)]
        [string]
        $PolicyUUID,

        [Parameter(Mandatory = $true,
            Position = 2,
            ParameterSetName = 'Policy',
            ValueFromPipelineByPropertyName = $true)]
        [int]
        $PolicyId,

        [Parameter(Mandatory = $true,
            Position = 3,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Target,

        [Parameter(Mandatory = $true,
            Position = 4,
            ValueFromPipelineByPropertyName = $true)]
        [bool]
        $Enabled,

        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $true)]
        [string]
        $Description,

        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $true)]
        [Int]
        $FolderId,

        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $true)]
        [Int]
        $ScannerId,

        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Email,

        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $true)]
        [switch]
        $CreateDashboard
    )

    begin {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }



        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

    }
    process {
        foreach ($Connection in $ToProcess) {
            # Join emails as a single comma separated string.
            $emails = $email -join ","

            # Join targets as a single comma separated string.
            $Targets = $target -join ","

            # Build Scan JSON
            $settings = @{
                'name'         = $Name
                'text_targets' = $Targets
            }

            if ($FolderId) {$settings.Add('folder_id', $FolderId)}
            if ($ScannerId) {$settings.Add('scanner_id', $ScannerId)}
            if ($Email.Length -gt 0) {$settings.Add('emails', $emails)}
            if ($Description.Length -gt 0) {$settings.Add('description', $Description)}
            if ($CreateDashboard) {$settings.Add('use_dashboard', $true)}
            if ($PolicyId) {$settings.Add('policy_id', $PolicyId)}

            switch ($PSCmdlet.ParameterSetName) {
                'Template' {
                    Write-Verbose -Message "Using Template with UUID of $($PolicyUUID)"
                    $scanhash = [ordered]@{
                        'uuid'     = $PolicyUUID
                        'settings' = $settings
                    }
                }

                'Policy' {
                    $polUUID = $null
                    $Policies = Get-AcasPolicy -SessionId $Connection.SessionId
                    foreach ($Policy in $Policies) {
                        if ($Policy.PolicyId -eq $PolicyId) {
                            Write-Verbose -Message "Uising Poicy with UUID of $($Policy.PolicyUUID)"
                            $polUUID = $Policy.PolicyUUID
                        }
                    }

                    if ($polUUID -eq $null) {
                        Write-Error -message 'Policy specified does not exist in session.'
                        return
                    } else {
                        $scanhash = [ordered]@{
                            'uuid'     = $polUUID
                            'settings' = $settings
                        }
                    }
                }
            }

            $ScanJson = ConvertTo-Json -InputObject $scanhash -Compress

            $ServerTypeParams = @{
                'SessionObject' = $Connection
                'Path'          = '/scans'
                'Method'        = 'POST'
                'ContentType'   = 'application/json'
                'Parameter'     = $ScanJson
            }

            $NewScan = InvokeNessusRestRequest @ServerTypeParams

            foreach ($scan in $NewScan.scan) {
                $ScanProps = [ordered]@{}
                $ScanProps.add('Name', $scan.name)
                $ScanProps.add('ScanId', $scan.id)
                $ScanProps.add('Status', $scan.status)
                $ScanProps.add('Enabled', $scan.enabled)
                $ScanProps.add('FolderId', $scan.folder_id)
                $ScanProps.add('Owner', $scan.owner)
                $ScanProps.add('UserPermission', $PermissionsId2Name[$scan.user_permissions])
                $ScanProps.add('Rules', $scan.rrules)
                $ScanProps.add('Shared', $scan.shared)
                $ScanProps.add('TimeZone', $scan.timezone)
                $ScanProps.add('CreationDate', $origin.AddSeconds($scan.creation_date).ToLocalTime())
                $ScanProps.add('LastModified', $origin.AddSeconds($scan.last_modification_date).ToLocalTime())
                $ScanProps.add('StartTime', $origin.AddSeconds($scan.starttime).ToLocalTime())
                $ScanProps.add('Scheduled', $scan.control)
                $ScanProps.add('DashboardEnabled', $scan.use_dashboard)
                $ScanProps.Add('SessionId', $Connection.SessionId)

                $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                $ScanObj.pstypenames[0] = 'Nessus.Scan'
                $ScanObj
            }
        }
    }
}