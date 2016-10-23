#requires -RunAsAdministrator
#requires -Version 4

$moduleName = 'Lability';
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path;
Import-Module (Join-Path -Path $RepoRoot -ChildPath "$moduleName.psd1") -Force;

Describe 'Src\LabSwitch' {

    InModuleScope $moduleName {

        Context 'Validates "NewLabSwitch" method' {

            It 'Returns a "System.Collections.Hashtable" object type' {
                $testSwitchName = 'TestSwitch';
                $newSwitchParams = @{
                    Name = $testSwitchName;
                    Type = 'Internal';
                }
                $labSwitch = NewLabSwitch @newSwitchParams;
                $labSwitch -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Throws when switch type is "External" and "NetAdapterName" is not specified' {
                $testSwitchName = 'TestSwitch';
                $newSwitchParams = @{
                    Name = $testSwitchName;
                    Type = 'External';
                }

                { NewLabSwitch @newSwitchParams } | Should Throw;
            }

            It 'Removes "NetAdapterName" if switch type is not "External"' {
                $testSwitchName = 'TestSwitch';
                $newSwitchParams = @{
                    Name = $testSwitchName;
                    Type = 'Internal';
                }

                $labSwitch = NewLabSwitch @newSwitchParams;

                $labSwitch.NetAdapaterName | Should BeNullOrEmpty;
            }

            It 'Removes "AllowManagementOS" if switch type is not "External"' {
                $testSwitchName = 'TestSwitch';
                $newSwitchParams = @{
                    Name = $testSwitchName;
                    Type = 'Internal';
                }

                $labSwitch = NewLabSwitch @newSwitchParams;

                $labSwitch.AllowManagementOS | Should BeNullOrEmpty;
            }

        } #end context Validates "NewLabSwitch" method

        Context 'Validates "ResolveLabSwitch" method' {


            It 'Returns a "System.Collections.Hashtable" object type' {
                $testSwitchName = 'Test Switch';
                $testSwitchType = 'Private';
                $defaultSwitchName = 'DefaultInternalSwitch';
                $fakeExistingSwitch = @{
                    Name = $testSwitchName;
                    Type = $testSwitchType;
                    IsExisting = $true;
                }
                Mock Get-VMSwitch -ParameterFilter { $Name -eq $testSwitchName } { }
                Mock Get-VMSwitch { }

                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @( ) } } }
                $fakeConfigurationData = [PSCustomObject] @{ SwitchName = $defaultSwitchName; }
                Mock GetConfigurationData -ParameterFilter { $Configuration -eq 'VM' } -MockWith { return $fakeConfigurationData; }

                $labSwitch = ResolveLabSwitch -ConfigurationData $configurationData -Name $testSwitchName -WarningAction SilentlyContinue;

                $labSwitch -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Returns specified network switch from configuration data if defined' {
                $testSwitchName = 'Test Switch';
                $testSwitchType = 'Private';
                $defaultSwitchName = 'DefaultInternalSwitch';

                $fakeExistingSwitch = [PSCustomObject] @{
                    Name = $testSwitchName;
                    SwitchType = 'External';
                    AllowManagementOS = $true;
                    NetAdapterInterfaceDescription = 'Ethernet Adapter #1';
                    IsExisting = $true;
                }

                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @(
                                @{ Name = $testSwitchName; Type = $testSwitchType; }
                            ) } } }
                $fakeConfigurationData = [PSCustomObject] @{ SwitchName = $defaultSwitchName; }

                Mock GetConfigurationData -ParameterFilter { $Configuration -eq 'VM' } -MockWith { return $fakeConfigurationData; }
                Mock Get-NetAdapter { return @{ Name = 'Ethernet Adapter #1';} }
                Mock Get-VMSwitch -ParameterFilter { $Name -eq $testSwitchName } { return $fakeExistingSwitch; }
                Mock Get-VMSwitch { }

                $labSwitch = ResolveLabSwitch -ConfigurationData $configurationData -Name $testSwitchName -WarningAction SilentlyContinue;;

                $labSwitch.Name | Should Be $testSwitchName;
                $labSwitch.Type | Should Be $testSwitchType;
                $labSwitch.IsExisting | Should BeNullOrEmpty;
            }


            It 'Returns existing "External" switch if "Name" cannot be resolved' {
                $testSwitchName = 'Test Switch';
                $testSwitchType = 'External';

                $fakeExistingSwitch = [PSCustomObject] @{
                    Name = $testSwitchName;
                    SwitchType = $testSwitchType;
                    AllowManagementOS = $true;
                    NetAdapterInterfaceDescription = 'Ethernet Adapter #1';
                    IsExisting = $true;
                }
                $configurationData = @{ }
                $fakeConfigurationData = [PSCustomObject] @{ SwitchName = 'DefaultInternalSwitch'; }
                Mock GetConfigurationData -ParameterFilter { $Configuration -eq 'VM' } -MockWith { return $fakeConfigurationData; }
                Mock Get-VMSwitch -ParameterFilter { $Name -eq $testSwitchName } { return $fakeExistingSwitch; }
                Mock Get-VMSwitch { }
                Mock Get-NetAdapter { return @{ Name = 'Ethernet Adapter #1';} }

                $labSwitch = ResolveLabSwitch -ConfigurationData $configurationData -Name $testSwitchName -WarningAction SilentlyContinue;

                $labSwitch.Name | Should Be $testSwitchName;
                $labSwitch.Type | Should Be $testSwitchType;
                $labSwitch.IsExisting | Should Be $true;
            }

            It 'Returns a default "Internal" switch if the switch cannot be resolved' {
                $testSwitchName = 'TestSwitch';
                $defaultSwitchName = 'DefaultInternalSwitch';
                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @( ) } } }
                $fakeConfigurationData = [PSCustomObject] @{ SwitchName = $defaultSwitchName; }
                Mock GetConfigurationData -ParameterFilter { $Configuration -eq 'VM' } -MockWith { return $fakeConfigurationData; }
                Mock Get-VMSwitch -ParameterFilter { $Name -eq $testSwitchName } { }
                Mock Get-VMSwitch { }

                $labSwitch = ResolveLabSwitch -ConfigurationData $configurationData -Name $testSwitchName -WarningAction SilentlyContinue;;

                $labSwitch.Name | Should Be $testSwitchName;
                $labSwitch.Type | Should Be 'Internal';
                $labSwitch.IsExisting | Should BeNullOrEmpty;
            }
        } #end context Validates "ResolveLabSwitch" method

        Context 'Validates "TestLabSwitch" method' {

            It 'Passes when network switch is found' {
                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @( ) } } }
                Mock ImportDscResource -MockWith { }
                Mock TestDscResource -ParameterFilter { $ResourceName -eq 'VMSwitch' } -MockWith { return $true; }

                TestLabSwitch -ConfigurationData $configurationData -Name 'ExistingSwitch' | Should Be $true;
            }

            It 'Passes when an existing switch is found' {
                $testSwitchName = 'Existing Virtual Switch';
                $fakeExistingSwitch = [PSCustomObject] @{
                    Name = $testSwitchName;
                    SwitchType = 'Private';
                    IsExisting = $true;
                }
                $configurationData = @{ }
                Mock ResolveLabSwitch -ParameterFilter { $Name -eq $testSwitchName } { return $fakeExistingSwitch; }

                TestLabSwitch -ConfigurationData $configurationData -Name $testSwitchName | Should Be $true;
            }

            It 'Fails when network switch is not found' {
                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @( ) } } }
                Mock Get-VMSwitch { }
                Mock ImportDscResource -MockWith { }
                Mock TestDscResource -ParameterFilter { $ResourceName -eq 'VMSwitch' } -MockWith { return $false; }

                TestLabSwitch -ConfigurationData $configurationData -Name 'NonExistentSwitch' | Should Be $false;
            }

        } #end context Validates "TestLabSwitch" method

        Context 'Validates "SetLabSwitch" method' {

            It 'Calls "InvokeDscResource"' {
                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @( ) } } }
                Mock Get-VMSwitch { }
                Mock ImportDscResource -MockWith { }
                Mock InvokeDscResource -ParameterFilter { $ResourceName -eq 'VMSwitch' } -MockWith { return $false; }

                SetLabSwitch -ConfigurationData $configurationData -Name 'Test Switch';

                Assert-MockCalled InvokeDscResource -ParameterFilter { $ResourceName -eq 'VMSwitch' } -Scope It;
            }

            It 'Does not call "InvokeDscResource" for an existing switch' {
                $testSwitchName = 'Existing Virtual Switch';
                $fakeExistingSwitch = [PSCustomObject] @{
                    Name = $testSwitchName;
                    SwitchType = 'Private';
                    IsExisting = $true;
                }
                $configurationData = @{ }
                Mock ResolveLabSwitch -ParameterFilter { $Name -eq $testSwitchName } { return $fakeExistingSwitch; }
                Mock InvokeDscResource { }

                SetLabSwitch -ConfigurationData $configurationData -Name $testSwitchName;

                Assert-MockCalled InvokeDscResource -Exactly 0 -Scope It;
            }
        } #end context Validates "SetLabSwitch" method

        Context 'Validates "RemoveLabSwitch" method' {

            It 'Calls "InvokeDscResource" with "Ensure" = "Absent"' {
                $configurationData = @{
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            Network = @( ) } } }
                Mock Get-VMSwitch { }
                Mock ImportDscResource -MockWith { }
                Mock InvokeDscResource -ParameterFilter { $Parameters['Ensure'] -eq 'Absent' } -MockWith { return $false; }

                RemoveLabSwitch -ConfigurationData $configurationData -Name 'Test Switch';

                Assert-MockCalled InvokeDscResource -ParameterFilter { $Parameters['Ensure'] -eq 'Absent' } -Scope It;
            }

            It 'Does not call "InvokeDscResource" for an existing switch' {
                $testSwitchName = 'Existing Virtual Switch';
                $fakeExistingSwitch = [PSCustomObject] @{
                    Name = $testSwitchName;
                    SwitchType = 'Private';
                    IsExisting = $true;
                }
                $configurationData = @{ }
                Mock ResolveLabSwitch -ParameterFilter { $Name -eq $testSwitchName } { return $fakeExistingSwitch; }
                Mock InvokeDscResource { }

                RemoveLabSwitch -ConfigurationData $configurationData -Name $testSwitchName;

                Assert-MockCalled InvokeDscResource -Exactly 0 -Scope It;
            }

        } #end context Validates "RemoveLabSwitch" method

    } #end InModuleScope

} #end describe Src\LabSwitch
