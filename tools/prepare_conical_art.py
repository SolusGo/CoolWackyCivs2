"""Compile retained original Conical Union paintings with the collection DDS pipeline."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R = Path(__file__).resolve().parents[1]
S = R / 'art-source/TheConicalUnion'
V = R / 'TheConicalUnion/Art'
SIZES = [16, 24, 32, 45, 48, 64, 80, 128, 256]

def cone_alpha():
    im = Image.new('RGBA', (256, 256))
    d = ImageDraw.Draw(im)
    d.polygon([(128, 23), (61, 209), (195, 209)], fill='white')
    d.rounded_rectangle((40, 207, 216, 233), radius=8, fill='white')
    # Transparent band cutouts survive the player's native color tint.
    d.polygon([(108, 79), (148, 79), (156, 101), (100, 101)], fill=(0, 0, 0, 0))
    d.polygon([(87, 139), (169, 139), (177, 161), (79, 161)], fill=(0, 0, 0, 0))
    return im

def network_map():
    im = Image.new('RGBA', (512, 512), '#d9c8a2')
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((15, 15, 497, 497), radius=14, outline='#28333a', width=8)
    for points in [[(81, 113), (241, 97), (389, 155), (421, 343)],
                   [(81, 113), (128, 338), (268, 402), (421, 343)],
                   [(128, 338), (260, 246), (389, 155)], [(241, 97), (260, 246), (268, 402)]]:
        d.line(points, fill='#6c6860', width=15)
        d.line(points, fill='#f5e9ce', width=3)
    for x, y in [(81, 113), (241, 97), (389, 155), (421, 343), (128, 338), (268, 402), (260, 246)]:
        d.ellipse((x-20, y-20, x+20, y+20), fill='#28333a', outline='#bb8b35', width=3)
        d.polygon([(x, y-14), (x-10, y+10), (x+10, y+10)], fill='#ff731c')
        d.line((x-5, y, x+5, y), fill='white', width=4)
    return im

def save(im, name, size):
    (V / name).write_bytes(raw_mips(ImageOps.fit(im, size, Image.Resampling.LANCZOS)))

def main():
    V.mkdir(parents=True, exist_ok=True)
    painting = Image.open(S / 'Bollard.png').convert('RGBA')
    w, h = painting.size
    portrait = painting.crop((round(w*.24), round(h*.02), round(w*.63), round(h*.82)))
    objects = Image.new('RGBA', (512, 256))
    for i, name in enumerate(['DetourOffice.png', 'RoadCrew.png']):
        objects.alpha_composite(ImageOps.fit(Image.open(S/name).convert('RGBA'), (256, 256), Image.Resampling.LANCZOS), (i*256, 0))
    masters = {'Icon': Image.open(S/'ConeEmblem.png').convert('RGBA'), 'Alpha': cone_alpha(),
               'Portrait': portrait, 'Objects': objects}
    for stem, master in masters.items():
        master = ImageOps.fit(master, (512 if stem == 'Objects' else 256, 256), Image.Resampling.LANCZOS)
        for size in SIZES:
            (V/f'CONICAL_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*(2 if stem == 'Objects' else 1), size), Image.Resampling.LANCZOS)))
    save(cone_alpha(), 'CONICAL_Flag32.dds', (32, 32))
    save(painting, 'CONICAL_Leader.dds', (1600, 900))
    save(painting, 'CONICAL_Dawn.dds', (1024, 768))
    save(network_map(), 'CONICAL_Map.dds', (512, 512))
    (V/'CONICAL_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="CONICAL_Leader.dds" />\n', encoding='utf-8', newline='\n')
    preview = Image.new('RGBA', (1024, 256), '#20272d')
    for i, im in enumerate([masters['Icon'], portrait, objects.crop((256, 0, 512, 256)), objects.crop((0, 0, 256, 256))]):
        preview.alpha_composite(ImageOps.fit(im, (256, 256), Image.Resampling.LANCZOS), (i*256, 0))
    preview.convert('RGB').save(S/'Preview.png')
    print('Compiled 40 Conical Union mipmapped legacy DDS textures and the silent 2D leader scene')

if __name__ == '__main__':
    main()
