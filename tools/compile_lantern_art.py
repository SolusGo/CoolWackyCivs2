"""Package generated LANTERN raster masters as padded, mipmapped legacy DXT5 DDS."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
from PIL import Image, ImageDraw, ImageOps
from standardize_icons import frame_cell

R = Path(__file__).resolve().parents[1]
SOURCE = R / 'art-source/TheLanternFleet'
ART = R / 'TheLanternFleet/Art'
SIZES = [16, 24, 32, 45, 48, 64, 80, 128, 256]


def main():
    converter = shutil.which('texconv') or shutil.which('texconv.exe')
    if not converter:
        candidates = sorted((Path(os.environ['LOCALAPPDATA']) / 'Microsoft/WinGet/Packages').glob('Microsoft.DirectXTex.Texconv_*/texconv.exe'))
        converter = str(candidates[-1]) if candidates else None
    assert converter, 'Use the existing DirectXTex texconv installation'
    ART.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        temp = Path(temporary)

        def export(image, name):
            source = temp / (name + '.png')
            image.save(source)
            result = subprocess.run([converter, '-nologo', '-y', '-dx9', '-f', 'DXT5',
                                     '-m', '0', '-o', str(ART), str(source)], capture_output=True, text=True)
            assert result.returncode == 0, result.stdout + result.stderr

        images = {name: Image.open(SOURCE / (name + '.png')).convert('RGBA')
                  for name in ['Leader', 'Dawn', 'Icon', 'Unit', 'Building']}
        for size in SIZES:
            export(frame_cell(images['Icon'], size), f'LANTERN_Icon{size}')
            # Square portrait crop places Marginalia's face in the setup portrait.
            portrait = ImageOps.fit(images['Leader'], (1024, 1024), centering=(.50, .20))
            export(frame_cell(portrait, size, leader=True), f'LANTERN_Portrait{size}')
            objects = Image.new('RGBA', (size*2, size))
            for i, name in enumerate(['Building', 'Unit']):
                objects.alpha_composite(frame_cell(images[name], size), (size*i, 0))
            export(objects, f'LANTERN_Objects{size}')
        # Recolorable lantern silhouette, deliberately simplified for tiny HUDs.
        mono = Image.new('RGBA', (256, 256))
        draw = ImageDraw.Draw(mono)
        draw.arc((86,12,170,94),180,360,fill='white',width=18)
        draw.polygon([(74,81),(182,81),(205,105),(51,105)],fill='white')
        draw.rounded_rectangle((67,100,189,222),radius=8,outline='white',width=17)
        draw.rectangle((53,215,203,239),fill='white')
        draw.polygon([(128,117),(100,164),(116,202),(140,202),(156,166)],fill='white')
        for size in SIZES:
            export(mono.resize((size,size),Image.Resampling.LANCZOS),f'LANTERN_Alpha{size}')
        export(mono.resize((32,32),Image.Resampling.LANCZOS),'LANTERN_Flag32')
        images['Map'] = images['Dawn']
        for name, dimensions in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(1024,768))]:
            export(ImageOps.fit(images[name],dimensions), 'LANTERN_'+name)
    print('Compiled 40 LANTERN DDS textures, legacy DXT5 with mip chains')


if __name__ == '__main__':
    main()
