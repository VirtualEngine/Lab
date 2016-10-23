﻿function ExpandLabResource {

<#
    .SYNOPSIS
        Copies files, e.g. EXEs, ISOs and ZIP file resources into a lab VM's mounted VHDX differencing disk image.
    .NOTES
        VHDX should already be mounted and passed in via the $DestinationPath parameter
        Can expand ISO and ZIP files if the 'Expand' property is set to $true on the resource's properties.
#>
    param (
        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData,

        ## Lab VM name
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        ## Destination mounted VHDX path to expand resources into
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath,

        ## Source resource path
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ResourcePath
    )
    begin {

        if (-not $ResourcePath) {

            $hostDefaults = GetConfigurationData -Configuration Host;
            $ResourcePath = $hostDefaults.ResourcePath;
        }

    }
    process {

        ## Create the root destination (\Resources) container
        if (-not (Test-Path -Path $DestinationPath -PathType Container)) {

            [ref] $null = New-Item -Path $DestinationPath -ItemType Directory -Force;
        }

        $node = ResolveLabVMProperties -NodeName $Name -ConfigurationData $ConfigurationData -ErrorAction Stop;
        foreach ($resourceId in $node.Resource) {

            WriteVerbose ($localized.AddingResource -f $resourceId);
            $resource = ResolveLabResource -ConfigurationData $ConfigurationData -ResourceId $resourceId;

            ## Default to resource.Id unless there is a filename property defined!
            $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Id;

            if ($resource.Filename) {

                $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Filename;
                if ($resource.IsLocal) {

                    $resourceSourcePath = Resolve-Path -Path $resource.Filename;
                }
            }

            if (-not (Test-Path -Path $resourceSourcePath) -and (-not $resource.IsLocal)) {

                $invokeLabResourceDownloadParams = @{
                    ConfigurationData = $ConfigurationData;
                    ResourceId = $resourceId;
                }
                [ref] $null = Invoke-LabResourceDownload @invokeLabResourceDownloadParams;
            }

            if (-not (Test-Path -Path $resourceSourcePath)) {

                throw ($localized.CannotResolveResourceIdError -f $resourceId);
            }

            $resourceItem = Get-Item -Path $resourceSourcePath;
            $resourceDestinationPath = $DestinationPath;

            if ($resource.DestinationPath -and (-not [System.String]::IsNullOrEmpty($resource.DestinationPath))) {

                $destinationDrive = Split-Path -Path $DestinationPath -Qualifier;
                $resourceDestinationPath = Join-Path -Path $destinationDrive -ChildPath $resource.DestinationPath;

                ## We can't create a drive-rooted folder!
                if (($resource.DestinationPath -ne '\') -and (-not (Test-Path -Path $resourceDestinationPath))) {

                    [ref] $null = New-Item -Path $resourceDestinationPath -ItemType Directory -Force;
                }
            }
            elseif ($resource.IsLocal -and ($resource.IsLocal -eq $true)) {

                $relativeLocalPath = ($resource.Filename).TrimStart('.');
                $resourceDestinationPath = Join-Path -Path $DestinationPath -ChildPath $relativeLocalPath;
            }

            if (($resource.Expand) -and ($resource.Expand -eq $true)) {

                if ([System.String]::IsNullOrEmpty($resource.DestinationPath)) {

                    ## No explicit destination path, so expand into the <DestinationPath>\<ResourceId> folder
                    $resourceDestinationPath = Join-Path -Path $DestinationPath -ChildPath $resource.Id;
                }

                if (-not (Test-Path -Path $resourceDestinationPath)) {

                    [ref] $null = New-Item -Path $resourceDestinationPath -ItemType Directory -Force;
                }

                switch ([System.IO.Path]::GetExtension($resourceSourcePath)) {

                    '.iso' {

                        ExpandIso -Path $resourceItem.FullName -DestinationPath $resourceDestinationPath;
                    }

                    '.zip' {

                        WriteVerbose ($localized.ExpandingZipResource -f $resourceItem.FullName);
                        $expandZipArchiveParams = @{
                            Path = $resourceItem.FullName;
                            DestinationPath = $resourceDestinationPath;
                            Verbose = $false;
                        }
                        [ref] $null = ExpandZipArchive @expandZipArchiveParams;
                    }

                    Default {

                        throw ($localized.ExpandNotSupportedError -f $resourceItem.Extension);
                    }

                } #end switch
            }
            else {

                WriteVerbose ($localized.CopyingFileResource -f $resourceDestinationPath);
                $copyItemParams = @{
                    Path = "$($resourceItem.FullName)";
                    Destination = "$resourceDestinationPath";
                    Force = $true;
                    Recurse = $true;
                    Verbose = $false;
                }
                Copy-Item @copyItemParams;
            }

        } #end foreach ResourceId

    } #end process

}

