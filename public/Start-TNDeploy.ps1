function Start-TNDeploy {
<#
    .SYNOPSIS
        Starts a list of deploys

    .DESCRIPTION
        Starts a list of deploys
        
    .PARAMETER ComputerName
        The network name or IP address of the Nessus or tenable.sc server
        
    .PARAMETER Port
        The port of the Nessus or tenable.sc server. Defaults to 8834 which is the default port for Nessus.
        
    .PARAMETER Credential
        The credential object (from Get-Credential) used to log into the target server. Specifies a user account that has permission to send the request. 
        
    .PARAMETER LicensePath
        Description for LicensePath
        
    .PARAMETER AcceptSelfSignedCert
        Accept self-signed certs
        
    .PARAMETER Type
        The type of deploy
        
    .PARAMETER SecurityManagerCredential
        Description for SecurityManagerCredential
        
    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with 'sea of red' exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this 'nice by default' feature off and enables you to catch exceptions with your own try/catch.
        
    .EXAMPLE
        PS C:\> Start-TNDeploy

        Starts a list of deploys
        
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        [int]$Port,
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory)]
        [string]$LicensePath,
        [switch]$AcceptSelfSignedCert,
        [ValidateSet("tenable.sc", "Nessus")]
        [string]$Type,
        [Parameter(Mandatory)]
        [Management.Automation.PSCredential]$SecurityManagerCredential,
        [switch]$EnableException
    )
    begin {
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $started = Get-Date
    }
    process {
        foreach ($computer in $ComputerName) {
            <#
            Initialize with admin account and license
            Create Organization
            Create LDAP https://securitycenter/#ldap_servers/edit/1
            Create Repository with IP subnets, assign to Organization
            Create Organization User / TNS or LDAP
            Create Secman user, -Role and assign to Organization, Auto timezone?
            Create Credential as Admin cuz it's inherited to Org logins
            Create Asset(s) based on Repo
            Import Policy
            Add Nessus Scanner
            Create Scan based on policy
            Start Scan
            Get Scan output while waiting
            Import Reports
            Import dashboard
            Import asset lists
            Import nessus scan policy and xml scan
            #>

            $stepCounter++
            Write-PSFMessage -Level Verbose -Message "Initializing $computer"
            Write-ProgressHelper -StepNumber ($stepCounter++) -Message "Initializing $computer"
            $splat = @{
                ComputerName    = $computer
                Credential      = $Credential
                EnableException = $EnableException
                LicensePath     = $LicensePath
            }
            Initialize-TNServer @splat

            Write-Progress -Activity "Performing Instance Export for $instance" -Completed
        }
    }
    end {
        $totalTime = ($elapsed.Elapsed.toString().Split(".")[0])
        Write-PSFMessage -Level Verbose -Message "Export started: $started"
        Write-PSFMessage -Level Verbose -Message "Export completed: $(Get-Date)"
        Write-PSFMessage -Level Verbose -Message "Total Elapsed time: $totalTime"
    }
}