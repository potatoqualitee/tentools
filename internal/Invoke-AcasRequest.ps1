function Invoke-AcasRequest {
    [CmdletBinding()]
    param
    (
        [object]$SessionObject,
        [string]$Parameter,
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [String]$Method,
        [String]$OutFile,
        [String]$ContentType,
        [String]$InFile,
        [switch]$EnableException
    )

    $RestMethodParams = @{
        'Method'        = $Method
        'URI'           = "$($SessionObject.URI)$($Path)"
        'Headers'       = @{'X-Cookie' = "token=$($SessionObject.Token)"}
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
        Invoke-RestMethod @RestMethodParams -ErrorAction Stop
   
    }
    catch [Net.WebException] {
        [int]$res = $_.Exception.Response.StatusCode
        if ($res -eq 401) {
            # Request failed. More than likely do to time-out.
            # Re-Authenticating using information from session.
            Write-PSFMessage -Level Verbose -Mesage 'The session has expired, Re-authenticating'
            $ReAuthParams = @{
                'Method'        = 'Post'
                'URI'           = "$($SessionObject.URI)/session"
                'Body'          = @{'username' = $SessionObject.Credential.UserName; 'password' = $SessionObject.Credential.GetNetworkCredential().password}
                'ErrorVariable' = 'NessusLoginError'
                'ErrorAction'   = 'SilentlyContinue'
            }

            $TokenResponse = Invoke-RestMethod @ReAuthParams

            if ($NessusLoginError) {
                Write-Error -Message 'Failed to Re-Authenticate the session. Session is being Removed.'
                $FailedConnection = $SessionObject
                [void]$global:NessusConn.Remove($FailedConnection)
            }
            else {
                Write-PSFMessage -Level Verbose -Mesage 'Updating session with new authentication token.'

                # Creating new object with updated token so as to replace in the array the old one.
                $SessionProps = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $SessionProps.add('URI', $SessionObject.URI)
                $SessionProps.Add('Credential', $SessionObject.Credential)
                $SessionProps.add('Token', $TokenResponse.token)
                $SessionProps.Add('SessionId', $SessionObject.SessionId)
                $Sessionobj = New-Object -TypeName psobject -Property $SessionProps
                $Sessionobj.pstypenames[0] = 'Nessus.Session'
                [void]$global:NessusConn.Remove($SessionObject)
                [void]$global:NessusConn.Add($Sessionobj)

                # Re-submit query with the new token and return results.
                $RestMethodParams.Headers = @{'X-Cookie' = "token=$($Sessionobj.Token)"}
                Invoke-RestMethod @RestMethodParams
            }
        }
        else {
            Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}
