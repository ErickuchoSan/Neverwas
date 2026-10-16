Set-StrictMode -Version 2.0

function Read-TextFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 2 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
        throw "Rebrand does not support UTF-16 files: $Path"
    }
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    # Throwing decoder: invalid bytes must fail loudly, not become U+FFFD and get written back.
    $encoding = New-Object System.Text.UTF8Encoding($hasBom, $true)
    $offset = 0
    if ($hasBom) { $offset = 3 }
    try {
        $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
    }
    catch [System.Text.DecoderFallbackException] {
        throw "Rebrand only supports UTF-8 files; $Path is not valid UTF-8"
    }
    [pscustomobject]@{ Text = $text; Encoding = $encoding }
}

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][System.Text.Encoding]$Encoding
    )
    [IO.File]::WriteAllText($Path, $Text, $Encoding)
}

function Convert-ResxBrand {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$ValueRules
    )
    $dataEvaluator = {
        param($dataMatch)
        $attrs = $dataMatch.Groups['attrs'].Value
        # Typed and binary resources (images, icons, ResXFileRef) carry base64 or type names: never touch them.
        if ($attrs -cmatch '\s(type|mimetype)\s*=') { return $dataMatch.Value }
        $valueEvaluator = {
            param($valueMatch)
            $value = $valueMatch.Groups['v'].Value
            foreach ($rule in $ValueRules) {
                if ($rule.Regex) { $value = [regex]::Replace($value, $rule.Find, $rule.Replace) }
                else { $value = $value.Replace($rule.Find, $rule.Replace) }
            }
            '<value>' + $value + '</value>'
        }
        $body = [regex]::Replace($dataMatch.Groups['body'].Value, '(?s)<value>(?<v>.*?)</value>', $valueEvaluator)
        '<data' + $attrs + '>' + $body + '</data>'
    }
    # (?<!/) skips self-closing <data ... />, which would otherwise capture the next element's body.
    [regex]::Replace($Text, '(?s)<data\b(?<attrs>[^>]*)(?<!/)>(?<body>.*?)</data>', $dataEvaluator)
}

function Convert-LiteralRules {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][object[]]$Rules,
        [Parameter(Mandatory = $true)][string]$File
    )
    foreach ($rule in $Rules) {
        if ($Text.Contains($rule.Find)) {
            $Text = $Text.Replace($rule.Find, $rule.Replace)
        }
        elseif (-not $Text.Contains($rule.Replace)) {
            throw ("Rebrand rule broken in ${File}: neither '{0}' nor '{1}' was found. Upstream changed this line; update tools/rebrand-rules.psd1." -f $rule.Find, $rule.Replace)
        }
    }
    $Text
}

function Get-LiteralRulesByFile {
    param([Parameter(Mandatory = $true)][hashtable]$Rules)
    $byFile = @{}
    foreach ($rule in @($Rules.Literal)) {
        if (-not $byFile.ContainsKey($rule.File)) { $byFile[$rule.File] = @() }
        $byFile[$rule.File] += $rule
    }
    $byFile
}

function Get-SourceFiles {
    # Repo-relative, forward-slash paths of files under source/ with the given extensions, outside bin/ and obj/.
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$Extensions
    )
    $sourceDir = Join-Path $Root 'source'
    if (-not (Test-Path -LiteralPath $sourceDir)) { return @() }
    @(Get-ChildItem -LiteralPath $sourceDir -Recurse -File |
        Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
        ForEach-Object { $_.FullName.Substring($Root.Length + 1).Replace('\', '/') })
}

function Convert-FileBrand {
    # The in-memory result of the rebrand for one file: its literal rules first, then the resx value rules.
    param(
        [Parameter(Mandatory = $true)][string]$Rel,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][hashtable]$Rules,
        [Parameter(Mandatory = $true)][hashtable]$LiteralByFile
    )
    if ($LiteralByFile.ContainsKey($Rel)) { $Text = Convert-LiteralRules -Text $Text -Rules $LiteralByFile[$Rel] -File $Rel }
    if ($Rel.EndsWith('.resx')) { $Text = Convert-ResxBrand -Text $Text -ValueRules @($Rules.ResxValue) }
    $Text
}

function Invoke-Rebrand {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][hashtable]$Rules,
        [switch]$Check
    )
    $Root = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')
    $literalByFile = Get-LiteralRulesByFile -Rules $Rules

    $files = @{}
    foreach ($rel in $literalByFile.Keys) { $files[$rel] = $true }
    foreach ($rel in (Get-SourceFiles -Root $Root -Extensions @('.resx'))) { $files[$rel] = $true }

    $changed = New-Object System.Collections.Generic.List[string]
    foreach ($rel in ($files.Keys | Sort-Object)) {
        $path = Join-Path $Root $rel
        if (-not (Test-Path -LiteralPath $path)) { throw "Rebrand rule points to missing file: $rel" }
        $file = Read-TextFile -Path $path
        $text = Convert-FileBrand -Rel $rel -Text $file.Text -Rules $Rules -LiteralByFile $literalByFile
        if ($text -cne $file.Text) {
            $changed.Add($rel)
            if (-not $Check) { Write-TextFile -Path $path -Text $text -Encoding $file.Encoding }
        }
    }
    $changed.ToArray()
}

# Residual scan: brand names that survive every rule. Resx string values are checked loosely (any "bcu" or
# "bulk crap"); code is checked only inside string literals (whole lines for batch files), where text reaches the user.
$script:ResxResidualPattern = '(?i)bcu|bulk\s*crap'
$script:CodeResidualPattern = 'BCUninstaller|Bulk Crap|(?<![A-Za-z0-9_])BCU(?![A-Za-z0-9_])'
$script:CodeResidualExtensions = @('.cs', '.cpp', '.rc', '.bat')
$script:ResidualSkippedPrefix = 'source/BulkCrapUninstallerTests/'

