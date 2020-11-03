function Get-TNPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER Name
        Parameter description

    .PARAMETER PolicyID
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TN
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByID')]
        [string]$PolicyID,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
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