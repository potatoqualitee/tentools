Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"


Describe "Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        # Ensure Nessus is warmed up
        Wait-TNServerReady -ComputerName localhost

        # Set universal parameter values
        $PSBoundParameters['*:WarningAction'] = "SilentlyContinue"
        $PSBoundParameters['*:WarningVariable'] = "warning"

        # Connect then add policy to test later
        $cred = New-Object -TypeName PSCredential -ArgumentList "admin", (ConvertTo-SecureString -String admin123 -AsPlainText -Force)
        $splat = @{
            ComputerName         = "localhost"
            AcceptSelfSignedCert = $false
            Credential           = $cred
            EnableException      = $true
            Port                 = 8834
        }
        $null = Connect-TNServer @splat
        # add policy
        $params = @{
            Path        = "/policies"
            Method      = "POST"
            ContentType = "application/json"
            Parameter   = '{"uuid":"bbd4f805-3966-d464-b2d1-0079eb89d69708c3a05ec2812bcf","settings":{"display_unreachable_hosts":"no","log_live_hosts":"yes","reverse_lookup":"no","allow_post_scan_editing":"yes","udp_scanner":"no","syn_scanner":"yes","syn_firewall_detection":"Automatic (normal)","tcp_scanner":"no","tcp_firewall_detection":"Automatic (normal)","portscan_range":"default","unscanned_closed":"no","wol_wait_time":"5","wol_mac_addresses":"","scan_netware_hosts":"no","scan_network_printers":"no","ping_the_remote_host":"yes","udp_ping":"no","icmp_ping":"yes","icmp_ping_retries":"2","icmp_unreach_means_host_down":"no","tcp_ping":"yes","tcp_ping_dest_ports":"built-in","arp_ping":"yes","fast_network_discovery":"no","test_local_nessus_host":"yes","discovery_mode":"Host enumeration","acls":[{"object_type":"policy","permissions":0,"type":"default"}],"description":"","name":"Test Policy"}}'
        }
        $null = Invoke-TNRequest @params
    }
    BeforeEach {
        Write-Output -Message "Next test"
    }
    Context "Connect-TNServer" {
        It "Connects to a site" {
            $cred = New-Object -TypeName PSCredential -ArgumentList "admin", (ConvertTo-SecureString -String admin123 -AsPlainText -Force)
            $splat = @{
                ComputerName         = "localhost"
                AcceptSelfSignedCert = $false
                Credential           = $cred
                EnableException      = $true
                Port                 = 8834
            }
            (Connect-TNServer @splat).ComputerName | Should -Be "localhost"
            # Nessus has restricted some API access in higher versions
            $script:version = (Get-TNSession).ServerVersionMajor
        }
    }
    Context "Get-TNUser" {
        It "Returns a user..or doesnt" {
            if ($script:version -ge 8) {
                Get-TNUser 3>$null | Select-Object -ExpandProperty name | Should -BeNullOrEmpty
            } else {
                Get-TNUser | Select-Object -ExpandProperty name | Should -Contain "admin"
            }
        }
    }

    Context "Get-TNFolder" {
        It "Returns a folder" {
            Get-TNFolder | Select-Object -ExpandProperty name | Should -Contain "Trash"
        }
    }

    Context "Get-TNGroup" {
        It "Doesn't return a group but does return a warning" {
            Get-TNGroup -WarningVariable warning 3>$null
            $warning | Should -match "not licenced for multiple users"
        }
    }

    Context "Get-TNGroupMember" {
        It "Doesn't return a group member but does return a warning" {
            Get-TNGroupMember -GroupId 0 -WarningVariable warning 3>$null
            $warning | Should -match "not licenced for multiple users"
        }
    }

    Context "Get-TNPlugin" {
        It "Returns proper plugin information" {
            $results = Get-TNPlugin -PluginId 100000
            $results | Select-Object -ExpandProperty Name | Should -Be 'Test Plugin for tentools'
            $results | Select-Object -ExpandProperty PluginId | Should -Be 100000
            ($results | Select-Object -ExpandProperty Attributes).fname | Should -Be 'tentools_test.nasl'
        }
    }

    Context "Get-TNPluginFamily" {
        It "Returns proper plugin family information" {
            $results = Get-TNPluginFamily -FamilyId 1
            $results | Select-Object -ExpandProperty Name | Should -Be 'Misc.'
        }
    }

    Context "Add-TNPluginRule" {
        It "Adds a plugin rule" {
            $results = Add-TNPluginRule -PluginId 100000 -Type High -ComputerName localhost
            $results | Select-Object -ExpandProperty PluginId | Should -Be 100000
        }
    }

    Context "Get-TNPluginRule" {
        It "Returns proper plugin rule information" {
            $results = Get-TNPluginRule
            $results | Select-Object -ExpandProperty Type | Should -Contain 'High'
        }
    }
    Context "Get-TNPolicy" {
        It "Returns proper policy information" {
            $results = Get-TNPolicy
            $results | Select-Object -ExpandProperty Name | Should -Be 'Test Policy'
        }
    }
    Context "Get-TNPolicyDetail" {
        It "Returns proper policy detail information" {
            $results = Get-TNPolicy | Select-Object Id | Get-TNPolicyDetail
            $results | Select-Object -ExpandProperty Title | Should -Contain 'Host Discovery'
        }
    }

    Context "Get-TNPolicyLocalPortEnumeration" {
        It "Returns proper policy detail information" {
            $results = Get-TNPolicy | Select-Object Id | Get-TNPolicyDetail | Get-TNPolicyLocalPortEnumeration
            $results.PolicyId | Should -Contain 4
        }
    }
}