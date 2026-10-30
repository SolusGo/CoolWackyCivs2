"""Kingdom actual-schema, pinned source, shipped Lua simulation and asset validation.

These are automated doubles/static checks, never a claim of native Civ V gameplay.
"""
from collections import Counter
from xml.etree import ElementTree as ET
import re
from lupa.lua51 import LuaRuntime
from PIL import Image
from build_mod import R,files
from database import database,quote
from generate_kingdom import CIV,LEADER,UNIT,HOUSE,TEXT
from generate_threshold import movement_type

V=R/'TheChildrenOfTheKingdom'
TABLES=['Civilizations','Units','UnitPromotions','GameSpeeds','Buildings','Building_YieldChanges','Policies']

def sql():
    d=database()
    originals={t:[tuple(r) for r in d.execute('SELECT * FROM '+t+' ORDER BY ID')] for t in ['Civilizations','Units','Buildings','Traits','Leaders']}
    for path in files():
        if path.suffix=='.sql': d.executescript(path.read_text(encoding='utf-8'))
    assert tuple(d.execute('SELECT Playable,AIPlayable FROM Civilizations WHERE Type=?',(CIV,)).fetchone())==(1,0)
    for table,old,new,allowed in [
      ('Units','UNIT_PIKEMAN',UNIT,{'Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex','UnitFlagAtlas','UnitFlagIconOffset'}),
      ('Buildings','BUILDING_TEMPLE',HOUSE,{'Description','Help','Strategy','Civilopedia','IconAtlas','PortraitIndex'})]:
        a=d.execute('SELECT * FROM '+table+' WHERE Type=?',(old,)).fetchone();b=d.execute('SELECT * FROM '+table+' WHERE Type=?',(new,)).fetchone()
        assert a and b
        for k in a.keys():
            if k not in allowed|{'ID','Type'}: assert a[k]==b[k],(table,k)
        prefix,col=('Unit_','UnitType') if table=='Units' else ('Building_','BuildingType')
        for (t,) in d.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
            cols=[r[1] for r in d.execute('PRAGMA table_info('+quote(t)+')')]
            if not t.startswith(prefix) or col not in cols: continue
            fields=[c for c in cols if c not in [col,'ID']]
            query='SELECT '+','.join(map(quote,fields))+' FROM '+quote(t)+' WHERE '+quote(col)+'=?'
            assert Counter(tuple(r) for r in d.execute(query,(old,)))==Counter(tuple(r) for r in d.execute(query,(new,))),t
    assert not d.execute('SELECT 1 FROM Unit_FreePromotions WHERE UnitType=? AND PromotionType LIKE ?',(UNIT,'PROMOTION_CK_%')).fetchone()
    for name,defense,heal,lost in [('STAND',0,5,0),('DEFENDER',15,0,1),('SHIELD',15,0,1)]:
        p=d.execute('SELECT * FROM UnitPromotions WHERE Type=?',('PROMOTION_CK_'+name,)).fetchone()
        assert (p['DefenseMod'],p['EmbarkDefenseModifier'],p['FriendlyHealChange'],p['NeutralHealChange'],p['LostWithUpgrade'],p['AttackMod'],p['FriendlyLandsModifier'])==(defense,defense,heal,0,lost,0,0)
    assert d.execute("SELECT COUNT(*) FROM UnitPromotions WHERE Type LIKE 'PROMOTION_CK_%'").fetchone()[0]==3,'keep existing promotion definitions'
    assert d.execute("SELECT CultureRateModifier FROM Buildings WHERE Type='BUILDING_CK_SEEK'").fetchone()[0]==15
    assert d.execute("SELECT ExtraHappiness FROM Policies WHERE Type='POLICY_CK_REPENT'").fetchone()[0]==2
    assert d.execute("SELECT CityStrengthMod FROM Policies WHERE Type='POLICY_CK_PROTECTION'").fetchone()[0]==20
    assert [r[0] for r in d.execute("SELECT IsDummy FROM Policies WHERE Type LIKE 'POLICY_CK_%'")]==[1,1]
    assert not d.execute('SELECT 1 FROM Leader_Flavors WHERE LeaderType=?',(LEADER,)).fetchone(),'no AI strategy'
    # Threshold exhaustion requires CP's per-type movement notification opt-in.
    # Permit exactly that bit on land combat types; keep all gameplay columns exact.
    for table,rows in originals.items():
        cols=[r[1] for r in d.execute('PRAGMA table_info('+table+')')]
        for original in rows:
            now=d.execute('SELECT * FROM '+table+' WHERE ID=?',(original[cols.index('ID')],)).fetchone()
            expected=list(original)
            if table=='Units' and movement_type(dict(zip(cols,original))):
                expected[cols.index('SendCanMoveIntoEvent')]=1
            assert tuple(now)==tuple(expected),('native row changed',table,original[0])
    # Civ V's stock atlas foreign keys target a non-unique Atlas column; SQLite's
    # generic foreign_key_check cannot validate this schema. Check our references.
    for t,col,target in [('Civilization_Leaders','LeaderheadType','Leaders'),('Leader_Traits','TraitType','Traits')]:
        owner='CivilizationType' if t.startswith('Civilization') else 'LeaderType'
        value=CIV if owner=='CivilizationType' else LEADER
        for (typ,) in d.execute('SELECT '+col+' FROM '+t+' WHERE '+owner+'=?',(value,)):
            assert d.execute('SELECT 1 FROM '+target+' WHERE Type=?',(typ,)).fetchone(),typ
    print('PASS Kingdom all-collection SQL, exact active Pikeman/Temple scalar and companion inheritance, human-only extras')
    return d

