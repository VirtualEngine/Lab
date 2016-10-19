### Lability ###
<img align="right" alt="Lability logo" src="https://raw.githubusercontent.com/VirtualEngine/Lability/dev/Lability.png">

The __Lability__ module enables simple provisioning of Windows Hyper-V development and
testing environments. It uses a declarative document for machine configuration.
However, rather than defining configurations in an external custom domain-specific
language (DSL) document, __Lability__ extends existing PowerShell Desired
State Configuration (DSC) configuration .psd1 documents with metadata that can
be interpreted by the module.

By using this approach, it allows the use of a single configuration document to
describe all properties for provisioning Windows-centric development and/or test
environments.

The __Lability__ module will parse the DSC configuration document and provision
Hyper-V virtual machines according to the metadata contained within. When invoked,
__Lability__ will parse a DSC configuration document and automagically
provision the following resources:
* Virtual machine disk images
 * Download required evaluation Operating System installation media
 * Expand Windows Image (WIM) image files into Sysprep'd virtual machine parent disks, including Server 2016 TP4 and Nano server
 * Apply required/recommended DSC Windows updates
* Virtual networks
 * Create internal and external Hyper-V switches
* Virtual machines
 * Connect to the correct virtual switches
 * Inject DSC resources from the host machine
 * Inject a dynamically created Unattend.xml file
 * Inject external ISO, EXE and ZIP resources
 * Inject the virtual machine's DSC document
 * Invoke the Local Configuration Manager (LCM) after Sysprep

An example DSC configuration document might look the following. Note: this is a
standard DSC .psd1 configuration document, but has been extended with specific
properties which the __Lability__ module can interpret.

```powershell
@{
    AllNodes = @(
		@{
			NodeName = 'DC1';
            Lability_ProcessorCount = 2;
			Lability_SwitchName = 'CORPNET';
			Lability_Media = '2012R2_x64_Standard_EN_Eval';
		},
		@{
			NodeName = 'APP1';
            Lability_ProcessorCount = 1;
			Lability_SwitchName = 'CORPNET';
			Lability_Media = '2012R2_x64_Standard_EN_Eval';
		}
	)
	NonNodeData = @{
        Lability = @{
            Network = @(
                @{ Name = 'CORPNET'; Type = 'Internal'; }
			)
		}
	}
}
```
When `Start-LabConfiguration` is invoked with the above configuration document, it
will:
* Create an internal Hyper-V virtual switch named 'CORPNET'
* Download required Server 2012 R2 Standard Edition evaluation media
 * Create a Sysprep'd Server 2012 R2 Standard Edition parent VHDX
 * Install required/recommended DSC hotfixes
* Provision two Hyper-V virtual machines called 'DC1' and 'APP1'
 * Each VM will be given 2GB RAM (configurable default)
 * 'DC1' will be assigned 2 virtual CPUs
 * 'APP1' will be assigned 1 virtual CPU
 * Attach each virtual machine to the 'CORPNET' virtual switch
 * Create differencing VHDX for each VM
 * Inject a dynamically created Unattend.xml file into the differencing VHDX

