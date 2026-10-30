"""Render actual Jin XML/shipped Lua state with modeled font metrics, not Civ V."""
from pathlib import Path
import re
from xml.etree import ElementTree as ET
from PIL import Image,ImageDraw,ImageFont
from validate_jin import database,apply,make_runtime,R,V

S=R/'art-source/JinDynasty/VisualRefresh'
ROOT=ET.parse(V/'UI/JIN_Dynasty.xml').getroot()
def pair(word,default=(0,0)):return tuple(map(int,word.split(','))) if word else default
def font(name):
 size=int(re.search(r'(\d+)$',name or '16')[1])
 return ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',size)
def color(word):return tuple(map(int,(word or '241,225,196,255').split(',')))
def nine(size,disabled):
 tile=Image.open(V/'Art/JIN_UI_Buttons.dds').convert('RGBA').crop((0,135 if disabled else 0,44,179 if disabled else 44))
 im=Image.new('RGBA',size);xs=[0,8,36,44];ys=xs
 ox=[0,8,size[0]-8,size[0]];oy=[0,8,size[1]-8,size[1]]
 for y in range(3):
  for x in range(3):im.alpha_composite(tile.crop((xs[x],ys[y],xs[x+1],ys[y+1])).resize((ox[x+1]-ox[x],oy[y+1]-oy[y])),(ox[x],oy[y]))
 return im
def render(lua,viewport):
 controls=lua.globals().Controls;rows=lua.globals().uiManager.rows
 canvas=Image.new('RGBA',viewport,'#16151a')
 def draw(node,im,origin,parent_size,bindings=controls,flow=None):
  tag=node.tag;id=node.get('ID');c=bindings[id] if id else None
  hidden=c.hidden if c is not None else None
  if hidden is True or (hidden is None and node.get('Hidden')=='1'):return
  w,h=pair(node.get('Size'));dx,dy=pair(node.get('Offset'));anchor=node.get('Anchor','L,T').split(',')
  x=origin[0]+(parent_size[0]-dx-w if anchor[0]=='R' else (parent_size[0]-w)//2+dx if anchor[0]=='C' else dx)
  y=origin[1]+(parent_size[1]-dy-h if anchor[1]=='B' else (parent_size[1]-h)//2+dy if anchor[1]=='C' else dy)
  if flow is not None:x,y=flow
  if tag=='Image':
   icon=c.icon if c is not None else None
   if icon is not None:
    atlases={'JIN_UNIT_ATLAS':('Units',4),'JIN_BUILDING_ATLAS':('Buildings',5),'JIN_UPGRADE_ATLAS':('Upgrades',4),'JIN_CIV_ATLAS':('Icon',1)}
    stem=atlases.get(icon.atlas,('Icon',1));i=icon.index if icon.atlas in atlases else 0
    # Packed vanilla portraits use a crest placeholder in this modeled preview.
    art=Image.open(V/'Art'/f'JIN_{stem[0]}64.dds').convert('RGBA');art=art.crop(((i%stem[1])*64,(i//stem[1])*64,(i%stem[1]+1)*64,(i//stem[1]+1)*64))
   else:art=Image.open(V/'Art'/node.get('Texture')).convert('RGBA')
   im.alpha_composite(art.resize((w,h)),(x,y));return
  if tag=='GridButton':im.alpha_composite(nine((w,h),c is not None and c.disabled is True),(x,y))
  if tag in ['Label','GridButton']:
   text=c.text if c is not None and c.text is not None else node.get('String','')
   text=re.sub(r'\[ICON_[^]]+\]','',text).replace('[NEWLINE]','\n');f=font(node.get('Font'));d=ImageDraw.Draw(im)
   width=int(node.get('WrapWidth') or w or parent_size[0]);lines=[]
   for paragraph in text.split('\n'):
    line=''
    for word in paragraph.split():
     test=(line+' '+word).strip()
     if line and d.textlength(test,font=f)>width:lines.append(line);line=word
     else:line=test
    lines.append(line)
   spacing=f.size+2
   for n,line in enumerate(lines):
    tx=x;ty=y+n*spacing
    if tag=='GridButton':tx=x+(w-d.textlength(line,font=f))/2;ty=y+(h-spacing)/2+n*spacing
    if node.get('Align')=='Center':tx=x+(w-d.textlength(line,font=f))/2
    d.text((tx+1,ty+1),line,font=f,fill=(0,0,0,200));d.text((tx,ty),line,font=f,fill=(115,109,104,255) if c is not None and c.disabled is True else color(node.get('Color0')))
  if tag=='ScrollPanel':
   crop=Image.new('RGBA',(w,h));rowxml=ROOT.find('Instance/Grid');cy=0
   for index in range(1,len(rows)+1):
    draw(rowxml,crop,(0,0),(w,h),rows[index],(0,cy));cy+=100
   im.alpha_composite(crop,(x,y));return
  cursor=0
  for child in node:
   if child.tag=='GridData':continue
   child_flow=None
   if tag=='Stack':
    child_flow=(x+cursor,y) if node.get('StackGrowth')=='Right' else (x,y+cursor)
    cw,ch=pair(child.get('Size'));cursor+=(cw if node.get('StackGrowth')=='Right' else ch)+int(node.get('Padding',0))
   draw(child,im,(x,y),(w or parent_size[0],h or parent_size[1]),bindings,child_flow)
 for child in ROOT:
  if child.tag!='Instance':draw(child,canvas,(0,0),viewport)
 ImageDraw.Draw(canvas).text((8,2),'LAYOUT PREVIEW / MODELED FONTS / NOT A NATIVE GAME SCREENSHOT',font=font('14'),fill='#bba981')
 return canvas
def main():
 d=database();apply(d);lua,_=make_runtime(d)
 lua.execute("Complete('GREAT_PASTURE');Complete('DRAGON_PAVILION');Complete('GREAT_WALL_BASTION');local j=MapModData.JIN;local s=j.State(0);for i=1,3 do local c=j.Candidates(0,s,i);Action('SITE',i,c[1]);s=j.State(0)end;for _,g in pairs(s.grass)do g.horses=5 end;j.Save(0,s);for t in GameInfo.Technologies()do Learn(t.Type)end")
 lua.globals().LoadJinUI();lua.execute('Controls.Open.callback()')
 for tab in ['Overview','Landmarks','Recruit','Emissaries','Upgrades','Defense']:
  lua.execute('Controls.'+tab+'Tab.callback()')
  render(lua,(1280,720)).convert('RGB').save(S/f'UI-{tab}-1280.png')
  if tab=='Landmarks':render(lua,(1920,1080)).convert('RGB').save(S/'UI-Landmarks-1920.png')
 print('Rendered six shipped-Lua/XML panel previews at 1280x720, plus 1920x1080; native rendering remains pending')
if __name__=='__main__':main()