def source_audit():
    ref=R/'tools/reference'
    sources={n:(ref/(n+'.cpp')).read_text(encoding='utf-8-sig') for n in ['CvUnit','CvCity','CvPlayer','CvTeam','CvPlot','CvPromotionClasses','CvBuildingClasses','CvPolicyClasses','CvLuaUnit','CvLuaCity','CvLuaPlayer','CvLuaPlot','CvLuaGame']}
    h=(ref/'CustomMods.h').read_text(encoding='utf-8-sig')
    assert re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)',h)
    native=set.union(*[set(re.findall(r'Method\s*\(\s*(\w+)\s*\)',sources['CvLua'+kind])) for kind in ['Unit','City','Player','Plot','Game']])
    ui={'SetHide','IsHidden','SetText','SetDisabled','SetToolTipString','RegisterCallback','CalculateSize','ReprocessAnchoring','CalculateInternalSize','LookUpControl','SetInputHandler','SetShowHideHandler','SetUpdate','ClearUpdate'}
    used=set()
    for path in V.rglob('*.lua'):
        source=path.read_text(encoding='utf-8')
        if path.parent.name=='Lua': assert 'SetUpdate' not in source and 'ClearUpdate' not in source,path
        else:
            assert source.count('ContextPtr:SetUpdate(')==1
            assert re.search(r'ContextPtr:SetUpdate\(function\(\)\s*ContextPtr:ClearUpdate\(\);queued=false;interface.transition=false;refresh\(\)',source)
        for name in re.findall(r'\buiRecovery:(\w+)\(',source):
            assert name in {'Available','Reason','Sync','Refresh'},('Unknown presentation method',name,path)
        native_source=re.sub(r'\buiRecovery:\w+\(', 'presentation(',source)
        for name in re.findall(r':([A-Z]\w+)\(',native_source):
            assert name in native|ui,('unknown method',path,name);used.add(name)
    for method in ['IsNetworkMultiPlayer','IsHotSeat','GetGameTurn','GetGameSpeedType','GetActivePlayer']:
        assert method in native,method
    for name,sig in {'CapitalChanged':'iii','CityConstructed':'iiibb','CitySoldBuilding':'iii','UnitCreated':'iiiii','UnitConverted':'iiiib','TileOwnershipChanged':'iiii','MinorFriendsChanged':'iibii','MinorAlliesChanged':'iibii'}.items():
        assert re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+sig+'"',h),(name,sig)
    unit,city,player=sources['CvUnit'],sources['CvCity'],sources['CvPlayer']
    melee=unit[unit.index('int CvUnit::GetMaxDefenseStrength('):unit.index('int CvUnit::GetMaxRangedCombatStrength(')]
    ranged=unit[unit.index('int CvUnit::GetMaxRangedCombatStrength('):unit.index('int CvUnit::GetRangeCombatDamage(')]
    assert 'getDefenseModifier(bQuickAndDirty)' in melee
    assert re.search(r'else\s*\{\s*// Regular defense modifier\s*iModifier \+= getDefenseModifier',ranged)
    assert 'm_iDefenseMod = kResults.GetInt("DefenseMod")' in sources['CvPromotionClasses']
    assert 'm_iFriendlyHealChange = kResults.GetInt("FriendlyHealChange")' in sources['CvPromotionClasses']
    embarked=unit[unit.index('int CvUnit::GetEmbarkedUnitDefense()'):unit.index('int CvUnit::GetResistancePower(')]
    assert 'int iModifier = GetEmbarkDefensiveModifier()' in embarked
    assert 'ChangeEmbarkDefensiveModifier((thisPromotion.GetEmbarkDefenseModifier()) * iChange)' in unit
    can_heal=unit[unit.index('bool CvUnit::canHeal('):unit.index('int CvUnit::healRate(')]
    assert 'bCheckMovement && hasMoved() && !isAlwaysHeal()' in can_heal
    assert 'if (!canEndTurnAtPlot(pPlot))' in can_heal
    movement=unit[unit.index('bool CvUnit::canMoveInto('):unit.index('bool CvUnit::canMoveInto(')+24000]
    assert re.search(r'if\(plot.isCity\(\) && plot.getPlotCity\(\)->getOwner\(\) != getOwner\(\)\)\s*return false;',movement)
    assert '!IsCivilianUnit() && plot.isCity() && plot.getTeam() != getTeam()' in movement
    end_turn=unit[unit.index('bool CvUnit::canEndTurnAtPlot('):unit.index('bool CvUnit::canEndTurnAtPlot(')+600]
    assert 'return canMoveInto(*pPlot, MOVEFLAG_DESTINATION)' in end_turn
    healing=unit[unit.index('int CvUnit::healRate('):unit.index('void CvUnit::doHeal(')]
    assert '(pPlot->getTeam()==getTeam()) ? iExtraFriendlyHeal : iExtraNeutralHeal' in healing
    assert re.search(r'if \(pPlot->IsFriendlyTerritory\(getOwner\(\)\)\).*?iExtraHeal \+= iExtraFriendlyHeal;',healing,re.S)
    assert 'changeExtraNeutralHeal(thisPromotion.GetNeutralHealChange() * iChange)' in unit
    assert 'visitor(unit.m_iExtraNeutralHeal)' in unit,'native modifier counters are serialized'
    assert '(!bIsUpgrade || !pkPromotionInfo->IsLostWithUpgrade())' in unit
    assert 'GetNumPolicies' not in (V/'Lua/CK_Blessings.lua').read_text()
    policies=city[city.index('int CvCity::GetHappinessFromPolicies'):city.index('int CvCity::GetHappinessFromReligion')]
    assert re.search(r'if \(isCapital\(\)\)\s*\{\s*iTotalHappiness \+=.*POLICYMOD_EXTRA_HAPPINESS',policies)
    policy=sources['CvPolicyClasses']
    count=policy[policy.index('int CvPlayerPolicies::GetNumPoliciesOwned('):policy.index('int CvPlayerPolicies::GetNumPoliciesOwned(')+2000]
    assert re.search(r'if \(m_pPolicies->GetPolicyEntry\(i\)->IsDummy\(\)\)\s*continue;',count)
    assert '!pkPolicyInfo->IsDummy()' in policy and 'GetNumPoliciesOwned(false, true)' in policy
    assert '"PlayerCanAdoptPolicy"' in policy
    team=sources['CvTeam'];opened=team[team.index('void CvTeam::SetAllowsOpenBordersToTeam('):team.index('int CvTeam::GetRemainingDisengagementTurns(')]
    assert 'setDirty(Score_DIRTY_BIT, true)' in opened
    plot=sources['CvPlot'];friendly=plot[plot.index('bool CvPlot::IsFriendlyTerritory('):plot.index('bool CvPlot::IsFriendlyTerritory(')+1800]
    assert 'IsAllowsOpenBordersToTeam' in friendly and 'IsPlayerHasOpenBorders' in friendly
    assert 'ChangeCityStrengthMod(pkPolicyInfo->GetCityStrengthMod() * iChange)' in player
    assert 'int iStrengthMod = GET_PLAYER(getOwner()).GetCityStrengthMod()' in city
    city_strength=city[city.index('void CvCity::updateStrengthValue()'):city.index('int CvCity::getStrengthValue(')]
    ranged_strength=city[city.index('int CvCity::getStrengthValue('):city.index('int CvCity::getStrengthValue(')+13500]
    assert city_strength.index('iStrengthValue *= (100 + iStrengthMod)')<city_strength.index('int iStrengthValueRanged = iStrengthValue')
    assert city_strength.index('POLICYMOD_CITY_DEFENSE_BOOST')<city_strength.index('int iStrengthValueRanged = iStrengthValue')
    assert city_strength.index('int iStrengthValueRanged = iStrengthValue')<city_strength.index('int iAdjacentUnitsDefenseMod = getAdjacentUnitsDefenseMod()')
    assert 'int iValue = m_iStrengthValueRanged' in ranged_strength and 'int iValue = m_iStrengthValue;' in ranged_strength
    assert 'if (HasGarrison())' in ranged_strength and 'GetGarrisonedCityRangeStrikeModifier()' in ranged_strength
    city_bindings=set(re.findall(r'Method\s*\(\s*(\w+)\s*\)',sources['CvLuaCity']))
    assert {'GetStrengthValue','UpdateStrengthValue'}<=city_bindings and not {'SetStrengthValue','ChangeStrengthValue'}&city_bindings
    assert 'm_piYieldModifier[YIELD_CULTURE] += m_iCultureRateModifier' in sources['CvBuildingClasses']
    assert player.index('pLoopCity->doTurn();',player.index('void CvPlayer::doTurn()'))<player.index('"PlayerDoTurn"',player.index('void CvPlayer::doTurn()'))
    production=city[city.index('void CvCity::setProduction(int'):city.index('void CvCity::changeProduction(int')]
    assert all(n in production for n in ['isProductionUnit','isProductionBuilding','isProductionProject']) and 'popOrder' not in production
    delta=city[city.index('void CvCity::changeProduction(int'):city.index('void CvCity::setProductionTimes100(int')]
    assert all(n in delta for n in ['isProductionUnit','isProductionBuilding','isProductionProject','changeOverflowProduction'])
    print('PASS Kingdom pinned CP v151:',len(used),'Lua methods, event ABIs, defense/healing/save branches, native culture/policy/production and city tick ordering')
    print('PASS Protection source contract: CityStrengthMod boosts defense AND ranged cache; defense-only aura requires nearby units, flat building/policy boosts are not an equivalent blanket percentage')

