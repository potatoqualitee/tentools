function New-AcasUser {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Credential
    Credential for connecting to the Nessus Server

    .PARAMETER Permission
    Parameter description

    .PARAMETER Type
    Parameter description

    .PARAMETER Email
    Parameter description

    .PARAMETER Name
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1)]
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory, Position = 2)]
        [ValidateSet('Read-Only', 'Regular', 'Administrator', 'Sysadmin')]
        [string]$Permission,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Local', 'LDAP')]
        [string]$Type = 'Local',
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Email,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Name
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
            $NewUserParams = @{}

            $NewUserParams.Add('type', $Type.ToLower())
            $NewUserParams.Add('permissions', $PermissionsName2Id[$Permission])
            $NewUserParams.Add('username', $Credential.GetNetworkCredential().UserName)
            $NewUserParams.Add('password', $Credential.GetNetworkCredential().Password)

            if ($Email.Length -gt 0) {
                $NewUserParams.Add('email', $Email)
            }

            if ($Name.Length -gt 0) {
                $NewUserParams.Add('name', $Name)
            }

            $NewUser = InvokeNessusRestRequest -SessionObject $connection -Path '/users' -Method 'Post' -Parameter $NewUserParams

            if ($NewUser) {
                $NewUser
            }
        }
    }
}