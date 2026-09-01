# pdf_raster — look at a rendered page from the terminal

Phase 7 is a rendering problem, and a rendering problem is settled by looking at the page.
The Phase 7 shaping probes (D-070) were rasterised through a browser extension; when that
connection dropped mid-diagnosis the whole question became unanswerable, and the ZWNJ cause
(D-073) sat unresolved for a session because of it.

These four scripts keep the loop local. They use **`Windows.Data.Pdf`**, the renderer that ships
with Windows 10 — no Ghostscript, no poppler, no Python, no network, nothing to install — and
`System.Drawing` for the cropping. They are Windows-only by design; that is where this project's
desktop target is.

## Usage

```powershell
# PDF page -> PNG. -Width is the raster width in pixels; use 4000+ to read glyph shapes.
.\rasterize.ps1 -Pdf out.pdf -Out out.png [-Page 0] [-Width 2400]

# Crop to the bounding box of everything that is not white, and scale up.
# The fastest way to get a line of text large enough to judge letter forms.
.\inkcrop.ps1 -In out.png -Out crop.png [-Pad 30] [-Scale 1.0] [-Threshold 245]

# Crop an explicit rectangle, for a page too full for inkcrop to help.
.\region.ps1 -In out.png -Out band.png -X 2600 -Y 300 -W 2200 -H 900 [-Scale 1.0]

# Count differing pixels between two renders of the same size.
.\pxdiff.ps1 -A before.png -B after.png
```

## Why `pxdiff` matters more than it looks

The ZWNJ diagnosis turned on it twice. A remedy that "looks right" next to a defect that
"looks wrong" proves nothing about the letters that were **not** meant to change; a zero-pixel
diff between two variants proved that the `pdf` package silently deletes U+200E, which no amount
of reading the source had shown. Render both, diff, then look at what the diff says changed.

## The rule this exists to enforce

**Read the pixels, not the content stream.** D-070 set that rule for the shaping probes and it
has caught something every time it was applied. A glyph index tells you what the renderer was
asked for; only the raster tells you what it drew — and for a zero-length glyph in this package
those are different things (D-073).
