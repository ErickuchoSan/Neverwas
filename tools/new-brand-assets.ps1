<#
.SYNOPSIS
    Draws the Neverwas raster assets the app ships: logo.ico, 3.png and bigImage.bmp.
.DESCRIPTION
    Same geometry as the SVG masters in docs/brand/logo (built by docs/brand/build-masters.py);
    the brand manual is docs/brand/manual.html. Small icon sizes snap the symbol to whole pixels.

    logo.ico      exe, launcher and console icon; also the window icon (Resources.Icon_Logo).
                  16-256 px, 32bpp; DIB entries below 64 px, PNG from 64 px up.
    3.png         256x256 ARGB, transparent: the symbol alone (first-start wizard and splash).
    bigImage.bmp  164x314, 24bpp: vertical lockup in negative on the primary colour (About box).
#>
[CmdletBinding()]
param([string]$ResourcesPath)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
if (-not $ResourcesPath) { $ResourcesPath = Join-Path $root 'source\BulkCrapUninstaller\Resources' }

$primary = [System.Drawing.Color]::FromArgb(255, 0x66, 0x56, 0xF0)
$white = [System.Drawing.Color]::White
$fontPath = Join-Path $root 'docs\brand\fonts\Manrope-Bold.ttf'

function Get-Snapped {
    param([double]$Value, [bool]$Snap)
    if ($Snap) { return [math]::Round($Value, [MidpointRounding]::AwayFromZero) }
    $Value
}

function New-Symbol {
    # Tile: rounded square of side $Size at ($X, $Y), radius 3/14. N on the 14-unit tile: stems 2 wide
    # from y=2 to y=12, left stem at x=3, right stem ending at x=11 and running out through the top edge.
    param([double]$X, [double]$Y, [double]$Size, [bool]$Snap)
    $u = $Size / 14
    $stem = [math]::Max(1, (Get-Snapped (2 * $u) $Snap))
    $diagonal = $stem * 1.165
    $l0 = $X + (Get-Snapped (3 * $u) $Snap); $l1 = $l0 + $stem
    $r1 = $X + $Size - (Get-Snapped (3 * $u) $Snap); $r0 = $r1 - $stem
    $top = $Y + (Get-Snapped (2 * $u) $Snap); $bottom = $Y + $Size - (Get-Snapped (2 * $u) $Snap)
    $crossRight = $top + ($r0 - ($l0 + $diagonal)) / ($r1 - ($l0 + $diagonal)) * ($bottom - $top)
    $crossLeft = $top + ($l1 - $l0) / (($r1 - $diagonal) - $l0) * ($bottom - $top)
    $points = @(
        @($l0, $top), @(($l0 + $diagonal), $top), @($r0, $crossRight), @($r0, $Y), @($r1, $Y), @($r1, $bottom),
        @(($r1 - $diagonal), $bottom), @($l1, $crossLeft), @($l1, $bottom), @($l0, $bottom)
    ) | ForEach-Object { New-Object System.Drawing.PointF ([single]$_[0]), ([single]$_[1]) }

    $d = [single](6 * $u)
    $tile = New-Object System.Drawing.Drawing2D.GraphicsPath
    $tile.AddArc([single]$X, [single]$Y, $d, $d, 180, 90)
    $tile.AddArc([single]($X + $Size - $d), [single]$Y, $d, $d, 270, 90)
    $tile.AddArc([single]($X + $Size - $d), [single]($Y + $Size - $d), $d, $d, 0, 90)
    $tile.AddArc([single]$X, [single]($Y + $Size - $d), $d, $d, 90, 90)
    $tile.CloseFigure()
    [pscustomobject]@{ Tile = $tile; N = [System.Drawing.PointF[]]$points }
}

function Add-Symbol {
    # Paints the tile in $TileColor and the N in $NColor (white for the colour symbol; the background
    # colour for the negative one, where the N is a cut-out).
    param($Graphics, $Symbol, [System.Drawing.Color]$TileColor, [System.Drawing.Color]$NColor)
    $tileBrush = New-Object System.Drawing.SolidBrush $TileColor
    $nBrush = New-Object System.Drawing.SolidBrush $NColor
    $Graphics.FillPath($tileBrush, $Symbol.Tile)
    $Graphics.FillPolygon($nBrush, $Symbol.N)
    $tileBrush.Dispose(); $nBrush.Dispose(); $Symbol.Tile.Dispose()
}

function New-Canvas {
    param([int]$Width, [int]$Height, [System.Drawing.Imaging.PixelFormat]$Format)
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height, $Format
    $bitmap.SetResolution(96, 96)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    [pscustomobject]@{ Bitmap = $bitmap; Graphics = $graphics }
}

function New-IconFrame {
    # The symbol on a transparent square; the tile keeps a 1/16 margin like the 16 px grid.
    param([int]$Size)
    $canvas = New-Canvas $Size $Size ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $canvas.Graphics.Clear([System.Drawing.Color]::Transparent)
    $margin = [math]::Max(1, (Get-Snapped ($Size / 16) $true))
    Add-Symbol $canvas.Graphics (New-Symbol $margin $margin ($Size - 2 * $margin) $true) $primary $white
    $canvas.Graphics.Dispose()
    $canvas.Bitmap
}

