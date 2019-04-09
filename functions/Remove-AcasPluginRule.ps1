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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$Id
    )

    begin {
        $collection = @()

        foreach ($i in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $collection += $connection
                }
            }
        }
    }

    process {
        foreach ($connection in $collection) {
            Invoke-AcasRequest -SessionObject $connection -Path ('/plugin-rules/{0}' -f $Id) -Method 'Delete'
        }
    }
}