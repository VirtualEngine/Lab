function GetModule {
<#
    .SYNOPSIS
        Tests whether an exising PowerShell module meets the minimum or required version
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name
    )
    process {

        WriteVerbose -Message ($localized.LocatingModule -f $Name);
        ## Only return modules in the %ProgramFiles%\WindowsPowerShell\Modules location, ignore other $env:PSModulePaths
        $programFiles = [System.Environment]::GetFolderPath('ProgramFiles');
        $modulesPath = ('{0}\WindowsPowerShell\Modules' -f $programFiles).Replace('\','\\');
        $module = Get-Module -Name $Name -ListAvailable -Verbose:$false | Where-Object Path -match $modulesPath;

        if (-not $module) {
            WriteVerbose -Message ($localized.ModuleNotFound -f $Name);
        }
        else {
            WriteVerbose -Message ($localized.ModuleFoundInPath -f $module.Path);
        }
        return $module;

    } #end process
} #end function GetModule


function TestModule {
<#
    .SYNOPSIS
        Tests whether an exising PowerShell module meets the minimum or required version
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## The minimum version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'MinimumVersion')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $MinimumVersion,

        ## The exact version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'RequiredVersion')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $RequiredVersion,

        ## Catch all to be able to pass parameters via $PSBoundParameters
        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )
    process {

        $module = GetModule -Name $Name;
        if ($module) {

            $testLabModuleVersionParams = @{
                ModulePath = $module.Path;
            }

            if ($MinimumVersion) {
                $testLabModuleVersionParams['MinimumVersion'] = $MinimumVersion;
            }

            if ($RequiredVersion) {
                $testLabModuleVersionParams['RequiredVersion'] = $RequiredVersion;
            }

            return (Test-LabModuleVersion @testLabModuleVersionParams);
        }
        else {
            return $false;
        }

    } #end process
} #end function TestModule


function ResolveModule {
<#
    .SYNOPSIS
        Resolves a lab module definition by its name from Lability configuration data.
#>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData,

        [Parameter(Mandatory)] [ValidateSet('Module','DscResource')]
        [System.String] $ModuleType,

        ## Lab module name/ID
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String[]] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $ThrowIfNotFound
    )
    process {

        $modules = $ConfigurationData.NonNodeData.($labDefaults.ModuleName).$ModuleType;

        if (($PSBoundParameters.ContainsKey('Name')) -and ($Name -notcontains '*')) {

            ## Check we have them all first..
            foreach ($moduleName in $Name) {
                if ($modules.Name -notcontains $moduleName) {
                    if ($ThrowIfNotFound) {
                        throw ($localized.CannotResolveModuleNameError -f $ModuleType, $moduleName);
                    }
                    else {
                        WriteWarning -Message ($localized.CannotResolveModuleNameError -f $ModuleType, $moduleName);
                    }
                }
            }

            $modules = $modules | Where-Object { $_.Name -in $Name };
        }

        return $modules;
    }
} #end function ResolveLabResource




function TestModuleCache {
<#
    .SYNOPSIS
         Tests whether the requested PowerShell module is cached.
#>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [OutputType([System.Boolean])]
    param (
        ## PowerShell module/DSC resource module name
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## The minimum version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $MinimumVersion,

        ## The exact version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $RequiredVersion,

        ## GitHub repository owner
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Owner,

        ## GitHub repository branch
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Branch,

        ## Source Filesystem module path
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## Provider used to download the module
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateSet('PSGallery','GitHub','FileSystem')]
        [System.String] $Provider,

        ## Lability PowerShell module info hashtable
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Module')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable] $Module,

        ## Catch all to be able to pass parameter via $PSBoundParameters
        [Parameter(ValueFromRemainingArguments)] $RemainingArguments
    )
    begin {

        ## Remove -RemainingArguments to stop it being passed on.
        [ref] $null = $PSBoundParameters.Remove('RemainingArguments');

    }
    process {

        $moduleFileInfo = Get-LabModuleCache @PSBoundParameters;
        return ($null -ne $moduleFileInfo);

    } #end process
} #end function TestModuleCache


