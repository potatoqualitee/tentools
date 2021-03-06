﻿function Copy-TNPolicy {
    <#
    .SYNOPSIS
        Copies a policy to a new policy

    .DESCRIPTION
        Copies a policy to a new policy

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Copy-TNPolicy -PolicyID 10

        Copies policy with ID 10 to a new policy

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
            $PSDefaultParameterValues["*:SessionObject"] = $session
            $CopiedPolicy = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/policies/$PolicyId/copy" -Method 'Post'
            [PSCustomObject]@{
                Name     = $CopiedPolicy.Name
                PolicyId = $CopiedPolicy.Id
            }
        }
    }
}