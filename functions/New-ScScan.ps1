function New-ScScan {
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
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER Email
        Parameter description

    .PARAMETER CreateDashboard
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Sc
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
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
             
            # Join emails as a single comma separated string.
            $emails = $email -join ","

            # Join targets as a single comma separated string.
            $targets = $target -join ","

            # Build Scan JSON
            $settings = @{
                name         = $Name
                text_targets = $targets
            }

            if ($FolderId) { $settings.Add('folder_id', $FolderId) }
            if ($scannerId) { $settings.Add('scanner_id', $scannerId) }
            if ($Email.Length -gt 0) { $settings.Add('emails', $emails) }
            if ($Description.Length -gt 0) { $settings.Add('description', $Description) }
            if ($CreateDashboard) { $settings.Add('use_dashboard', $true) }
            if ($PolicyId) { $settings.Add('policy_id', $PolicyId) }

            switch ($PSCmdlet.ParameterSetName) {
                'Template' {
                    Write-PSFMessage -Level Verbose -Message "Using Template with UUID of $($PolicyUUID)"
                    $scanhash = [pscustomobject]@{
                        uuid     = $PolicyUUID
                        settings = $settings
                    }
                }

                'Policy' {
                    $polUUID = $null
                    $Policies = Get-ScPolicy -SessionId $session.SessionId
                    foreach ($Policy in $Policies) {
                        if ($Policy.PolicyId -eq $PolicyId) {
                            Write-PSFMessage -Level Verbose -Message "Uising Poicy with UUID of $($Policy.PolicyUUID)"
                            $polUUID = $Policy.PolicyUUID
                        }
                    }

                    if ($null -eq $polUUID) {
                        Stop-PSFFunction -Message 'Policy specified does not exist in session.' -Continue
                    }
                    else {
                        $scanhash = [pscustomobject]@{
                            uuid     = $polUUID
                            settings = $settings
                        }
                    }
                }
            }

            $ScanJson = ConvertTo-Json -InputObject $scanhash -Compress

            $serverparams = @{
                SessionObject = $session
                Path          = '/scans'
                Method        = 'POST'
                ContentType   = 'application/json'
                Parameter     = $ScanJson
            }
            
            foreach ($scan in (Invoke-ScRequest @serverparams).scan) {
                [pscustomobject]@{
                    Name             = $scan.name
                    ScanId           = $scan.id
                    Status           = $scan.status
                    Enabled          = $scan.enabled
                    FolderId         = $scan.folder_id
                    Owner            = $scan.owner
                    UserPermission   = $permidenum[$scan.user_permissions]
                    Rules            = $scan.rrules
                    Shared           = $scan.shared
                    TimeZone         = $scan.timezone
                    CreationDate     = $origin.AddSeconds($scan.creation_date).ToLocalTime()
                    LastModified     = $origin.AddSeconds($scan.last_modification_date).ToLocalTime()
                    StartTime        = $origin.AddSeconds($scan.starttime).ToLocalTime()
                    Scheduled        = $scan.control
                    DashboardEnabled = $scan.use_dashboard
                    SessionId        = $session.SessionId
                }
            }
        }
    }
}