function GetModuleCacheManifest  {
<#
    .SYNOPSIS
        Returns a zipped module's manifest.
#>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## File path to the zipped module
        [Parameter(Mandatory)]
        [System.String] $Path,

        [ValidateSet('PSGallery','GitHub')]
        [System.String] $Provider = 'PSGallery'
    )
    begin {

        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            throw ($localized.InvalidPathError -f 'Module', $Path);
        }

    }
    process {

        Write-Debug -Message 'Loading ''System.IO.Compression'' .NET binaries.';
        [ref] $null = [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression");
        [ref] $null = [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem");

        $moduleFileInfo = Get-Item -Path $Path;

        if ($Provider -eq 'PSGallery') {
            $moduleName = $moduleFileInfo.Name -replace '\.zip', '';
        }
        elseif ($Provider -eq 'GitHub') {
            ## If we have a GitHub module, trim the _Owner_Branch.zip; if we have a PSGallery module, trim the .zip
            $moduleName = $moduleFileInfo.Name -replace '_\S+_\S+\.zip', '';
        }

        $moduleManifestName = '{0}.psd1' -f $moduleName;
        $temporaryArchivePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$moduleName.psd1";

        try {

            ### Open the ZipArchive with read access
            WriteVerbose -Message ($localized.OpeningArchive -f $moduleFileInfo.FullName);
            $archive = New-Object System.IO.Compression.ZipArchive(New-Object System.IO.FileStream($moduleFileInfo.FullName, [System.IO.FileMode]::Open));

            ## Zip archive entries are case-sensitive, therefore, we need to search for a match and can't use ::GetEntry()
            foreach ($archiveEntry in $archive.Entries) {
                if ($archiveEntry.Name -eq $moduleManifestName) {
                    $moduleManifestArchiveEntry = $archiveEntry;
                }
            }

            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($moduleManifestArchiveEntry, $temporaryArchivePath, $true);
            $moduleManifest = ConvertTo-ConfigurationData -ConfigurationData $temporaryArchivePath;
        }

        catch {

            Write-Error ($localized.ReadingArchiveItemError -f $moduleManifestName);
        }
        finally {

            if ($null -ne $archive) {
                WriteVerbose -Message ($localized.ClosingArchive -f $moduleFileInfo.FullName);
                $archive.Dispose();
            }
            Remove-Item -Path $temporaryArchivePath -Force;
        }

        return $moduleManifest;

    } #end process
} #end function GetModuleCacheVersion


function RenameModuleCacheVersion {
<#
    .SYNOPSIS
        Renames a cached module zip file with its version number.
#>
    [CmdletBinding(DefaultParameterSetName = 'PSGallery')]
    [OutputType([System.IO.FileInfo])]
    param (
        ## PowerShell module/DSC resource module name
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Destination directory path to download the PowerShell module/DSC resource module to
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## GitHub module repository owner
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'GitHub')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Owner,

        ## GitHub module branch
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'GitHub')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Branch
    )
    process {

        if ($PSCmdlet.ParameterSetName -eq 'GitHub') {
            $moduleManifest = GetModuleCacheManifest -Path $Path -Provider 'GitHub';
            $versionedModuleFilename = '{0}-v{1}_{2}_{3}.zip' -f $Name, $moduleManifest.ModuleVersion, $Owner, $Branch;
        }
        else {
            $moduleManifest = GetModuleCacheManifest -Path $Path;
            $versionedModuleFilename = '{0}-v{1}.zip' -f $Name, $moduleManifest.ModuleVersion;
        }

        $versionedModulePath = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath $versionedModuleFilename;

        if (Test-Path -Path $versionedModulePath -PathType Leaf) {
            ## Remove existing version module
            Remove-Item -Path $versionedModulePath -Force -Confirm:$false;
        }

        Rename-Item -Path $Path -NewName $versionedModuleFilename;
        return (Get-Item -Path $versionedModulePath);

    } #end process
} #end function RenameModuleCacheVersion


