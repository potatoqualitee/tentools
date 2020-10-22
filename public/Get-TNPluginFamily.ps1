function Get-TNPluginFamily {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-TNPluginFamily
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [int32[]]$FamilyId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TNSession)) {
            foreach ($id in $FamilyId) {
                $family = Invoke-TNRequest -SessionObject $session -Path "/plugins/families/$FamilyId" -Method GET
                [pscustomobject]@{
                    FamilyId = $family.id
                    Name     = $family.name
                    Count    = $family.plugins.count
                    Plugins  = $family.plugins
                }
            }
        }
    }
}