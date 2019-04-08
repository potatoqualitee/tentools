function New-AcasGroup {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Name
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $Name
    )

    begin {
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
            $ServerTypeParams = @{
                'SessionObject' = $Connection
                'Path'          = '/server/properties'
                'Method'        = 'GET'
            }

            $Server = InvokeNessusRestRequest @ServerTypeParams

            if ($Server.capabilities.multi_user -eq 'full') {
                $Groups = InvokeNessusRestRequest -SessionObject $Connection -Path '/groups' -Method 'POST' -Parameter @{'name' = $Name}
                $NewGroupProps = [ordered]@{}
                $NewGroupProps.Add('Name', $Groups.name)
                $NewGroupProps.Add('GroupId', $Groups.id)
                $NewGroupProps.Add('Permissions', $Groups.permissions)
                $NewGroupProps.Add('SessionId', $Connection.SessionId)
                $NewGroupObj = [pscustomobject]$NewGroupProps
                $NewGroupObj
            } else {
                Write-Warning -message "Server for session $($Connection.sessionid) is not licenced for multiple users."
            }
        }
    }
}