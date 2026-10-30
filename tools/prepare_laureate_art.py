"""Mechanical game exports of original paintings; code-native monochrome heraldry/map."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips
from standardize_icons import frame_cell
R=Path(__file__).resolve().parents[1]
S=R/'art-source/TheLaureateCommonwealth'; V=R/'TheLaureateCommonwealth/Art'
SIZES=[16,24,32,45,48,64,80,128,256]

def alpha(sword=False):
    im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
    for side in [-1,1]:
        stem=[]
        for i in range(11):
            theta=math.radians(22+i*12)
            x=128+side*82*math.sin(theta); y=119+89*math.cos(theta)
            stem.append((x,y))
            tilt=side*(theta-math.pi/2)
            for offset in [-.7,.7]:
                angle=tilt+offset
                ex=x+side*23*math.cos(angle);ey=y-23*math.sin(theta+offset)
                dx,dy=ex-x,ey-y
                d.polygon([(x,y),(x+dx*.5-dy*.25,y+dy*.5+dx*.25),(ex,ey),
                           (x+dx*.5+dy*.25,y+dy*.5-dx*.25)],fill='white')
        d.line(stem,fill='white',width=5)
    if sword:
        d.polygon([(128,49),(139,70),(134,162),(122,162),(117,70)],fill='white')
        d.rectangle((107,161,149,169),fill='white');d.rectangle((123,167,133,194),fill='white')
    else:
        points=[(128+(30 if i%2==0 else 13)*math.sin(i*math.pi/5),
                 122-(30 if i%2==0 else 13)*math.cos(i*math.pi/5)) for i in range(10)]
        d.polygon(points,fill='white')
    return im

def map_image():
    im=Image.new('RGBA',(512,512),'#dfcd96');d=ImageDraw.Draw(im)
    d.rectangle((13,13,498,498),outline='#76602b',width=4)
    d.polygon([(40,70),(141,35),(255,90),(298,170),(438,206),(478,329),
               (421,446),(296,475),(194,407),(61,428),(30,284),(98,191)],
              fill='#54775b',outline='#294c3d',width=5)
    d.line([(39,285),(147,302),(251,261),(312,166),(469,177)],fill='#79adb0',width=12)
    for x,y in [(247,250),(133,178),(371,289),(191,377),(337,397)]:
        d.ellipse((x-8,y-8,x+8,y+8),fill='#e1bf59',outline='#473e28',width=2)
    d.text((263,239),'DAPHNE',fill='#f6e5b5',stroke_width=1,stroke_fill='#294c3d')
    d.line([(450,71),(450,126)],fill='#473e28',width=3)
    d.polygon([(450,49),(440,77),(460,77)],fill='#473e28')
    return im

def main():
    V.mkdir(parents=True,exist_ok=True)
    leader=Image.open(S/'Laurea.png').convert('RGBA');w,h=leader.size
    portrait=leader.crop((int(w*.31),int(h*.04),int(w*.69),int(h*.72)))
    objects=Image.new('RGBA',(512,256))
    for i,name in enumerate(['Champion','Hall']):
        objects.paste(ImageOps.fit(Image.open(S/(name+'.png')).convert('RGBA'),(256,256)),(256*i,0))
    masters={'Icon':Image.open(S/'CivIcon.png').convert('RGBA'),'Portrait':portrait,
             'Objects':objects,'Alpha':alpha()}
    for stem,im in masters.items():
        cols=2 if stem=='Objects' else 1
        im=ImageOps.fit(im,(256*cols,256),Image.Resampling.LANCZOS);im.save(S/(stem+'.png'))
        if stem!='Alpha':
            retained=R/'art-source/IconAtlasMasters'/f'LC_{stem}256.png'
            retained.parent.mkdir(parents=True,exist_ok=True);im.save(retained)
        for size in SIZES:
            out=Image.new('RGBA',(size*cols,size))
            for i in range(cols):
                cell=im.crop((i*256,0,(i+1)*256,256))
                cell=cell.resize((size,size),Image.Resampling.LANCZOS) if stem=='Alpha' else frame_cell(cell,size,stem=='Portrait')
                out.alpha_composite(cell,(i*size,0))
            (V/f'LC_{stem}{size}.dds').write_bytes(raw_mips(out))
    (V/'LC_Flag32.dds').write_bytes(raw_mips(alpha(True).resize((32,32),Image.Resampling.LANCZOS)))
    for name,im,size in [('Leader',leader,(1600,900)),('Dawn',Image.open(S/'Daphne.png'),(1024,768)),('Map',map_image(),(512,512))]:
        (V/f'LC_{name}.dds').write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))
    (V/'LC_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="LC_Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(1024,256),'#092e20')
    for i,im in enumerate([masters['Icon'],masters['Portrait'],objects.crop((0,0,256,256)),objects.crop((256,0,512,256))]):
        preview.alpha_composite(frame_cell(im,256,i==1),(256*i,0))
    preview.convert('RGB').save(S/'Preview.png')
    print('Compiled 40 mipmapped RGBA DDS textures and static leader scene')

if __name__=='__main__': main()
