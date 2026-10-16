<#
.SYNOPSIS
    Fails when code or config still points to upstream (Klocman) servers or links.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Endpoints.psm1') -Force
$hits = @(Find-ForbiddenEndpoint -Root (Split-Path -Parent $PSScriptRoot))
if ($hits.Count -gt 0) {
    Write-Host 'Endpoint guard FAILED:'
    $hits | ForEach-Object { Write-Host ("  {0}:{1}  {2}" -f $_.File, $_.Line, $_.Text) }
    exit 1
}
Write-Host 'Endpoint guard passed.'
