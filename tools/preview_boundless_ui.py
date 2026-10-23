"""Compose a labelled layout preview from shipped textures and XML geometry.

Uses sample data and Windows fonts, not Civ V's native font/markup renderer.
"""
from pathlib import Path
from xml.etree import ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

R=Path(__file__).resolve().parents[1]
V=R/'TheBoundlessCity'; S=R/'art-source/TheBoundlessCity/WorkforceUI'
GOLD='#e3c483'; WHITE='#eadfc8'; MUTED='#aaa88f'; GREEN='#8fd3b5'


def font(size):
    candidates=[Path('C:/Windows/Fonts/segoeui.ttf'),Path('C:/Windows/Fonts/arial.ttf')]
    return ImageFont.truetype(str(next(p for p in candidates if p.exists())),size)


def wrap(text,width,f):
    lines=[];line=''
    for word in text.split():
        candidate=(line+' '+word).strip()
        if line and f.getlength(candidate)>width:lines.append(line);line=word
        else:line=candidate
    return lines+[line]


def button(size,state=0):
    tile=Image.open(V/'Art/BC_UI_Buttons.dds').convert('RGBA').crop((0,state*45,44,state*45+44))
    out=Image.new('RGBA',size);w,h=size
    for sy,ey,dy,dh in [(0,8,0,8),(8,36,8,h-16),(36,44,h-8,8)]:
        for sx,ex,dx,dw in [(0,8,0,8),(8,36,8,w-16),(36,44,w-8,8)]:
            out.paste(tile.crop((sx,sy,ex,ey)).resize((dw,dh),Image.Resampling.LANCZOS),(dx,dy))
    return out


def main():
    root=ET.parse(V/'UI/BoundlessWorkforce.xml').getroot()
    ids={n.get('ID'):n for n in root.iter() if n.get('ID')}
    panel=Image.open(V/'Art/BC_UI_Panel.dds').convert('RGBA');d=ImageDraw.Draw(panel)
    panel.alpha_composite(Image.open(V/'Art/BoundlessIcon64.dds').convert('RGBA'),(18,18))
    d.text((92,22),'The Boundless Workforce',font=font(24),fill='#f3e0b4')
    d.text((92,55),'The Heart of the World',font=font(16),fill=GOLD)
    def draw_button(name,text,state=0):
        n=ids[name];w,h=map(int,n.get('Size').split(','));x,y=map(int,n.get('Offset','0,0').split(','))
        if n.get('Anchor','L,T').startswith('R,'):x=900-x-w
        panel.alpha_composite(button((w,h),state),(x,y))
        f=font(15);d.text((x+(w-f.getlength(text))/2,y+(h-20)/2),text,font=f,fill=WHITE if state!=3 else MUTED)
    for name,text in [('Close','X'),('Siege','Siege demolition'),('Mode','Hybrid'),('Priority','Food'),('Direction','Direction: Any'),('Sort','Distance'),('Previous','Previous'),('Next','Next')]:draw_button(name,text,3 if name=='Previous' else 0)
    columns=[('TerritoryStack',['Territory','Population: 34','Owned Plots: 146','Frontier Culture: 62','Next frontier claim: 84 Culture']),
             ('WorkforceStack',['Workforce','Local Workers: 18','Remote Workers: 10','Specialists: 6','Idle Labourers: 0','Unassigned Citizens: 0']),
             ('ManagementStack',['Management','Available Citizens: 28','Additional Remote Capacity: 18','Maximum Remote Capacity: 28','Pending Requests: 2','Locked Requests: 4','Original capitals subjugated: 0 / 7'])]
    for name,lines in columns:
        x=22+int(ids[name].get('Offset').split(',')[0]);y=110
        for i,text in enumerate(lines):
            size=18 if i==0 or text.startswith(('Remote Workers','Frontier Culture')) else 16
            if text.startswith('Population'):size=20
            color=GOLD if i==0 or text.startswith('Frontier Culture') else GREEN if text.startswith('Remote Workers') else WHITE
            f=font(size)
            for line in wrap(text,244,f):d.text((x,y),line,font=f,fill=color);y+=size+2
            y+=4
    # Three complete rows fit the actual 210px viewport. Native yield icons are
    # represented by labelled colored counters in this portable preview only.
    rows=Image.new('RGBA',(834,210));rd=ImageDraw.Draw(rows)
    sample=[('(25, 12)  Distance 6  Wheat · Farm','Assigned','6 Food    1 Production    1 Gold',True),
            ('(32, 9)  Distance 11  Iron · Mine','Assigned','1 Food    5 Production    1 Science',True),
            ('(41, 18)  Distance 20  Fish · Boats','Pending','6 Food    4 Gold    1 Culture',False)]
    for i,(title,status,values,assigned) in enumerate(sample):
        y=i*70;rows.alpha_composite(Image.open(V/'Art/BC_UI_Row.dds').convert('RGBA'),(0,y))
        rows.alpha_composite(Image.open(V/('Art/BC_UI_'+('Assigned' if assigned else 'Pending')+'.dds')).convert('RGBA'),(2,y+6))
        rd.text((12,y+9),title,font=font(15),fill=GREEN if assigned else WHITE)
        rd.text((12,y+34),values,font=font(14),fill=GOLD)
        for x,text in [(530,'Locate'),(630,'Unlock' if i==0 else 'Lock'),(730,'Release' if assigned else 'Assign')]:
            rows.alpha_composite(button((94,34),1 if i==0 and x==730 else 0),(x,y+16))
            f=font(14);rd.text((x+(94-f.getlength(text))/2,y+23),text,font=f,fill=WHITE)
    panel.alpha_composite(rows,(22,354))
    d.text((413,582),'1 / 6  (87)',font=font(16),fill=WHITE)
    help_text='Remote districts use real citizens. Teal marks show assigned workers; amber marks show pending requests. Scroll the overview for the full yield breakdown.'
    for i,line in enumerate(wrap(help_text,832,font(15))):d.text((32,626+i*20),line,font=font(15),fill=MUTED)
    canvas=Image.new('RGB',(960,768),'#080f15');canvas.paste(panel,(30,28))
    ImageDraw.Draw(canvas).text((32,739),'LAYOUT PREVIEW · Sample data · Native fonts and yield glyphs may differ',font=font(13),fill='#a1a897')
    canvas.save(S/'Preview.png')
    print('Saved actual-texture/XML layout preview:',S/'Preview.png')


if __name__=='__main__':main()
