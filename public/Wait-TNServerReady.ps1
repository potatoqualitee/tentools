function Wait-TNServerReady {
<#
    .SYNOPSIS
        Waits for a Nessus server to be ready

    .DESCRIPTION
        Waits for a Nessus server to be ready
        
    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server
        
    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.
        
    .PARAMETER AcceptSelfSignedCert
        Accept self-signed certs
        
    .PARAMETER Register
        Description for Register
        
    .PARAMETER Timeout
        Description for Timeout
        
    .PARAMETER SilentUntil
        Description for SilentUntil
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Wait-TNServerReady

        Waits for a Nessus server to be ready
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,
        [int]$Port = "8834",
        [switch]$AcceptSelfSignedCert,
        [switch]$Register,
        [int]$Timeout = 60,
        [int]$SilentUntil,
        [switch]$EnableException
    )
    process {
        if ($Register) {
            $progressmessage = "Please wait while Nessus prepares the files needed to scan your assets."
        } else {
            $progressmessage = "Waiting for server to be ready."
        }
        foreach ($computer in $ComputerName) {
            $params = @{
                ComputerName         = $computer
                Port                 = $Port
                Path                 = "/server/status"
                AcceptSelfSignedCert = $AcceptSelfSignedCert
                EnableException      = $EnableException
            }
            do {
                $i++
                $helper = @{
                    StepNumber = $i
                    Activity   = "Loading"
                    Message    = $progressmessage
                    TotalSteps = $Timeout
                }
                if ($SilentUntil) {
                    if ($SilentUntil -gt $i) {
                        $result = Invoke-NonAuthRequest @params -WarningAction SilentlyContinue
                    } else {
                        $SilentUntil = $null
                    }
                } else {
                    Write-ProgressHelper @helper
                    $result = Invoke-NonAuthRequest @params -WarningAction SilentlyContinue
                    Start-Sleep 1
                }

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