$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $here 'Rebrand.psm1') -Force

$valueRules = @(
    @{ Find = 'BCUninstaller (Bulk Crap Uninstaller)'; Replace = 'Neverwas'; Regex = $false },
    @{ Find = 'Bulk Crap Uninstaller'; Replace = 'Neverwas'; Regex = $false },
    @{ Find = 'BCUninstaller'; Replace = 'Neverwas'; Regex = $false },
    @{ Find = '\bBCU\b'; Replace = 'Neverwas'; Regex = $true }
)

Describe 'Convert-ResxBrand' {
    It 'replaces brand inside plain string values' {
        $in = '<data name="A" xml:space="preserve"><value>Uninstall BCUninstaller</value></data>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules |
            Should Be '<data name="A" xml:space="preserve"><value>Uninstall Neverwas</value></data>'
    }
    It 'replaces the long form before the short form' {
        $in = '<data name="A"><value>BCUninstaller (Bulk Crap Uninstaller)</value></data>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules |
            Should Be '<data name="A"><value>Neverwas</value></data>'
    }
    It 'rewrites the assembly name in type-qualified values' {
        $in = '<data name="&gt;&gt;x.Type" xml:space="preserve"><value>BulkCrapUninstaller.Controls.Foo, BCUninstaller, Culture=neutral, PublicKeyToken=null</value></data>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules |
            Should Be '<data name="&gt;&gt;x.Type" xml:space="preserve"><value>BulkCrapUninstaller.Controls.Foo, Neverwas, Culture=neutral, PublicKeyToken=null</value></data>'
    }
    It 'replaces BCU only as a whole word' {
        $in = '<data name="A"><value>Close BCU now. BCUX stays. aBCU stays.</value></data>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules |
            Should Be '<data name="A"><value>Close Neverwas now. BCUX stays. aBCU stays.</value></data>'
    }
    It 'leaves typed and binary resources untouched' {
        $in = '<data name="img" type="System.Drawing.Bitmap, System.Drawing" mimetype="application/x-microsoft.net.object.bytearray.base64"><value>AA/BCU+AA</value></data>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules | Should Be $in
    }
    It 'leaves data names, comments and metadata untouched' {
        $in = '<data name="BCU_Title"><value>x</value><comment>BCU</comment></data><metadata name="BCU"><value>BCU</value></metadata>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules | Should Be $in
    }
    It 'does not let a self-closing data element swallow the next one' {
        $in = '<data name="Empty" /><data name="img" type="System.Drawing.Bitmap, System.Drawing"><value>AA/BCU+AA</value></data>'
        Convert-ResxBrand -Text $in -ValueRules $valueRules | Should Be $in
    }
    It 'handles multi-line values' {
        $in = "<data name=`"A`"><value>Line one BCU`r`nLine two BCUninstaller</value></data>"
        Convert-ResxBrand -Text $in -ValueRules $valueRules |
            Should Be "<data name=`"A`"><value>Line one Neverwas`r`nLine two Neverwas</value></data>"
    }
    It 'is idempotent' {
        $in = '<data name="A"><value>BCUninstaller (Bulk Crap Uninstaller) and BCU</value></data>'
        $once = Convert-ResxBrand -Text $in -ValueRules $valueRules
        Convert-ResxBrand -Text $once -ValueRules $valueRules | Should Be $once
    }
}

Describe 'Convert-LiteralRules' {
    $rules = @(@{ File = 'a.cs'; Find = '"BCU Backup "'; Replace = '"Neverwas Backup "' })

    It 'replaces every occurrence' {
        Convert-LiteralRules -Text 'x("BCU Backup ") y("BCU Backup ")' -Rules $rules -File 'a.cs' |
            Should Be 'x("Neverwas Backup ") y("Neverwas Backup ")'
    }
    It 'is a no-op when the replacement is already present' {
        Convert-LiteralRules -Text 'x("Neverwas Backup ")' -Rules $rules -File 'a.cs' |
            Should Be 'x("Neverwas Backup ")'
    }
    It 'throws when neither text is present' {
        { Convert-LiteralRules -Text 'x("Other")' -Rules $rules -File 'a.cs' } |
            Should Throw 'Rebrand rule broken in a.cs'
    }
}

