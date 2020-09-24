function Add-TenPolicyPortRange {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER Port
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Ten
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [string[]]$Port,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            foreach ($PolicyToChange in $PolicyId) {
                try {
                    $policy = Get-TenPolicyDetail -SessionId $session.SessionId -PolicyId $PolicyToChange
                    $ports = "$($Policy.settings.portscan_range),$($Port -join ",")"
                    $params = @{
                        SessionObject   = $session
                        Path            = "/policies/$($PolicyToChange)"
                        Method          = 'PUT'
                        ContentType     = 'application/json'
                        Parameter       = "{`"settings`": {`"portscan_range`": `"$($Ports)`"}}"
                        EnableException = $EnableException
                    }

                    $null = Invoke-TenRequest @params
                    Get-TenPolicyPortRange -SessionId $session.SessionId -PolicyId $PolicyToChange
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}