function Set-TNUserPassword {
<#
    .SYNOPSIS
        Sets properties for user passwords

    .DESCRIPTION
        Sets properties for user passwords
        
    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer
        
    .PARAMETER UserId
        The ID of the target user
        
    .PARAMETER Password
        The required password. This is a securestring type. The easiest way to get this is by using (Get-Credential).Password which extracts the password in a secure manner (and does not care about the username.)
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Set-TNUserPassword

        Sets properties for user passwords
        
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32[]]$UserId,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [securestring]$Password,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            foreach ($uid in $UserId) {
                Write-PSFMessage -Level Verbose -Message "Updating user with Id $uid"
                $params = @{'password' = $([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))) }
                $paramJson = ConvertTo-Json -InputObject $params -Compress
                Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/users/$uid/chpasswd" -Method 'PUT' -Parameter $paramJson -ContentType 'application/json'
            }
        }
    }
}