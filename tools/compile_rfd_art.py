"""Package generated RFD raster masters as padded, mipmapped legacy DXT5 DDS."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
from PIL import Image, ImageDraw, ImageOps
from standardize_icons import frame_cell

R = Path(__file__).resolve().parents[1]
SOURCE = R / 'art-source/TheRepublicOfFirstDrafts'
ART = R / 'TheRepublicOfFirstDrafts/Art'
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
                  for name in ['Leader', 'Dawn', 'Icon', 'Unit', 'Building', 'Map']}
        for size in SIZES:
            export(frame_cell(images['Icon'], size), f'RFD_Icon{size}')
            # Square portrait crop places Marginalia's face in the setup portrait.
            portrait = ImageOps.fit(images['Leader'], (1024, 1024), centering=(.53, .34))
            export(frame_cell(portrait, size, leader=True), f'RFD_Portrait{size}')
            objects = Image.new('RGBA', (size*2, size))
            for i, name in enumerate(['Building', 'Unit']):
                objects.alpha_composite(frame_cell(images[name], size), (size*i, 0))
            export(objects, f'RFD_Objects{size}')
        # Simple white parchment/quill silhouette for recolorable civilization
        # alpha and siege flags. Geometry is deliberate UI asset finishing.
        mono = Image.new('RGBA', (256, 256))
        draw = ImageDraw.Draw(mono)
        draw.polygon([(48,40),(180,40),(164,208),(34,208)], fill='white')
        draw.polygon([(111,206),(218,26),(225,69),(174,151)], fill='white')
        draw.line([(109,205),(206,57)], fill=(0,0,0,0), width=7)
        for y in [79,105,131,157]:
            draw.line([(61,y),(124,y)], fill=(0,0,0,0), width=9)
        for size in SIZES:
            export(mono.resize((size,size),Image.Resampling.LANCZOS),f'RFD_Alpha{size}')
        export(mono.resize((32,32),Image.Resampling.LANCZOS),'RFD_Flag32')
        for name, dimensions in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(1024,768))]:
            export(ImageOps.fit(images[name],dimensions), 'RFD_'+name)
    print('Compiled 40 RFD DDS textures, legacy DXT5 with mip chains')


if __name__ == '__main__':
    main()
