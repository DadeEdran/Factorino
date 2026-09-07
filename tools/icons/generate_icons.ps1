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
# The launcher icon, at every density. Used on EVERY API level -- see the note
# below about why there is no adaptive icon.
$legacy = [ordered]@{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($density in $legacy.Keys) {
  $px = $legacy[$density]
  $bmp = [IconGen]::Resize($art, $px)
  [IconGen]::SavePng($bmp, (Join-Path $root "android\app\src\main\res\mipmap-$density\ic_launcher.png"))
  Write-Host ("  android legacy   {0,-8} {1}x{1}" -f $density, $px)
  $bmp.Dispose()
}

# THERE IS DELIBERATELY NO ADAPTIVE ICON. This is the second half of the fix,
# and it is the half that matters -- read this before adding one back.
#
# An adaptive icon is defined to be cropped: the launcher draws only the middle
# 72 dp of the 108 dp canvas and picks the shape itself. Measured on this
# image, that safe zone is source pixels 209-1045 of 1254, and the artwork
# spans 278-973 across and 212-1050 down -- so the mask keeps the mark and
# throws away EVERY pixel of the white margin around it, then clips five pixels
# off the bottom of the receipt. Rendered and looked at, not reasoned about:
# the result is the mark bleeding to all four edges with no white left.
#
# That is the icon the owner reported as "the white background has been
# removed", and no amount of regenerating a PNG fixes it, because nothing is
# wrong with the PNG. The crop IS the adaptive icon.
#
# So there is no `mipmap-anydpi-v26/ic_launcher.xml` and no
# `ic_launcher_background.png`. Every API level takes the legacy
# `ic_launcher.png` above, which is the whole supplied square, downscaled and
# nothing else. On API 26+ the system applies its own legacy treatment -- it
# scales the icon down inside the launcher's shape rather than cutting into it
# -- so the white margin survives and the mark is never clipped.
#
# The cost, stated so it reads as a choice rather than an oversight: the icon
# does not move with the launcher's parallax, and on a launcher that draws
# legacy icons small it sits inside a shape rather than filling it. That is the
# trade for showing the picture as it was drawn.

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
