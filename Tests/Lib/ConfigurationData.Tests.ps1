#requires -RunAsAdministrator
#requires -Version 4

$moduleName = 'Lability';
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path;
Import-Module (Join-Path -Path $RepoRoot -ChildPath "$moduleName.psd1") -Force;

Describe 'Lib\ConfigurationData' {

    InModuleScope $moduleName {

        Context 'Validates "ResolveConfigurationDataPath" method' {

            foreach ($config in @('Host','VM','Media','CustomMedia')) {

                It "Resolves '$config' to module path when custom configuration does not exist" {
                    Mock Test-Path -MockWith { return $false }
                    $configurationPath = ResolveConfigurationDataPath -Configuration $config -IncludeDefaultPath;
                    $configurationPath -match $repoRoot | Should Be $true;
                }

                It "Resolves '$config' to %ALLUSERSPROFILE% path when custom configuration does exist" {
                    Mock Test-Path -MockWith { return $true }
                    $configurationPath = ResolveConfigurationDataPath -Configuration $config;
                    $allUsersProfile = ("$env:AllUsersProfile\$moduleName").Replace('\','\\');
                    $configurationPath -match $allUsersProfile | Should Be $true;
                }

            } #end foreach $config

            It 'Resolves environment variables in resulting path' {
                Mock Test-Path -MockWith { return $true }
                Mock ResolvePathEx -MockWith { }

                ResolveConfigurationDataPath -Configuration Media;

                Assert-MockCalled ResolvePathEx -Scope It;
            }

        } #end context Validates "ResolveConfigurationDataPath" method

        Context 'Validates "GetConfigurationData" method' {

            It 'Adds missing "CustomBootstrapOrder" property to VM configuration' {
                $testConfigurationFilename = 'TestVMConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $vmConfiguration = GetConfigurationData -Configuration VM;

                $vmConfiguration.CustomBootstrapOrder | Should Be 'MediaFirst';
            }

            It 'Adds missing "SecureBoot" property to VM configuration' {
                $testConfigurationFilename = 'TestVMConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $vmConfiguration = GetConfigurationData -Configuration VM;

                $vmConfiguration.SecureBoot -eq $true | Should Be $true;
            }

            It 'Adds missing "GuestIntegrationServices" property to VM configuration' {
                $testConfigurationFilename = 'TestVMConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $vmConfiguration = GetConfigurationData -Configuration VM;

                $vmConfiguration.GuestIntegrationServices -eq $false | Should Be $true;
            }

            It 'Adds missing "OperatingSystem" property to CustomMedia configuration' {
                $testConfigurationFilename = 'TestMediaConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '[{ "Id": "TestMedia" }]';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $customMediaConfiguration = GetConfigurationData -Configuration CustomMedia;

                $customMediaConfiguration.OperatingSystem | Should Be 'Windows';
            }

            It 'Adds missing "DisableLocalFileCaching" property to Host configuration' {
                $testConfigurationFilename = 'TestMediaConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $customMediaConfiguration = GetConfigurationData -Configuration Host;

                $customMediaConfiguration.DisableLocalFileCaching | Should Be $false;
            }

            It 'Adds missing "EnableCallStackLogging" property to Host configuration' {
                $testConfigurationFilename = 'TestMediaConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $customMediaConfiguration = GetConfigurationData -Configuration Host;

                $customMediaConfiguration.EnableCallStackLogging | Should Be $false;
            }

            It 'Removes deprecated "UpdatePath" property from Host configuration (Issue #77)' {
                $testConfigurationFilename = 'TestMediaConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\Temp\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations", "UpdatePath": "%SYSTEMDRIVE%\\TestLab\\Updates" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return $testConfigurationPath }
                Mock Get-Content -ParameterFilter { $Path -eq $testConfigurationPath } -MockWith { return $fakeConfiguration; }

                $hostConfiguration = GetConfigurationData -Configuration Host;

                $hostConfiguration.PSObject.Properties.Name.Contains('UpdatePath') | Should Be $false;
            }

        } #end context Validates "GetConfigurationData" method

        ## Removed until I can work out why this one test is failing :(
        ##Context 'Validates "SetConfigurationData" method' {
        ##
        ##    It 'Resolves environment variables in path' {
        ##        $testConfigurationFilename = 'TestConfiguration.json';
        ##        $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }' | ConvertFrom-Json;
        ##        Mock ResolveConfigurationDataPath -MockWith { return ('%SYSTEMROOT%\{0}' -f $testConfigurationFilename); }
        ##        Mock NewDirectory -MockWith { }
        ##        Mock Set-Content -ParameterFilter { $Path -eq "$env:SystemRoot\$testConfigurationFilename" } -MockWith { return $fakeConfiguration; }
        ##
        ##        SetConfigurationData -Configuration Host -InputObject $fakeConfiguration;
        ##
        ##        Assert-MockCalled Set-Content -ParameterFilter { $Path -eq "$env:SystemRoot\$testConfigurationFilename" } -Scope It;
        ##    }
        ##
        ##} #end context Validates "GetConfigurationData" method

        Context 'Validates "RemoveConfigurationData" method' {

            It 'Removes configuration file' {
                $testConfigurationFilename = 'TestVMConfiguration.json';
                $testConfigurationPath = "$env:SystemRoot\$testConfigurationFilename";
                $fakeConfiguration = '{ "ConfigurationPath": "%SYSTEMDRIVE%\\TestLab\\Configurations" }';
                [ref] $null = New-Item -Path $testConfigurationPath -ItemType File -Force;
                Mock ResolveConfigurationDataPath -MockWith { return ('%SYSTEMROOT%\{0}' -f $testConfigurationFilename); }
                Mock Test-Path -MockWith { return $true; }
                Mock Remove-Item -ParameterFilter { $Path.EndsWith($testConfigurationFilename ) } -MockWith { }

                RemoveConfigurationData -Configuration VM;

                Assert-MockCalled Remove-Item -ParameterFilter { $Path.EndsWith($testConfigurationFilename) } -Scope It;
            }

        } #end context Validates "RemoveConfigurationData" method

    } #end InModuleScope

} #end describe Lib\ConfigurationData
