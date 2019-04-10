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
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER Email
        Parameter description

    .PARAMETER CreateDashboard
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding(DefaultParameterSetName = 'Policy')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(Mandatory, Position = 2, ParameterSetName = 'Template', ValueFromPipelineByPropertyName)]
        [string]$PolicyUUID,
        [Parameter(Mandatory, Position = 2, ParameterSetName = 'Policy', ValueFromPipelineByPropertyName)]
        [int]$PolicyId,
        [Parameter(Mandatory, Position = 3, ValueFromPipelineByPropertyName)]
        [string[]]$Target,
        [Parameter(Mandatory, Position = 4, ValueFromPipelineByPropertyName)]
        [bool]$Enabled,
        [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName)]
        [string]$Description,
        [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName)]
        [Int]$FolderId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Int]$scannerId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Email,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$CreateDashboard,
        [switch]$EnableException
    )

    begin {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0 
    }
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
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
            if ($scannerId) {$settings.Add('scanner_id', $scannerId)}
            if ($Email.Length -gt 0) {$settings.Add('emails', $emails)}
            if ($Description.Length -gt 0) {$settings.Add('description', $Description)}
            if ($CreateDashboard) {$settings.Add('use_dashboard', $true)}
            if ($PolicyId) {$settings.Add('policy_id', $PolicyId)}

            switch ($PSCmdlet.ParameterSetName) {
                'Template' {
                    Write-PSFMessage -Level Verbose -Mesage "Using Template with UUID of $($PolicyUUID)"
                    $scanhash = [ordered]@{
                        'uuid'     = $PolicyUUID
                        'settings' = $settings
                    }
                }

                'Policy' {
                    $polUUID = $null
                    $Policies = Get-AcasPolicy -SessionId $session.SessionId
                    foreach ($Policy in $Policies) {
                        if ($Policy.PolicyId -eq $PolicyId) {
                            Write-PSFMessage -Level Verbose -Mesage "Uising Poicy with UUID of $($Policy.PolicyUUID)"
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
                'SessionObject' = $session
                'Path'          = '/scans'
                'Method'        = 'POST'
                'ContentType'   = 'application/json'
                'Parameter'     = $ScanJson
            }

            $NewScan = Invoke-AcasRequest @ServerTypeParams

            foreach ($scan in $NewScan.scan) {
                $ScanProps = [ordered]@{}
                $ScanProps.add('Name', $scan.name)
                $ScanProps.add('ScanId', $scan.id)
                $ScanProps.add('Status', $scan.status)
                $ScanProps.add('Enabled', $scan.enabled)
                $ScanProps.add('FolderId', $scan.folder_id)
                $ScanProps.add('Owner', $scan.owner)
                $ScanProps.add('UserPermission', $permidenum[$scan.user_permissions])
                $ScanProps.add('Rules', $scan.rrules)
                $ScanProps.add('Shared', $scan.shared)
                $ScanProps.add('TimeZone', $scan.timezone)
                $ScanProps.add('CreationDate', $origin.AddSeconds($scan.creation_date).ToLocalTime())
                $ScanProps.add('LastModified', $origin.AddSeconds($scan.last_modification_date).ToLocalTime())
                $ScanProps.add('StartTime', $origin.AddSeconds($scan.starttime).ToLocalTime())
                $ScanProps.add('Scheduled', $scan.control)
                $ScanProps.add('DashboardEnabled', $scan.use_dashboard)
                $ScanProps.Add('SessionId', $session.SessionId)

                $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                $ScanObj.pstypenames[0] = 'Nessus.Scan'
                $ScanObj
            }
        }
    }
}