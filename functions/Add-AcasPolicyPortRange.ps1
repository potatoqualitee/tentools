function Add-AcasPolicyPortRange {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .PARAMETER Port
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32]
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32[]]
        $PolicyId,

        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Port
    )

    begin {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        if ($SessionId -notin $sessions) {
            throw "SessionId $($SessionId) is not present in the current sessions."
        }
        $Session = Get-AcasSession -SessionId $SessionId
    }
    process {
        foreach ($PolicyToChange in $PolicyId) {
            try {
                $Policy = Get-AcasPolicyDetail -SessionId $Session.SessionId -PolicyId $PolicyToChange
                $Ports = "$($Policy.settings.portscan_range),$($Port -join ",")"
                $RequestParams = @{
                    'SessionObject' = $Session
                    'Path'          = "/policies/$($PolicyToChange)"
                    'Method'        = 'PUT'
                    'ContentType'   = 'application/json'
                    'Parameter'     = "{`"settings`": {`"portscan_range`": `"$($Ports)`"}}"
                }

                InvokeNessusRestRequest @RequestParams | Out-Null
                Get-AcasPolicyPortRange -SessionId $SessionId -PolicyId $PolicyToChange
            } catch {
                throw $_
            }
        }
    }
    end {
    }
}