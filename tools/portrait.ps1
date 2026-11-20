param([string]$src, [string]$dst)
# Quadratischer Ausschnitt (Kopf/Schultern), 600x600, mit dezenter Abdunklung der Ränder
# (beruhigt den Hintergrund) und leichter Kontrast-/Farbkorrektur.
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($src)
$size = 960                                  # Ausschnitt im Original
$x = [int](($img.Width - $size) / 2); $y = 200
$out = 600
$bmp = New-Object System.Drawing.Bitmap $out, $out
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

# leichte Farbkorrektur: etwas mehr Kontrast, minimal kühler/neutraler
$c = 1.06; $t = (1 - $c) / 2
$m = New-Object System.Drawing.Imaging.ColorMatrix
$m.Matrix00 = $c * 0.99; $m.Matrix11 = $c; $m.Matrix22 = $c * 1.02; $m.Matrix33 = 1; $m.Matrix44 = 1
$m.Matrix40 = $t; $m.Matrix41 = $t; $m.Matrix42 = $t
$ia = New-Object System.Drawing.Imaging.ImageAttributes
$ia.SetColorMatrix($m)
$g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $out, $out), $x, $y, $size, $size, [System.Drawing.GraphicsUnit]::Pixel, $ia)

# Vignette: Ränder sanft abdunkeln, Gesicht bleibt unverändert
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(-120, -150, $out + 240, $out + 300)
$brush = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
$brush.CenterPoint = New-Object System.Drawing.PointF ($out / 2), ($out * 0.42)
$brush.CenterColor = [System.Drawing.Color]::FromArgb(0, 15, 42, 68)
$brush.SurroundColors = @([System.Drawing.Color]::FromArgb(110, 15, 42, 68))
$blend = New-Object System.Drawing.Drawing2D.Blend
$blend.Positions = @(0.0, 0.35, 1.0); $blend.Factors = @(0.0, 0.0, 1.0)
$brush.Blend = $blend
$g.FillRectangle($brush, 0, 0, $out, $out)

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$p = New-Object System.Drawing.Imaging.EncoderParameters 1
$p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 86L
$bmp.Save($dst, $codec, $p)
$g.Dispose(); $bmp.Dispose(); $img.Dispose()
"$dst ($([math]::Round((Get-Item $dst).Length/1KB)) KB)"
