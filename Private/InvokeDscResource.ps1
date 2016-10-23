﻿function InvokeDscResource {

<#
    .SYNOPSIS
        Runs the ResourceName DSC resource ensuring it's in the desired state.
    .DESCRIPTION
        The InvokeDscResource cmdlet invokes the target $ResourceName\Test-TargetResource function using the supplied
        $Parameters hastable. If the resource is not in the desired state, the $ResourceName\Set-TargetResource
        function is called with the $Parameters hashtable to attempt to correct the resource.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.String] $ResourceName,

        [Parameter(Mandatory)]
        [System.Collections.Hashtable] $Parameters
    )
    process {

        if (-not (TestDscResource @PSBoundParameters)) {
            if ($ResourceName -match 'PendingReboot') {
                throw $localized.PendingRebootWarning;
            }
            return (SetDscResource @PSBoundParameters);
        }
        else {
            $setTargetResourceCommand = 'Set-{0}TargetResource' -f $ResourceName;
            WriteVerbose ($localized.SkippingCommand -f $setTargetResourceCommand);
        }

    } #end process

}