function InvokeModuleDownloadFromPSGallery {
<#
    .SYNOPSIS
        Downloads a PowerShell module/DSC resource from the PowerShell gallery to the host's module cache.
#>
    [CmdletBinding(DefaultParameterSetName = 'LatestAvailable')]
    [OutputType([System.IO.FileInfo])]
    param (
        ## PowerShell module/DSC resource module name
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Destination directory path to download the PowerShell module/DSC resource module to
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath = (Get-ConfigurationData -Configuration Host).ModuleCachePath,

        ## The minimum version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'MinimumVersion')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $MinimumVersion,

        ## The exact version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'RequiredVersion')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $RequiredVersion,

        ## Catch all, for splatting parameters
        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )
    process {

        $destinationModuleName = '{0}.zip' -f $Name;
        $moduleCacheDestinationPath = Join-Path -Path $DestinationPath -ChildPath $destinationModuleName;
        $setResourceDownloadParams = @{
            DestinationPath = $moduleCacheDestinationPath;
            Uri = Resolve-PSGalleryModuleUri @PSBoundParameters;
            NoCheckSum = $true;
        }
        $moduleDestinationPath = SetResourceDownload @setResourceDownloadParams;
        return (RenameModuleCacheVersion -Name $Name -Path $moduleDestinationPath);

    } #end process
} #end function InvokeModuleDownloadFromPSGallery


function InvokeModuleDownloadFromGitHub {
    <#
    .SYNOPSIS
        Downloads a DSC resource if it has not already been downloaded from Github.
    .NOTES
        Uses the GitHubRepository module!
#>
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param (
        ## PowerShell DSC resource module name
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Destination directory path to download the PowerShell module/DSC resource module to
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath = (Get-ConfigurationData -Configuration Host).ModuleCachePath,


        ## The GitHub repository owner, typically 'PowerShell'
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Owner,

        ## The GitHub repository name, normally the DSC module's name
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Repository = $Name,

        ## The GitHub branch to download, defaults to the 'master' branch
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Branch = 'master',

        ## Override the local directory name. Only used if the repository name does not
        ## match the DSC module name
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $OverrideRepositoryName = $Name,

        ## Force a download, overwriting any existing resources
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force,

        ## Catch all, for splatting parameters
        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )
    begin {

        if (-not $PSBoundParameters.ContainsKey('Owner')) {
            throw ($localized.MissingParameterError -f 'Owner');
        }
        if (-not $PSBoundParameters.ContainsKey('Branch')) {
            WriteWarning -Message ($localized.NoModuleBranchSpecified -f $Name);
        }

        ## Remove -RemainingArguments to stop it being passed on.
        [ref] $null = $PSBoundParameters.Remove('RemainingArguments');
        ## Add Repository and Branch as they might not have been explicitly passed.
        $PSBoundParameters['Repository'] = $Repository;
        $PSBoundParameters['Branch'] = $Branch;

    }
    process {

        ## GitHub modules are suffixed with .Owner_Branch.zip
        $destinationModuleName = '{0}_{1}_{2}.zip' -f $Name, $Owner, $Branch;
        $moduleCacheDestinationPath = Join-Path -Path $DestinationPath -ChildPath $destinationModuleName;
        $setResourceDownloadParams = @{
            DestinationPath = $moduleCacheDestinationPath;
            Uri = ResolveGitHubModuleUri @PSBoundParameters;
            NoCheckSum = $true;
        }
        $moduleDestinationPath = SetResourceDownload @setResourceDownloadParams;
        return (RenameModuleCacheVersion -Name $Name -Path $moduleDestinationPath -Owner $Owner -Branch $Branch);

    } #end process
} #end function InvokeModuleDownloadFromGitHub


