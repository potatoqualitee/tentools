function Export-AcasPolicy {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER PolicyId
    Parameter description

    .PARAMETER OutFile
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$PolicyId,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [string]$OutFile
    )

    process {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }

        foreach ($Connection in $ToProcess) {
            Write-PSFMessage -Level Verbose -Mesage "Exporting policy with id $($PolicyId)."
            $Policy = InvokeNessusRestRequest -SessionObject $Connection -Path "/policies/$($PolicyId)/export" -Method 'GET'
            if ($OutFile.length -gt 0) {
                Write-PSFMessage -Level Verbose -Mesage "Saving policy as $($OutFile)"
                $Policy.Save($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile))
            } else {
                $Policy
            }
            Write-PSFMessage -Level Verbose -Mesage 'Policy exported.'
        }
    }
}