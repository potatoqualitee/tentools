function New-TNPolicy {
    <#
    .SYNOPSIS
        Creates new policies

    .DESCRIPTION
        Creates new policies

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER Name
        The name of the target policy

    .PARAMETER PolicyUUID
        The UUID of the target policy

    .PARAMETER TemplateName
        Description for TemplateName

    .PARAMETER Description
        Description for Description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> New-TNPolicy

        Creates new policies

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$PolicyUUID,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$TemplateName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description = '',
        [switch]$EnableException
    )
    process {
        if (-not $PSBoundParameters.TemplateName -and -not $PSBoundParameters.PolicyUUID) {
            Stop-PSFFunction -EnableException:$EnableException -Message "Please specify either TemplateName or PolicyUUID"
            return
        }

        foreach ($session in $SessionObject) {
            if ($PSBoundParameters.TemplateName) {
                $PolicyUUID = (Get-TNPolicyTemplate -Name $TemplateName).PolicyUUID
            }

            foreach ($policyid in $PolicyUUID) {
                $req = @{
                    uuid     = $policyid
                    settings = @{
                        'name'        = $Name
                        'description' = $Description
                    }
                }

                $SettingsJson = ConvertTo-Json -InputObject $req -Compress
                $params = @{
                    SessionObject = $session
                    Path          = "/policies/"
                    Method        = 'POST'
                    ContentType   = "application/json"
                    Parameter     = $SettingsJson
                }
                $newpolicy = Invoke-TNRequest @params
                Get-TNPolicy -PolicyID $newpolicy.policy_id
            }
        }
    }
}