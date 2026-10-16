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
        @{ File = 'source/BulkCrapUninstaller/CleanLogs.bat'; Find = 'title Removing BCU log files'; Replace = 'title Removing Neverwas log files' }
        @{ File = 'source/BulkCrapUninstaller/CleanLogs.bat'; Find = 'BCUninstaller'; Replace = 'Neverwas' }
        @{ File = 'publish.bat'; Find = '"%publish%\BCUninstaller.exe"'; Replace = '"%publish%\Neverwas.exe"' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Windows/JunkRemoveWindow.Designer.cs'; Find = '"New BCUninstaller Junk Export"'; Replace = '"New Neverwas Junk Export"' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Windows/MainWindow.Designer.cs'; Find = '"New BCUninstaller Export"'; Replace = '"New Neverwas Export"' }
        @{ File = 'source/BulkCrapUninstaller/Properties/Resources.resx'; Find = 'https://www.bcuninstaller.com/'; Replace = 'https://github.com/ErickuchoSan/Neverwas' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Windows/JunkRemoveWindow.cs'; Find = 'adding BCU to exclusions'; Replace = 'adding Neverwas to exclusions' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Helpers/DebugWindow.cs'; Find = '"BCU RESTORE POINT TEST "'; Replace = '"NEVERWAS RESTORE POINT TEST "' }
        @{ File = 'source/BulkCrapUninstaller/Forms/Helpers/DebugWindow.Designer.cs'; Find = '"Override BCU is installed"'; Replace = '"Override Neverwas is installed"' }
        @{ File = 'source/UninstallTools/Factory/InfoAdders/FastSizeGenerator.cs'; Find = 'valid BCU directory size'; Replace = 'valid Neverwas directory size' }
        @{ File = 'source/KlocTools/Tools/RegistryTools.cs'; Find = 'Path.Combine(temp, "BCU")'; Replace = 'Path.Combine(temp, "Neverwas")' }
        @{ File = 'source/BCU-console/BCU-console.csproj'; Find = "offers some of BCU's functionality"; Replace = "offers some of Neverwas's functionality" }
        @{ File = 'source/ScriptHelper/ScriptHelper.csproj'; Find = 'registry tweaks and scripts to BCU'; Replace = 'registry tweaks and scripts to Neverwas' }
        @{ File = 'source/UniversalUninstaller/UniversalUninstaller.csproj'; Find = 'Utility used by BCU in place'; Replace = 'Utility used by Neverwas in place' }
    )

    # Resx rules: applied inside <value> of plain string <data> elements only, in this order.
    ResxValue = @(
        @{ Find = 'BCUninstaller (Bulk Crap Uninstaller)'; Replace = 'Neverwas'; Regex = $false }
        @{ Find = 'http://klocmansoftware.weebly.com/'; Replace = 'https://github.com/ErickuchoSan/Neverwas/discussions'; Regex = $false }
        @{ Find = 'Bulk Crap Uninstaller'; Replace = 'Neverwas'; Regex = $false }
        @{ Find = 'BCUninstaller'; Replace = 'Neverwas'; Regex = $false }
        # Upstream typos of the product name (the boundary rule below does not catch them).
        @{ Find = 'delBCU'; Replace = 'del Neverwas'; Regex = $false }
        @{ Find = 'BCUininstaller'; Replace = 'Neverwas'; Regex = $false }
        @{ Find = 'BCUinstaller'; Replace = 'Neverwas'; Regex = $false }
        # ASCII-bounded instead of a word boundary: .NET treats CJK/Hangul letters as word chars, so a plain boundary misses them.
        @{ Find = '(?<![A-Za-z0-9_])BCU(?![A-Za-z0-9_])'; Replace = 'Neverwas'; Regex = $true }
    )
}
