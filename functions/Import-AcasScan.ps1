function Import-AcasScan {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER File
    Parameter description

    .PARAMETER Encrypted
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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateScript( {Test-Path -Path $_})]
        [string]$File,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [switch]$Encrypted,
        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring]$Password
    )

    begin {
        if ($Encrypted) {
            $ContentType = 'application/octet-stream'
            $URIPath = 'file/upload?no_enc=1'
        } else {
            $ContentType = 'application/octet-stream'
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

        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    process {
        $collection = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $collection += $connection
                }
            }
        }

        foreach ($conn in $collection) {
            $fileinfo = Get-ItemProperty -Path $File
            $FilePath = $fileinfo.FullName
            $RestClient = New-Object RestSharp.RestClient
            $RestRequest = New-Object RestSharp.RestRequest
            $RestClient.UserAgent = 'Posh-SSH'
            $RestClient.BaseUrl = $conn.uri
            $RestRequest.Method = [RestSharp.Method]::POST
            $RestRequest.Resource = $URIPath

            [void]$RestRequest.AddFile('Filedata', $FilePath, 'application/octet-stream')
            [void]$RestRequest.AddHeader('X-Cookie', "token=$($connection.Token)")
            $result = $RestClient.Execute($RestRequest)
            if ($result.ErrorMessage.Length -gt 0) {
                Write-Error -Message $result.ErrorMessage
            } else {
                $RestParams = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $RestParams.add('file', "$($fileinfo.name)")
                if ($Encrypted) {
                    $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
                    $RestParams.Add('password', $Credential.GetNetworkCredential().Password)
                }

                $impParams = @{ 'Body' = $RestParams }
                $ImportResult = Invoke-RestMethod -Method Post -Uri "$($conn.URI)/scans/import" -header @{'X-Cookie' = "token=$($conn.Token)"} -Body (ConvertTo-Json @{'file' = $fileinfo.name; } -Compress) -ContentType 'application/json'
                if ($ImportResult.scan -ne $null) {
                    $scan = $ImportResult.scan
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
                    $ScanProps.Add('SessionId', $conn.SessionId)

                    $ScanObj = New-Object -TypeName psobject -Property $ScanProps
                    $ScanObj.pstypenames[0] = 'Nessus.Scan'
                    $ScanObj
                }
            }
        }
    }
}