param([Parameter(Mandatory=$true)][string]$In,[Parameter(Mandatory=$true)][string]$Out,
      [int]$X=0,[int]$Y=0,[int]$W=0,[int]$H=0,[double]$Scale=1.0)
Add-Type -AssemblyName System.Drawing
$b = New-Object System.Drawing.Bitmap((Resolve-Path $In).Path)
if ($W -le 0) { $W = $b.Width - $X }; if ($H -le 0) { $H = $b.Height - $Y }
$dw=[int]($W*$Scale); $dh=[int]($H*$Scale)
$d = New-Object System.Drawing.Bitmap($dw,$dh)
$g = [System.Drawing.Graphics]::FromImage($d)
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($b,(New-Object System.Drawing.Rectangle(0,0,$dw,$dh)),(New-Object System.Drawing.Rectangle($X,$Y,$W,$H)),[System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose(); $d.Save($Out,[System.Drawing.Imaging.ImageFormat]::Png); $d.Dispose(); $b.Dispose()
"$Out  ${dw}x${dh} from ${X},${Y} ${W}x${H}"
