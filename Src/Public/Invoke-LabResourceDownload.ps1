function Invoke-LabResourceDownload {
<#
    .SYNOPSIS
        Starts a download of all required lab resources.
    .DESCRIPTION
        When a lab configuration is started, Lability will attempt to download all the required media and resources.

        In some scenarios you many need to download lab resources in advance, e.g. where internet access is not
        readily available or permitted. The `Invoke-LabResourceDownload` cmdlet can be used to manually download
        all required resources or specific media/resources as needed.
    .PARAMETER ConfigurationData
        Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
    .PARAMETER All
        Specifies all media, custom and DSC resources should be downloaded.
    .PARAMETER MediaId
        Specifies the specific media IDs to download.
    .PARAMETER ResourceId
        Specifies the specific custom resource IDs to download.
    .PARAMETER Media
        Specifies all media IDs should be downloaded.
    .PARAMETER Resources
        Specifies all custom resource IDs should be downloaded.
    .PARAMETER DSCResources
        Specifies all defined DSC resources should be downloaded.
    .PARAMETER Moduless
        Specifies all defined PowerShell modules should be downloaded.
    .PARAMETER Force
        Forces a download of all resources, overwriting any existing resources.
    .PARAMETER DestinationPath
        Specifies the target destination path of downloaded custom resources (not media or DSC resources).
    .EXAMPLE
        Invoke-LabResourceDownload -ConfigurationData ~\Documents\MyLab.psd1 -All

        Downloads all required lab media, any custom resources and DSC resources defined in the 'MyLab.psd1' configuration.
    .EXAMPLE
        Invoke-LabResourceDownload -ConfigurationData ~\Documents\MyLab.psd1 -MediaId 'WIN10_x64_Enterprise_EN_Eval'

        Downloads only the 'WIN10_x64_Enterprise_EN_Eval' media.
    .EXAMPLE
        Invoke-LabResourceDownload -ConfigurationData ~\Documents\MyLab.psd1 -ResourceId 'MyCustomResource'

        Downloads only the 'MyCustomResource' resource defined in the 'MyLab.psd1' configuration.
    .EXAMPLE
        Invoke-LabResourceDownload -ConfigurationData ~\Documents\MyLab.psd1 -Media

        Downloads only the media defined in the 'MyLab.psd1' configuration.
    .EXAMPLE
        Invoke-LabResourceDownload -ConfigurationData ~\Documents\MyLab.psd1 -Resources -DSCResources

        Downloads only the custom file resources and DSC resources defined in the 'MyLab.psd1' configuration.
#>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
         $ConfigurationData = @{ },

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [System.Management.Automation.SwitchParameter] $All,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'MediaId')]
        [System.String[]] $MediaId,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ResourceId')]
        [System.String[]] $ResourceId,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Media')]
        [System.Management.Automation.SwitchParameter] $Media,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Resources')]
        [System.Management.Automation.SwitchParameter] $Resources,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'DSCResources')]
        [System.Management.Automation.SwitchParameter] $DSCResources,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Modules')]
        [System.Management.Automation.SwitchParameter] $Modules,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Resources')]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ResourceId')]
        [ValidateNotNullOrEmpty()]
        [System.String] $DestinationPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    begin {

        $hostDefaults = Get-ConfigurationData -Configuration Host;
        if (-not $DestinationPath) {
            $DestinationPath = $hostDefaults.ResourcePath;
        }

    }
    process {

        if ($PSCmdlet.ParameterSetName -in 'MediaId','Media','All') {

            if (-not $MediaId) {

                Write-Verbose -Message ($Localized.DownloadingAllRequiredMedia);
                $uniqueMediaIds = @();
                $ConfigurationData.AllNodes.Where({ $_.NodeName -ne '*' }) | ForEach-Object {
                    $id = (Resolve-NodePropertyValue -NodeName $_.NodeName -ConfigurationData $ConfigurationData).Media;
                    if ($uniqueMediaIds -notcontains $id) { $uniqueMediaIds += $id; }
                }
                $MediaId = $uniqueMediaIds;
            }

            if ($MediaId) {

                foreach ($id in $MediaId) {

                    $labMedia = Resolve-LabMedia -ConfigurationData $ConfigurationData -Id $id;
                    Invoke-LabMediaImageDownload -Media $labMedia -Force:$Force;

                    Write-Verbose -Message $Localized.DownloadingAllRequiredHotfixes;
                    if ($labMedia.Hotfixes.Count -gt 0) {
                        foreach ($hotfix in $labMedia.Hotfixes) {
                            Invoke-LabMediaDownload -Id $hotfix.Id -Uri $hotfix.Uri;
                        }
                    }
                    else {
                        Write-Verbose -Message ($localized.NoHotfixesSpecified);
                    }
                }

            }
            else {
                Write-Verbose -Message ($localized.NoMediaDefined);
            }

        } #end if MediaId or MediaOnly

        if ($PSCmdlet.ParameterSetName -in 'ResourceId','Resources','All') {

            if (-not $ResourceId) {

                Write-Verbose -Message ($Localized.DownloadingAllDefinedResources);
                $ResourceId = $ConfigurationData.NonNodeData.$($labDefaults.ModuleName).Resource.Id;
            }

            if (($ResourceId.Count -gt 0) -and (-not $MediaOnly)) {

                foreach ($id in $ResourceId) {

                    $resource = Resolve-LabResource -ConfigurationData $ConfigurationData -ResourceId $id;
                    if (($null -eq $resource.IsLocal) -or ($resource.IsLocal -eq $false)) {

                        $fileName = $resource.Id;
                        if ($resource.Filename) { 
                            if ($resource.DownloadToFolder) {
                                $fileName = $fileName + "\" + $resource.Filename
                            } else {
                                $fileName = $resource.Filename
                            }
                        }
                        $resourceDestinationPath = Join-Path -Path $DestinationPath -ChildPath $fileName;
                        $invokeResourceDownloadParams = @{
                            DestinationPath = $resourceDestinationPath;
                            Uri = $resource.Uri;
                            Checksum = $resource.Checksum;
                            Force = $Force;
                        }
                        [ref] $null = Invoke-ResourceDownload @invokeResourceDownloadParams;
                        Write-Output (Get-Item -Path $resourceDestinationPath);
                    }
                }
            }
            else {

                Write-Verbose -Message ($localized.NoResourcesDefined);
            }

        } #end if ResourceId or ResourceOnly

        if ($PSCmdlet.ParameterSetName -in 'DSCResources','All') {

            $dscResourceDefinitions = $ConfigurationData.NonNodeData.$($labDefaults.ModuleName).DSCResource;
            if (($null -ne $dscResourceDefinitions) -and ($dscResourceDefinitions.Count -gt 0)) {

                ## Invokes download of DSC resource modules into the module cache
                Write-Verbose -Message ($Localized.DownloadingAllDSCResources);
                Invoke-LabModuleCacheDownload -Module $dscResourceDefinitions -Force:$Force;
            }
            else {
                Write-Verbose -Message ($localized.NoDSCResourcesDefined);
            }
        } #end if DSC resource

        if ($PSCmdlet.ParameterSetName -in 'Modules','All') {

            $moduleDefinitions = $ConfigurationData.NonNodeData.$($labDefaults.ModuleName).Module;
            if (($null -ne $moduleDefinitions) -and ($moduleDefinitions.Count -gt 0)) {

                ## Invokes download of PowerShell modules into the module cache
                Write-Verbose -Message ($Localized.DownloadingAllPowerShellModules);
                Invoke-LabModuleCacheDownload -Module $moduleDefinitions -Force:$Force;
            }
            else {
                Write-Verbose -Message ($localized.NoPowerShellModulesDefined);
            }

        } #end PowerShell module

    } #end process
} #end function
