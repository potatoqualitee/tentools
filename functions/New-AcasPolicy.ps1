function New-AcasPolicy {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER SessionId
    Parameter description

    .PARAMETER Name
    Name for new policy

    .PARAMETER PolicyUUID
    Policy Template UUID to base new policy from.

    .PARAMETER TemplateName
    Policy Template name to base new policy from.

    .PARAMETER Description
    Description for new policy.

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [Alias('Index')]
        [int32[]]$SessionId = $Global:NessusConn.SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [string]$Name,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUUID')]
        [string]$PolicyUUID,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$TemplateName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [string]$Description = ''
    )

    begin
    {
        $ToProcess = @()

        foreach($i in $SessionId)
        {
            $Connections = $Global:NessusConn

            foreach($Connection in $Connections)
            {
                if ($Connection.SessionId -eq $i)
                {
                    $ToProcess += $Connection
                }
            }
        }
    }
    process
    {
        foreach($Connection in $ToProcess)
        {
            switch ($PSCmdlet.ParameterSetName)
            {
                'ByName'
                {
                    $tmpl = Get-AcasPolicyTemplate -Name $TemplateName -SessionId $Connection.SessionId
                    if ($tmpl -ne $null)
                    {
                        $PolicyUUID = $tmpl.PolicyUUID
                    }
                    else
                    {
                        throw "Template with name $($TemplateName) was not found."
                    }
                }
                'ByUUID'
                {
                    $Templates2Proc = $Templates.templates | Where-Object {$_.uuid -eq $PolicyUUID}
                }
            }
            $RequestSet = @{'uuid' = $PolicyUUID;
                'settings' = @{
                    'name' = $Name
                    'description' = $Description}
            }

            $SettingsJson = ConvertTo-Json -InputObject $RequestSet -Compress
            $RequestParams = @{
                'SessionObject' = $Connection
                'Path' = "/policies/"
                'Method' = 'POST'
                'ContentType' = 'application/json'
                'Parameter'= $SettingsJson
            }
            $NewPolicy = InvokeNessusRestRequest @RequestParams
            Get-AcasPolicy -PolicyID $NewPolicy.policy_id -SessionId $Connection.sessionid
        }
    }
}