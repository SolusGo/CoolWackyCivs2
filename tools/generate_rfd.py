"""Generate First Drafts SQL from installed BNW/CP151 schema; clones read live rows."""
from pathlib import Path
from database import database
from generate_database import clone as base_clone, companions as base_companions

R = Path(__file__).resolve().parents[1]
V = R / 'TheRepublicOfFirstDrafts'
CIV = 'CIVILIZATION_RFD_REPUBLIC'
LEADER = 'LEADER_RFD_MARGINALIA'
UNIT = 'UNIT_RFD_INK_MORTAR'
WORKSHOP = 'BUILDING_RFD_REVISION_WORKSHOP'
DUMMIES = [f'BUILDING_RFD_SCIENCE_{i}' for i in range(1, 4)]
CITIES = ['First Edition', 'Second Edition', 'The Red Margin', 'Footnote Harbor',
          'Inkfall', 'Revised Heights', 'The Proofing Grounds', 'Quillhaven',
          'New Appendix', 'Errata', 'The Grand Index', 'Citation Point',
          'Drafting Hall', 'The Unfinished Quarter', "Margin's End",
          'The Printing District', 'Bibliograph', 'Inkspire', 'Final Proof',
          'The Seventeenth Amendment', 'Neverending Manuscript']
TEXT = {
 'CIV': 'The Republic of First Drafts', 'SHORT': 'The Republic of First Drafts',
 'ADJECTIVE': 'First Draft', 'LEADER': 'Editor-in-Chief Marginalia',
 'TRAIT': 'Nothing Is Ever Final',
 'TRAIT_HELP': 'The first time your civilization possesses a new qualifying non-wonder Building Class, gain 12 [ICON_CULTURE] Culture and 20 [ICON_GOLD] Gold (scaled by game speed). Each Building Class can grant this reward only once. Buildings must still be present at the next owner-turn evaluation.',
 'UNIT': 'Ink Mortar',
 'UNIT_HELP': 'Replaces the Catapult. Has +1 Movement and +1 Sight compared to the normal Catapult. Retains normal siege setup requirements, attacks and upgrade paths. The additional Sight is lost on upgrade.',
 'UNIT_STRATEGY': 'Move the Ink Mortar into useful siege positions and use its additional Sight to survey approaches. All normal Catapult combat, setup, resource and attack rules still apply.',
 'UNIT_PEDIA': 'An Ink Mortar launches industrial barrels of black ink with the same mechanical discipline as an ordinary Catapult. Its crews learn to read terrain as carefully as a proofreader reads a manuscript. The ink is a matter of national style; the weapon has no additional city damage, special attack or ink debuff.',
 'WORKSHOP': 'Revision Workshop',
 'WORKSHOP_HELP': 'Replaces the Workshop. Retains its normal benefits and provides +1 [ICON_CULTURE] Culture. Gains +1 [ICON_RESEARCH] Science for every 4 distinct qualifying Building Classes currently present in this city, up to +3 Science. The Revision Workshop counts toward this total.',
 'WORKSHOP_STRATEGY': 'Develop a broad collection of ordinary city institutions. Including the Revision Workshop, 4, 8 and 12 qualifying classes provide 1, 2 and 3 additional Science. Losing buildings can reduce this Science. The additional Culture remains while the Workshop exists.',
 'WORKSHOP_PEDIA': 'The Editorial Department directs the Republic\'s Revision Workshops: government engineering institutions where architects annotate blueprints, scholars examine prototypes and engineers submit the next version. Every existing institution offers another useful design problem. Their Science reflects the city\'s current architectural diversity, independent of the permanent national reward ledger.',
 'CIV_PEDIA': 'The Republic of First Drafts unites writers, architects, engineers, scholars and publishers around one conviction: Nothing Is Ever Final. Its government rewards new institutions and treats experimentation as a civic duty. The Editorial Department preserves revisions rather than pretending that any design is complete.[NEWLINE][NEWLINE]Each qualifying Building Class earns one empire-wide reward of 12 Culture and 20 Gold on Standard speed, rounded individually using the active construction percentage. Possession is checked at PlayerDoTurn; a building removed before this evaluation earns nothing. Production, purchases, gifts, free buildings and captures all count if the qualifying building remains. Unique replacements share their ordinary Building Class. Wonders, the Palace, hidden dummies and nonconstructible special buildings are excluded.[NEWLINE][NEWLINE]The rewarded-class ledger survives losses, reconstruction, recapture and save/load. Revision Workshop Science instead counts CURRENT qualifying classes in that individual city. An existing progressed save with no ledger seeds already-owned classes without retroactive rewards.',
 'LEADER_PEDIA': 'Editor-in-Chief Marginalia governs in an enormous robe embroidered with annotations. Her slightly crooked spectacles have survived seventeen proposed replacements. From a desk buried in unfinished manuscripts she oversees the Editorial Department, accepting revisions from engineers and poets with equal seriousness. Her authority rests on the belief that even the republic itself remains open to improvement.',
 'STRATEGY': 'Intermediate complexity (3/5). Diversify ordinary buildings across your empire for permanent first-class Culture and Gold rewards. Develop individual cities toward 4, 8 and 12 qualifying classes for Revision Workshop Science. Use Ink Mortars for positioning and awareness. Science and Culture are the preferred victories.',
 'DAWN': 'Esteemed Editor-in-Chief Marginalia, First Author of the Republic, your people await your next great revision.[NEWLINE][NEWLINE]Throughout history, civilizations have constructed monuments, established institutions and recorded their achievements for future generations.[NEWLINE][NEWLINE]Yet your people have recognized a fundamental truth.[NEWLINE][NEWLINE]No creation is ever truly complete.[NEWLINE][NEWLINE]Every building can be improved. Every discovery can be reconsidered. Every great work begins with an imperfect first draft.[NEWLINE][NEWLINE]Now, the scattered scholars and architects of your Republic have united beneath a common purpose.[NEWLINE][NEWLINE]Build your cities. Gather your knowledge. Let every new institution become another chapter in the history of your people.[NEWLINE][NEWLINE]Will you write the greatest civilization the world has ever known?[NEWLINE][NEWLINE]Or will history remember you as another unfinished manuscript?',
 'DUMMY': 'Editorial Research', 'DUMMY_HELP': 'Internal Revision Workshop Science. Automatically reconciled; cannot be built, bought or sold.',
 'SIGHT': 'Surveying the Margins', 'SIGHT_HELP': '+1 Sight. Lost on upgrade. Automatically granted to Ink Mortars; cannot be selected.',
 'GREETING_1': 'Welcome, esteemed visitor! Before we begin negotiations, I must ask you to review the seventeen amendments to our preliminary diplomatic introduction.',
 'WAR_1': 'Your civilization has been reviewed. Unfortunately, the editorial board has recommended its complete removal.',
 'DEFEAT_1': 'I see... perhaps... we should have considered another draft.',
 'PEACE_1': 'Let us strike out this unfortunate chapter and begin a fresh page.',
 'PEACE_OFFER_1': 'The board proposes a revision to our present hostilities.',
 'FRIENDLY_1': 'A welcome collaborator! Please, take a seat among the manuscripts.',
 'NEUTRAL_1': 'Your proposal is on the desk. Somewhere beneath the other proposals.',
 'HOSTILE_1': 'I have read your latest actions. The margins are now entirely red.',
 'ATTACKED_1': 'An unsolicited amendment by force? The board rejects it unanimously.',
 'TRADE_1': 'Approved, with only a modest number of footnotes.',
 'CIV5_HEADING_1': 'Nothing Is Ever Final',
 'MARGINALIA_NAME': 'Editor-in-Chief Marginalia', 'MARGINALIA_SUBTITLE': 'First Author of the Republic',
 'MARGINALIA_LIVED': 'The age of continuous revision',
 'MARGINALIA_TITLES_1': 'Editor-in-Chief and Chair of the Editorial Department',
 'MARGINALIA_HEADING_1': 'Authority in the Margins',
}
TEXT.update(CIV5_TEXT_1=TEXT['CIV_PEDIA'], MARGINALIA_TEXT_1=TEXT['LEADER_PEDIA'])
TEXT.update({f'CITY_{i}': name for i, name in enumerate(CITIES, 1)})
TEXT.update({f'SPY_{i}': name for i, name in enumerate([
 'Redactor', 'Footnote', 'Erratum', 'Palimpsest', 'Semicolon', 'Addendum',
 'Proofreader', 'Black Quill', 'Appendix', 'Second Reading'], 1)})


