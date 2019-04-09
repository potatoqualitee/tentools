function Get-AcasPolicy {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Name
    Parameter description

    .PARAMETER PolicyID
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByID')]
        [Alias('Index')]
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByID')]
        [string]$PolicyID
    )

    begin {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $ToProcess = @()

        foreach ($i in $SessionId) {
            $connections = $Global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $i) {
                    $ToProcess += $connection
                }
            }
        }
    }
    process {
        foreach ($connection in $ToProcess) {
            $Policies = InvokeNessusRestRequest -SessionObject $connection -Path '/policies' -Method 'Get'

            if ($Policies -is [psobject]) {
                switch ($PSCmdlet.ParameterSetName) {
                    'ByName' {
                        $Policies2Proc = $Policies.policies | Where-Object {$_.name -eq $Name}
                    }

                    'ByID' {
                        $Policies2Proc = $Policies.policies | Where-Object {$_.id -eq $PolicyID}
                    }

                    'All' {
                        $Policies2Proc = $Policies.policies
                    }
                }

                foreach ($Policy in $Policies2Proc) {
                    $PolProps = [ordered]@{}
                    $PolProps.Add('Name', $Policy.Name)
                    $PolProps.Add('PolicyId', $Policy.id)
                    $PolProps.Add('Description', $Policy.description)
                    $PolProps.Add('PolicyUUID', $Policy.template_uuid)
                    $PolProps.Add('Visibility', $Policy.visibility)
                    $PolProps['Shared'] = & { if ($Policy.shared -eq 1) {$True}else {$False}}
                    $PolProps.Add('Owner', $Policy.owner)
                    $PolProps.Add('UserId', $Policy.owner_id)
                    $PolProps.Add('NoTarget', $Policy.no_target)
                    $PolProps.Add('UserPermission', $Policy.user_permissions)
                    $PolProps.Add('Modified', $origin.AddSeconds($Policy.last_modification_date).ToLocalTime())
                    $PolProps.Add('Created', $origin.AddSeconds($Policy.creation_date).ToLocalTime())
                    $PolProps.Add('SessionId', $connection.SessionId)
                    $PolObj = [PSCustomObject]$PolProps
                    $PolObj.pstypenames.insert(0, 'Nessus.Policy')
                    $PolObj
                }
            }
        }
    }
}