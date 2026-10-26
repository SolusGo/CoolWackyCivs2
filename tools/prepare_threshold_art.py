"""Compile retained paintings and collection-style doorway symbols to DDS."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1];S=R/'art-source/TheThresholdCourt';V=R/'TheThresholdCourt/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
GOLD='#c9a65d';WOOD='#302b27';INK='#101f24';LIGHT='#f2e0b4'

def door(alpha=False):
 im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
 color='white' if alpha else GOLD
 if not alpha:d.ellipse((5,5,251,251),fill=INK,outline=GOLD,width=8)
 d.rounded_rectangle((55,35,201,227),radius=64,fill=color)
 d.rectangle((55,107,201,227),fill=color)
 inside=(0,0,0,0) if alpha else WOOD
 d.rounded_rectangle((73,54,183,216),radius=50,fill=inside)
 d.rectangle((73,113,183,216),fill=inside)
 d.rectangle((122,82,134,216),fill=color)
 d.rectangle((41,218,215,231),fill=color)
 if not alpha:
  for y in [119,174]:d.rectangle((77,y,105,y+8),fill=GOLD);d.rectangle((151,y,179,y+8),fill=GOLD)
  d.ellipse((141,142,152,153),fill=LIGHT)
 return im

def house():
 im=Image.new('RGBA',(256,256),INK);d=ImageDraw.Draw(im)
 d.polygon([(21,103),(128,26),(235,103)],fill=GOLD)
 d.rectangle((36,101,220,224),fill=WOOD,outline=GOLD,width=7)
 for x in [50,187]:
  d.rectangle((x,114,x+20,177),fill='#70a5a8',outline=GOLD,width=4)
 portal=door();portal=portal.crop((36,29,220,237)).resize((104,119),Image.Resampling.LANCZOS)
 im.alpha_composite(portal,(76,106))
 return im

def main():
 V.mkdir(parents=True,exist_ok=True)
 queen=Image.open(S/'QueenElsewhere.png').convert('RGBA');w,h=queen.size
 portrait=queen.crop((round(w*.22),0,round(w*.70),round(h*.94)))
 guard=ImageOps.fit(Image.open(S/'Hingeguard.png').convert('RGBA'),(256,256),Image.Resampling.LANCZOS)
 objects=Image.new('RGBA',(512,256));objects.alpha_composite(house(),(0,0));objects.alpha_composite(guard,(256,0))
 promos=Image.new('RGBA',(512,256));promos.alpha_composite(door(),(0,0));promos.alpha_composite(door(),(256,0))
 d=ImageDraw.Draw(promos);d.line((306,195,462,62),fill='#c36f54',width=22)
 masters={'Icon':door(),'Alpha':door(True),'Portrait':portrait,'Objects':objects,'Promotions':promos}
 for stem,im in masters.items():
  cols=2 if stem in ['Objects','Promotions'] else 1
  im=ImageOps.fit(im,(256*cols,256),Image.Resampling.LANCZOS)
  for size in SIZES:(V/f'THC_{stem}{size}.dds').write_bytes(raw_mips(im.resize((size*cols,size),Image.Resampling.LANCZOS)))
 for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768))]:
  (V/f'THC_{stem}.dds').write_bytes(raw_mips(ImageOps.fit(queen,size,Image.Resampling.LANCZOS)))
 im=Image.new('RGBA',(512,512),'#b5aa89');d=ImageDraw.Draw(im)
 # Illustrative, geographically separated provinces joined by doors.
 for x,y in [(107,111),(339,113),(138,329),(370,356)]:
  d.polygon([(x-60,y-45),(x+52,y-64),(x+79,y+30),(x+15,y+74),(x-73,y+20)],fill=INK,outline=GOLD,width=4)
 for a,b in [((107,111),(370,356)),((339,113),(138,329)),((107,111),(138,329)),((339,113),(370,356))]:d.line([a,b],fill='#785f38',width=3)
 small=door(True).resize((34,34),Image.Resampling.LANCZOS)
 for x,y in [(107,111),(339,113),(138,329),(370,356)]:im.alpha_composite(small,(x-17,y-17))
 (V/'THC_Map.dds').write_bytes(raw_mips(im))
 (V/'THC_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="THC_Leader.dds" />\n',encoding='utf-8',newline='\n')
 preview=Image.new('RGBA',(1024,256),INK)
 for i,im in enumerate([door(),portrait,guard,house()]):preview.alpha_composite(ImageOps.fit(im,(256,256),Image.Resampling.LANCZOS),(i*256,0))
 preview.convert('RGB').save(S/'Preview.png')
 print('Compiled 48 Threshold DDS textures: original queen/guardian, doorway heraldry, Market icon, map')

if __name__=='__main__':main()
