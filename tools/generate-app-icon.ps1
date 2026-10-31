param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon.png")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Get-Color([string]$Hex, [int]$Alpha = 255) {
    $color = [System.Drawing.ColorTranslator]::FromHtml($Hex)
    return [System.Drawing.Color]::FromArgb($Alpha, $color.R, $color.G, $color.B)
}

function New-RoundedRectanglePath([float]$X, [float]$Y, [float]$Width, [float]$Height, [float]$Radius) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

$destinationDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

$bitmap = [System.Drawing.Bitmap]::new(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

try {
    # Full-bleed warm background; iOS applies the platform mask to the square artwork.
    $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 0, 1024, 1024),
        (Get-Color "#B86D63"),
        (Get-Color "#754647"),
        135
    )
    $graphics.FillRectangle($background, 0, 0, 1024, 1024)
    $background.Dispose()

    # A quiet, warm halo gives the paper card separation at small icon sizes.
    $halo = [System.Drawing.SolidBrush]::new((Get-Color "#E9A38A" 38))
    $graphics.FillEllipse($halo, 92, 82, 840, 840)
    $halo.Dispose()

    $shadowPath = New-RoundedRectanglePath 227 190 588 680 78
    $shadowBrush = [System.Drawing.SolidBrush]::new((Get-Color "#3A2728" 76))
    $shadowMatrix = [System.Drawing.Drawing2D.Matrix]::new()
    $shadowMatrix.Translate(0, 19)
    $shadowPath.Transform($shadowMatrix)
    $graphics.FillPath($shadowBrush, $shadowPath)
    $shadowMatrix.Dispose()
    $shadowBrush.Dispose()
    $shadowPath.Dispose()

    $paperPath = New-RoundedRectanglePath 218 173 588 680 78
    $paperBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(218, 173, 588, 680),
        (Get-Color "#FFF9F1"),
        (Get-Color "#F2E6D9"),
        90
    )
    $graphics.FillPath($paperBrush, $paperPath)
    $paperBrush.Dispose()
    $paperPath.Dispose()

    # The centered heart reads as a personal keepsake; the quiet strokes below suggest a journal page.
    $heart = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $heart.StartFigure()
    $heart.AddBezier(512, 590, 458, 550, 314, 467, 314, 402)
    $heart.AddBezier(314, 402, 314, 338, 356, 304, 414, 304)
    $heart.AddBezier(414, 304, 462, 304, 493, 344, 512, 372)
    $heart.AddBezier(512, 372, 531, 344, 562, 304, 610, 304)
    $heart.AddBezier(610, 304, 668, 304, 710, 338, 710, 402)
    $heart.AddBezier(710, 402, 710, 467, 566, 550, 512, 590)
    $heart.CloseFigure()
    $heartBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(314, 304, 396, 286),
        (Get-Color "#C66D62"),
        (Get-Color "#A64E4B"),
        90
    )
    $graphics.FillPath($heartBrush, $heart)
    $heartBrush.Dispose()
    $heart.Dispose()

    $linePen = [System.Drawing.Pen]::new((Get-Color "#C7A99B"), 24)
    $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawLine($linePen, 396, 680, 628, 680)
    $graphics.DrawLine($linePen, 426, 738, 598, 738)
    $linePen.Dispose()

    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Generated 1024x1024 App Icon: $OutputPath"
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
