﻿function ExpandModuleCache {

<#
    .SYNOPSIS
        Extracts a cached PowerShell module to the specified destination module path.
#>
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param (
        ## PowerShell module hashtable
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]] $Module,

        ## Destination directory path to download the PowerShell module/DSC resource module to
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath,

        ## Removes existing module directory if present
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Clean,

        ## Catch all to be able to pass parameter via $PSBoundParameters
        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )
    begin {

        [ref] $null = $PSBoundParameters.Remove('RemainingArguments');

    }
    process {

        foreach ($moduleInfo in $Module) {

            $moduleFileInfo = GetModuleCache @moduleInfo;
            $moduleSourcePath = $moduleFileInfo.FullName;
            $moduleDestinationPath = Join-Path -Path $DestinationPath -ChildPath $moduleInfo.Name;

            if ($Clean -and (Test-Path -Path $moduleDestinationPath -PathType Container)) {
                WriteVerbose -Message ($localized.CleaningModuleDirectory -f $moduleDestinationPath);
                Remove-Item -Path $moduleDestinationPath -Recurse -Force -Confirm:$false;
            }

            if ((-not $moduleInfo.ContainsKey('Provider')) -or
                    ($moduleInfo.Provider -eq 'PSGallery')) {

                WriteVerbose -Message ($localized.ExpandingModule -f $moduleDestinationPath);
                $expandZipArchiveParams = @{
                    Path = $moduleSourcePath;
                    DestinationPath = $moduleDestinationPath;
                    ExcludeNuSpecFiles = $true;
                    Force = $true;
                    Verbose = $false;
                    WarningAction = 'SilentlyContinue';
                }
                [ref] $null = ExpandZipArchive @expandZipArchiveParams;

            } #end if PSGallery
            elseif (($moduleInfo.ContainsKey('Provider')) -and
                    ($moduleInfo.Provider -eq 'GitHub')) {

                WriteVerbose -Message ($localized.ExpandingModule -f $moduleDestinationPath);
                $expandGitHubZipArchiveParams = @{
                    Path = $moduleSourcePath;
                    ## GitHub modules include the module directory. Therefore, we need the parent root directory
                    DestinationPath = Split-Path -Path $moduleDestinationPath -Parent;;
                    Repository = $moduleInfo.Name;
                    Force = $true;
                    Verbose = $false;
                    WarningAction = 'SilentlyContinue';
                }

                if ($moduleInfo.ContainsKey('OverrideRepository')) {
                    $expandGitHubZipArchiveParams['OverrideRepository'] = $moduleInfo.OverrideRepository;
                }

                [ref] $null = ExpandGitHubZipArchive @expandGitHubZipArchiveParams;

            } #end if GitHub
            elseif (($moduleInfo.ContainsKey('Provider')) -and
                    ($moduleInfo.Provider -eq 'FileSystem')) {
                if ($null -ne $moduleFileInfo) {

                    if ($moduleFileInfo -is [System.IO.FileInfo]) {

                        WriteVerbose -Message ($localized.ExpandingModule -f $moduleDestinationPath);
                        $expandZipArchiveParams = @{
                            Path = $moduleSourcePath;
                            DestinationPath = $moduleDestinationPath;
                            ExcludeNuSpecFiles = $true;
                            Force = $true;
                            Verbose = $false;
                            WarningAction = 'SilentlyContinue';
                        }
                        [ref] $null = ExpandZipArchive @expandZipArchiveParams;
                    }
                    elseif ($moduleFileInfo -is [System.IO.DirectoryInfo]) {

                        WriteVerbose -Message ($localized.CopyingModuleDirectory -f $moduleFileInfo.Name, $moduleDestinationPath);
                        ## If the target doesn't exist create it. We may be copying a versioned
                        ## module, i.e. \xJea\0.2.16.6 to \xJea..
                        if (-not (Test-Path -Path $moduleDestinationPath -PathType Container)) {
                            New-Item -Path $moduleDestinationPath -ItemType Directory -Force;
                        }
                        $copyItemParams = @{
                            Path = "$moduleSourcePath\*";
                            Destination = $moduleDestinationPath;
                            Recurse = $true;
                            Force = $true;
                            Verbose = $false;
                        }
                        Copy-Item @copyItemParams;
                    }

                }
            } #end if FileSystem

            ## Only output if we found a module during this pass
            if ($null -ne $moduleFileInfo) {
                Write-Output -InputObject (Get-Item -Path $moduleDestinationPath);
            }

        } #end foreach module

    } #end process

}

