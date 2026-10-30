"""Compile all refreshed Jin 2D art; changes no other civilization's textures.

Generated paintings are immutable inputs. Cropping, atlas layout, native framing,
UI material drawing and DDS encoding are deterministic project asset compilation.
"""
from pathlib import Path
import math,random
from PIL import Image,ImageDraw,ImageOps,ImageChops
from prepare_red_art import raw_mips
from prepare_jin_art import symbol,SIZES
from standardize_icons import frame_cell

R=Path(__file__).resolve().parents[1];S=R/'art-source/JinDynasty/VisualRefresh';V=R/'JinDynasty/Art'
UNITS=['worker','iron','mohe','bed','zhanma','eruptor','grenadier','defender','emissary','trader','bees','trebuchet']
GOLD='#d9b36b';CREAM='#f7e3bb'
def save(name,im):
 im.convert('RGBA').save(S/(name+'.png'));(V/(name+'.dds')).write_bytes(raw_mips(im))
def material(size,top=(52,21,27),bottom=(19,14,20),seed=19):
 im=Image.new('RGBA',size);rng=random.Random(seed);pixels=im.load()
 for y in range(size[1]):
  t=y/max(1,size[1]-1);base=[round(a+(b-a)*t) for a,b in zip(top,bottom)]
  for x in range(size[0]):
   grain=rng.choice((-1,0,0,0,1));pixels[x,y]=tuple(max(0,min(255,c+grain))for c in base)+(255,)
 return im
def edge(im,bright=False):
 d=ImageDraw.Draw(im);w,h=im.size
 for n,color in [(0,'#0c080d'),(1,GOLD if bright else '#776043'),(2,'#2b161e'),(5,'#594031')]:d.rectangle((n,n,w-n-1,h-n-1),outline=color)
 return im
def glyph(kind):
 # Crisp native tintable symbols: redraw the code-native insignia at 4x size.
 if kind=='civ':
  im=Image.new('RGBA',(1024,1024));d=ImageDraw.Draw(im)
  # Original seal-style rendering of 金 (Jin / gold), drawn as eight strokes.
  # No font dependency, animal portrait or borrowed game logo.
  strokes=[[(128,37),(103,70),(54,105)],[(128,37),(155,72),(202,105)],
   [(90,103),(166,103)],[(73,139),(183,139)],[(128,105),(128,216)],
   [(81,160),(96,188)],[(176,160),(160,188)],[(62,216),(194,216)]]
  for points in strokes:d.line([(x*4,y*4)for x,y in points],fill='white',width=13*4,joint='curve')
  return im
 im=symbol(kind,True,scale=4)
 if kind=='trader':
  d=ImageDraw.Draw(im);d.line([(760,210),(768,105),(720,50)],fill='white',width=18)
  d.line([(768,125),(825,65),(816,30)],fill='white',width=14)
 return im
def crest(kind):
 im=material((512,512),(103,28,37),(24,12,21));d=ImageDraw.Draw(im)
 for inset,color,width in [(14,'#452817',10),(20,GOLD,5),(29,'#f4df9f',3),(38,'#6b4a2c',3)]:d.ellipse((inset,inset,511-inset,511-inset),outline=color,width=width)
 # Deterministic radial engraving and a pale-gold silhouette, never baked text.
 for n in range(48):
  a=n*math.tau/48;d.line((256+214*math.cos(a),256+214*math.sin(a),256+223*math.cos(a),256+223*math.sin(a)),fill='#a78348',width=2)
 mask=ImageOps.fit(glyph(kind).getchannel('A'),(420,420),Image.Resampling.LANCZOS)
 metal=material((420,420),(255,237,185),(169,113,49));metal.putalpha(mask)
 im.alpha_composite(metal,(46,46));return im
def cells(filename,cols,rows):
 source=Image.open(S/filename).convert('RGBA');out=[]
 for y in range(rows):
  for x in range(cols):
   box=(round(x*source.width/cols),round(y*source.height/rows),round((x+1)*source.width/cols),round((y+1)*source.height/rows))
   out.append(ImageOps.fit(source.crop(box),(256,256),Image.Resampling.LANCZOS))
 return out
