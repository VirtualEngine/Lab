﻿function GetConfigurationData {

<#
    .SYNOPSIS
        Gets lab configuration data.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Host','VM','Media','CustomMedia')]
        [System.String] $Configuration
    )
    process {

        $configurationPath = ResolveConfigurationDataPath -Configuration $Configuration -IncludeDefaultPath;
        if (Test-Path -Path $configurationPath) {
            $configurationData = Get-Content -Path $configurationPath -Raw | ConvertFrom-Json;

            switch ($Configuration) {

                'VM' {

                    ## This property may not be present in the original VM default file TODO: Could be deprecated in the future
                    if ($configurationData.PSObject.Properties.Name -notcontains 'CustomBootstrapOrder') {

                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'CustomBootstrapOrder' -Value 'MediaFirst';
                    }
                    ## This property may not be present in the original VM default file TODO: Could be deprecated in the future
                    if ($configurationData.PSObject.Properties.Name -notcontains 'SecureBoot') {

                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'SecureBoot' -Value $true;
                    }
                    ## This property may not be present in the original VM default file TODO: Could be deprecated in the future
                    if ($configurationData.PSObject.Properties.Name -notcontains 'GuestIntegrationServices') {

                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'GuestIntegrationServices' -Value $false;
                    }
                }
                'CustomMedia' {

                    foreach ($mediaItem in $configurationData) {

                        ## Add missing OperatingSystem property
                        if ($mediaItem.PSObject.Properties.Name -notcontains 'OperatingSystem') {

                            [ref] $null = Add-Member -InputObject $mediaItem -MemberType NoteProperty -Name 'OperatingSystem' -Value 'Windows';
                        }
                    } #end foreach media item
                }
                'Host' {

                    ## This property may not be present in the original machine configuration file
                    if ($configurationData.PSObject.Properties.Name -notcontains 'DisableLocalFileCaching') {

                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'DisableLocalFileCaching' -Value $false;
                    }
                    ## This property may not be present in the original machine configuration file
                    if ($configurationData.PSObject.Properties.Name -notcontains 'EnableCallStackLogging') {

                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'EnableCallStackLogging' -Value $false;
                    }
                    ## This property may not be present in the original machine configuration file
                    if ($configurationData.PSObject.Properties.Name -notcontains 'ModuleCachePath') {

                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'ModuleCachePath' -Value '%ALLUSERSPROFILE%\Lability\Modules';
                    }
                    if ($configurationData.PSObject.Properties.Name -notcontains 'DismPath') {

                        $dismDllName = 'Microsoft.Dism.PowerShell.dll';
                        $dismDllPath = Join-Path -Path "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\Dism" -ChildPath $dismDllName -Resolve;
                        [ref] $null = Add-Member -InputObject $configurationData -MemberType NoteProperty -Name 'DismPath' -Value $dismDllPath;
                    }

                    ## Remove deprecated UpdatePath, if present (Issue #77)
                    $configurationData.PSObject.Properties.Remove('UpdatePath');
                }
            } #end switch

            # Expand any environment variables in configuration data
            $configurationData.PSObject.Members |
                Where-Object { ($_.MemberType -eq 'NoteProperty') -and ($_.IsSettable) -and ($_.TypeNameOfValue -eq 'System.String') } |
                    ForEach-Object {
                        $_.Value = [System.Environment]::ExpandEnvironmentVariables($_.Value);
                    }

            return $configurationData;
        }

    } #end process

}

