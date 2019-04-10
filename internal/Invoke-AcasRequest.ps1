function Invoke-AcasRequest {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        $SessionObject,

        [Parameter(Mandatory = $false)]
        $Parameter,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [String]$Method,

        [Parameter(Mandatory = $false)]
        [String]$OutFile,

        [Parameter(Mandatory = $false)]
        [String]$ContentType,

        [Parameter(Mandatory = $false)]
        [String]$InFile,

        [Parameter(Mandatory = $false)]
        [switch]$EnableException

    )
    process {
        $RestMethodParams = @{
            Method          = $Method
            'URI'           = "$($SessionObject.URI)$($Path)"
            'Headers'       = @{'X-Cookie' = "token=$($SessionObject.Token)" }
            'ErrorVariable' = 'NessusUserError'
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
            Write-PSFMessage -Level Verbose -Message "Connecting to $($SessionObject.URI)"
            $results = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
   
        }
        catch [Net.WebException] {
            [int]$res = $_.Exception.Response.StatusCode
            if ($res -eq 401) {
                # Request failed. More than likely do to time-out.
                # Re-Authenticating using information from session.
                Write-PSFMessage -Level Verbose -Message 'The session has expired, Re-authenticating'

                if ($SessionObject.Credential) {
                    $body = @{'username' = $SessionObject.Credential.UserName; 'password' = $SessionObject.Credential.GetNetworkCredential().password }
                }
                else {
                    $body = $null
                }

                $ReAuthParams = @{
                    Method          = 'Post'
                    'URI'           = "$($SessionObject.URI)/session"
                    'Body'          = $body
                    'ErrorVariable' = 'NessusLoginError'
                    'ErrorAction'   = 'SilentlyContinue'
                }
                $TokenResponse = Invoke-RestMethod @ReAuthParams

                if ($NessusLoginError) {
                    Write-Error -Message 'Failed to Re-Authenticate the session. Session is being Removed.'
                    $FailedConnection = $SessionObject
                    [void]$Global:NessusConn.Remove($FailedConnection)
                }
                else {
                    Write-PSFMessage -Level Verbose -Message 'Updating session with new authentication token.'

                    # Creating new object with updated token so as to replace in the array the old one.
                    $SessionProps = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                    $SessionProps.add('URI', $SessionObject.URI)
                    $SessionProps.Add('Credential', $SessionObject.Credential)
                    $SessionProps.add('Token', $TokenResponse.token)
                    $SessionProps.Add('SessionId', $SessionObject.SessionId)
                    $Sessionobj = New-Object -TypeName psobject -Property $SessionProps
                    $Sessionobj.pstypenames[0] = 'Nessus.Session'
                    [void]$Global:NessusConn.Remove($SessionObject)
                    [void]$Global:NessusConn.Add($Sessionobj)

                    # Re-submit query with the new token and return results.
                    $RestMethodParams.Headers = @{'X-Cookie' = "token=$($Sessionobj.Token)" }
                    try {
                        $results = Invoke-RestMethod @RestMethodParams -ErrorAction Stop
                    }
                    catch {
                        $msg = Get-ErrorMessage -Record $_
                        Stop-PSFFunction -Message $msg -ErrorRecord $_ -Continue
                    }
                }
            }
        } 
        catch {
            $msg = Get-ErrorMessage -Record $_
            Stop-PSFFunction -Message $msg -ErrorRecord $_ -Continue
        }
        $results
    }
}