def table(lua,v):
    if isinstance(v,dict): return lua.table_from({k:table(lua,x) for k,x in v.items()})
    if isinstance(v,list): return lua.table_from([table(lua,x) for x in v])
    return v

def runtime(d,tests=None):
    data={t:[dict(r) for r in d.execute('SELECT * FROM '+t)] for t in TABLES}
    for test in tests or ['kingdom_cycle.lua','kingdom_persistence.lua','kingdom_transfers.lua','kingdom_ui.lua',
                         'kingdom_activation.lua','kingdom_unit_rules.lua','kingdom_lifecycle.lua']:
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.globals().CK_DATABASE=table(lua,data)
        lua.globals().CK_TEXT=table(lua,{'TXT_KEY_CK_'+k:v for k,v in TEXT.items()})
        loaded=set()
        def include(name):
            if name in loaded: return
            paths=list(V.rglob(name+'.lua'));assert len(paths)==1,name
            loaded.add(name);lua.execute(paths[0].read_text(encoding='utf-8'))
        def reload():
            loaded.clear();lua.execute('ResetEvents();MapModData={}')
            include('CK_Core')
        lua.globals().include=include
        lua.execute((R/'tools/tests/kingdom_mock.lua').read_text(encoding='utf-8'))
        lua.globals().TEST.reload=reload
        lua.globals().TEST.LoadPanel=lambda:lua.execute((V/'UI/CK_Prayer.lua').read_text(encoding='utf-8'))
        include('CK_Core')
        lua.execute((R/'tools/tests'/test).read_text(encoding='utf-8'))

