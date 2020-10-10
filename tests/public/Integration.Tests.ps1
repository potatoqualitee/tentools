Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    Context "Connect-TenServer" {
        It "Connects to a site" {
            $cred = New-Object -TypeName PSCredential -ArgumentList "admin", (ConvertTo-SecureString -String admin123 -AsPlainText -Force)
            $splat = @{
                ComputerName         = "localhost"
                AcceptSelfSignedCert = $true
                Credential           = $cred
                EnableException      = $true
                Port                 = 8834
            }
            (Connect-TenServer @splat).ComputerName | Should -Be "localhost"
            # Nessus has restricted some API access in higher versions
            $script:version = ([version]((Get-TenSession).ServerVersion)).Major
        }
    }
    Context "Get-TenUser" {
        It "Returns a user..or doesnt" {
            if ($script:version -eq 18) {
                Get-TenUser  3>$null | Select-Object -ExpandProperty name | Should -BeNullOrEmpty
            } else {
                Get-TenUser | Select-Object -ExpandProperty name | Should -Contain "admin"
            }
        }
    }

    Context "Get-TenFolder" {
        It "Returns a folder" {
            Get-TenFolder | Select-Object -ExpandProperty name | Should -Contain "Trash"
        }
    }
}