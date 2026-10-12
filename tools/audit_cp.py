"""Audit pinned official CP v151 source. --fetch downloads only into tools/reference."""
from pathlib import Path
import argparse, hashlib, json, re, urllib.request

ROOT = Path(__file__).resolve().parents[1]
COMMIT = '44c1e14ff75d80c1dba5c8a71e8289439a53aafb'
BASE = f'https://raw.githubusercontent.com/LoneGazebo/Community-Patch-DLL/{COMMIT}/CvGameCoreDLL_Expansion2/'
FILES = ['CustomMods.h', 'CvCityCitizens.cpp', 'CvCityCitizens.h', 'CvCity.cpp', 'CvPlayer.cpp',
         'CvPlot.cpp', 'CvUnit.cpp', 'CvUnitCombat.cpp', 'CvUnitMission.cpp', 'CvTeam.cpp',
         'CvBuilderTaskingAI.cpp', 'Lua/CvLuaCity.cpp', 'Lua/CvLuaPlayer.cpp', 'Lua/CvLuaPlot.cpp',
         'Lua/CvLuaUnit.cpp', 'Lua/CvLuaTeam.cpp']
METHODS = {
 'City': 'GetOwner GetX GetY GetID GetOriginalOwner GetPreviousOwner GetGameTurnFounded IsOriginalCapital '
         'GetPopulation GetAutomatons GetNumCityPlots GetCityIndexPlot IsWorkingPlot IsForcedWorkingPlot '
         'GetSpecialistCount GetTotalSpecialistCount GetExtraSpecialistYieldOfType GetNumBuilding '
         'GetNumRealBuilding SetNumRealBuilding SetName GetJONSCulturePerTurn FoodDifference AlterWorkingPlot '
         'DoTask GetBaseYieldRateFromMisc ChangeBaseYieldRateFromMisc GetBaseYieldRateFromTerrain '
         'ChangeBaseYieldRateFromTerrain IsHolyCityAnyReligion IsRazing GetDamage GetMaxHitPoints GetName '
         'GetResistanceTurns ChangeResistanceTurns IsRevealed',
 'Player': 'GetCivilizationType GetCapitalCity Cities Units GetNumCities GetScriptData SetScriptData IsHuman '
           'IsAlive IsBarbarian IsMinorCiv GetPlayerToLiberate CanLiberatePlayer CanRaze AcquireCity Disband '
           'IsTurnActive GetCurrentEra GetTeam AddNotification GetUnitByID ChangeJONSCulture GetNumMilitaryUnits',
 'Plot': 'GetOwner GetX GetY GetPlotIndex GetPlotCity IsCity HasYield IsWater IsVisibleEnemyUnit IsBlockaded '
         'GetYield GetResourceType GetImprovementType IsImprovementPillaged IsVisible GetScriptData SetScriptData '
         'SetOwner GetCityPurchaseID',
 'Unit': 'GetUnitType GetID GetX GetY IsHasPromotion SetHasPromotion Kill MovesLeft GetGameTurnCreated IsBusy '
         'IsCombatUnit IsRanged IsEmbarked FinishMoves GeneratePath CanBuild GetPlot PushMission',
 'Team': 'IsAtWar IsWaterWork',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fetch', action='store_true')
    parser.add_argument('--source', type=Path, default=ROOT / 'tools/reference')
    args = parser.parse_args()
    if args.fetch:
        args.source.mkdir(parents=True, exist_ok=True)
        for path in FILES:
            (args.source / Path(path).name).write_bytes(urllib.request.urlopen(BASE + path, timeout=30).read())
    sources = {Path(p).name: (args.source / Path(p).name).read_text(encoding='utf-8-sig') for p in FILES}
    checks = []
    def check(name, condition):
        assert condition, name
        checks.append(name)
    check('DLL version is 151', bool(re.search(r'MOD_DLL_VERSION_NUMBER\s+\(\(uint\) 151\)', sources['CustomMods.h'])))
    for kind, names in METHODS.items():
        content = sources[f'CvLua{kind}.cpp']
        for name in names.split():
            check(f'{kind}:{name} registered', bool(re.search(r'Method\s*\(\s*'+name+r'\s*\)', content)))
    check('DoTask option uses luaL_optint', 'const bool bOption = luaL_optint(L, 5, 0)' in sources['CvLuaCity.cpp'])
    check('Labourer extra yield is count multiplied', 'GetSpecialistCount(eSpecialist) * iYieldMultiplier' in sources['CvCity.cpp'])
    check('Specialist extra binding order is yield then specialist', 'BasicLuaMethod<int, YieldTypes, SpecialistTypes>' in sources['CvLuaCity.cpp'])
    check('Default labourer excluded from generic extras', 'eSpecialist != GD_INT_GET(DEFAULT_SPECIALIST)' in sources['CvCity.cpp'])
    check('No exposed forced-default citizen setter', not re.search(r'Method\s*\(\s*(Set|Change)NumForcedDefaultSpecialists', sources['CvLuaCity.cpp']))
    check('No City ScriptData binding', not re.search(r'Method\s*\(\s*(Get|Set)ScriptData', sources['CvLuaCity.cpp']))
    check('CanRaze requires ownership', 'pCity->getOwner() != GetID()' in sources['CvPlayer.cpp'])
    check('CanRaze rejects own-founded settlements', 'pCity->getOriginalOwner() == GetID()' in sources['CvPlayer.cpp'])
    check('GeneratePath accepts native max turns', 'const int iMaxTurns = lua_tointeger(L, 3)' in sources['CvLuaUnit.cpp'])
    check('Misc source setter updates native static yield', bool(re.search(r'void CvCity::ChangeBaseYieldRateFromMisc.*?UpdateCityYields\(eIndex\)', sources['CvCity.cpp'], re.S)))
    check('CanMoveInto is per-unit opt-in', 'm_pUnitInfo->IsSendCanMoveIntoEvent()' in sources['CvUnit.cpp'])
    check('Citizen automation task is a no-op', bool(re.search(r'case TASK_SET_AUTOMATED_CITIZENS:\s*break;', sources['CvCity.cpp'])))
    check('Resistance blocks ordinary raw city yields', bool(re.search(r'IsAnarchy\(\) \|\| IsResistance\(\) \|\| IsRazing\(\).*?return 0;', sources['CvCity.cpp'], re.S)))
    check('Resistance blocks purchase-cost legality', bool(re.search(r'if \(bTestPurchaseCost\).*?if \(IsResistance\(\) \|\| IsRazing\(\)\)\s*return false;', sources['CvCity.cpp'], re.S)))
    check('Native city turn decrements resistance before production', bool(re.search(r'DoResistanceTurn\(\);.*?doProduction\(', sources['CvCity.cpp'], re.S)))
    check('CanRaze has a native script protection veto', '"CanRaze", args.get(), bResult' in sources['CvPlayer.cpp'])
    for name, signature in {'PlayerBuilt':'iiiii', 'UnitConverted':'iiiib', 'TileOwnershipChanged':'iiii',
                            'TileImprovementChanged':'iiiiib', 'PlayerDoneTurn':'i', 'DeclareWar':'iib', 'MakePeace':'iib'}.items():
        check('CP event ABI '+name, bool(re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+signature+'"', sources['CustomMods.h'])))
    for name, filename in {'CityCaptureComplete':'CvPlayer.cpp', 'PlayerDoTurn':'CvPlayer.cpp',
                           'PlayerCityFounded':'CvPlayer.cpp', 'CityCanCreate':'CvCity.cpp',
                           'CityCanMaintain':'CvCity.cpp', 'SetPopulation':'CvCity.cpp'}.items():
        check('Native event call '+name, '"'+name+'"' in sources[filename])
    report = {'official_commit': COMMIT, 'dll_version': 151,
              'scope': 'source availability/ABI assertions; NOT launched-game verification',
              'passed_assertions': len(checks), 'checks': checks,
              'sources': {p: {'url': BASE+p, 'sha256': hashlib.sha256((args.source/Path(p).name).read_bytes()).hexdigest()} for p in FILES}}
    (ROOT/'TheBoundlessCity/docs/SourceAudit.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
    print(f'PASS {len(checks)} pinned CP v151 source assertions ({COMMIT})')


if __name__ == '__main__':
    main()
