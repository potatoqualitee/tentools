function Set-AcasPolicyPortRange {
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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [string[]]$Port
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
            $RequestParams = @{
                'SessionObject' = $Session
                'Path'          = "/policies/$($PolicyToChange)"
                'Method'        = 'PUT'
                'ContentType'   = 'application/json'
                'Parameter'     = "{`"settings`": {`"portscan_range`": `"$($Port -join ",")`"}}"
            }

            Invoke-AcasRequest @RequestParams | Out-Null
            Get-AcasPolicyPortRange -SessionId $SessionId -PolicyId $PolicyToChange
        }
    }
}