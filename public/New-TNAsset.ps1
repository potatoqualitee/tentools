function New-TNAsset {
    <#
    .SYNOPSIS
        Creates new assets

    .DESCRIPTION
        Creates new assets

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target asset

    .PARAMETER Description
        Description for Description

    .PARAMETER Type
        The type of asset

    .PARAMETER IPRange
        Description for IPRange

    .PARAMETER Repository
        Description for Repository

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNAsset

        Creates new assets

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$Name,
        [string]$Description,
        [ValidateSet("static")]
        [string]$Type = "static",
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$IPRange,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Repository,
        [switch]$EnableException
    )
    begin {
        if (-not $PSBoundParameters.IPRange -and -not $PSBoundParameters.Repository -and $Type -eq "static") {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify either Repository or IPRange"
            return
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }

        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            if ($PSBoundParameters.Repository) {
                $repo = Get-TNRepository -SessionObject $session -Name $Repository
                if (-not $repo.TypeFields.IpRange) {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Could not obtain repository for $($session.URI)" -Continue
                } else {
                    $IPRange = $repo.TypeFields.IpRange
                }
            }

            $body = @{
                name        = $Name
                description = $Description
                type        = $Type
                definedIPs  = $IpRange
                groups      = $null
            }

            $params = @{
                SessionObject   = $session
                Path            = "/asset"
                Method          = "POST"
                Parameter       = $body
                EnableException = $EnableException
            }
            Invoke-TNRequest @params | ConvertFrom-TNRestResponse
        }
    }
}