function Hide-AllowedToken {
    # Masks allowlisted tokens with '#' of the same length, so match positions (and line numbers) stay valid.
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Allowlist
    )
    foreach ($token in $Allowlist) { $Text = $Text.Replace($token, (New-Object string ('#', $token.Length))) }
    $Text
}

function New-ResidualHit {
    param([string]$File, [string]$Text, [int]$Index)
    $lineStart = 0
    if ($Index -gt 0) { $lineStart = $Text.LastIndexOf([char]10, $Index - 1) + 1 }
    $lineEnd = $Text.IndexOf([char]10, $Index)
    if ($lineEnd -lt 0) { $lineEnd = $Text.Length }
    $line = $Text.Substring($lineStart, $lineEnd - $lineStart).Trim()
    if ($line.Length -gt 160) {
        $from = [Math]::Max(0, ($Index - $lineStart) - 60)
        $line = $Text.Substring($lineStart, $lineEnd - $lineStart).Substring($from).Trim()
        if ($line.Length -gt 160) { $line = $line.Substring(0, 160) }
    }
    $lineNumber = 1
    for ($i = $Text.IndexOf([char]10); $i -ge 0 -and $i -lt $Index; $i = $Text.IndexOf([char]10, $i + 1)) { $lineNumber++ }
    [pscustomobject]@{ File = $File; Line = $lineNumber; Text = $line }
}

function Find-ResxResidual {
    param([string]$File, [string]$Text, [string[]]$Allowlist)
    $hits = New-Object System.Collections.Generic.List[object]
    foreach ($data in [regex]::Matches($Text, '(?s)<data\b(?<attrs>[^>]*)(?<!/)>(?<body>.*?)</data>')) {
        if ($data.Groups['attrs'].Value -cmatch '\s(type|mimetype)\s*=') { continue }
        $body = $data.Groups['body']
        foreach ($value in [regex]::Matches($body.Value, '(?s)<value>(?<v>.*?)</value>')) {
            $v = $value.Groups['v']
            $m = [regex]::Match((Hide-AllowedToken -Text $v.Value -Allowlist $Allowlist), $script:ResxResidualPattern)
            if ($m.Success) { $hits.Add((New-ResidualHit -File $File -Text $Text -Index ($body.Index + $v.Index + $m.Index))) }
        }
    }
    $hits.ToArray()
}

function Find-CodeResidual {
    param([string]$File, [string]$Text, [string[]]$Allowlist)
    $hits = New-Object System.Collections.Generic.List[object]
    $isBatch = $File.EndsWith('.bat')
    $lines = $Text.Split("`n")
    for ($n = 0; $n -lt $lines.Length; $n++) {
        $line = $lines[$n].TrimEnd("`r")
        $trimmed = $line.TrimStart()
        if ($trimmed.StartsWith('//')) { continue }
        if ($isBatch -and ($trimmed.StartsWith('::') -or $trimmed -match '^(?i)@?rem(\s|$)')) { continue }
        $masked = Hide-AllowedToken -Text $line -Allowlist $Allowlist
        if ($isBatch) { $spans = @($masked) }
        else { $spans = @([regex]::Matches($masked, '"(?:[^"\\]|\\.)*"') | ForEach-Object { $_.Value }) }
        foreach ($span in $spans) {
            if ($span -cmatch $script:CodeResidualPattern) {
                $hits.Add([pscustomobject]@{ File = $File; Line = $n + 1; Text = $line.Trim() })
                break
            }
        }
    }
    $hits.ToArray()
}

function Read-ScanText {
    # Read-only decode for the residual scan: strict UTF-8 first; otherwise BOM detection (UTF-16) or Windows-1252.
    # Safe because the scan never writes; files the rebrand writes still go through the strict Read-TextFile.
    param([Parameter(Mandatory = $true)][string]$Path)
    try { return (Read-TextFile -Path $Path).Text }
    catch {
        $reader = New-Object System.IO.StreamReader($Path, [System.Text.Encoding]::GetEncoding(1252), $true)
        try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
    }
}

function Find-BrandResidual {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][hashtable]$Rules
    )
    $Root = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')
    $literalByFile = Get-LiteralRulesByFile -Rules $Rules
    $allowlist = [string[]]@($Rules.ResidualAllowlist | Where-Object { $_ })

    $files = @(Get-SourceFiles -Root $Root -Extensions (@('.resx') + $script:CodeResidualExtensions))
    if (Test-Path -LiteralPath (Join-Path $Root 'publish.bat')) { $files += 'publish.bat' }

    $hits = New-Object System.Collections.Generic.List[object]
    foreach ($rel in ($files | Where-Object { -not $_.StartsWith($script:ResidualSkippedPrefix) } | Sort-Object)) {
        $text = Convert-FileBrand -Rel $rel -Text (Read-ScanText -Path (Join-Path $Root $rel)) -Rules $Rules -LiteralByFile $literalByFile
        if ($rel.EndsWith('.resx')) {
            if ($text -notmatch $script:ResxResidualPattern) { continue }
            foreach ($hit in (Find-ResxResidual -File $rel -Text $text -Allowlist $allowlist)) { $hits.Add($hit) }
        }
        else {
            if ($text -cnotmatch $script:CodeResidualPattern) { continue }
            foreach ($hit in (Find-CodeResidual -File $rel -Text $text -Allowlist $allowlist)) { $hits.Add($hit) }
        }
    }
    $hits.ToArray()
}

Export-ModuleMember -Function Read-TextFile, Write-TextFile, Convert-ResxBrand, Convert-LiteralRules, Invoke-Rebrand, Find-BrandResidual
