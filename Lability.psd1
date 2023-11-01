@{
    RootModule        = 'Lability.psm1';
    ModuleVersion     = '0.25.0';
    GUID              = '374126b4-f3d4-471d-b25e-767f69ee03d0';
    Author            = 'Iain Brighton';
    CompanyName       = 'Virtual Engine';
    Copyright         = '(c) 2023 Virtual Engine Limited.';
    Description       = 'The Lability module contains cmdlets for provisioning Hyper-V test lab and development environments.';
    PowerShellVersion = '4.0';
    FormatsToProcess  = @('Lability.Format.ps1xml');
    FunctionsToExport = @(
                            'Checkpoint-Lab',
                            'Clear-LabModuleCache',
                            'Clear-ModulePath',
                            'Export-LabHostConfiguration',
                            'Export-LabImage',
                            'Get-LabHostConfiguration',
                            'Get-LabHostDefault',
                            'Get-LabImage',
                            'Get-LabMedia',
                            'Get-LabStatus',
                            'Get-LabVM',
                            'Get-LabVMDefault',
                            'Install-LabModule',
                            'Import-LabHostConfiguration',
                            'Invoke-LabResourceDownload',
                            'New-LabImage',
                            'New-LabVM',
                            'Register-LabMedia',
                            'Remove-LabConfiguration',
                            'Remove-LabVM',
                            'Reset-Lab',
                            'Reset-LabHostDefault',
                            'Reset-LabMedia',
                            'Reset-LabVM',
                            'Reset-LabVMDefault',
                            'Restore-Lab',
                            'Set-LabHostDefault',
                            'Set-LabVMDefault',
                            'Start-DscCompilation',
                            'Start-Lab',
                            'Start-LabConfiguration',
                            'Start-LabHostConfiguration',
                            'Stop-Lab',
                            'Test-LabConfiguration',
                            'Test-LabHostConfiguration',
                            'Test-LabImage',
                            'Test-LabMedia',
                            'Test-LabResource',
                            'Test-LabStatus',
                            'Test-LabVM',
                            'Unregister-LabMedia',
                            'Wait-Lab'
                        );
    CmdletsToExport = @(); # Suppresses exporting of imported the DISM cmdlets
    PrivateData = @{
        PSData = @{  # Private data to pass to the module specified in RootModule/ModuleToProcess
            Tags       = @('VirtualEngine','Lability','Powershell','Development','HyperV','Hyper-V','Test','Lab','TestLab');
            LicenseUri = 'https://github.com/VirtualEngine/Lability/blob/master/LICENSE';
            ProjectUri = 'https://github.com/VirtualEngine/Lability';
            IconUri    = 'https://raw.githubusercontent.com/VirtualEngine/Lability/master/Lability.png';
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
