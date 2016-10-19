function NewLabMedia {
<#
    .SYNOPSIS
        Creates a new lab media object.
    .DESCRIPTION
        Permits validation of custom NonNodeData\Lability\Media entries.
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Id = $(throw ($localized.MissingParameterError -f 'Id')),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Filename = $(throw ($localized.MissingParameterError -f 'Filename')),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Description = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('x86','x64')]
        [System.String] $Architecture = $(throw ($localized.MissingParameterError -f 'Architecture')),

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $ImageName = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('ISO','VHD')]
        [System.String] $MediaType = $(throw ($localized.MissingParameterError -f 'MediaType')),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri = $(throw ($localized.MissingParameterError -f 'Uri')),

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $Checksum = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $ProductKey = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Windows','Linux')]
        [System.String] $OperatingSystem = 'Windows',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.Collections.Hashtable] $CustomData = @{},

        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [System.Array] $Hotfixes
    )
    begin {

        ## Confirm we have a valid Uri
        try {

            $resolvedUri = New-Object -TypeName 'System.Uri' -ArgumentList $Uri;
            if ($resolvedUri.Scheme -notin 'http','https','file') {
                throw ($localized.UnsupportedUriSchemeError -f $resolvedUri.Scheme);
            }
        }
        catch {

            throw $_;
        }

    }
    process {

        $labMedia = [PSCustomObject] @{
            Id = $Id;
            Filename = $Filename;
            Description = $Description;
            Architecture = $Architecture;
            ImageName = $ImageName;
            MediaType = $MediaType;
            OperatingSystem = $OperatingSystem;
            Uri = [System.Uri] $Uri;
            Checksum = $Checksum;
            CustomData = $CustomData;
            Hotfixes = $Hotfixes;
        }

        ## Ensure any explicit product key overrides the CustomData value
        if ($ProductKey) {

            $CustomData['ProductKey'] = $ProductKey;
        }
        return $labMedia;

    } #end process
} #end function NewLabMedia


function ResolveLabMedia {
<#
    .SYNOPSIS
        Resolves the specified media using the registered media and configuration data.
    .DESCRIPTION
        Resolves the specified lab media from the registered media, but permitting the defaults to be overridden by configuration data.

        This also permits specifying of media within Configuration Data and not having to be registered on the lab host.
#>
    [CmdletBinding()]
    param (
        ## Media ID
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $Id,

        ## Lab DSC configuration data
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {

        ## Avoid any $media variable scoping issues
        $media = $null;

        ## If we have configuration data specific instance, return that
        if ($PSBoundParameters.ContainsKey('ConfigurationData')) {

            $customMedia = $ConfigurationData.NonNodeData.$($labDefaults.ModuleName).Media.Where({ $_.Id -eq $Id });
            if ($customMedia) {

                $newLabMediaParams = @{};
                foreach ($key in $customMedia.Keys) {

                    $newLabMediaParams[$key] = $customMedia.$key;
                }
                $media = NewLabMedia @newLabMediaParams;
            }
        }

        ## If we have custom media, return that
        if (-not $media) {

            $media = GetConfigurationData -Configuration CustomMedia;
            $media = $media | Where-Object { $_.Id -eq $Id };
        }

        ## If we still don't have a media image, return the built-in object
        if (-not $media) {

            $media = Get-LabMedia -Id $Id;
        }

        ## We don't have any defined, custom or built-in media
        if (-not $media) {

            throw ($localized.CannotLocateMediaError -f $Id);
        }

        return $media;

    } #end process
} #end function ResolveLabMedia


function Get-LabMedia {
<#
    .SYNOPSIS
        Gets registered lab media.
    .DESCRIPTION
        The Get-LabMedia cmdlet retrieves all built-in and registered custom media.
    .PARAMETER Id
        Specifies the specific media Id to return.
    .PARAMETER CustomOnly
        Specifies that only registered custom media are returned.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        ## Media ID
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Id,

        ## Only return custom media
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $CustomOnly
    )
    process {

        ## Retrieve built-in media
        if (-not $CustomOnly) {

            $defaultMedia = GetConfigurationData -Configuration Media;
        }
        ## Retrieve custom media
        $customMedia = @(GetConfigurationData -Configuration CustomMedia);
        if (-not $customMedia) {

            $customMedia = @();
        }

        ## Are we looking for a specific media Id
        if ($Id) {

            ## Return the custom media definition first (if it exists)
            $media = $customMedia | Where-Object { $_.Id -eq $Id };
            if ((-not $media) -and (-not $CustomOnly)) {

                ## We didn't find a custom media entry, return a default entry (if it exists)
                $media = $defaultMedia | Where-Object { $_.Id -eq $Id };
            }
        }
        else {

            ## Return all custom media
            $media = $customMedia;
            if (-not $CustomOnly) {

                foreach ($mediaEntry in $defaultMedia) {

                    ## Determine whether the media is present in the custom media, i.e. make sure
                    ## we don't override a custom entry with the default one.
                    $defaultMediaEntry = $customMedia | Where-Object { $_.Id -eq $mediaEntry.Id }
                    ## If not, add it to the media array to return
                    if (-not $defaultMediaEntry) {

                        $media += $mediaEntry;
                    }
                } #end foreach default media
            } #end if not custom only
        }

        foreach ($mediaObject in $media) {

            $mediaObject.PSObject.TypeNames.Insert(0, 'VirtualEngine.Lability.Media');
            Write-Output -InputObject $mediaObject;
        }

    } #end process
} #end function Get-LabMedia


