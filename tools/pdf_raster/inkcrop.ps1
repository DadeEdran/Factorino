# Crop a PNG to the bounding box of its non-white pixels, with padding, and scale up.
param(
  [Parameter(Mandatory=$true)][string]$In,
  [Parameter(Mandatory=$true)][string]$Out,
  [int]$Pad = 24,
  [double]$Scale = 1.0,
  [int]$Threshold = 245
)
Add-Type -AssemblyName System.Drawing
$In = (Resolve-Path $In).Path
$bmp = New-Object System.Drawing.Bitmap($In)
$w = $bmp.Width; $h = $bmp.Height
$rect = New-Object System.Drawing.Rectangle(0,0,$w,$h)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$bmp.UnlockBits($data)

$minX = $w; $minY = $h; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $h; $y++) {
  $row = $y * $stride
  for ($x = 0; $x -lt $w; $x++) {
    $i = $row + $x * 4
    if ($bytes[$i] -lt $Threshold -or $bytes[$i+1] -lt $Threshold -or $bytes[$i+2] -lt $Threshold) {
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}
if ($maxX -lt 0) { $bmp.Dispose(); throw "the page is blank: no pixel darker than $Threshold" }

$x0 = [Math]::Max(0, $minX - $Pad); $y0 = [Math]::Max(0, $minY - $Pad)
$x1 = [Math]::Min($w - 1, $maxX + $Pad); $y1 = [Math]::Min($h - 1, $maxY + $Pad)
$cw = $x1 - $x0 + 1; $ch = $y1 - $y0 + 1
$dw = [int]($cw * $Scale); $dh = [int]($ch * $Scale)

$dst = New-Object System.Drawing.Bitmap($dw, $dh)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode  = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($bmp, (New-Object System.Drawing.Rectangle(0,0,$dw,$dh)), (New-Object System.Drawing.Rectangle($x0,$y0,$cw,$ch)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose(); $bmp.Dispose()
"ink box x=$minX..$maxX y=$minY..$maxY of ${w}x${h}  ->  ${dw}x${dh}  $Out"
