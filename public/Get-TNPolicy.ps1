function Get-TNPolicy {
    <#
    .SYNOPSIS
        Gets a list of policies

    .DESCRIPTION
        Gets a list of policies

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target policy

    .PARAMETER PolicyID
        The ID of the target policy

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNPolicy

        Gets a list of policies

#>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByID')]
        [string]$PolicyID,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $policies = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/policies' -Method GET |
                ConvertFrom-TNRestResponse

            switch ($PSCmdlet.ParameterSetName) {
                'ByName' {
                    $policies | Where-Object Name -eq $Name
                }
                'ByID' {
                    $policies | Where-Object Id -eq $PolicyID
                }
                default {
                    $policies
                }
            }
        }
    }
}