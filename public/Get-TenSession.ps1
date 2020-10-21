function Get-TenSession {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Ten
    #>
    [CmdletBinding()]
    param(
        [switch]$EnableException
    )
    begin {
        if (Test-PSFParameterBinding -Parameter SessionId) {
            if ($null -eq $SessionId) {
                Write-PSFMessage -Level Warning -Message "No session specified. Have you connected using Connect-TenServer during this session?"
            }
        }
    }
    process {
        Write-PSFMessage -level Verbose -Message "Connected sessions: $($script:NessusConn.Count)"
        if ($PSBoundParameters.SessionId) {
            $script:NessusConn | Where-Object SessionId -in $SessionId
        } else {
            $script:NessusConn
        }
    }
}