"""Compile original Workforce artwork and precise UI materials to legacy RGBA DDS.

No network calls. Keeps the existing game artwork and all other civ assets intact.
"""
from pathlib import Path
import random
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R = Path(__file__).resolve().parents[1]
S = R / 'art-source/TheBoundlessCity/WorkforceUI'
V = R / 'TheBoundlessCity/Art'
SIZES = {'Panel': (900, 700), 'Launcher': (245, 36), 'Row': (834, 66),
         'Buttons': (64, 256), 'Assigned': (4, 54), 'Pending': (4, 54)}


def material(size, top=(18, 39, 43), bottom=(9, 22, 28), seed=17):
    im = Image.new('RGBA', size)
    p = im.load(); rng = random.Random(seed)
    for y in range(size[1]):
        t = y / max(1, size[1]-1)
        color = [round(a+(b-a)*t) for a,b in zip(top,bottom)]
        for x in range(size[0]):
            grain = rng.choice((-1, 0, 0, 0, 1))
            p[x,y] = tuple(max(0,min(255,c+grain)) for c in color)+(255,)
    return im


def rim(d, box, bright=False):
    x,y,r,b = box
    d.rectangle(box, outline='#060e12')
    d.rectangle((x+1,y+1,r-1,b-1), outline='#ae8d50' if bright else '#655b40')
    d.line((x+2,y+2,r-2,y+2), fill='#d4b36c' if bright else '#9b8653')
    d.line((x+2,b-2,r-2,b-2), fill='#17272a')


def panel():
    im = material(SIZES['Panel'])
    art = ImageOps.fit(Image.open(S/'EngravedCity.png').convert('RGBA'), (900, 300), Image.Resampling.LANCZOS)
    # A format/layout composite: the source painting remains unchanged on disk.
    im.alpha_composite(art, (0,-48))
    shade = Image.new('RGBA', (900, 252)); sd = ImageDraw.Draw(shade)
    for y in range(252):
        alpha = round(255*min(1, max(0, (y-58)/175)))
        sd.line((0,y,899,y), fill=(10,25,30,alpha))
    im.alpha_composite(shade)
    d = ImageDraw.Draw(im)
    # Fine engraved construction lines, deliberately quieter than live labels.
    for x in range(28,875,44): d.line((x,296,x,614),fill='#132b30')
    for y in range(304,615,44): d.line((24,y,875,y),fill='#132b30')
    for x,w in [(22,276),(304,276),(586,272)]:
        d.rectangle((x,102,x+w-1,294),fill='#10252c')
        rim(d,(x,102,x+w-1,294))
    d.rectangle((20,350,879,568),fill='#09171e');rim(d,(20,350,879,568))
    d.rectangle((20,620,879,688),fill='#10252b');rim(d,(20,620,879,688))
    for y in [96,300,614]:
        d.line((22,y,877,y),fill='#5e573b');d.line((22,y+1,877,y+1),fill='#08171c')
        d.polygon([(447,y),(450,y-3),(453,y),(450,y+3)],fill='#bc9a58')
    # Bespoke brass edge and stepped corner ornaments.
    rim(d,(0,0,899,699),True);d.rectangle((5,5,894,694),outline='#4a523f')
    d.rectangle((9,9,890,690),outline='#283e3c')
    for x,sx in [(12,1),(887,-1)]:
        for y,sy in [(12,1),(687,-1)]:
            d.line([(x,y+sy*23),(x,y),(x+sx*23,y)],fill='#d0ad65',width=2)
            d.line([(x+sx*5,y+sy*17),(x+sx*5,y+sy*5),(x+sx*17,y+sy*5)],fill='#776c46')
            d.polygon([(x+sx*4,y),(x+sx*8,y+sy*4),(x+sx*4,y+sy*8),(x,y+sy*4)],fill='#c3a261')
    return im


def buttons():
    # Native Grid9FrameButtons coordinates: 44px slices, 45px state stride.
    # Four states remain native: normal, hover, pressed and disabled.
    sheet = Image.new('RGBA', SIZES['Buttons'])
    for n,(top,bottom,edge) in enumerate([
        ((25,55,61),(10,29,36),'#b99a5f'),
        ((42,80,82),(18,46,52),'#f2d899'),
        ((7,23,30),(20,44,49),'#d8b86f'),
        ((25,31,33),(17,23,27),'#665f4e')]):
        tile = material((44,44),top,bottom,seed=25+n);d=ImageDraw.Draw(tile)
        d.rectangle((0,0,43,43),outline='#071319')
        d.rectangle((1,1,42,42),outline=edge)
        d.rectangle((3,3,40,40),outline='#364b46' if n!=3 else '#303b3b')
        d.line((4,4,39,4),fill=edge)
        d.line((4,39,39,39),fill='#09171c')
        for x in [3,40]:
            for y in [3,40]:d.point((x,y),fill=edge)
        sheet.alpha_composite(tile,(0,n*45))
    return sheet


def assets():
    row = material(SIZES['Row'], (23,43,48), (12,29,36));d=ImageDraw.Draw(row)
    rim(d,(0,0,833,65));d.line((524,10,524,55),fill='#3b4e48')
    launcher = material(SIZES['Launcher']);rim(ImageDraw.Draw(launcher),(0,0,244,35),True)
    return {'Panel':panel(), 'Launcher':launcher, 'Row':row, 'Buttons':buttons(),
            'Assigned':material(SIZES['Assigned'],(128,222,185),(40,115,104)),
            'Pending':material(SIZES['Pending'],(236,196,114),(143,103,51))}


def main():
    V.mkdir(parents=True,exist_ok=True)
    for name,im in assets().items():
        assert im.size == SIZES[name]
        im.save(S/('BC_UI_'+name+'.png'))
        (V/('BC_UI_'+name+'.dds')).write_bytes(raw_mips(im))
    print('Compiled six original Workforce DDS textures with complete mip chains')


if __name__ == '__main__':main()
