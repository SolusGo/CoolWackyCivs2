"""Assemble retained 2D paintings and legacy Civ V DDS assets deterministically.

No image generation, network access or 3D unit-art edits occur in this build.
Original reference: art-source/The11Cats/Emblem.png (never overwritten).
"""
from pathlib import Path
import hashlib, json, math, os, shutil, subprocess, tempfile
from PIL import Image, ImageDraw, ImageOps, ImageFont
from prepare_red_art import raw_mips
from cats_data import CATS
R=Path(__file__).resolve().parents[1]; S=R/'art-source/The11Cats'; V=R/'The11Cats/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
PURPLE='#38204f'; GOLD='#edbf63'; CREAM='#fff1cf'

def symbol(kind='paw',alpha=False):
    """Four toe pads and an open crown remain readable at flag/alpha sizes."""
    im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im);color='white' if alpha else GOLD
    if not alpha:d.ellipse((7,7,249,249),fill=PURPLE,outline=GOLD,width=7)
    for box in [(48,113,84,156),(86,91,122,139),(134,91,170,139),(172,113,208,156)]:d.ellipse(box,fill=color)
    d.rounded_rectangle((82,151,174,214),radius=31,fill=color)
    d.polygon([(76,77),(65,32),(102,51),(128,21),(154,51),(191,32),(180,77)],fill=color)
    d.rounded_rectangle((77,80,179,88),radius=3,fill=color)
    return im

def painting(name):
    with Image.open(S/name) as im:return im.convert('RGBA')

