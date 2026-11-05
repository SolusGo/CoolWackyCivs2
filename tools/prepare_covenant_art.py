"""Compile Covenant paintings and code-native heraldry using pack conventions.

Nine atlas sizes, 90% gold-rim colour cells, 75% leader cells, monochrome
alpha/flag textures and complete legacy RGBA mip chains. No other civ is touched.
"""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageOps, ImageFont
from dds_mips import raw_mips
from standardize_icons import frame_cell

R = Path(__file__).resolve().parents[1]
S = R / 'art-source/TheCovenant'
V = R / 'TheCovenant/Art'
SIZES = (16,24,32,45,48,64,80,128,256)
UI_SIZES = {'Panel':(920,640), 'Buttons':(44,180), 'Trim':(844,3)}


def emblem():
    """Open Scripture and a quill: a simplified tintable mark, not stock Egypt."""
    size=1024
    mask=Image.new('L',(size,size));d=ImageDraw.Draw(mask)
    d.polygon([(150,420),(460,465),(493,510),(493,794),(445,753),(150,708)],fill=255)
    d.polygon([(531,510),(563,465),(874,420),(874,708),(578,753),(531,794)],fill=255)
    for y in (520,580,640):
        d.line([(207,y),(421,y+31)],fill=0,width=19)
        d.line([(603,y+31),(817,y)],fill=0,width=19)
    d.line([(128,734),(438,784),(493,824),(531,824),(586,784),(896,734)],fill=255,width=20)
    # Broad feather and short nib retain a clear silhouette in 16px slots.
    d.polygon([(475,423),(538,307),(661,163),(824,119),(782,274),(618,388),(523,428)],fill=255)
    d.line([(483,447),(738,207)],fill=0,width=18)
    d.line([(449,472),(741,206)],fill=255,width=14)
    for x,y,ex,ey in [(362,238,323,175),(296,340,218,319),(479,183,479,104)]:
        d.line((x,y,ex,ey),fill=255,width=22)
    alpha=Image.new('RGBA',(size,size),'white');alpha.putalpha(mask)
    color=Image.new('RGBA',(size,size),(14,26,46,255));cd=ImageDraw.Draw(color)
    for radius in (425,450):cd.ellipse((512-radius,512-radius,512+radius,512+radius),outline=(49,60,70,255),width=3)
    gold=Image.new('RGBA',(size,size));gd=ImageDraw.Draw(gold)
    for y in range(size):
        t=y/(size-1);gd.line((0,y,size-1,y),fill=(round(255-65*t),round(232-84*t),round(164-100*t),255))
    gold.putalpha(mask);color.alpha_composite(gold)
    return color,alpha


def material(size,top=(19,35,56),bottom=(7,15,27)):
    image=Image.new('RGBA',size);d=ImageDraw.Draw(image)
    for y in range(size[1]):
        t=y/max(1,size[1]-1)
        d.line((0,y,size[0]-1,y),fill=tuple(round(a+(b-a)*t) for a,b in zip(top,bottom))+(255,))
    return image


def panel():
    image=material(UI_SIZES['Panel']);d=ImageDraw.Draw(image)
    # Quiet illuminated-manuscript ornament stays outside the recall text area.
    d.rectangle((1,1,918,638),outline='#513f25',width=2)
    d.rectangle((4,4,915,635),outline='#d7b36a',width=2)
    d.rectangle((10,10,909,629),outline='#4e4c3d')
    d.rectangle((20,16,899,88),fill='#14283e')
    d.line((36,94,883,94),fill='#e0bc71',width=2)
    d.line((36,96,883,96),fill='#413b2f')
    for x,sx in ((16,1),(903,-1)):
        for y,sy in ((16,1),(623,-1)):
            d.line([(x,y+sy*28),(x,y),(x+sx*28,y)],fill='#edcf89',width=2)
            for j in range(3):
                d.polygon([(x+sx*(5+j*5),y+sy*10),(x+sx*(12+j*5),y+sy*5),
                           (x+sx*(15+j*5),y+sy*13),(x+sx*(8+j*5),y+sy*18)],outline='#8d7649')
    # Page-rule details on the far border, never beneath Scripture or input.
    for y in range(126,596,34):
        for x in (20,898):d.line((x,y,x,y+14),fill='#3d4650')
    return image


def buttons():
    sheet=Image.new('RGBA',UI_SIZES['Buttons'])
    states=[((26,45,65),(10,23,39),'#cfb06d'),((43,66,88),(18,35,55),'#f4d894'),
            ((8,18,30),(26,43,62),'#d9b773'),((28,32,39),(16,22,30),'#6f6755')]
    for i,(top,bottom,rim) in enumerate(states):
        tile=material((44,44),top,bottom);d=ImageDraw.Draw(tile)
        d.rectangle((0,0,43,43),outline='#050c16')
        d.rectangle((1,1,42,42),outline=rim)
        d.rectangle((3,3,40,40),outline='#3f4b59' if i<3 else '#32383e')
        d.line((5,5,38,5),fill=rim)
        sheet.alpha_composite(tile,(0,i*45))
    return sheet


