function Reset-LabHostDefault {
<#
    .SYNOPSIS
        Resets lab host default settings to default.
    .DESCRIPTION
        The Reset-LabHostDefault cmdlet resets the lab host's settings to default values.
    .LINK
        Get-LabHostDefault
        Set-LabHostDefault
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param ( )
    process {

        RemoveConfigurationData -Configuration Host;
        Get-LabHostDefault;

    } #end process
} #end function Reset-LabHostDefault

function Reset-LabHostDefaults {
<#
    .SYNOPSIS
        Resets lab host default settings to default.
    .DESCRIPTION
        The Reset-LabHostDefault cmdlet resets the lab host's settings to default values.
    .NOTES
        Proxy function replacing alias to enable warning output.
    .LINK
        Get-LabHostDefault
        Set-LabHostDefault
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param ( )
    process {

        Write-Warning -Message ($localized.DeprecatedCommandWarning -f 'Reset-LabHostDefaults','Reset-LabHostDefault');
        Reset-LabHostDefault @PSBoundParameters;

    } #end process
} #end function Reset-LabHostDefaults


function Get-LabHostDefault {
<#
    .SYNOPSIS
        Gets the lab host's default settings.
    .DESCRIPTION
        The Get-LabHostDefault cmdlet returns the lab host's current settings.
    .LINK
        Set-LabHostDefault
        Reset-LabHostDefault
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param ( )
    process {

        GetConfigurationData -Configuration Host;

    } #end process
} #end function Get-LabHostDefault

function Get-LabHostDefaults {
<#
    .SYNOPSIS
        Gets the lab host's default settings.
    .DESCRIPTION
        The Get-LabHostDefault cmdlet returns the lab host's current settings.
    .NOTES
        Proxy function replacing alias to enable warning output.
    .LINK
        Set-LabHostDefault
        Reset-LabHostDefault
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param ( )
    process {

        Write-Warning -Message ($localized.DeprecatedCommandWarning -f 'Get-LabHostDefaults','Get-LabHostDefault');
        Get-LabHostDefault @PSBoundParameters;


    } #end process
} #end function Get-LabHostDefaults


function GetLabHostDSCConfigurationPath {
<#
    .SYNOPSIS
        Shortcut function to resolve the host's default ConfigurationPath property
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param ( )
    process {

        $labHostDefaults = GetConfigurationData -Configuration Host;
        return $labHostDefaults.ConfigurationPath;

    } #end process
} #end function GetLabHostDSCConfigurationPath


function Set-LabHostDefault {
<#
    .SYNOPSIS
        Sets the lab host's default settings.
    .DESCRIPTION
        The Set-LabHostDefault cmdlet sets one or more lab host default settings.
    .LINK
        Get-LabHostDefault
        Reset-LabHostDefault
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param (
        ## Lab host .mof configuration document search path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ConfigurationPath,

        ## Lab host Media/ISO storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $IsoPath,

        ## Lab host parent/master VHD(X) storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ParentVhdPath,

        ## Lab host virtual machine differencing VHD(X) storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DifferencingVhdPath,

        ## Lab module storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ModuleCachePath,

        ## Lab custom resource storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ResourcePath,

        ## Lab host DSC resource share name (for SMB Pull Server).
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ResourceShareName,

        ## Lab host media hotfix storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $HotfixPath,

        ## Disable local caching of file-based ISO and WIM files.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $DisableLocalFileCaching,

        ## Enable call stack logging in verbose output
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $EnableCallStackLogging,

        ## Custom DISM/ADK path
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $DismPath
    )
    process {

        $hostDefaults = GetConfigurationData -Configuration Host;

        $resolvablePaths = @(
            'IsoPath',
            'ParentVhdPath',
            'DifferencingVhdPath',
            'ResourcePath',
            'HotfixPath',
            'UpdatePath',
            'ConfigurationPath',
            'ModuleCachePath'
        )
        foreach ($path in $resolvablePaths) {
            if ($PSBoundParameters.ContainsKey($path)) {
                $resolvedPath = ResolvePathEx -Path $PSBoundParameters[$path];
                if (-not ((Test-Path -Path $resolvedPath -PathType Container -IsValid) -and (Test-Path -Path (Split-Path -Path $resolvedPath -Qualifier))) ) {
                    throw ($localized.InvalidPathError -f $resolvedPath, $PSBoundParameters[$path]);
                }
                else {
                    $hostDefaults.$path = $resolvedPath.Trim('\');
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('ResourceShareName')) {

            $hostDefaults.ResourceShareName = $ResourceShareName;
        }
        if ($PSBoundParameters.ContainsKey('DisableLocalFileCaching')) {

            $hostDefaults.DisableLocalFileCaching = $DisableLocalFileCaching.ToBool();
        }
        if ($PSBoundParameters.ContainsKey('EnableCallStackLogging')) {

            ## Set the global script variable read by WriteVerbose
            $script:labDefaults.CallStackLogging = $EnableCallStackLogging;
            $hostDefaults.EnableCallStackLogging = $EnableCallStackLogging.ToBool();
        }
        if ($PSBoundParameters.ContainsKey('DismPath')) {

            $hostDefaults.DismPath = ResolveDismPath -Path $DismPath;
            WriteWarning -Message ($localized.DismSessionRestartWarning);
        }

        SetConfigurationData -Configuration Host -InputObject $hostDefaults;
        ImportDismModule;

        return $hostDefaults;

    } #end process
} #end function Set-LabHostDefault

function Set-LabHostDefaults {
<#
    .SYNOPSIS
        Sets the lab host's default settings.
    .DESCRIPTION
        The Set-LabHostDefault cmdlet sets one or more lab host default settings.
    .NOTES
        Proxy function replacing alias to enable warning output.
    .LINK
        Get-LabHostDefault
        Reset-LabHostDefault
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param (
        ## Lab host .mof configuration document search path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ConfigurationPath,

        ## Lab host Media/ISO storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $IsoPath,

        ## Lab host parent/master VHD(X) storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ParentVhdPath,

        ## Lab host virtual machine differencing VHD(X) storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DifferencingVhdPath,

        ## Lab module storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ModuleCachePath,

        ## Lab custom resource storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ResourcePath,

        ## Lab host DSC resource share name (for SMB Pull Server).
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ResourceShareName,

        ## Lab host media hotfix storage location/path.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $HotfixPath,

        ## Disable local caching of file-based ISO and WIM files.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $DisableLocalFileCaching,

        ## Enable call stack logging in verbose output
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $EnableCallStackLogging,

        ## Custom DISM/ADK path
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $DismPath
    )
    process {

        Write-Warning -Message ($localized.DeprecatedCommandWarning -f 'Set-LabHostDefaults','Set-LabHostDefault');
        Set-LabHostDefault @PSBoundParameters;

    }
} #end function Set-LabHostDefaults
