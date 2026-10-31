"""Audit pinned official CP v151 source. --fetch downloads only into tools/reference."""
from pathlib import Path
import argparse, hashlib, json, re, urllib.request
from validation_prerequisites import PrerequisiteError,require_sources

ROOT = Path(__file__).resolve().parents[1]
COMMIT = '44c1e14ff75d80c1dba5c8a71e8289439a53aafb'
BASE = f'https://raw.githubusercontent.com/LoneGazebo/Community-Patch-DLL/{COMMIT}/CvGameCoreDLL_Expansion2/'
FILES = ['CustomMods.h', 'CvCityCitizens.cpp', 'CvCityCitizens.h', 'CvCity.cpp', 'CvPlayer.cpp',
         'CvPlot.cpp', 'CvUnit.cpp', 'CvUnitCombat.cpp', 'CvUnitMission.cpp', 'CvTeam.cpp',
         'CvBuilderTaskingAI.cpp', 'Lua/CvLuaCity.cpp', 'Lua/CvLuaPlayer.cpp', 'Lua/CvLuaPlot.cpp',
         'Lua/CvLuaUnit.cpp', 'Lua/CvLuaTeam.cpp', 'CvGame.cpp', 'Lua/CvLuaGame.cpp',
         'CvTraitClasses.cpp', 'CvTraitClasses.h', 'CvCultureClasses.cpp', 'CvTradeClasses.cpp', 'CvDllNetMessageHandler.cpp', 'CvBuildingClasses.cpp', 'CvPolicyClasses.cpp',
         'CvPromotionClasses.cpp','CvUnitClasses.cpp','CvMinorCivAI.cpp','CvCity.h','CvCityConnections.cpp',
         'CvPlayerAI.cpp','CvTreasury.cpp','CvGameCoreStructs.cpp','CustomModsGlobal.h','CvBarbarians.cpp',
         'CvGameCoreDLL_Expansion2.vcxproj','CvInfos.cpp']
METHODS = {
 'City': 'GetOwner GetX GetY GetID GetOriginalOwner GetPreviousOwner GetGameTurnFounded IsOriginalCapital '
         'GetPopulation GetAutomatons GetNumCityPlots GetCityIndexPlot IsWorkingPlot IsForcedWorkingPlot '
         'GetSpecialistCount GetTotalSpecialistCount GetExtraSpecialistYieldOfType GetNumBuilding '
         'GetNumRealBuilding SetNumRealBuilding SetName GetJONSCulturePerTurn FoodDifference AlterWorkingPlot '
         'DoTask GetBaseYieldRateFromMisc ChangeBaseYieldRateFromMisc GetBaseYieldRateFromTerrain '
         'ChangeBaseYieldRateFromTerrain IsHolyCityAnyReligion IsRazing GetDamage GetMaxHitPoints GetName '
         'GetResistanceTurns ChangeResistanceTurns IsRevealed RefreshTourism FoodDifferenceTimes100',
 'Player': 'GetCivilizationType GetCapitalCity Cities Units GetNumCities GetScriptData SetScriptData IsHuman '
           'IsAlive IsBarbarian IsMinorCiv GetPlayerToLiberate CanLiberatePlayer CanRaze AcquireCity Disband '
           'IsTurnActive GetCurrentEra GetTeam AddNotification GetUnitByID ChangeJONSCulture GetNumMilitaryUnits '
           'IsEverAlive GetOriginalCapitalPlot GetImprovementUpgradeRate',
 'Plot': 'GetOwner GetX GetY GetPlotIndex GetPlotCity IsCity HasYield IsWater IsVisibleEnemyUnit IsBlockaded '
         'GetYield GetResourceType GetImprovementType IsImprovementPillaged IsVisible GetScriptData SetScriptData '
         'SetOwner GetCityPurchaseID IsBeingWorked IsCoastalLand GetUpgradeProgress ChangeUpgradeProgress '
         'SetImprovementType GetPlayerThatBuiltImprovement',
 'Unit': 'GetUnitType GetID GetX GetY IsHasPromotion SetHasPromotion Kill MovesLeft GetGameTurnCreated IsBusy '
         'IsCombatUnit IsRanged IsEmbarked FinishMoves GeneratePath CanBuild GetPlot PushMission '
         'GetDomainType IsDead IsDelayedDeath IsOnlyDefensive IsOutOfAttacks',
 'Team': 'IsAtWar IsWaterWork',
 'Game': 'GetWinner GetVictory SetWinner IsVictoryValid GetImprovementUpgradeTime',
}

