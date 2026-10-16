"""Package original Coo artwork and repo-style code-drawn postal insignia as DDS."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
R=Path(__file__).resolve().parents[1]
V=R/'TheRepublicOfPigeons/Art'
SOURCE=R/'art-source/TheRepublicOfPigeons'
SIZES=[16,24,32,45,48,64,80,128,256]
SLATE=(79,97,122,255); CREAM=(243,232,197,255); INK=(41,52,71,255)

def emblem(kind,alpha=False):
    im=Image.new('RGBA',(512,512),(0,0,0,0)); d=ImageDraw.Draw(im)
    if not alpha:
        d.ellipse((12,12,500,500),fill=SLATE,outline=CREAM,width=14)
        d.ellipse((34,34,478,478),outline=CREAM,width=2)
    color=(255,255,255,255) if alpha else CREAM
    if kind in ['civ','carrier']:
        # Readable pigeon silhouette: swept wing, breast, beak and envelope.
        d.polygon([(184,292),(97,110),(214,176),(268,256),(337,245),(385,276),(329,300),(246,368),(123,388)],fill=color)
        d.ellipse((286,190,377,281),fill=color)
        d.polygon([(369,219),(412,240),(370,247)],fill=color)
        if not alpha: d.ellipse((340,214,351,225),fill=INK)
        if kind=='carrier':
            d.rounded_rectangle((207,290,320,363),radius=5,fill=SLATE if not alpha else (0,0,0,0),outline=color,width=9)
            d.line([(214,299),(264,332),(311,299)],fill=color,width=6)
        else:
            d.line([(126,411),(386,411)],fill=color,width=13)
            d.line([(169,437),(342,437)],fill=color,width=8)
    else:
        d.polygon([(100,242),(256,117),(412,242)],fill=color)
        d.rectangle((132,249,380,382),outline=color,width=15)
        for x in [173,236,299]:
            d.rounded_rectangle((x,272,x+40,340),radius=18,fill=color)
        d.line([(106,400),(406,400)],fill=color,width=16)
        d.line([(256,97),(256,75),(347,75),(347,120),(256,120)],fill=color,width=9)
    return im

def save(im,name,size):
    ImageOps.fit(im,size,method=Image.Resampling.LANCZOS).save(V/name)

def postal_map():
    im=Image.new('RGBA',(512,512),(222,208,170,255)); d=ImageDraw.Draw(im)
    d.rectangle((14,14,497,497),outline=SLATE,width=7)
    d.polygon([(43,389),(82,292),(59,176),(154,91),(298,65),(399,147),(444,296),(382,425),(236,451),(148,406)],fill=(151,166,149,255),outline=SLATE,width=4)
    d.line([(311,79),(279,164),(315,220),(271,291),(295,375),(244,448)],fill=(113,147,170,255),width=13)
    points=[(242,250),(146,159),(351,162),(137,323),(350,352)]
    for p in points[1:]:
        for i in range(0,100,9):
            a=tuple(int(points[0][j]+(p[j]-points[0][j])*i/100) for j in [0,1])
            b=tuple(int(points[0][j]+(p[j]-points[0][j])*(i+5)/100) for j in [0,1])
            d.line([a,b],fill=CREAM,width=5)
    for x,y in points:
        d.ellipse((x-10,y-10,x+10,y+10),fill=SLATE,outline=CREAM,width=3)
    seal=emblem('civ').resize((118,118),Image.Resampling.LANCZOS)
    im.alpha_composite(seal,(365,370))
    return im

def main():
    V.mkdir(parents=True,exist_ok=True)
    source=Image.open(SOURCE/'CooAndCoopolis.png').convert('RGBA')
    save(source,'PigeonDawn.dds',(1024,768))
    save(source,'PigeonLeader.dds',(1600,900))
    postal_map().save(V/'PigeonMap.dds')
    # Portrait crop retains Coo's face and ceremonial cap from the master illustration.
    portrait=source.crop((175,30,685,540))
    for size in SIZES:
        save(emblem('civ'),f'PigeonIcon{size}.dds',(size,size))
        save(emblem('civ',True),f'PigeonAlpha{size}.dds',(size,size))
        objects=Image.new('RGBA',(size*2,size),(0,0,0,0))
        for i,kind in enumerate(['roost','carrier']):
            objects.paste(emblem(kind).resize((size,size),Image.Resampling.LANCZOS),(i*size,0))
        objects.save(V/f'PigeonObjects{size}.dds')
    for size in [64,128,256]:
        icon=portrait.resize((size,size),Image.Resampling.LANCZOS)
        mask=Image.new('L',(size,size),0)
        ImageDraw.Draw(mask).ellipse((1,1,size-2,size-2),fill=255)
        icon.putalpha(mask);icon.save(V/f'PigeonPortrait{size}.dds')
    save(emblem('carrier',True),'PigeonFlag32.dds',(32,32))
    (V/'PigeonLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="PigeonLeader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(1536,512),INK)
    for i,kind in enumerate(['civ','roost','carrier']):preview.paste(emblem(kind),(i*512,0))
    preview.convert('RGB').save(SOURCE/'InsigniaPreview.png')
    print('Prepared',len(list(V.glob('*.dds'))),'Pigeon DDS textures and static leader scene')

if __name__=='__main__':main()