Describe 'Read-TextFile / Write-TextFile' {
    It 'round-trips UTF-8 with BOM and CRLF' {
        $p = Join-Path $TestDrive 'bom.txt'
        [IO.File]::WriteAllBytes($p, [byte[]](0xEF,0xBB,0xBF,0x61,0x0D,0x0A,0x62))
        $f = Read-TextFile -Path $p
        $f.Text | Should Be "a`r`nb"
        Write-TextFile -Path $p -Text $f.Text -Encoding $f.Encoding
        ([IO.File]::ReadAllBytes($p) -join ',') | Should Be '239,187,191,97,13,10,98'
    }
    It 'round-trips UTF-8 without BOM' {
        $p = Join-Path $TestDrive 'nobom.txt'
        [IO.File]::WriteAllBytes($p, [byte[]](0x61,0x0A))
        $f = Read-TextFile -Path $p
        Write-TextFile -Path $p -Text $f.Text -Encoding $f.Encoding
        ([IO.File]::ReadAllBytes($p) -join ',') | Should Be '97,10'
    }
    It 'refuses files that are not valid UTF-8' {
        $p = Join-Path $TestDrive 'latin1.txt'
        [IO.File]::WriteAllBytes($p, [byte[]](0x61,0xE9,0x62))
        { Read-TextFile -Path $p } | Should Throw 'not valid UTF-8'
    }
    It 'refuses UTF-16 files' {
        $p = Join-Path $TestDrive 'utf16.txt'
        [IO.File]::WriteAllBytes($p, [byte[]](0xFF,0xFE,0x61,0x00))
        { Read-TextFile -Path $p } | Should Throw 'UTF-16'
    }
}

Describe 'Invoke-Rebrand' {
    function New-Fixture {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'source\App') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'source\App\obj') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'source\App\Form.resx') -Value '<root><data name="T"><value>BCUninstaller</value></data></root>' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root 'source\App\obj\Gen.resx') -Value '<root><data name="T"><value>BCUninstaller</value></data></root>' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root 'source\App\Links.resx') -Value '<root><data name="D"><value>http://klocmansoftware.weebly.com/donate.html</value></data></root>' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root 'source\App\Code.cs') -Value 'const string exeName = "BCUninstaller";' -Encoding UTF8
        $root
    }
    $rules = @{
        Literal = @(
            @{ File = 'source/App/Code.cs'; Find = 'const string exeName = "BCUninstaller";'; Replace = 'const string exeName = "Neverwas";' },
            @{ File = 'source/App/Links.resx'; Find = 'http://klocmansoftware.weebly.com/donate.html'; Replace = 'https://github.com/ErickuchoSan/Neverwas' }
        )
        ResxValue = @(
            @{ Find = 'http://klocmansoftware.weebly.com/'; Replace = 'https://github.com/ErickuchoSan/Neverwas/discussions'; Regex = $false },
            @{ Find = 'BCUninstaller'; Replace = 'Neverwas'; Regex = $false }
        )
    }

    It 'reports pending files in -Check mode without writing' {
        $root = New-Fixture
        $changed = @(Invoke-Rebrand -Root $root -Rules $rules -Check)
        ($changed | Sort-Object) -join ';' | Should Be 'source/App/Code.cs;source/App/Form.resx;source/App/Links.resx'
        (Get-Content -LiteralPath (Join-Path $root 'source\App\Code.cs') -Raw) | Should Match 'BCUninstaller'
    }
    It 'applies changes and is clean on a second check' {
        $root = New-Fixture
        Invoke-Rebrand -Root $root -Rules $rules | Out-Null
        @(Invoke-Rebrand -Root $root -Rules $rules -Check).Count | Should Be 0
        (Get-Content -LiteralPath (Join-Path $root 'source\App\Code.cs') -Raw) | Should Match '"Neverwas"'
    }
    It 'runs literal rules before resx rules on the same file' {
        $root = New-Fixture
        Invoke-Rebrand -Root $root -Rules $rules | Out-Null
        (Get-Content -LiteralPath (Join-Path $root 'source\App\Links.resx') -Raw) |
            Should Match '<value>https://github.com/ErickuchoSan/Neverwas</value>'
    }
    It 'ignores resx files under bin and obj' {
        $root = New-Fixture
        Invoke-Rebrand -Root $root -Rules $rules | Out-Null
        (Get-Content -LiteralPath (Join-Path $root 'source\App\obj\Gen.resx') -Raw) | Should Match 'BCUninstaller'
    }
    It 'throws when a literal rule points to a missing file' {
        $root = New-Fixture
        $bad = @{ Literal = @(@{ File = 'source/App/Missing.cs'; Find = 'a'; Replace = 'b' }); ResxValue = @() }
        { Invoke-Rebrand -Root $root -Rules $bad -Check } | Should Throw 'missing file: source/App/Missing.cs'
    }
}

