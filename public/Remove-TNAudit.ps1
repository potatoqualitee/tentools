function Remove-TNAudit {
    <#
    .SYNOPSIS
        Removes a list of audits

    .DESCRIPTION
        Removes a list of audits

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER AuditId
        The ID of the target audit

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNAudit | Remove-TNAudit

        Removes a list of audits

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32[]]$AuditId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            foreach ($id in $AuditId) {
                Write-PSFMessage -Level Verbose -Message "Deleting audit with id $id"
                Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/auditFile/$id" -Method Delete | ConvertFrom-TNRestResponse
                Write-PSFMessage -Level Verbose -Message 'Audit deleted'
            }
        }
    }
}