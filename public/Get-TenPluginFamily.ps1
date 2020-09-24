function Get-TenPluginFamily {
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
        PS> Get-TenPluginFamily
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
            foreach ($families in (Invoke-TenRequest -SessionObject $session -Path '/plugins/families' -Method 'Get')) {
                foreach ($family in $families) {
                    [pscustomobject]@{
                        Name     = $family.name
                        FamilyId = $family.id
                        Count    = $family.count
                    }
                }
            }
        }
    }
}