<img align="left" src=https://user-images.githubusercontent.com/8278033/55955866-d3b64900-5c62-11e9-8175-92a8427d7f94.png alt="tentools logo"> tentools is PowerShell module automates tenable.sc and Nessus. It is a rewrite of Tenable's [Posh-Nessus](https://github.com/tenable/Posh-Nessus), which was created by [Carlos Perez](https://www.trustedsec.com/team/carlos-perez/).

This toolset extends Posh-Nessus by adding more functionality, including the ability to work with tenable.sc / SecurityCenter.

## Key links for reference:

- [ACAS overview](https://www.ask-ten.info/overview/) for discussion around contributing to the project
- [Tenable ACAS Blog](https://www.tenable.com/blog/tenable-selected-for-disa-s-ten-vulnerability-management-solution) for general discussion on the module and asking questions

## Installer

tentools works on PowerShell Core. This means that you can run all commands on <strong>Windows</strong>, <strong>Linux</strong> and <strong>macOS </strong>.

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

* PowerShell v3 and above
* Windows, macOS and Linux

## Command Support

Some commands are not supported on all platforms. Here is is legend to help.

| Command | Nessus | tenable.sc
| --- | --- | --- |
| Add-TNGroupUser | x | |
| Add-TNPluginRule | x | |
| Add-TNPolicyPortRange | x | x |
| Add-TNScanner | | x |
| Connect-TNServer | x | x |
| ConvertFrom-TNRestResponse | x | x |
| Copy-TNPolicy | x | x |
| Disable-TNPolicyLocalPortEnumeration | x | x |
| Disable-TNPolicyPortScanner | x | x |
| Edit-TNPluginRule | x | x |
| Enable-TNPolicyLocalPortEnumeration | x | x |
| Enable-TNPolicyPortScanner | x | x |
| Export-TNPolicy | x | x |
| Export-TNScan | x | x |
| Get-TNAsset | | x |
| Get-TNAuditFile | | x |
| Get-TNCredential | | x |
| Get-TNFolder | x | |
| Get-TNGroup | x | x |
| Get-TNGroupMember | x | x |
| Get-TNLdapServer | | x |
| Get-TNOrganization | | x |
| Get-TNOrganizationUser | | x |
| Get-TNPlugin | x | x |
| Get-TNPluginFamily | x | x |
| Get-TNPluginFamilyDetails | x | x |
| Get-TNPluginRule | x | |
| Get-TNPolicy | x | x |
| Get-TNPolicyDetail | x | x |
| Get-TNPolicyLocalPortEnumeration | x | |
| Get-TNPolicyPortRange | x | x |
| Get-TNPolicyPortScanner | x | x |
| Get-TNPolicyTemplate | x | x |
| Get-TNReportAttribute | | x |
| Get-TNRepository | | x |
| Get-TNRole | | x |
| Get-TNScan | x | x |
| Get-TNScanDetail | x | x |
| Get-TNScanHistory | x | |
| Get-TNScanHost | x | x |
| Get-TNScanHostDetail | x | x |
| Get-TNScanner | | x |
| Get-TNScanResult | | x |
| Get-TNScanTemplate | x | |
| Get-TNScanZone | | x |
| Get-TNServerInfo | x | |
| Get-TNServerStatus | x | |
| Get-TNSession | x | x |
| Get-TNSessionInfo | x | x |
| Get-TNUser | x | x |
| Import-TNPolicy | | x |
| Import-TNScan | x | |
| Initialize-TNServer | x | x |
| Invoke-TNRequest | x | x |
| New-TNAsset | | x |
| New-TNCredential | | x |
| New-TNFolder | x | |
| New-TNGroup | x | x |
| New-TNLdapServer | | x |
| New-TNOrganization | | x |
| New-TNOrganizationUser | | x |
| New-TNPolicy | x | x |
| New-TNReportAttribute | | x |
| New-TNRepository | | x |
| New-TNScan | x | x |
| New-TNScanZone | | x |
| New-TNUser | x | x |
| Remove-TNFolder | x | x |
| Remove-TNGroup | x | x |
| Remove-TNGroupUser | x | x |
| Remove-TNOrganizationUser | | x |
| Remove-TNPluginRule | x | x |
| Remove-TNPolicy | x | x |
| Remove-TNScan | x | x |
| Remove-TNScanHistory | x | x |
| Remove-TNSession | x | x |
| Remove-TNUser | x | x |
| Rename-TNFolder | x | x |
| Rename-TNGroup | x | x |
| Restart-TNService | x | x |
| Resume-TNScan | x | x |
| Save-TNPlugin | x | x |
| Set-TNCertificate | x | x |
| Set-TNPolicyPortRange | x | x |
| Set-TNUserPassword | x | x |
| Start-TNDeploy | x | x |
| Start-TNScan | x | x |
| Stop-TNScan | x | x |
| Suspend-TNScan | x | x |
| Test-TNAccessibility | x | x |
| Wait-TNServerReady | x | x |




