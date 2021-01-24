function Remove-TNPluginRule {
    <#
    .SYNOPSIS
        Removes a list of plugin rules

    .DESCRIPTION
        Removes a list of plugin rules

        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER RuleId
        The ID of the target rule

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Remove-TNPluginRule -RuleId 500

        Will delete a plugin rule with an RuleId of 500

    .EXAMPLE
        PS C:\> Get-TNPluginRule | Remove-TNPluginRule

        Will delete all rules

    .EXAMPLE
        PS C:\> Get-TNPluginRule | ? {$_.Host -eq 'myComputer'} | Remove-TNPluginRule

        Will find all plugin rules that match the computer name, and delete them

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32]$RuleId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path ('/plugin-rules/{0}' -f $RuleId) -Method Delete | ConvertFrom-TNRestResponse
        }
    }
}