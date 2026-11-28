"""Prepare original artwork and code-drawn insignia as legacy RGBA DDS textures."""
import argparse
from pathlib import Path
import math
from PIL import Image, ImageChops, ImageDraw
R=Path(__file__).resolve().parents[1]; V=R/'TheBoundlessCity/Art'
SOURCE = R / 'art-source/TheBoundlessCity'
SIZES=[16,24,32,45,48,64,80,128,256]
BLUE=(10,26,53,255); GOLD=(227,189,94,255); IVORY=(247,239,210,255)


def prepare_civ_icon():
    with Image.open(SOURCE / 'GateReference.png') as image:
        # Keep the reference's square medallion and the antialiasing around it.
        reference = image.convert('RGB').crop((25, 7, 129, 111))
    center = (51.5, 51.5)
    matte = (14, 14, 14)
    navy = (9, 23, 51)
    gold = (216, 183, 96)
    color = Image.new('RGBA', reference.size)
    mask = Image.new('L', reference.size)
    for y in range(reference.height):
        for x in range(reference.width):
            r, g, b = reference.getpixel((x, y))
            distance = math.dist((x, y), center)
            if r == g == b == matte[0]:
                continue
            if distance >= 50:
                # The screenshot blends the outer gold edge into its gray matte.
                # Remove that matte while retaining the original fractional edge.
                coverage = min(1, max(0, (r - matte[0]) / (gold[0] - matte[0])))
                if abs(b - (matte[2] + coverage * (gold[2] - matte[2]))) <= 2:
                    color.putpixel((x, y), (*gold, round(255 * coverage)))
                    continue
            color.putpixel((x, y), (r, g, b, 255))
            if distance < 49:
                # Civ V supplies a background for this mask. Extract only the gate.
                coverage = min(1, max(0, (r - navy[0]) / (gold[0] - navy[0])))
                mask.putpixel((x, y), round(255 * coverage))
    gate = mask.point(lambda value: 255 if value else 0)
    ImageDraw.floodfill(gate, (52, 82), 128)  # The middle of the gate's sill.
    mask = ImageChops.multiply(mask, gate.point(lambda value: 255 if value == 128 else 0))

    # The crop includes a pixel of antialiasing on each side of a 102px disk.
    # Keep the display diameter at the collection's 90% of the atlas slot.
    def place(image):
        canvas = Image.new(image.mode, (256, 256))
        canvas.paste(image.resize((234, 234), Image.Resampling.LANCZOS), (11, 11))
        return canvas

    seal = place(color)
    seal.save(R / 'art-source/IconAtlasMasters/BoundlessIcon256.png')
    silhouette = Image.new('RGBA', (256, 256), IVORY)
    silhouette.putalpha(place(mask))
    for size in SIZES:
        save(silhouette, f'BoundlessAlpha{size}.dds', (size, size))
    save(silhouette, 'BoundlessFlag32.dds', (32, 32))

    preview = Image.new('RGBA', (512 * 3, 512), BLUE)
    preview.alpha_composite(seal.resize((512, 512), Image.Resampling.LANCZOS))
    for index, kind in enumerate(('registry', 'surveyor'), 1):
        preview.paste(emblem(kind), (index * 512, 0))
    preview.convert('RGB').save(SOURCE / 'InsigniaPreview.png')


def emblem(kind):
    im=Image.new('RGBA',(512,512),(0,0,0,0));d=ImageDraw.Draw(im)
    d.ellipse((12,12,500,500),fill=BLUE,outline=GOLD,width=14)
    d.ellipse((34,34,478,478),outline=GOLD,width=2)
    color=GOLD
    if kind=='registry':
        d.rectangle((116,224,396,373),outline=color,width=14)
        d.polygon([(96,224),(256,106),(416,224)],outline=color,width=14)
        for x in [146,206,286,346]:d.line([(x,248),(x,350)],fill=color,width=14)
        d.line([(96,392),(416,392)],fill=color,width=18)
    else:
        d.ellipse((150,98,362,310),outline=color,width=12)
        d.line([(256,98),(256,310)],fill=color,width=4)
        d.line([(150,204),(362,204)],fill=color,width=4)
        d.line([(256,180),(156,412)],fill=color,width=18)
        d.line([(256,180),(356,412)],fill=color,width=18)
        d.ellipse((234,155,278,199),fill=color)
    return im

def save(im,name,size):
    im.resize(size,Image.Resampling.LANCZOS).save(V/name)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--icon-only', action='store_true', help='Prepare the Boundless City emblem and tintable mask')
    args = parser.parse_args()
    V.mkdir(parents=True,exist_ok=True)
    prepare_civ_icon()
    if args.icon_only:
        from standardize_icons import standardize
        standardize(only=('BC_CIV_ATLAS',))
        return
    source=Image.open(R/'art-source/TheBoundlessCity/ArchitectAndWorld.png').convert('RGBA')
    save(source,'BoundlessDawn.dds',(1024,768))
    save(source,'BoundlessLeader.dds',(1600,900))
    from prepare_boundless_map import main as prepare_map
    prepare_map()
    portrait=source.crop((55,20,600,565))
    for size in SIZES:
        objects=Image.new('RGBA',(size*2,size),(0,0,0,0))
        for index,kind in enumerate(['registry','surveyor']):
            objects.paste(emblem(kind).resize((size,size),Image.Resampling.LANCZOS),(index*size,0))
        objects.save(V/f'BoundlessObjects{size}.dds')
    for size in [64,128,256]:
        icon=portrait.resize((size,size),Image.Resampling.LANCZOS)
        mask=Image.new('L',(size,size),0);ImageDraw.Draw(mask).ellipse((1,1,size-2,size-2),fill=255)
        icon.putalpha(mask);icon.save(V/f'BoundlessPortrait{size}.dds')
    (V/'BoundlessLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="BoundlessLeader.dds" />\n',encoding='utf-8',newline='\n')
    print('Prepared',len(list(V.glob('*.dds'))),'real DDS textures and the 2D leader scene')
    from prepare_boundless_ui import main as prepare_workforce
    prepare_workforce()
    from prepare_pigeon_art import main as prepare_pigeons
    prepare_pigeons()
    from prepare_saba_art import main as prepare_saba
    prepare_saba()
    from prepare_garvey_art import main as prepare_garvey
    prepare_garvey()
    from prepare_conical_art import main as prepare_conical
    prepare_conical()
    from prepare_unrung_art import main as prepare_unrung
    prepare_unrung()
    from prepare_jin_art import main as prepare_jin
    prepare_jin()
    from prepare_threshold_art import main as prepare_threshold
    prepare_threshold()
    from prepare_t1zofgk_art import main as prepare_t1zofgk
    prepare_t1zofgk()

if __name__=='__main__':main()
