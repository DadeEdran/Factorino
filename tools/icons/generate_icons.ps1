# generate_icons.ps1 — build every launcher icon from the one source logo.
#
#   powershell -ExecutionPolicy Bypass -File tools\icons\generate_icons.ps1
#
# **The source image is used exactly as supplied.** White background included:
# nothing is keyed out, nothing is cropped, nothing is recomposed onto a new
# canvas. Every output is the whole 1254 x 1254 PNG resampled down to one
# square size, and `IconGen.Resize` throws rather than enlarge.
#
# WHY THIS EXISTS RATHER THAN A PACKAGE
#
# `flutter_launcher_icons` does this job and would be a dependency added to
# `pubspec.yaml` to run once — the project spec asks what happens when a dependency
# stops being maintained, and the honest answer for a one-shot generator is
# "nothing, because we should not have taken it". This script and IconGen.cs
# use System.Drawing, which is already on the machine, and they are checked in
# so the icons can be regenerated from the source art rather than being opaque
# binaries nobody can reproduce.
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Add-Type -TypeDefinition (Get-Content "$PSScriptRoot\IconGen.cs" -Raw) -ReferencedAssemblies System.Drawing

$source = Join-Path $root "Images and logo\factorino logo.png"
if (-not (Test-Path $source)) { throw "source logo not found: $source" }

Write-Host "source: $source"
$art = [IconGen]::Load($source)
Write-Host ("  loaded {0}x{1} — used whole, unmodified" -f $art.Width, $art.Height)

# --------------------------------------------------------------- Android
#
# Legacy density icons, for API 24 and 25 — the two levels below adaptive that
# `minSdk` still admits.
$legacy = [ordered]@{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($density in $legacy.Keys) {
  $px = $legacy[$density]
  $bmp = [IconGen]::Resize($art, $px)
  [IconGen]::SavePng($bmp, (Join-Path $root "android\app\src\main\res\mipmap-$density\ic_launcher.png"))
  Write-Host ("  android legacy   {0,-8} {1}x{1}" -f $density, $px)
  $bmp.Dispose()
}

# The adaptive icon's background layer, API 26+ — the image itself, at the
# 108 dp canvas for each density. There is no generated foreground: the layer
# that carries the artwork is this one, and `ic_launcher.xml` puts a
# transparent colour in the foreground slot rather than inventing a second
# picture. A launcher masks this to the middle 72 dp of the 108 — see the
# README for what that costs on this particular image.
$adaptive = [ordered]@{ 'mdpi' = 108; 'hdpi' = 162; 'xhdpi' = 216; 'xxhdpi' = 324; 'xxxhdpi' = 432 }
foreach ($density in $adaptive.Keys) {
  $px = $adaptive[$density]
  $bmp = [IconGen]::Resize($art, $px)
  [IconGen]::SavePng($bmp, (Join-Path $root "android\app\src\main\res\mipmap-$density\ic_launcher_background.png"))
  Write-Host ("  android adaptive {0,-8} {1}x{1}" -f $density, $px)
  $bmp.Dispose()
}

# --------------------------------------------------------------- Windows
#
# 16 through 256. The small entries are what the taskbar, the title bar and a
# list view in Explorer actually draw, so they are resampled from the source
# rather than left for Windows to derive by shrinking the 256.
$icoSizes = @(16, 24, 32, 48, 64, 128, 256)
$images = New-Object 'System.Collections.Generic.List[System.Drawing.Bitmap]'
foreach ($px in $icoSizes) { $images.Add([IconGen]::Resize($art, $px)) }
[IconGen]::SaveIco($images, (Join-Path $root "windows\runner\resources\app_icon.ico"))
Write-Host ("  windows ico      {0}" -f ($icoSizes -join ', '))
foreach ($b in $images) { $b.Dispose() }

$art.Dispose()
Write-Host "done"
