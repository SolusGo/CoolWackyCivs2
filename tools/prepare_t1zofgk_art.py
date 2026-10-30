"""Deterministic atlas export, official heraldry and editable symbolic promotion art.

Paintings are built-in imagegen outputs; no substitute leader/unit paintings.
Only crop/resize/export work is performed on those finished illustrations.
"""
from pathlib import Path
import json, math
from PIL import Image,ImageDraw,ImageOps,ImageFont
from dds_mips import raw_mips
from standardize_icons import frame_cell

R=Path(__file__).resolve().parents[1]; S=R/'art-source/T1ZOFGK'; V=R/'T1ZOFGK/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
RED='#e2012d'; GOLD='#efd28a'; WHITE='#fff2da'; BLACK='#11131a'

def symbol(kind):
    # High-resolution, original, code-native heraldry. Gradients, dimensional
    # gold outlines and broad silhouettes survive the smallest game UI sizes.
    im=Image.new('RGBA',(512,512));d=ImageDraw.Draw(im)
    for y in range(512):
        c=round(18+20*(1-y/512));d.line((0,y,512,y),fill=(c+12,c//2,c//2+12,255))
    d.ellipse((50,50,462,462),outline='#633c39',width=4)
    def line(points,width=15,fill=GOLD):d.line(points,fill=fill,width=width,joint='curve')
    def poly(points,fill=GOLD):d.polygon(points,fill=fill)
    if kind=='Zeus':
        poly([(287,85),(158,282),(239,270),(213,428),(367,213),(282,228)],WHITE)
        line([(133,405),(194,405)],10);line([(318,111),(379,111)],10)
    elif kind=='Oner':
        for x,y,angle in [(199,332,-.28),(297,189,.28)]:
            d.ellipse((x-32,y-49,x+32,y+49),fill=WHITE)
            for off in [-34,-11,12,35]:d.ellipse((x+off-9,y-78,x+off+9,y-57),fill=GOLD)
        line([(106,373),(83,269),(122,156)],8)
        poly([(103,249),(69,202),(122,214)]);poly([(113,181),(94,125),(142,153)])
        line([(406,373),(429,269),(390,156)],8)
        poly([(409,249),(443,202),(390,214)]);poly([(399,181),(418,125),(370,153)])
    elif kind in ['Faker','Pressure']:
        poly([(127,209),(145,338),(367,338),(385,209),(318,259),(256,153),(194,259)],WHITE if kind=='Faker' else RED)
        for x,y in [(126,197),(256,141),(386,197)]:d.ellipse((x-13,y-13,x+13,y+13),fill=GOLD)
        line([(149,364),(363,364)],18)
        d.ellipse((216,276,296,307),outline=BLACK,width=8);d.ellipse((248,276,264,307),fill=BLACK)
        if kind=='Pressure':line([(275,130),(230,235),(272,256),(223,404)],12,WHITE)
    elif kind=='Gumayusi':
        d.arc((106,91,385,422),270,450,fill=GOLD,width=20)
        line([(247,92),(247,420)],8)
        line([(117,256),(399,256)],16,WHITE)
        poly([(410,256),(343,217),(357,256),(343,295)],WHITE)
        line([(137,225),(174,256),(137,287)],12)
    elif kind in ['Keria','Support']:
        shield=[(256,99),(378,152),(362,302),(313,372),(256,413),(199,372),(150,302),(134,152),(256,99)]
        poly(shield,WHITE);line(shield,12,GOLD)
        poly([(256,131),(346,169),(333,287),(299,341),(256,375),(213,341),(179,287),(166,169)],BLACK)
        d.rectangle((237,204,275,325),fill=GOLD);d.rectangle((196,245,316,283),fill=GOLD)
        if kind=='Support':d.arc((87,67,425,433),210,330,fill=RED,width=12)
    elif kind=='Scouted':
        points=[(256+(140 if i%2==0 else 62)*math.sin(i*math.pi/5),249-(140 if i%2==0 else 62)*math.cos(i*math.pi/5)) for i in range(10)]
        poly(points,WHITE)
        line([(138,384),(256,414),(374,384)],12)
    elif kind=='Development':
        for y in [161,249,337]:line([(146,y+40),(256,y-33),(366,y+40)],26,WHITE)
    elif kind in ['Synergy3','Synergy5']:
        count=3 if kind=='Synergy3' else 5
        pts=[(256+142*math.sin(i*math.tau/count),256-142*math.cos(i*math.tau/count)) for i in range(count)]
        for p in pts:line([(256,256),p],12)
        line(pts+[pts[0]],11)
        for x,y in pts:d.ellipse((x-28,y-28,x+28,y+28),fill=WHITE,outline=GOLD,width=6)
        d.ellipse((222,222,290,290),fill=RED,outline=GOLD,width=8)
    return im

def fit_mark(logo,size,color=None):
    mark=logo.crop(logo.getchannel('A').getbbox())
    if color:
        alpha=mark.getchannel('A');mark=Image.new('RGBA',mark.size,color);mark.putalpha(alpha)
    mark.thumbnail(size,Image.Resampling.LANCZOS)
    return mark

def map_image():
    # An original commemorative route chart, not a claim to game geography.
    im=Image.new('RGBA',(512,512),'#e6d3a2');d=ImageDraw.Draw(im)
    for inset,color in [(12,'#392928'),(17,'#b89048'),(21,'#392928')]:d.rectangle((inset,inset,511-inset,511-inset),outline=color,width=2)
    d.polygon([(310,100),(333,109),(335,144),(358,168),(353,208),(374,240),(360,270),(374,302),(358,328),(337,315),(326,283),(309,275),(315,245),(294,225),(304,202),(287,173),(309,153)],fill='#997b4d',outline='#392928',width=3)
    d.ellipse((323,347,347,357),fill='#997b4d')
    fontpath=Path('C:/Windows/Fonts/georgia.ttf')
    def text(xy,value,size,fill='#392928'):
        font=ImageFont.truetype(str(fontpath),size) if fontpath.exists() else ImageFont.load_default(size=size)
        d.text(xy,value,font=font,fill=fill)
    text((52,42),'THE ZOFGK DYNASTY',23)
    text((51,78),'A legacy of five',17)
    d.arc((87,132,369,405),130,294,fill=RED,width=4)
    for x,y in [(320,214),(117,295)]:d.ellipse((x-8,y-8,x+8,y+8),fill=RED,outline='#392928',width=2)
    text((327,200),'SEOUL',14);text((329,223),'2023',14)
    text((53,313),'LONDON',14);text((68,333),'2024',14)
    text((55,396),'2022: The final',17)
    text((55,425),'2023-2024: Back to back',17)
    text((55,455),'Five Legends. One Dynasty.',15)
    return im

def main():
    V.mkdir(parents=True,exist_ok=True)
    logo=Image.open(S/'T1-Official-Red.png').convert('RGBA')
    icon=Image.new('RGBA',(256,256),BLACK);mark=fit_mark(logo,(202,122));icon.alpha_composite(mark,((256-mark.width)//2,(256-mark.height)//2))
    alpha=Image.new('RGBA',(256,256));mark=fit_mark(logo,(228,160),'white');alpha.alpha_composite(mark,((256-mark.width)//2,(256-mark.height)//2))
    leader=Image.open(S/'Faker.png').convert('RGBA');w,h=leader.size
    portrait=ImageOps.fit(leader.crop((int(w*.20),int(h*.01),int(w*.49),int(h*.64))),(256,256))
    objects=Image.new('RGBA',(512,256))
    for i,name in enumerate(['Recruit','Headquarters']):objects.paste(ImageOps.fit(Image.open(S/(name+'.png')).convert('RGBA'),(256,256)),(256*i,0))
    promotions=Image.new('RGBA',(1024,768))
    kinds=['Zeus','Oner','Faker','Gumayusi','Keria','Scouted','Development','Synergy3','Synergy5','Pressure','Support']
    for i,kind in enumerate(kinds):
        source=symbol(kind);source.save(S/(kind+'Symbol.png'))
        promotions.paste(source.resize((256,256),Image.Resampling.LANCZOS),(i%4*256,i//4*256))
    masters={'Icon':(icon,1,1),'Alpha':(alpha,1,1),'Portrait':(portrait,1,1),'Objects':(objects,2,1),'Promotions':(promotions,4,3)}
    for stem,(im,cols,rows) in masters.items():
        im.save(S/(stem+'.png'))
        if stem not in ['Alpha','Promotions']:
            retained=R/'art-source/IconAtlasMasters'/f'T1Z_{stem}256.png';im.save(retained)
        for size in SIZES:
            out=Image.new('RGBA',(size*cols,size*rows))
            for y in range(rows):
                for x in range(cols):
                    cell=im.crop((x*256,y*256,(x+1)*256,(y+1)*256))
                    if not cell.getchannel('A').getbbox():continue
                    cell=cell.resize((size,size),Image.Resampling.LANCZOS) if stem=='Alpha' else frame_cell(cell,size,stem=='Portrait',preserve_art=True)
                    out.alpha_composite(cell,(x*size,y*size))
            (V/f'T1Z_{stem}{size}.dds').write_bytes(raw_mips(out))
    (V/'T1Z_Flag32.dds').write_bytes(raw_mips(alpha.resize((32,32),Image.Resampling.LANCZOS)))
    for name,im,size in [('Leader',leader,(1600,900)),('Dawn',Image.open(S/'ZOFGK.png'),(1024,768)),('Map',map_image(),(512,512))]:
        if name=='Map':im.save(S/'Map.png')
        (V/f'T1Z_{name}.dds').write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))
    (V/'T1Z_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="T1Z_Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(1024,768),'#18141a')
    for i,cell in enumerate([icon,portrait,objects.crop((0,0,256,256)),objects.crop((256,0,512,256))]):preview.alpha_composite(frame_cell(cell,256,i==1,preserve_art=True),(i*256,0))
    for i,kind in enumerate(kinds):preview.alpha_composite(frame_cell(symbol(kind),128,preserve_art=True),(i%8*128,256+i//8*128))
    preview.convert('RGB').save(S/'Preview.png')
    print('Prepared',len(list(V.glob('*.dds'))),'DDS textures with complete mip chains, official T1 heraldry and original symbolic art')

if __name__=='__main__':main()
