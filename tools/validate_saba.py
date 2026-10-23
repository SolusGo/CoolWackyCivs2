"""Actual-schema SQL, CP v151 source contracts and shipped Lua 5.1 simulations."""
from collections import Counter
import hashlib,json,re,sqlite3,struct,time
from pathlib import Path
from xml.etree import ElementTree as ET
from PIL import Image
from lupa.lua51 import LuaRuntime
from database import database,quote
from build_mod import files
from generate_saba import R,V,CIV,LEADER,UNIT,CISTERN,PROMOTION,DUMMIES,TEXT,CITIES

def apply(d):
    for p in sorted((V/'SQL').glob('*.sql')):d.executescript(p.read_text(encoding='utf-8'))

def yields(d,b):
    return dict(d.execute('SELECT YieldType,SUM(Yield) FROM Building_YieldChanges WHERE BuildingType=? GROUP BY YieldType',(b,)))

def inheritance(d):
    for table,old,new,allowed in [
        ('Units','UNIT_SPEARMAN',UNIT,{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}),
        ('Buildings','BUILDING_WATERMILL',CISTERN,{'ID','Type','Description','Civilopedia','Help','Strategy','IconAtlas','PortraitIndex'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone()
        b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        assert a and b
        for k in a.keys():
            if k not in allowed:assert a[k]==b[k],(table,k,a[k],b[k])
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in cols:continue
            fields=[c for c in cols if c not in [col,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
            left=Counter(tuple(r) for r in d.execute(query,(old,)))
            right=Counter(tuple(r) for r in d.execute(query,(new,)))
            if t=='Unit_FreePromotions':right.subtract({(PROMOTION,):1});right=+right
            if t=='Building_YieldChanges':
                a,b=yields(d,old),yields(d,new)
                for y in ['YIELD_FOOD','YIELD_GOLD']:a[y]=a.get(y,0)+1
                assert a==b,(a,b)
            else:assert left==right,('companion inheritance',t,left-right,right-left)

def sql():
    d=database()
    # Apply every released civilization in its existing order, then snapshot all
    # rows, including numeric IDs, before appending Saba.
    for p in files():
        if p.suffix=='.sql' and p.relative_to(R).parts[0]!='KingdomOfSaba':d.executescript(p.read_text(encoding='utf-8'))
    tables=[r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")]
    before={t:Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))) for t in tables}
    apply(d)
    for t,rows in before.items():assert not rows-Counter(tuple(r) for r in d.execute('SELECT * FROM '+quote(t))),('modified a preexisting row',t)
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    assert d.execute('SELECT CityName FROM Civilization_CityNames WHERE CivilizationType=? ORDER BY rowid',(CIV,)).fetchone()[0]=='TXT_KEY_SABA_CITY_1'
    assert TEXT['CITY_1']=="Ma'rib"
    assert d.execute('SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType=?',(CIV,)).fetchone()[0]==len(CITIES)
    assert tuple(d.execute('SELECT UnitClassType,UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType=?',(CIV,)).fetchone())==('UNITCLASS_SPEARMAN',UNIT)
    assert tuple(d.execute('SELECT BuildingClassType,BuildingType FROM Civilization_BuildingClassOverrides WHERE CivilizationType=?',(CIV,)).fetchone())==('BUILDINGCLASS_WATERMILL',CISTERN)
    inheritance(d)
    for suffix in DUMMIES:
        b='BUILDING_SABA_'+suffix
        assert tuple(d.execute('SELECT Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb FROM Buildings WHERE Type=?',(b,)).fetchone())==(-1,-1,-1,1,1,1,0,0)
    assert yields(d,'BUILDING_SABA_RIVER')=={'YIELD_FOOD':1,'YIELD_PRODUCTION':1}
    assert yields(d,'BUILDING_SABA_DESERT')=={'YIELD_CULTURE':1}
    assert tuple(d.execute('SELECT VisibilityChange,LostWithUpgrade,CannotBeChosen,DefenseMod FROM UnitPromotions WHERE Type=?',(PROMOTION,)).fetchone())==(1,1,1,0)
    assert [tuple(r) for r in d.execute('SELECT TerrainType,Attack,Defense FROM UnitPromotions_TerrainModifiers WHERE PromotionType=?',(PROMOTION,))]==[('TERRAIN_DESERT',0,15)]
    assert not d.execute('SELECT 1 FROM UnitPromotions_Terrains WHERE PromotionType=?',(PROMOTION,)).fetchone()
    assert d.execute('SELECT COUNT(*) FROM Unit_FreePromotions WHERE UnitType=? AND PromotionType=?',(UNIT,PROMOTION)).fetchone()[0]==1
    for k,v in TEXT.items():assert d.execute('SELECT Text FROM Language_en_US WHERE Tag=?',('TXT_KEY_SABA_'+k,)).fetchone()[0]==v
    # Check all localized references, including pedia prefix and diplomacy patterns.
    keys={'TXT_KEY_SABA_'+k for k in TEXT}
    source='\n'.join(p.read_text(encoding='utf-8') for p in (V/'SQL').glob('*.sql'))
    for key in re.findall(r"'(TXT_KEY_SABA_[A-Z_0-9%]+)'",source):
        assert key in keys or any(k.startswith(key.rstrip('%')) for k in keys),key
    assert d.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    # Mutate base rows and companion rows BEFORE activation. SELECT * must copy
    # future scalar fields; additive yields must handle absent and present rows.
    altered=database()
    altered.executescript("""ALTER TABLE Units ADD SABA_TestScalar INTEGER DEFAULT 0;
ALTER TABLE Buildings ADD SABA_TestScalar INTEGER DEFAULT 0;
UPDATE Units SET Cost=197,Moves=4,Combat=19,BaseSightRange=3,SABA_TestScalar=37 WHERE Type='UNIT_SPEARMAN';
UPDATE Buildings SET Cost=211,GoldMaintenance=4,River=0,SpecialistCount=2,SABA_TestScalar=73 WHERE Type='BUILDING_WATERMILL';
DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_WATERMILL' AND YieldType='YIELD_FOOD';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('BUILDING_WATERMILL','YIELD_GOLD',4);
""")
    apply(altered);inheritance(altered)
    assert altered.execute('SELECT SABA_TestScalar FROM Units WHERE Type=?',(UNIT,)).fetchone()[0]==37
    assert altered.execute('SELECT SABA_TestScalar FROM Buildings WHERE Type=?',(CISTERN,)).fetchone()[0]==73
    assert yields(altered,CISTERN)['YIELD_FOOD']==1 and yields(altered,CISTERN)['YIELD_GOLD']==5
    cache=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
    if cache.exists():
        active=database(cache=cache)
        for p in sorted((R/'Shared/SQL').glob('*.sql')):active.executescript(p.read_text(encoding='utf-8'))
        if not active.execute('SELECT 1 FROM Civilizations WHERE Type=?',(CIV,)).fetchone():
            apply(active);inheritance(active)
            print('PASS Saba activation on read-only active-cache copy with installed CP schema')
        else:print('SKIP active-cache activation: Saba already present')
    print('PASS Saba real-schema SQL, all released rows/IDs preserved, exact bonuses, full inheritance and changed-base/companion regressions')
    return d

def sources():
    from audit_cp import COMMIT
    names=['CvPlayer.cpp','CvUnit.cpp','CvPromotionClasses.cpp','CvLuaPlot.cpp','CvPlot.cpp','CvCity.cpp','CvBuildingClasses.cpp']
    data={n:(R/'tools/reference'/n).read_text(encoding='utf-8-sig') for n in names}
    def body(name,sig):
        s=data[name];i=s.index(sig);return s[i:s.index('\n}',i)+2]
    acquire=body('CvPlayer.cpp','CvCity* CvPlayer::acquireCity(')
    defense=body('CvUnit.cpp','int CvUnit::GetMaxDefenseStrength(')
    attack=body('CvUnit.cpp','int CvUnit::GetMaxAttackStrength(')
    contracts={
      'singular terrain table absent from installed schema':not database().execute("SELECT 1 FROM sqlite_master WHERE name='UnitPromotions_Terrain'").fetchone(),
      'CP loader consumes TerrainModifiers Defense':'UnitPromotions_TerrainModifiers.Defense' in data['CvPromotionClasses.cpp'] and 'm_piTerrainModifierDefense[iTerrainID] = iTerrainDefense;' in data['CvPromotionClasses.cpp'],
      'defense uses underlying terrain independent of features':'GetTerrainModifierDefense(pInPlot->getTerrainType())' in defense,
      'Desert Hills retain terrain lookup':defense.index('GetTerrainModifierDefense(pInPlot->getTerrainType())')<defense.index('GetTerrainModifierDefense(TERRAIN_HILL)'),
      'attacking never consumes terrain defense':'GetTerrainModifierDefense(' not in attack,
      'native visibility modifier':'changeExtraVisibilityRange(thisPromotion.GetVisibilityChange() * iChange)' in data['CvUnit.cpp'],
      'native upgrade drops unique promotion':'(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in data['CvUnit.cpp'],
      'native river binding':'lua_pushboolean(L, pkPlot->isRiver());' in body('CvLuaPlot.cpp','int CvLuaPlot::lIsRiver('),
      'native terrain binding':'getTerrainType()' in body('CvLuaPlot.cpp','int CvLuaPlot::lGetTerrainType('),
      'capture callback after reconstruction':acquire.index('pNewCity->')<acquire.index('"CityCaptureComplete"'),
      'common callback is not conquest gated':acquire.rfind('if (pkScriptSystem)',0,acquire.index('"CityCaptureComplete"'))>acquire.rfind('// Update events',0,acquire.index('"CityCaptureComplete"')),
      'liberation reacquires city':'acquireCity(' in body('CvPlayer.cpp','void CvPlayer::DoLiberatePlayer('),
      'never capture rejects gifts and conquests':body('CvPlayer.cpp','bool CvPlayer::IsValidBuildingForPlayer(').index('IsNeverCapture()')<body('CvPlayer.cpp','bool CvPlayer::IsValidBuildingForPlayer(').index('if (!bConquest'),
      'founding callback exists':'"PlayerCityFounded"' in data['CvPlayer.cpp'],
      'turn fallback exists':'"PlayerDoTurn"' in data['CvPlayer.cpp'],
      'native building yields are city base yields':'ChangeBaseYieldRateFromBuildings' in data['CvBuildingClasses.cpp'],
      'zero-maintenance dummy buildings cannot be sold':'if(kBuilding.GetGoldMaintenance() <= 0)' in body('CvBuildingClasses.cpp','bool CvCityBuildings::IsBuildingSellable('),
    }
    for name,ok in contracts.items():assert ok,name
    cp=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/MODS/(1) Community Patch/Database Changes/UnitPromotions/NewPromotionTables.xml"
    root=ET.parse(cp).getroot()
    assert root.find("Table[@name='UnitPromotions_TerrainModifiers']") is not None
    report={'source_commit':COMMIT,'source_repository':'https://github.com/LoneGazebo/Community-Patch-DLL','native_gameplay':'NOT TESTED IN GAME','contracts':contracts,
            'sha256':{n:hashlib.sha256((R/'tools/reference'/n).read_bytes()).hexdigest() for n in names},
            'installed_promotion_schema_sha256':hashlib.sha256(cp.read_bytes()).hexdigest()}
    (V/'docs').mkdir(parents=True,exist_ok=True)
    (V/'docs/SourceAudit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS Saba',len(contracts),'CP v151 source/schema contracts; NOT native gameplay')

def runtime(d):
    ids={name:d.execute('SELECT ID FROM '+table+' WHERE Type=?',(name,)).fetchone()[0] for name,table in [(CIV,'Civilizations'),('BUILDING_SABA_RIVER','Buildings'),('BUILDING_SABA_DESERT','Buildings'),('TERRAIN_DESERT','Terrains')]}
    source=(V/'Lua/SABA_Cities.lua').read_text(encoding='utf-8')
    times={}
    for name in ['saba_locations.lua','saba_lifecycle.lua','saba_reload_stress.lua']:
        lua=LuaRuntime();lua.globals().GameInfoTypes=lua.table_from(ids)
        lua.execute((R/'tools/tests/saba_mock.lua').read_text(encoding='utf-8'))
        lua.globals().LoadSaba=lambda:lua.execute(source)
        river=yields(d,'BUILDING_SABA_RIVER');desert=yields(d,'BUILDING_SABA_DESERT')
        lua.execute('function Harvest(c) local r=c:GetNumRealBuilding(GameInfoTypes.BUILDING_SABA_RIVER);local d=c:GetNumRealBuilding(GameInfoTypes.BUILDING_SABA_DESERT);return r*'+str(river['YIELD_FOOD'])+',r*'+str(river['YIELD_PRODUCTION'])+',d*'+str(desert['YIELD_CULTURE'])+' end')
        started=time.perf_counter();lua.execute((R/'tools/tests'/name).read_text(encoding='utf-8'));times[name]=round(time.perf_counter()-started,6)
    assert 'SetUpdate' not in source and 'GetNumPlots' not in source
    print('PASS Saba shipped Lua 5.1 simulations:',times,'(synthetic native boundary, NOT game timings)')

def art(d):
    for atlas,size,filename,cols,rows in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'SABA_%'"):
        p=V/'Art'/filename
        with Image.open(p) as im:im.load();assert im.size==(size*int(cols),size*int(rows)),(p,im.size)
        header=p.read_bytes()[:128]
        assert header[:4]==b'DDS ' and header[84:88]!=b'DX10'
        assert struct.unpack_from('<I',header,28)[0]==max(size*int(cols),size*int(rows)).bit_length(),p
    for table,typ in [('Civilizations',CIV),('Leaders',LEADER),('Units',UNIT),('Buildings',CISTERN),('UnitPromotions',PROMOTION)]:
        atlas,index=d.execute('SELECT IconAtlas,PortraitIndex FROM '+table+' WHERE Type=?',(typ,)).fetchone()
        assert d.execute('SELECT 1 FROM IconTextureAtlases WHERE Atlas=? AND IconSize=32 AND IconsPerRow*IconsPerColumn>?',(atlas,index)).fetchone()
    assert ET.parse(V/'Art/SABA_LeaderScene.xml').getroot().get('FallbackImage')=='SABA_Leader.dds'
    for stem,size in [('Leader',(1600,900)),('Dawn',(1024,768)),('Map',(512,512))]:
        with Image.open(V/'Art'/f'SABA_{stem}.dds') as im:im.load();assert im.size==size
    assert len(list((V/'Art').glob('*.dds')))==40
    print('PASS Saba 40 decoded DDS textures, atlas sizes/indices, mipmaps, legacy encoding and leader/loading/map references')

def validate():
    d=sql();sources();runtime(d);art(d)

if __name__=='__main__':validate()