def clone(*args, **kwargs):
    return base_clone(*args, **kwargs).replace('BCClone', 'RFD_Clone')


def companions(*args, **kwargs):
    return base_companions(*args, **kwargs).replace('BCCompanion', 'RFD_Companion')


def main():
    d = database()
    (V / 'SQL').mkdir(parents=True, exist_ok=True)
    core = """-- BNW + CP v151 only. Append after released civilizations to preserve IDs.
UPDATE CustomModOptions SET Value=1 WHERE Name='EVENTS_CITY';
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_RFD_BURGUNDY',0.32,0.035,0.10,1),('COLOR_RFD_CREAM',0.96,0.88,0.67,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_RFD','COLOR_RFD_BURGUNDY','COLOR_RFD_CREAM','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES
 ('TRAIT_RFD_NOTHING_FINAL','TXT_KEY_RFD_TRAIT_HELP','TXT_KEY_RFD_TRAIT');
"""
    core += clone('Civilizations', 'CIVILIZATION_AMERICA', CIV,
        Description='TXT_KEY_RFD_CIV', ShortDescription='TXT_KEY_RFD_SHORT',
        Adjective='TXT_KEY_RFD_ADJECTIVE', Civilopedia='TXT_KEY_RFD_CIV_PEDIA',
        CivilopediaTag='TXT_KEY_RFD_CIV5', Strategy='TXT_KEY_RFD_STRATEGY',
        DefaultPlayerColor='PLAYERCOLOR_RFD', Playable=1, AIPlayable=0, PackageID=None,
        DawnOfManQuote='TXT_KEY_RFD_DAWN', DawnOfManAudio='', DawnOfManImage='RFD_Dawn.dds',
        MapImage='RFD_Map.dds', PortraitIndex=0, IconAtlas='RFD_CIV_ATLAS', AlphaIconAtlas='RFD_ALPHA_ATLAS')
    core += clone('Leaders', 'LEADER_WASHINGTON', LEADER, Description='TXT_KEY_RFD_LEADER',
        Civilopedia='TXT_KEY_RFD_LEADER_PEDIA', CivilopediaTag='TXT_KEY_RFD_MARGINALIA',
        PackageID=None, PortraitIndex=0, IconAtlas='RFD_LEADER_ATLAS', ArtDefineTag='RFD_LeaderScene.xml')
    core += f"INSERT INTO Civilization_Leaders VALUES ('{CIV}','{LEADER}');\nINSERT INTO Leader_Traits VALUES ('{LEADER}','TRAIT_RFD_NOTHING_FINAL');\n"
    core += clone('Units', 'UNIT_CATAPULT', UNIT, Description='TXT_KEY_RFD_UNIT',
        Civilopedia='TXT_KEY_RFD_UNIT_PEDIA', Help='TXT_KEY_RFD_UNIT_HELP', Strategy='TXT_KEY_RFD_UNIT_STRATEGY',
        IconAtlas='RFD_OBJECT_ATLAS', PortraitIndex=1, UnitFlagAtlas='RFD_FLAG_ATLAS', UnitFlagIconOffset=0)
    core += f"UPDATE Units SET Moves=Moves+1 WHERE Type='{UNIT}';\n"
    core += clone('Buildings', 'BUILDING_WORKSHOP', WORKSHOP, Description='TXT_KEY_RFD_WORKSHOP',
        Civilopedia='TXT_KEY_RFD_WORKSHOP_PEDIA', Help='TXT_KEY_RFD_WORKSHOP_HELP', Strategy='TXT_KEY_RFD_WORKSHOP_STRATEGY',
        IconAtlas='RFD_OBJECT_ATLAS', PortraitIndex=0)
    core += f"INSERT INTO Civilization_UnitClassOverrides VALUES ('{CIV}','UNITCLASS_CATAPULT','{UNIT}');\nINSERT INTO Civilization_BuildingClassOverrides VALUES ('{CIV}','BUILDINGCLASS_WORKSHOP','{WORKSHOP}');\n"
    for i in range(1, len(CITIES) + 1):
        core += f"INSERT INTO Civilization_CityNames VALUES ('{CIV}','TXT_KEY_RFD_CITY_{i}');\n"
    for i in range(1, 11):
        core += f"INSERT INTO Civilization_SpyNames VALUES ('{CIV}','TXT_KEY_RFD_SPY_{i}');\n"
    inherit = '-- Active scalar SELECT * clones and every compatible installed companion table.\n'
    for table in ['Civilization_FreeBuildingClasses', 'Civilization_FreeTechs', 'Civilization_FreeUnits']:
        inherit += companions(d, table, 'CivilizationType', 'CIVILIZATION_AMERICA', CIV)
    inherit += companions(d, 'Unit', 'UnitType', 'UNIT_CATAPULT', UNIT)
    inherit += companions(d, 'Building', 'BuildingType', 'BUILDING_WORKSHOP', WORKSHOP)
    effects = f"""INSERT INTO UnitPromotions(Type,Description,Help,CannotBeChosen,LostWithUpgrade,VisibilityChange,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_RFD_INK_MORTAR_SIGHT','TXT_KEY_RFD_SIGHT','TXT_KEY_RFD_SIGHT_HELP',1,1,1,0,'RFD_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_RFD_SIGHT');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('{UNIT}','PROMOTION_RFD_INK_MORTAR_SIGHT');
-- Add to, rather than replace, any inherited Culture.
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE rowid=(SELECT MIN(rowid) FROM Building_YieldChanges WHERE BuildingType='{WORKSHOP}' AND YieldType='YIELD_CULTURE');
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT '{WORKSHOP}','YIELD_CULTURE',1
 WHERE NOT EXISTS (SELECT 1 FROM Building_YieldChanges WHERE BuildingType='{WORKSHOP}' AND YieldType='YIELD_CULTURE');
"""
    for dummy in DUMMIES:
        cls = dummy.replace('BUILDING_', 'BUILDINGCLASS_', 1)
        effects += f"""INSERT INTO BuildingClasses(Type,DefaultBuilding,Description) VALUES ('{cls}','{dummy}','TXT_KEY_RFD_DUMMY');
INSERT INTO Buildings(Type,BuildingClass,Description,Help,Cost,FaithCost,GreatWorkCount,NeverCapture,NukeImmune,IsDummy,ShowInPedia,ConquestProb,IconAtlas,PortraitIndex)
 VALUES ('{dummy}','{cls}','TXT_KEY_RFD_DUMMY','TXT_KEY_RFD_DUMMY_HELP',-1,-1,-1,1,1,1,0,0,'RFD_CIV_ATLAS',0);
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) VALUES ('{dummy}','YIELD_SCIENCE',1);
"""
    for response, key in [('FIRST_GREETING', 'GREETING'), ('DECLAREWAR', 'WAR'), ('DEFEATED', 'DEFEAT'),
        ('PEACE_MADE_BY_HUMAN_GRACIOUS', 'PEACE'), ('PEACE_MADE_BY_HUMAN_UNGRACIOUS', 'PEACE'),
        ('PEACE_OFFER', 'PEACE_OFFER'), ('GREETING_POLITE_HELLO', 'FRIENDLY'),
        ('GREETING_NEUTRAL_HELLO', 'NEUTRAL'), ('GREETING_HOSTILE_HELLO', 'HOSTILE'),
        ('ATTACKED', 'ATTACKED'), ('TRADE_ACCEPT_GENEROUS', 'TRADE')]:
        effects += f"INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('{LEADER}','RESPONSE_{response}','TXT_KEY_RFD_{key}_%',1);\n"
    art = ''
    for atlas, stem, columns in [('CIV', 'Icon', 1), ('ALPHA', 'Alpha', 1), ('OBJECT', 'Objects', 2), ('LEADER', 'Portrait', 1)]:
        for size in [16, 24, 32, 45, 48, 64, 80, 128, 256]:
            art += f"INSERT INTO IconTextureAtlases VALUES ('RFD_{atlas}_ATLAS',{size},'RFD_{stem}{size}.dds',{columns},1);\n"
    art += "INSERT INTO IconTextureAtlases VALUES ('RFD_FLAG_ATLAS',32,'RFD_Flag32.dds',1,1);\n"
    text = ''.join("INSERT INTO Language_en_US(Tag,Text) VALUES ('TXT_KEY_RFD_" + k + "','" + v.replace("'", "''") + "');\n" for k, v in sorted(TEXT.items()))
    for name, content in [('00_RFD_Core', core), ('01_RFD_Inheritance', inherit),
                          ('02_RFD_Effects', effects), ('03_RFD_Art', art), ('10_RFD_Text', text)]:
        (V / 'SQL' / (name + '.sql')).write_text(content, encoding='utf-8', newline='\n')
    print('Generated RFD identity, active Catapult/Workshop inheritance, effects, art registration and text')


if __name__ == '__main__':
    main()
