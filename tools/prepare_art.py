"""Prepare original artwork and code-drawn insignia as legacy RGBA DDS textures."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageOps
R=Path(__file__).resolve().parents[1]; V=R/'TheBoundlessCity/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
BLUE=(10,26,53,255); GOLD=(227,189,94,255); IVORY=(247,239,210,255)

def emblem(kind,alpha=False):
    im=Image.new('RGBA',(512,512),(0,0,0,0));d=ImageDraw.Draw(im)
    if not alpha:
        d.ellipse((12,12,500,500),fill=BLUE,outline=GOLD,width=14)
        d.ellipse((34,34,478,478),outline=GOLD,width=2)
    color=IVORY if alpha else GOLD
    if kind=='civ':
        # Single arch, endless boulevard, and infinity ribbon.
        d.rectangle((156,200,356,356),fill=color)
        d.polygon([(126,204),(256,110),(386,204)],fill=color)
        d.rounded_rectangle((216,228,296,372),radius=38,fill=(0,0,0,0) if alpha else BLUE)
        curve=[]
        for i in range(361):
            t=i*math.pi/180;curve.append((256+166*math.cos(t)/(1+math.sin(t)**2),380+70*math.sin(t)*math.cos(t)/(1+math.sin(t)**2)))
        d.line(curve,fill=color,width=20)
    elif kind=='registry':
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
    V.mkdir(parents=True,exist_ok=True)
    source=Image.open(R/'art-source/TheBoundlessCity/ArchitectAndWorld.png').convert('RGBA')
    save(source,'BoundlessDawn.dds',(1024,768))
    save(source,'BoundlessLeader.dds',(1600,900))
    save(source,'BoundlessMap.dds',(512,512))
    portrait=source.crop((55,20,600,565))
    for size in SIZES:
        save(emblem('civ'),f'BoundlessIcon{size}.dds',(size,size))
        save(emblem('civ',True),f'BoundlessAlpha{size}.dds',(size,size))
        objects=Image.new('RGBA',(size*2,size),(0,0,0,0))
        for index,kind in enumerate(['registry','surveyor']):
            objects.paste(emblem(kind).resize((size,size),Image.Resampling.LANCZOS),(index*size,0))
        objects.save(V/f'BoundlessObjects{size}.dds')
    for size in [64,128,256]:
        icon=portrait.resize((size,size),Image.Resampling.LANCZOS)
        mask=Image.new('L',(size,size),0);ImageDraw.Draw(mask).ellipse((1,1,size-2,size-2),fill=255)
        icon.putalpha(mask);icon.save(V/f'BoundlessPortrait{size}.dds')
    save(emblem('surveyor',True),'BoundlessFlag32.dds',(32,32))
    (V/'BoundlessLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="BoundlessLeader.dds" />\n',encoding='utf-8')
    preview=Image.new('RGBA',(512*3,512),BLUE)
    for i,kind in enumerate(['civ','registry','surveyor']):preview.paste(emblem(kind),(i*512,0))
    preview.convert('RGB').save(R/'art-source/TheBoundlessCity/InsigniaPreview.png')
    print('Prepared',len(list(V.glob('*.dds'))),'real DDS textures and the 2D leader scene')

if __name__=='__main__':main()
