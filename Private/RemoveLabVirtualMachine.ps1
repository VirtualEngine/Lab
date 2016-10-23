﻿function RemoveLabVirtualMachine {

<#
    .SYNOPSIS
        Removes the current configuration a virtual machine.
    .DESCRIPTION
        Invokes/sets a virtual machine configuration using the xVMHyperV DSC resource.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Name,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String[]] $SwitchName,

        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()]
        [System.String] $Media,

        [Parameter(Mandatory)]
        [System.UInt64] $StartupMemory,

        [Parameter(Mandatory)]
        [System.UInt64] $MinimumMemory,

        [Parameter(Mandatory)]
        [System.UInt64] $MaximumMemory,

        [Parameter(Mandatory)]
        [System.Int32] $ProcessorCount,

        [Parameter()] [AllowNull()]
        [System.String[]] $MACAddress,

        [Parameter()]
        [System.Boolean] $SecureBoot,

        [Parameter()]
        [System.Boolean] $GuestIntegrationServices,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {
        if ($PSCmdlet.ShouldProcess($Name)) {
            ## Resolve the xVMHyperV resource parameters
            $vmHyperVParams = GetVirtualMachineProperties @PSBoundParameters;
            $vmHyperVParams['Ensure'] = 'Absent';
            ImportDscResource -ModuleName xHyper-V -ResourceName MSFT_xVMHyperV -Prefix VM;
            InvokeDscResource -ResourceName VM -Parameters $vmHyperVParams -ErrorAction SilentlyContinue;
        }
    } #end process

}

