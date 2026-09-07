# icons — every launcher icon, from one source file

```powershell
powershell -ExecutionPolicy Bypass -File tools\icons\generate_icons.ps1
```

Reads `Images and logo/factorino logo.png` and writes:

| target | files |
|---|---|
| Android, every API level | `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` — 48 / 72 / 96 / 144 / 192 |
| Windows | `windows/runner/resources/app_icon.ico` — 16, 24, 32, 48, 64, 128, 256 |

**There is no adaptive icon, and that is the point** — see below.

## The rule: downscale, and nothing else

The source is used exactly as supplied — 1254 × 1254, 24-bit RGB, opaque white
background included. Nothing is keyed out, cropped, padded or recomposed. Every
output is the whole square image resampled to one smaller square, and
`IconGen.Resize` throws rather than enlarge, so an upscale cannot happen by
accident.

**Two things enforce it rather than assert it**, both added after the rule was
stated here and broken anyway:

* `IconGen.AssertOpaque` runs on the source and on every resized bitmap, and
  throws naming the offending pixel. The source has no alpha channel, so any
  transparency in an output was invented in transit and no value of it can be
  right.
* `Resize` sets `WrapMode.TileFlipXY`. Without it a bicubic kernel reads past
  the edge of the bitmap, GDI+ calls outside "transparent black", and under
  `SourceCopy` that gets copied rather than blended — which put a **one-pixel
  translucent frame** (alpha 220–243) around every mipmap and every `.ico`
  entry, and shipped it in both artifacts. Mirroring the edge gives the kernel
  real pixels to read.

## Why there is no adaptive icon

**Because an adaptive icon is defined to crop, and cropping is what removed the
white.** The launcher draws only the middle **72 dp of the 108 dp** canvas and
chooses the shape itself. Measured against this image, whose artwork spans
x 278–973 and y 212–1050 of the 1254 px square, that safe zone is 209–1045 — so
the mask keeps the mark, throws away **every pixel of the white margin around
it**, and clips the last five pixels off the bottom of the receipt.

Rendered and looked at rather than reasoned about: the masked result is the mark
bleeding to all four edges with no white anywhere. That is what was reported as
"the white background has been removed from the logo", and it is not something
regenerating a PNG can fix, because nothing was wrong with the PNG — every file
on disk and in both shipped artifacts carried the full opaque image the whole
time.

The alternatives were weighed and both are excluded by the rule above: scaling
the image into the 72 dp safe zone adds padding, and putting it in a foreground
layer over a white background layer invents a second picture. Either is a
recomposition.

So the adaptive icon is gone, and `ic_launcher.png` serves every API level. On
API 26+ the system applies its **legacy treatment** — it scales the icon down
inside the launcher's shape rather than cutting into it — so the white margin
survives and the mark is never clipped.

**The cost, so it reads as a choice:** the icon does not move with the
launcher's parallax, and a launcher that draws legacy icons small will sit it
inside a shape rather than let it fill one. That is the trade for showing the
picture as it was drawn.

## How it reads small

Read off the rendered `.ico` at 1:1. The artwork occupies about 56% of the
square, so a 16 px tile gives it roughly 9 × 11 px:

* **16 px** — a blue smear with a pale block beside it. The list rows and the
  teal check badge are single pixels; the shape does not resolve.
* **24 px** — the F reads. The receipt's rows are dots rather than lines.
* **32 px** — the F is clean, the teal badge is clearly a badge, the rows are
  faint.
* **48 px** — rows resolve as bars and the checkmark is visible.

On Windows there is no transparency at all — every entry is fully opaque — so
the icon is a **white square** in the taskbar and the title bar rather than a
floating mark. Both of these follow from using the image as designed, at its own
margins.

## Why not `flutter_launcher_icons`

It would be a `pubspec.yaml` dependency added to run once. The project spec asks
what happens if a dependency stops being maintained, and for a one-shot
generator the honest answer is that it should not have been taken. `IconGen.cs`
uses System.Drawing, which is already on the machine — the same reasoning, and
the same Windows-only shape, as `tools/pdf_raster`.
