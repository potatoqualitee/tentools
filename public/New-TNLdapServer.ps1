function New-TNLdapServer {
    <#
    .SYNOPSIS
        Adds an organization

    .DESCRIPTION
        Adds an organization

    .PARAMETER Name
        Parameter description

    .PARAMETER ZoneSelection
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS>  $params = @{
              Name = "DC"
              ComputerName = "dc"
              Credential = $adcred
              BaseDN = "DC=ad,DC=local"
        }
        PS>  New-TNLdapServer @params -Verbose

    #>
    [CmdletBinding()]
    param
    (
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
        foreach ($session in (Get-TNSession)) {
            if (-not $session.sc) {
                Stop-PSFFunction -Message "Only tenable.sc supported" -Continue
            }

            $body = @{
                name         = $Name
                description  = $Description
                host         = $ComputerName
                port         = $Port
                encryption   = $Encryption
                dn           = $BaseDN
                dnsField     = "dNSHostName"
                #lowercase    = $LowerCase
                timeLimit    = $TimeLimit
                searchString = $SearchString
            }

            if ($PSBoundParameters.Credential) {
                $body.Add("username", $Credential.UserName)
                $body.Add("password", ($Credential.GetNetworkCredential().Password))
            }

            $params = @{
                Path            = "/ldap"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}