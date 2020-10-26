function Import-TNPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER File
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
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]$FilePath,
        [switch]$EnableException
    )

    begin {
        try {
            $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])
        } catch {
            # probably Linux
        }
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
        foreach ($session in (Get-TNSession)) {
            foreach ($file in $FilePath) {
                $fileinfo = Get-ItemProperty -Path $file
                $fullname = $fileinfo.FullName
                $restclient = New-Object RestSharp.RestClient
                $restrequest = New-Object RestSharp.RestRequest
                $restclient.UserAgent = 'tentools'
                $restclient.BaseUrl = $session.uri
                $restrequest.Method = [RestSharp.Method]::POST
                $restrequest.Resource = 'file/upload'
                $restclient.CookieContainer = $session.WebSession.Cookies
                [void]$restrequest.AddFile('Filedata', $fullname, 'application/octet-stream')

                foreach ($header in $session.Headers) {
                    [void]$restrequest.AddHeader($header.Keys, $header.Values)
                }
                $result = $restclient.Execute($restrequest)

                if ($result.ErrorMessage) {
                    Stop-PSFFunction -Message $result.ErrorMessage -Continue
                }
                $restparams = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $restparams.add('file', "$($fileinfo.name)")
                if ($Encrypted -and ($Credential -or $Password)) {
                    if (-not $Credential) {
                        $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', $Password
                    }
                    $restparams.Add('password', $Credential.GetNetworkCredential().Password)
                }
                if ($session.sc) {
                    $filename = ($result.Content | ConvertFrom-Json | Select-Object Response | ConvertFrom-TNRestResponse).Filename
                    $body = ConvertTo-Json @{'filename' = $filename; } -Compress
                } else {
                    $body = ConvertTo-Json @{'file' = $fileinfo.name; } -Compress
                }

                # parse Content           : {"fileuploaded":"policy-7.nessus"}
                $Policy = Invoke-TnRequest -Method Post -Path "/policies/import" -Parameter $body -ContentType 'application/json' -SessionObject $session
                [pscustomobject]@{
                    Name           = $Policy.Name
                    PolicyId       = $Policy.id
                    Description    = $Policy.description
                    PolicyUUID     = $Policy.template_uuid
                    Visibility     = $Policy.visibility
                    Shared         = $(if ($Policy.shared -eq 1) { $True }else { $False })
                    Owner          = $Policy.owner
                    UserId         = $Policy.owner_id
                    NoTarget       = $Policy.no_target
                    UserPermission = $Policy.user_permissions
                    Modified       = $origin.AddSeconds($Policy.last_modification_date).ToLocalTime()
                    Created        = $origin.AddSeconds($Policy.creation_date).ToLocalTime()
                }
            }
        }
    }
}