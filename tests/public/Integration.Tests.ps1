Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Ensure Nessus is warmed up
        Wait-TenServerReady -ComputerName localhost
        $PSBoundParameters['*:WarningAction'] = "SilentlyContinue"
        $PSBoundParameters['*:WarningVariable'] = "warning"
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
    Context "Get-TenUser" {
        It "Returns a user..or doesnt" {
            if ($script:version -eq 18) {
                Get-TenUser 3>$null | Select-Object -ExpandProperty name | Should -BeNullOrEmpty
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

    Context "Get-TenGroup" {
        It "Doesn't return a group but does return a warning" {
            Get-TenGroup -WarningVariable warning 3>$null
            $warning | Should -match "not licenced for multiple users"
        }
    }

    Context "Get-TenGroupMember" {
        It "Doesn't return a group member but does return a warning" {
            Get-TenGroupMember -GroupId 0 -WarningVariable warning 3>$null
            $warning | Should -match "not licenced for multiple users"
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

    Context "Get-TenPluginFamily" {
        It "Returns proper plugin family information" {
            $results = Get-TenPluginFamily -FamilyId 1
            $results | Select-Object -ExpandProperty Name | Should -Be 'Misc.'
        }
    }

    Context "Add-TenPluginRule" {
        It "Adds a plugin rule" {
            $results = Add-TenPluginRule -PluginId 100000 -Type High -ComputerName localhost
            $results | Select-Object -ExpandProperty Id | Should -Be 100000
        }
    }

    Context "Get-TenPluginRule" {
        It "Returns proper plugin rule information" {
            $results = Get-TenPluginRule
            $results | Select-Object -ExpandProperty Type | Should -Contain 'High'
        }
    }
}