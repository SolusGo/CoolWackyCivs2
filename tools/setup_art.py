"""Fit civilization maps to the 360×410 game window on a block-aligned DDS."""
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

from dds_mips import raw_mips

MAP_WINDOW = (360, 410)
MAP_SIZE = (360, 412)
RESAMPLE = Image.Resampling.LANCZOS


def fit_canvas(source, size):
    """Preserve the whole image and its proportions, including labels at the edges."""
    image = source.convert('RGBA')
    foreground = ImageOps.contain(image, size, RESAMPLE)
    if foreground.size == size:
        return foreground
    # Extend the artwork into the margins without duplicating sharp detail.
    background = ImageOps.fit(image, size, RESAMPLE).filter(ImageFilter.GaussianBlur(24))
    left = (size[0] - foreground.width) // 2
    top = (size[1] - foreground.height) // 2
    background.paste(foreground, (left, top))
    return background


def map_canvas(source):
    window = fit_canvas(source, MAP_WINDOW)
    canvas = Image.new('RGBA', MAP_SIZE)
    canvas.paste(window)
    canvas.paste(window.crop((0, MAP_WINDOW[1] - 1, MAP_WINDOW[0], MAP_WINDOW[1])).resize((MAP_SIZE[0], 2)),
                 (0, MAP_WINDOW[1]))
    return canvas


def write_map(source, path: Path):
    path.write_bytes(raw_mips(map_canvas(source)))
