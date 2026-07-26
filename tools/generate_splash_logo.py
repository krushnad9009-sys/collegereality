from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(r"C:\Users\Sahyadri\collegereality")
OUT = ROOT / "assets" / "icons" / "splash_logo.png"
SIZE = 1024
CENTER = SIZE / 2
scale = (SIZE / 512.0) * 1.18
stroke = int(38 * scale)

def grad(colors, t, alpha=255):
    t = max(0.0, min(1.0, t))
    i = int(t * (len(colors) - 1))
    if i >= len(colors) - 1:
        r, g, b = colors[-1]
        return (r, g, b, alpha)
    local = t * (len(colors) - 1) - i
    c0, c1 = colors[i], colors[i + 1]
    return (int(c0[0] + (c1[0]-c0[0])*local), int(c0[1] + (c1[1]-c0[1])*local), int(c0[2] + (c1[2]-c0[2])*local), alpha)

base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(base)
indigo = [(99, 102, 241), (79, 70, 229), (67, 56, 202)]
accent = [(52, 211, 153), (16, 185, 129)]

c_box = (CENTER - 118*scale, CENTER - 108*scale, CENTER + 78*scale, CENTER + 112*scale)
draw.arc(c_box, start=118, end=358, fill=grad(indigo, 0.15), width=stroke)
stem_x = CENTER + 8*scale
draw.line([(stem_x, CENTER - 98*scale), (stem_x, CENTER + 98*scale)], fill=grad(indigo, 0.55), width=stroke, joint="curve")
bowl_box = (stem_x - 4*scale, CENTER - 58*scale, stem_x + 98*scale, CENTER + 58*scale)
draw.arc(bowl_box, start=-108, end=62, fill=grad(indigo, 0.72), width=stroke)
draw.line([(stem_x, CENTER + 8*scale), (stem_x + 88*scale, CENTER + 108*scale)], fill=grad(indigo, 0.95), width=int(stroke*0.94), joint="curve")

dot_center = (CENTER + 68*scale, CENTER + 8*scale)
dot_r = int(26*scale)
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([dot_center[0]-dot_r*1.8, dot_center[1]-dot_r*1.8, dot_center[0]+dot_r*1.8, dot_center[1]+dot_r*1.8], fill=(*accent[0], 70))
glow = glow.filter(ImageFilter.GaussianBlur(radius=int(10*scale)))
base = Image.alpha_composite(base, glow)
draw = ImageDraw.Draw(base)
draw.ellipse([dot_center[0]-dot_r, dot_center[1]-dot_r, dot_center[0]+dot_r, dot_center[1]+dot_r], fill=grad(accent, 0.5))
draw.ellipse([dot_center[0]-dot_r*0.35, dot_center[1]-dot_r*0.55, dot_center[0]-dot_r*0.05, dot_center[1]-dot_r*0.25], fill=(255,255,255,180))

glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gld = ImageDraw.Draw(glow_layer)
gld.ellipse([CENTER-220*scale, CENTER-220*scale, CENTER+220*scale, CENTER+220*scale], fill=(99, 102, 241, 42))
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=int(48*scale)))
final = Image.alpha_composite(glow_layer, base)
final.save(OUT, "PNG", optimize=True)
print(f"Wrote {OUT}")
