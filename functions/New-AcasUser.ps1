function New-AcasUser {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Credential
    Parameter description

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
        # Nessus session Id
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        # Credentials for connecting to the Nessus Server
        [Parameter(Mandatory,
            Position = 1)]
        [Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory,
            Position = 2)]
        [ValidateSet('Read-Only', 'Regular', 'Administrator', 'Sysadmin')]
        [string]
        $Permission,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName)]
        [ValidateSet('Local', 'LDAP')]
        [string]
        $Type = 'Local',

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName)]
        [string]
        $Email,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName)]
        [string]
        $Name

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

            $NewUser = InvokeNessusRestRequest -SessionObject $Connection -Path '/users' -Method 'Post' -Parameter $NewUserParams

            if ($NewUser) {
                $NewUser
            }
        }
    }
}