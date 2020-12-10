function Remove-TNPolicy {
    <#
    .SYNOPSIS
        Removes a list of policies

    .DESCRIPTION
        Removes a list of policies

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Remove-TNPolicy

        Removes a list of policies

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$PolicyId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            Write-PSFMessage -Level Verbose -Message "Deleting policy with id $PolicyId"
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/policies/$PolicyId" -Method 'DELETE'
            Write-PSFMessage -Level Verbose -Message 'Policy deleted.'
        }
    }
}