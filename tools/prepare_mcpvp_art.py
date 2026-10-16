"""Original geometric lobby art and symbols. No external textures or artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1]
V=R/'McPvP/Art';S=R/'art-source/McPvP'
SIZES=[16,24,32,45,48,64,80,128,256]
INK='#142b26';GOLD='#dfbd69';WHITE='#edf2da';GREEN='#54b66b'

def badge(kind,alpha=False):
 im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
 if not alpha:d.ellipse((8,8,248,248),fill=INK,outline=GOLD,width=7)
 c=WHITE
 if kind in ['CIV','VETERAN']:
  d.polygon([(63,57),(188,182),(177,201),(50,75)],fill=c)
  d.polygon([(193,57),(68,182),(79,201),(206,75)],fill=c)
  d.polygon([(128,60),(163,82),(163,124),(128,146),(93,124),(93,82)],fill=c if alpha else GREEN)
 elif kind=='HUB':
  for x in [61,102,143]:
   for y in [71,111,151]:d.rectangle((x,y,x+35,y+30),fill=c)
  d.rectangle((51,190,203,202),fill=c)
 elif kind=='PORTRAIT':
  d.rectangle((75,57,181,147),fill='#b98a63');d.rectangle((75,49,181,81),fill='#544637')
  d.rectangle((93,94,111,108),fill=WHITE);d.rectangle((145,94,163,108),fill=WHITE)
  d.rectangle((49,153,207,213),fill=GREEN);d.rectangle((113,151,143,213),fill=GOLD)
 elif kind=='GRACE':
  d.polygon([(63,62),(193,62),(187,154),(128,211),(69,154)],fill=c)
 elif kind in ['FINAL','THOR']:
  d.polygon([(141,43),(67,137),(119,137),(99,214),(198,107),(142,107)],fill=GOLD)
 elif kind=='FLAG':
  d.rectangle((68,48,79,213),fill=c);d.polygon([(80,51),(199,76),(80,121)],fill=GREEN)
 elif kind in ['POISON','VIPER']:
  d.line([(70,178),(182,178),(182,125),(80,125),(80,76),(163,76)],fill=GREEN,width=24)
  d.polygon([(152,51),(202,76),(152,100)],fill=c)
 elif kind=='MEMORY':
  d.polygon([(57,91),(89,61),(128,93),(167,61),(199,91),(199,127),(128,201),(57,127)],fill=GOLD)
 elif kind=='KANGAROO':
  d.line([(51,185),(101,185),(119,126),(151,126),(169,69),(199,69)],fill=c,width=19)
 elif kind=='STOMPER':
  d.polygon([(39,192),(128,66),(217,192)],fill=c);d.rectangle((111,70,146,143),fill=GOLD)
 elif kind=='ENDERMAGE':
  d.ellipse((58,59,198,199),outline='#b99cda',width=19);d.line((78,128,178,128),fill=c,width=14)
  d.polygon([(74,128),(106,100),(106,156)],fill=c)
 return im

def scene():
 im=Image.new('RGB',(1024,768),'#142c30');d=ImageDraw.Draw(im)
 for y in range(768):d.line((0,y,1024,y),fill=(18+y//24,39+y//22,43+y//25))
 for i in range(48):
  x=(i*181+63)%1024;y=(i*73+19)%330;d.rectangle((x,y,x+2,y+2),fill=GOLD)
 d.ellipse((738,72,848,182),fill='#d9e0bf')
 # Isometric arena and a softly lit spawn hall.
 d.polygon([(80,508),(512,302),(946,508),(512,733)],fill='#344a37')
 d.polygon([(80,508),(512,733),(512,762),(80,535)],fill='#25382c')
 for n in range(1,9):
  t=n/9;d.line((80+432*t,508-206*t,512+434*t,733-225*t),fill='#50654c',width=2)
  d.line((80+432*t,508+225*t,512+434*t,302+206*t),fill='#50654c',width=2)
 d.rectangle((278,280,742,490),fill='#826d4c');d.rectangle((254,249,766,285),fill='#567f43')
 for x in [290,390,610,710]:d.rectangle((x,294,x+22,482),fill='#b89b62')
 d.rectangle((435,306,589,480),fill='#142b26');d.rectangle((448,318,576,468),outline=GOLD,width=5)
 for x,y in [(239,487),(714,508),(358,568),(567,586),(641,455)]:
  d.rectangle((x-14,y-60,x+14,y-34),fill='#ba9468');d.rectangle((x-19,y-32,x+19,y+10),fill=GREEN)
  d.rectangle((x-17,y+11,x-3,y+37),fill='#314c64');d.rectangle((x+3,y+11,x+17,y+37),fill='#314c64')
 fontpath=Path('C:/Windows/Fonts/consolab.ttf')
 font=ImageFont.truetype(str(fontpath),42) if fontpath.exists() else ImageFont.load_default()
 small=ImageFont.truetype(str(fontpath),22) if fontpath.exists() else ImageFont.load_default()
 d.text((512,194),'McPvP',anchor='mm',font=font,fill=GOLD)
 d.text((512,230),'THE ENDLESS LOBBY',anchor='mm',font=small,fill=WHITE)
 d.text((512,704),'The match ends. The memories don\'t.',anchor='mm',font=small,fill=WHITE)
 return im

def main():
 V.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
 groups={'Icon':['CIV'],'Alpha':['CIV'],'Portrait':['PORTRAIT'],'Objects':['VETERAN','HUB'],
         'Promotions':['VETERAN','GRACE','FINAL','FLAG','POISON','MEMORY','KANGAROO','STOMPER','ENDERMAGE','THOR','VIPER']}
 for stem,kinds in groups.items():
  master=Image.new('RGBA',(256*len(kinds),256))
  for i,kind in enumerate(kinds):master.alpha_composite(badge(kind,stem=='Alpha'),(256*i,0))
  master.save(S/(stem+'.png'))
  for size in SIZES:(V/f'MCP_{stem}{size}.dds').write_bytes(raw_mips(master.resize((size*len(kinds),size),Image.Resampling.LANCZOS)))
 painting=scene();painting.save(S/'Lobby.png')
 for name,im in [('Leader',painting),('Dawn',painting),('Map',painting.resize((512,384),Image.Resampling.LANCZOS))]: (V/f'MCP_{name}.dds').write_bytes(raw_mips(im))
 (V/'MCP_LeaderScene.xml').write_text('<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="MCP_Leader.dds" />\n',encoding='utf-8',newline='\n')
 print('Generated 48 DDS assets and static scene from original geometric art')

if __name__=='__main__':main()
