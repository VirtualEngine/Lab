function Invoke-LabMediaImageDownload {
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
        [System.Object] $Media,

        ## Force (re)download of the resource
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {
        $hostDefaults = Get-ConfigurationData -Configuration Host;

        $invokeResourceDownloadParams = @{
            DestinationPath = if ($media.DownloadToFolder) { Join-Path -Path $hostDefaults.IsoPath -ChildPath (Join-Path -Path $media.Id -ChildPath $media.Filename); } else { Join-Path -Path $hostDefaults.IsoPath -ChildPath $media.Filename; }
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
            [ref] $null = Invoke-ResourceDownload @invokeResourceDownloadParams -Force:$Force;
        }
        elseif (($mediaUri.Scheme -eq 'File') -and ($media.MediaType -eq 'WIM') -and $hostDefaults.DisableLocalFileCaching)
        ## TODO: elseif (($mediaUri.Scheme -eq 'File') -and $hostDefaults.DisableLocalFileCaching)
        {
            ## NOTE: Only WIM media can currently be run from a file share (see https://github.com/VirtualEngine/Lab/issues/28)
            ## Caching is disabled and we have a file resource, so just return the source URI path
            Write-Verbose -Message ($localized.MediaFileCachingDisabled -f $Media.Id);
            $invokeResourceDownloadParams['DestinationPath'] = $mediaUri.LocalPath;
        }
        else {

            ## Caching is enabled or it's a http/https source
            [ref] $null = Invoke-ResourceDownload @invokeResourceDownloadParams -Force:$Force;
        }
        return (Get-Item -Path $invokeResourceDownloadParams.DestinationPath);

    } #end process
} #end function
