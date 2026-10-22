"""Technical crops/atlas assembly of the user's supplied emblem; no invented photos.

The source already depicts white Austin with a crown. Sisi is the dark
tortoiseshell face at the lower left; the decorative tail is not a portrait.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps, ImageFont
from prepare_red_art import raw_mips
from cats_data import CATS
R=Path(__file__).resolve().parents[1]; S=R/'art-source/The11Cats'; V=R/'The11Cats/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
PURPLE='#38204f';GOLD='#edbf63';CREAM='#fff1cf'
CROPS={
 'AUSTIN':(387,350,865,825),'LUNA':(510,66,743,310),
 'BONNIE':(778,126,982,348),'APPA':(935,334,1181,579),
 'LOKI':(978,579,1205,814),'KURO':(298,107,507,359),
 'OSCAR':(215,800,452,1035),'BOOMIE':(143,340,379,570),
 'CHARLOTTE':(428,935,654,1183),'SISI':(62,575,310,816),
 'MAX':(844,801,1054,1059),
}
def symbol(kind,alpha=False):
 im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im);color='white' if alpha else GOLD
 if not alpha:d.ellipse((7,7,249,249),fill=PURPLE,outline=GOLD,width=7)
 if kind=='tree':
  d.rounded_rectangle((62,208,202,223),radius=6,fill=color)
  d.rectangle((120,67,137,216),fill=color);d.rectangle((68,129,83,213),fill=color)
  d.rounded_rectangle((47,114,115,132),radius=5,fill=color)
  d.rounded_rectangle((96,65,196,82),radius=5,fill=color)
  d.polygon([(151,62),(152,42),(164,53),(177,42),(182,62)],fill=CREAM)
 else:
  for box in [(62,85,96,132),(105,70,139,117),(150,85,184,132)]: d.ellipse(box,fill=color)
  d.ellipse((80,130,175,204),fill=color)
  d.polygon([(80,61),(72,27),(105,43),(128,17),(151,43),(184,27),(176,61)],fill=color)
  if not alpha:
   d.text((112,153),'11',fill=PURPLE,font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',25))
 return im
def main():
 V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
 source=Image.open(S/'Emblem.png').convert('RGBA');source=source.resize((1280,1280),Image.Resampling.LANCZOS)
 cats=Image.new('RGBA',(1024,768))
 portraits={}
 for i,(id,*_) in enumerate(CATS):
  portrait=ImageOps.fit(source.crop(CROPS[id]),(256,256),Image.Resampling.LANCZOS)
  mask=Image.new('L',(256,256));ImageDraw.Draw(mask).ellipse((3,3,253,253),fill=255)
  portrait.putalpha(mask);portraits[id]=portrait;cats.paste(portrait,((i%4)*256,(i//4)*256))
 objects=Image.new('RGBA',(512,256));objects.paste(symbol('tree'),(0,0));objects.paste(portraits['LUNA'],(256,0))
 masters={'Icon':source.resize((256,256),Image.Resampling.LANCZOS),'Alpha':symbol('paw',True),'Portrait':portraits['AUSTIN'],'Objects':objects,'Cats':cats}
 for stem,master in masters.items():
  master.save(S/(stem+'.png'))
  for size in SIZES:
   if stem=='Icon' and size<=48: im=symbol('paw').resize((size,size),Image.Resampling.LANCZOS)
   else:im=master.resize((size*(master.width//256),size*(master.height//256)),Image.Resampling.LANCZOS)
   (V/f'THE11CATS_{stem}{size}.dds').write_bytes(raw_mips(im))
 (V/'THE11CATS_Flag32.dds').write_bytes(raw_mips(symbol('paw',True).resize((32,32),Image.Resampling.LANCZOS)))
 # Full emblem on a quiet purple field; preserve its composition and white King.
 for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Household',(1024,768)),('Map',(512,512))]:
  im=Image.new('RGBA',size,PURPLE);scale=min(size);emblem=source.resize((scale,scale),Image.Resampling.LANCZOS)
  im.paste(emblem,((size[0]-scale)//2,(size[1]-scale)//2));(V/f'THE11CATS_{stem}.dds').write_bytes(raw_mips(im))
 (V/'THE11CATS_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="THE11CATS_Leader.dds" />\n',encoding='utf-8',newline='\n')
 print('Prepared 50 mipmapped DDS assets from the supplied emblem, including eleven distinct source crops')
if __name__=='__main__':main()