### Community Resources
A brief introduction to the __VirtualEngineLab__ module presented at the European
PowerShell Summit 2015 can be found __[here](https://www.youtube.com/watch?v=jefhLaJsG3E "Man vs TestLab")__.
Other generous members of the community have written some comprehensive guides to compliment the built-in documentation – thank you!

* [Building A Lab using Hyper-V and Lability](https://blog.kilasuit.org/2016/04/13/building-a-lab-using-hyper-v-and-lability-the-end-to-end-example/) via @kilasuit
* [The Ultimate Hyper-V Lab Tool](http://www.absolutejam.co.uk/posts/lability-the-ultimate-hyper-v-lab-tool/) via @absolutejam
* [Create Your Virtual Lab Environment with Lability How-To](http://blog.mscloud.guru/2016/09/17/create-your-virtual-lab-environment-with-lability-howto/) via @Naboo2604
* [Microsoft Channel 9 PSDEVOPS](https://channel9.msdn.com/Blogs/PSDEVOPSSIG/PSDEVOPSSIGEventLability-Demo-w-Iain-Brigton) presentation recording

## Versions

### Unreleased

* Updates bundled xHyper-V DSC resource module to 3.5.0.0
* Updates bundled xPendingReboot DSC resource module to 0.3.0.0

### v0.10.1

* Removes local Administrator password from verbose output (#140)
* Reinstates the xDhcpServerOption 'Router' parameter in example TestLabGuide.ps1
* Fixes bug in 'IsLocal' resource when combined with a custom 'DestinationPath' location
* Adds Server 2016 RTM (and deprecates Server 2016 technical preview) media
* Adds output formatting to lab images and media
* Adds descriptive error message for a missing WIM Image Name parameter (#148)
* Fixes bug where 'Hotfixes' in defined in configuration data (.psd1) media where not injected (#148)
* Adds Server 2016 RTM Nano Server support
* Fixes bug where media ProductKey entry was not specified in the generated unattend.xml (#134)
* Adds Windows ADK support to enable Win 10 and Server 2016 deployments on Win 8.1 and 2012 R2 hosts (#139)

### v0.10.0

* Updates Windows 10 media to build 14393 (1607).
* Adds `WIN10_x64_Enterprise_LTSB_EN_Eval` and `WIN10_x86_Enterprise_LTSB_EN_Eval` media.
 * Adds July 2016 CU hotfix (KB3163912) to Windows 10 x86 and x64 LTSB media.
* Adds June 2016 CU hotfix (KB3172982) to WS2016 TP5 default lab media registrations.
* Replaces Get-LabVMDefaults, Set-LabVMDefaults aliases with proxy functions with deprecation warning.
* Replaces Get-LabHostDefaults, Set-LabHostDefaults aliases with proxy functions with deprecation warning.
* Adds support for injecting modules in VMs (#106).
 * Caches multiple module and DSC resource versions.
 * Adds `-ModuleCachePath` to `Set-LabHostDefault`.
 * Adds `NonNodeData\Lability\Module = @()` and `Node\Lability_Module` support.
 * Adds `Provider = 'FileSystem'` support to DSC resource and PowerShell module definitions.
* Deprecates LabNode functionality (will move to the LabilityBootstrap module).
* As 'IsLocal' resource flag to support local-only resources, i.e. stored in version control.
* Fixes bug in VM test when multiple switches are specified on a node.

### v0.9.11

* Fixes bug in custom media enumeration in Start-LabConfiguration (#97).
* Removes importing module warnings when enumerating local module availability.
* Fixes bug when invoking lab deployments with PSake (#104).
* Adds Server 2016 Technical Preview 5 media.
* Fixes bug in Import-LabHostConfiguration where VM defaults contains reference to custom media.
* Fixes long local module enumeration times on build 14295 and later.
* Fixes hard-coded '\Program Files\' directory when enumerating modules to resolve localisation issues.
* Tests computer name for validity before creating a virtual machine (#109).

### v0.9.10

* Fixes bug where xHyperVM\Test-TargetResource throws if a VM's VHD has not been created.

### v0.9.9

* Removes boot delay in Stop-Lab.
* Adds GuestIntegrationServices support.
* Adds Write-Progress support to Reset-LabVM, New-LabVM, Remove-LabVM and Test-LabConfiguration.
* Adds -IgnorePendingReboot parameter to Start-LabConfiguration.
* Removes extraneous verbose output from Get-CimInstance in Test-LabHostConfiguration.
* Fixes bug in Test-LabVM where VM's prefixed name was not resolved causing calls to TestLabVMDisk and TestLabVirtualMachine to fail.
* Adds -Force switch to Stop-Lab to ensure that locked VMs do not prevent shutdown.
* Removes unused -UpdatePath parameter from Get/Set-LabHostDefault cmdlets (#77).
* Fixes bug in Get-LabVM where VMs' prefixed name was not resolved correctly (#89).
* Adds optional -ConfigurationData switch to Remove-LabVM to support prefixed configurations.
* Deprecates ConvertToConfigurationData function in favour of the native [ArgumentToConfigurationDataTransformationAttribute()].

### v0.9.8

* Fixes BandwidthReservationMode bug where duplicate 'Internal' virtual switches are created.
* Moves examples into the \Examples directory.
* Removes trailing space causing Resources.psd1 here string to not appear correctly in certain editors (like VS Code).
* Adds missing EnvironmentPrefix/Suffix support and tests to Start-Lab, Stop-Lab, Checkpoint-Lab and Restore-Lab.
* Adds Windows Management Framework v5 media IDs for Windows 8.1 and Server 2012 R2 evaluations.
* Updates bootstrap MOF encoding to Unicode and increases MaxEnvelopeSizekb to 1024Kb to support large .mof files.
* Adds Get-LabNodeResourceList and Show-LabNodeResourceList cmdlets to support bootstrapping manually configured VMs.
* Fixes bug in Quick VM switch creation always creating the switch using the default switch name.
* Adds Write-Progress output to -Lab and -LabConfiguration cmdlets.

### v0.9.7

* Adds backup and restore of the Lability host's settings:
 * New Export-LabHostConfiguration and Import-LabHostConfiguration cmdlets added.
* Adds environment prefix and suffix tagging:
 * Adds NonNodeData\Lability\EnvironmentPrefix and EnvironmentSuffix directives.
 * VM display names and VHD(X) files are named accordingly.
* Adds Linux VM support:
 * Custom media "OperatingSystem" property added.
 * Defaults to "Windows".
 * If "Linux" if specified, no resources are injected into the VM.
* Minor updates/fixes:
 * Renames LabHostDefaults.ps1 to LabHostDefault.ps1.
 * Renames LabVMDefaults.ps1 to LabVMDefault.ps1.
 * Adds -SecureBoot to Set-LabVMDefault.
 * Adds Generation property to LabMedia to ensure that VHD files result in Generation 1 VMs.
 * Documentation updates.

### v0.9.6

* Updates bundled DSC resources from PSGallery:
 * xHyper-V updated to v3.3.0.0.
 * xPendingReboot updated to v0.2.0.0.
* Minor updates/fixes:
 * Fixes parameter errors in WindowsFeature\Get-TargetResource calls (#62).
 * Suppresses SCCM client warning output in Get-LabHostConfiguration.
 * Changes Get-LabHostConfiguration output to PSObjects to improve readability.

### v0.9.5

* Minor updates/fixes:
 * Removes existing DSC resources in VM before copying local DSC resources.
 * Fixes VM generation bug when custom partition style is defined.
 * Fixes bug creating VMs from custom VHD media.
 * Updates bootstrap to remove existing DSC configurations and restart WMI.

### v0.9.4

* Adds DestinationPath directive to custom resources:
 * Permits specifying an alternative relative location than the default \Resources directory.
 * Explicitly exports all functions to allow auto-loading of the module.
* Minor updates/fixes:
 * Fixes bug expanding environment variables.

### v0.9.2

* Minor updates/fixes:
 * Fixes image enumeration with custom VHD media.

### v0.9.1

* Adds support for existing virtual switches:
 * Switches no longer need to be defined in the NonNodeData\Lability\Network configuration document.
 * If not defined, an existing virtual switch is used.
 * If there is no local virtual switch, an internal one is automatically created.
* Adds mutliple MAC address support.

### v0.9.0

* Renames module to Lability (#42).
* Adds NonNodeData\Lability\DSCResource directive:
 * Permits bootstrapping DSC resources from both the PSGallery and directly from Github.
* Adds manual node configuration:
 * Adds Test-LabNodeConfiguration cmdlet to test a node's configuration.
 * Adds Invoke-LabNodeConfiguration to install Lability certificates and download required DSC resources.


[__Lability__ image/logo attribution credit](https://openclipart.org/image/300px/svg_to_png/22734/papapishu-Lab-icon-1.png)
