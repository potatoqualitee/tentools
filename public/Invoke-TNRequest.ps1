function Invoke-TNRequest {
    <#
    .SYNOPSIS
        Invokes a list of requests

    .DESCRIPTION
        Invokes a list of requests

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Parameter
        The body of the request

    .PARAMETER Path
        The path, such as /folders

    .PARAMETER Method
        The HTTP method such as GET, PUT, POST

    .PARAMETER OutFile
        The output as a file

    .PARAMETER ContentType
        The content type such as application/json

    .PARAMETER InFile
        The file to upload, I guess

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> $session = Connect-TNServer -ComputerName nessus -Credential admin
        PS C:\> $params = @{
                    SessionObject   = $session
                    Path            = "/folders"
                    Method          = "GET"
                    EnableException = $EnableException
                }
        PS C:\> Invoke-TNRequest @params

        Returns the output of Nessus' REST results for /folders. A connection is neede only once.

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        $Parameter,
        [Parameter(Mandatory)]
        [String]$Path,
        [Parameter(Mandatory)]
        [String]$Method,
        [String]$OutFile,
        [String]$ContentType,
        [String]$InFile,
        [switch]$Header,
        [switch]$EnableException


    )
    process {
        foreach ($session in $SessionObject) {
            # to manage differences between nessus and tenable.sc
            if ($session.sc) {
                $replace = @{
                    "/plugins/families/" = "/pluginFamily/"
                    "/groups"            = "/group"
                }

                foreach ($key in $replace.keys) {
                    $Path = $Path.Replace($key, $replace[$key])
                }
                if ($Path -match '/group/' -and $Path -match '/user' -and $Method -eq "Get") {
                    $Path = $Path.Replace("/user", "?fields=users")
                }
                if ($Path -match '/user' -and $Path -notmatch '/group/') {
                    $Path = $Path.Replace("/users", "/user?fields=apiKeys,name,username,firstname,lastname,group,role,lastLogin,canManage,canUse,locked,status,title,email,id")
                }
                # https://securitycenter:8834/#/scans/reports/5/hosts
                # https://securitycenter:8834/#/scans/reports/5/vulnerabilities
                # https://securitycenter:8834/#/scans/reports/5/history

                if ($Path -match '/scans') {
                    if ($Path -notmatch '/scans/') {
                        $Path = $Path.Replace("/scan", "/scan?filter=*&fields=canUse,canManage,owner,groups,ownerGroup,status,name,createdTime,schedule,policy,plugin,type")
                    } else {
                        $id = Split-path $Path -Leaf
                        $Path = $Path.Replace("/$id","/")
                        $Path = $Path.Replace("/scans/", "/scan/$($id)?fields=modifiedTime,description,name,repository,schedule,dhcpTracking,emailOnLaunch,emailOnFinish,reports,history,canUse,canManage,status,canUse,canManage,owner,groups,ownerGroup,status,name,createdTime,schedule,policy,plugin,type,policy,zone,credentials,timeoutAction,rolloverType,scanningVirtualHosts,classifyMitigatedAge,assets,ipList,maxScanTime,plugin&expand=details,credentials")
                    }
                }

                if ($Path -match '/policies') {
                    if ($Path -notmatch '/policies/') {
                        $Path = $Path.Replace("/policies", "/policy?filter=usable&fields=name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    } else {
                        $id = Split-path $Path -Leaf
                        $Path = $Path.Replace("/$id","/")
                        $Path = $Path.Replace("/policies/", "/policy/$($id)?fields=name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    }
                }

                if ($Path -match '/editor/policy') {
                    if ($Path -notmatch '/editor/policy/') {
                        $Path = $Path.Replace("/editor/policy", "/policy?filter=*&expand=policyTemplate&fields=preferences,families,auditFiles,name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    } else {
                        $id = Split-path $Path -Leaf
                        $Path = $Path.Replace("/$id","/")
                        $Path = $Path.Replace("/editor/policy/", "/policy/$($id)?expand=policyTemplate&fields=preferences,families,auditFiles,name,description,tags,type,createdTime,ownerGroup,groups,owner,modifiedTime,policyTemplate,canUse,canManage,status")
                    }
                }
            }
            if ($session.sc -and $Path -eq "/server/properties") {
                return
            }

            $RestMethodParams = @{
                Method        = $Method
                URI           = "$($session.URI)$($Path)"
                Headers       = $session.Headers
                ErrorVariable = 'NessusUserError'
                WebSession    = $session.WebSession
            }

            if ($Parameter) {
                if ($Parameter -is [hashtable]) {
                    $ContentType = "application/json"
                    $Parameter = $Parameter | ConvertTo-Json
                }
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
                if ($Header) {
                    Write-PSFMessage -Level Verbose -Message "Connecting to $($session.URI)"
                    $results = Invoke-WebRequest @RestMethodParams -ErrorAction Stop
                    return $results.Headers
                }

                #$RestMethodParams.Uri
                Write-PSFMessage -Level Verbose -Message "Connecting to $($session.URI)"
                $results = Invoke-RestMethod @RestMethodParams -ErrorAction Stop

            } catch [Net.WebException] {
                [int]$responsecode = $_.Exception.Response.StatusCode
                if ($responsecode -eq 401) {
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
                    if ($_.ErrorDetails) {
                        $details = $_.ErrorDetails | ConvertFrom-Json
                        $errormsg = $details.error_msg.ToString().Replace("`n", " ")
                        $msg = "Response code $responsecode, Error $($details.error_code): $errormsg"
                        Stop-PSFFunction -EnableException:$EnableException -Message $msg -Continue
                    } else {
                        Stop-PSFFunction -EnableException:$EnableException -Message $PSitem -Continue
                    }
                }
            } catch {
                if ($_.ErrorDetails) {
                    $details = $_.ErrorDetails | ConvertFrom-Json
                    $errormsg = $details.error_msg.ToString().Replace("`n", " ")
                    $msg = "Response code $responsecode, Error $($details.error_code): $errormsg"
                    Stop-PSFFunction -EnableException:$EnableException -Message $msg -Continue
                } else {
                    Stop-PSFFunction -EnableException:$EnableException -Message $PSitem -Continue
                }
            }

            if ($results.response) {
                $results.response
            } else {
                $results
            }
        }
    }
}