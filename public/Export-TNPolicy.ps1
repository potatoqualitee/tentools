function Export-TNPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER OutFile
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$PolicyId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$OutFile,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            Write-PSFMessage -Level Verbose -Message "Exporting policy with id $PolicyId"
            $policy = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/policies/$PolicyId/export" -Method GET
            if ($PSBoundParameters.OutFile) {
                Write-PSFMessage -Level Verbose -Message "Saving policy as $($OutFile)"
                $policy.Save($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile))
                Get-ChildItem -Path $OutFile
            } else {
                $policy
            }
            Write-PSFMessage -Level Verbose -Message 'Policy exported.'
        }
    }
}