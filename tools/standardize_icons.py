"""Compile retained atlas masters with consistent Civ V padding and gold rims.

This is a deterministic finishing step for the existing artwork. Run after any
individual art generator, or let build_mod run it before making the manifest.
The first run retains the original 256px DDS atlases as lossless PNG masters;
later runs always use those masters, never the already resized/framed output.
Use --refresh-sources ATLAS_NAME only after regenerating that atlas's ORIGINAL
256px artwork. Other masters remain untouched.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import io
import math
import os
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import tempfile
from xml.etree import ElementTree as ET

from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
LEADER_DIAMETER = 0.75  # 96px artwork in the 128px slot of a 100px setup row.
ICON_DIAMETER = 0.90


@dataclass(frozen=True)
class Atlas:
    name: str
    size: int
    path: Path
    columns: int
    rows: int

    @property
    def monochrome(self):
        return "ALPHA" in self.name or "FLAG" in self.name


def inventory(root=ROOT):
    """Read just atlas declarations; never execute gameplay SQL or touch a cache."""
    project = ET.parse(next(root.glob("*.civ5proj")))
    content = [root / e.get("Include").replace("\\", "/")
               for e in project.iter() if e.tag.endswith("}Content") and e.get("Include")]
    textures = {p.name: p for p in content if p.suffix.lower() == ".dds"}
    assert len(textures) == sum(p.suffix.lower() == ".dds" for p in content), "DDS VFS name collision"
    database = sqlite3.connect(":memory:")
    database.execute("CREATE TABLE IconTextureAtlases(Atlas TEXT, IconSize INTEGER, "
                     "Filename TEXT, IconsPerRow INTEGER, IconsPerColumn INTEGER)")
    leaders = set()
    for path in content:
        if path.suffix.lower() != ".sql":
            continue
        source = re.sub(r"--[^\n]*", "", path.read_text(encoding="utf-8-sig"))
        for statement in re.findall(r"INSERT\s+(?:OR\s+\w+\s+)?INTO\s+IconTextureAtlases\b.*?;",
                                    source, re.I | re.S):
            database.executescript(statement)
        for statement in source.split(";"):
            if not re.search(r'\bType"?\s*=\s*\x27LEADER_', statement, re.I):
                continue
            atlas = re.search(r'\bIconAtlas"?\s*=\s*\x27([^\x27]+)', statement, re.I)
            index = re.search(r'\bPortraitIndex"?\s*=\s*(\d+)', statement, re.I)
            if atlas and index:
                leaders.add((atlas[1], int(index[1])))
    atlases = [Atlas(name, size, textures[filename], columns, rows)
               for name, size, filename, columns, rows in database.execute("SELECT * FROM IconTextureAtlases")]
    database.close()
    assert len({(a.name, a.size) for a in atlases}) == len(atlases), "Duplicate atlas size"
    return atlases, leaders


def visible_bounds(cell, threshold=32):
    return cell.getchannel("A").point(lambda a: 255 if a >= threshold else 0).getbbox()


def frame_cell(source, size, leader=False):
    bounds = visible_bounds(source)
    if bounds is None:
        return Image.new("RGBA", (size, size))
    # Remove the old rim before fitting the retained artwork into the new one.
    art = source.crop(bounds)
    trim = round(min(art.size) * .06)
    if trim:
        art = art.crop((trim, trim, art.width - trim, art.height - trim))
    edge = size * 4
    canvas = Image.new("RGBA", (edge, edge))
    diameter = round(edge * (LEADER_DIAMETER if leader else ICON_DIAMETER))
    offset = (edge - diameter) // 2
    draw = ImageDraw.Draw(canvas)
    # Bronze edge, warm gold, and a pale inner bevel remain readable at 16px.
    rim = max(4, round(edge * .024))
    for inset, color in ((0, (94, 61, 20, 255)),
                         (max(1, round(rim * .15)), (225, 176, 65, 255)),
                         (max(2, round(rim * .42)), (255, 225, 144, 255)),
                         (max(3, round(rim * .65)), (191, 136, 38, 255))):
        draw.ellipse((offset + inset, offset + inset,
                      offset + diameter - inset - 1, offset + diameter - inset - 1), fill=color)
    inner = diameter - 2 * rim
    art = ImageOps.fit(art, (inner, inner), Image.Resampling.LANCZOS)
    mask = Image.new("L", art.size)
    ImageDraw.Draw(mask).ellipse((0, 0, inner - 1, inner - 1), fill=255)
    art.putalpha(ImageChops.multiply(art.getchannel("A"), mask))
    canvas.alpha_composite(art, (offset + rim, offset + rim))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def standardize(root=ROOT, refresh=()):
    atlases, leaders = inventory(root)
    master_dir = root / "art-source/IconAtlasMasters"
    master_dir.mkdir(parents=True, exist_ok=True)
    families = {}
    for atlas in atlases:
        # Promotion tier badges already have gold rims and extend beyond their
        # portrait circle. Retain those intentional overlays without clipping.
        if not atlas.monochrome and "PROMOTION" not in atlas.name:
            families.setdefault(atlas.name, []).append(atlas)
    changed = 0
    texconv = shutil.which("texconv") or shutil.which("texconv.exe")
    if not texconv and os.environ.get("LOCALAPPDATA"):
        candidates = sorted((Path(os.environ["LOCALAPPDATA"]) / "Microsoft/WinGet/Packages").glob(
            "Microsoft.DirectXTex.Texconv_*/texconv.exe"))
        if candidates:
            texconv = str(candidates[-1])
    if not texconv:
        raise RuntimeError("DirectXTex texconv is required to compile gold rims accurately as legacy DXT5")
    for name, family in sorted(families.items()):
        largest = max(family, key=lambda a: a.size)
        master = master_dir / (largest.path.stem + ".png")
        if name in refresh or not master.exists():
            with Image.open(largest.path) as image:
                image.convert("RGBA").save(master)
        with Image.open(master) as image:
            source = image.convert("RGBA")
        assert source.size == (largest.size * largest.columns, largest.size * largest.rows), master
        cells = [source.crop((x * largest.size, y * largest.size,
                              (x + 1) * largest.size, (y + 1) * largest.size))
                 for y in range(largest.rows) for x in range(largest.columns)]
        with tempfile.TemporaryDirectory(prefix="compile-", dir=master_dir) as temporary:
            stage = Path(temporary).resolve()
            assert stage.parent == master_dir.resolve(), "Unsafe temporary output directory"
            pngs = []
            encoded = {}
            for atlas in family:
                assert (atlas.columns, atlas.rows) == (largest.columns, largest.rows), name
                output = Image.new("RGBA", (atlas.size * atlas.columns, atlas.size * atlas.rows))
                for index, cell in enumerate(cells):
                    framed = frame_cell(cell, atlas.size, (name, index) in leaders)
                    output.alpha_composite(framed, ((index % atlas.columns) * atlas.size,
                                                     (index // atlas.columns) * atlas.size))
                if output.width % 4 == 0 and output.height % 4 == 0:
                    png = stage / (atlas.path.stem + ".png")
                    output.save(png)
                    pngs.append(str(png))
                else:
                    stream = io.BytesIO()
                    output.save(stream, format="DDS")
                    encoded[atlas.path] = stream.getvalue()
            if pngs:
                result = subprocess.run([texconv, "-nologo", "-y", "-dx9", "-f", "DXT5", "-m", "1",
                                         "-o", str(stage), *pngs], capture_output=True, text=True)
                if result.returncode:
                    raise RuntimeError(result.stdout + result.stderr)
            for atlas in family:
                data = encoded.get(atlas.path)
                if data is None:
                    data = (stage / atlas.path.name).read_bytes()
                if atlas.path.read_bytes() != data:
                    atlas.path.write_bytes(data)
                    changed += 1
    print(f"Gold icon finishing: {len(families)} atlas families, {len(leaders)} leaders, {changed} DDS files updated")
    return atlases, leaders


def validate(root=ROOT):
    atlases, leaders = inventory(root)
    framed_cells = 0
    for atlas in atlases:
        with Image.open(atlas.path) as image:
            image.load()
            assert image.size == (atlas.size * atlas.columns, atlas.size * atlas.rows), atlas.path
            if atlas.monochrome or "PROMOTION" in atlas.name:
                continue
            for index in range(atlas.columns * atlas.rows):
                x, y = index % atlas.columns * atlas.size, index // atlas.columns * atlas.size
                cell = image.crop((x, y, x + atlas.size, y + atlas.size)).convert("RGBA")
                # BC3 quantizes faint antialiasing fringes. Measure the visible
                # medallion, not its low-opacity compression halo.
                bounds = visible_bounds(cell, 96)
                if bounds is None:
                    continue
                leader = (atlas.name, index) in leaders
                expected = round(atlas.size * (LEADER_DIAMETER if leader else ICON_DIAMETER))
                assert abs(bounds[2] - bounds[0] - expected) <= 3, (atlas.path, index, bounds)
                assert abs(bounds[3] - bounds[1] - expected) <= 3, (atlas.path, index, bounds)
                assert abs(bounds[0] + bounds[2] - atlas.size) <= 2, (atlas.path, index, "off centre")
                assert abs(bounds[1] + bounds[3] - atlas.size) <= 2, (atlas.path, index, "off centre")
                # Sample the rim around the circle: BC3 shares a palette with
                # neighbouring artwork, especially in the smallest slots.
                gold = 0
                radius = expected / 2 - max(.5, atlas.size * .012)
                for angle in (n * math.tau / 32 for n in range(32)):
                    px = round((atlas.size - 1) / 2 + radius * math.cos(angle))
                    py = round((atlas.size - 1) / 2 + radius * math.sin(angle))
                    for y in range(max(0, py - 1), min(atlas.size, py + 2)):
                        for x in range(max(0, px - 1), min(atlas.size, px + 2)):
                            r, g, b, a = cell.getpixel((x, y))
                            gold += a >= 96 and r > 120 and r >= g and g > b * 1.25
                assert gold, (atlas.path, index, "missing gold rim")
                framed_cells += 1
    assert leaders, "No custom leader portrait slots found"
    assert all(any(a.name == name and a.size == 128 for a in atlases) for name, _ in leaders)
    print(f"PASS icon dimensions: {len(atlases)} atlas sizes, {len(leaders)} leaders, {framed_cells} framed cells; decoded gold rims and centred padding")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate without rewriting art")
    parser.add_argument("--refresh-sources", nargs="+", default=[], metavar="ATLAS",
                        help="Capture newly regenerated ORIGINAL artwork for these atlas names")
    args = parser.parse_args()
    if not args.check:
        standardize(refresh=args.refresh_sources)
    validate()


if __name__ == "__main__":
    main()