function InvokeModuleCacheDownload {
<#
    .SYNOPSIS
        Downloads a PowerShell module (DSC resource) into the module cache.
#>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [OutputType([System.IO.FileInfo])]
    param (
        ## PowerShell module/DSC resource module name
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## The minimum version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $MinimumVersion,

        ## The exact version of the module required
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.Version] $RequiredVersion,

        ## GitHub repository owner
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Owner,

        ## The GitHub repository name, normally the DSC module's name
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Repository = $Name,

        ## GitHub repository branch
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Branch,

        ## Source Filesystem module path
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## Provider used to download the module
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameMinimum')]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'NameRequired')]
        [ValidateSet('PSGallery','GitHub','FileSystem')]
        [System.String] $Provider,

        ## Lability PowerShell module info hashtable
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Module')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]] $Module,

        ## Destination directory path to download the PowerShell module/DSC resource module to
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath = (Get-ConfigurationData -Configuration Host).ModuleCachePath,

        ## Force a download of the module(s) even if they already exist in the cache.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force,

        ## Catch all to be able to pass parameter via $PSBoundParameters
        [Parameter(ValueFromRemainingArguments)]
        $RemainingArguments
    )
    begin {

        ## Remove -RemainingArguments to stop it being passed on.
        [ref] $null = $PSBoundParameters.Remove('RemainingArguments');
        if ($PSCmdlet.ParameterSetName -ne 'Module') {

            ## Create a module hashtable
            $newModule = @{
                Name = $Name;
                Repository = $Repository;
            }
            if ($PSBoundParameters.ContainsKey('MinimumVersion')) {
                $newModule['MinimumVersion'] = $MinimumVersion;
            }
            if ($PSBoundParameters.ContainsKey('RequiredVersion')) {
                $newModule['RequiredVersion'] = $RequiredVersion;
            }
            if ($PSBoundParameters.ContainsKey('Owner')) {
                $newModule['Owner'] = $Owner;
            }
            if ($PSBoundParameters.ContainsKey('Branch')) {
                $newModule['Branch'] = $Branch;
            }
            if ($PSBoundParameters.ContainsKey('Path')) {
                $newModule['Path'] = $Path;
            }
            if ($PSBoundParameters.ContainsKey('Provider')) {
                $newModule['Provider'] = $Provider;
            }

            $Module = $newModule;
        }

    }
    process {

        foreach ($moduleInfo in $Module) {

            if ((-not (TestModuleCache @moduleInfo)) -or ($Force)) {

                if ((-not $moduleInfo.ContainsKey('Provider')) -or ($moduleInfo['Provider'] -eq 'PSGallery')) {

                    if ($moduleInfo.ContainsKey('RequiredVersion')) {
                        WriteVerbose -Message ($localized.ModuleVersionNotCached -f $moduleInfo.Name, $moduleInfo.RequiredVersion);
                    }
                    elseif ($moduleInfo.ContainsKey('MinimumVersion')) {
                        WriteVerbose -Message ($localized.ModuleMinmumVersionNotCached -f $moduleInfo.Name, $moduleInfo.MinimumVersion);
                    }
                    else {
                        WriteVerbose -Message ($localized.ModuleNotCached -f $moduleInfo.Name);
                    }

                    InvokeModuleDownloadFromPSGallery @moduleInfo;
                }
                elseif ($moduleInfo['Provider'] -eq 'GitHub') {

                    WriteVerbose -Message ($localized.ModuleNotCached -f $moduleInfo.Name);
                    InvokeModuleDownloadFromGitHub @moduleInfo;
                }
                elseif ($moduleInfo['Provider'] -eq 'FileSystem') {
                    ## We should never get here as filesystem modules are not cached.
                    ## If the test doesn't throw, it should return $true.
                }
            }
            else {
                Get-LabModuleCache @moduleInfo;
            }

        } #end foreach module

    } #end process
} #end function InvokeModuleDownload


function ExpandModuleCache {
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

            $moduleFileInfo = Get-LabModuleCache @moduleInfo;
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
                    Confirm = $false;
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
                    Confirm = $false;
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
                            Confirm = $false;
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
                            Confirm = $false;
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
} #end function ExpandModule
