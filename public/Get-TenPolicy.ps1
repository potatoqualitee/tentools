function Get-TenPolicy {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER Name
        Parameter description

    .PARAMETER PolicyID
        Parameter description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Ten
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByID')]
        [Alias('Index')]
        [int32[]]$SessionId = $script:NessusConn.SessionId,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string]$Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByID')]
        [string]$PolicyID,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {
            $policies = Invoke-TenRequest -SessionObject $session -Path '/policies' -Method 'Get'

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

                foreach ($policy in $collection) {
                    [pscustomobject]@{
                        Name           = $policy.Name
                        PolicyId       = $policy.id
                        Description    = $policy.description
                        PolicyUUID     = $policy.template_uuid
                        Visibility     = $policy.visibility
                        Shared         = $(if ($policy.shared -eq 1) { $true } else { $false })
                        Owner          = $policy.owner
                        UserId         = $policy.owner_id
                        NoTarget       = $policy.no_target
                        UserPermission = $policy.user_permissions
                        Modified       = $origin.AddSeconds($policy.last_modification_date).ToLocalTime()
                        Created        = $origin.AddSeconds($policy.creation_date).ToLocalTime()
                        SessionId      = $session.SessionId
                    }
                }
            }
        }
    }
}