# Rasterize a PDF page to PNG using the Windows.Data.Pdf WinRT renderer.
# No external tooling: this ships with Windows 10.
param(
  [Parameter(Mandatory=$true)][string]$Pdf,
  [Parameter(Mandatory=$true)][string]$Out,
  [int]$Page = 0,
  [uint32]$Width = 2400
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]                  | Out-Null
[Windows.Storage.StorageFolder,Windows.Storage,ContentType=WindowsRuntime]                | Out-Null
[Windows.Data.Pdf.PdfDocument,Windows.Data.Pdf,ContentType=WindowsRuntime]                | Out-Null
[Windows.Data.Pdf.PdfPageRenderOptions,Windows.Data.Pdf,ContentType=WindowsRuntime]       | Out-Null
[Windows.Graphics.Imaging.BitmapEncoder,Windows.Graphics.Imaging,ContentType=WindowsRuntime] | Out-Null

$exts = [System.WindowsRuntimeSystemExtensions].GetMethods()
$asTaskOp = ($exts | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
$asTaskAct = ($exts | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.FullName -eq 'Windows.Foundation.IAsyncAction' })[0]

function Await($op, $type) {
  $t = $asTaskOp.MakeGenericMethod($type).Invoke($null, @($op))
  $t.Wait(-1) | Out-Null
  $t.Result
}
function AwaitAction($act) {
  $t = $asTaskAct.Invoke($null, @($act))
  $t.Wait(-1) | Out-Null
}

$Pdf = (Resolve-Path $Pdf).Path
$outDir  = Split-Path -Parent $Out
$outName = Split-Path -Leaf   $Out
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$outDir = (Resolve-Path $outDir).Path

$srcFile = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Pdf)) ([Windows.Storage.StorageFile])
$doc     = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($srcFile)) ([Windows.Data.Pdf.PdfDocument])
if ($Page -ge $doc.PageCount) { throw "page $Page out of range; document has $($doc.PageCount)" }
$pg = $doc.GetPage([uint32]$Page)

$opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
$opts.DestinationWidth  = $Width
$opts.BitmapEncoderId   = [Windows.Graphics.Imaging.BitmapEncoder]::PngEncoderId

$folder  = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($outDir)) ([Windows.Storage.StorageFolder])
$outFile = Await ($folder.CreateFileAsync($outName, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
$stream  = Await ($outFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])

AwaitAction ($pg.RenderToStreamAsync($stream, $opts))
$stream.Dispose()
$pg.Dispose()

$size = (Get-Item (Join-Path $outDir $outName)).Length
"OK pages=$($doc.PageCount) page=$Page -> $(Join-Path $outDir $outName) ($size bytes)"
