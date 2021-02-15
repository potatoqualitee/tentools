<img align="left" src=https://user-images.githubusercontent.com/8278033/107939993-d9c88f80-6f87-11eb-892b-a7f090b1f619.png alt="tentools logo"> tentools is PowerShell module automates tenable.sc and Nessus. It is a rewrite of Tenable's [Posh-Nessus](https://github.com/tenable/Posh-Nessus), which was created by [Carlos Perez](https://www.trustedsec.com/team/carlos-perez/).

This toolset extends Posh-Nessus by adding more functionality, including the ability to work with tenable.sc / SecurityCenter.

## Key links for reference:

- [tentools wiki](https://github.com/potatoqualitee/tentools/wiki) for an overall view of tentools, things like purpose, roles and simplified deployment
- [ACAS overview](https://www.ask-ten.info/overview/) for discussion around contributing to the project
- [Tenable ACAS Blog](https://www.tenable.com/blog/tenable-selected-for-disa-s-ten-vulnerability-management-solution) for general discussion on the module and asking questions

## Installer

tentools works on PowerShell Core. This means that you can run all commands on <strong>Windows</strong>, <strong>Linux</strong> and <strong>macOS</strong>.

Run the following to install tentools from the PowerShell Gallery (to install on a server or for all users, remove the `-Scope` parameter and run in an elevated session):

```powershell
Install-Module tentools -Scope CurrentUser
```

If you need to install this module to an offline server, you can run

```powershell
Save-Module tentools -Path C:\temp
```
And it will save all dependent modules. You can also [download the zip](https://github.com/potatoqualitee/tentools/archive/master.zip) from our repo, but you'll also need to download [PSFramework](https://github.com/PowershellFrameworkCollective/psframework/archive/development.zip).

Please rename the folders from `name-master` to `name` and store in your `$Env:PSModulePath`.

## Usage scenarios

- Deploy standardized implementations
- Manage Nessus and tenable.sc at scale
- Manage some objects that are not available in the web interface

## Usage examples

<p align="center"><img align="center" src="https://user-images.githubusercontent.com/8278033/105730891-1d068400-5f2f-11eb-8ca1-1e12d8b58e7d.gif"></p>

Initalize a newly setup Nessus server with a license and username

```powershell
Initialize-TNServer -ComputerName securitycenter01 -Path $home\Downloads\nessus.license -Credential admin
```

Get a list of Organizations and Repositories using an Administrator account then create an Organization

```powershell
$admin = Get-Credential acasadmin
Connect-TNServer -ComputerName acas -Credential $admin
Get-TNOrganization
Get-TNRepository
New-TNOrganization -Name "Acme Corp"
```

Get a list of Scans using an Security Manager account

```powershell
$cred = Get-Credential secman
Connect-TNServer -ComputerName acas -Credential $cred
Get-TNScan
```

## Support

* PowerShell v5.1 and above
* Windows, macOS and Linux


# Simplified deployment

As described in the [wiki](https://github.com/potatoqualitee/tentools/wiki), you can deploy your entire environment in one simple command called `Start-TNDeploy`. This wrapper command accepts input from a JSON file with all of your configuration values, such as the one below.

```json
{
    "ComputerName": "securitycenter",
    "ServerType": "tenable.sc",
    "AdministratorCredential": "admin",
    "Scanner": "localhost",
    "ScannerCredential": "admin",
    "Repository": [
        "Vulnerabilities",
        "Audits"
    ],
    "Organization": "Acme",
    "SecurityManagerCredential": "secman",
    "IpRange": "192.168.100.0/24",
    "PolicyFilePath": "C:\\sc\\scan_policies",
    "AuditFilePath": "C:\\sc\\portal_audits\\Database\\DISA*MSSQL*",
    "DashboardFilePath": "C:\\sc\\dashboards",
    "AssetFilePath": "C:\\sc\\asset_lists",
    "ReportFilePath": "C:\\sc\\reports",
    "ScanZone": "All Computers",
    "ScanCredentialHash": [
        {
            "Credential": "ad\\nessus",
            "Name": "Windows Scanner Account",
            "Type": "windows",
            "AuthType": "password"
        },
        {
            "Credential": "acasaccount",
            "PrivilegeEscalation": "sudo",
            "Name": "Linux Scanner Account",
            "Type": "ssh",
            "AuthType": "password"
        },
        {
            "Credential": "sa",
            "Name": "SQL Server sqladmin account",
            "CredentialHash": {
                "SQLServerAuthType": "SQL",
                "dbType": "SQL Server"
            },
            "Type": "database",
            "AuthType": "password"
        }
    ]
}
```

To create a well-stocked deployment, just add that to a JSON file, then pipe that file to `Start-TNDeploy`.

```powershell
Get-Content C:\github\demo.json | ConvertFrom-Json | Start-TNDeploy
```

After entering all of the required passwords for your accounts (administrator, security manager, nessus scanner, scan credentials), sit back and let PowerShell take care of the rest as seen in the video below.

<div align="center">
  <a href="https://user-images.githubusercontent.com/8278033/105759670-fc4f2600-5f50-11eb-86fc-eea0242edc90.mp4"><img src="https://user-images.githubusercontent.com/8278033/105724894-a1093d80-5f28-11eb-8e5c-7a24deff6c82.png" alt="Start-TNDeploy demo" target="new"></a>
</div>

That last frame of that video was basically this result, which shows how the tenable.sc has been fully stocked:

```powershell
ServerUri         : securitycenter:443
AuditPolicy       : {DISA STIG MSSQL 2012 Database v1r20, DISA STIG MSSQL 2012 Instance-DB v1r20, DISA STIG MSSQL 2012 Instance-OS v1r20, DISA STIG MSSQL 2014 Database v1r6...}
ComputerName      : securitycenter
DISADetailedASR   : DISA ASR
ImportedAsset     : {BPG 5.4 - Bad, No Auth Attempted, BPG 5.4 - Bad, Error, - CMRS Daily Publishing, BPG 5.4 - Endpoint No Agent Differential Scan...}
ImportedAudit     : {DISA STIG MSSQL 2012 Database v1r20, DISA STIG MSSQL 2012 Instance-DB v1r20, DISA STIG MSSQL 2012 Instance-OS v1r20, DISA STIG MSSQL 2014 Database v1r6...}
ImportedDashboard : Acme Scan Summary
ImportedPolicy    : {Acme - Agent Differential Scan Policy (DRAFT), Acme - Agent Scan BPG, Acme - Configuration (STIG) Scan, Acme - Malware Scan...}
ImportedReport    : Test Import File
IpRange           : 192.168.100.0/24
Organization      : Acme
ReportAttribute   : DISA
Repository        : {Vulnerabilities, Audits}
ScanCredential    : {Windows Scanner Account, Linux Scanner Account, SQL Server sqladmin account}
Scanner           : localhost
ScannerCredential : admin
Scans             : {Acme - Agent Differential Scan Policy (DRAFT), Acme - Agent Scan BPG, Acme - Configuration (STIG) Scan, Acme - Malware Scan...}
ScanZone          : All Computers
SecurityManager   : secman
ServerType        : tenable.sc
Status            : Success
```

From here, you can run the necessary scans and export the reports for eMASS.

```powershell
# Run the STIG scan
Get-TNScan -Name 'DISA STIG MSSQL 2012 Database v1r20' | Start-TNScan -Wait
# Export the zip to upload to eMASS
Get-TNReport -Name 'DISA ASR' | Start-TNReport -Wait | Save-TNReportResult -Path C:\temp
```

## Command Support

Some commands are not supported on all platforms. Here is is legend to help.

| Command                              | Nessus | tenable.sc |
| ------------------------------------ | ------ | ---------- |
| Add-TNGroupUser                      | x      |            |
| Add-TNPluginRule                     | x      |            |
| Add-TNPolicyPortRange                | x      | x          |
| Add-TNScanner                        |        | x          |
| Connect-TNServer                     | x      | x          |
| ConvertFrom-TNRestResponse           | x      | x          |
| Copy-TNPolicy                        | x      | x          |
| Disable-TNPolicyLocalPortEnumeration | x      | x          |
| Disable-TNPolicyPortScanner          | x      | x          |
| Edit-TNPluginRule                    | x      | x          |
| Enable-TNPolicyLocalPortEnumeration  | x      | x          |
| Enable-TNPolicyPortScanner           | x      | x          |
| Export-TNPolicy                      | x      | x          |
| Export-TNScan                        | x      | x          |
| Get-TNAnalysis                       | x      | x          |
| Get-TNAsset                          |        | x          |
| Get-TNAudit                          |        | x          |
| Get-TNCredential                     |        | x          |
| Get-TNDashboard                      |        | x          |
| Get-TNFolder                         | x      |            |
| Get-TNGroup                          | x      | x          |
| Get-TNGroupMember                    | x      | x          |
| Get-TNLdapServer                     |        | x          |
| Get-TNOrganization                   |        | x          |
| Get-TNOrganizationUser               |        | x          |
| Get-TNPlugin                         | x      | x          |
| Get-TNPluginFamily                   | x      | x          |
| Get-TNPluginFamilyDetails            | x      | x          |
| Get-TNPluginRule                     | x      |            |
| Get-TNPolicy                         | x      | x          |
| Get-TNPolicyDetail                   | x      | x          |
| Get-TNPolicyLocalPortEnumeration     | x      |            |
| Get-TNPolicyPortRange                | x      | x          |
| Get-TNPolicyPortScanner              | x      | x          |
| Get-TNPolicyTemplate                 | x      | x          |
| Get-TNReport                         |        | x          |
| Get-TNReportAttribute                |        | x          |
| Get-TNReportResult                   |        | x          |
| Get-TNRepository                     |        | x          |
| Get-TNRole                           |        | x          |
| Get-TNScan                           | x      | x          |
| Get-TNScanDetail                     | x      | x          |
| Get-TNScanHistory                    | x      |            |
| Get-TNScanHost                       | x      | x          |
| Get-TNScanHostDetail                 | x      | x          |
| Get-TNScanner                        |        | x          |
| Get-TNScanResult                     |        | x          |
| Get-TNScanTemplate                   | x      |            |
| Get-TNScanZone                       |        | x          |
| Get-TNServerInfo                     | x      |            |
| Get-TNServerStatus                   | x      | x          |
| Get-TNSession                        | x      | x          |
| Get-TNSessionInfo                    | x      | x          |
| Get-TNSystemLog                      |        | x          |
| Get-TNUser                           | x      | x          |
| Import-TNAsset                       |        | x          |
| Import-TNAudit                       |        | x          |
| Import-TNCustomPlugin                |        | x          |
| Import-TNDashboard                   |        | x          |
| Import-TNPolicy                      |        | x          |
| Import-TNReport                      |        | x          |
| Import-TNScan                        | x      |            |
| Initialize-TNServer                  | x      | x          |
| Invoke-TNRequest                     | x      | x          |
| New-TNAsset                          |        | x          |
| New-TNCredential                     |        | x          |
| New-TNDisaAsrReport                  |        | x          |
| New-TNFolder                         | x      |            |
| New-TNGroup                          | x      | x          |
| New-TNLdapServer                     |        | x          |
| New-TNOrganization                   |        | x          |
| New-TNOrganizationUser               |        | x          |
| New-TNPolicy                         | x      | x          |
| New-TNReportAttribute                |        | x          |
| New-TNRepository                     |        | x          |
| New-TNScan                           | x      | x          |
| New-TNScanZone                       |        | x          |
| New-TNUser                           | x      | x          |
| Remove-TNAsset                       | x      | x          |
| Remove-TNAudit                       | x      | x          |
| Remove-TNCredential                  |        | x          |
| Remove-TNDashboard                   | x      | x          |
| Remove-TNFolder                      | x      | x          |
| Remove-TNGroup                       | x      | x          |
| Remove-TNGroupUser                   | x      | x          |
| Remove-TNOrganization                |        | x          |
| Remove-TNOrganizationUser            |        | x          |
| Remove-TNPluginRule                  | x      | x          |
| Remove-TNPolicy                      | x      | x          |
| Remove-TNReport                      | x      | x          |
| Remove-TNReportResult                | x      | x          |
| Remove-TNRepository                  |        | x          |
| Remove-TNScan                        | x      | x          |
| Remove-TNScanHistory                 | x      | x          |
| Remove-TNScanner                     |        | x          |
| Remove-TNScanZone                    | x      | x          |
| Remove-TNSession                     | x      | x          |
| Remove-TNUser                        | x      | x          |
| Rename-TNFolder                      | x      | x          |
| Rename-TNGroup                       | x      | x          |
| Restart-TNService                    | x      | x          |
| Resume-TNScan                        | x      | x          |
| Save-TNAudit                         | x      | x          |
| Save-TNPlugin                        | x      | x          |
| Save-TNReportResult                  |        | x          |
| Save-TNScanResult                    |        | x          |
| Save-TNScapFile                      | x      | x          |
| Set-TNCertificate                    | x      | x          |
| Set-TNPolicyPortRange                | x      | x          |
| Set-TNRepositoryProperty             |        | x          |
| Set-TNScanProperty                   |        | x          |
| Set-TNScanZoneProperty               |        | x          |
| Set-TNUserPassword                   | x      | x          |
| Start-TNDeploy                       | x      | x          |
| Start-TNReport                       |        | x          |
| Start-TNScan                         | x      | x          |
| Stop-TNScan                          | x      | x          |
| Suspend-TNScan                       | x      | x          |
| Test-TNAccessibility                 | x      | x          |
| Wait-TNServerReady                   | x      | x          |
