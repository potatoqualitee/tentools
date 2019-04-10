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
        PS> Get-Acas
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByID')]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByID')]
        [int32]$PolicyId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            switch ($PSCmdlet.ParameterSetName) {
                'ByName' {
                    $policy = Get-AcasPolicy -Name $Name -SessionId $session.SessionId
                    if ($policy) {
                        $PolicyId = $policy.PolicyId
                    }
                    else {
                        Stop-Function -Message "Policy with name $($Name) was not found." -Continue
                    }
                }
            }
            Write-PSFMessage -Level Verbose -Mesage "Getting details for policy with id $($PolicyId)."
            Invoke-AcasRequest -SessionObject $session -Path "/policies/$($PolicyId)" -Method 'GET'
        }
    }
}