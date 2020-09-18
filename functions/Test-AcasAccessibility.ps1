function Test-AcasAccessibility {
    <#
	.SYNOPSIS
	    Tests the Credentialing and Accessibility of ACAS.

	.DESCRIPTION
        Tests the Credentialing and Accessibility of ACAS.

        This command automates the checklist found at:
        https://docs.tenable.com/nessus/Content/EnableWindowsLoginsForLocalAndRemoteAudits.htm


        This includes:
        *1) The Windows Management Instrumentation (WMI) service must be enabled on the target.  (https://technet.microsoft.com/en-us/library/cc180684.aspx)
        *2) The Remote Registry service must be enabled on the target.
        *3) File & Printer Sharing must be enabled in the target's network configuration.
        4) An SMB account must be used that has local administrator rights on the target.  (You can use a domain account, but that account must be a local administrator on the devices being scanned.)
        *5) Ports 139 (TCP) and 445 (TCP) must be open between the Nessus scanner and the target.
        6) Ensure that no Windows security policies are in place that block access to these services. See below for more information.
        7) The default administrative shares (i.e. IPC$, ADMIN$, C$) must be enabled (AutoShareServer = 1). These are enabled by default and can cause other issues if disabled (http://support.microsoft.com/kb/842715/en-us).
        RemoteRegistry

	.PARAMETER ComputerName
	    The network name or names of the target computers. Using an IP address will be slower and potentially less accurate.

	.PARAMETER ServiceAccount
	    The ACAS Service account.

	.PARAMETER Credential
        Optional parameter to run the script checker as an alternative user.
        Useful if running as the ACAS service account is desired

	.EXAMPLE
        PS> Test-AcasAccessibility -ComputerName WS101

        Remotely connects to computer WS101 and performs tests. Assumes svc.acas.* is the service account

	.EXAMPLE
        PS> Test-AcasAccessibility -ComputerName WS101 -Credential ad\acaschecker -ServiceAccount acas2

        Remotely connects to computer WS101 as ad\acaschecker and performs tests. Checks to see if an account matching acas2 is a local admin.
	#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String[]]$ComputerName,
        [String]$ServiceAccount = $env:USERNAME,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        $scriptblock = {
            function Get-ErrorMessage {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory, ValueFromPipeline)]
                    [System.Management.Automation.ErrorRecord]$Record
                )
                process {
                    $innermessage = $Record.Exception.InnerException.InnerException.InnerException.InnerException.InnerException.Message
                    if (-not $innermessage) { $innermessage = $Record.Exception.InnerException.InnerException.InnerException.InnerException.Message }
                    if (-not $innermessage) { $innermessage = $Record.Exception.InnerException.InnerException.InnerException.Message }
                    if (-not $innermessage) { $innermessage = $Record.Exception.InnerException.InnerException.Message }
                    if (-not $innermessage) { $innermessage = $Record.Exception.InnerException.Message }
                    if (-not $innermessage) { $innermessage = $Record.Exception.Message }
                    return $innermessage
                }

            }
            if ($PSBoundParameters.Credential) {
                $executedasuser = $Credential.UserName
            }
            else {
                $executedasuser = "$env:USERDOMAIN\$env:USERNAME"
            }

            $ServiceAccount = $args
            if ((Invoke-Command -ScriptBlock { net.exe localgroup administrators } | Out-String | Where-Object { $psitem -match "$ServiceAccount" })) {
                $isadmin = $true
            }
            else {
                $isadmin = $false
            }
            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = "$ServiceAccount is local administrator"
                Value          = $isadmin
                Errors         = "None"
                Compliant      = $isadmin
            }

            try {
                $WMIService = Get-Service -Name Winmgmt -ErrorAction Stop
                $stoperror = "None"
            }
            catch {
                $stoperror = Get-ErrorMessage -Record $_
            }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'WMI Service Startup'
                Value          = $WMIService.StartType
                Errors         = $stoperror
                Compliant      = $WMIService.StartType -eq 'Automatic'
            }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'WMI Service Status'
                Value          = $WMIService.Status
                Errors         = $stoperror
                Compliant      = $WMIService.Status -eq 'Running'
            }

            try {
                $RemoteRegService = Get-Service -Name RemoteRegistry -ErrorAction Stop
                $stoperror = "None"
            }
            catch {
                $stoperror = Get-ErrorMessage -Record $_
            }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'Remote Registry Startup'
                Value          = $RemoteRegService.StartType
                Errors         = $stoperror
                Compliant      = $RemoteRegService.StartType -eq 'Automatic'
            }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'Remote Registry Status'
                Value          = $RemoteRegService.Status
                Errors         = $stoperror
                Compliant      = $RemoteRegService.Status -eq 'Running'
            }

            try {
                # shhh, we decided on WmiObject over CimInstance because it is more reliable
                $share = Get-WmiObject -Class Win32_Share -ErrorAction Stop
                $stoperror = "None"
            }
            catch {
                $stoperror = Get-ErrorMessage -Record $_
            }

            $RemoteAdmin = $share | Where-Object Description -eq "Remote Admin"
            $RemoteIPC = $share | Where-Object Description -eq "Remote IPC"
            $DefaultShareC = $share | Where-Object { $_.Description -eq "Default Share" -and $_.Name -like "C*" }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'Remote Admin Share Exists'
                Value          = (-not (-not $RemoteAdmin)) # LOL
                Errors         = $stoperror
                Compliant      = (-not (-not $RemoteAdmin)) -eq $true
            }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'Remote IPC Exists'
                Value          = (-not (-not $RemoteIPC))
                Errors         = $stoperror
                Compliant      = (-not (-not $RemoteIPC)) -eq $true
            }

            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME.ToUpper()
                ExecutedAsUser = $executedasuser
                Name           = 'Default Share C$ Exists'
                Value          = (-not (-not $DefaultShareC))
                Errors         = $stoperror
                Compliant      = (-not (-not $DefaultShareC)) -eq $true
            }
        }
        if ($PSBoundParameters.Credential) {
            $executedasuser = $Credential.UserName
        }
        else {
            $executedasuser = "$env:USERDOMAIN\$env:USERNAME"
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $stepCounter = 0
            if ($Computer -as [ipaddress]) {
                Write-Message -Level Warning -Message "An IP address was specified instead of a hostname. Attempting to resolve hostname, this may be less accurate"
                $resolved = (Resolve-NetworkName -Computer $Computer -ErrorAction Ignore).ComputerName

                if ($resolved -as [ipaddress]) {
                    Stop-PSFFunction -Message "Unable to resolve $computer to a hostname. Please use the network name instead. You can potentially find the network name by using ping -a $computer" -Continue
                }
                else {
                    $Computer = $resolved
                }
            }

            $splat = @{
                ComputerName = $Computer
                Credential   = $Credential
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Connecting to $Computer and performing tests"
            Invoke-Command2 @splat -ScriptBlock $scriptblock -ArgumentList $ServiceAccount | Select-Object -Property ComputerName, ExecutedAsUser, Name, Value, Errors, Compliant

            try {
                $Port139 = Test-NetConnection -ComputerName $computer -Port 139 -ErrorAction Stop
                $stoperror = "None"
            }
            catch {
                $stoperror = Get-ErrorMessage -Record $_
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Testing port 139 on $Computer"
            [PSCustomObject]@{
                ComputerName   = $Computer.ToUpper()
                ExecutedAsUser = "$env:USERDOMAIN\$env:USERNAME"
                Name           = 'Port 139 Accessible'
                Value          = $Port139.TcpTestSucceeded
                Errors         = $stoperror
                Compliant      = $Port139.TcpTestSucceeded -eq $true
            }

            try {
                $Port445 = Test-NetConnection -ComputerName $computer -Port 445 -ErrorAction Stop
                $stoperror = "None"
            }
            catch {
                $stoperror = Get-ErrorMessage -Record $_
            }

            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Testing port 445 on $Computer"
            [PSCustomObject]@{
                ComputerName   = $Computer.ToUpper()
                ExecutedAsUser = "$env:USERDOMAIN\$env:USERNAME"
                Name           = 'Port 445 Accessible'
                Value          = $Port445.TcpTestSucceeded
                Errors         = $stoperror
                Compliant      = $Port445.TcpTestSucceeded -eq $true
            }
        }
    }
}