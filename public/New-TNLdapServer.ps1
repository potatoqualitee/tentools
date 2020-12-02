function New-TNLdapServer {
    <#
    .SYNOPSIS
        Creates new ldap servers

    .DESCRIPTION
        Creates new ldap servers

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target ldap server

    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server

    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request.

    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.

    .PARAMETER BaseDN
        Description for BaseDN

    .PARAMETER Encryption
        Description for Encryption

    .PARAMETER UserObjectFilter
        Description for UserObjectFilter

    .PARAMETER SeachString
        Description for SeachString

    .PARAMETER TimeLimit
        Description for TimeLimit

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> $params = @{
              Name = "DC"
              ComputerName = "dc"
              Credential = $adcred
              BaseDN = "DC=ad,DC=local"
        }
        PS C:\> New-TNLdapServer @params -Verbose

        Creates a new ldap server for the ad.loacl domain, which connects to the domain controller named "DC"

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$ComputerName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [pscredential]$Credential,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int]$Port = 389,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$BaseDN,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet("ldaps", "none", "tls")]
        [string]$Encryption = "tls",
        [string]$UserObjectFilter,
        [string]$SeachString,
        [int]$TimeLimit = 3600,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $body = @{
                name         = $Name
                description  = $Description
                host         = $ComputerName
                port         = $Port
                encryption   = $Encryption.ToLower()
                dn           = $BaseDN
                dnsField     = "dNSHostName"
                timeLimit    = $TimeLimit
                searchString = $SearchString
            }

            if ($PSBoundParameters.Credential) {
                $body.Add("username", $Credential.UserName)
                $body.Add("password", ($Credential.GetNetworkCredential().Password))
            }

            $params = @{
                SessionObject   = $session
                Path            = "/ldap"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}