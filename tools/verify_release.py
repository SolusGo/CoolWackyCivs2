"""Verify built ZIP/7z inventories, game-file bytes and the embedded modinfo."""
from pathlib import Path
import json, tempfile, zipfile
import py7zr
from build_mod import R,NAME,CIVILIZATIONS,files,relative

def main():
    game=files()
    paths=game+[R/(NAME+'.modinfo'),R/'README.md',R/'CHANGELOG.md']
    paths += [p for civ in CIVILIZATIONS for p in (R/civ).rglob('*.md')]+list((R/'docs').rglob('*.md'))
    paths += [p for civ in CIVILIZATIONS for p in (R/civ/'docs').glob('*.json')]
    paths += [R/'JinDynasty/Balance.json']
    expected={relative(p):p for p in paths}
    assert len(expected)==len(paths),'duplicate package paths'
    with zipfile.ZipFile(R/'dist'/(NAME+'.zip')) as z:
        assert z.testzip() is None
        assert {n.removeprefix(NAME+'/') for n in z.namelist()}==set(expected),'ZIP inventory'
        for name,p in expected.items(): assert z.read(NAME+'/'+name)==p.read_bytes(),('ZIP stale bytes',name)
    with py7zr.SevenZipFile(R/'dist'/(NAME+'.civ5mod')) as z:
        assert set(z.getnames())==set(expected),'7z inventory'
        assert z.testzip() is None,'7z CRC'
    # Extract a small authoritative sample, confined to the ignored workspace output.
    with tempfile.TemporaryDirectory(prefix='verify-release-',dir=R/'dist') as temporary:
        target=Path(temporary).resolve()
        assert target.parent==(R/'dist').resolve(),'unsafe extraction target'
        sample=[NAME+'.modinfo','TheBoundlessCity/Lua/BoundlessPlanner.lua',
                'TheBoundlessCity/Lua/BoundlessCitizens.lua','TheBoundlessCity/UI/BoundlessWorkforce.xml',
                'TheConicalUnion/Lua/ConicalUnion.xml',
                'TheConicalUnion/Lua/ConicalUnion.lua',
                'TheConicalUnion/SQL/00_CONICAL_Core.sql',
                'TheConicalUnion/SQL/01_CONICAL_Inheritance.sql',
                'TheConicalUnion/SQL/02_CONICAL_Effects.sql',
                'TheConicalUnion/Art/CONICAL_Leader.dds',
                'TheConicalUnion/Art/CONICAL_Objects256.dds',
                'TheConicalUnion/docs/Validation.json',
                'TheSubstituteClassroom/UI/GARVEY_RollCall.xml',
                'TheSubstituteClassroom/UI/GARVEY_RollCall.lua',
                'TheSubstituteClassroom/Lua/GARVEY_Core.lua',
                'TheSubstituteClassroom/Lua/GARVEY_Events.lua',
                'TheSubstituteClassroom/SQL/02_GARVEY_Effects.sql',
                'TheSubstituteClassroom/Art/GARVEY_Leader.dds',
                'TheSubstituteClassroom/docs/Validation.json',
                'KingdomOfSaba/Lua/SABA_Cities.lua',
                'KingdomOfSaba/Lua/SABA_Cities.xml',
                'KingdomOfSaba/SQL/01_SABA_Inheritance.sql',
                'KingdomOfSaba/SQL/02_SABA_Effects.sql',
                'KingdomOfSaba/Art/SABA_Leader.dds',
                'KingdomOfSaba/Art/SABA_Objects256.dds',
                'TheWanderingCircus/UI/WanderingCircus.lua',
                'TheWanderingCircus/SQL/02_WCIRCUS_Effects.sql',
                'The11Cats/Lua/THE11CATS_Manager.lua',
                'The11Cats/Lua/THE11CATS_Safety.lua',
                'The11Cats/Lua/THE11CATS_Presentation.lua',
                'The11Cats/UI/THE11CATS_Household.xml',
                'The11Cats/SQL/THE11CATS_02_Effects.sql',
                'The11Cats/Art/THE11CATS_Cats256.dds',
                'The11Cats/Art/THE11CATS_Leader.dds',
                'The11Cats/Art/THE11CATS_Dawn.dds',
                'The11Cats/Art/THE11CATS_Flag32.dds']
        sample += ['KingdomOfTheUnrungBell/'+p for p in [
            'Lua/UnrungBell.xml','Lua/UnrungBell.lua','SQL/00_UNRUNG_Core.sql',
            'SQL/01_UNRUNG_Inheritance.sql','SQL/02_UNRUNG_Effects.sql',
            'Art/UNRUNG_Leader.dds','Art/UNRUNG_Objects256.dds','docs/Validation.json']]
        sample += ['TheBoundlessCity/UI/BoundlessWorkforce.lua','TheBoundlessCity/UI/BoundlessWorkforce.xml']
        sample += ['TheBoundlessCity/Art/BoundlessMap.dds']
        sample += ['TheBoundlessCity/SQL/10_BC_Text.sql','TheBoundlessCity/Lore/TheCity.md','TheBoundlessCity/Lore/TheFirstArchitect.md']
        sample += ['TheUrgal/'+p for p in ['Lua/URGAL_Core.lua','Lua/URGAL_AI.lua','UI/URGAL_Potions.lua','UI/URGAL_Potions.xml','SQL/02_URGAL_Effects.sql','Art/URGAL_Leader.dds','Art/URGAL_Objects256.dds','Art/URGAL_PotionUI32.dds','docs/Validation.json']]
        sample += ['JinDynasty/'+p for p in ['Lua/JIN_Core.lua','Lua/JIN_State.lua','Lua/JIN_Military.lua','Lua/JIN_Autonomy.lua','Lua/JIN_Runtime.lua','Lua/JIN_Transactions.lua','Lua/JIN_Config.lua','UI/JIN_Dynasty.lua','UI/JIN_Dynasty.xml','SQL/00_JIN_Core.sql','SQL/02_JIN_Effects.sql','SQL/10_JIN_Text.sql','Art/JIN_Leader.dds','Art/JIN_Units256.dds','docs/Validation.json','docs/HardeningBenchmark.json','Balance.json']]
        sample += ['TheBoundlessCity/Art/BC_UI_'+name+'.dds' for name in ['Panel','Launcher','Row','Buttons','Assigned','Pending']]
        sample += ['TheThresholdCourt/'+p for p in ['Lua/THC_Core.lua','Lua/THC_State.lua','Lua/THC_Events.lua','UI/THC_Transfer.lua','UI/THC_Transfer.xml','SQL/00_THC_Core.sql','SQL/01_THC_Inheritance.sql','SQL/02_THC_Effects.sql','SQL/03_THC_Art.sql','SQL/10_THC_Text.sql','Art/THC_Leader.dds','Art/THC_Objects256.dds','docs/Validation.json']]
        sample += ['Shared/UI/CWC2_Screen.lua']
        sample += ['T1ZOFGK/'+p for p in ['Lua/T1Z_Controller.lua','UI/T1Z_Roster.lua','UI/T1Z_Roster.xml',
            'SQL/00_T1Z_Core.sql','SQL/01_T1Z_Inheritance.sql','SQL/02_T1Z_Effects.sql',
            'SQL/03_T1Z_Art.sql','SQL/10_T1Z_Text.sql','Art/T1Z_Leader.dds','Art/T1Z_Dawn.dds',
            'Art/T1Z_Icon256.dds','Art/T1Z_Promotions45.dds','docs/Validation.json']]
        sample += [relative(p) for p in game if p.relative_to(R).parts[0]=='TheRepublicOfFirstDrafts']
        sample += ['TheRepublicOfFirstDrafts/docs/Validation.json','TheRepublicOfFirstDrafts/README.md']
        sample += [relative(p) for p in game if p.relative_to(R).parts[0]=='TheLanternFleet']
        sample += ['TheLanternFleet/docs/Validation.json','TheLanternFleet/README.md']
        for record in json.loads((R/'docs/UIRefreshInventory.json').read_text(encoding='utf-8')):
            sample += record['xml']
            sample += [name.removesuffix('.xml')+'.lua' for name in record['xml']]
            sample += [record['civilization']+'/Art/'+name for name in record['textures'] if '_Panel_' in name or '_Launcher_' in name]
        sample=list(dict.fromkeys(sample))
        with py7zr.SevenZipFile(R/'dist'/(NAME+'.civ5mod')) as z: z.extract(path=target,targets=sample)
        for name in sample: assert (target/name).read_bytes()==(R/name).read_bytes(),('7z stale bytes',name)
    print('PASS ZIP and genuine 7z/LZMA release:',len(expected),'files,',len(game),'game files, exact ZIP bytes, CRC and extracted 7z manifest/runtime/SQL')

if __name__=='__main__': main()
