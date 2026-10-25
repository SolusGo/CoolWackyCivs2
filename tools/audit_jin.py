"""Fetch the additional pinned CP v151 contracts used by Jin. Read-only upstream."""
import argparse,urllib.request
from pathlib import Path
COMMIT='44c1e14ff75d80c1dba5c8a71e8289439a53aafb'
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--fetch',action='store_true');args=p.parse_args()
 if args.fetch:
  for path in ['CvGameCoreDLL_Expansion2/CvGameCoreDLL_Expansion2.vcxproj','CvGameCoreDLLUtil/include/CustomModsGlobal.h']:
   destination=ROOT/'tools/reference'/Path(path).name;destination.parent.mkdir(parents=True,exist_ok=True)
   destination.write_bytes(urllib.request.urlopen('https://raw.githubusercontent.com/LoneGazebo/Community-Patch-DLL/'+COMMIT+'/'+path,timeout=30).read())
 from validate_jin import source_audit
 source_audit()
if __name__=='__main__':main()
