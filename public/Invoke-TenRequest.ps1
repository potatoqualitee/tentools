function Invoke-TNRequest {
    [CmdletBinding()]
    Param
    (
        [PSCustomObject[]]$SessionObject = (Get-TNSession),
        [String]$Parameter,
        [Parameter(Mandatory)]
        [String]$Path,
        [Parameter(Mandatory)]
        [String]$Method,
        [String]$OutFile,
        [String]$ContentType,
        [String]$InFile,
        [switch]$EnableException

    )
    process {
        foreach ($session in $SessionObject) {
            # to manage differences between nessus and tenable.sc
            if ($session.sc) {
                $replace = @{
                    "/plugins/families/" = "/pluginFamily/"
                }

                foreach ($key in $replace.keys) {
                    $Path = $Path.Replace($key, $replace[$key])
                }

                if ($Path -match '/group/' -and $Path -match '/user') {
                    $Path = $Path.Replace("/user", "?fields=users")
                }

                if ($Path -match '/policies') {
                    if ($Path -notmatch '/policies/') {
                        $Path = $Path.Replace("/policies", "/policy?filter=*&fields=name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    } else {
                        $id = Split-path $Path -Leaf
                        $Path = $Path.Replace("/policies/", "/policy/$($id)?fields=name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    }
                }

                if ($Path -match '/editor/policy') {
                    if ($Path -notmatch '/editor/policy/') {
                        $Path = $Path.Replace("/editor/policy", "/policy?filter=*&expand=policyTemplate&fields=preferences,families,auditFiles,name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    } else {
                        $id = Split-path $Path -Leaf
                        $Path = $Path.Replace("/editor/policy/", "/policy/$($id)?expand=policyTemplate&fields=preferences,families,auditFiles,name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    }
                }
            }

            if ($session.sc -and $Path -eq "/server/properties") {
                return $null
            }

            if ($session.sc) {
                $headers = @{
                    "X-SecurityCenter" = $session.Token
                }
            } else {
                $headers = @{
                    "X-Cookie" = "token=$($session.Token)"
                }
            }
            $RestMethodParams = @{
                Method          = $Method
                'URI'           = "$($session.URI)$($Path)"
                'Headers'       = $headers
                'ErrorVariable' = 'NessusUserError'
                'WebSession'    = $session.WebSession
            }

            if ($Parameter) {
                $RestMethodParams.Add('Body', $Parameter)
            }

            if ($OutFile) {
                $RestMethodParams.add('OutFile', $OutFile)
            }

            if ($ContentType) {
                $RestMethodParams.add('ContentType', $ContentType)
            }

            if ($InFile) {
                $RestMethodParams.add('InFile', $InFile)
            }

            try {
                #$RestMethodParams.Uri
                Write-PSFMessage -Level Verbose -Message "Connecting to $($session.URI)"
                $results = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
            } catch [Net.WebException] {
                [int]$res = $_.Exception.Response.StatusCode
                if ($res -eq 401) {
                    # Request failed. More than likely do to time-out.
                    # Re-Authenticating using information from session.
                    Write-PSFMessage -Level Verbose -Message 'The session has expired, Re-authenticating'
                    try {
                        $null = $script:NessusConn.Remove($session)
                        $bound = $session.Bound
                        $null = Connect-TNServer @bound
                        $results = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
                    } catch {
                        $msg = Get-ErrorMessage -Record $_
                        Stop-PSFFunction -EnableException:$EnableException -Message $msg -ErrorRecord $_ -Continue
                    }
                } else {
                    $msg = Get-ErrorMessage -Record $_
                    Stop-PSFFunction -EnableException:$EnableException -Message $msg -ErrorRecord $_ -Continue
                }
            } catch {
                $msg = Get-ErrorMessage -Record $_
                Stop-PSFFunction -EnableException:$EnableException -Message $msg -ErrorRecord $_ -Continue
            }

            if ($results.response) {
                $results.response
            } else {
                $results
            }
        }
    }
}