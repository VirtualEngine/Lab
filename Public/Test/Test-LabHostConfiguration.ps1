﻿function Test-LabHostConfiguration {

<#
    .SYNOPSIS
        Tests the lab host's configuration.
    .DESCRIPTION
        The Test-LabHostConfiguration tests the current configuration of the lab host.
    .PARAMETER IgnorePendingReboot
        Specifies a pending reboot does not fail the test.
    .LINK
        Get-LabHostConfiguration
        Test-LabHostConfiguration
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## Skips pending reboot check
        [Parameter()]
        [System.Management.Automation.SwitchParameter] $IgnorePendingReboot
    )
    process {
        WriteVerbose $localized.StartedHostConfigurationTest;
        ## Test folders/directories
        $hostDefaults = GetConfigurationData -Configuration Host;
        foreach ($property in $hostDefaults.PSObject.Properties) {
        
            if (($property.Name.EndsWith('Path')) -and (-not [System.String]::IsNullOrEmpty($property.Value))) {

                ## DismPath is not a folder and should be ignored (#159)
                if ($property.Name -ne 'DismPath') {
                
                    WriteVerbose ($localized.TestingPathExists -f $property.Value);
                    $resolvedPath = ResolvePathEx -Path $property.Value;
                    if (-not (Test-Path -Path $resolvedPath -PathType Container)) {
                    
                        WriteVerbose -Message ($localized.PathDoesNotExist -f $resolvedPath);
                        return $false;
                    }
                }
            }
        }

        $labHostSetupConfiguration = GetLabHostSetupConfiguration;
        foreach ($configuration in $labHostSetupConfiguration) {
            $importDscResourceParams = @{
                ModuleName = $configuration.ModuleName;
                ResourceName = $configuration.ResourceName;
                Prefix = $configuration.Prefix;
                UseDefault = $configuration.UseDefault;
            }
            ImportDscResource @importDscResourceParams;
            WriteVerbose ($localized.TestingNodeConfiguration -f $Configuration.Description);
            if (-not (TestDscResource -ResourceName $configuration.Prefix -Parameters $configuration.Parameters)) {
                if ($configuration.Prefix -eq 'PendingReboot') {
                    WriteWarning $localized.PendingRebootWarning;
                    if (-not $IgnorePendingReboot) {
                        return $false;
                    }
                }
                else {
                    return $false;
                }
            }
        } #end foreach labHostSetupConfiguration
        WriteVerbose $localized.FinishedHostConfigurationTest;
        return $true;
    } #end process

}

