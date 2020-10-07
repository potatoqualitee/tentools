Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Give Nessus time to warm up
        Wait-TenServerReady -ComputerName localhost
        # Sleep to give it even more time
        Start-Sleep 30
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
        }
    }

    # Nessus has restricted some API access in higher versions
    $version = [version]((Get-TenSession).ServerVersion)

    Context "Get-TenUser" {
        It "Returns a user..or doesnt" {
            if ($version.Major -lt 18) {
                Get-TenUser | Select-Object -ExpandProperty name | Should -Contain "admin"
            } else {
                Get-TenUser | Select-Object -ExpandProperty name | Should -BeNullOrEmpty
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