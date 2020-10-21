function Remove-TenPluginRule {
    <#
    .SYNOPSIS
        Removes a Nessus plugin rule

    .DESCRIPTION
        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER RuleId
        RuleId number of the rule which would you like removed/deleted

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Remove-TenPluginRule -SessionId 0 -RuleId 500
        Will delete a plugin rule with an RuleId of 500

    .EXAMPLE
        Get-TenPluginRule -SessionId 0 | Remove-TenPluginRule
        Will delete all rules

    .EXAMPLE
        Get-TenPluginRule -SessionId 0 | ? {$_.Host -eq 'myComputer'} | Remove-TenPluginRule
        Will find all plugin rules that match the computer name, and delete them

    .INPUTS
        Can accept pipeline data from Get-TenPluginRule

    .OUTPUTS
        Empty, unless an error is received from the server
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$RuleId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession)) {
            Invoke-TenRequest -SessionObject $session -Path ('/plugin-rules/{0}' -f $RuleId) -Method 'Delete'
        }
    }
}