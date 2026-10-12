"""Generate matching ModBuddy project and deployable modinfo; package without the SDK."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib,sys,zipfile
R=Path(__file__).resolve().parents[1]
MOD_ID='f6859d5b-50bf-4a7e-b5d3-bdc2d6e69392'
PROJECT_ID='aa4ad1c1-c12d-4d53-9cb9-19714c36ea01'
VERSION='4'
NAME='Cool Wacky Civs 2 (v '+VERSION+')'
ENTRY='TheBoundlessCity/UI/BoundlessWorkforce.xml'
NS='http://schemas.microsoft.com/developer/msbuild/2003'
ET.register_namespace('',NS)
PROPS={'Name':'Cool Wacky Civs 2','Teaser':'One city. A world without an end.',
 'Description':'The Boundless City: contiguous cultural frontier growth, real citizen reservations for distant tiles, the Grand Registry, Frontier Surveyors and The Boundless Workforce. Requires BNW and Community Patch v151. See the included guide for native engine limits.',
 'Authors':'SolusGo','Homepage':'https://github.com/SolusGo/CoolWackyCivs2',
 'AffectsSavedGames':'1','MinCompatibleSaveVersion':'1','SupportsSinglePlayer':'1','SupportsMultiplayer':'0',
 'SupportsHotSeat':'0','SupportsMac':'0','ReloadAudioSystem':'0','ReloadLandmarkSystem':'0',
 'ReloadStrategicViewSystem':'0','ReloadUnitSystem':'0'}
DEPS=[('Dlc','6DA07636-4123-4018-B643-6575B4EC336B','0','Expansion - Brave New World'),
 ('Mod','d1b6328c-ff44-4b0d-aad7-c657f83610cd','151','(1) Community Patch')]

def files():
    return sorted(p for p in (R/'TheBoundlessCity').rglob('*') if p.is_file() and p.suffix in ['.sql','.lua','.xml','.dds'])
def relative(p): return p.relative_to(R).as_posix()
def imported(p): return p.suffix!='.sql' and relative(p)!=ENTRY

def manifests():
    paths=files();root=ET.Element('Mod',id=MOD_ID,version=VERSION);props=ET.SubElement(root,'Properties')
    for k,v in PROPS.items(): ET.SubElement(props,k).text=v
    deps=ET.SubElement(root,'Dependencies')
    for typ,id,minimum,title in DEPS: ET.SubElement(deps,typ,id=id,minversion=minimum,maxversion='999',title=title)
    ET.SubElement(root,'References');ET.SubElement(root,'Blocks')
    content=ET.SubElement(root,'Files')
    for p in paths: ET.SubElement(content,'File',md5=hashlib.md5(p.read_bytes()).hexdigest().upper(),**{'import':str(int(imported(p)))}).text=relative(p)
    actions=ET.SubElement(ET.SubElement(root,'Actions'),'OnModActivated')
    for p in paths:
        if p.suffix=='.sql': ET.SubElement(actions,'UpdateDatabase').text=relative(p)
    entry=ET.SubElement(ET.SubElement(root,'EntryPoints'),'EntryPoint',type='InGameUIAddin',file=ENTRY)
    ET.SubElement(entry,'Name').text='The Boundless Workforce'
    ET.SubElement(entry,'Description').text='One simulation owner and an event-driven workforce panel.'
    ET.indent(root,'  ')
    with (R/(NAME+'.modinfo')).open('wb') as output:
        ET.ElementTree(root).write(output,encoding='utf-8',xml_declaration=True)
    def tag(name):return '{'+NS+'}'+name
    proj=ET.Element(tag('Project'),DefaultTargets='Deploy',ToolsVersion='4.0');group=ET.SubElement(proj,tag('PropertyGroup'))
    properties={**PROPS,'Guid':MOD_ID,'ProjectGuid':'{'+PROJECT_ID.upper()+'}', 'ModVersion':VERSION,
     'Name':'Cool Wacky Civs 2','SafeName':'CoolWackyCivs2','AssemblyName':'CoolWackyCivs2','RootNamespace':'CoolWackyCivs2','Stability':'Alpha',
     'Civ5UserPath':"$(USERPROFILE)\\Documents\\My Games\\Sid Meier's Civilization 5"}
    boolean_keys={'AffectsSavedGames','SupportsSinglePlayer','SupportsMultiplayer','SupportsHotSeat','SupportsMac',
                  'ReloadAudioSystem','ReloadLandmarkSystem','ReloadStrategicViewSystem','ReloadUnitSystem'}
    for k,v in properties.items(): ET.SubElement(group,tag(k)).text=('true' if v=='1' else 'false') if k in boolean_keys else v
    ET.SubElement(group,tag('Configuration'),Condition=" '$(Configuration)' == '' ").text='Default'
    act=ET.SubElement(group,tag('ModActions'))
    for p in paths:
        if p.suffix=='.sql':
            a=ET.SubElement(act,tag('Action'))
            for k,v in [('Set','OnModActivated'),('Type','UpdateDatabase'),('FileName',relative(p))]: ET.SubElement(a,tag(k)).text=v
    contents=ET.SubElement(group,tag('ModContent'));entry=ET.SubElement(contents,tag('Content'))
    for k,v in [('Type','InGameUIAddin'),('Name','The Boundless Workforce'),('Description','Boundless gameplay and UI'),('FileName',ENTRY)]:ET.SubElement(entry,tag(k)).text=v
    deps=ET.SubElement(group,tag('ModDependencies'))
    for typ,id,minimum,title in DEPS:
        a=ET.SubElement(deps,tag('Association'))
        for k,v in [('Type',typ),('Name',title),('Id',id),('MinVersion',minimum),('MaxVersion','999')]:ET.SubElement(a,tag(k)).text=v
    ET.SubElement(group,tag('ModReferences'));ET.SubElement(group,tag('ModBlockers'))
    for config in ['Default','Deploy Only','Package Only']:
        g=ET.SubElement(proj,tag('PropertyGroup'),Condition=f" '$(Configuration)' == '{config}' ")
        ET.SubElement(g,tag('OutputPath')).text='.'
    items=ET.SubElement(proj,tag('ItemGroup'))
    for p in paths:
        c=ET.SubElement(items,tag('Content'),Include=relative(p));ET.SubElement(c,tag('ImportIntoVFS')).text=str(imported(p))
    ET.SubElement(proj,tag('Import'),Project='$(MSBuildExtensionsPath)\\Firaxis\\ModBuddy\\Civ5Mod.targets')
    ET.indent(proj,'  ')
    with (R/'CoolWackyCivs2.civ5proj').open('wb') as output:
        ET.ElementTree(proj).write(output,encoding='utf-8',xml_declaration=True)
    print('Updated modinfo and ModBuddy project for',len(paths),'game files')
    return paths

def main():
    paths=manifests()
    if '--manifest-only' in sys.argv:return
    paths += [R/(NAME+'.modinfo'),R/'README.md',R/'CHANGELOG.md']
    paths += list((R/'TheBoundlessCity').rglob('*.md'))+list((R/'docs').rglob('*.md'))
    paths += list((R/'TheBoundlessCity/docs').glob('*.json'))
    out=R/'dist';out.mkdir(exist_ok=True)
    with zipfile.ZipFile(out/(NAME+'.zip'),'w',compression=zipfile.ZIP_DEFLATED) as z:
        for p in paths:z.write(p,NAME+'/'+relative(p))
    import py7zr
    with py7zr.SevenZipFile(out/(NAME+'.civ5mod'),'w',filters=[{'id':py7zr.FILTER_LZMA}]) as z:
        for p in paths:z.write(p,relative(p))
    with py7zr.SevenZipFile(out/(NAME+'.civ5mod'),'r') as z: assert z.testzip() is None
    print('Built ZIP and genuine 7z Civ5Mod:',out)

if __name__=='__main__':main()
