function Remove-TNDashboard {
    <#
    .SYNOPSIS
        Removes a dashboard

    .DESCRIPTION
        Removes a dashboard

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER DashboardId
        The ID of the target dashboard

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNDashboard | Remove-TNDashboard

        Removes a list of dashboards

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias("Id")]
        [int32[]]$DashboardId,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            foreach ($id in $DashboardId) {
                Write-PSFMessage -Level Verbose -Message "Deleting dashboard with id $id"
                Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/dashboard/$id" -Method Delete | ConvertFrom-TNRestResponse
                Write-PSFMessage -Level Verbose -Message 'Dashboard deleted'
            }
        }
    }
}