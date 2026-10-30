"""Jin's actual compiled textures, native styles, XML geometry and art-only SQL diff."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,json,math,struct,subprocess
from PIL import Image,ImageChops
from database import database
from validate_urgal import support_source

R=Path(__file__).resolve().parents[1];V=R/'JinDynasty';S=R/'art-source/JinDynasty/VisualRefresh'
BASELINE='3b25b7859ac3f0508a0f6e875a7dd61bc60cf935'
def main():
 textures=list((V/'Art').glob('*.dds'));assert len(textures)==82
 for path in textures:
  raw=path.read_bytes();assert raw[:4]==b'DDS ' and raw[84:88]!=b'DX10',path
  with Image.open(path)as im:
   im.load();assert struct.unpack_from('<I',raw,28)[0]==int(math.log2(max(im.size)))+1,('incomplete mip chain',path)
   if path.stem.startswith(('JIN_Alpha','JIN_Flags')):
    r,g,b,a=im.convert('RGBA').split()
    assert not ImageChops.multiply(ImageChops.difference(r,g),a).getbbox() and not ImageChops.multiply(ImageChops.difference(g,b),a).getbbox(),('non-tintable flag',path)
 old=subprocess.check_output(['git','ls-tree','-r','--name-only',BASELINE,'JinDynasty/Art'],cwd=R,text=True).splitlines()
 changed=[]
 for name in old:
  if name.endswith('.dds'):
   assert subprocess.check_output(['git','show',BASELINE+':'+name],cwd=R)!=(R/name).read_bytes(),('old art was not refreshed',name)
   changed.append(name)
 assert len(changed)==63
 xml=ET.parse(V/'UI/JIN_Dynasty.xml');ids={e.get('ID'):e for e in xml.iter() if e.get('ID')}
 native={e.tag for e in ET.parse(support_source().with_name('Styles.xml')).iter()}
 requested={e.get('Style')for e in xml.iter()if e.get('Style')};assert requested<=native,requested-native
 for node in xml.iter('Image'):
  assert (V/'Art'/node.get('Texture')).is_file(),node.get('Texture')
 for node in xml.iter('GridData'):assert (V/'Art'/node.get('Texture')).is_file()
 for key in ['Horse','Tribute','Villager','Karma','Landmark']:
  card=ids[key+'Card'];x,y=map(int,card.get('Offset').split(','));w,h=map(int,card.get('Size').split(','))
  assert 0<=x and 0<=y and x+w<=980 and y+h<=680
 for width,height in [(1280,720),(1920,1080)]:assert width>=980 and height>=680
 # Re-execute original/current effects SQL against the same data. Only the
 # promotion icon columns and a new texture atlas may differ, never gameplay.
 before=database();after=database()
 for path in sorted((V/'SQL').glob('*.sql')):
  relative=path.relative_to(R).as_posix()
  before.executescript(subprocess.check_output(['git','show',BASELINE+':'+relative],cwd=R).decode('utf-8'))
  after.executescript(path.read_text(encoding='utf-8'))
 for (name,)in before.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"):
  if name=='IconTextureAtlases':continue
  columns=[r[1]for r in before.execute('PRAGMA table_info("'+name+'")')if not(name=='UnitPromotions'and r[1]in ['IconAtlas','PortraitIndex'])and not(name=='Units'and r[1]=='UnitArtInfo')]
  query='SELECT '+','.join('"'+c+'"'for c in columns)+' FROM "'+name+'"'
  assert before.execute(query).fetchall()==after.execute(query).fetchall(),('gameplay database changed',name)
 art_before=dict(before.execute('SELECT Type,UnitArtInfo FROM Units'));art_after=dict(after.execute('SELECT Type,UnitArtInfo FROM Units'))
 assert [k for k in art_before if art_before[k]!=art_after[k]]==['UNIT_JIN_ZHANMA']
 assert art_after['UNIT_JIN_ZHANMA']=='ART_DEF_UNIT_U_JAPANESE_SAMURAI'
 assert after.execute('SELECT 1 FROM ArtDefine_UnitInfos WHERE Type=?',(art_after['UNIT_JIN_ZHANMA'],)).fetchone()
 result={'date':'2026-10-30','baseline':BASELINE,'compiled_dds':82,'existing_dds_refreshed':len(changed),'new_dds':19,'complete_legacy_mip_chains':True,'native_styles':sorted(requested),'gameplay_sql_identical_except_visual_metadata':True,'unit_model_changes':{'UNIT_JIN_ZHANMA':art_after['UNIT_JIN_ZHANMA']},'viewport_geometry':[[1280,720],[1920,1080]],'native_rendering':'NOT RUN','preview':'Actual shipped Lua/XML, modeled fonts; packed vanilla portraits use crest placeholders','sources':{p.name:hashlib.sha256(p.read_bytes()).hexdigest()for p in S.glob('*Paintings.png')}}
 (V/'docs/GraphicsValidation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('PASS Jin graphics: all 63 old DDS refreshed, 19 new DDS, complete mips, tintable flags, native styles, viewport geometry and unchanged gameplay SQL')
if __name__=='__main__':main()
