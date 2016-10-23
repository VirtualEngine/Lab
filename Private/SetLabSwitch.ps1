﻿function SetLabSwitch {

<#
    .SYNOPSIS
        Sets/invokes a virtual network switch configuration.
    .DESCRIPTION
        Sets/invokes a virtual network switch configuration using the xVMSwitch DSC resource.
#>
    [CmdletBinding()]
    param (
        ## Switch Id/Name
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.String] $Name,

        ## PowerShell DSC configuration document (.psd1) containing lab metadata.
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {
        $networkSwitch = ResolveLabSwitch @PSBoundParameters;
        if (($null -eq $networkSwitch.IsExisting) -or ($networkSwitch.IsExisting -eq $false)) {
            ImportDscResource -ModuleName xHyper-V -ResourceName MSFT_xVMSwitch -Prefix VMSwitch;
            [ref] $null = InvokeDscResource -ResourceName VMSwitch -Parameters $networkSwitch;
        }
    } #end process

}