function Test-LabMedia {
<#
    .SYNOPSIS
        Tests whether lab media has already been successfully downloaded.
    .DESCRIPTION
        The Test-LabMedia cmdlet will check whether the specified media Id has been downloaded and its checksum is correct.
    .PARAMETER Id
        Specifies the media Id to test.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Id
    )
    process {

        $hostDefaults = GetConfigurationData -Configuration Host;
        $media = Get-LabMedia -Id $Id;
        if ($media) {

            if (-not $hostDefaults.DisableLocalFileCaching) {

                $testResourceDownloadParams = @{
                    DestinationPath = Join-Path -Path $hostDefaults.IsoPath -ChildPath $media.Filename;
                    Uri = $media.Uri;
                    Checksum = $media.Checksum;
                }
                return TestResourceDownload @testResourceDownloadParams;
            }
            else {

                ## Local file resource caching is disabled
                return $true;
            }
        }
        else {

            return $false;
        }

    } #end process
} #end function Test-LabMedia


function InvokeLabMediaImageDownload {
<#
    .SYNOPSIS
        Downloads ISO/WIM/VHDX media resources.
    .DESCRIPTION
        Initiates a download of a media resource. If the resource has already been downloaded and the checksum is
        correct, it won't be re-downloaded. To force download of a ISO/VHDX use the -Force switch.
    .NOTES
        ISO media is downloaded to the default IsoPath location. VHD(X) files are downloaded directly into the
        ParentVhdPath location.
#>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        ## Lab media object
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Object] $Media,

        ## Force (re)download of the resource
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {
        $hostDefaults = GetConfigurationData -Configuration Host;

        $invokeResourceDownloadParams = @{
            DestinationPath = Join-Path -Path $hostDefaults.IsoPath -ChildPath $media.Filename;
            Uri = $media.Uri;
            Checksum = $media.Checksum;
        }
        if ($media.MediaType -eq 'VHD') {

            $invokeResourceDownloadParams['DestinationPath'] = Join-Path -Path $hostDefaults.ParentVhdPath -ChildPath $media.Filename;
        }

        $mediaUri = New-Object -TypeName System.Uri -ArgumentList $Media.Uri;
        if ($mediaUri.Scheme -eq 'File') {

            ## Use a bigger buffer for local file copies..
            $invokeResourceDownloadParams['BufferSize'] = 1MB;
        }

        if ($media.MediaType -eq 'VHD') {

            ## Always download VHDXs regardless of Uri type
            [ref] $null = InvokeResourceDownload @invokeResourceDownloadParams -Force:$Force;
        }
        elseif (($mediaUri.Scheme -eq 'File') -and ($media.MediaType -eq 'WIM') -and $hostDefaults.DisableLocalFileCaching)
        ## TODO: elseif (($mediaUri.Scheme -eq 'File') -and $hostDefaults.DisableLocalFileCaching)
        {
            ## NOTE: Only WIM media can currently be run from a file share (see https://github.com/VirtualEngine/Lab/issues/28)
            ## Caching is disabled and we have a file resource, so just return the source URI path
            WriteVerbose ($localized.MediaFileCachingDisabled -f $Media.Id);
            $invokeResourceDownloadParams['DestinationPath'] = $mediaUri.LocalPath;
        }
        else {

            ## Caching is enabled or it's a http/https source
            [ref] $null = InvokeResourceDownload @invokeResourceDownloadParams -Force:$Force;
        }
        return (Get-Item -Path $invokeResourceDownloadParams.DestinationPath);

    } #end process
} #end InvokeLabMediaImageDownload


