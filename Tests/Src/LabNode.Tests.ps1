<# DEPRECATED
#requires -RunAsAdministrator
#requires -Version 4

$moduleName = 'Lability';
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path;
Import-Module (Join-Path -Path $RepoRoot -ChildPath "$moduleName.psd1") -Force;

Describe 'Src\LabNode' {

    InModuleScope $moduleName {

        Context 'Validates "Test-LabNodeConfiguration" method' {

            It 'Passes when single DSC module exists' {
                $testNode = 'TestNode'
                $testModuleName = 'TestModule';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                            )
                        }
                    }
                }
                Mock TestLabNodeCertificate { return $true; }
                Mock TestModule { return $true; }

                $result = Test-LabNodeConfiguration -ConfigurationData $configurationData -NodeName $testNode;

                $result | Should Be $true;
            }

            It 'Passes when multiple DSC modules exist' {
                $testNode = 'TestNode'
                $testModuleName = 'TestModule';
                $testModuleName2 = 'TestModule2';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                                @{ Name = $testModuleName2; }
                            )
                        }
                    }
                }
                Mock TestModule { return $true; }

                $result = Test-LabNodeConfiguration -ConfigurationData $configurationData -NodeName $testNode;

                $result | Should Be $true;
            }

            It 'Fails when single DSC module does not exist' {
                $testNode = 'TestNode'
                $testModuleName = 'TestModule';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                            )
                        }
                    }
                }
                Mock TestModule { return $false; }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    WarningAction = 'SilentlyContinue';
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                $result | Should Be $false;
            }

            It 'Fails when multiple DSC module does not exist' {
                $testNode = 'TestNode'
                $testModuleName = 'TestModule';
                $testModuleName2 = 'TestModule2';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                                @{ Name = $testModuleName2; }
                            )
                        }
                    }
                }
                Mock TestModule -ParameterFilter { $Name -eq $testModuleName2 } { return $true; }
                Mock TestModule  { return $false; }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    WarningAction = 'SilentlyContinue';
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                $result | Should Be $false;
            }

            It 'Does not call "TestModule" when "SkipDscCheck" specified' {
                $testNode = 'TestNode'
                $testModuleName = 'TestModule';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                            )
                        }
                    }
                }
                Mock TestModule -MockWith { }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    SkipDscCheck = $true;
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                Assert-MockCalled TestModule -Exactly 0 -Scope It;
            }

            It 'Passes when single resource exists' {
                $testNode = 'TestNode'
                $testResourceId = 'TestResource';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; Resource = $testResourceId; }
                    )
                }
                Mock TestLabResourceIsLocal { return $true; }

                $result = Test-LabNodeConfiguration -ConfigurationData $configurationData -NodeName $testNode;

                $result | Should Be $true;
            }

            It 'Passes when multiple resources exist' {
                $testNode = 'TestNode'
                $testResourceId = 'TestResource';
                $testResourceId2 = 'TestResource2';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; Resource = $testResourceId, $testResourceId2 }
                    )
                }
                Mock TestLabResourceIsLocal { return $true; }

                $result = Test-LabNodeConfiguration -ConfigurationData $configurationData -NodeName $testNode;

                $result | Should Be $true;
            }

            It 'Fails when single resource does not exist' {
                $testNode = 'TestNode'
                $testResourceId = 'TestResource';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; Resource = $testResourceId; }
                    )
                }
                Mock TestLabResourceIsLocal { return $false; }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    WarningAction = 'SilentlyContinue';
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                $result | Should Be $false;
            }

            It 'Fails when multiple resource does not exist' {
                $testNode = 'TestNode'
                $testResourceId = 'TestResource';
                $testResourceId2 = 'TestResource2';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; Resource = $testResourceId, $testResourceId2; }
                    )
                }
                Mock TestLabResourceIsLocal -ParameterFilter { $ResourceId -eq $testResourceId2 } { return $true; }
                Mock TestLabResourceIsLocal { return $false; }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    WarningAction = 'SilentlyContinue';
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                $result | Should Be $false;
            }

            It 'Does not call "TestLabResourceIsLocal" when "SkipResourceCheck" specified' {
                $testNode = 'TestNode'
                $testResourceId = 'TestResource';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; Resource = $testResourceId, $testResourceId2; }
                    )
                }
                Mock TestLabResourceIsLocal { }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    SkipResourceCheck = $true;
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                Assert-MockCalled TestLabResourceIsLocal -Exactly 0 -Scope It;
            }

            It 'Passes when certificates are present' {
                $testNode = 'TestNode'
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                }
                Mock TestLabNodeCertificate { return $true; }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                $result | Should Be $true;
            }

            It 'Fails when certificates are not present' {
                $testNode = 'TestNode'
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                }
                Mock TestLabNodeCertificate { return $false; }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    WarningAction = 'SilentlyContinue';
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                $result | Should Be $false;
            }

            It 'Does not call "TestLabNodeCertificate" when "SkipCertificateCheck" specified' {
                $testNode = 'TestNode'
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                }
                Mock TestLabNodeCertificate { }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    SkipCertificateCheck = $true;
                }
                $result = Test-LabNodeConfiguration @testLabNodeConfigurationParams;

                Assert-MockCalled TestLabNodeCertificate -Exactly 0 -Scope It;
            }

            It 'Throws is node cannot be resolved' {
                $testNode = 'TestNode'
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = 'NonExistent'; }
                    )
                }

                $testLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                }
                { Test-LabNodeConfiguration @testLabNodeConfigurationParams } | Should Throw;
            }

        } #end context Validates "Test-LabNodeConfiguration" method

        Context 'Validates "Invoke-LabNodeConfiguration" method' {

            Mock Test-LabNodeConfiguration { return $true; }

            It 'Calls "InstallLabNodeCertificates' {
                $testNode = 'TestNode'
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode;  }
                    )
                }
                Mock InstallLabNodeCertificates -MockWith { }

                $invokeLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    DestinationPath = 'TestDrive:';
                }
                Invoke-LabNodeConfiguration @invokeLabNodeConfigurationParams;

                Assert-MockCalled InstallLabNodeCertificates -Scope It;
            }

            It 'Calls "InvokeDscResourceDownload" when DSC module does not exist' {
                $testNode = 'TestNode';
                $testModuleName = 'TestModule';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                            )
                        }
                    }
                }
                Mock TestModule { return $false; }
                Mock InvokeDscResourceDownload { }

                $invokeLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    DestinationPath = 'TestDrive:';
                }
                Invoke-LabNodeConfiguration @invokeLabNodeConfigurationParams;

                Assert-MockCalled InvokeDscResourceDownload -Scope It;
            }

            It 'Does not call "InvokeDscResourceDownload" when DSC module exists' {
                $testNode = 'TestNode';
                $testModuleName = 'TestModule';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; }
                    )
                    NonNodeData = @{
                        $labDefaults.ModuleName = @{
                            DSCResource = @(
                                @{ Name = $testModuleName; }
                            )
                        }
                    }
                }
                Mock TestModule { return $true; }
                Mock InvokeDscResourceDownload { }

                $invokeLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    DestinationPath = 'TestDrive:';
                }
                Invoke-LabNodeConfiguration @invokeLabNodeConfigurationParams;

                Assert-MockCalled InvokeDscResourceDownload -Exactly 0 -Scope It;
            }

            It 'Calls "Test-LabNodeConfiguration"' {
                $testNode = 'TestNode';
                $testResourceId = 'TestResource';
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = $testNode; Resource = $testResourceId; }
                    )
                }
                Mock Test-LabNodeConfiguration { return $true; }

                $invokeLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    DestinationPath = 'TestDrive:';
                }
                Invoke-LabNodeConfiguration @invokeLabNodeConfigurationParams;

                Assert-MockCalled Test-LabNodeConfiguration -Scope It;
            }

            It 'Throws is node cannot be resolved' {
                $testNode = 'TestNode'
                $configurationData = @{
                    AllNodes = @(
                        @{ NodeName = 'NonExistent'; }
                    )
                }

                $invokeLabNodeConfigurationParams = @{
                    ConfigurationData = $configurationData;
                    NodeName = $testNode;
                    DestinationPath = 'TestDrive:';
                }
                { Invoke-LabNodeConfiguration @invokeLabNodeConfigurationParams } | Should Throw;
            }

        } #end context Validates "Invoke-LabNodeConfiguration" method

    } #end inmodulescope

} #end describe Src\LabNode
#>
