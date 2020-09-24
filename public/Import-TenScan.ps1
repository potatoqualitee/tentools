function Import-TenScan {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenService.

    .PARAMETER File
        Parameter description

    .PARAMETER Encrypted
        Parameter description

    .PARAMETER Password
        Parameter description

    .PARAMETER Credential
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Ten
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$File,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [switch]$Encrypted,
        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring]$Password,
        [securestring]$Credential,
        [switch]$EnableException
    )

    begin {
        if ($Encrypted) {
            $URIPath = 'file/upload?no_enc=1'
        } else {
            $URIPath = 'file/upload'
        }

        $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

        if ($netAssembly) {
            $bindingFlags = [Reflection.BindingFlags] "Static,GetProperty,NonPublic"
            $settingsType = $netAssembly.GetType("System.Net.Configuration.SettingsSectionInternal")

            $instance = $settingsType.InvokeMember("Section", $bindingFlags, $null, $null, @())

            if ($instance) {
                $bindingFlags = "NonPublic", "Instance"
                $useUnsafeHeaderParsingField = $settingsType.GetField("useUnsafeHeaderParsing", $bindingFlags)

                if ($useUnsafeHeaderParsingField) {
                    $useUnsafeHeaderParsingField.SetValue($instance, $true)
                }
            }
        }
    }
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
            $fileinfo = Get-ItemProperty -Path $File
            $FilePath = $fileinfo.FullName
            $RestClient = New-Object RestSharp.RestClient
            $RestRequest = New-Object RestSharp.RestRequest
            $RestClient.UserAgent = 'Posh-SSH'
            $RestClient.BaseUrl = $conn.uri
            $RestRequest.Method = [RestSharp.Method]::POST
            $RestRequest.Resource = $URIPath

            [void]$RestRequest.AddFile('Filedata', $FilePath, 'application/octet-stream')
            [void]$RestRequest.AddHeader('X-Cookie', "token=$($session.Token)")
            $result = $RestClient.Execute($RestRequest)
            if ($result.ErrorMessage.Length -gt 0) {
                Write-Error -Message $result.ErrorMessage
            } else {
                $RestParams = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $RestParams.add('file', "$($fileinfo.name)")
                if ($Encrypted -and ($Password -or $Credential)) {
                    if (-not $Credential) {
                        $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
                    }
                    $RestParams.Add('password', $Credential.GetNetworkCredential().Password)
                }

                foreach ($scan in ((Invoke-RestMethod -Method Post -Uri "$($conn.URI)/scans/import" -header @{'X-Cookie' = "token=$($conn.Token)" } -Body (ConvertTo-Json @{'file' = $fileinfo.name; } -Compress) -ContentType 'application/json').scan)) {
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
                        SessionId        = $conn.SessionId
                    }
                }
            }
        }
    }
}