function Get-TenScanTemplate {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TenScanTemplate
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            $Templates = Invoke-TenRequest -SessionObject $session -Path '/editor/scan/templates' -Method GET
            foreach ($Template in $Templates.templates) {
                [pscustomobject]@{
                    Name             = $Template.name
                    Title            = $Template.title
                    Description      = $Template.desc
                    UUID             = $Template.uuid
                    CloudOnly        = $Template.cloud_only
                    SubscriptionOnly = $Template.subscription_only
                    SessionId        = $session.SessionId
                } | Select-DefaultView -ExcludeProperty SessionId
            }
        }
    }
}