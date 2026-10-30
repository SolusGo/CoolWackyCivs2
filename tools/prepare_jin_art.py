"""Original Jin iconography and loading painting, compiled to legacy mipmapped DDS."""
from pathlib import Path
import math
from PIL import Image,ImageDraw,ImageOps
from prepare_red_art import raw_mips
R=Path(__file__).resolve().parents[1];V=R/'JinDynasty/Art';S=R/'art-source/JinDynasty'
SIZES=[16,24,32,45,48,64,80,128,256]
GOLD='#dab76b';CREAM='#fff1c9';RED='#650e20';INK='#25121a'

def symbol(kind,alpha=False,scale=1):
 im=Image.new('RGBA',(256*scale,256*scale));native=ImageDraw.Draw(im)
 class ScaledDraw:
  def __getattr__(self,name):
   def draw(xy,*args,**kwargs):
    def scaled(v):return tuple(scaled(n)for n in v) if isinstance(v,(list,tuple)) else v*scale
    if 'width' in kwargs:kwargs['width']*=scale
    return getattr(native,name)(scaled(xy),*args,**kwargs)
   return draw
 d=ScaledDraw()
 if not alpha:d.ellipse((3,3,253,253),fill=RED,outline=GOLD,width=7)
 fg='white' if alpha else CREAM;gold=fg if alpha else GOLD
 def horse():
  d.polygon([(48,139),(78,102),(155,107),(170,62),(199,45),(207,91),(190,130),(170,155),(153,184),(142,224),(125,224),(130,171),(91,171),(76,224),(57,224),(68,164)],fill=fg)
  d.line((174,62,159,34),fill=gold,width=9);d.line((71,114,37,83),fill=gold,width=10)
  if not alpha:d.ellipse((190,73,197,80),fill=INK)
 def pagoda():
  for y,w in [(77,85),(122,116),(168,150)]:
   d.polygon([(128,y-25),(128-w//2,y),(128+w//2,y)],fill=gold)
   d.rectangle((128-w//3,y,128+w//3,y+30),fill=fg)
  d.line((128,37,128,53),fill=fg,width=7);d.rectangle((59,207,198,220),fill=gold)
 def sword(x=128):
  d.polygon([(x-10,173),(x-9,66),(x,29),(x+9,66),(x+10,173)],fill=fg)
  d.line((x-35,177,x+35,177),fill=gold,width=12);d.line((x,179,x,226),fill=gold,width=13)
 if kind in ['civ','iron','horse','mohe','worker','grenadier','defender','trader']:
  horse()
  if kind=='civ':
   d.arc((31,25,225,220),190,350,fill=gold,width=10)
   d.polygon([(95,53),(110,27),(127,48),(147,22),(167,58)],fill=gold)
  if kind=='iron':
   for y in range(115,157,12):d.line((91,y,155,y),fill=RED if not alpha else (0,0,0,0),width=4)
   d.polygon([(87,69),(135,51),(151,100),(98,100)],fill=gold)
  if kind=='mohe':d.arc((49,35,143,169),90,270,fill=gold,width=8);d.line((95,39,95,163),fill=gold,width=4)
  if kind=='worker':d.line((59,57,127,104),fill=gold,width=11);d.line((51,55,90,28),fill=gold,width=13)
  if kind=='grenadier':d.ellipse((60,34,111,84),fill=gold);d.line((90,36,113,20),fill=fg,width=6)
  if kind=='defender':d.line((111,99,104,25),fill=gold,width=8);d.polygon([(104,20),(90,47),(117,47)],fill=fg)
  if kind=='trader':d.rectangle((70,109,144,153),fill=gold);d.line((83,103,81,70),fill=gold,width=7);d.line((81,76,62,54),fill=gold,width=6)
 elif kind in ['pagoda','flower','dragon','forest','pasture','hall','bastion','stable','workshop','monastery']:
  if kind in ['pasture','stable']:
   d.polygon([(39,100),(128,39),(218,100)],fill=gold);d.rectangle((53,100,203,206),outline=fg,width=11)
   d.arc((83,110,172,220),180,360,fill=fg,width=11);d.line((86,157,86,209),fill=fg,width=11);d.line((169,157,169,209),fill=fg,width=11)
  elif kind=='bastion':
   d.rectangle((50,72,204,213),fill=fg)
   for x in [48,100,154]:d.rectangle((x,44,x+48,91),fill=gold)
   d.rectangle((109,157,146,215),fill=RED if not alpha else (0,0,0,0))
  else:
   pagoda()
   if kind=='flower':
    for i in range(5):
     x=128+29*math.cos(i*math.tau/5);y=135+29*math.sin(i*math.tau/5);d.ellipse((x-18,y-18,x+18,y+18),fill=RED if not alpha else (0,0,0,0),outline=gold,width=4)
   if kind=='dragon':d.arc((45,88,213,207),15,270,fill=RED if not alpha else (0,0,0,0),width=15)
   if kind=='forest':d.line((35,150,35,218),fill=gold,width=8);d.line((221,150,221,218),fill=gold,width=8)
   if kind=='workshop':d.line((52,55,203,204),fill=RED if not alpha else (0,0,0,0),width=16)
   if kind=='monastery':d.ellipse((100,117,155,172),fill=RED if not alpha else (0,0,0,0),outline=gold,width=6)
 elif kind in ['bed','bees','trebuchet']:
  d.line((57,191,128,86,196,192),fill=fg,width=13);d.line((46,189,211,189),fill=gold,width=10)
  d.ellipse((52,182,93,223),outline=fg,width=10);d.ellipse((169,182,210,223),outline=fg,width=10)
  if kind=='bed':
   d.arc((46,55,214,153),180,360,fill=gold,width=12)
   for x in [113,143]:d.line((x,159,x,42),fill=fg,width=7);d.polygon([(x,29),(x-10,49),(x+10,49)],fill=gold)
  elif kind=='bees':
   for x in [79,108,137,166]:d.line((x,142,x+19,64),fill=gold,width=12)
  else:d.line((87,161,168,39),fill=gold,width=13);d.ellipse((160,27,191,58),fill=fg)
 elif kind=='grassland':
  d.arc((34,114,223,237),180,360,fill=gold,width=10)
  for x in [61,127,193]:d.line((x,190,x-15,134,x,157,x+17,118),fill=fg,width=8)
  d.line((42,208,215,208),fill=gold,width=10)
 elif kind=='karma':
  d.ellipse((60,60,196,196),outline=gold,width=13)
  for i in range(8):
   angle=i*math.tau/8;d.line((128+81*math.cos(angle),128+81*math.sin(angle),128+105*math.cos(angle),128+105*math.sin(angle)),fill=fg,width=8)
  d.polygon([(128,85),(157,128),(128,171),(99,128)],fill=fg)
 elif kind=='zhanma':sword();d.line((51,198,199,63),fill=gold,width=7)
 elif kind=='eruptor':
  d.line((63,211,148,100),fill=fg,width=24);d.polygon([(118,105),(154,58),(193,86),(159,127)],fill=gold)
  for x,y in [(166,40),(202,49),(223,83)]:d.line((173,76,x,y),fill=fg,width=8)
 elif kind=='emissary':
  d.rectangle((75,53,190,199),fill=gold);d.rectangle((56,38,88,70),fill=fg);d.rectangle((164,185,206,218),fill=fg)
  for y in [86,116,146]:d.line((100,y,163,y),fill=RED if not alpha else (0,0,0,0),width=8)
 else:pagoda()
 return im

def legacy_main():
 V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
 painting=Image.open(S/'Aguda.png').convert('RGBA');w,h=painting.size
 portrait=ImageOps.fit(painting.crop((int(w*.04),0,int(w*.46),int(h*.77))),(256,256),Image.Resampling.LANCZOS)
 units=['worker','iron','mohe','bed','zhanma','eruptor','grenadier','defender','emissary','trader','bees','trebuchet']
 buildings=['flower','pasture','dragon','hall','bastion','forest','stable','workshop','monastery','horse']
 def atlas(kinds,cols,alpha=False):
  master=Image.new('RGBA',(cols*256,math.ceil(len(kinds)/cols)*256))
  for i,kind in enumerate(kinds):master.alpha_composite(symbol(kind,alpha),((i%cols)*256,(i//cols)*256))
  return master
 masters={'Icon':symbol('civ'),'Alpha':symbol('civ',True),'Portrait':portrait,'Units':atlas(units,4),'Buildings':atlas(buildings,5),'Flags':atlas(units,4,True)}
 for stem,master in masters.items():
  master.save(S/(stem+'.png'))
  for size in SIZES:(V/f'JIN_{stem}{size}.dds').write_bytes(raw_mips(master.resize((master.width*size//256,master.height*size//256),Image.Resampling.LANCZOS)))
 for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768))]:(V/f'JIN_{stem}.dds').write_bytes(raw_mips(ImageOps.fit(painting,size,Image.Resampling.LANCZOS)))
 header=Image.new('RGBA',(1024,128),RED);hd=ImageDraw.Draw(header);hd.rectangle((4,4,1019,123),outline=GOLD,width=3)
 (V/'JIN_Header.dds').write_bytes(raw_mips(header))
 for name,kind in [('Grassland','grassland'),('Horse','horse'),('Tributary','emissary'),('Karma','karma'),('Mengan','defender')]:
  im=symbol(kind);im.save(S/(name+'UI.png'));(V/('JIN_'+name+'UI32.dds')).write_bytes(raw_mips(im.resize((32,32),Image.Resampling.LANCZOS)))
 mapim=Image.new('RGBA',(512,512),'#d9c69c');md=ImageDraw.Draw(mapim)
 md.polygon([(60,65),(184,31),(284,72),(312,175),(263,212),(283,296),(202,363),(96,340),(43,243)],fill='#8b9865',outline='#5d523d',width=5)
 md.line([(265,47),(242,124),(273,198),(236,258),(269,330)],fill='#789fa5',width=14)
 md.line([(60,179),(134,170),(214,205),(287,178)],fill='#7c3d30',width=8)
 for x,y,label in [(187,92,'HUINING'),(132,194,'ZHONGDU'),(176,287,'KAIFENG')]:
  md.ellipse((x-6,y-6,x+6,y+6),fill=RED);md.text((x+10,y-5),label,fill=INK)
 md.text((60,385),'JIN DYNASTY / 1115-1234',fill=INK)
 mapim.save(S/'Map.png');(V/'JIN_Map.dds').write_bytes(raw_mips(mapim))
 (V/'JIN_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="JIN_Leader.dds"/>\n',encoding='utf-8',newline='\n')
 preview=Image.new('RGBA',(1024,768),INK);preview.alpha_composite(masters['Units'],(0,0));preview.convert('RGB').save(S/'Preview.png')
 print('Prepared',len(list(V.glob('*.dds'))),'original Jin DDS textures')

def main():
 from prepare_jin_visuals import main as compile_visuals
 compile_visuals()
if __name__=='__main__':main()
