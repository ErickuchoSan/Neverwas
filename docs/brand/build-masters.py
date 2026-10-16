"""Builds the Neverwas logo masters (SVG, wordmark converted to curves).

Requires Python 3 with fontTools. Run from the repo root:
    python docs/brand/build-masters.py

The SVGs in docs/brand/logo/ are the source of truth for the brand. The raster assets the app
ships (logo.ico, 3.png, bigImage.bmp) are drawn from the same geometry by tools/new-brand-assets.ps1.
"""
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

HERE = Path(__file__).resolve().parent
OUT = HERE / "logo"

PRIMARY = "#6656F0"
INK = "#17151F"
WHITE = "#FFFFFF"

# Symbol on a 14-unit tile (the 16-unit icon grid minus its 1-unit margin), scaled by U.
# Tile: rounded square 14x14, radius 3. N: stems 2 wide, from y=2 to y=12, left stem at x=3,
# right stem ending at x=11. The diagonal is 1.165x wider so it looks as heavy as the stems.
# The right stem runs out through the top edge: the tile is open where the program left.
U = 16
TILE = 14 * U
RADIUS = 3 * U
SW = 2 * U
DIAG = SW * 1.165
L0, L1 = 3 * U, 3 * U + SW
R1 = TILE - 3 * U
R0 = R1 - SW
TOP, BOTTOM = 2 * U, 12 * U


def _cross_y(x, x_top, x_bottom):
    """y where the diagonal edge running from (x_top, TOP) to (x_bottom, BOTTOM) crosses x."""
    return TOP + (x - x_top) / (x_bottom - x_top) * (BOTTOM - TOP)


def n_polygon(top_y):
    """The N as one outline; the right stem starts at top_y."""
    y_right = _cross_y(R0, L0 + DIAG, R1)
    y_left = _cross_y(L1, L0, R1 - DIAG)
    return [
        (L0, TOP), (L0 + DIAG, TOP), (R0, y_right), (R0, top_y), (R1, top_y), (R1, BOTTOM),
        (R1 - DIAG, BOTTOM), (L1, y_left), (L1, BOTTOM), (L0, BOTTOM),
    ]


def fmt(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def pts(points, dx=0.0, dy=0.0, s=1.0):
    return " ".join(f"{fmt(dx + x * s)},{fmt(dy + y * s)}" for x, y in points)


def tile_with_n_cut(dx=0.0, dy=0.0, s=1.0):
    """Tile minus the N, as one path: the cut enters through the top edge at the right stem."""
    r = RADIUS * s
    t = TILE * s

    def p(x, y):
        return f"{fmt(dx + x * s)},{fmt(dy + y * s)}"

    n = n_polygon(0)
    # Walk the N outline from the right stem's left edge back around to its right edge.
    inner = [n[2], n[1], n[0], n[9], n[8], n[7], n[6], n[5]]
    d = [f"M{p(RADIUS, 0)}", f"L{p(R0, 0)}"]
    d += [f"L{p(x, y)}" for x, y in inner]
    d += [f"L{p(R1, 0)}", f"L{p(TILE - RADIUS, 0)}",
          f"A{fmt(r)},{fmt(r)} 0 0 1 {fmt(dx + t)},{fmt(dy + r)}",
          f"L{fmt(dx + t)},{fmt(dy + t - r)}",
          f"A{fmt(r)},{fmt(r)} 0 0 1 {fmt(dx + t - r)},{fmt(dy + t)}",
          f"L{fmt(dx + r)},{fmt(dy + t)}",
          f"A{fmt(r)},{fmt(r)} 0 0 1 {fmt(dx)},{fmt(dy + t - r)}",
          f"L{fmt(dx)},{fmt(dy + r)}",
          f"A{fmt(r)},{fmt(r)} 0 0 1 {fmt(dx + r)},{fmt(dy)}", "Z"]
    return " ".join(d)


def symbol(kind, dx=0.0, dy=0.0, s=1.0):
    """kind: 'color' (primary tile, white N), or a single fill colour for the cut-out tile."""
    if kind == "color":
        return (f'<rect x="{fmt(dx)}" y="{fmt(dy)}" width="{fmt(TILE * s)}" height="{fmt(TILE * s)}" '
                f'rx="{fmt(RADIUS * s)}" fill="{PRIMARY}"/>'
                f'<polygon points="{pts(n_polygon(0), dx, dy, s)}" fill="{WHITE}"/>')
    return f'<path d="{tile_with_n_cut(dx, dy, s)}" fill="{kind}"/>'


FONT = TTFont(HERE / "fonts" / "Manrope-Bold.ttf")
UPM = FONT["head"].unitsPerEm
X_HEIGHT = FONT["OS/2"].sxHeight


def wordmark(text, x, baseline, size, fill):
    """Text converted to curves; returns (svg, advance width)."""
    glyphs = FONT.getGlyphSet()
    cmap = FONT.getBestCmap()
    hmtx = FONT["hmtx"]
    scale = size / UPM
    paths, pen_x = [], 0.0
    for ch in text:
        name = cmap[ord(ch)]
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, x + pen_x * scale, baseline)))
        paths.append(pen.getCommands())
        pen_x += hmtx[name][0]
    return f'<path d="{" ".join(paths)}" fill="{fill}"/>', pen_x * scale


def svg(width, height, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {fmt(width)} {fmt(height)}" '
            f'width="{fmt(width)}" height="{fmt(height)}" role="img" aria-label="{title}">'
            f"<title>{title}</title>{body}</svg>\n")


WORD = "neverwas"
# Horizontal lockup: wordmark x-height = 45% of the tile, centred on it; gap = 1/4 tile.
H_SIZE = TILE * 0.45 / (X_HEIGHT / UPM)
H_GAP = TILE / 4
# Vertical lockup: wordmark 1.5x the tile width, 1/4 tile gap below the tile.
V_GAP = TILE / 4


def build():
    OUT.mkdir(exist_ok=True)
    variants = {"color": (PRIMARY, "color"), "negro": (INK, INK), "blanco": (WHITE, WHITE)}
    written = []
    for name, (word_fill, sym_kind) in variants.items():
        # Isotipo
        written.append((f"neverwas-isotipo-{name}.svg", svg(TILE, TILE, symbol(sym_kind), "Neverwas")))
        # Horizontal
        x_h = TILE * 0.45
        baseline = TILE / 2 + x_h / 2
        word, adv = wordmark(WORD, TILE + H_GAP, baseline, H_SIZE, INK if name == "color" else word_fill)
        written.append((f"neverwas-horizontal-{name}.svg",
                        svg(TILE + H_GAP + adv, TILE, symbol(sym_kind) + word, "Neverwas")))
        # Vertical
        _, probe_adv = wordmark(WORD, 0, 0, 100, word_fill)
        v_size = 100 * (TILE * 1.5) / probe_adv
        v_xh = X_HEIGHT / UPM * v_size
        width = TILE * 1.5
        word, adv = wordmark(WORD, 0, TILE + V_GAP + v_xh, v_size, INK if name == "color" else word_fill)
        written.append((f"neverwas-vertical-{name}.svg",
                        svg(width, TILE + V_GAP + v_xh * 1.03,
                            symbol(sym_kind, (width - TILE) / 2, 0) + word, "Neverwas")))
    # Negative colour lockups: for dark or primary backgrounds the tile is white and the N lets the
    # background through, so they are the "blanco" files.
    for file_name, content in written:
        (OUT / file_name).write_text(content, encoding="utf-8")
    print("\n".join(f for f, _ in written))


if __name__ == "__main__":
    build()
