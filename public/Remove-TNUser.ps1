function Remove-TNUser {
    <#
    .SYNOPSIS
        Removes a list of users

    .DESCRIPTION
        Removes a list of users

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER UserId
        The ID of the target user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Remove-TNUser

        Removes a list of users

#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32[]]$UserId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            foreach ($uid in $UserId) {
                Write-PSFMessage -Level Verbose -Message "Deleting user with Id $uid"
                Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/users/$uid" -Method Delete | ConvertFrom-TNRestResponse
            }
        }
    }
}