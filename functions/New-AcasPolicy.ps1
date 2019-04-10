function New-AcasPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER Name
        Name for new policy

    .PARAMETER PolicyUUID
        Policy Template UUID to base new policy from.

    .PARAMETER TemplateName
        Policy Template name to base new policy from.

    .PARAMETER Description
        Description for new policy.

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
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByUUID')]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
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
        [string]$Description = '',
        [switch]$EnableException
    )

    begin {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }
    }
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            switch ($PSCmdlet.ParameterSetName) {
                'ByName' {
                    $tmpl = Get-AcasPolicyTemplate -Name $TemplateName -SessionId $session.SessionId
                    if ($tmpl -ne $null) {
                        $PolicyUUID = $tmpl.PolicyUUID
                    }
                    else {
                        throw "Template with name $($TemplateName) was not found."
                    }
                }
                'ByUUID' {
                    $Templates2Proc = $Templates.templates | Where-Object { $_.uuid -eq $PolicyUUID }
                }
            }
            $RequestSet = @{'uuid' = $PolicyUUID;
                'settings'         = @{
                    'name'        = $Name
                    'description' = $Description
                }
            }

            $SettingsJson = ConvertTo-Json -InputObject $RequestSet -Compress
            $params = @{
                SessionObject = $session
                Path          = "/policies/"
                Method        = 'POST'
                'ContentType'   = 'application/json'
                'Parameter'     = $SettingsJson
            }
            $NewPolicy = Invoke-AcasRequest @params
            Get-AcasPolicy -PolicyID $NewPolicy.policy_id -SessionId $session.sessionid
        }
    }
}