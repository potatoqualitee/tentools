function Get-TenPolicyTemplate {
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
        PS> Get-Ten
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
        foreach ($session in (Get-TenSession)) {
            $templates = Invoke-TenRequest -SessionObject $session -Path '/editor/policy/templates' -Method GET

            switch ($PSCmdlet.ParameterSetName) {
                'ByName' {
                    $templates = $templates.templates | Where-Object { $_.name -eq $Name }
                }
                'ByUUID' {
                    $templates = $templates.templates | Where-Object { $_.uuid -eq $PolicyUUID }
                }
                'All' {
                    $templates = $templates.templates
                }
            }

            foreach ($template in $templates) {
                [pscustomobject]@{
                    Name             = $template.name
                    Title            = $template.title
                    Description      = $template.desc
                    PolicyUUID       = $template.uuid
                    CloudOnly        = $template.cloud_only
                    SubscriptionOnly = $template.subscription_only
                    SessionId        = $session.SessionId
                }
            }
        }
    }
}