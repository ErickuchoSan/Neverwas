@{
    # Literal rules: File + exact Find -> Replace. Each Find must exist, or its Replace must already be there.
    Literal = @(
        @{ File = 'source/BulkCrapUninstaller/BulkCrapUninstaller.csproj'; Find = '<AssemblyName>BCUninstaller</AssemblyName>'; Replace = '<AssemblyName>Neverwas</AssemblyName>' }
        @{ File = 'source/BulkCrapUninstaller/BulkCrapUninstaller.csproj'; Find = '<Product>Bulk Crap Uninstaller</Product>'; Replace = '<Product>Neverwas</Product>' }
        @{ File = 'source/BCU-console/BCU-console.csproj'; Find = '<Product>Command Line Interface for Bulk Crap Uninstaller</Product>'; Replace = '<Product>Command Line Interface for Neverwas</Product><AssemblyName>neverwas-cli</AssemblyName>' }
        @{ File = 'source/BCU-console/Program.cs'; Find = 'BCU-console '; Replace = 'neverwas-cli ' }
        @{ File = 'source/BulkCrapUninstaller/Program.cs'; Find = 'const string exeName = "BCUninstaller";'; Replace = 'const string exeName = "Neverwas";' }
        @{ File = 'source/BulkCrapUninstaller/CultureConfigurator.cs'; Find = '"BCUninstaller.resources.dll"'; Replace = '"Neverwas.resources.dll"' }
        @{ File = 'source/BulkCrapUninstaller/EntryPoint.cs'; Find = '@"Global\BCU-singleinstance"'; Replace = '@"Global\Neverwas-singleinstance"' }
        @{ File = 'source/BulkCrapUninstaller/EntryPoint.cs'; Find = 'BCUninstaller is already running'; Replace = 'Neverwas is already running' }
        @{ File = 'source/BulkCrapUninstaller/EntryPoint.cs'; Find = 'one instance of BCUninstaller.'; Replace = 'one instance of Neverwas.' }
        @{ File = 'source/BulkCrapUninstaller/EntryPoint.cs'; Find = 'see the BCUninstaller window'; Replace = 'see the Neverwas window' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Windows/UninstallProgressWindow.cs'; Find = '" - Bulk Crap Uninstaller"'; Replace = '" - Neverwas"' }
        @{ File = 'source/BulkCrapUninstaller/Functions/MessageBoxes.cs'; Find = 'latest version of BCUninstaller?'; Replace = 'latest version of Neverwas?' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Windows/JunkRemoveWindow.cs'; Find = '"BCU Backup "'; Replace = '"Neverwas Backup "' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Windows/MainWindow.cs'; Find = 'echo BCU Generated batch uninstall script'; Replace = 'echo Neverwas Generated batch uninstall script' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Helpers/FeedbackWindow.cs'; Find = 'http://klocmansoftware.weebly.com/feedback--contact.html'; Replace = 'https://github.com/ErickuchoSan/Neverwas/discussions' }
        @{ File = 'source/BulkCrapUninstaller/Functions/Tools/UpdateGrabber.cs'; Find = 'Klocman/Bulk-Crap-Uninstaller'; Replace = 'ErickuchoSan/Neverwas' }
        @{ File = 'source/BulkCrapUninstaller/Properties/Resources.resx'; Find = 'Klocman/Bulk-Crap-Uninstaller'; Replace = 'ErickuchoSan/Neverwas' }
        @{ File = 'source/BulkCrapUninstaller/Properties/Resources.resx'; Find = 'ErickuchoSan/Neverwas/blob/master/'; Replace = 'ErickuchoSan/Neverwas/blob/main/' }
        @{ File = 'source/BulkCrapUninstaller/Properties/Resources.resx'; Find = 'http://klocmansoftware.weebly.com/donate.html'; Replace = 'https://github.com/ErickuchoSan/Neverwas' }
        @{ File = 'source/BulkCrapUninstaller/Properties/Resources.resx'; Find = 'https://dappcdn.com/download/utilities/bulk-crap-uninstaller'; Replace = 'https://github.com/ErickuchoSan/Neverwas#readme' }
        @{ File = 'source/BulkCrapUninstaller/Properties/Resources.resx'; Find = 'Check+out+this+cool+uninstaller+that+I+found!+sourceforge.net/projects/bulk-crap-uninstaller/'; Replace = 'Check+out+Neverwas,+a+free+uninstaller!+github.com/ErickuchoSan/Neverwas' }
        @{ File = 'source/NBug_custom/Handler.cs'; Find = 'BCU from running'; Replace = 'Neverwas from running' }
        @{ File = 'source/NBug_custom/Handler.cs'; Find = 'BCUninstaller'; Replace = 'Neverwas' }
        @{ File = 'source/BCU-launcher/main.cpp'; Find = 'BCUninstaller'; Replace = 'Neverwas' }
        @{ File = 'source/BCU-launcher/BCU-launcher.rc'; Find = 'BCUninstaller'; Replace = 'Neverwas' }
    )

    # Resx rules: applied inside <value> of plain string <data> elements only, in this order.
    ResxValue = @(
        @{ Find = 'BCUninstaller (Bulk Crap Uninstaller)'; Replace = 'Neverwas'; Regex = $false }
        @{ Find = 'http://klocmansoftware.weebly.com/'; Replace = 'https://github.com/ErickuchoSan/Neverwas/discussions'; Regex = $false }
        @{ Find = 'Bulk Crap Uninstaller'; Replace = 'Neverwas'; Regex = $false }
        @{ Find = 'BCUninstaller'; Replace = 'Neverwas'; Regex = $false }
        @{ Find = '\bBCU\b'; Replace = 'Neverwas'; Regex = $true }
    )
}
