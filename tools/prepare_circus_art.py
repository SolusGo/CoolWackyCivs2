"""Original circus painting and collection-style drawn symbols -> mipmapped DDS."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1]; S=R/'art-source/TheWanderingCircus'; V=R/'TheWanderingCircus/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
GOLD='#edbf63'; CRIMSON='#a41835'; INK='#14233c'; WHITE='#fff1cf'

def symbol(kind, alpha=False):
    im=Image.new('RGBA',(512,512)); d=ImageDraw.Draw(im)
    if not alpha: d.ellipse((12,12,500,500),fill=INK,outline=GOLD,width=14)
    color='white' if alpha else GOLD
    if kind=='tent':
        d.polygon([(78,238),(256,92),(434,238)],fill=color)
        if not alpha:
            for a,b in [(78,149),(220,292),(363,434)]: d.polygon([(a,238),(256,92),(b,238)],fill=CRIMSON)
        d.rectangle((103,242,409,391),fill=color)
        if not alpha:
            for x in [111,185,259,333]: d.rectangle((x,245,x+33,388),fill=CRIMSON)
        d.polygon([(211,392),(256,286),(301,392)],fill=(0,0,0,0) if alpha else INK)
        d.line((256,56,256,92),fill=color,width=10)
        d.polygon([(263,50),(332,66),(263,83)],fill=color)
        for x,y in [(114,115),(403,120)]:
            points=[(x+math.sin(i*math.pi/5)*(27 if i%2==0 else 12),y-math.cos(i*math.pi/5)*(27 if i%2==0 else 12)) for i in range(10)]
            d.polygon(points,fill=color)
    elif kind=='office':
        d.rounded_rectangle((96,174,416,369),radius=18,fill=color)
        d.ellipse((71,237,121,295),fill=INK);d.ellipse((391,237,441,295),fill=INK)
        d.line((157,194,157,349),fill=CRIMSON,width=9)
        for y in range(197,352,26): d.rectangle((150,y,164,y+12),fill=GOLD)
        d.polygon([(279,203),(295,239),(334,243),(304,270),(313,310),(279,290),(244,310),(254,270),(224,243),(263,239)],fill=CRIMSON)
    elif kind=='crew':
        d.rectangle((142,111,370,144),fill=color)
        d.rounded_rectangle((185,57,327,125),radius=12,fill=color)
        d.ellipse((211,156,301,246),fill=color)
        d.line((256,255,256,365),fill=color,width=39)
        d.line((256,285,160,323),fill=color,width=28);d.line((256,285,352,249),fill=color,width=28)
        d.line((249,355,192,433),fill=color,width=28);d.line((263,355,321,433),fill=color,width=28)
        d.line((370,183,370,413),fill=color,width=16)
        if not alpha:d.rectangle((190,106,322,123),fill=CRIMSON)
    return im

def map_image():
    im=Image.new('RGBA',(512,512),'#d6bc88');d=ImageDraw.Draw(im)
    d.rounded_rectangle((17,17,495,495),radius=22,outline=CRIMSON,width=9)
    d.polygon([(40,137),(102,110),(146,132),(191,78),(245,99),(271,151),(332,131),(380,170),(458,155),(475,208),(422,258),(454,327),(377,370),(310,352),(280,434),(218,413),(179,343),(104,366),(71,295),(100,235),(41,203)],fill='#777b54',outline=INK,width=4)
    route=[(122,292),(196,219),(268,267),(354,227),(378,334)]
    d.line(route,fill=GOLD,width=7)
    for x,y in route:
        d.polygon([(x-20,y),(x,y-23),(x+20,y)],fill=CRIMSON)
        d.rectangle((x-15,y,x+15,y+15),fill=WHITE,outline=CRIMSON,width=3)
    return im

def save(im,name,size): (V/name).write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))

def main():
    V.mkdir(parents=True,exist_ok=True); S.mkdir(parents=True,exist_ok=True)
    painting=Image.open(S/'Aurelio.png').convert('RGBA'); w,h=painting.size
    portrait=painting.crop((int(w*.45),0,int(w*.78),int(h*.62)))
    masters={'Icon':symbol('tent'),'Alpha':symbol('tent',True),'Portrait':portrait}
    objects=Image.new('RGBA',(1024,512));objects.paste(symbol('office'),(0,0));objects.paste(symbol('crew'),(512,0))
    masters['Objects']=objects
    for stem,master in masters.items():
        # Retained 256px masters; the shared builder adds the standard gold frames.
        master=master.resize((512 if stem=='Objects' else 256,256),Image.Resampling.LANCZOS)
        master.save(S/(stem+'.png'))
        for size in SIZES: (V/f'WCIRCUS_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*(2 if stem=='Objects' else 1),size),Image.Resampling.LANCZOS)))
    save(symbol('crew',True),'WCIRCUS_Flag32.dds',(32,32))
    save(painting,'WCIRCUS_Leader.dds',(1600,900));save(painting,'WCIRCUS_Dawn.dds',(1024,768))
    map_image().save(S/'CircusMap.png');save(map_image(),'WCIRCUS_Map.dds',(512,512))
    (V/'WCIRCUS_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="WCIRCUS_Leader.dds" />\n',encoding='utf-8',newline='\n')
    print('Compiled 40 circus DDS textures, original map/symbols, painting and static leader scene')

if __name__=='__main__': main()
