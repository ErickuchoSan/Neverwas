<#
.SYNOPSIS
    Writes the provisional Neverwas wizard/splash image (3.png) and About-box image (bigImage.bmp).
    Same pixel size and format as the BCU originals. Replaced by the real artwork in the branding subproject.
.DESCRIPTION
    3.png        256x256, 32bpp ARGB, transparent background: dark octagon outline with a bold "N".
    bigImage.bmp 164x314, 24bpp RGB, white background: the same N-octagon with "Neverwas" below it.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$WizardImagePath,
    [Parameter(Mandatory = $true)][string]$AboutImagePath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$ink = [System.Drawing.Color]::FromArgb(255, 60, 60, 60)

function Add-CenteredText {
    # Fills $Text as a vector path whose bounding box is scaled to $TargetHeight and centred on ($CenterX, $CenterY).
    param($Graphics, [string]$Text, [single]$CenterX, [single]$CenterY, [single]$TargetHeight, [string]$FontName)
    $family = New-Object System.Drawing.FontFamily $FontName
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $format = New-Object System.Drawing.StringFormat
    $path.AddString($Text, $family, [int][System.Drawing.FontStyle]::Bold, [single]100, (New-Object System.Drawing.PointF 0, 0), $format)
    $bounds = $path.GetBounds()
    $scale = $TargetHeight / $bounds.Height
    $matrix = New-Object System.Drawing.Drawing2D.Matrix
    $matrix.Translate(-($bounds.X + $bounds.Width / 2), -($bounds.Y + $bounds.Height / 2))
    $matrix.Scale($scale, $scale, [System.Drawing.Drawing2D.MatrixOrder]::Append)
    $matrix.Translate($CenterX, $CenterY, [System.Drawing.Drawing2D.MatrixOrder]::Append)
    $path.Transform($matrix)
    $brush = New-Object System.Drawing.SolidBrush $ink
    $Graphics.FillPath($brush, $path)
    $brush.Dispose(); $path.Dispose(); $matrix.Dispose(); $format.Dispose(); $family.Dispose()
}

function Add-NOctagon {
    # Regular octagon with flat sides facing up/down/left/right, $Width pixels across, plus a bold "N".
    param($Graphics, [single]$CenterX, [single]$CenterY, [single]$Width)
    $stroke = $Width * 0.0625
    $apothem = $Width / 2 - $stroke / 2
    $radius = $apothem / [math]::Cos([math]::PI / 8)
    $points = New-Object 'System.Drawing.PointF[]' 8
    for ($i = 0; $i -lt 8; $i++) {
        $angle = [math]::PI / 8 + $i * [math]::PI / 4
        $points[$i] = New-Object System.Drawing.PointF ([single]($CenterX + $radius * [math]::Cos($angle))), ([single]($CenterY + $radius * [math]::Sin($angle)))
    }
    $pen = New-Object System.Drawing.Pen $ink, $stroke
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Miter
    $Graphics.DrawPolygon($pen, $points)
    $pen.Dispose()
    Add-CenteredText -Graphics $Graphics -Text 'N' -CenterX $CenterX -CenterY $CenterY -TargetHeight ($Width * 0.52) -FontName 'Segoe UI'
}

function New-Canvas {
    param([int]$Width, [int]$Height, [System.Drawing.Imaging.PixelFormat]$Format)
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height, $Format
    $bitmap.SetResolution(96, 96)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    [pscustomobject]@{ Bitmap = $bitmap; Graphics = $graphics }
}

# 3.png: wizard label image and splash.
$canvas = New-Canvas 256 256 ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$canvas.Graphics.Clear([System.Drawing.Color]::Transparent)
Add-NOctagon -Graphics $canvas.Graphics -CenterX 128 -CenterY 128 -Width 256
$canvas.Bitmap.Save($WizardImagePath, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Graphics.Dispose(); $canvas.Bitmap.Dispose()

# bigImage.bmp: About box (and installer) side image.
$canvas = New-Canvas 164 314 ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$canvas.Graphics.Clear([System.Drawing.Color]::White)
Add-NOctagon -Graphics $canvas.Graphics -CenterX 82 -CenterY 110 -Width 120
Add-CenteredText -Graphics $canvas.Graphics -Text 'Neverwas' -CenterX 82 -CenterY 205 -TargetHeight 20 -FontName 'Segoe UI'
$canvas.Bitmap.Save($AboutImagePath, [System.Drawing.Imaging.ImageFormat]::Bmp)
$canvas.Graphics.Dispose(); $canvas.Bitmap.Dispose()
