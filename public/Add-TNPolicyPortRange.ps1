function Add-TNPolicyPortRange {
    <#
    .SYNOPSIS
        Adds a list of policy port ranges

    .DESCRIPTION
        Adds a list of policy port ranges

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER Port
        A comma-separated list of ports to add to the Policy range

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Add-TNPolicyPortRange -PolicyId 32 -Port 1433,1434

        Adds port 1433-1434 to Policy with Id 32


    .EXAMPLE
        PS C:\> Get-TNPolicy -Name "Host Scans" | Add-TNPolicyPortRange -Port 1433,1434

        Adds port 1433-1434 to Host Scans policy
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
                        ContentType     = "application/json"
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