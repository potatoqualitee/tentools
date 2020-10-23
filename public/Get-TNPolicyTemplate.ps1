function Get-TNPolicyTemplate {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER Name
        Parameter description

    .PARAMETER PolicyUUID
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
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByUUID')]
        [string]$PolicyUUID,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            $templates = Invoke-TNRequest -SessionObject $session -Path '/editor/policy/templates' -Method GET | ConvertFrom-TNRestResponse

            switch ($PSCmdlet.ParameterSetName) {
                'ByName' {
                    $templates | Where-Object Name -eq $Name
                }
                'ByUUID' {
                    $templates | Where-Object Uuid -eq $PolicyUUID
                }
                'All' {
                    $templates
                }
            }
        }
    }
}