function ConvertTo-DibBytes {
    # ICO DIB entry: BITMAPINFOHEADER (height doubled), bottom-up BGRA rows, then the 1bpp AND mask.
    param([System.Drawing.Bitmap]$Bitmap)
    $width = $Bitmap.Width; $height = $Bitmap.Height
    $rect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
    $data = $Bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $pixels = New-Object byte[] ($data.Stride * $height)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixels, 0, $pixels.Length)
    $stride = $data.Stride
    $Bitmap.UnlockBits($data)

    $maskStride = [int][math]::Ceiling($width / 32) * 4
    $stream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter $stream
    $writer.Write([UInt32]40); $writer.Write([Int32]$width); $writer.Write([Int32](2 * $height))
    $writer.Write([UInt16]1); $writer.Write([UInt16]32); $writer.Write([UInt32]0)
    $writer.Write([UInt32]($width * $height * 4 + $maskStride * $height))
    $writer.Write([Int32]0); $writer.Write([Int32]0); $writer.Write([UInt32]0); $writer.Write([UInt32]0)
    for ($y = $height - 1; $y -ge 0; $y--) { $writer.Write($pixels, $y * $stride, $width * 4) }
    for ($y = $height - 1; $y -ge 0; $y--) {
        $row = New-Object byte[] $maskStride
        for ($x = 0; $x -lt $width; $x++) {
            if ($pixels[$y * $stride + $x * 4 + 3] -eq 0) { $row[[math]::Floor($x / 8)] = $row[[math]::Floor($x / 8)] -bor (0x80 -shr ($x % 8)) }
        }
        $writer.Write($row)
    }
    $writer.Flush()
    $bytes = $stream.ToArray()
    $writer.Dispose()
    , $bytes
}

function Write-Icon {
    param([string]$Path, [int[]]$Sizes)
    $images = New-Object System.Collections.Generic.List[byte[]]
    foreach ($size in $Sizes) {
        $frame = New-IconFrame $size
        if ($size -ge 64) {
            $png = New-Object System.IO.MemoryStream
            $frame.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
            $images.Add($png.ToArray()); $png.Dispose()
        }
        else { $images.Add((ConvertTo-DibBytes $frame)) }
        $frame.Dispose()
    }
    # ICO layout: ICONDIR (6 bytes) + one ICONDIRENTRY (16 bytes) per image + image data.
    $output = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter $output
    $writer.Write([UInt16]0); $writer.Write([UInt16]1); $writer.Write([UInt16]$Sizes.Count)
    $offset = 6 + 16 * $Sizes.Count
    for ($i = 0; $i -lt $Sizes.Count; $i++) {
        $dimension = $Sizes[$i]
        if ($dimension -ge 256) { $dimension = 0 }   # 0 means 256 in the ICO format
        $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
        $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([UInt16]1); $writer.Write([UInt16]32)
        $writer.Write([UInt32]$images[$i].Length); $writer.Write([UInt32]$offset)
        $offset += $images[$i].Length
    }
    foreach ($image in $images) { $writer.Write($image) }
    $writer.Flush()
    [System.IO.File]::WriteAllBytes($Path, $output.ToArray())
    $writer.Dispose()
}

function New-WordmarkPath {
    # "neverwas" in Manrope Bold as a path scaled to $Width, its top-left at ($X, $Y).
    param([double]$X, [double]$Y, [double]$Width)
    $fonts = New-Object System.Drawing.Text.PrivateFontCollection
    $fonts.AddFontFile($fontPath)
    $family = $fonts.Families[0]
    $style = if ($family.IsStyleAvailable([System.Drawing.FontStyle]::Bold)) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddString('neverwas', $family, [int]$style, [single]100, (New-Object System.Drawing.PointF 0, 0), [System.Drawing.StringFormat]::GenericTypographic)
    $bounds = $path.GetBounds()
    $scale = $Width / $bounds.Width
    $matrix = New-Object System.Drawing.Drawing2D.Matrix
    $matrix.Translate(-$bounds.X, -$bounds.Y)
    $matrix.Scale($scale, $scale, [System.Drawing.Drawing2D.MatrixOrder]::Append)
    $matrix.Translate($X, $Y, [System.Drawing.Drawing2D.MatrixOrder]::Append)
    $path.Transform($matrix)
    $matrix.Dispose(); $family.Dispose(); $fonts.Dispose()
    $path
}

# logo.ico
Write-Icon -Path (Join-Path $ResourcesPath 'logo.ico') -Sizes @(16, 20, 24, 32, 40, 48, 64, 96, 128, 256)

# 3.png
$frame = New-IconFrame 256
$frame.Save((Join-Path $ResourcesPath '3.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$frame.Dispose()

# bigImage.bmp: vertical lockup (wordmark 1.5x the tile, 1/4 tile gap), centred slightly above the middle.
$width = 164; $height = 314; $tile = 88
$canvas = New-Canvas $width $height ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$canvas.Graphics.Clear($primary)
$wordmark = New-WordmarkPath 0 0 ($tile * 1.5)
$wordHeight = $wordmark.GetBounds().Height
$lockupHeight = $tile + $tile / 4 + $wordHeight
$top = [math]::Round(($height - $lockupHeight) * 0.45)
$left = ($width - $tile) / 2
Add-Symbol $canvas.Graphics (New-Symbol $left $top $tile $true) $white $primary
$wordmark.Dispose()
$wordmark = New-WordmarkPath (($width - $tile * 1.5) / 2) ($top + $tile + $tile / 4) ($tile * 1.5)
$brush = New-Object System.Drawing.SolidBrush $white
$canvas.Graphics.FillPath($brush, $wordmark)
$brush.Dispose(); $wordmark.Dispose()
$canvas.Bitmap.Save((Join-Path $ResourcesPath 'bigImage.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$canvas.Graphics.Dispose(); $canvas.Bitmap.Dispose()

Write-Host "Wrote logo.ico, 3.png and bigImage.bmp to $ResourcesPath"
