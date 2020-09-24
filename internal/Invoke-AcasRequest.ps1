function Invoke-AcasRequest {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        $SessionObject,
        $Parameter,
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [String]$Method,
        [String]$OutFile,
        [String]$ContentType,
        [String]$InFile,
        [switch]$EnableException

    )
    begin {
        # to manage differences between nessus and tenable.sc
        if ($SessionObject.sc) {
            foreach ($key in $replace.keys) {
                $Path = $Path.Replace($key, $replace[$key])
            }
            if ($Path -match '/group/' -and $Path -match '/user') {
                $Path = $Path.Replace("/user", "?fields=users")
            }
        }
    }
    process {
        if ($SessionObject.sc -and $Path -eq "/server/properties") {
            return $null
        }

        if ($SessionObject.sc) {
            $headers = @{
                "X-SecurityCenter" = $SessionObject.Token
            }
        } else {
            $headers = @{
                "X-Cookie" = "token=$($SessionObject.Token)"
            }
        }
        $RestMethodParams = @{
            Method          = $Method
            'URI'           = "$($SessionObject.URI)$($Path)"
            'Headers'       = $headers
            'ErrorVariable' = 'NessusUserError'
            'WebSession'    = $SessionObject.WebSession
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
        } catch [Net.WebException] {
            [int]$res = $_.Exception.Response.StatusCode
            if ($res -eq 401) {
                # Request failed. More than likely do to time-out.
                # Re-Authenticating using information from session.
                Write-PSFMessage -Level Verbose -Message 'The session has expired, Re-authenticating'
                try {
                    $null = $script:NessusConn.Remove($SessionObject)
                    $results = Invoke-RestMethod $SessionObject.PSBoundParameters -ErrorAction Stop
                } catch {
                    $msg = Get-ErrorMessage -Record $_
                    Stop-PSFFunction -Message $msg -ErrorRecord $_ -Continue
                }
            } else {
                $msg = Get-ErrorMessage -Record $_
                Stop-PSFFunction -Message $msg -ErrorRecord $_ -Continue
            }
        } catch {
            $msg = Get-ErrorMessage -Record $_
            Stop-PSFFunction -Message $msg -ErrorRecord $_ -Continue
        }

        if ($results.response) {
            $results.response
        } else {
            $results
        }
    }
}