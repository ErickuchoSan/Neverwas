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

function Invoke-Rebrand {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][hashtable]$Rules,
        [switch]$Check
    )
    $Root = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')

    $literalByFile = @{}
    foreach ($rule in @($Rules.Literal)) {
        if (-not $literalByFile.ContainsKey($rule.File)) { $literalByFile[$rule.File] = @() }
        $literalByFile[$rule.File] += $rule
    }

    $files = @{}
    foreach ($rel in $literalByFile.Keys) { $files[$rel] = $true }
    $sourceDir = Join-Path $Root 'source'
    if (Test-Path -LiteralPath $sourceDir) {
        Get-ChildItem -LiteralPath $sourceDir -Recurse -Filter '*.resx' -File |
            Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
            ForEach-Object { $files[$_.FullName.Substring($Root.Length + 1).Replace('\', '/')] = $true }
    }

    $changed = New-Object System.Collections.Generic.List[string]
    foreach ($rel in ($files.Keys | Sort-Object)) {
        $path = Join-Path $Root $rel
        if (-not (Test-Path -LiteralPath $path)) { throw "Rebrand rule points to missing file: $rel" }
        $file = Read-TextFile -Path $path
        $text = $file.Text
        if ($literalByFile.ContainsKey($rel)) { $text = Convert-LiteralRules -Text $text -Rules $literalByFile[$rel] -File $rel }
        if ($rel.EndsWith('.resx')) { $text = Convert-ResxBrand -Text $text -ValueRules @($Rules.ResxValue) }
        if ($text -cne $file.Text) {
            $changed.Add($rel)
            if (-not $Check) { Write-TextFile -Path $path -Text $text -Encoding $file.Encoding }
        }
    }
    $changed.ToArray()
}

Export-ModuleMember -Function Read-TextFile, Write-TextFile, Convert-ResxBrand, Convert-LiteralRules, Invoke-Rebrand
