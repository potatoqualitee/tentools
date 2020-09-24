Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"

Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Give it time to do whatever it needs to do
        Start-Sleep 60
    }
    AfterAll {
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
            Connect-TenServer @splat
        }
    }
}