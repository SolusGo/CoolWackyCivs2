"""Mechanical DDS exports of the six retained AI paintings; no artwork regeneration.

Reuse the collection's monochrome laurel/flag convention and gold circular frames.
All textures are legacy RGBA DDS with complete mip chains (including 45px slots).
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
from dds_mips import raw_mips
from standardize_icons import frame_cell
from prepare_laureate_art import alpha

R=Path(__file__).resolve().parents[1]
S=R/'art-source/TheTriumphalImperium'
V=R/'TheTriumphalImperium/Art'
SIZES=[16,24,32,45,48,64,80,128,256]

def main():
    V.mkdir(parents=True,exist_ok=True)
    images={name:Image.open(S/(name+'.png')).convert('RGBA')
            for name in ('CivIcon','Aurelion','Unbroken','Hall','Dawn','Map')}
    leader=images['Aurelion'];w,h=leader.size
    portrait=leader.crop((round(w*.29),0,round(w*.71),round(w*.42)))
    objects=Image.new('RGBA',(512,256))
    for i,name in enumerate(('Unbroken','Hall')):
        objects.paste(ImageOps.fit(images[name],(256,256),Image.Resampling.LANCZOS),(i*256,0))
    masters={'Icon':images['CivIcon'],'Portrait':portrait,'Objects':objects,'Alpha':alpha(True)}
    retained=R/'art-source/IconAtlasMasters';retained.mkdir(parents=True,exist_ok=True)
    for stem,source in masters.items():
        cols=2 if stem=='Objects' else 1
        source=ImageOps.fit(source,(cols*256,256),Image.Resampling.LANCZOS)
        if stem!='Alpha': source.save(retained/f'TRI_{stem}256.png')
        for size in SIZES:
            out=Image.new('RGBA',(cols*size,size))
            for i in range(cols):
                cell=source.crop((256*i,0,256*(i+1),256))
                cell=cell.resize((size,size),Image.Resampling.LANCZOS) if stem=='Alpha' else frame_cell(cell,size,stem=='Portrait',preserve_art=stem=='Portrait')
                out.alpha_composite(cell,(size*i,0))
            (V/f'TRI_{stem}{size}.dds').write_bytes(raw_mips(out))
    (V/'TRI_Flag32.dds').write_bytes(raw_mips(alpha(True).resize((32,32),Image.Resampling.LANCZOS)))
    for name,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(512,512))]:
        source=images['Aurelion' if name=='Leader' else name]
        (V/f'TRI_{name}.dds').write_bytes(raw_mips(ImageOps.fit(source,size,Image.Resampling.LANCZOS)))
    (V/'TRI_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="TRI_Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGB',(1024,760),'#340912');draw=ImageDraw.Draw(preview)
    for i,name in enumerate(('Icon','Portrait','Unbroken','Hall')):
        source=masters.get(name,images.get(name))
        cell=frame_cell(source,256,name=='Portrait',preserve_art=name=='Portrait')
        preview.paste(cell,(i*256,0),cell)
        draw.text((i*256+16,256),name,fill='#edcf87')
    for i,name in enumerate(('Aurelion','Dawn','Map')):
        thumb=ImageOps.contain(images[name],(326,430),Image.Resampling.LANCZOS)
        preview.paste(thumb,(i*342+(326-thumb.width)//2,296+(430-thumb.height)//2))
        draw.text((i*342+16,735),name,fill='#edcf87')
    preview.save(S/'Preview.png')
    print('Compiled 40 full-mip RGBA DDS textures, static leader scene, and art review')

if __name__=='__main__': main()
