"""Validate every themed interface and execute the shipped screen-recovery contract."""
from pathlib import Path
import json, math, re, struct, sys
from xml.etree import ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/python'))

def run(root=ROOT):
 from PIL import Image
 from lupa.lua51 import LuaRuntime
 records=json.loads((root/'docs/UIRefreshInventory.json').read_text(encoding='utf-8'))
 module='CWC2_Screen' if root.name.endswith('2') else 'CWC_Screen'
 helper=root/'Shared/UI'/(module+'.lua')
 source=helper.read_text(encoding='utf-8')
 assert ':SetUpdate(' not in source and ':ClearUpdate(' not in source,'UI helper owns a gameplay dispatcher'
 lua=LuaRuntime();compile_lua=lua.eval('function(s,n)local f,e=loadstring(s,n);assert(f,e)end')
 total=0
 for record in records:
  for name in record['xml']:
   path=root/name;tree=ET.parse(path).getroot()
   ids=[e.get('ID') for e in tree.iter() if e.get('ID')]
   assert len(ids)==len(set(ids)),(name,'duplicate control ID')
   code=path.with_suffix('.lua').read_text(encoding='utf-8-sig')
   compile_lua(code,name)
   assert module+'.New{' in code and 'uiRecovery:Sync()' in code,(name,'missing recovery integration')
   # Execute the shipped input callback with the native screen gate closed.
   # It must yield before touching its local panel state or consuming Escape.
   for callback in re.findall(r'ContextPtr:SetInputHandler\((function\(.*?\bend)\)',code,re.S):
    handler=lua.execute('local uiRecovery={Available=function()return false end};return '+callback)
    assert handler(1,27) is False,(name,'input handler consumes a hidden screen')
   for control in re.findall(r'Controls\.([A-Za-z0-9_]+)',code):assert control in ids,(name,control)
   for scroll in tree.iter('ScrollPanel'):assert scroll.find('ScrollBar') is not None,(name,'missing scrollbar')
   for e in tree.iter('Image'):
    if not e.get('Texture','').startswith(record['prefix']):continue
    path=root/record['civilization']/'Art'/e.get('Texture')
    with Image.open(path) as image:assert image.size==tuple(map(int,e.get('Size').split(','))),(name,e.get('Texture'),'native pixel cropping')
  for filename,size in record['textures'].items():
   path=root/record['civilization']/'Art'/filename
   expected=b'DXT5' if size[0]%4==0 and size[1]%4==0 else b'\0\0\0\0'
   header=path.read_bytes()[:128];assert header[84:88]==expected,path
   assert struct.unpack_from('<I',header,28)[0]==int(math.log2(max(size)))+1,path
   with Image.open(path) as image:image.load();assert image.size==tuple(size),path
   total+=1
 lua.execute(source);lua.globals().UI_SCREEN=lua.globals()[module]
 lua.execute((root/'tools/tests/ui_recovery_contract.lua').read_text(encoding='utf-8'))
 print(f'PASS {len(records)} themed interfaces: {total} decoded textures, native control wiring, scrollbars and Lua 5.1 recovery')

if __name__=='__main__':run()
