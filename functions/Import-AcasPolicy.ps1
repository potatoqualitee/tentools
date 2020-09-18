function Import-AcasPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER File
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
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path -Path $_ })]
        [string]$File,
        [switch]$EnableException
    )

    begin {
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
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $fileinfo = Get-ItemProperty -Path $File
            $FilePath = $fileinfo.FullName
            $RestClient = New-Object RestSharp.RestClient
            $RestRequest = New-Object RestSharp.RestRequest
            $RestClient.UserAgent = 'Posh-SSH'
            $RestClient.BaseUrl = $session.uri
            $RestRequest.Method = [RestSharp.Method]::POST
            $RestRequest.Resource = 'file/upload'

            [void]$RestRequest.AddFile('Filedata', $FilePath, 'application/octet-stream')
            [void]$RestRequest.AddHeader('X-Cookie', "token=$($session.Token)")
            $result = $RestClient.Execute($RestRequest)
            if ($result.ErrorMessage.Length -gt 0) {
                Write-Error -Message $result.ErrorMessage
            }
            else {
                $RestParams = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $RestParams.add('file', "$($fileinfo.name)")
                if ($Encrypted -and ($Credential -or $Password)) {
                    if (-not $Credential) {
                        $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
                    }
                    $RestParams.Add('password', $Credential.GetNetworkCredential().Password)
                }

                $Policy = Invoke-RestMethod -Method Post -Uri "$($session.URI)/policies/import" -header @{'X-Cookie' = "token=$($session.Token)" } -Body (ConvertTo-Json @{'file' = $fileinfo.name; } -Compress) -ContentType 'application/json'
                [pscustomobject]@{ 
                    Name           = $Policy.Name
                    PolicyId       = $Policy.id
                    Description    = $Policy.description
                    PolicyUUID     = $Policy.template_uuid
                    Visibility     = $Policy.visibility
                    Shared         = (if ($Policy.shared -eq 1) { $True }else { $False })
                    Owner          = $Policy.owner
                    UserId         = $Policy.owner_id
                    NoTarget       = $Policy.no_target
                    UserPermission = $Policy.user_permissions
                    Modified       = $origin.AddSeconds($Policy.last_modification_date).ToLocalTime()
                    Created        = $origin.AddSeconds($Policy.creation_date).ToLocalTime()
                    SessionId      = $session.SessionId
                }
            }
        }
    }
}