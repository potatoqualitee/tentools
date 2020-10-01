Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Give it time to do whatever it needs to do
        Wait-TenServer
    }
    BeforeEach {
        Write-Output -Message "Next test"
    }
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
        }
    }

    Context "Get-TenUser" {
        It "Returns a user" {
            Get-TenUser | Select-Object -ExpandProperty name | Should -Contain "admin"
        }
    }
    Context "Get-TenFolder" {
        It "Returns a folder" {
            Get-TenFolder | Select-Object -ExpandProperty name | Should -Contain "Trash"
        }
    }

    Context "Set-TenCertificate" {
        It -Skip "Sets a Certificate" {
            $cred = New-Object -TypeName PSCredential -ArgumentList "root", (ConvertTo-SecureString -String 0Eff92c0eff92c -AsPlainText -Force)
            Set-TenCertificate -ComputerName localhost -Credential $cred -CertPath /tmp/servercert.pem -KeyPath /tmp/serverkey.pem -AcceptAnyThumbprint -Type Nessus -Verbose
            Restart-TenService
            $cred = New-Object -TypeName PSCredential -ArgumentList "admin", (ConvertTo-SecureString -String admin123 -AsPlainText -Force)
            $splat = @{
                ComputerName    = "localhost"
                Credential      = $cred
                EnableException = $true
                Port            = 8834
            }
            Start-Sleep 3
            Wait-TenServerReady -ComputerName localhost
            (Connect-TenServer @splat).ComputerName | Should -Be "localhost"
        }
    }
}