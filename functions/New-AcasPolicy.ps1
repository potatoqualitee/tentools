function New-AcasPolicy {
<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER SessionId
Parameter description

.PARAMETER Name
Parameter description

.PARAMETER PolicyUUID
Parameter description

.PARAMETER TemplateName
Parameter description

.PARAMETER Description
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param
    (
        # Nessus session Id.
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [Alias('Index')]
        [int32[]]
        $SessionId,

        # Name for new policy.
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [string]
        $Name,

        # Policy Template UUID to base new policy from.
        [Parameter(Mandatory = $true,
                   Position = 2,
                   ValueFromPipelineByPropertyName = $true,
                   ParameterSetName = 'ByUUID')]
        [string]
        $PolicyUUID,

        # Policy Template name to base new policy from.
        [Parameter(Mandatory = $true,
                   Position = 2,
                   ValueFromPipelineByPropertyName = $true,
                   ParameterSetName = 'ByName')]
        [string]
        $TemplateName,

        # Description for new policy.
        [Parameter(Mandatory = $false,
                   ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [string]
        $Description = ''
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
    end
    {
    }
}