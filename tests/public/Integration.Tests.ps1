Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Ensure Nessus is warmed up
        Wait-TenServerReady -ComputerName localhost
    }
    BeforeEach {
        Write-Output -Message "Next test"
    }
    Context "Connect-TenServer" {
        It "Connects to a site" {
            $cred = New-Object -TypeName PSCredential -ArgumentList "admin", (ConvertTo-SecureString -String admin123 -AsPlainText -Force)
            $splat = @{
                ComputerName         = "localhost"
                AcceptSelfSignedCert = $false
                Credential           = $cred
                EnableException      = $true
                Port                 = 8834
            }
            (Connect-TenServer @splat).ComputerName | Should -Be "localhost"
            # Nessus has restricted some API access in higher versions
            $script:version = ([version]((Get-TenSession).ServerVersion)).Major
        }
    }
    Write-Warning "$script:version"
    Context "Get-TenUser" {
        It "Returns a user..or doesnt" {
            if ($script:version -eq 18) {
                Get-TenUser | Select-Object -ExpandProperty name | Should -BeNullOrEmpty
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

    Context "Get-TenPlugin" {
        It "Returns proper plugin information" {
            $results = Get-TenPlugin -PluginId 100000
            $results | Select-Object -ExpandProperty Name | Should -Be 'Test Plugin for tentools'
            $results | Select-Object -ExpandProperty PluginId | Should -Be 100000
            ($results | Select-Object -ExpandProperty Attributes).fname | Should -Be 'tentools_test.nasl'
        }
    }
}