# icons — every launcher icon, from one source file

```powershell
powershell -ExecutionPolicy Bypass -File tools\icons\generate_icons.ps1
```

Reads `Images and logo/factorino logo.png` and writes:

| target | files |
|---|---|
| Android, API 24–25 | `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` — 48 / 72 / 96 / 144 / 192 |
| Android, API 26+ | `mipmap-{…}dpi/ic_launcher_background.png` — 108 / 162 / 216 / 324 / 432, with `mipmap-anydpi-v26/ic_launcher.xml` |
| Windows | `windows/runner/resources/app_icon.ico` — 16, 24, 32, 48, 64, 128, 256 |

`ic_launcher.xml` is **not** generated — it is hand-written and checked in,
because it is configuration rather than output.

## The rule: downscale, and nothing else

The source is used exactly as supplied — 1254 × 1254, 24-bit RGB, opaque white
background included. Nothing is keyed out, cropped, padded or recomposed. Every
output is the whole square image resampled to one smaller square, and
`IconGen.Resize` throws rather than enlarge, so an upscale cannot happen by
accident.

The adaptive icon takes the image as its **background** layer, at the full
108 dp canvas, with a transparent foreground. The artwork is a finished square
picture with its own background, so it goes in the layer that is drawn
full-bleed, and nothing is invented to sit in front of it.

## What the launcher mask does to it

A launcher shows the middle **72 dp of the 108 dp** canvas, and chooses the
shape itself. Measured against this image, whose artwork spans x 278–973 and
y 212–1050 of the 1254 px square:

* **Square, rounded-square and squircle masks keep essentially all of it.** The
  safe zone is 209–1045, and only the last five pixels of the drop shadow fall
  outside it.
* **A circular mask cuts the corners of the blue badge.** A circle of that
  diameter reaches 418 px from the centre; the badge's corner region is about
  462 px out. Rendered under both masks before this was written — the squircle
  is intact, the circle shaves the badge's top-left and top-right and the
  bottom of the receipt.

That is what a full-bleed square picture in the background layer means, on the
launchers that mask to a circle.

## How it reads small

Read off the rendered `.ico` at 1:1. The artwork occupies about 56% of the
square, so a 16 px tile gives it roughly 9 × 11 px:

* **16 px** — a blue smear with a pale block beside it. The list rows and the
  teal check badge are single pixels; the shape does not resolve.
* **24 px** — the F reads. The receipt's rows are dots rather than lines.
* **32 px** — the F is clean, the teal badge is clearly a badge, the rows are
  faint.
* **48 px** — rows resolve as bars and the checkmark is visible.

On Windows there is no transparency, so the icon is a **white square** in the
taskbar and the title bar rather than a floating mark. Both of these follow
from using the image as designed, at its own margins.

## Why not `flutter_launcher_icons`

It would be a `pubspec.yaml` dependency added to run once. The project spec asks
what happens if a dependency stops being maintained, and for a one-shot
generator the honest answer is that it should not have been taken. `IconGen.cs`
uses System.Drawing, which is already on the machine — the same reasoning, and
the same Windows-only shape, as `tools/pdf_raster`.
