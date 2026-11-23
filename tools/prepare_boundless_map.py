"""Compile the dedicated Boundless atlas for Civ V's civilization map slot.

GameSetupScreen.xml displays a 360x410 image window. Pad its lower edge
by two pixels to align the DDS to full compression blocks.
Only this map texture and its source preview are written.
"""
from pathlib import Path
from PIL import Image, ImageOps
from setup_art import MAP_WINDOW, write_map

R=Path(__file__).resolve().parents[1]
SOURCE=R/'art-source/TheBoundlessCity'


def main():
    with Image.open(SOURCE/'BoundlessCityMap.png') as source:
        view=ImageOps.fit(source.convert('RGBA'),MAP_WINDOW,Image.Resampling.LANCZOS)
    destination=R/'TheBoundlessCity/Art/BoundlessMap.dds'
    write_map(view, destination)
    view.save(SOURCE/'BoundlessMapPreview.png')
    print('Compiled dedicated BoundlessMap.dds: 360x410 map on 360x412 legacy RGBA DDS, full mip chain')


if __name__=='__main__':main()
