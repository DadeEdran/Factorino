# icons — every launcher icon, from one source file

```powershell
powershell -ExecutionPolicy Bypass -File tools\icons\generate_icons.ps1
```

Reads `Images and logo/factorino logo.png` and writes:

| target | files |
|---|---|
| Android, API 24–25 | `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` — 48 / 72 / 96 / 144 / 192 |
| Android, API 26+ | `mipmap-{…}dpi/ic_launcher_foreground.png` — 108 / 162 / 216 / 324 / 432, with `mipmap-anydpi-v26/ic_launcher.xml` and `values/ic_launcher_background.xml` |
| Windows | `windows/runner/resources/app_icon.ico` — 16, 24, 32, 48, 64, 128, 256 |

The two XML files are **not** generated — they are hand-written and checked in,
because they are configuration rather than output.

## What the source is, and what had to be done to it

1254 × 1254, 24-bit RGB, **no alpha**. The mark occupies 701 × 848 of that,
centred in an opaque white field. So it cannot be used as an icon directly:
scaled into a 48 px tile it is a small mark adrift in white, and on the Windows
taskbar it is a white block.

`IconGen.KeyAndTrim` makes the white transparent with a **flood fill from the
border**, not a per-pixel colour test. That distinction is the whole reason this
is not three lines: the receipt inside the mark is white too, and a threshold
applied everywhere punches a hole through the middle of the artwork. Only white
reachable from the edge of the canvas is background.

**The threshold is 250 and deliberately conservative.** The receipt reads only
because of the soft blue shadow beneath it; key harder and the artwork loses its
edge against a light background. Measured on this file: 250 keeps 701 × 848,
244 keeps 694 × 836, 236 keeps 693 × 828 — the falloff is steep enough that the
cautious threshold costs seven pixels.

## Sizing

Nothing is ever upscaled. The trimmed mark is 701 × 848 and the largest artwork
drawn from it is 268 px, inside the 432 px xxxhdpi adaptive foreground.

* **Legacy tiles: 0.94 coverage.** The artwork is a badge with its own weight;
  a tile it touches on all four sides reads as clipped.
* **Adaptive foreground: 0.62 coverage.** The canvas is 108 dp and a launcher
  may mask everything outside the middle 72 dp. 0.62 puts the artwork at 67 dp,
  inside the safe zone. The receipt overhangs the badge at the bottom right, and
  a circular mask taking the corner off it is what this margin buys out —
  rendered under both a circle and a squircle before the number was settled.
* **`.ico`: full bleed.** At 16 px every pixel is worth having.
* **The adaptive background is flat white**, which is the field the artwork was
  drawn on. A coloured plate takes the edge off the receipt, which is the one
  element that says "invoice".

## Where it stops working

Read off the rendered `.ico` at 1:1: at **16 px** the three list rows collapse
into a grey smudge and the teal check badge is a dot with no check in it — the
silhouette still says "blue document", but the detail is gone. **24 px** brings
the rows back as bars; **32 px** is the first size where the checkmark itself is
legible; **48 px** carries everything including the receipt's torn bottom edge.
That is a property of the artwork — four distinct elements — not of the
resampling, and the remedy would be a simplified mark drawn for the small sizes,
which is a design job rather than a generation one.

## Why not `flutter_launcher_icons`

It would be a `pubspec.yaml` dependency added to run once. The project spec asks
what happens if a dependency stops being maintained, and for a one-shot
generator the honest answer is that it should not have been taken. `IconGen.cs`
uses System.Drawing, which is already on the machine — the same reasoning, and
the same Windows-only shape, as `tools/pdf_raster`.
