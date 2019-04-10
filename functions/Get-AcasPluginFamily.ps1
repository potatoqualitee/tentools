function Get-AcasPluginFamily {
    <#
    .SYNOPSIS
        Short description

    .DESCRIPTION
        Long description

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-AcasService.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Get-Acas
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32[]]$SessionId = $global:NessusConn.SessionId,
        [switch]$EnableException
    )
    process {
        $collection = @()

        foreach ($id in $SessionId) {
            $connections = $global:NessusConn

            foreach ($connection in $connections) {
                if ($connection.SessionId -eq $id) {
                    $collection += $session
                }
            }
        }

        foreach ($session in (Get-AcasSession -SessionId $SessionId)) {
            $Families = Invoke-AcasRequest -SessionObject $session -Path '/plugins/families' -Method 'Get'
            if ($Families -is [Object[]]) {
                foreach ($Family in $Families) {
                    $FamilyProps = [ordered]@{ }
                    $FamilyProps.add('Name', $Family.name)
                    $FamilyProps.add('Id', $Family.id)
                    $FamilyProps.add('Count', $Family.count)
                    $FamilyObj = New-Object -TypeName psobject -Property $FamilyProps
                    $FamilyObj.pstypenames[0] = 'Nessus.PluginFamily'
                    $FamilyObj

                }
            }
        }
    }
    end {
    }
}