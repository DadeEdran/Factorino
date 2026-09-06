// Icon generation from the source logo. Compiled at run time by
// tools/icons/generate_icons.ps1 -- see tools/icons/README.md.
//
// WHY C# AND NOT A DART SCRIPT
//
// Decoding a PNG in Dart needs the `image` package, and the project spec
// asks that a dependency be justified before it is added. This needs no
// dependency at all: System.Drawing ships with the .NET Framework already on
// the machine, and the whole job -- key, trim, fit, resample, write ICO -- is
// a couple of hundred lines of it. The PowerShell wrapper exists only because
// that is how this repository already drives Windows-only tooling
// (tools/pdf_raster).
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

    // Makes the opaque background transparent, and trims to what is left.
    //
    // **A flood fill from the border, not a colour test per pixel.** The
    // receipt inside the mark is white too, and a threshold applied everywhere
    // would punch a hole through the middle of the artwork. Only white that is
    // CONNECTED to the edge of the canvas is background, which is the
    // definition that matches what a person means by the word.
    public static Bitmap KeyAndTrim(Bitmap src, int threshold)
    {
        int w = src.Width, h = src.Height;
        BitmapData data = src.LockBits(new Rectangle(0, 0, w, h),
            ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int stride = data.Stride;
        byte[] buf = new byte[stride * h];
        System.Runtime.InteropServices.Marshal.Copy(data.Scan0, buf, 0, buf.Length);

        bool[] bg = new bool[w * h];
        Stack<int> stack = new Stack<int>();
        for (int x = 0; x < w; x++)
        {
            Seed(buf, stride, w, bg, stack, x, 0, threshold);
            Seed(buf, stride, w, bg, stack, x, h - 1, threshold);
        }
        for (int y = 0; y < h; y++)
        {
            Seed(buf, stride, w, bg, stack, 0, y, threshold);
            Seed(buf, stride, w, bg, stack, w - 1, y, threshold);
        }

        while (stack.Count > 0)
        {
            int i = stack.Pop();
            int x = i % w, y = i / w;
            if (x > 0) Seed(buf, stride, w, bg, stack, x - 1, y, threshold);
            if (x < w - 1) Seed(buf, stride, w, bg, stack, x + 1, y, threshold);
            if (y > 0) Seed(buf, stride, w, bg, stack, x, y - 1, threshold);
            if (y < h - 1) Seed(buf, stride, w, bg, stack, x, y + 1, threshold);
        }

        int minX = w, minY = h, maxX = -1, maxY = -1;
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                int i = y * w + x;
                int o = y * stride + x * 4;
                if (bg[i]) { buf[o + 3] = 0; continue; }
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            }
        }
        System.Runtime.InteropServices.Marshal.Copy(buf, 0, data.Scan0, buf.Length);
        src.UnlockBits(data);

        if (maxX < 0) throw new Exception("the whole image keyed away as background");
        Rectangle box = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
        Console.WriteLine("  keyed at " + threshold + ": kept " + box.Width + "x" + box.Height
            + " of " + w + "x" + h + " (offset " + minX + "," + minY + ")");
        return src.Clone(box, PixelFormat.Format32bppArgb);
    }

    private static void Seed(byte[] buf, int stride, int w, bool[] bg, Stack<int> stack,
        int x, int y, int threshold)
    {
        int i = y * w + x;
        if (bg[i]) return;
        int o = y * stride + x * 4;
        if (buf[o] < threshold || buf[o + 1] < threshold || buf[o + 2] < threshold) return;
        bg[i] = true;
        stack.Push(i);
    }

    // [art] centred on a square canvas, scaled so its longest side is
    // [coverage] of it. Contain, never crop and never stretch.
    public static Bitmap Fit(Bitmap art, int canvas, double coverage, Color background)
    {
        Bitmap dst = new Bitmap(canvas, canvas, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst))
        {
            g.Clear(background);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;

            double scale = canvas * coverage / Math.Max(art.Width, art.Height);
            double dw = art.Width * scale, dh = art.Height * scale;
            g.DrawImage(art, (float)((canvas - dw) / 2), (float)((canvas - dh) / 2),
                (float)dw, (float)dh);
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
