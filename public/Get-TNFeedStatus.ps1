function Get-TNFeedStatus {
    <#
    .SYNOPSIS
        Gets a list of feed status

    .DESCRIPTION
        Gets a list of feed status

    .PARAMETER SessionObject
        Optional parameter to force using specific SessionObjects. By default, each command will connect to all connected servers that have been connected to using Connect-TNServer

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS C:\> Get-TNFeedStatus

        Gets a list of feed status

#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$SessionObject = (Get-TNSession),
        [switch]$EnableException
    )
    process {
        foreach ($session in $SessionObject) {
            if (-not $session.sc) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Only tenable.sc supported" -Continue
            }

            $params = @{
                Path            = "/feed"
                Method          = "GET"
                EnableException = $EnableException
            }
            $results = Invoke-TNRequest @params | ConvertFrom-TNRestResponse -ExcludeEmptyResult
            [pscustomobject]@{
                ServerUri                        = $results.ServerUri
                SecurityCenterStale              = $results.Sc.stale -eq $true
                SecurityCenterUpdateTime         = $results.Sc.updateTime
                SecurityCenterUpdateRunning      = $results.Sc.updateRunning -eq $true
                SecurityCenterSubscriptionStatus = $results.Sc.subscriptionStatus
                ActivePluginsStale               = $results.Active.stale -eq $true
                ActivePluginsUpdateTime          = $results.Active.updateTime
                ActivePluginsUpdateRunning       = $results.Active.updateRunning -eq $true
                ActivePluginsSubscriptionStatus  = $results.Active.subscriptionStatus
                PassivePluginsStale              = $results.Passive.stale -eq $true
                PassivePluginsUpdateTime         = $results.Passive.updateTime
                PassivePluginsUpdateRunning      = $results.Passive.updateRunning -eq $true
                PassivePluginsSubscriptionStatus = $results.Passive.subscriptionStatus
                IndustrialStale                  = $results.Industrial.stale -eq $true
                IndustrialUpdateTime             = $results.Industrial.updateTime
                IndustrialUpdateRunning          = $results.Industrial.updateRunning -eq $true
                IndustrialSubscriptionStatus     = $results.Industrial.subscriptionStatus
                LceStale                         = $results.Industrial.stale -eq $true
                LceUpdateTime                    = $results.Industrial.updateTime
                LceRunning                       = $results.Industrial.updateRunning -eq $true
                LceSubscriptionStatus            = $results.Industrial.subscriptionStatus
            }
        }
    }
}