$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $here 'Endpoints.psm1') -Force

Describe 'Find-ForbiddenEndpoint' {
    function New-Tree {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        foreach ($d in 'source\App', 'source\App\obj', 'installer', 'docs', '.superpowers\sdd') { New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null }
        $root
    }

    It 'finds an upstream endpoint in code' {
        $root = New-Tree
        Set-Content (Join-Path $root 'source\App\A.cs') -Value @('var a = 1;', 'var u = "http://bugsklocman.ddns.net:7721";')
        $hits = @(Find-ForbiddenEndpoint -Root $root)
        $hits.Count | Should Be 1
        $hits[0].File | Should Be 'source/App/A.cs'
        $hits[0].Line | Should Be 2
    }
    It 'finds upstream links in resx values' {
        $root = New-Tree
        Set-Content (Join-Path $root 'source\App\R.resx') -Value '<data name="L"><value>https://github.com/Klocman/Bulk-Crap-Uninstaller/issues</value></data>'
        @(Find-ForbiddenEndpoint -Root $root).Count | Should Be 1
    }
    It 'finds the renamed org and homepage' {
        $root = New-Tree
        Set-Content (Join-Path $root 'source\App\A.cs') -Value 'var u = "https://github.com/BCUninstaller/Bulk-Crap-Uninstaller";'
        Set-Content (Join-Path $root 'source\App\R.resx') -Value '<value>https://www.bcuninstaller.com/</value>'
        @(Find-ForbiddenEndpoint -Root $root).Count | Should Be 2
    }
    It 'ignores comment lines' {
        $root = New-Tree
        Set-Content (Join-Path $root 'source\App\A.cs') -Value @('    // was http://bugsklocman.ddns.net', '/// similar to http://klocmansoftware.weebly.com/', ' * dappcdn')
        @(Find-ForbiddenEndpoint -Root $root).Count | Should Be 0
    }
    It 'ignores excluded folders and file types' {
        $root = New-Tree
        Set-Content (Join-Path $root 'source\App\obj\G.cs') -Value 'bugsklocman'
        Set-Content (Join-Path $root 'installer\Setup.iss') -Value 'Klocman/Bulk-Crap-Uninstaller'
        Set-Content (Join-Path $root 'docs\x.json') -Value 'dappcdn'
        Set-Content (Join-Path $root '.superpowers\sdd\x.json') -Value 'bugsklocman'
        Set-Content (Join-Path $root 'README.md') -Value 'Klocman/Bulk-Crap-Uninstaller'
        @(Find-ForbiddenEndpoint -Root $root).Count | Should Be 0
    }
}
