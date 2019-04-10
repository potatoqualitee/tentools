function Get-AcasPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER Name
        Parameter description

    .PARAMETER PolicyID
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByID')]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByID')]
        [string]$PolicyID,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
            $policies = Invoke-AcasRequest -SessionObject $session -Path '/policies' -Method 'Get'

            if ($policies -is [psobject]) {
                switch ($PSCmdlet.ParameterSetName) {
                    'ByName' {
                        $collection = $policies.policies | Where-Object { $_.name -eq $Name }
                    }

                    'ByID' {
                        $collection = $policies.policies | Where-Object { $_.id -eq $PolicyID }
                    }

                    'All' {
                        $collection = $policies.policies
                    }
                }

                foreach ($Policy in $collection) {
                    [pscustomobject]@{
                        Name           = $Policy.Name
                        PolicyId       = $Policy.id
                        Description    = $Policy.description
                        PolicyUUID     = $Policy.template_uuid
                        Visibility     = $Policy.visibility
                        Shared         = (if ($Policy.shared -eq 1) { $true } else { $false })
                        Owner          = $Policy.owner
                        UserId         = $Policy.owner_id
                        NoTarget       = $Policy.no_target
                        UserPermission = $Policy.user_permissions
                        Modified       = $origin.AddSeconds($Policy.last_modification_date).ToLocalTime()
                        Created        = $origin.AddSeconds($Policy.creation_date).ToLocalTime()
                        SessionId      = $session.SessionId
                    }
                }
            }
        }
    }
}