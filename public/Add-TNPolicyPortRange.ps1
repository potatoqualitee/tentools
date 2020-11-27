function Add-TNPolicyPortRange {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER Port
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$Port,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                $method = "PATCH"
            } else {
                $method = "PUT"
            }
            foreach ($PolicyToChange in $PolicyId) {
                try {
                    $policy = Get-TNPolicyDetail -PolicyId $PolicyToChange
                    $ports = "$($Policy.settings.portscan_range),$($Port -join ",")"
                    $params = @{
                        SessionObject   = $session
                        Path            = "/policies/$PolicyToChange"
                        Method          = $method
                        ContentType     = 'application/json'
                        Parameter       = "{`"settings`": {`"portscan_range`": `"$($Ports)`"}}"
                        EnableException = $EnableException
                    }

                    $null = Invoke-TNRequest @params
                    Get-TNPolicyPortRange -PolicyId $PolicyToChange
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}