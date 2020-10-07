Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Give Nessus time to warm up
        Wait-TenServerReady -ComputerName localhost
        Start-Sleep 20
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

    # sometimes the first command just fails for no reason. Run once.
    $null = Get-TenUser -EnableException:$false -WarningAction SilentlyContinue

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

    Context "Get-TenPlugin" {
        It "Returns proper plugin information" {
            $results = Get-TenPlugin -PluginId 100000
            $results | Select-Object -ExpandProperty Name | Should -Be 'Test Plugin for tentools'
            $results | Select-Object -ExpandProperty PluginId | Should -Be 100000
            ($results | Select-Object -ExpandProperty Attributes).fname | Should -Be 'tentools_test.nasl'
        }
    }
}