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
        }
        catch [Net.WebException] {
            [int]$res = $_.Exception.Response.StatusCode
            if ($res -eq 401) {
                # Request failed. More than likely do to time-out.
                # Re-Authenticating using information from session.
                Write-PSFMessage -Level Verbose -Message 'The session has expired, Re-authenticating'
                try {
                    $null = $script:NessusConn.Remove($SessionObject)
                    $results = Invoke-RestMethod $SessionObject.PSBoundParameters -ErrorAction Stop
                }
                catch {
                    $msg = Get-ErrorMessage -Record $_
                    Stop-PSFFunction -Message "$msg Detailed Error: $_" -ErrorRecord $_ -Continue
                }
            } else {
            $msg = Get-ErrorMessage -Record $_
            Stop-PSFFunction -Message "$msg Detailed Error: $_" -ErrorRecord $_ -Continue
            }
        } 
        catch {
            $msg = Get-ErrorMessage -Record $_
            Stop-PSFFunction -Message "$msg Detailed Error: $_" -ErrorRecord $_ -Continue
        }
        if ($results.response) {
            $results.response
        } else {
            $results
        }
    }
}