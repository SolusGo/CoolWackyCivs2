"""Compile original generated Garvey painting and drawn collection-style icons."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps
from prepare_red_art import raw_mips
R=Path(__file__).resolve().parents[1]
S=R/'art-source/TheSubstituteClassroom'
V=R/'TheSubstituteClassroom/Art'
SIZES=[16,24,32,45,48,64,80,128,256]
GREEN='#123c2d';CHALK='#f3eed6';GOLD='#dcb867';RED='#cf5350'

def symbol(kind,alpha=False):
 im=Image.new('RGBA',(512,512));d=ImageDraw.Draw(im)
 if not alpha:d.ellipse((12,12,500,500),fill=GREEN,outline=GOLD,width=14)
 c='white' if alpha else CHALK
 cut=(0,0,0,0) if alpha else GREEN
 if kind=='office':
  d.rectangle((139,116,373,412),fill=c)
  d.rectangle((158,136,354,412),fill=cut)
  d.rectangle((184,164,328,249),fill=c)
  d.ellipse((310,288,327,305),fill=c)
  d.rectangle((178,78,334,109),fill=c)
 elif kind=='monitor':
  d.polygon([(256,107),(372,157),(354,317),(256,406),(158,317),(140,157)],fill=c)
  d.polygon([(256,139),(340,176),(324,300),(256,363),(188,300),(172,176)],fill=cut)
  d.line([(211,253),(247,291),(306,211)],fill=c,width=24)
 else:
  d.rounded_rectangle((141,119,371,410),radius=13,fill=c)
  d.rounded_rectangle((159,139,353,390),radius=6,fill=cut)
  d.rounded_rectangle((204,92,308,152),radius=9,fill=c)
  for y in [203,267,331]:
   d.line([(183,y),(196,y+12),(216,y-16)],fill=c,width=12)
   d.line((240,y,326,y),fill=c,width=13)
 return im

def save(im,name,size):
 (V/name).write_bytes(raw_mips(ImageOps.fit(im,size,Image.Resampling.LANCZOS)))

def main():
 V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
 painting=Image.open(S/'MrGarvey.png').convert('RGBA');w,h=painting.size
 portrait=painting.crop((int(w*.44),0,int(w*.70),int(h*.48)))
 objects=Image.new('RGBA',(1024,512));objects.paste(symbol('office'),(0,0));objects.paste(symbol('monitor'),(512,0))
 masters={'Icon':symbol('civ'),'Alpha':symbol('civ',True),'Portrait':portrait,'Objects':objects}
 for stem,im in masters.items():
  master=ImageOps.fit(im,(512 if stem=='Objects' else 256,256),Image.Resampling.LANCZOS)
  master.save(S/(stem+'.png'))
  for size in SIZES:(V/f'GARVEY_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*(2 if stem=='Objects' else 1),size),Image.Resampling.LANCZOS)))
 save(symbol('monitor',True),'GARVEY_Flag32.dds',(32,32))
 save(painting,'GARVEY_Leader.dds',(1600,900));save(painting,'GARVEY_Dawn.dds',(1024,768))
 plan=Image.new('RGBA',(512,512),'#c9b98e');d=ImageDraw.Draw(plan)
 for box in [(45,45,220,195),(292,45,467,195),(45,310,220,467),(292,310,467,467)]:d.rectangle(box,fill=GREEN,outline=GOLD,width=9)
 d.rectangle((240,45,272,467),fill=CHALK);d.rectangle((45,235,467,267),fill=CHALK)
 d.ellipse((109,96,157,144),fill=RED);plan.save(S/'ClassroomPlan.png');save(plan,'GARVEY_Map.dds',(512,512))
 board=Image.new('RGBA',(768,640),GREEN);d=ImageDraw.Draw(board)
 d.rectangle((4,4,763,635),outline=GOLD,width=8)
 for y in range(190,620,90):d.line((20,y,748,y),fill='#24513e',width=2)
 board.save(S/'Board.png');save(board,'GARVEY_Board.dds',(768,640))
 (V/'GARVEY_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="GARVEY_Leader.dds" />\n',encoding='utf-8',newline='\n')
 preview=Image.new('RGBA',(1024,256),GREEN)
 for i,im in enumerate([masters['Icon'],masters['Portrait'],symbol('monitor'),symbol('office')]):preview.paste(ImageOps.fit(im,(256,256),Image.Resampling.LANCZOS),(i*256,0))
 preview.convert('RGB').save(S/'Preview.png')
 print('Compiled 41 Classroom DDS textures with mipmaps and original source masters')

if __name__=='__main__':main()
