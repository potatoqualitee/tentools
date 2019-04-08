function Resolve-NetworkName {
    [CmdletBinding()]
    param(
        [string]$Computer
    )
    $cName = $Computer

    # resolve IP address
    try {
        Write-PSFMessage -Level Verbose -Mesage "Resolving $cName using .NET.Dns GetHostEntry"
        $resolved = [System.Net.Dns]::GetHostEntry($cName)
        $ipaddresses = $resolved.AddressList | Sort-Object -Property AddressFamily # prioritize IPv4
        $ipaddress = $ipaddresses[0].IPAddressToString
    } catch {
        $em = Get-ErrorMessage -Record $_
        Write-Warning $em
        return
    }

    # try to resolve IP into a hostname
    try {
        Write-PSFMessage -Level Verbose -Mesage "Resolving $ipaddress using .NET.Dns GetHostByAddress"
        $fqdn = [System.Net.Dns]::GetHostByAddress($ipaddress).HostName
    } catch {
        Write-PSFMessage -Level Verbose -Mesage "Failed to resolve $ipaddress using .NET.Dns GetHostByAddress"
        $fqdn = $resolved.HostName
    }

    $dnsDomain = $env:USERDNSDOMAIN
    # augment fqdn if needed
    if ($fqdn -notmatch "\." -and $dnsDomain) {
        $fqdn = "$fqdn.$dnsdomain"
    }
    $hostname = $fqdn.Split(".")[0]

    # create an output object with some preliminary data gathered so far
    [PSCustomObject]@{
        InputName        = $computer
        ComputerName     = $hostname.ToUpper()
        IPAddress        = $ipaddress
        DNSHostname      = $hostname
        DNSDomain        = $dnsdomain
        Domain           = $dnsdomain
        DNSHostEntry     = $fqdn
        FQDN             = $fqdn
        FullComputerName = $cName
    }
}