def atlas(stem,images,cols,rows,leader=False,monochrome=False):
 master=Image.new('RGBA',(cols*256,rows*256))
 for i,im in enumerate(images):master.alpha_composite(im.resize((256,256),Image.Resampling.LANCZOS),((i%cols)*256,(i//cols)*256))
 master.save(S/(stem+'Master.png'))
 if not monochrome:
  (R/'art-source/IconAtlasMasters').mkdir(exist_ok=True)
  master.save(R/'art-source/IconAtlasMasters'/('JIN_'+stem+'256.png'))
 for size in SIZES:
  out=Image.new('RGBA',(cols*size,rows*size))
  for i,im in enumerate(images):
   cell=im.resize((size,size),Image.Resampling.LANCZOS) if monochrome else frame_cell(im,size,leader)
   out.alpha_composite(cell,((i%cols)*size,(i//cols)*size))
  (V/f'JIN_{stem}{size}.dds').write_bytes(raw_mips(out))
 return master
def ui(leader):
 panel=edge(material((980,680)),True);d=ImageDraw.Draw(panel)
 d.rectangle((20,318,959,602),fill='#130e15',outline='#68513a');d.rectangle((21,608,958,662),fill='#26151c',outline='#594031')
 for x,sx in [(10,1),(969,-1)]:
  for y,sy in [(10,1),(669,-1)]:
   d.line([(x,y+sy*25),(x,y),(x+sx*25,y)],fill=GOLD,width=2)
   d.line([(x+sx*5,y+sy*18),(x+sx*5,y+sy*5),(x+sx*18,y+sy*5)],fill='#84613c')
 for x in range(34,950,56):
  for y in [132,228,282]:d.polygon([(x,y),(x+3,y-2),(x+6,y),(x+3,y+2)],fill='#765039')
 save('JIN_UI_Panel',panel)
 header=ImageOps.fit(leader,(964,220),Image.Resampling.LANCZOS,centering=(.65,.42)).crop((0,18,964,142))
 shade=Image.new('RGBA',header.size);sd=ImageDraw.Draw(shade)
 for x in range(964):sd.line((x,0,x,123),fill=(27,10,18,round(215-115*x/963)))
 header.alpha_composite(shade);save('JIN_Header',header)
 row=edge(material((910,86),(48,24,30),(25,17,23)));d=ImageDraw.Draw(row);d.line((728,10,728,75),fill='#604431');save('JIN_UI_Row',row)
 save('JIN_UI_Metric',edge(material((180,80),(57,27,33),(24,16,23))))
 save('JIN_UI_Accent',Image.new('RGBA',(120,3),GOLD))
 buttons=Image.new('RGBA',(64,256))
 for n,(top,bottom) in enumerate([((80,31,39),(38,16,24)),((121,55,57),(64,27,35)),((32,15,22),(77,35,41)),((38,31,33),(26,22,27))]):
  tile=edge(material((44,44),top,bottom,n),n==1);buttons.alpha_composite(tile,(0,n*45))
 save('JIN_UI_Buttons',buttons)
def main():
 S.mkdir(parents=True,exist_ok=True);V.mkdir(exist_ok=True)
 leader=Image.open(S/'Leader.png').convert('RGBA');w,h=leader.size
 portrait=ImageOps.fit(leader.crop((int(w*.07),int(h*.03),int(w*.36),int(h*.62))),(256,256),Image.Resampling.LANCZOS)
 masters={'Icon':atlas('Icon',[crest('civ')],1,1),'Alpha':atlas('Alpha',[glyph('civ')],1,1,monochrome=True),
  'Portrait':atlas('Portrait',[portrait],1,1,leader=True),'Units':atlas('Units',cells('UnitPaintings.png',4,3),4,3),
  'Buildings':atlas('Buildings',cells('BuildingPaintings.png',5,2),5,2),'Flags':atlas('Flags',[glyph(k)for k in UNITS],4,3,monochrome=True),
  'Upgrades':atlas('Upgrades',cells('UpgradePaintings.png',4,4),4,4)}
 for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768))]:save('JIN_'+stem,ImageOps.fit(leader,size,Image.Resampling.LANCZOS,centering=(.4,.5)))
 save('JIN_Map',ImageOps.fit(Image.open(S/'Map.png').convert('RGBA'),(512,512),Image.Resampling.LANCZOS))
 for name,kind in [('Grassland','grassland'),('Horse','horse'),('Tributary','emissary'),('Karma','karma'),('Mengan','defender')]:
  art=crest(kind)
  for size in [32,64]:save(f'JIN_{name}UI{size}',frame_cell(art,size))
 ui(leader)
 from generate_jin_ui import main as layout
 layout()
 board=Image.new('RGBA',(1536,1568),'#160e16');board.alpha_composite(ImageOps.fit(leader,(1536,864)),(0,0))
 board.alpha_composite(masters['Units'].resize((768,576)),(0,872));board.alpha_composite(masters['Buildings'].resize((768,307)),(768,872))
 board.alpha_composite(masters['Upgrades'].resize((384,384)),(768,1184));board.alpha_composite(Image.open(V/'JIN_Map.dds').resize((384,384)),(1152,1184))
 flags=Image.open(V/'JIN_Flags64.dds').convert('RGBA')
 for i in range(12):board.alpha_composite(flags.crop(((i%4)*64,(i//4)*64,(i%4+1)*64,(i//4+1)*64)),(i*64,1476))
 board.convert('RGB').save(S/'ArtOverview.jpg',quality=94)
 print('Compiled full Jin visual set:',len(list(V.glob('*.dds'))),'DDS files; no other civ art touched')
if __name__=='__main__':main()
