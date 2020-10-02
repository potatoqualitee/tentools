function Wait-TenServerReady {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string[]]$ComputerName,
        [int]$Port = "8834",
        [switch]$AcceptSelfSignedCert,
        [switch]$Register,
        [int]$Timeout = 60,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName) {
            $params = @{
                ComputerName    = $computer
                Port            = $Port
                Path            = "/server/status"
                EnableException = $EnableException
            }
            do {
                try {
                    $result = Invoke-NonAuthRequest @params -ErrorAction Stop
                } catch {
                    # keep trying
                }
                Start-Sleep 1
                $i++

                if ($Register) {
                    $registerstatus = $result.status -eq 'register'
                } else {
                    $registerstatus = $false
                }
            }
            until ($result.code -eq 200 -or $i -eq $Timeout -or $registerstatus)
            $result
        }
    }
}