Describe 'Find-BrandResidual' {
    function New-Tree {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        foreach ($d in 'source\App', 'source\App\obj', 'source\BulkCrapUninstallerTests') { New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null }
        $root
    }
    function Set-File([string]$Root, [string]$Rel, [string[]]$Lines) {
        [IO.File]::WriteAllText((Join-Path $Root $Rel), ($Lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    }
    $noRules = @{ Literal = @(); ResxValue = @(); ResidualAllowlist = @('.bcul', 'BCU-console', 'BulkCrapUninstaller.') }

    It 'reports a brand name left in a resx string value, with file and line' {
        $root = New-Tree
        Set-File $root 'source\App\S.resx' @('<root>', '<data name="A" xml:space="preserve">', '  <value>Thanks for using BCUnintstaller!</value>', '</data></root>')
        $hits = @(Find-BrandResidual -Root $root -Rules $noRules)
        $hits.Count | Should Be 1
        $hits[0].File | Should Be 'source/App/S.resx'
        $hits[0].Line | Should Be 3
        $hits[0].Text | Should Match 'BCUnintstaller'
    }
    It 'applies the rules in memory before scanning, without writing' {
        $root = New-Tree
        Set-File $root 'source\App\S.resx' @('<root><data name="A"><value>Thanks for using BCUnintstaller!</value></data></root>')
        $fixed = @{ Literal = @(); ResxValue = @(@{ Find = 'BCUnintstaller'; Replace = 'Neverwas'; Regex = $false }); ResidualAllowlist = @() }
        @(Find-BrandResidual -Root $root -Rules $fixed).Count | Should Be 0
        [IO.File]::ReadAllText((Join-Path $root 'source\App\S.resx')) | Should Match 'BCUnintstaller'
    }
    It 'ignores typed resources, data names and comments' {
        $root = New-Tree
        Set-File $root 'source\App\S.resx' @('<root><data name="BCU_x" type="System.Byte[], mscorlib"><value>AABCUAA</value><comment>BCU</comment></data></root>')
        @(Find-BrandResidual -Root $root -Rules $noRules).Count | Should Be 0
    }
    It 'passes allowlisted tokens' {
        $root = New-Tree
        Set-File $root 'source\App\S.resx' @('<root><data name="A"><value>Default.bcul</value></data><data name="B"><value>BulkCrapUninstaller.Controls.X, Neverwas</value></data></root>')
        Set-File $root 'source\App\C.cs' @('var p = "BCU-console.exe";')
        @(Find-BrandResidual -Root $root -Rules $noRules).Count | Should Be 0
    }
    It 'reports a brand name in a code string literal' {
        $root = New-Tree
        Set-File $root 'source\App\C.cs' @('var a = 1;', 'var t = "Close BCU now";')
        $hits = @(Find-BrandResidual -Root $root -Rules $noRules)
        $hits.Count | Should Be 1
        $hits[0].File | Should Be 'source/App/C.cs'
        $hits[0].Line | Should Be 2
    }
    It 'ignores comments and code outside string literals' {
        $root = New-Tree
        Set-File $root 'source\App\C.cs' @('// "BCU" here', '    /// <summary>"Bulk Crap" docs</summary>', 'namespace BulkCrapUninstaller.Forms', 'var BCU = "Neverwas";')
        Set-File $root 'source\App\L.bat' @('REM Wait for BCU', 'rem Since BCU is new', ':: BCU', 'echo Neverwas')
        @(Find-BrandResidual -Root $root -Rules $noRules).Count | Should Be 0
    }
    It 'scans whole batch lines, including publish.bat at the root' {
        $root = New-Tree
        Set-File $root 'publish.bat' @('@echo off', 'echo Building BCU')
        $hits = @(Find-BrandResidual -Root $root -Rules $noRules)
        $hits.Count | Should Be 1
        $hits[0].File | Should Be 'publish.bat'
    }
    It 'scans code files that are not UTF-8 instead of failing (read-only, never written)' {
        $root = New-Tree
        [IO.File]::WriteAllBytes((Join-Path $root 'source\App\L.cs'), [byte[]](0x22,0x42,0x43,0x55,0x20,0xE9,0x22))
        [IO.File]::WriteAllBytes((Join-Path $root 'source\App\W.cs'), [byte[]](0xFF,0xFE,0x22,0x00,0x42,0x00,0x43,0x00,0x55,0x00,0x22,0x00))
        $hits = @(Find-BrandResidual -Root $root -Rules $noRules)
        ($hits | ForEach-Object { $_.File } | Sort-Object) -join ';' | Should Be 'source/App/L.cs;source/App/W.cs'
    }
    It 'skips the upstream test project and build output' {
        $root = New-Tree
        Set-File $root 'source\BulkCrapUninstallerTests\T.cs' @('var t = "BCU";')
        Set-File $root 'source\App\obj\G.cs' @('var t = "BCU";')
        @(Find-BrandResidual -Root $root -Rules $noRules).Count | Should Be 0
    }
}
