function Test-LabConfiguration {
<#
    .SYNOPSIS
        Invokes a lab configuration from a DSC configuration document.
#>
    [CmdletBinding()]
    param (
        ## Lab DSC configuration data
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        [Parameter(Mandatory, ValueFromPipeline)] [System.Object] $ConfigurationData
    )
    begin {
        $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {
        WriteVerbose $localized.StartedLabConfigurationTest;
        $nodes = $ConfigurationData.AllNodes | Where { $_.NodeName -ne '*' };
        foreach ($node in $nodes) {
            [PSCustomObject] @{
                Name = $node.NodeName;
                IsConfigured = Test-LabVM -Name $node.NodeName -ConfigurationData $ConfigurationData;
            }
        }
        WriteVerbose $localized.FinishedLabConfigurationTest;
    } #end process
} #end function Test-LabConfiguration

function TestLabConfigurationMof {
<#
    .SYNOPSIS
        Checks for node MOF and meta MOF configuration files.
#>
    [CmdletBinding()]
    param (
        ## Lab DSC configuration data
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        [Parameter(Mandatory, ValueFromPipeline)] [System.Object] $ConfigurationData,
        ## Lab vm/node name
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Name,
        ## Path to .MOF files created from the DSC configuration
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Path = (GetLabHostDSCConfigurationPath),
        ## Ignores missing MOF file
        [Parameter()] [System.Management.Automation.SwitchParameter] $SkipMofCheck
    )
    begin {
        $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {
        $Path = Resolve-Path -Path $Path -ErrorAction Stop;
        $node = $ConfigurationData.AllNodes | Where { $_.NodeName -eq $Name };
        
        $mofPath = Join-Path -Path $Path -ChildPath ('{0}.mof' -f $node.NodeName);
        WriteVerbose ($localized.CheckingForNodeFile -f $mofPath);
        if (-not (Test-Path -Path $mofPath -PathType Leaf)) {
            if ($SkipMofCheck) {
                WriteWarning ($localized.CannotLocateMofFileError -f $mofPath)
            }
            else {
                throw ($localized.CannotLocateMofFileError -f $mofPath);
            }
        }

        $metaMofPath = Join-Path -Path $Path -ChildPath ('{0}.meta.mof' -f $node.NodeName);
        WriteVerbose ($localized.CheckingForNodeFile -f $metaMofPath);
        if (-not (Test-Path -Path $metaMofPath -PathType Leaf)) {
            WriteWarning ($localized.CannotLocateLCMFileWarning -f $metaMofPath);
        }
    } #end process
} #end function TestLabConfigurationMof

function Start-LabConfiguration {
<#
    .SYNOPSIS
        Invokes a lab configuration from a DSC configuration document.
#>
    [CmdletBinding(DefaultParameterSetName = 'PSCredential')]
    param (
        ## Lab DSC configuration data
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        [Parameter(Mandatory, ValueFromPipeline)] [System.Object] $ConfigurationData,
        
        ## Local administrator password of the VM. The username is NOT used.
        [Parameter(ParameterSetName = 'PSCredential')] [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential] $Credential = (& $credentialCheckScriptBlock),
        
        ## Local administrator password of the VM.
        [Parameter(Mandatory, ParameterSetName = 'Password')] [ValidateNotNullOrEmpty()]
        [System.Security.SecureString] $Password,
        
        ## Path to .MOF files created from the DSC configuration
        [Parameter()] [ValidateNotNullOrEmpty()] [System.String] $Path = (GetLabHostDSCConfigurationPath),
        ## Skip creating baseline snapshots
        [Parameter()] [System.Management.Automation.SwitchParameter] $NoSnapshot,
        ## Forces a reconfiguration/redeployment of all nodes.
        [Parameter()] [System.Management.Automation.SwitchParameter] $Force,
        ## Ignores missing MOF file
        [Parameter()] [System.Management.Automation.SwitchParameter] $SkipMofCheck
    )
    begin {
        ## If we have only a secure string, create a PSCredential
        if ($PSCmdlet.ParameterSetName -eq 'Password') {
            $Credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'LocalAdministrator', $Password;
        }
        if (-not $Credential) { throw ($localized.CannotProcessCommandError -f 'Credential'); }
        elseif ($Credential.Password.Length -eq 0) { throw ($localized.CannotBindArgumentError -f 'Password'); }

        $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
        if (-not (Test-LabHostConfiguration) -and (-not $Force)) {
            throw $localized.HostConfigurationTestError;
        }
    }
    process {
        WriteVerbose $localized.StartedLabConfiguration;
        $nodes = $ConfigurationData.AllNodes | Where { $_.NodeName -ne '*' };

        $Path = Resolve-Path -Path $Path -ErrorAction Stop;
        foreach ($node in $nodes) {
            $testLabConfigurationMofParams = @{
                ConfigurationData = $ConfigurationData;
                Name = $node.NodeName;
                Path = $Path;
            }
            TestLabConfigurationMof @testLabConfigurationMofParams -SkipMofCheck:$SkipMofCheck;
        } #end foreach node

        foreach ($node in (Test-LabConfiguration -ConfigurationData $ConfigurationData)) {
            
            if ($node.IsConfigured -and $Force) {
                WriteVerbose ($localized.NodeForcedConfiguration -f $node.Name);
                NewLabVM -Name $node.Name -ConfigurationData $ConfigurationData -Path $Path -NoSnapshot:$NoSnapshot -Credential $Credential;
            }
            elseif ($node.IsConfigured) {
                WriteVerbose ($localized.NodeAlreadyConfigured -f $node.Name);
            }
            else {
                WriteVerbose ($localized.NodeMissingOrMisconfigured -f $node.Name);
                NewLabVM -Name $node.Name -ConfigurationData $ConfigurationData -Path $Path -NoSnapshot:$NoSnapshot -Credential $Credential;
            }
        }
        WriteVerbose $localized.FinishedLabConfiguration;
    } #end process
} #end function Start-LabConfiguration

function Remove-LabConfiguration {
<#
    .SYNOPSIS
        Removes a lab configuration from a DSC configuration document.
#>
    [CmdletBinding()]
    param (
        ## Lab DSC configuration data
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        [Parameter(Mandatory, ValueFromPipeline)] [System.Object] $ConfigurationData,
        ## Include removal of virtual switch(es). By default virtual switches are not removed.
        [Parameter()] [System.Management.Automation.SwitchParameter] $RemoveSwitch
    )
    begin {
        $ConfigurationData = ConvertToConfigurationData -ConfigurationData $ConfigurationData;
    }
    process {
        WriteVerbose $localized.StartedLabConfiguration;
        $nodes = $ConfigurationData.AllNodes | Where { $_.NodeName -ne '*' };
        foreach ($node in $nodes) {
            RemoveLabVM -Name $node.NodeName -ConfigurationData $ConfigurationData -RemoveSwitch:$RemoveSwitch;
        }
        WriteVerbose $localized.FinishedLabConfiguration;
    } #end process
} #end function Remove-LabConfiguration
