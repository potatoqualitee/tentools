function Get-TNLdapServer {
<#
    .SYNOPSIS
        Gets a list of ldap servers

    .DESCRIPTION
        Gets a list of ldap servers
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Get-TNLdapServer

        Gets a list of ldap servers
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/ldap?fields=name,description,host,port,username,password,encryption,searchBase,searchString,organizations,modifiedTime,created,dn,organizations"
                Method          = "GET"
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}