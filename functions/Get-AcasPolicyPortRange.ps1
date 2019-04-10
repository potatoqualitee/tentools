function Get-AcasPolicyPortRange {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            foreach ($policy in $PolicyId) {
                try {
                    $policydetail = Get-AcasPolicyDetail -SessionId $session.SessionId -PolicyId $policy
                    [pscustomobject]@{
                        'PolicyId'  = $policy
                        'PortRange' = $policydetail.settings.portscan_range
                    }
                }
                catch {
                    Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}