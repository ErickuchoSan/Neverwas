<#
.SYNOPSIS
    Applies (or with -Check, verifies) the Neverwas branding over the upstream BCU tree.
.DESCRIPTION
    After merging upstream: take upstream's version of conflicting branded files, run this
    script, then run it again with -Check. Rules live in tools/rebrand-rules.psd1.
#>
[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'Rebrand.psm1') -Force
$rules = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'rebrand-rules.psd1')

$changed = @(Invoke-Rebrand -Root $root -Rules $rules -Check:$Check)

if ($Check) {
    if ($changed.Count -gt 0) {
        Write-Host 'Brand check FAILED. Files still carrying upstream branding:'
        $changed | ForEach-Object { Write-Host "  $_" }
        Write-Host 'Fix: powershell -NoProfile -ExecutionPolicy Bypass -File tools/rebrand.ps1'
        exit 1
    }
    Write-Host 'Brand check passed.'
    exit 0
}

Write-Host "Rebranded $($changed.Count) file(s)."
$changed | ForEach-Object { Write-Host "  $_" }
