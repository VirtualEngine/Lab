function Expand-LabResource {
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

            $hostDefaults = Get-ConfigurationData -Configuration Host;
            $ResourcePath = $hostDefaults.ResourcePath;
        }

    }
    process {

        ## Create the root destination (\Resources) container
        if (-not (Test-Path -Path $DestinationPath -PathType Container)) {

            [ref] $null = New-Item -Path $DestinationPath -ItemType Directory -Force -Confirm:$false;
        }

        $node = Resolve-NodePropertyValue -NodeName $Name -ConfigurationData $ConfigurationData -ErrorAction Stop;
        foreach ($resourceId in $node.Resource) {

            Write-Verbose -Message ($localized.AddingResource -f $resourceId);
            $resource = Resolve-LabResource -ConfigurationData $ConfigurationData -ResourceId $resourceId;

            ## Default to resource.Id unless there is a filename property defined!
            $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Id;

            if ($resource.Filename) {
                
                if ($resource.DownloadToFolder -and $resource.Expand) {
                    $resourceSourcePath = Join-Path $resourcePath -ChildPath (Join-Path -Path $resource.Id -ChildPath $resource.Filename)
                } elseif ($resource.DownloadToFolder) {
                    $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Id
                } else {
                    $resourceSourcePath = Join-Path $resourcePath -ChildPath $resource.Filename;
                }
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

                    [ref] $null = New-Item -Path $resourceDestinationPath -ItemType Directory -Force  -Confirm:$false;
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

                    [ref] $null = New-Item -Path $resourceDestinationPath -ItemType Directory -Force -Confirm:$false;
                }

                switch ([System.IO.Path]::GetExtension($resourceSourcePath)) {

                    '.iso' {
                        Write-Verbose "Expand [$($resourceItem.FullName)] to [$resourceDestinationPath]"
                        Expand-LabIso -Path $resourceItem.FullName -DestinationPath $resourceDestinationPath;
                        break;
                    }

                    '.zip' {

                        Write-Verbose -Message ($localized.ExpandingZipResource -f $resourceItem.FullName);
                        $expandZipArchiveParams = @{
                            Path = $resourceItem.FullName;
                            DestinationPath = $resourceDestinationPath;
                            Verbose = $false;
                        }
                        [ref] $null = Expand-ZipArchive @expandZipArchiveParams;
                        break;
                    }

                    { $resource.DownloadToFolder } {
                        Write-Verbose "Copy [$resourceSourcePath] from [$($resourceItem.FullName)] to [$resourceDestinationPath]"
                        Copy-Item -Path $resourceItem.FullName $resourceDestinationPath -Recurse
                        break;
                    }

                    Default {

                        throw ($localized.ExpandNotSupportedError -f $resourceItem.Extension);
                    }

                } #end switch
            }
            else {

                Write-Verbose -Message ($localized.CopyingFileResource -f $resourceDestinationPath);
                $copyItemParams = @{
                    Path = "$($resourceItem.FullName)";
                    Destination = "$resourceDestinationPath";
                    Force = $true;
                    Recurse = $true;
                    Verbose = $false;
                    Confirm = $false;
                }
                Copy-Item @copyItemParams;
            }

        } #end foreach ResourceId

    } #end process
} #end function
