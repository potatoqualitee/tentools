function Get-TNPolicyTemplate {
    <#
    .SYNOPSIS
        Gets a list of policy templates

    .DESCRIPTION
        Gets a list of policy templates

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target policy template

    .PARAMETER PolicyUUID
        The UUID of the target policy

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNPolicyTemplate

        Gets a list of policy templates

#>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ByUUID')]
        [string]$PolicyUUID,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if ($session.sc) {
                $templates = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/policyTemplate?fields=name,description,editor,profiles,credentials' -Method GET | ConvertFrom-TNRestResponse
            } else {
                $templates = Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path '/editor/policy/templates' -Method GET | ConvertFrom-TNRestResponse
            }

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