function InvokeLabMediaHotfixDownload {
<#
    .SYNOPSIS
        Downloads resources.
    .DESCRIPTION
        Initiates a download of a media resource. If the resource has already been downloaded and the checksum
        is correct, it won't be re-downloaded. To force download of a ISO/VHDX use the -Force switch.
    .NOTES
        ISO/WIM media is downloaded to the default IsoPath location. VHD(X) files are downloaded directly into the
        ParentVhdPath location.
#>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Id,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Checksum,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {

        $hostDefaults = GetConfigurationData -Configuration Host;
        $destinationPath = Join-Path -Path $hostDefaults.HotfixPath -ChildPath $Id;
        $invokeResourceDownloadParams = @{
            DestinationPath = $destinationPath;
            Uri = $Uri;
        }
        if ($Checksum) {

            [ref] $null = $invokeResourceDownloadParams.Add('Checksum', $Checksum);
        }

        [ref] $null = InvokeResourceDownload @invokeResourceDownloadParams -Force:$Force;
        return (Get-Item -Path $destinationPath);

    } #end process
} #end function InvokeLabMediaHotfixDownload


function Register-LabMedia {
<#
    .SYNOPSIS
        Registers a custom media entry.
    .DESCRIPTION
        The Register-LabMedia cmdlet allows adding custom media to the host's configuration. This circumvents the requirement of having to define custom media entries in the DSC configuration document (.psd1).

        You can use the Register-LabMedia cmdlet to override the default media entries, e.g. you have the media hosted internally or you wish to replace the built-in media with your own implementation.

        To override a built-in media entry, specify the same media Id with the -Force switch.
    .LINK
        Get-LabMedia
        Unregister-LabMedia
#>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        ## Specifies the media Id to register. You can override the built-in media if required.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.String] $Id,

        ## Specifies the media's type.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('VHD','ISO','WIM')]
        [System.String] $MediaType,

        ## Specifies the source Uri (http/https/file) of the media.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.Uri] $Uri,

        ## Specifies the architecture of the media.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('x64','x86')]
        [System.String] $Architecture,

        ## Specifies a description of the media.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Description,

        ## Specifies the image name containing the target WIM image. You can specify integer values.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ImageName,

        ## Specifies the local filename of the locally cached resource file.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Filename,

        ## Specifies the MD5 checksum of the resource file.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Checksum,

        ## Specifies custom data for the media.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.Collections.Hashtable] $CustomData,

        ## Specifies additional Windows hotfixes to install post deployment.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.Collections.Hashtable[]] $Hotfixes,

        ## Specifies the media type. Linux VHD(X)s do not inject resources.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Windows','Linux')]
        [System.String] $OperatingSystem = 'Windows',

        ## Specifies that an exiting media entry should be overwritten.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {

        ## Validate Linux VM media type is VHD
        if (($OperatingSystem -eq 'Linux') -and ($MediaType -ne 'VHD')) {

            throw ($localized.InvalidOSMediaTypeError -f $MediaType, $OperatingSystem);
        }

        ## Validate ImageName when media type is ISO/WIM
        if (($MediaType -eq 'ISO') -or ($MediaType -eq 'WIM')) {

            if (-not $PSBoundParameters.ContainsKey('ImageName')) {

                throw ($localized.ImageNameRequiredError -f '-ImageName');
            }
        }

        ## Resolve the media Id to see if it's already been used
        $media = ResolveLabMedia -Id $Id -ErrorAction SilentlyContinue;
        if ($media -and (-not $Force)) {

            throw ($localized.MediaAlreadyRegisteredError -f $Id, '-Force');
        }

        ## Get the custom media list (not the built in media)
        $existingCustomMedia = @(GetConfigurationData -Configuration CustomMedia);
        if (-not $existingCustomMedia) {

            $existingCustomMedia = @();
        }

        $customMedia = [PSCustomObject] @{
            Id = $Id;
            Filename = $Filename;
            Description = $Description;
            Architecture = $Architecture;
            ImageName = $ImageName;
            MediaType = $MediaType;
            OperatingSystem = $OperatingSystem;
            Uri = $Uri;
            Checksum = $Checksum;
            CustomData = $CustomData;
            Hotfixes = $Hotfixes;
        }

        $hasExistingMediaEntry = $false;
        for ($i = 0; $i -lt $existingCustomMedia.Count; $i++) {

            if ($existingCustomMedia[$i].Id -eq $Id) {

                WriteVerbose ($localized.OverwritingCustomMediaEntry -f $Id);
                $hasExistingMediaEntry = $true;
                $existingCustomMedia[$i] = $customMedia;
            }
        }

        if (-not $hasExistingMediaEntry) {

            ## Add it to the array
            WriteVerbose ($localized.AddingCustomMediaEntry -f $Id);
            $existingCustomMedia += $customMedia;
        }

        WriteVerbose ($localized.SavingConfiguration -f $Id);
        SetConfigurationData -Configuration CustomMedia -InputObject @($existingCustomMedia);
        return $customMedia;

    } #end process
} #end function Register-LabMedia


