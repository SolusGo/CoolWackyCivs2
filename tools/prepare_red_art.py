"""Compile original Red paintings and collection-style vector-drawn symbols to DDS."""
from pathlib import Path
import io, math, shutil, struct, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont, ImageOps

R=Path(__file__).resolve().parents[1];S=R/'art-source/TrainerRed';V=R/'TrainerRed/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
CRIMSON='#b51935';WHITE='#f2f4ed';GOLD='#d7b563';INK='#152638'
NAMES=['PIKACHU','CHARIZARD','BLASTOISE','VENUSAUR','SNORLAX','LAPRAS']

def raw_mips(im):
 """Legacy uncompressed RGBA DDS including complete NPOT mip chain."""
 out=io.BytesIO();im.convert('RGBA').save(out,format='DDS');header=bytearray(out.getvalue()[:128])
 levels=[];im=im.convert('RGBA')
 while True:
  stream=io.BytesIO();im.save(stream,format='DDS');levels.append(stream.getvalue()[128:])
  if im.size==(1,1):break
  im=im.resize((max(1,im.width//2),max(1,im.height//2)),Image.Resampling.LANCZOS)
 struct.pack_into('<I',header,8,struct.unpack_from('<I',header,8)[0]|0x20000)
 struct.pack_into('<I',header,28,len(levels));struct.pack_into('<I',header,108,0x401008)
 return bytes(header)+b''.join(levels)

def emblem(kind,alpha=False):
 im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
 if not alpha:d.ellipse((7,7,249,249),fill=INK,outline=GOLD,width=7)
 color=WHITE
 def mountain():
  d.polygon([(36,181),(111,63),(144,111),(168,80),(228,181)],fill='#93a9b9' if not alpha else color)
  if not alpha:d.polygon([(88,100),(111,63),(144,111),(119,100),(111,90),(101,108)],fill=WHITE)
 if kind in ['CIV','CAUGHT','TRAINED','PROVEN','CHAMPION','LEGENDARY']:
  if kind=='CIV':mountain()
  d.ellipse((59,86,197,224),fill=WHITE,outline=INK,width=9)
  d.pieslice((59,86,197,224),180,360,fill=CRIMSON if not alpha else color)
  d.line((62,155,194,155),fill=INK if not alpha else (0,0,0,0),width=10)
  d.ellipse((111,138,145,172),fill=WHITE,outline=INK if not alpha else color,width=6)
  if kind!='CIV':
   n=['CAUGHT','TRAINED','PROVEN','CHAMPION','LEGENDARY'].index(kind)
   for i in range(n):d.ellipse((51+i*40,43,68+i*40,60),fill=GOLD)
 elif kind in ['ACE','BOND','TEAM']:
  d.pieslice((50,70,195,190),180,360,fill=CRIMSON if not alpha else color)
  d.polygon([(51,130),(193,130),(229,155),(50,155)],fill=color)
  if not alpha:d.ellipse((106,95,139,125),fill=WHITE)
 elif kind=='CENTER':
  d.rounded_rectangle((43,72,213,203),radius=12,fill=WHITE)
  d.polygon([(32,79),(128,32),(225,79)],fill=CRIMSON)
  d.rectangle((112,101,143,177),fill=CRIMSON);d.rectangle((88,122,168,151),fill=CRIMSON)
 elif kind=='PLATEAU':
  d.polygon([(32,104),(128,49),(224,104)],fill=color)
  for x in [55,101,149,193]:d.rectangle((x,107,x+12,187),fill=GOLD)
  d.rectangle((40,190,218,204),fill=color);d.ellipse((106,57,149,101),fill=CRIMSON)
 elif kind in ['JOURNEY','SUMMIT']:
  mountain();d.ellipse((121,62,136,77),fill=CRIMSON);d.line((128,78,128,112),fill=CRIMSON,width=11)
 elif kind in ['RIBBON','HORIZON']:
  d.polygon([(90,136),(65,222),(121,197),(132,150)],fill=CRIMSON)
  d.polygon([(129,151),(158,220),(191,204),(166,133)],fill=CRIMSON)
  d.regular_polygon((128,111,63),8,rotation=22,fill=GOLD);d.ellipse((91,74,165,148),fill=INK,outline=WHITE,width=5)
 elif kind=='PIKACHU':
  d.polygon([(142,35),(63,132),(118,132),(101,222),(197,102),(141,102)],fill='#f4d34f')
 elif kind=='CHARIZARD':
  d.polygon([(127,31),(144,91),(177,67),(174,118),(208,111),(194,168),(162,211),(112,222),(62,188),(50,134),(97,165),(90,100)],fill='#ec873d')
 elif kind=='BLASTOISE':
  d.regular_polygon((128,140,75),6,rotation=30,fill='#75b5d7',outline=WHITE,width=7)
  d.rounded_rectangle((46,45,82,131),radius=12,fill='#9eaeb4');d.rounded_rectangle((174,45,210,131),radius=12,fill='#9eaeb4')
 elif kind in ['VENUSAUR','BLOOM_STATUS']:
  for angle in range(0,360,72):
   x=128+math.cos(math.radians(angle))*46;y=121+math.sin(math.radians(angle))*46
   d.ellipse((x-34,y-34,x+34,y+34),fill='#d86e88')
  d.ellipse((101,93,155,147),fill=GOLD);d.polygon([(64,201),(109,156),(128,199),(166,161),(206,207)],fill='#77a77b')
 elif kind=='SNORLAX':
  mountain();d.ellipse((63,89,193,213),fill='#587e90');d.ellipse((88,112,169,204),fill=WHITE)
 elif kind=='LAPRAS':
  for y in [108,147,184]:d.arc((35,y-36,133,y+28),0,180,fill='#89c7e4',width=12);d.arc((128,y-36,224,y+28),0,180,fill='#89c7e4',width=12)
 else:
  d.regular_polygon((128,128,73),6,fill=GOLD);d.ellipse((95,95,161,161),fill=CRIMSON)
 return im

def atlas(kinds,size):
 cols=8 if len(kinds)>8 else len(kinds);rows=math.ceil(len(kinds)/cols)
 im=Image.new('RGBA',(cols*size,rows*size))
 for i,kind in enumerate(kinds):im.alpha_composite(emblem(kind).resize((size,size),Image.Resampling.LANCZOS),((i%cols)*size,(i//cols)*size))
 return im

def map_art():
 im=Image.new('RGBA',(512,512),'#d8c99f');d=ImageDraw.Draw(im)
 d.rectangle((10,10,501,501),outline=GOLD,width=8)
 d.polygon([(34,192),(79,78),(183,55),(228,122),(266,85),(375,81),(468,175),(450,320),(380,405),(293,436),(211,365),(118,396),(51,313)],fill='#829d8e',outline=INK,width=3)
 d.line([(248,105),(254,196),(224,255),(258,320)],fill='#739fad',width=11)
 font=ImageFont.truetype('C:/Windows/Fonts/georgia.ttf',19)
 small=ImageFont.truetype('C:/Windows/Fonts/georgia.ttf',14)
 for x,y,label in [(136,139,'JOHTO'),(339,145,'KANTO')]:d.text((x,y),label,font=font,fill=INK,anchor='mm')
 points=[(344,344,'Pallet Town'),(227,214,'Mt. Silver'),(304,252,'Indigo Plateau')]
 for x,y,label in points:
  d.ellipse((x-6,y-6,x+6,y+6),fill=CRIMSON,outline=WHITE,width=2);d.text((x,y+17),label,font=small,fill=INK,anchor='mm')
 d.polygon([(202,205),(227,162),(251,205)],fill=WHITE,outline=INK)
 d.text((256,467),'THE INDIGO CHAMPION',font=font,fill=INK,anchor='mm')
 return im

def main():
 V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
 leader=Image.open(S/'RedOnSilver.png').convert('RGBA');dawn=Image.open(S/'SilverDawn.png').convert('RGBA')
 outputs={'RED_Leader':ImageOps.fit(leader,(1600,900)),'RED_Dawn':ImageOps.fit(dawn,(1024,768)),'RED_Map':map_art()}
 promo=['CAUGHT','TRAINED','PROVEN','CHAMPION','LEGENDARY','RIBBON','BOND','SUMMIT']+NAMES+['BLOOM_STATUS','HORIZON']+['ACE']*16
 for size in SIZES:
  outputs[f'RED_Icon{size}']=emblem('CIV').resize((size,size),Image.Resampling.LANCZOS)
  outputs[f'RED_Alpha{size}']=emblem('CIV',True).resize((size,size),Image.Resampling.LANCZOS)
  outputs[f'RED_Objects{size}']=atlas(['ACE','CENTER','PLATEAU','JOURNEY'],size)
  outputs[f'RED_Identities{size}']=atlas(NAMES,size)
  outputs[f'RED_Promotions{size}']=atlas(promo,size)
  # Retain the face and red cap, not the whole illustration in a tiny portrait.
  crop=leader.crop((int(leader.width*.57),0,int(leader.width*.88),int(leader.height*.55)))
  portrait=ImageOps.fit(crop,(size,size));mask=Image.new('L',(size,size));ImageDraw.Draw(mask).ellipse((1,1,size-2,size-2),fill=255);portrait.putalpha(mask)
  outputs[f'RED_Portrait{size}']=portrait
 outputs['RED_Flag32']=emblem('ACE',True).resize((32,32),Image.Resampling.LANCZOS)
 texconv=shutil.which('texconv')
 assert texconv,'DirectXTex texconv is required'
 with tempfile.TemporaryDirectory(prefix='red-art-',dir=S) as temporary:
  stage=Path(temporary).resolve();assert stage.parent==S.resolve()
  pngs=[]
  for name,im in outputs.items():
   if im.width%4==0 and im.height%4==0:
    path=stage/(name+'.png');im.save(path);pngs.append(str(path))
   else:(V/(name+'.dds')).write_bytes(raw_mips(im))
  result=subprocess.run([texconv,'-nologo','-y','-dx9','-f','DXT5','-m','0','-o',str(stage),*pngs],capture_output=True,text=True)
  assert result.returncode==0,result.stdout+result.stderr
  for path in stage.glob('*.dds'):shutil.copyfile(path,V/path.name)
 (V/'RED_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="RED_Leader.dds" />\n',encoding='utf-8',newline='\n')
 preview=atlas(['CIV','ACE','CENTER','PLATEAU','JOURNEY']+NAMES,128);preview.save(S/'InsigniaPreview.png')
 print('Compiled',len(outputs),'original, mipmapped Red DDS textures')

if __name__=='__main__':main()
