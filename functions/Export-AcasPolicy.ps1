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
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true)]
        [int32]
        $PolicyId,

        [Parameter(Mandatory = $false,
            Position = 2,
            ValueFromPipelineByPropertyName = $true)]
        [string]
        $OutFile

    )

    begin {
    }
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
            Write-Verbose -Message "Exporting policy with id $($PolicyId)."
            $Policy = InvokeNessusRestRequest -SessionObject $Connection -Path "/policies/$($PolicyId)/export" -Method 'GET'
            if ($OutFile.length -gt 0) {
                Write-Verbose -Message "Saving policy as $($OutFile)"
                $Policy.Save($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile))
            } else {
                $Policy
            }
            Write-Verbose -Message 'Policy exported.'
        }
    }
    end {
    }
}