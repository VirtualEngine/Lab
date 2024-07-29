function Get-LabHostDscConfigurationPath {
<#
    .SYNOPSIS
        Shortcut function to resolve the host's default ConfigurationPath property
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param ( )
    process {

        $labHostDefaults = Get-ConfigurationData -Configuration Host;
        return $labHostDefaults.ConfigurationPath;

    } #end process
} #end function Get-LabHostDscConfigurationPath
