"""Compile the dedicated Boundless atlas for Civ V's civilization map slot.

GameSetupScreen.xml displays a 360x410 image window. Keep the traditional
512x512 DDS canvas, with the map in its upper-left window and transparent gutters.
Only this map texture and its source preview are written.
"""
from pathlib import Path
from PIL import Image, ImageOps
from prepare_red_art import raw_mips

R=Path(__file__).resolve().parents[1]
SOURCE=R/'art-source/TheBoundlessCity'
VIEW=(360,410)
CANVAS=(512,512)


def main():
    with Image.open(SOURCE/'BoundlessCityMap.png') as source:
        view=ImageOps.fit(source.convert('RGBA'),VIEW,Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',CANVAS,(0,0,0,0))
    canvas.paste(view,(0,0))
    destination=R/'TheBoundlessCity/Art/BoundlessMap.dds'
    destination.write_bytes(raw_mips(canvas))
    view.save(SOURCE/'BoundlessMapPreview.png')
    print('Compiled dedicated BoundlessMap.dds: 360x410 map on 512x512 legacy RGBA DDS, full mip chain')


if __name__=='__main__':main()
