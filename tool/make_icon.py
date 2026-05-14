"""Generate the Tally launcher icon.

Renders four vertical tally marks with a diagonal slash on a warm peach
gradient background. Output: assets/icon/icon.png (1024x1024) and a foreground
variant for adaptive icons.
"""
from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

SIZE = 1024
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)


def vertical_gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h), top)
    pixels = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        for x in range(w):
            pixels[x, y] = (r, g, b)
    return img


def draw_marks(draw: ImageDraw.ImageDraw, cx, cy, mark_h, mark_w, gap, color, stroke):
    total_w = mark_w * 4 + gap * 3
    x0 = cx - total_w / 2
    y_top = cy - mark_h / 2
    y_bot = cy + mark_h / 2
    for i in range(4):
        x = x0 + i * (mark_w + gap) + mark_w / 2
        draw.line(
            [(x, y_top), (x, y_bot)],
            fill=color,
            width=stroke,
        )
    # diagonal slash
    pad = mark_w * 0.7
    draw.line(
        [(x0 - pad, y_bot - mark_h * 0.05),
         (x0 + total_w + pad, y_top + mark_h * 0.05)],
        fill=color,
        width=stroke,
    )


def make_full_icon():
    bg = vertical_gradient(
        SIZE, SIZE, top=(255, 152, 70), bottom=(255, 122, 41)
    )
    img = bg.convert("RGBA")
    draw = ImageDraw.Draw(img)
    # soft inner glow / vignette
    glow = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse(
        (-SIZE * 0.2, -SIZE * 0.4, SIZE * 1.2, SIZE * 1.1),
        fill=(255, 220, 180, 80),
    )
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(radius=80)))
    draw = ImageDraw.Draw(img)
    draw_marks(
        draw,
        cx=SIZE / 2,
        cy=SIZE / 2 + SIZE * 0.02,
        mark_h=SIZE * 0.50,
        mark_w=SIZE * 0.08,
        gap=SIZE * 0.06,
        color=(255, 248, 240, 255),
        stroke=int(SIZE * 0.05),
    )
    img.save(OUT / "icon.png")
    print(f"Wrote {OUT / 'icon.png'}")


def make_foreground():
    # Transparent background, just the marks centered with safe-zone padding.
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_marks(
        draw,
        cx=SIZE / 2,
        cy=SIZE / 2 + SIZE * 0.02,
        mark_h=SIZE * 0.36,
        mark_w=SIZE * 0.06,
        gap=SIZE * 0.045,
        color=(255, 248, 240, 255),
        stroke=int(SIZE * 0.04),
    )
    img.save(OUT / "icon_foreground.png")
    print(f"Wrote {OUT / 'icon_foreground.png'}")


if __name__ == "__main__":
    make_full_icon()
    make_foreground()
