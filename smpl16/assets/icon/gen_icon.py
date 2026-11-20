#!/usr/bin/env python3
"""Generate the SMPL16 icon SVG + HTML wrappers.

    python3 gen_icon.py /tmp/icon && for v in full foreground; do
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
        --screenshot=/tmp/icon/$v.png --window-size=1024,1024 --hide-scrollbars \
        --default-background-color=00000000 file:///tmp/icon/icon_$v.html; done

Then copy full.png -> icon.png (flatten alpha) and foreground.png ->
icon_foreground.png and run `dart run flutter_launcher_icons`. Chrome is used
because ImageMagick's SVG renderer drops the gradients and the glow filter.
The "16" is set in Menlo, so the SVG renders slightly differently on machines
without it; the PNGs are the source of truth.

variants:
  full        1024 full-bleed square, dark background (iOS / store / legacy)
  foreground  1024 transparent, grid shrunk into the adaptive-icon safe zone
"""
import sys, pathlib

BG = "#080a08"
ACCENT = "#c8f000"
ACCENT2 = "#ff6b00"
PAD = "#1d251b"
PAD_EDGE = "#3a483a"

# (row, col) -> colour of lit pads
LIT = {
    (0, 0): ACCENT,
    (1, 2): ACCENT,
    (2, 1): ACCENT,
    (0, 3): ACCENT2,
    (3, 3): ACCENT,
}
LABEL_PAD = (3, 3)  # pad carrying "16"


def svg(variant: str) -> str:
    size = 1024
    span = 780 if variant == "full" else 640  # grid width
    gap = span * 0.055
    s = (span - 3 * gap) / 4
    r = s * 0.2
    x0 = (size - span) / 2
    y0 = (size - span) / 2
    parts = []
    parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">')
    parts.append("""<defs>
  <radialGradient id="bg" cx="50%" cy="42%" r="75%">
    <stop offset="0" stop-color="#18200f"/>
    <stop offset="0.55" stop-color="#0d110c"/>
    <stop offset="1" stop-color="#080a08"/>
  </radialGradient>
  <linearGradient id="gloss" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#ffffff" stop-opacity="0.07"/>
    <stop offset="0.5" stop-color="#ffffff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="lime" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#dcff3a"/>
    <stop offset="1" stop-color="#a8cc00"/>
  </linearGradient>
  <linearGradient id="orange" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ff8a2e"/>
    <stop offset="1" stop-color="#e85a00"/>
  </linearGradient>
  <filter id="glow" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="26"/>
  </filter>
</defs>""")
    if variant == "full":
        parts.append(f'<rect width="{size}" height="{size}" fill="url(#bg)"/>')
    # glows first
    for (row, col), colour in LIT.items():
        x = x0 + col * (s + gap)
        y = y0 + row * (s + gap)
        parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{s:.1f}" height="{s:.1f}" rx="{r:.1f}" fill="{colour}" opacity="0.7" filter="url(#glow)"/>')
    sw = s * 0.035
    for row in range(4):
        for col in range(4):
            x = x0 + col * (s + gap)
            y = y0 + row * (s + gap)
            colour = LIT.get((row, col))
            if colour:
                fill = "url(#lime)" if colour == ACCENT else "url(#orange)"
                parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{s:.1f}" height="{s:.1f}" rx="{r:.1f}" fill="{fill}"/>')
            else:
                parts.append(f'<rect x="{x+sw/2:.1f}" y="{y+sw/2:.1f}" width="{s-sw:.1f}" height="{s-sw:.1f}" rx="{r:.1f}" fill="{PAD}" stroke="{PAD_EDGE}" stroke-width="{sw:.1f}"/>')
            parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{s:.1f}" height="{s:.1f}" rx="{r:.1f}" fill="url(#gloss)"/>')
            if (row, col) == LABEL_PAD:
                parts.append(
                    f'<text x="{x + s/2:.1f}" y="{y + s*0.68:.1f}" text-anchor="middle" '
                    f'font-family="Menlo, \'SF Mono\', monospace" font-weight="700" '
                    f'font-size="{s*0.52:.1f}" fill="{BG}" letter-spacing="-2">16</text>')
    parts.append("</svg>")
    return "\n".join(parts)


def html(svg_text: str) -> str:
    return ("<!doctype html><html><head><meta charset='utf-8'><style>"
            "html,body{margin:0;padding:0;background:transparent;width:1024px;height:1024px;overflow:hidden}"
            "svg{display:block}</style></head><body>" + svg_text + "</body></html>")


if __name__ == "__main__":
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for v in ("full", "foreground"):
        t = svg(v)
        (out / f"icon_{v}.svg").write_text(t)
        (out / f"icon_{v}.html").write_text(html(t))
