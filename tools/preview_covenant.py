"""Render shipped Covenant Lua/XML and compiled textures with modeled fonts.

These previews are not screenshots of the native game. No game data is changed.
"""
from pathlib import Path
import re
from xml.etree import ElementTree as ET
from PIL import Image, ImageDraw, ImageFont
from validate_covenant import ui_runtime

R=Path(__file__).resolve().parents[1]
V=R/'TheCovenant/Art';S=R/'art-source/TheCovenant'
XML=ET.parse(R/'TheCovenant/UI/CovenantGate.xml').getroot()

def font(size):return ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',size)
def pair(value):return tuple(map(int,value.split(',')))

def wrap(text,width,f):
    output=[]
    for paragraph in text.replace('[NEWLINE]','\n').split('\n'):
        current=''
        for word in paragraph.split():
            candidate=(current+' '+word).strip()
            if current and f.getlength(candidate)>width:output.append(current);current=word
            else:current=candidate
        output.append(current)
    return output

def button(size,disabled):
    source=Image.open(V/'COVENANT_UI_Buttons.dds').convert('RGBA')
    tile=source.crop((0,135 if disabled else 0,44,179 if disabled else 44))
    output=Image.new('RGBA',size);xs=ys=(0,8,36,44)
    ox=(0,8,size[0]-8,size[0]);oy=(0,8,size[1]-8,size[1])
    for y in range(3):
        for x in range(3):
            output.alpha_composite(tile.crop((xs[x],ys[y],xs[x+1],ys[y+1])).resize((ox[x+1]-ox[x],oy[y+1]-oy[y])),(ox[x],oy[y]))
    return output

def render(lua,name):
    canvas=Image.new('RGBA',(1024,768),(5,10,20,255));controls=lua.globals().Controls
    def draw(node,origin,parent,inherited=18,disabled=False):
        if node.tag=='GridData':return
        c=controls[node.get('ID')] if node.get('ID') else None
        if (c is not None and c.hidden) or (c is None and node.get('Hidden')=='1'):return
        fs=int(re.search(r'\d+$',node.get('Font'))[0]) if node.get('Font') else inherited
        f=font(fs);text=(c.text if c is not None and c.text else node.get('String',''))
        lines=wrap(text,int(node.get('WrapWidth') or parent[0]),f)
        w,h=parent if node.get('Size')=='Full,Full' else pair(node.get('Size','0,0'))
        if node.tag=='Label':w,h=round(max(map(f.getlength,lines),default=0)),fs+(len(lines)-1)*(fs+2)
        dx,dy=pair(node.get('Offset','0,0'))
        if c is not None and c.x is not None:dx=int(c.x)
        ax,ay=node.get('Anchor','L,T').split(',')
        x=origin[0]+(parent[0]-dx-w if ax=='R' else (parent[0]-w)//2+dx if ax=='C' else dx)
        y=origin[1]+(parent[1]-dy-h if ay=='B' else (parent[1]-h)//2+dy if ay=='C' else dy)
        disabled=disabled or (bool(c.disabled) if c is not None else False)
        d=ImageDraw.Draw(canvas)
        if node.tag=='Box':d.rectangle((x,y,x+w-1,y+h-1),fill=pair(node.get('Color')))
        if node.tag=='Image':
            image=Image.open(V/node.get('Texture')).convert('RGBA')
            assert image.size==(w,h),'Image must use its actual texture size'
            canvas.alpha_composite(image,(x,y))
        if node.tag=='GridButton':canvas.alpha_composite(button((w,h),disabled),(x,y))
        if node.tag in ('Label','EditBox'):
            color=pair(node.get('Color0')) if node.get('Color0') else (239,230,207,255)
            if disabled:color=(139,136,125,255)
            if node.tag=='EditBox':lines=[text]
            for i,line in enumerate(lines):
                pos=(x,y+i*(fs+2));d.text((pos[0]+1,pos[1]+1),line,font=f,fill=(0,0,0,200));d.text(pos,line,font=f,fill=color)
            if node.tag=='EditBox' and c.focused:
                cx=x+f.getlength(text);d.line((cx,y+4,cx,y+fs+2),fill='#e7c985',width=1)
        for child in node:draw(child,(x,y),(w or parent[0],h or parent[1]),fs,disabled)
    for node in XML:draw(node,(0,0),canvas.size)
    ImageDraw.Draw(canvas).text((18,743),'SOURCE PREVIEW | Compiled Covenant DDS + shipped Lua/XML | Modeled fonts; not a native game screenshot',font=font(12),fill='#9ca9b7')
    canvas.convert('RGB').save(S/name)

def main():
    lua=ui_runtime();lua.execute('Events.LoadScreenClose.fire()');render(lua,'UI-Study.png')
    lua.execute("tick(60);click('Submit');typeText('Revelation 3:17-18')");render(lua,'UI-Reference.png')
    lua.execute("click('Submit');typeText('You say,')");render(lua,'UI-Recall.png')
    print('Rendered Study, Reference and Recall from actual Lua/XML/DDS; native rendering NOT RUN')

if __name__=='__main__':main()
