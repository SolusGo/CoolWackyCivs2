"""Compile retained original paintings and simple alpha symbols to mipmapped DDS."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageOps
from prepare_red_art import raw_mips

R = Path(__file__).resolve().parents[1]
S = R/'art-source/TheTwelfthHour'
V = R/'TheTwelfthHour/Art'
SIZES = [16,24,32,45,48,64,80,128,256]

def alpha_clock():
    im = Image.new('RGBA', (512,512))
    d = ImageDraw.Draw(im)
    d.ellipse((65,65,447,447), outline='white', width=34)
    for hour in range(12):
        angle = hour*math.pi/6
        d.line([(256+math.sin(angle)*r,256-math.cos(angle)*r) for r in [139,160]], fill='white', width=16)
    d.line((256,256,256,127), fill='white', width=26)
    d.ellipse((230,230,282,282), fill='white')
    return im

def flag():
    im = Image.new('RGBA',(512,512));d = ImageDraw.Draw(im)
    d.line((188,83,188,434), fill='white', width=30)
    d.polygon([(188,29),(135,134),(188,119),(243,134)], fill='white')
    d.line((304,151,304,330), fill='white', width=18)
    d.ellipse((264,310,344,390), fill='white')
    d.arc((221,257,389,425),20,160,fill='white',width=16)
    return im

def save(im, name, size):
    im = ImageOps.fit(im, size, method=Image.Resampling.LANCZOS)
    (V/name).write_bytes(raw_mips(im))

def main():
    V.mkdir(parents=True,exist_ok=True)
    sheet = Image.open(S/'ClockworkMasters.png').convert('RGBA')
    w,h = sheet.size
    # The retained painting's horizontal divider is at y=600/1254.
    split = round(h*600/1254)
    icon,unit,tower,portrait = [sheet.crop(box) for box in
        [(0,0,w//2,split),(w//2,0,w,split),(0,split,w//2,h),(w//2,split,w,h)]]
    dawn = Image.open(S/'ClockworkCity.png').convert('RGBA')
    save(dawn,'TWELFTH_Dawn.dds',(1024,768))
    leader = Image.open(S/'KeeperOfSeconds.png').convert('RGBA')
    save(leader,'TWELFTH_Leader.dds',(1600,900))
    save(dawn,'TWELFTH_Map.dds',(512,512))
    for size in SIZES:
        save(icon,f'TWELFTH_Icon{size}.dds',(size,size))
        save(alpha_clock(),f'TWELFTH_Alpha{size}.dds',(size,size))
        save(portrait,f'TWELFTH_Portrait{size}.dds',(size,size))
        objects = Image.new('RGBA',(size*2,size))
        objects.paste(ImageOps.fit(tower,(size,size),method=Image.Resampling.LANCZOS),(0,0))
        objects.paste(ImageOps.fit(unit,(size,size),method=Image.Resampling.LANCZOS),(size,0))
        (V/f'TWELFTH_Objects{size}.dds').write_bytes(raw_mips(objects))
    save(flag(),'TWELFTH_Flag32.dds',(32,32))
    (V/'TWELFTH_LeaderScene.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<LeaderScene FallbackImage="TWELFTH_Leader.dds" />\n',encoding='utf-8',newline='\n')
    print('Compiled original Twelfth Hour paintings, atlas sizes, alpha/flag and leader fallback')

if __name__ == '__main__':
    main()