def assets(d):
    lua=LuaRuntime()
    for path in V.rglob('*.lua'): lua.execute('assert(loadstring(...))',path.read_text(encoding='utf-8'))
    ids={e.get('ID') for e in ET.parse(V/'UI/CK_Prayer.xml').iter() if e.get('ID')}
    refs=set(re.findall(r'Controls\.(\w+)',(V/'UI/CK_Prayer.lua').read_text(encoding='utf-8')))
    assert refs<=ids,refs-ids
    for path in V.rglob('*.xml'): ET.parse(path)
    names={p.name:p for p in (V/'Art').iterdir()}
    for row in d.execute("SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'CK_%'"):
        with Image.open(names[row['Filename']]) as im:
            im.load();assert im.size==(row['IconSize']*int(row['IconsPerRow']),row['IconSize']*int(row['IconsPerColumn'])),(row['Filename'],im.size,dict(row))
    for field in ['DawnOfManImage','MapImage']:
        assert d.execute('SELECT '+field+' FROM Civilizations WHERE Type=?',(CIV,)).fetchone()[0] in names
    for p in (V/'Art').glob('*.dds'):
        with Image.open(p) as im: im.load()
    all_sources='\n'.join(p.read_text(encoding='utf-8') for p in V.rglob('*') if p.suffix in ['.sql','.xml','.lua'])
    keys=set(re.findall(r'TXT_KEY_CK_[A-Z_0-9]+',all_sources))
    assert keys<={'TXT_KEY_CK_'+k for k in TEXT}|{'TXT_KEY_CK_CIV5','TXT_KEY_CK_FAITHFUL'},keys-{'TXT_KEY_CK_'+k for k in TEXT}
    print('PASS Kingdom Lua 5.1 syntax, UI XML/control IDs, localization and all 34 decoded DDS references')

def validate():
    d=sql();source_audit();runtime(d);assets(d)

if __name__=='__main__':
    import sys
    if '--fetch' in sys.argv:
        from urllib.request import urlopen
        from audit_cp import BASE
        path=R/'tools/reference/CvPolicyClasses.cpp'
        path.write_bytes(urlopen(BASE+path.name,timeout=30).read())
    validate()
