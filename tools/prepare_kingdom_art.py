"""Compile the original Kingdom painting and repository-style drawn icons to mipmapped DDS."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1]
S=R/'art-source/TheChildrenOfTheKingdom'
V=R/'TheChildrenOfTheKingdom/Art'
BLUE='#3b5c7d'; GOLD='#e8cc87'; WHITE='#fff6df'
SIZES=[16,24,32,45,48,64,80,128,256]

def emblem(kind,alpha=False):
    im=Image.new('RGBA',(512,512)); d=ImageDraw.Draw(im)
    if not alpha: d.ellipse((12,12,500,500),fill=BLUE,outline=GOLD,width=14)
    ink='white' if alpha else WHITE
    if kind in ('civ','prayer'):
        # A cross above an open book: a clear original alpha silhouette.
        d.rectangle((239,89,273,237),fill=ink);d.rectangle((193,130,319,162),fill=ink)
        d.polygon([(87,278),(179,261),(256,285),(332,261),(425,278),(425,396),(333,380),(256,406),(179,380),(87,396)],fill=ink)
        d.line((256,294,256,391),fill=(0,0,0,0) if alpha else BLUE,width=12)
        if not alpha:
            for y in (307,332,357):
                d.line((113,y,211,y-5),fill=BLUE,width=6); d.line((302,y-5,399,y),fill=BLUE,width=6)
    elif kind=='house':
        d.polygon([(90,243),(256,111),(422,243)],fill=ink)
        d.rectangle((124,247,388,394),fill=ink)
        d.rounded_rectangle((225,287,287,405),radius=28,fill=(0,0,0,0) if alpha else BLUE)
        d.rectangle((247,77,265,146),fill=ink);d.rectangle((226,94,286,112),fill=ink)
        for x in (154,323): d.rounded_rectangle((x,281,x+35,345),radius=16,fill=(0,0,0,0) if alpha else BLUE)
    else:
        d.polygon([(128,134),(256,169),(383,134),(369,299),(327,366),(256,419),(183,366),(142,299)],fill=ink)
        bg=(0,0,0,0) if alpha else BLUE
        d.rectangle((244,204,269,338),fill=bg);d.rectangle((205,242,308,267),fill=bg)
        d.line((388,96,388,394),fill=ink,width=16);d.polygon([(388,62),(366,114),(410,114)],fill=ink)
    return im

def save(im,name,size):
    image=ImageOps.fit(im,size,method=Image.Resampling.LANCZOS)
    (V/name).write_bytes(raw_mips(image))

def main():
    V.mkdir(parents=True,exist_ok=True); S.mkdir(parents=True,exist_ok=True)
    source=Image.open(S/'FaithfulAndSanctuary.png').convert('RGBA')
    save(source,'CKDawn.dds',(1024,768));save(source,'CKLeader.dds',(1600,900))
    # Keep the face/hands in the setup portrait; avoid clipping the top of the head.
    portrait=source.crop((int(source.width*.51),int(source.height*.015),int(source.width*.86),int(source.height*.64)))
    map_image=Image.new('RGBA',(512,512),'#e9dfc4');d=ImageDraw.Draw(map_image)
    d.rectangle((14,14,497,497),outline=BLUE,width=6)
    d.polygon([(49,377),(99,249),(77,164),(176,71),(312,88),(419,190),(439,333),(338,447),(193,430)],fill='#a5b5a1',outline=BLUE,width=4)
    d.line([(102,182),(192,239),(253,233),(296,306),(370,350),(403,413)],fill='#8caab5',width=13)
    for x,y in [(254,202),(156,292),(325,330),(220,367),(330,146)]:
        d.ellipse((x-9,y-9,x+9,y+9),fill=BLUE,outline=WHITE,width=3)
    seal=emblem('civ').resize((115,115),Image.Resampling.LANCZOS);map_image.alpha_composite(seal,(370,375))
    save(map_image,'CKMap.dds',(512,512))
    for size in SIZES:
        save(emblem('civ'),f'CKIcon{size}.dds',(size,size))
        save(emblem('civ',True),f'CKAlpha{size}.dds',(size,size))
        atlas=Image.new('RGBA',(size*3,size))
        for i,kind in enumerate(['house','keeper','prayer']): atlas.paste(emblem(kind).resize((size,size),Image.Resampling.LANCZOS),(size*i,0))
        (V/f'CKObjects{size}.dds').write_bytes(raw_mips(atlas))
    for size in [64,128,256]:
        image=ImageOps.fit(portrait,(size,size),method=Image.Resampling.LANCZOS)
        mask=Image.new('L',(size,size));ImageDraw.Draw(mask).ellipse((1,1,size-2,size-2),fill=255)
        image.putalpha(mask);(V/f'CKPortrait{size}.dds').write_bytes(raw_mips(image))
    save(emblem('keeper',True),'CKFlag32.dds',(32,32))
    (V/'CKLeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="CKLeader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(2048,512),BLUE)
    for i,kind in enumerate(['civ','house','keeper','prayer']): preview.paste(emblem(kind),(512*i,0))
    preview.convert('RGB').save(S/'InsigniaPreview.png')
    print('Prepared',len(list(V.glob('*.dds'))),'Kingdom mipmapped DDS textures and static leader scene')

if __name__=='__main__': main()
