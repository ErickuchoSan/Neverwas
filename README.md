# Neverwas

Free, open-source uninstaller for Windows. Removes programs and the leftovers they
leave behind, in bulk or one at a time — as if they never were.

Neverwas is a fork of [Bulk Crap Uninstaller](https://github.com/Klocman/Bulk-Crap-Uninstaller)
by Marcin Szeniak, licensed under Apache 2.0. It keeps everything BCU does and is working
toward install tracking: recording what an installer changes so it can be undone exactly.

## Differences from BCU

- Own branding, settings file (`Neverwas.settings`) and update channel (this repo's releases).
- No crash reports, ratings or usage statistics are sent anywhere.

## Build

Requirements: Windows 10/11, Visual Studio 2022 or newer with the .NET desktop workload, .NET 8 runtime.

    msbuild source\BulkCrapUninstaller.sln /t:Restore;Build /p:Configuration=Release /p:Platform="Any CPU"
    dotnet test source\BulkCrapUninstallerTests\BulkCrapUninstallerTests.csproj -c Release --no-build

`dotnet build` alone does not work: the solution uses COM references.

## Syncing with upstream BCU

    git fetch upstream
    git switch -c chore/sync-upstream-vX.Y main
    git merge upstream/master
    # conflicts in .resx or in files listed in tools/rebrand-rules.psd1:
    git checkout --theirs -- <file>
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/rebrand.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/rebrand.ps1 -Check
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/check-endpoints.ps1

The version needs no manual edit: `source/Directory.Build.props` stays exactly as upstream has
it apart from one `<Import Project="Neverwas.props" />` line, and `source/Neverwas.props` appends
`.0.N` to upstream's `<Version>` (6.4 becomes 6.4.0.1). Bump `NeverwasRevision` there for
Neverwas-only releases, and set it back to 1 when syncing a new upstream version.

If you need to back out of a sync after `tools/rebrand.ps1` has rewritten files that the merge
staged, `git merge --abort` can fail. Use `git reset --hard` on the throwaway sync branch instead.

## License

Apache License 2.0 — see [Licence.txt](Licence.txt) and [NOTICE](NOTICE).
