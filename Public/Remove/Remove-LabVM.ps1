﻿function Remove-LabVM {

<#
    .SYNOPSIS
        Removes a bare-metal virtual machine and differencing VHD(X).
    .DESCRIPTION
        The Remove-LabVM cmdlet removes a virtual machine and it's VHD(X) file.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        ## Virtual machine name
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Name,

        ## Specifies a PowerShell DSC configuration document (.psd1) containing the lab configuration.
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData
    )
    process {

        $currentNodeCount = 0;
        foreach ($vmName in $Name) {

            $shouldProcessMessage = $localized.PerformingOperationOnTarget -f 'Remove-LabVM', $vmName;
            $verboseProcessMessage = GetFormattedMessage -Message ($localized.RemovingVM -f $vmName);
            if ($PSCmdlet.ShouldProcess($verboseProcessMessage, $shouldProcessMessage, $localized.ShouldProcessWarning)) {

                $currentNodeCount++;
                [System.Int32] $percentComplete = (($currentNodeCount / $Name.Count) * 100) - 1;
                $activity = $localized.ConfiguringNode -f $vmName;
                Write-Progress -Id 42 -Activity $activity -PercentComplete $percentComplete;

                ## Create a skeleton config data if one wasn't supplied
                if (-not $PSBoundParameters.ContainsKey('ConfigurationData')) {

                    $configurationData = @{
                        AllNodes = @(
                            @{  NodeName = $vmName; }
                        )
                    };
                }

                RemoveLabVM -Name $vmName -ConfigurationData $configurationData;
            } #end if should process
        } #end foreach VM

        if (-not [System.String]::IsNullOrEmpty($activity)) {

            Write-Progress -Id 42 -Activity $activity -PercentComplete $percentComplete;
        }

    } #end process

}

