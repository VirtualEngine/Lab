function New-LabMedia {
<#
    .SYNOPSIS
        Creates a new lab media object.
    .DESCRIPTION
        Permits validation of custom NonNodeData\Lability\Media entries.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
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
        [System.Boolean] $DownloadToFolder,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Boolean] $CopyToFolder,
    
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.String] $ImageName = '',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('ISO','VHD','WIM','NULL')]
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

            if ($MediaType -ne 'NULL') {

                $resolvedUri = New-Object -TypeName 'System.Uri' -ArgumentList $Uri;
                if ($resolvedUri.Scheme -notin 'http','https','file') {
                    throw ($localized.UnsupportedUriSchemeError -f $resolvedUri.Scheme);
                }
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
            DownloadToFolder = $DownloadToFolder;
            CopyToFolder = $CopyToFolder;
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
} #end function
