"""Legacy RGBA DDS with a complete mip chain, including non-block-aligned UI sizes."""
import io, struct
from PIL import Image

def raw_mips(image):
 stream=io.BytesIO();image=image.convert('RGBA');image.save(stream,format='DDS')
 header=bytearray(stream.getvalue()[:128]);levels=[]
 while True:
  stream=io.BytesIO();image.save(stream,format='DDS');levels.append(stream.getvalue()[128:])
  if image.size==(1,1):break
  image=image.resize((max(1,image.width//2),max(1,image.height//2)),Image.Resampling.LANCZOS)
 struct.pack_into('<I',header,8,struct.unpack_from('<I',header,8)[0]|0x20000)
 struct.pack_into('<I',header,28,len(levels));struct.pack_into('<I',header,108,0x401008)
 return bytes(header)+b''.join(levels)
