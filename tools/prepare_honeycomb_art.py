"""Compile retained original paintings and a code-native bee alpha to real mipmapped DDS."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips
from standardize_icons import frame_cell

R = Path(__file__).resolve().parents[1]
S = R / 'art-source/TheHoneycombCommonwealth'
V = R / 'TheHoneycombCommonwealth/Art'
SIZES = [16,24,32,45,48,64,80,128,256]

def alpha():
    im = Image.new('RGBA', (256,256))
    d = ImageDraw.Draw(im)
    for box in [(38,56,125,142), (131,56,218,142)]: d.ellipse(box, fill='white')
    d.ellipse((94,74,162,214), fill='white')
    d.ellipse((99,45,157,101), fill='white')
    for y in [117,150,183]: d.rectangle((94,y,162,y+9), fill=(0,0,0,0))
    d.line([(111,52),(91,28)], fill='white', width=9)
    d.line([(145,52),(165,28)], fill='white', width=9)
    return im

def map_image():
    im = Image.new('RGBA',(512,512),'#38220e')
    d = ImageDraw.Draw(im)
    for row in range(6):
        for col in range(6):
            x,y = 42 + col*86 + (row%2)*43, 40 + row*74
            points = [(x+45*math.cos(math.pi/3*i+math.pi/6), y+45*math.sin(math.pi/3*i+math.pi/6)) for i in range(6)]
            d.polygon(points, fill='#ad762b' if (row+col)%3 else '#e7b44d', outline='#fff0ad', width=3)
    im.alpha_composite(alpha().resize((180,180)),(166,166))
    return im

def main():
    V.mkdir(parents=True, exist_ok=True)
    painting = Image.open(S/'Mellia.png').convert('RGBA')
    w,h = painting.size
    # Mechanical export/crop only; retain the original generated paintings.
    portrait = painting.crop((int(w*.52),0,int(w*.98),int(h*.71)))
    objects = Image.new('RGBA',(512,256))
    for i,name in enumerate(['Forager','Exchange']):
        objects.paste(ImageOps.fit(Image.open(S/(name+'.png')).convert('RGBA'),(256,256)),(i*256,0))
    masters = {'Icon':Image.open(S/'CivIcon.png').convert('RGBA'), 'Alpha':alpha(),
               'Portrait':portrait, 'Objects':objects}
    for stem,im in masters.items():
        im = ImageOps.fit(im, (512 if stem=='Objects' else 256,256), Image.Resampling.LANCZOS)
        im.save(S/(stem+'.png'))
        if stem != 'Alpha':
            retained = R/'art-source/IconAtlasMasters'/f'HCC_{stem}256.png'
            retained.parent.mkdir(parents=True,exist_ok=True)
            im.save(retained)
        for size in SIZES:
            cols = 2 if stem=='Objects' else 1
            out = Image.new('RGBA',(size*cols,size))
            for i in range(cols):
                cell = im.crop((i*256,0,(i+1)*256,256))
                cell = cell.resize((size,size),Image.Resampling.LANCZOS) if stem=='Alpha' else frame_cell(cell,size,stem=='Portrait')
                out.alpha_composite(cell,(i*size,0))
            (V/f'HCC_{stem}{size}.dds').write_bytes(raw_mips(out))
    (V/'HCC_Flag32.dds').write_bytes(raw_mips(alpha().resize((32,32),Image.Resampling.LANCZOS)))
    for name,im,size in [('Leader',painting,(1600,900)), ('Dawn',painting,(1024,768)), ('Map',map_image(),(512,512))]:
        (V/f'HCC_{name}.dds').write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))
    (V/'HCC_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="HCC_Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview = Image.new('RGBA',(1024,256),'#38220e')
    for i,im in enumerate([masters['Icon'],masters['Portrait'],objects.crop((0,0,256,256)),objects.crop((256,0,512,256))]):
        preview.alpha_composite(im.resize((256,256)),(i*256,0))
    preview.convert('RGB').save(S/'Preview.png')
    print('Compiled 40 genuine HCC DDS textures and static leader scene')

if __name__ == '__main__': main()
