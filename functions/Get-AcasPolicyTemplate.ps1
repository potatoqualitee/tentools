function Get-ScPolicyTemplate {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-ScService.

    .PARAMETER Name
        Parameter description

    .PARAMETER PolicyUUID
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Sc
#>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUUID')]
        [string]$PolicyUUID,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-ScSession -SessionId $SessionId)) {
            $templates = Invoke-ScRequest -SessionObject $session -Path '/editor/policy/templates' -Method 'Get'

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
                } | Select-DefaultView -ExcludeProperty SessionId
            }
        }
    }
}