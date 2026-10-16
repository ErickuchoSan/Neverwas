Set-StrictMode -Version 2.0

$script:Patterns = @('bugsklocman', 'klocmansoftware', 'Klocman/Bulk-Crap-Uninstaller', 'BCUninstaller/Bulk-Crap-Uninstaller', 'bcuninstaller.com', 'dappcdn')
$script:Extensions = @('.cs', '.resx', '.cpp', '.h', '.rc', '.csproj', '.vcxproj', '.props', '.targets', '.config', '.json', '.yml', '.yaml', '.bat')
$script:ExcludedDirs = @('.git', '.superpowers', 'bin', 'obj', 'tools', 'docs', 'doc', 'installer')

function Find-ForbiddenEndpoint {
    param([Parameter(Mandatory = $true)][string]$Root)
    $Root = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')
    $hits = New-Object System.Collections.Generic.List[object]
    $files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
        $script:Extensions -contains $_.Extension.ToLowerInvariant() -and
        -not (($_.FullName.Substring($Root.Length + 1) -split '[\\/]' | Select-Object -SkipLast 1) | Where-Object { $script:ExcludedDirs -contains $_ })
    }
    foreach ($file in $files) {
        $lineNumber = 0
        foreach ($line in [IO.File]::ReadAllLines($file.FullName)) {
            $lineNumber++
            $trimmed = $line.TrimStart()
            if ($trimmed.StartsWith('//') -or $trimmed.StartsWith('*') -or $trimmed.StartsWith('/*') -or $trimmed.StartsWith('<!--')) { continue }
            foreach ($pattern in $script:Patterns) {
                if ($line.IndexOf($pattern, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $hits.Add([pscustomobject]@{ File = $file.FullName.Substring($Root.Length + 1).Replace('\', '/'); Line = $lineNumber; Text = $line.Trim() })
                    break
                }
            }
        }
    }
    $hits.ToArray()
}

Export-ModuleMember -Function Find-ForbiddenEndpoint
