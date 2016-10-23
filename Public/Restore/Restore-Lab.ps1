﻿function Restore-Lab {

<#
    .SYNOPSIS
        Restores all lab VMs to a previous configuration.
    .DESCRIPTION
        The Restore-Lab reverts all the nodes defined in a PowerShell DSC configuration document, back to a
        previously captured configuration.

        When creating the snapshots, they are created using a snapshot name. To restore a lab to a previous
        configuration, you must supply the same snapshot name.

        All virtual machines should be powered off when the snapshots are restored. If VMs are powered on,
        an error will be generated. You can override this behaviour by specifying the -Force parameter.

        WARNING: If the -Force parameter is used, running virtual machines will be powered off automatically.
    .PARAMETER ConfigurationData
        Specifies a PowerShell DSC configuration data hashtable or a path to an existing PowerShell DSC .psd1
        configuration document.
    .PARAMETER SnapshotName
        Specifies the virtual machine snapshot name to be restored. You must use the same snapshot name used when
        creating the snapshot with the Checkpoint-Lab cmdlet.
    .PARAMETER Force
        Forces virtual machine snapshots to be restored - even if there are any running virtual machines.
    .LINK
        Checkpoint-Lab
        Reset-Lab
#>
    [CmdletBinding()]
    param (
        ## Lab DSC configuration data
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Collections.Hashtable]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformationAttribute()]
        $ConfigurationData,

        ## Snapshot name
        [Parameter(Mandatory)] [Alias('Name')]
        [System.String] $SnapshotName,

        ## Force snapshots if virtual machines are on
        [System.Management.Automation.SwitchParameter] $Force
    )
    process {
        $nodes = @();
        $ConfigurationData.AllNodes |
            Where-Object { $_.NodeName -ne '*' } |
                ForEach-Object {
                    $nodes += ResolveLabVMProperties -NodeName $_.NodeName -ConfigurationData $ConfigurationData;
                };
        $runningNodes = $nodes | ForEach-Object {
            Get-VM -Name $_.NodeDisplayName } |
                Where-Object { $_.State -ne 'Off' }

        $currentNodeCount = 0;
        if ($runningNodes -and $Force) {
            $nodes | Sort-Object { $_.BootOrder } |
                ForEach-Object {
                    $currentNodeCount++;
                    [System.Int32] $percentComplete = ($currentNodeCount / $nodes.Count) * 100;
                    $activity = $localized.ConfiguringNode -f $_.NodeDisplayName;
                    Write-Progress -Id 42 -Activity $activity -PercentComplete $percentComplete;
                    WriteVerbose ($localized.RestoringVirtualMachineSnapshot -f $_.NodeDisplayName,  $SnapshotName);

                    GetLabVMSnapshot -Name $_.NodeDisplayName -SnapshotName $SnapshotName | Restore-VMSnapshot;
                }
        }
        elseif ($runningNodes) {
            foreach ($runningNode in $runningNodes) {
                Write-Error -Message ($localized.CannotSnapshotNodeError -f $runningNode.NodeDisplayName);
            }
        }
        else {
            $nodes | Sort-Object { $_.BootOrder } |
                ForEach-Object {
                    $currentNodeCount++;
                    [System.Int32] $percentComplete = ($currentNodeCount / $nodes.Count) * 100;
                    $activity = $localized.ConfiguringNode -f $_.NodeDisplayName;
                    Write-Progress -Id 42 -Activity $activity -PercentComplete $percentComplete;
                    WriteVerbose ($localized.RestoringVirtualMachineSnapshot -f $_.NodeDisplayName,  $SnapshotName);

                    GetLabVMSnapshot -Name $_.NodeDisplayName -SnapshotName $SnapshotName | Restore-VMSnapshot -Confirm:$false;
                }
        }
        Write-Progress -Id 42 -Activity $activity -Completed;
    } #end process

}