def main():
    V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
    images={name:Image.open(S/(name+'.png')).convert('RGBA') for name in
            ('Scribe','Scriptorium','Tabernacle','Dawn','Map')}
    icon,alpha=emblem();icon.save(S/'CivIcon.png');alpha.save(S/'Alpha.png')
    leader=images['Scribe'];w,h=leader.size
    edge=round(h*.50)
    portrait=leader.crop((round(w*.5-edge*.5),0,round(w*.5+edge*.5),edge))
    portrait.save(S/'Portrait.png')
    objects=Image.new('RGBA',(512,256))
    for i,name in enumerate(('Scriptorium','Tabernacle')):
        objects.paste(ImageOps.fit(images[name],(256,256),Image.Resampling.LANCZOS),(256*i,0))
    masters={'Icon':icon,'Portrait':portrait,'Objects':objects,'Alpha':alpha}
    retained=R/'art-source/IconAtlasMasters';retained.mkdir(parents=True,exist_ok=True)
    for stem,source in masters.items():
        cols=2 if stem=='Objects' else 1
        source=ImageOps.fit(source,(cols*256,256),Image.Resampling.LANCZOS)
        if stem!='Alpha':source.save(retained/f'COVENANT_{stem}256.png')
        for size in SIZES:
            output=Image.new('RGBA',(cols*size,size))
            for i in range(cols):
                cell=source.crop((256*i,0,256*(i+1),256))
                cell=cell.resize((size,size),Image.Resampling.LANCZOS) if stem=='Alpha' else frame_cell(cell,size,stem=='Portrait')
                output.alpha_composite(cell,(size*i,0))
            (V/f'COVENANT_{stem}{size}.dds').write_bytes(raw_mips(output))
    (V/'COVENANT_Flag32.dds').write_bytes(raw_mips(alpha.resize((32,32),Image.Resampling.LANCZOS)))
    for name,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(512,512))]:
        image=images['Scribe' if name=='Leader' else name]
        (V/f'COVENANT_{name}.dds').write_bytes(raw_mips(ImageOps.fit(image,size,Image.Resampling.LANCZOS)))
    (V/'COVENANT_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="COVENANT_Leader.dds" />\n',encoding='utf-8',newline='\n')
    trim=Image.new('RGBA',UI_SIZES['Trim']);td=ImageDraw.Draw(trim)
    for y,color in enumerate(('#55452c','#d6b66e','#463b2b')):td.line((0,y,843,y),fill=color)
    for name,image in {'Panel':panel(),'Buttons':buttons(),'Trim':trim}.items():
        image.save(S/f'UI_{name}.png');(V/f'COVENANT_UI_{name}.dds').write_bytes(raw_mips(image))
    art_sql='-- Original Covenant art; presentation updates only.\n'
    for family,stem,cols,sizes in [('CIV','Icon',1,SIZES),('ALPHA','Alpha',1,SIZES),('LEADER','Portrait',1,SIZES),('OBJECT','Objects',2,SIZES),('FLAG','Flag',1,(32,))]:
        for size in sizes:
            art_sql+=f"INSERT INTO IconTextureAtlases VALUES ('COVENANT_{family}_ATLAS',{size},'COVENANT_{stem}{size}.dds',{cols},1);\n"
    art_sql+="""
UPDATE Civilizations SET PortraitIndex=0,IconAtlas='COVENANT_CIV_ATLAS',
 AlphaIconAtlas='COVENANT_ALPHA_ATLAS',MapImage='COVENANT_Map.dds',
 DawnOfManImage='COVENANT_Dawn.dds',DawnOfManAudio=''
 WHERE Type='CIVILIZATION_COVENANT_MEMORY';
UPDATE Leaders SET PortraitIndex=0,IconAtlas='COVENANT_LEADER_ATLAS',
 ArtDefineTag='COVENANT_LeaderScene.xml' WHERE Type='LEADER_COVENANT_SCRIBE';
UPDATE Buildings SET PortraitIndex=0,IconAtlas='COVENANT_OBJECT_ATLAS'
 WHERE Type='BUILDING_COVENANT_SCRIPTORIUM';
UPDATE Buildings SET PortraitIndex=1,IconAtlas='COVENANT_OBJECT_ATLAS'
 WHERE Type='BUILDING_COVENANT_TABERNACLE';
"""
    (R/'TheCovenant/SQL/03_COVENANT_Art.sql').write_text(art_sql,encoding='utf-8',newline='\n')
    # Review the actual compiled 256px cells and scene exports.
    review=Image.new('RGB',(1280,920),'#0b1422');d=ImageDraw.Draw(review)
    face=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',19)
    title=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',30)
    d.text((30,18),'THE COVENANT — ORIGINAL ART SET',font=title,fill='#e9cd90')
    for i,(stem,index,label) in enumerate([('Icon',0,'The Covenant'),('Portrait',0,'The Scribe'),('Objects',0,'Scriptorium'),('Objects',1,'Tabernacle')]):
        im=Image.open(V/f'COVENANT_{stem}256.dds').convert('RGBA').crop((index*256,0,(index+1)*256,256))
        x=32+i*312;review.paste(im,(x,80),im)
        d.text((x+128-d.textlength(label,font=face)/2,348),label,font=face,fill='#f0e2c7')
    for i,(name,label) in enumerate([('Leader','Static leader scene'),('Dawn','Dawn of Man'),('Map','Civilization map')]):
        im=Image.open(V/f'COVENANT_{name}.dds').convert('RGB')
        im=ImageOps.contain(im,(390,440),Image.Resampling.LANCZOS)
        x=24+i*420+(390-im.width)//2;y=408+(440-im.height)//2
        review.paste(im,(x,y));d.text((24+i*420,866),label,font=face,fill='#e9cd90')
    review.save(S/'Preview.png')
    print('Compiled 43 full-mip DDS textures, static leader scene, atlas SQL and review image')


if __name__=='__main__':main()