def portrait(im,size=256,padding=0):
    # Keep ears/crown/paws inside native circular masks, using ORIGINAL PNGs.
    out=Image.new('RGBA',(size,size),PURPLE);edge=round(size*(1-2*padding))
    out.alpha_composite(ImageOps.fit(im,(edge,edge),Image.Resampling.LANCZOS),((size-edge)//2,(size-edge)//2))
    mask=Image.new('L',out.size);ImageDraw.Draw(mask).ellipse((1,1,size-2,size-2),fill=255)
    out.putalpha(mask);return out

def medallion(canvas,im,center,diameter):
    x,y=center;box=(round(x-diameter/2),round(y-diameter/2))
    cell=portrait(im,diameter);d=ImageDraw.Draw(cell)
    for inset,color in [(1,'#78511f'),(5,GOLD),(9,CREAM),(12,'#b47d32')]:
        d.ellipse((inset,inset,diameter-inset-1,diameter-inset-1),outline=color,width=3)
    canvas.alpha_composite(cell,box)

def group(portraits):
    size=2048;im=Image.new('RGBA',(size,size));d=ImageDraw.Draw(im)
    d.ellipse((8,8,size-9,size-9),fill=PURPLE,outline='#715023',width=12)
    d.ellipse((27,27,size-28,size-28),outline=GOLD,width=22)
    d.ellipse((55,55,size-56,size-56),outline=CREAM,width=4)
    layout=[]
    for index,(id,*_) in enumerate(CATS[1:]):
        angle=-math.pi/2+index*math.tau/10
        center=(size/2+math.cos(angle)*size*.305,size/2+math.sin(angle)*size*.305)
        diameter=round(size*.18);medallion(im,portraits[id],center,diameter)
        layout.append({'id':id,'center':[round(v) for v in center],'diameter':diameter})
    medallion(im,portraits['AUSTIN'],(size/2,size/2),round(size*.40))
    layout.insert(0,{'id':'AUSTIN','center':[1024,1024],'diameter':round(size*.40)})
    paw=symbol(alpha=True).resize((100,100),Image.Resampling.LANCZOS)
    tint=Image.new('RGBA',paw.size,GOLD);tint.putalpha(paw.getchannel('A'))
    for x,y in [(257,340),(1691,340),(257,1608),(1691,1608)]:im.alpha_composite(tint,(x,y))
    return im,layout

def texconv():
    tool=shutil.which('texconv') or shutil.which('texconv.exe')
    if not tool and os.environ.get('LOCALAPPDATA'):
        candidates=sorted((Path(os.environ['LOCALAPPDATA'])/'Microsoft/WinGet/Packages').glob('Microsoft.DirectXTex.Texconv_*/texconv.exe'))
        if candidates:tool=str(candidates[-1])
    if not tool:raise RuntimeError('DirectXTex texconv is required for legacy DXT5 scene DDS conversion')
    return tool

def main():
    V.mkdir(parents=True,exist_ok=True);master_dir=R/'art-source/IconAtlasMasters'
    originals={id:painting('Portraits/'+id.title()+'.png') for id,*_ in CATS}
    cats=Image.new('RGBA',(1024,768));portraits={};identity=[]
    for i,(id,*_) in enumerate(CATS):
        cell=portrait(originals[id]);portraits[id]=cell
        cats.alpha_composite(cell,((i%4)*256,(i//4)*256))
        path=S/'Portraits'/(id.title()+'.png')
        identity.append({'id':id,'index':i,'source':path.relative_to(S).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    emblem,layout=group(originals);emblem.save(S/'Group.png')
    objects=Image.new('RGBA',(512,256));objects.alpha_composite(portrait(painting('Sources/CatTree.png')),(0,0))
    objects.alpha_composite(portraits['LUNA'],(256,0))
    masters={'Icon':emblem.resize((256,256),Image.Resampling.LANCZOS),'Alpha':symbol(alpha=True),'Portrait':portraits['AUSTIN'],'Objects':objects,'Cats':cats}
    for stem,master in masters.items():
        master.save(S/(stem+'.png'))
        if stem!='Alpha':master.save(master_dir/('THE11CATS_'+stem+'256.png'))
        for size in SIZES:
            if stem=='Icon' and size<=80:im=symbol().resize((size,size),Image.Resampling.LANCZOS)
            else:im=master.resize((size*(master.width//256),size*(master.height//256)),Image.Resampling.LANCZOS)
            (V/f'THE11CATS_{stem}{size}.dds').write_bytes(raw_mips(im))
    (V/'THE11CATS_Flag32.dds').write_bytes(raw_mips(symbol(alpha=True).resize((32,32),Image.Resampling.LANCZOS)))
    scenes={'Leader':(painting('Sources/Leader.png'),(1600,900)),
            'Dawn':(painting('Sources/Dawn.png'),(1024,768)),
            'Household':(painting('Sources/Household.png'),(1024,768)),
            'Map':(emblem,(512,512))}
    (R/'dist').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='cats-art-',dir=R/'dist') as temp:
        stage=Path(temp);pngs=[]
        for stem,(source,size) in scenes.items():
            path=stage/f'THE11CATS_{stem}.png'
            ImageOps.fit(source,size,Image.Resampling.LANCZOS).save(path);pngs.append(str(path))
        result=subprocess.run([texconv(),'-nologo','-y','-dx9','-f','DXT5','-m','0','-o',str(stage),*pngs],capture_output=True,text=True)
        if result.returncode:raise RuntimeError(result.stdout+result.stderr)
        for stem in scenes:(V/f'THE11CATS_{stem}.dds').write_bytes((stage/f'THE11CATS_{stem}.dds').read_bytes())
    (V/'THE11CATS_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="THE11CATS_Leader.dds" />\n',encoding='utf-8',newline='\n')
    (S/'Identity.json').write_text(json.dumps({'portraits':identity,'emblem':layout,'scene_cats':{'Leader':['AUSTIN'],'Dawn':['AUSTIN','LUNA']}},indent=2)+'\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGB',(1024,900),PURPLE);draw=ImageDraw.Draw(preview)
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
    for i,(id,*_) in enumerate(CATS):
        preview.paste(portraits[id],((i%4)*256,(i//4)*300),portraits[id])
        draw.text(((i%4)*256+20,(i//4)*300+264),id.title(),font=font,fill=CREAM)
    preview.save(S/'PortraitPreview.png')
    print('Prepared 50 mipmapped 2D DDS assets; 11 unique portraits, exact 11-medallion emblem, dedicated leader/Dawn/UI paintings; no 3D edits')
if __name__=='__main__':main()