function Unregister-LabMedia {
<#
    .SYNOPSIS
        Unregisters a custom media entry.
    .DESCRIPTION
        The Unregister-LabMedia cmdlet allows removing custom media entries from the host's configuration.
    .LINK
        Get-LabMedia
        Register-LabMedia
#>
    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideDefaultParameterValue', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        ## Specifies the custom media Id to unregister. You cannot unregister the built-in media.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [System.String] $Id
    )
    process {

        ## Get the custom media list
        $customMedia = GetConfigurationData -Configuration CustomMedia;
        if (-not $customMedia) {

            ## We don't have anything defined
            WriteWarning ($localized.NoCustomMediaFoundWarning -f $Id);
            return;
        }
        else {

            ## Check if we have a matching Id
            $media = $customMedia | Where-Object { $_.Id -eq $Id };
            if (-not $media) {
                ## We don't have a custom matching Id registered
                WriteWarning ($localized.NoCustomMediaFoundWarning -f $Id);
                return;
            }
        }

        $shouldProcessMessage = $localized.PerformingOperationOnTarget -f 'Unregister-LabMedia', $Id;
        $verboseProcessMessage = $localized.RemovingCustomMediaEntry -f $Id;
        if ($PSCmdlet.ShouldProcess($verboseProcessMessage, $shouldProcessMessage, $localized.ShouldProcessWarning)) {

            $customMedia = $customMedia | Where-Object { $_.Id -ne $Id };
            WriteVerbose ($localized.SavingConfiguration -f $Id);
            SetConfigurationData -Configuration CustomMedia -InputObject @($customMedia);
            return $media;
        }

    } #end process
} #end function Unregister-LabMedia


function Reset-LabMedia {
<#
    .SYNOPSIS
        Reset the lab media entries to default settings.
    .DESCRIPTION
        The Reset-LabMedia removes all custom media entries, reverting them to default values.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    param ( )
    process {

        RemoveConfigurationData -Configuration CustomMedia;
        Get-Labmedia;

    }
} #end function Reset-LabMedia
