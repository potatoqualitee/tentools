function Get-TNPolicyDetail {
<#
    .SYNOPSIS
        Gets a list of policy details

    .DESCRIPTION
        Gets a list of policy details

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER PolicyId
        The ID of the target policy

    .PARAMETER Name
        The name of the target policy detail

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNPolicyDetail

        Gets a list of policy details

#>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [int32[]]$PolicyId,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            $PSDefaultParameterValues["*:SessionObject"] = $session
            if ($PSBoundParameters.Name) {
                $policy = Get-TNPolicy -Name $Name
                if ($policy) {
                    $PolicyId = $policy.PolicyId
                } else {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Policy with name $($Name) was not found on $($session.Uri)" -Continue
                }
            }
            if (-not $PSBoundParameters.PolicyId -and -not $PSBoundParameters.Name) {
                $PolicyId = (Get-TNPolicy).Id
            }
            foreach ($id in $PolicyId) {
                $script:includeid = $id
                Write-PSFMessage -Level Verbose -Message "Getting details for policy with id $id"
                Invoke-TNRequest -SessionObject $session -EnableException:$EnableException -Path "/editor/policy/$id" -Method GET |
                    ConvertFrom-TNRestResponse
            }
        }
    }
    end {
        $script:includeid = $null
    }
}