$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $here 'Rebrand.psm1') -Force
$rules = Import-PowerShellDataFile (Join-Path $here 'rebrand-rules.psd1')

Describe 'rebrand-rules.psd1' {
    It 'defines literal and resx rules' {
        @($rules.Literal).Count | Should BeGreaterThan 0
        @($rules.ResxValue).Count | Should BeGreaterThan 0
    }
    It 'never has a literal replacement that contains its own search text' {
        @($rules.Literal | Where-Object { $_.Replace.Contains($_.Find) }).Count | Should Be 0
    }
    It 'never has a resx replacement that re-matches any resx rule' {
        foreach ($rule in $rules.ResxValue) {
            foreach ($other in $rules.ResxValue) {
                if ($other.Regex) { $rule.Replace | Should Not Match $other.Find }
                else { $rule.Replace.Contains($other.Find) | Should Be $false }
            }
        }
    }
    It 'uses repo-relative forward-slash paths' {
        @($rules.Literal | Where-Object { $_.File -match '\\' -or $_.File -match '^[A-Za-z]:' }).Count | Should Be 0
    }
}
