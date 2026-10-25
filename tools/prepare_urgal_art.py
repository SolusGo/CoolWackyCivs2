"""Compile original Urgal paintings and deterministic symbols to legacy DDS."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1]
S=R/'art-source/TheUrgal'
V=R/'TheUrgal/Art'
SIZES=[16,24,32,45,48,64,80,128,256]

def bottle(alpha=False):
 im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
 if not alpha: d.ellipse((4,4,252,252),fill='#270e35',outline='#d7b563',width=8)
 white='white' if alpha else '#f8d6ff'
 d.polygon([(99,46),(157,46),(157,100),(190,131),(190,204),(175,220),(81,220),(66,204),(66,131),(99,100)],fill=white)
 if not alpha:
  d.rectangle((96,34,160,57),fill='#bc884e')
  d.polygon([(77,151),(179,151),(179,199),(169,210),(87,210),(77,199)],fill='#cf32e6')
  d.line((88,145,88,189),fill='#fff3ff',width=9)
  d.rectangle((114,65,141,103),fill='#6f487c')
 else:
  d.rectangle((96,34,160,57),fill=white)
  d.rectangle((117,67,139,98),fill=(0,0,0,0))
 return im

def main():
 V.mkdir(parents=True,exist_ok=True)
 leader=Image.open(S/'Urgal.png').convert('RGBA');w,h=leader.size
 portrait=leader.crop((int(w*.10),int(h*.04),int(w*.43),int(h*.68)))
 objects=Image.new('RGBA',(512,256))
 for i,name in enumerate(['BrewingStand.png','Rusher.png']):
  objects.alpha_composite(ImageOps.fit(Image.open(S/name).convert('RGBA'),(256,256),Image.Resampling.LANCZOS),(i*256,0))
 promotions=Image.new('RGBA',(512,256));promotions.alpha_composite(bottle(),(0,0))
 badge=Image.new('RGBA',(256,256),'#270e35');d=ImageDraw.Draw(badge)
 d.ellipse((7,7,249,249),fill='#381146',outline='#d7b563',width=9)
 d.polygon([(61,183),(169,55),(191,49),(187,75),(81,204)],fill='#f5d6ff')
 d.line((65,157,104,189),fill='#d7b563',width=15)
 d.rectangle((155,154,176,218),fill='#ff8bbc');d.rectangle((134,175,197,196),fill='#ff8bbc')
 promotions.alpha_composite(badge,(256,0))
 masters={'Icon':bottle(),'Alpha':bottle(True),'Objects':objects,'Portrait':portrait,'Promotions':promotions}
 for stem,master in masters.items():
  columns=2 if stem in ['Objects','Promotions'] else 1
  master=ImageOps.fit(master,(256*columns,256),Image.Resampling.LANCZOS)
  for size in SIZES: (V/f'URGAL_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*columns,size),Image.Resampling.LANCZOS)))
 for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768))]:
  (V/f'URGAL_{stem}.dds').write_bytes(raw_mips(ImageOps.fit(leader,size,Image.Resampling.LANCZOS)))
 # Illustrative Hardcore Games arena. Content fits the native 360x410 map window.
 arena=Image.new('RGBA',(360,410),'#d4c09b');d=ImageDraw.Draw(arena)
 d.ellipse((28,48,332,352),fill='#63714e',outline='#654e37',width=5)
 for x,y in [(91,122),(250,112),(99,274),(271,259),(156,89),(247,311)]:
  d.rectangle((x-14,y-12,x+13,y+14),fill='#354731')
 d.line([(63,221),(123,188),(186,201),(237,165),(305,184)],fill='#8badb5',width=13)
 for x,y in [(69,205),(278,179),(178,79),(177,321)]:
  d.line((x,y,180,202),fill='#b8a075',width=4)
 d.rectangle((159,181,201,223),fill='#53345c',outline='#e3c167',width=4)
 d.text((150,235),'THE FEAST',fill='#35243c')
 d.text((81,371),'HARDCORE GAMES ARENA',fill='#35243c')
 mapImage=Image.new('RGBA',(512,512),'#d4c09b');mapImage.alpha_composite(arena,(0,0))
 (V/'URGAL_Map.dds').write_bytes(raw_mips(mapImage));arena.save(S/'ArenaMap.png')
 (V/'URGAL_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="URGAL_Leader.dds" />\n',encoding='utf-8',newline='\n')
 preview=Image.new('RGBA',(1024,256),'#17101e')
 for i,im in enumerate([masters['Icon'],portrait,objects.crop((256,0,512,256)),objects.crop((0,0,256,256))]):
  preview.alpha_composite(ImageOps.fit(im,(256,256),Image.Resampling.LANCZOS),(i*256,0))
 preview.convert('RGB').save(S/'Preview.png')
 print('Compiled 48 Urgal DDS textures and static leader scene')

if __name__=='__main__': main()
