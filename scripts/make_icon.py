"""Color Rush 앱 아이콘 생성 스크립트.

실행:  python scripts/make_icon.py
출력:  app/assets/icon/icon.png            (1024x1024, 스토어/일반용)
       app/assets/icon/icon_foreground.png (1024x1024, Android 적응형 전경)

이후 앱 아이콘 적용:
  cd app && dart run flutter_launcher_icons
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

BG = (18, 19, 26, 255)  # #12131A
COLORS = [
    (255, 71, 87),  # red
    (255, 127, 80),  # orange
    (255, 192, 72),  # yellow
    (46, 213, 115),  # green
    (61, 155, 255),  # blue
    (165, 94, 234),  # purple
]
WHITE = (241, 242, 246, 255)

SIZE = 1024
SS = 4  # supersampling for smooth edges


def draw_mark(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
    """6-segment color ring + dark hole + white check mark."""
    ring_w = r * 0.38
    box = (cx - r, cy - r, cx + r, cy + r)
    gap = 4  # degrees between segments
    for i, color in enumerate(COLORS):
        start = i * 60 - 90 + gap / 2
        end = (i + 1) * 60 - 90 - gap / 2
        draw.arc(box, start=start, end=end, fill=color, width=int(ring_w))

    # check mark, centered in the hole
    s = r * 0.52
    pts = [
        (cx - s * 0.55, cy + s * 0.05),
        (cx - s * 0.12, cy + s * 0.48),
        (cx + s * 0.62, cy - s * 0.42),
    ]
    draw.line(pts, fill=WHITE, width=int(r * 0.16), joint="curve")
    for p in pts:  # round the line ends
        rr = r * 0.08
        draw.ellipse((p[0] - rr, p[1] - rr, p[0] + rr, p[1] + rr), fill=WHITE)


def render(radius_ratio: float, transparent_bg: bool) -> Image.Image:
    size = SIZE * SS
    bg = (0, 0, 0, 0) if transparent_bg else BG
    img = Image.new("RGBA", (size, size), bg)
    draw = ImageDraw.Draw(img)
    draw_mark(draw, size / 2, size / 2, size * radius_ratio)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    out_dir = Path(__file__).resolve().parent.parent / "app" / "assets" / "icon"
    out_dir.mkdir(parents=True, exist_ok=True)

    # 일반 아이콘: 꽉 찬 다크 배경 + 마크
    render(0.36, transparent_bg=False).save(out_dir / "icon.png")

    # Android 적응형 전경: 투명 배경, 세이프존(중앙 66%) 안에 마크
    render(0.26, transparent_bg=True).save(out_dir / "icon_foreground.png")

    print(f"OK: {out_dir / 'icon.png'}")
    print(f"OK: {out_dir / 'icon_foreground.png'}")


if __name__ == "__main__":
    main()
