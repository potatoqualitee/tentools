function Remove-AcasPluginRule {
    <#
    .SYNOPSIS
        Removes a Nessus plugin rule

    .DESCRIPTION
        Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER RuleId
        RuleId number of the rule which would you like removed/deleted

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Remove-AcasPluginRule -SessionId 0 -RuleId 500
        Will delete a plugin rule with an RuleId of 500

    .EXAMPLE
        Get-AcasPluginRule -SessionId 0 | Remove-AcasPluginRule
        Will delete all rules

    .EXAMPLE
        Get-AcasPluginRule -SessionId 0 | ? {$_.Host -eq 'myComputer'} | Remove-AcasPluginRule
        Will find all plugin rules that match the computer name, and delete them

    .INPUTS
        Can accept pipeline data from Get-AcasPluginRule

    .OUTPUTS
        Empty, unless an error is received from the server
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$RuleId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            Invoke-AcasRequest -SessionObject $session -Path ('/plugin-rules/{0}' -f $RuleId) -Method 'Delete'
        }
    }
}