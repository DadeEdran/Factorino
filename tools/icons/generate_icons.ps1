# generate_icons.ps1 — build every launcher icon from the one source logo.
#
#   powershell -ExecutionPolicy Bypass -File tools\icons\generate_icons.ps1
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
#
# WHAT IT DECIDES, AND WHY
#
# * **The background is keyed off, by a flood fill from the border.** The
#   source is 24-bit RGB with no alpha: the mark sits on an opaque white field
#   with a wide margin. Scaled straight into a 48 px tile it would be a small
#   mark adrift in a white square, and on Windows a white block on a dark
#   taskbar. See IconGen.KeyAndTrim for why the fill is connectivity-based and
#   not a per-pixel colour test.
#
# * **Threshold 250, not lower.** The receipt in the artwork is white and only
#   reads because of the soft blue shadow the designer put under it. Keying
#   more aggressively eats that shadow, and the artwork then loses its edge
#   against a light background. Measured: 250 keeps 701x848 of the source,
#   244 keeps 694x836, 236 keeps 693x828 — the falloff is steep, so the
#   conservative threshold costs seven pixels and keeps the shadow intact.
#
# * **Nothing is ever upscaled.** The source mark is 701x848 after trimming;
#   the largest thing generated from it is the 432 px xxxhdpi adaptive
#   foreground, whose artwork occupies 268 px. Every output is a downscale.
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Add-Type -TypeDefinition (Get-Content "$PSScriptRoot\IconGen.cs" -Raw) -ReferencedAssemblies System.Drawing

$source = Join-Path $root "Images and logo\factorino logo.png"
if (-not (Test-Path $source)) { throw "source logo not found: $source" }

$transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

Write-Host "source: $source"
$loaded = [IconGen]::Load($source)
Write-Host ("  loaded {0}x{1}" -f $loaded.Width, $loaded.Height)
$art = [IconGen]::KeyAndTrim($loaded, 250)
$loaded.Dispose()

# --------------------------------------------------------------- Android
#
# Legacy density icons, for API 24 and 25 — the two levels below adaptive that
# `minSdk` still admits. Coverage 0.94 rather than 1.0: the artwork is a badge
# with its own visual weight, and a launcher tile that it touches on every side
# reads as clipped.
$legacy = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($density in $legacy.Keys) {
  $px = $legacy[$density]
  $bmp = [IconGen]::Fit($art, $px, 0.94, $transparent)
  $path = Join-Path $root "android\app\src\main\res\mipmap-$density\ic_launcher.png"
  [IconGen]::SavePng($bmp, $path)
  Write-Host ("  android legacy  {0,-8} {1}x{1}" -f $density, $px)
  $bmp.Dispose()
}

# The adaptive foreground, API 26+. The canvas is 108 dp and a launcher may
# mask anything outside the middle 72 dp, so the artwork is fitted to 0.62 of
# the canvas — 67 dp, inside the 72 dp safe zone with room to spare. The
# receipt overhangs the badge at the bottom right, and a circular mask cutting
# the corner off it is the failure this margin buys out.
$adaptive = @{ 'mdpi' = 108; 'hdpi' = 162; 'xhdpi' = 216; 'xxhdpi' = 324; 'xxxhdpi' = 432 }
foreach ($density in $adaptive.Keys) {
  $px = $adaptive[$density]
  $bmp = [IconGen]::Fit($art, $px, 0.62, $transparent)
  $path = Join-Path $root "android\app\src\main\res\mipmap-$density\ic_launcher_foreground.png"
  [IconGen]::SavePng($bmp, $path)
  Write-Host ("  android adaptive {0,-7} {1}x{1}" -f $density, $px)
  $bmp.Dispose()
}

# --------------------------------------------------------------- Windows
#
# 16 through 256. The small entries are what the taskbar, the title bar and a
# list view in Explorer actually draw, so they are generated from the source
# rather than left for Windows to derive by shrinking the 256.
$icoSizes = @(16, 24, 32, 48, 64, 128, 256)
$images = New-Object 'System.Collections.Generic.List[System.Drawing.Bitmap]'
foreach ($px in $icoSizes) { $images.Add([IconGen]::Fit($art, $px, 1.0, $transparent)) }
$icoPath = Join-Path $root "windows\runner\resources\app_icon.ico"
[IconGen]::SaveIco($images, $icoPath)
Write-Host ("  windows ico      {0}" -f ($icoSizes -join ', '))
foreach ($b in $images) { $b.Dispose() }

$art.Dispose()
Write-Host "done"
