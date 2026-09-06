// Icon generation from the source logo. Compiled at run time by
// tools/icons/generate_icons.ps1 -- see tools/icons/README.md.
//
// **It downscales, and that is all it does.** The source PNG is used exactly as
// the owner supplied it: white background included, nothing keyed, nothing
// cropped, nothing recomposed. Load, resample, write.
//
// WHY C# AND NOT A DART SCRIPT
//
// Decoding a PNG in Dart needs the `image` package, and the project spec
// asks that a dependency be justified before it is added. This needs no
// dependency at all: System.Drawing ships with the .NET Framework already on
// the machine. The PowerShell wrapper exists only because that is how this
// repository already drives Windows-only tooling (tools/pdf_raster).
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class IconGen
{
    // Loads any image as 32bpp ARGB, so every later step has one format.
    public static Bitmap Load(string path)
    {
        using (Bitmap src = new Bitmap(path))
        {
            Bitmap dst = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(dst))
            {
                g.CompositingMode = CompositingMode.SourceCopy;
                g.DrawImage(src, new Rectangle(0, 0, src.Width, src.Height));
            }
            return dst;
        }
    }

    // The whole image at [size] x [size].
    //
    // The source is square, so this never changes the aspect ratio and never
    // crops. It refuses to enlarge: every target here is smaller than the
    // 1254 px source, and an icon quietly upscaled from something too small is
    // the soft, blurry result the owner asked to be told about instead.
    public static Bitmap Resize(Bitmap src, int size)
    {
        if (size > src.Width || size > src.Height)
        {
            throw new Exception("refusing to upscale: asked for " + size + " from a "
                + src.Width + "x" + src.Height + " source");
        }

        Bitmap dst = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            g.CompositingMode = CompositingMode.SourceCopy;
            g.DrawImage(src, new Rectangle(0, 0, size, size));
        }
        return dst;
    }

    public static void SavePng(Bitmap bmp, string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        bmp.Save(path, ImageFormat.Png);
    }

    // Writes a multi-image .ico.
    //
    // **DIB below 256, PNG at 256.** Windows has read PNG-compressed icon
    // entries since Vista, but a handful of older Win32 paths still expect a
    // DIB for the small sizes, and the small sizes are the ones that end up in
    // the taskbar and the title bar. The 256 entry has to be PNG: an
    // uncompressed 256x256 DIB is 256 KB and some shells reject it.
    public static void SaveIco(List<Bitmap> images, string path)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        using (FileStream fs = new FileStream(path, FileMode.Create))
        using (BinaryWriter w = new BinaryWriter(fs))
        {
            w.Write((short)0);
            w.Write((short)1);
            w.Write((short)images.Count);

            List<byte[]> blobs = new List<byte[]>();
            foreach (Bitmap b in images) blobs.Add(b.Width >= 256 ? PngBytes(b) : DibBytes(b));

            int offset = 6 + 16 * images.Count;
            for (int i = 0; i < images.Count; i++)
            {
                Bitmap b = images[i];
                w.Write((byte)(b.Width >= 256 ? 0 : b.Width));
                w.Write((byte)(b.Height >= 256 ? 0 : b.Height));
                w.Write((byte)0);
                w.Write((byte)0);
                w.Write((short)1);
                w.Write((short)32);
                w.Write(blobs[i].Length);
                w.Write(offset);
                offset += blobs[i].Length;
            }
            foreach (byte[] blob in blobs) w.Write(blob);
        }
    }

    private static byte[] PngBytes(Bitmap b)
    {
        using (MemoryStream ms = new MemoryStream())
        {
            b.Save(ms, ImageFormat.Png);
            return ms.ToArray();
        }
    }

    // A 32bpp bottom-up DIB with the 1bpp AND mask an .ico entry still needs.
    private static byte[] DibBytes(Bitmap b)
    {
        int w = b.Width, h = b.Height;
        int maskStride = ((w + 31) / 32) * 4;
        byte[] outBuf = new byte[40 + w * h * 4 + maskStride * h];

        BitmapData d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly,
            PixelFormat.Format32bppArgb);
        byte[] px = new byte[d.Stride * h];
        System.Runtime.InteropServices.Marshal.Copy(d.Scan0, px, 0, px.Length);
        int srcStride = d.Stride;
        b.UnlockBits(d);

        using (MemoryStream ms = new MemoryStream(outBuf, true))
        using (BinaryWriter bw = new BinaryWriter(ms))
        {
            bw.Write(40);
            bw.Write(w);
            bw.Write(h * 2);          // XOR and AND stacked, as the format wants
            bw.Write((short)1);
            bw.Write((short)32);
            bw.Write(0);
            bw.Write(w * h * 4 + maskStride * h);
            bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0);

            for (int y = h - 1; y >= 0; y--) bw.Write(px, y * srcStride, w * 4);
            // The AND mask stays zero: the alpha channel above is what masks a
            // 32bpp icon, and a stale AND mask is how an icon ends up with a
            // black box behind it on one shell and not another.
            bw.Write(new byte[maskStride * h]);
        }
        return outBuf;
    }
}