def source_url(path):
    if path=='CustomModsGlobal.h':
        return BASE.rsplit('CvGameCoreDLL_Expansion2/',1)[0]+'CvGameCoreDLLUtil/include/CustomModsGlobal.h'
    return BASE+path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fetch', action='store_true')
    parser.add_argument('--source', type=Path, default=ROOT / 'tools/reference')
    parser.add_argument('--report', type=Path, default=ROOT/'tools/reference/CP-v151-audit.json')
    args = parser.parse_args()
    if args.fetch:
        resolved=args.source.resolve()
        if not any(resolved.is_relative_to(base.resolve()) for base in [ROOT/'tools/reference',ROOT/'dist']):
            parser.error('--fetch output must stay in tools/reference or dist, separate from released assets')
        args.source.mkdir(parents=True, exist_ok=True)
        inventory={}
        for path in FILES:
            try:
                data=urllib.request.urlopen(source_url(path), timeout=30).read()
            except Exception as exc:parser.exit(2,f'Cannot fetch pinned CP source {path}: {exc}. Check network access and retry --fetch.\n')
            target=args.source/Path(path).name;temporary=target.with_suffix(target.suffix+'.download')
            temporary.write_bytes(data);temporary.replace(target)
            inventory[target.name]={'url':source_url(path),'sha256':hashlib.sha256(data).hexdigest()}
        (args.source/'CP-v151-sources.json').write_text(json.dumps({'commit':COMMIT,'files':inventory},indent=2)+'\n',encoding='utf-8',newline='\n')
    try:require_sources([Path(p).name for p in FILES],args.source)
    except PrerequisiteError as exc:parser.exit(2,str(exc)+'\n')
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
    def body(filename, signature):
        source = sources[filename]; start = source.index(signature)
        return source[start:source.index('\n}', start)+2]
    city_turn = body('CvCity.cpp', 'void CvCity::doTurn(')
    player_turn = body('CvPlayer.cpp', 'void CvPlayer::doTurnPostDiplomacy(')
    growth = body('CvCity.cpp', 'void CvCity::doGrowth(')
    check('Native governor optimization precedes city growth', city_turn.index('OptimizeWorkedPlots(false)') < city_turn.index('doGrowth();'))
    check('PlayerDoTurn is after native city economic turns', player_turn.index('pLoopCity->doTurn();') < player_turn.index('"PlayerDoTurn"'))
    check('Growth harvests the ordinary cached Food rate in hundredths', 'int iFoodPerTurn100 = getYieldRateTimes100(YIELD_FOOD);' in growth and 'changeFoodTimes100(iFoodPerTurn100);' in growth)
    check('Food feedback binding reads the native ordinary rate', 'pkCity->getYieldRateTimes100(YIELD_FOOD)' in body('CvLuaCity.cpp', 'int CvLuaCity::lFoodDifferenceTimes100('))
    check('Initial native allocation preserves forced default labourers', 'GetNumDefaultSpecialists() - GetNumForcedDefaultSpecialists()' in body('CvCityCitizens.cpp', 'void CvCityCitizens::DoInitialAssigment('))
    check('Native optimization cannot remove forced default labourers', 'iNumLaborers = max(0, GetNumDefaultSpecialists() - GetNumForcedDefaultSpecialists());' in body('CvCityCitizens.cpp', 'vector<TileChange> CvCityCitizens::GetBestOptionsQuick('))
    check('Native local working changes refresh city rates', 'UpdateAllNonPlotYields(false)' in body('CvCityCitizens.cpp', 'void CvCityCitizens::SetWorkingPlot('))
    alive = body('CvPlayer.cpp', 'void CvPlayer::verifyAlive(')
    check('Zero-city survival uses civilization trait', '!GetPlayerTraits()->IsStaysAliveZeroCities()' in alive)
    check('Zero-city survival cannot bypass no units or max-city-elimination', 'getNumUnits() == 0 ||' in alive and 'getMaxCityElimination() > 0' in alive)
    check('Trait loads native StaysAliveZeroCities column', 'm_bStaysAliveZeroCities = kResults.GetBool("StaysAliveZeroCities")' in sources['CvTraitClasses.cpp'])
    check('Trait aggregation preserves scoped zero-city survival', 'if(trait->IsStaysAliveZeroCities())' in sources['CvTraitClasses.cpp'])
    check('Elimination kills remaining units', 'killUnits();' in body('CvPlayer.cpp', 'void CvPlayer::setAlive('))
    check('Native save serializes survival trait cache', 'visitor(playerTraits.m_bStaysAliveZeroCities)' in sources['CvTraitClasses.cpp'])
    check('Trait read does not rebuild survival from updated SQL', 'InitPlayerTraits' not in body('CvTraitClasses.cpp', 'void CvPlayerTraits::Read('))
    check('Natural policy and technology refresh native traits', 'GetPlayerTraits()->InitPlayerTraits();' in body('CvPlayer.cpp', 'void CvPlayer::processPolicies(') and 'GetPlayerTraits()->InitPlayerTraits();' in sources['CvTeam.cpp'])
    acquire = body('CvPlayer.cpp', 'CvCity* CvPlayer::acquireCity(')
    check('Native acquisition has no pre-acquisition test veto', 'CallTestAll' not in acquire and 'CallTestAny' not in acquire and 'GAMEEVENTINVOKE_TEST' not in acquire)
    check('Native acquisition recognizes reclaimed original capital', 'bRegainedCapital = true' in acquire and 'AddFreeCapitalBuildings(true)' in acquire)
    check('Native acquisition validates displaced units', 'verifyUnitValidPlot' in acquire)
    move = body('CvUnit.cpp', 'bool CvUnit::canMoveInto(')
    check('NoCapture rejection precedes movement Lua hook', move.index('if (isNoCapture())') < move.index('GAMEEVENT_CanMoveInto'))
    raze = body('CvPlayer.cpp', 'bool CvPlayer::canRaze(')
    check('Own-founded rejection precedes all raze vetoes', raze.index('getOriginalOwner() == GetID()') < raze.index('"CanRazeOverride"'))
    check('CanRaze preserves option and unique-civilization luxury rules', 'GAMEOPTION_NO_CITY_RAZING' in raze and 'GetRequiredCivilization() != NO_CIVILIZATION' in raze)
    check('Tourism refresh binding recalculates native tourism source', 'pkCity->UpdateCityYields(YIELD_TOURISM)' in body('CvLuaCity.cpp', 'int CvLuaCity::lRefreshTourism('))
    check('Native Tourism converts terrain Culture once', 'int iFromImprovements = GetBaseYieldRateFromTerrain(YIELD_CULTURE)' in sources['CvCity.cpp'])
    check('Native improvement development is limited to native working array', bool(re.search(r'IsWorkingPlot\(iI\).*?pLoopPlot->doImprovement\(\)', sources['CvCity.cpp'], re.S)))
    check('Native development rate and threshold are plot-specific', 'changeUpgradeProgress(GET_PLAYER(getOwner()).getImprovementUpgradeRate())' in sources['CvPlot.cpp'] and 'getImprovementUpgradeTime(getImprovementType(), this)) * 100' in sources['CvPlot.cpp'])
    check('Worked improvement counters lack exposed mutator', 'ChangeNumImprovementWorked(eImprovement' in sources['CvCityCitizens.cpp'] or 'ChangeNumImprovementWorked(pPlot->getImprovementType()' in sources['CvCityCitizens.cpp'])
    check('City has no Lua worked-counter mutators', not re.search(r'Method\((Change|Set)Num(Terrain|Feature|Improvement)Worked\)', sources['CvLuaCity.cpp']))
    check('New-route hook is a veto', 'GAMEEVENTINVOKE_TESTALL(GAMEEVENT_PlayerCanCreateTradeRoute' in sources['CvTradeClasses.cpp'])
    check('City border selection hook is a veto', 'GAMEEVENTINVOKE_TESTALL(GAMEEVENT_CityCanAcquirePlot' in sources['CvCity.cpp'])
    check('Resistance alone does not universally suppress specialist GPP', 'IsResistance' not in body('CvCityCitizens.cpp', 'int CvCityCitizens::GetSpecialistRate(') and 'IsResistance' not in body('CvCity.cpp', 'int CvCity::getTotalGreatPeopleRateModifier('))
    winner = body('CvGame.cpp', 'void CvGame::setWinner(')
    check('Native winner setter completes replay notification and game state', 'REPLAY_MESSAGE_MAJOR_EVENT' in winner and 'NOTIFICATION_VICTORY' in winner and 'setGameState(GAMESTATE_OVER)' in winner)
    check('Native conquest considers ever-alive original capitals', 'isEverAlive()' in body('CvGame.cpp', 'void CvGame::DoTestConquestVictory('))
    for name, signature in {'PlayerBuilt':'iiiii', 'UnitConverted':'iiiib', 'TileOwnershipChanged':'iiii',
                            'TileImprovementChanged':'iiiiib', 'PlayerDoneTurn':'i', 'DeclareWar':'iib', 'MakePeace':'iib',
                            'PlayerCanCreateTradeRoute':'iiiiii','CityCanAcquirePlot':'iiii'}.items():
        check('CP event ABI '+name, bool(re.search(r'GAMEEVENT_'+name+r'\s+"'+name+r'",\s+"'+signature+'"', sources['CustomMods.h'])))
    for name, filename in {'CityCaptureComplete':'CvPlayer.cpp', 'PlayerDoTurn':'CvPlayer.cpp',
                           'PlayerCityFounded':'CvPlayer.cpp', 'CityCanCreate':'CvCity.cpp',
                           'CityCanMaintain':'CvCity.cpp', 'SetPopulation':'CvCity.cpp'}.items():
        check('Native event call '+name, '"'+name+'"' in sources[filename])
    report = {'official_commit': COMMIT, 'dll_version': 151,
              'scope': 'source availability/ABI assertions; NOT launched-game verification',
              'passed_assertions': len(checks), 'checks': checks,
              'sources': {p: {'url': source_url(p), 'sha256': hashlib.sha256((args.source/Path(p).name).read_bytes()).hexdigest()} for p in FILES}}
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
    print(f'PASS {len(checks)} pinned CP v151 source assertions ({COMMIT})')


if __name__ == '__main__':
    main()
