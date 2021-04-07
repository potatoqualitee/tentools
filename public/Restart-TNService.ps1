function Restart-TNService {
    <#
    .SYNOPSIS
        Restarts a list of services

    .DESCRIPTION
        Restarts a list of services

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Restart-TNService

        Restarts a list of services

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        # Nessus session Id
        [switch]$EnableException
    )
    begin {
        $params = @{ }
        $paramJson = ConvertTo-Json -InputObject $params -Compress
    }
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/server/restart" -Method 'Post' -Parameter $paramJson -ContentType "application/json"
        }
    }
}