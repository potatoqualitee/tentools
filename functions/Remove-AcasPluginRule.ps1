function Remove-AcasPluginRule {
    <#
    .SYNOPSIS
    Removes a Nessus plugin rule

    .DESCRIPTION
    Can be used to clear a previously defined, scan report altering rule

    .PARAMETER SessionId
    ID of a valid Nessus session

    .PARAMETER Id
    ID number of the rule which would you like removed/deleted

    .EXAMPLE
    Remove-AcasPluginRule -SessionId 0 -Id 500
    Will delete a plugin rule with an ID of 500

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
    Param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$Id
    )

    begin {
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $Connections = $Global:NessusConn

            foreach ($Connection in $Connections) {
                if ($Connection.SessionId -eq $i) {
                    $ToProcess += $Connection
                }
            }
        }
    }

    process {
        foreach ($Connection in $ToProcess) {
            InvokeNessusRestRequest -SessionObject $Connection -Path ('/plugin-rules/{0}' -f $Id) -Method 'Delete'
        }
    }
}