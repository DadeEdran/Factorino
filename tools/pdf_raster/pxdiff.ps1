param([Parameter(Mandatory=$true)][string]$A,[Parameter(Mandatory=$true)][string]$B)
Add-Type -AssemblyName System.Drawing
$ba = New-Object System.Drawing.Bitmap((Resolve-Path $A).Path)
$bb = New-Object System.Drawing.Bitmap((Resolve-Path $B).Path)
if ($ba.Width -ne $bb.Width -or $ba.Height -ne $bb.Height) {
  "SIZE DIFFERS: $($ba.Width)x$($ba.Height) vs $($bb.Width)x$($bb.Height)"
  $ba.Dispose(); $bb.Dispose(); return
}
$diff = 0
for ($y = 0; $y -lt $ba.Height; $y++) {
  for ($x = 0; $x -lt $ba.Width; $x++) {
    if ($ba.GetPixel($x,$y).ToArgb() -ne $bb.GetPixel($x,$y).ToArgb()) { $diff++ }
  }
}
"same size $($ba.Width)x$($ba.Height); differing pixels: $diff"
$ba.Dispose(); $bb.Dispose()
