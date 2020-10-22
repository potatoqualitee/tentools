function Get-TenGroupMember {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER GroupId
        Parameter description

    .EXAMPLE
        PS> Get-Ten

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$GroupId,
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession)) {
            if ($session.MultiUser) {
                $groupparams = @{
                    SessionObject = $session
                    Path          = "/groups/$GroupId/users"
                    Method        = 'GET'
                }

                (Invoke-TenRequest @groupparams).users | ConvertFrom-TenRestResponse
            } else {
                Write-PSFMessage -Level Warning -Message "Server ($($session.ComputerName)) for session $($session.sessionid) is not licenced for multiple users"
            }
        }
    }
}