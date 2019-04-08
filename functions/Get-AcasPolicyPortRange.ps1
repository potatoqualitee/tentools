function Get-AcasPolicyPortRange {
##
    [CmdletBinding()]
    [OutputType([int])]
    param
    (
        # Nessus session Id
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('Index')]
        [int32]
        $SessionId,

        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipelineByPropertyName=$true)]
        [int32[]]
        $PolicyId
    )

    begin
    {
        $sessions = Get-AcasSession | Select-Object -ExpandProperty sessionid
        if ($SessionId -notin $sessions)
        {
            throw "SessionId $($SessionId) is not present in the current sessions."
        }
        $Session = Get-AcasSession -SessionId $SessionId
    }
    process
    {
        foreach ($PolicyToChange in $PolicyId)
        {
            try
            {
                $Policy = Get-AcasPolicyDetail -SessionId $Session.SessionId -PolicyId $PolicyToChange
                $UpdateProps = [ordered]@{
                    'PolicyId' = $PolicyToChange
                    'PortRange' = $Policy.settings.portscan_range
                }
                $PolSettingsObj = [PSCustomObject]$UpdateProps
                $PolSettingsObj.pstypenames.insert(0,'Nessus.PolicySetting')
                $PolSettingsObj
            }
            catch
            {
                throw $_
            }

        }
    }
    end
    {
    }
}