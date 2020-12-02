function Export-TNPolicy {
<#
    .SYNOPSIS
        Exports a list of policys

    .DESCRIPTION
        Exports a list of policys
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER PolicyId
        The ID of the target policy
        
    .PARAMETER OutFile
        Description for OutFile
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Export-TNPolicy

        Exports a list of policys
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$PolicyId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$OutFile,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
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