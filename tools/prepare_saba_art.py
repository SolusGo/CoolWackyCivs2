"""Compile original Saba painting and collection-style drawn symbols to DDS."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1]
S=R/'art-source/KingdomOfSaba'
V=R/'KingdomOfSaba/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
GOLD='#e8b958';TEAL='#123d42';STONE='#d9ae70';WATER='#75d6cf'

def symbol(kind,alpha=False):
    im=Image.new('RGBA',(512,512));d=ImageDraw.Draw(im)
    if not alpha:d.ellipse((12,12,500,500),fill=TEAL,outline=GOLD,width=14)
    c='white' if alpha else GOLD
    cut=(0,0,0,0) if alpha else TEAL
    if kind=='civ':
        # Twin monumental sluice piers, three channels and a single water drop.
        for x in [121,317]:
            d.rectangle((x,190,x+74,355),fill=c)
            d.rectangle((x-14,170,x+88,194),fill=c)
            if not alpha:
                for y in [227,275,323]:d.line((x+5,y,x+69,y),fill=TEAL,width=5)
        d.rectangle((107,355,405,374),fill=c)
        d.polygon([(256,86),(218,143),(213,161),(219,182),(236,195),(256,199),(278,190),(293,173),(296,155),(288,137)],fill=c)
        for x in [179,256,333]:
            d.line([(x,387),(x-12,403),(x+10,420),(x,438)],fill=c,width=12)
    elif kind=='cistern':
        d.polygon([(99,226),(220,143),(411,206),(293,293)],fill=STONE)
        d.polygon([(99,226),(293,293),(293,384),(99,316)],fill=c)
        d.polygon([(293,293),(411,206),(411,302),(293,384)],fill='#a67c45')
        d.polygon([(145,224),(225,173),(366,214),(288,265)],fill=WATER)
        d.line([(145,224),(225,173),(366,214),(288,265),(145,224)],fill=TEAL,width=9)
        for a,b in [((108,265),(287,327)),((108,296),(287,359)),((300,329),(403,252))]:d.line((a,b),fill=TEAL,width=5)
        d.rectangle((366,291,389,358),fill=c)
        d.line([(378,337),(379,381),(334,412),(188,412)],fill=WATER,width=18)
    else:
        d.line([(344,103),(174,427)],fill=c,width=20)
        d.polygon([(344,103),(342,55),(308,118)],fill=c)
        d.ellipse((119,181,325,389),fill=c)
        d.ellipse((138,200,306,370),outline=cut,width=11)
        d.ellipse((205,267,239,301),fill=cut)
        if not alpha:
            for x,y in [(172,235),(270,235),(172,335),(270,335)]:d.ellipse((x-6,y-6,x+6,y+6),fill=TEAL)
    return im

def map_image():
    im=Image.new('RGBA',(512,512),'#d5bd8b');d=ImageDraw.Draw(im)
    d.rounded_rectangle((15,15,497,497),radius=20,outline=TEAL,width=8)
    # Schematic southern Arabian coast with Red Sea / Gulf of Aden, not a border claim.
    d.polygon([(32,32),(480,32),(480,338),(387,362),(315,388),(234,406),(158,384),(127,326),(83,250)],fill='#a98b5c')
    d.polygon([(32,190),(83,250),(127,326),(158,384),(234,406),(315,388),(387,362),(480,338),(480,480),(32,480)],fill='#6d9695')
    for x,y in [(190,164),(256,186),(327,173),(280,240)]:d.polygon([(x-22,y+20),(x,y-23),(x+24,y+20)],fill='#816b48')
    d.ellipse((220,274,339,335),fill='#708252')
    d.line([(277,253),(265,281),(280,302),(312,322)],fill=WATER,width=7)
    d.ellipse((272,293,286,307),fill=GOLD,outline=TEAL,width=3)
    return im

def save(im,name,size):
    (V/name).write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))

def main():
    V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
    painting=Image.open(S/'KaribilWatar.png').convert('RGBA');w,h=painting.size
    portrait=painting.crop((int(w*.53),int(h*.015),int(w*.83),int(h*.64)))
    objects=Image.new('RGBA',(1024,512));objects.paste(symbol('cistern'),(0,0));objects.paste(symbol('sentinel'),(512,0))
    masters={'Icon':symbol('civ'),'Alpha':symbol('civ',True),'Portrait':portrait,'Objects':objects}
    for stem,master in masters.items():
        master=ImageOps.fit(master,(512 if stem=='Objects' else 256,256),Image.Resampling.LANCZOS)
        master.save(S/(stem+'.png'))
        for size in SIZES:(V/f'SABA_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*(2 if stem=='Objects' else 1),size),Image.Resampling.LANCZOS)))
    save(symbol('sentinel',True),'SABA_Flag32.dds',(32,32))
    save(painting,'SABA_Leader.dds',(1600,900));save(painting,'SABA_Dawn.dds',(1024,768))
    map_image().save(S/'SabaMap.png');save(map_image(),'SABA_Map.dds',(512,512))
    (V/'SABA_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="SABA_Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(1024,256),TEAL)
    for i,im in enumerate([masters['Icon'],masters['Portrait'],symbol('sentinel'),symbol('cistern')]):
        preview.paste(ImageOps.fit(im,(256,256),Image.Resampling.LANCZOS),(i*256,0))
    preview.convert('RGB').save(S/'Preview.png')
    print('Compiled 40 Saba mipmapped DDS textures, original painting, symbols, map and 2D leader scene')

if __name__=='__main__':main()
