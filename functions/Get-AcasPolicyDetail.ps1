function Get-AcasPolicyDetail {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        Parameter description

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

    begin {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $connection
                }
            }
        }
    }
    process {
        foreach ($connection in $collection) {
            switch ($PSCmdlet.ParameterSetName) {
                'ByName' {
                    $Pol = Get-AcasPolicy -Name $Name -SessionId $connection.SessionId
                    if ($Pol -ne $null) {
                        $PolicyId = $Pol.PolicyId
                    }
                    else {
                        throw "Policy with name $($Name) was not found."
                    }
                }

            }
            Write-PSFMessage -Level Verbose -Mesage "Getting details for policy with id $($PolicyId)."
            $Policy = Invoke-AcasRequest -SessionObject $connection -Path "/policies/$($PolicyId)" -Method 'GET'
            $Policy
        }
    }
}