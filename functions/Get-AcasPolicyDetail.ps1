function Get-AcasPolicyDetail {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER PolicyId
        Parameter description

    .PARAMETER Name
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-AcasPolicyDetail
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [int32[]]$PolicyId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            if ($PSBoundParameters.Name) {
                $policy = Get-AcasPolicy -Name $Name -SessionId $session.SessionId
                if ($policy) {
                    $PolicyId = $policy.PolicyId
                }
                else {
                    Stop-PSFFunction -Message "Policy with name $($Name) was not found on $($session.Uri)" -Continue
                }
            }
            if (-not $PSBoundParameters.PolicyId -and -not $PSBoundParameters.Name) {
                $PolicyId = (Get-AcasPolicy).PolicyId
            }
            foreach ($id in $PolicyId) {
                Write-PSFMessage -Level Verbose -Message "Getting details for policy with id $($id)"
                Invoke-AcasRequest -SessionObject $session -Path "/policies/$id" -Method 'GET'
            }
        }
    }
}