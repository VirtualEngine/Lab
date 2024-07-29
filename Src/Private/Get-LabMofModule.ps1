function Get-LabMofModule {
<#
    .SYNOPSIS
        Retrieves a list of DSC resource modules defined in a MOF file.
#>
    [CmdletBinding(DefaultParameterSetName='Path')]
    [OutputType([System.Collections.Hashtable])]
    param (
        # Specifies the export path location.
        [Parameter(Mandatory, ParameterSetName = 'Path', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PSPath','FullName')]
        [System.String] $Path,

        # Specifies a literal export location path.
        [Parameter(Mandatory, ParameterSetName = 'LiteralPath', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.String] $LiteralPath
    )
    begin {

        $definedModules = @{ };
    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'Path') {

            # Resolve any relative paths
            $Path = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path);
        }
        else {

            $Path = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LiteralPath);
        }

        if ($Path -match '\.meta\.mof$') {

            Write-Warning -Message ($localized.SkippingMetaConfigurationWarning -f $Path);
        }
        else {

            Write-Verbose -Message ($localized.ProcessingMofFile -f $Path);
            $currentModule = $null;
            $currentLineNumber = 0;

            foreach ($line in [System.IO.File]::ReadLines($Path)) {

                $currentLineNumber++;
                if ($line -match '^instance of (?!MSFT_Credential|MSFT_xWebBindingInformation|ServerPermission)') {
                    ## Ignore MSFT_Credential and MSFT_xWebBindingInformation types. There may be
                    ## other types that need suppressing, but they'll be resource specific, like
                    ## ServerPermission is part of SqlServerDsc

                    if ($null -eq $currentModule) {

                        ## Ignore the very first instance definition!
                    }
                    elseif (($currentModule.ContainsKey('Name')) -and
                            ($currentModule.ContainsKey('RequiredVersion'))) {

                        $definedModules[($currentModule.Name)] = $currentModule;
                    }
                    else {

                        Write-Warning -Message ($localized.CannotResolveMofModuleWarning -f $path, $instanceLineNumber, $line);
                    }

                    $instanceLineNumber = $currentLineNumber;
                    $currentModule = @{ };

                }
                elseif ($line -match '(?<=\s?ModuleName\s?=\s?")\w+(?=";)') {

                    $currentModule['Name'] = $Matches[0];
                }
                elseif ($line -match '(?<=\s?ModuleVersion\s?=\s?")\d+(\.\d+){1,3}(?=";)') {

                    $currentModule['RequiredVersion'] = $Matches[0];
                }

            } #end foreach line
        }


    } #end process
    end {

        foreach ($module in $definedModules.GetEnumerator()) {

            ## Exclude the default/built-in PSDesiredStateConfiguration module
            if ($module.Key -ne 'PSDesiredStateConfiguration') {

                Write-Output -InputObject $module.Value;
            }

        }

    } #end end
} #end function
