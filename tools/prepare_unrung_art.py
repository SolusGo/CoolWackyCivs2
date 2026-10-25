"""Compile original generated Unrung Bell paintings into legacy mipmapped DDS."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R = Path(__file__).resolve().parents[1]
S = R/'art-source/KingdomOfTheUnrungBell'
V = R/'KingdomOfTheUnrungBell/Art'
SIZES = [16,24,32,45,48,64,80,128,256]

def bell_alpha():
    im = Image.new('RGBA', (256,256))
    d = ImageDraw.Draw(im)
    d.arc((107,26,149,70),180,360,fill='white',width=13)
    d.polygon([(128,53),(88,70),(77,155),(48,198),(208,198),(179,155),(168,70)],fill='white')
    d.ellipse((113,204,143,228),fill='white')
    # Transparent chain crossings keep the tintable silhouette legible.
    d.line((73,99,183,179),fill=(0,0,0,0),width=16)
    d.line((183,99,73,179),fill=(0,0,0,0),width=16)
    return im

def main():
    V.mkdir(parents=True,exist_ok=True)
    leader = Image.open(S/'Sable.png').convert('RGBA')
    w,h = leader.size
    portrait = leader.crop((round(w*.16),round(h*.05),round(w*.48),round(h*.77)))
    objects = Image.new('RGBA',(512,256))
    for i,name in enumerate(['SilentBelfry.png','Bellwarden.png']):
        objects.alpha_composite(ImageOps.fit(Image.open(S/name).convert('RGBA'),(256,256),Image.Resampling.LANCZOS),(i*256,0))
    promotions = Image.new('RGBA',(1024,256))
    for i in range(4):
        badge = Image.new('RGBA',(256,256),'#0b1427')
        d=ImageDraw.Draw(badge)
        d.ellipse((8,8,248,248),fill='#121d31',outline='#bca369',width=10)
        badge.alpha_composite(bell_alpha().resize((170,170),Image.Resampling.LANCZOS),(43,29))
        for j in range(i):
            x=128-(i-1)*18+j*36
            d.line((x-10,221,x,206,x+10,221),fill='#e5d0a2',width=6)
        promotions.alpha_composite(badge,(i*256,0))
    masters={'Icon':Image.open(S/'ChainedBell.png').convert('RGBA'),'Alpha':bell_alpha(),
             'Portrait':portrait,'Objects':objects,'Promotions':promotions}
    for stem,master in masters.items():
        columns={'Objects':2,'Promotions':4}.get(stem,1)
        master=ImageOps.fit(master,(256*columns,256),Image.Resampling.LANCZOS)
        for size in SIZES:
            (V/f'UNRUNG_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*columns,size),Image.Resampling.LANCZOS)))
    for name,im,size in [('Leader',leader,(1600,900)),('Dawn',leader,(1024,768))]:
        (V/f'UNRUNG_{name}.dds').write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))
    # An explicitly illustrative kingdom map, not a real-world territorial claim.
    im=Image.new('RGBA',(512,512),'#b7b7b0');d=ImageDraw.Draw(im)
    d.polygon([(115,55),(268,37),(401,129),(376,257),(426,376),(284,460),(139,405),(76,260)],fill='#253046',outline='#d5d8dd',width=8)
    for x,y in [(206,231),(293,142),(310,346),(142,320)]:
        d.ellipse((x-9,y-9,x+9,y+9),fill='#d8dbe2')
    d.line([(206,231),(293,142),(310,346),(142,320),(206,231)],fill='#838d9c',width=3)
    (V/'UNRUNG_Map.dds').write_bytes(raw_mips(im))
    (V/'UNRUNG_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="UNRUNG_Leader.dds" />\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGBA',(1024,256),'#101825')
    for i,im in enumerate([masters['Icon'],portrait,objects.crop((256,0,512,256)),objects.crop((0,0,256,256))]):
        preview.alpha_composite(ImageOps.fit(im,(256,256),Image.Resampling.LANCZOS),(i*256,0))
    preview.convert('RGB').save(S/'Preview.png')
    print('Compiled 48 mipmapped DDS textures and static leader scene; native Pikeman model/flag retained')

if __name__ == '__main__': main()
