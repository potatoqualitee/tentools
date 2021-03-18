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
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(Mandatory, ParameterSetName = "Template", ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$PolicyUUID,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$TemplateName,
        [string[]]$Audit,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,
        [Parameter(Mandatory, ParameterSetName = "Auto", ValueFromPipelineByPropertyName)]
        [switch]$Auto,
        [switch]$EnableException
    )
    process {
        if (-not $PSBoundParameters.TemplateName -and -not $PSBoundParameters.PolicyUUID -and -not $Auto) {
            Stop-PSFFunction -EnableException:$EnableException -Message "Please specify either TemplateName or PolicyUUID"
            return
        }

        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if ($PSBoundParameters.Auto) {
                $audits = Get-TNAudit
                $template = Get-TNPolicyTemplate -Name 'SCAP and OVAL Auditing'

                foreach ($auditfile in $audits) {
                    $preparams = @{
                        name           = $auditfile.Name
                        description    = $auditfile.Description
                        policyTemplate = @{ id = $template.id }
                        # brett worked!
                        auditFiles     = @(@{ id = $auditfile.id })
                    }

                    $json = ConvertTo-Json -InputObject $preparams -Compress
                    $params = @{
                        SessionObject = $session
                        Path          = "/policy"
                        Method        = "POST"
                        ContentType   = "application/json"
                        Parameter     = $json
                    }
                    $newpolicy = Invoke-TNRequest @params
                    Get-TNPolicy -PolicyID $newpolicy.Id
                }
            } else {
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
                    $json = ConvertTo-Json -InputObject $req -Compress
                    $params = @{
                        SessionObject = $session
                        Path          = "/policies/"
                        Method        = "POST"
                        ContentType   = "application/json"
                        Parameter     = $json
                    }
                    $newpolicy = Invoke-TNRequest @params
                    Get-TNPolicy -PolicyID $newpolicy.Id
                }
            }
        }
    }
}