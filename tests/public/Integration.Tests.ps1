﻿Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Give it time to do whatever it needs to do
        Start-Sleep 20
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
    Context "Set-TenCertificate" {
        It "Sets a Certificate" {
            $cred = New-Object -TypeName PSCredential -ArgumentList "root", (ConvertTo-SecureString -String 0Eff92c0eff92c -AsPlainText -Force)
            Set-TenCertificate -ComputerName localhost -Credential $cred -CertPath /tmp/servercert.pem -KeyPath /tmp/serverkey.pem -AcceptAnyThumbprint -Type Nessus -Verbose
            Reset-TenService
            $cred = New-Object -TypeName PSCredential -ArgumentList "admin", (ConvertTo-SecureString -String admin123 -AsPlainText -Force)
            $splat = @{
                ComputerName         = "localhost"
                AcceptSelfSignedCert = $true
                Credential           = $cred
                EnableException      = $true
                Port                 = 8834
            }
            Start-Sleep 20
            (Connect-TenServer @splat).ComputerName | Should -Be "localhost"
        }
    }
}