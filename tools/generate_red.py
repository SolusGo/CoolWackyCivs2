"""Trainer Red: schema-derived BNW / CP v151 database and localization."""
from pathlib import Path
from database import database
from generate_database import clone as _clone, companions as _companions

R=Path(__file__).resolve().parents[1]
V=R/'TrainerRed'
CIV='CIVILIZATION_RED_INDIGO_CHAMPION'
LEADER='LEADER_RED_TRAINER'
def clone(*a,**k): return _clone(*a,**k).replace('BCClone','REDClone')
def companions(d,prefix,*a,**k):
 # Copy gameplay companion tables, not another civilization's optional JFD
 # cultural/colonial metadata. The collection guards its two legacy metadata tables.
 if prefix=='Civilization_':
  optional=tuple(r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table' AND (name GLOB 'Civilization_JFD_*' OR name IN ('Civilization_FreePolicies','Civilization_DisableTechs'))"))
  k['skip']=tuple(k.get('skip',()))+optional
 return _companions(d,prefix,*a,**k).replace('BCCompanion','REDCompanion')
def value(x): return str(x) if isinstance(x,(int,float)) else "'"+x.replace("'","''")+"'"
def insert(table,**fields): return 'INSERT INTO '+table+'('+','.join(fields)+') VALUES ('+','.join(map(value,fields.values()))+');\n'

TEXT={
 'CIV':'The Indigo Champion','SHORT':'Indigo Champion','ADJECTIVE':'Indigo',
 'LEADER':'Trainer Red','TITLE':'The Silent Champion','TRAIT':'The Living Legend',
 'TRAIT_HELP':'Train irreplaceable military partners through battle. Champion Team capacity grows from 2 to 6. Defeat the strongest fielded unit types for Culture and Science; capture original capitals for Ribbons. In the Modern Era, send four or more Champions, including a Legendary unit, to Mt. Silver. They return as Summit-Trained legends after eight Standard-speed turns. Open Champion Team for Training, Ace bonds and explicit actions.',
 'CIV_PEDIA':'Pallet Town is a quiet beginning for an extraordinary journey. Across Kanto, Red challenged Gym Leaders, overcame his rival and earned the title of Champion. The Indigo Champion represents the discipline that outlasted those victories: a small team raised with patience, loyalty and trust.[NEWLINE][NEWLINE]After conquering the League, Red left public life for Mt. Silver. Far above the roads that had carried him to fame, the Champion became the silent measure against which every challenger would be tested.',
 'LEADER_PEDIA':'Red rarely needs words. From his first steps beyond Pallet Town to his final vigil on Mt. Silver, his answer to uncertainty has been practice. His companions are partners, never disposable soldiers. In Gold, Silver, Crystal, HeartGold and SoulSilver, the summit encounter reveals what that persistence has made of the young trainer: the final challenge awaiting those who thought their journey complete.',
 'STRATEGY':'Protect your veterans. Fight worthy opponents, heal in Pallet Town and build Indigo Plateau to assemble a six-member team. Pokémon Centers sustain the army; Pokémon Aces strengthen individual partners. Keep your empire safe during the Journey to Mt. Silver. On their return, use each identity to support the others. Domination is preferred, with Science as a strong alternative.',
 'DAWN':'From the quiet paths of Pallet Town, a young trainer set forth with a dream and a faithful companion. Across Kanto he travelled, challenging leaders, defeating rivals and overcoming the greatest trainers of his generation.[NEWLINE][NEWLINE]He became Champion, yet a title could not define him. Leaving fame behind, he ascended the frozen heights of Mt. Silver. There he trained in silence, until the boy from Pallet Town had become a legend.[NEWLINE][NEWLINE]And now, Red, the world awaits your return. Will you once more become the very best?',
 'ACE':'Pokémon Ace','ACE_HELP':'Great General replacement with 3 Movement. Retains the normal aura and Citadel actions while detached. Attach to an adjacent military unit for +15% Combat Strength, +50% combat Training, 5 HP each turn and Battle Item. A bonded team member uses 90% Training thresholds and gains +1 Sight at Legendary. Detach in friendly territory.',
 'ACE_PEDIA':'Some trainers follow Red for the trophies he earned. The finest follow him for the care he gives his partners. A Pokémon Ace offers patient instruction and a steady hand when a veteran faces its hardest battle. Attachment withdraws the trainer from the map until the bond is ended.',
 'CENTER':'Pokémon Center','CENTER_HELP':'Hospital replacement at Biology. Same Production cost; 4 Gold maintenance. +5 Food, 25% Food retained, +5 city healing. Healing military units in its owned three-tile territory recover 15 extra HP. Team members stationed here gain 3 Training per Standard-speed turn, capped at 65. Newly trained military units start with 15 Training. Upgrading here refunds 25% of the paid upgrade price. One explicit airlift departure per city per turn between legal airlift cities.',
 'CENTER_PEDIA':'A journey continues because someone opens the door when its travellers are tired. The Pokémon Center gives Red\'s partners a place to recover, and young trainers a place to learn that strength begins with care.',
 'PLATEAU':'Indigo Plateau','PLATEAU_HELP':'Heroic Epic replacement; inherits Barracks and national-wonder requirements. +15% military Production and Morale for trained units. Unlocks six team slots. Team members beginning turns in the capital gain 2 Training. The capital gains 1 Culture and Science per team rank (0–4). Each first rival original capital adds 2 Culture, 2 Science and 1 Happiness here, to five captures.',
 'PLATEAU_PEDIA':'Beyond Victory Road stands a place where preparation is tested and a trainer\'s companions become a team. Indigo Plateau remembers every hard-earned victory. Its Hall of Fame honours the partners who were there, rather than those who joined afterwards.',
 'JOURNEY':'Journey to Mt. Silver','JOURNEY_HELP':'One-time project: Modern Era, four living team members and one Legendary partner. Cost is 65% of the active Statue of Liberty baseline, scaled by native project speed. Withdraws the current team for eight Standard-speed turns; all cities suffer -10% Gold and Production. Returning veterans upgrade freely along available legal lines, become Legendary and Summit-Trained, and receive distinct Pokémon identities. Never creates replacement partners.',
 'JOURNEY_PEDIA':'The Champion leaves the applause behind. Snow erases the path to Mt. Silver, and the world wonders whether Red will ever return. His companions know: the journey was never finished.',
 'VANISHED':'Red has vanished from public life. Rumours place the former Champion atop Mt. Silver.',
 'RETURN_TITLE':'The Legend Has Returned',
 'RETURN':'Red has returned from the summit.[NEWLINE][NEWLINE]No proclamation announces his arrival. No great army marches beneath his banner. Only six companions stand at his side.[NEWLINE][NEWLINE]Those who would claim the title of greatest must now challenge the legend himself.',
 'TEAM':'Champion Team','TRAINING':'Pokémon Training','TRAINING_HELP':'Kills +10; surviving an opponent with at least 15% greater base strength +5; city captures +15; camps +8; ending damaged in the capital +2. Ranks replace one another at 0/15/35/65/100. Only Proven has +5 whenever healed; only Champion has +1 Movement. Legendary heals 10 after an attacking kill.',
 'TEAM_HELP':'Up to six Champion-rank non-air partners. +25% combat experience, cannot be captured, and heal 5 when another partner wins within three tiles. Initial capacity 2; Classical 3; Medieval 4; first national wonder 6. Dead partners are never restored.',
 'CAUGHT':'Caught','CAUGHT_HELP':'0 Training. No combat bonus.',
 'TRAINED':'Trained','TRAINED_HELP':'15 Training. +5% Combat Strength.',
 'PROVEN':'Proven','PROVEN_HELP':'35 Training. +10% Combat Strength; +5 HP whenever healed.',
 'CHAMPION':'Champion','CHAMPION_HELP':'65 Training. +15% Combat Strength; +1 Movement.',
 'LEGENDARY':'Legendary','LEGENDARY_HELP':'100 Training. +20% Combat Strength; heal 10 after attacking and defeating a unit.',
 'RIBBON':'Champion Ribbon','RIBBON_HELP':'+3% Combat Strength per Ribbon, at most five. Earned by current team members on each first rival original-capital capture.',
 'SUMMIT':'Summit-Trained','SUMMIT_HELP':'+15% Combat Strength, +10 maximum HP, ignore enemy Zone of Control, heal 10 after a kill, generate no additional combat War Weariness, and move after attacking with movement remaining.',
 'BOND':'Trainer Bond','BOND_HELP':'+15% Combat Strength, +50% combat Training, 5 HP each turn, Battle Item. Team rank thresholds reduced by 10%.',
 'PIKACHU':'Pikachu — Partner Above All','PIKACHU_HELP':'+2 Movement; +25% strength against stronger base opponents. Attacks against full-health units deal 10 extra damage. A lethal melee attack can be evaded to a legal nearby tile once per five Standard-speed turns.',
 'CHARIZARD':'Charizard — Blazing Ace','CHARIZARD_HELP':'+1 Range for ranged units without another range bonus, +25% attack against cities and fortified units, ignore terrain movement costs. Attacks splash 5 damage onto enemies adjacent to the target. A melee partner retains melee attacks.',
 'BLASTOISE':'Blastoise — Unbreakable Torrent','BLASTOISE_HELP':'+25% Defence, 25% less incoming ranged damage. If alive after melee defence, retaliate for 10 damage. Can fortify immediately after attacking where supported.',
 'VENUSAUR':'Venusaur — Ancient Bloom','VENUSAUR_HELP':'At your turn start, adjacent friends heal 10 HP. Enemies starting adjacent suffer -15% Combat Strength and -1 Movement for that turn. +25% strength in Forest and Jungle. Effects do not stack.',
 'SNORLAX':'Snorlax — The Sleeping Mountain','SNORLAX_HELP':'+40% Defence while fortified, 15 HP healing per fortified turn, maximum 1 Movement. Resists displacement and stops land movement between adjacent tiles even through normal Zone of Control immunity. See engine limits for third-party forced movement.',
 'LAPRAS':'Lapras — Across Every Horizon','LAPRAS_HELP':'Ocean access for naval partners; amphibious and safe embarkation for land partners. +1 Range without another range bonus. Friends embarked within two tiles gain +1 Movement and +15% Defence. +25% damage against naval or embarked targets.',
 'BLOOM_STATUS':'Ancient Bloom','BLOOM_STATUS_HELP':'-15% Combat Strength and -1 Movement this turn. Applied once when starting next to enemy Venusaur; removable by Battle Item.',
 'HORIZON':'Across Every Horizon','HORIZON_HELP':'Embarked near friendly Lapras: +1 Movement and +15% Defence.',
 'INTERNAL':'The Living Legend','INTERNAL_HELP':'Automatically maintained civilization effect.',
 'PANEL_HELP':'Select a partner or candidate, then use explicit actions. Attach requires a nearby Ace; detach requires friendly territory. Battle Item cannot follow an attack. Airlift cycles legal destinations with the destination button. Rendering this panel never changes gameplay.',
 'SELECT':'Select','ASSIGN':'Assign selected candidate','DETAILS':'Inspect','ATTACH':'Attach Ace','DETACH':'Detach Ace','ITEM':'Battle Item','AIRLIFT':'Airlift selected unit','DESTINATION':'Destination','CANDIDATE':'Next eligible unit','CLOSE':'Close',
 'SILENT_1':'...','GREETING_1':'... [Red silently adjusts his cap.]',
 'CIV5_HEADING_1':'From Pallet Town to the Summit','CIV5_TEXT_1':'',
 'TRAINER_NAME':'Trainer Red','TRAINER_SUBTITLE':'The Silent Champion','TRAINER_LIVED':'The Age of the Indigo League','TRAINER_TITLES_1':'Champion','TRAINER_HEADING_1':'A Legend in Silence','TRAINER_TEXT_1':'',
}
TEXT['CIV5_TEXT_1']=TEXT['CIV_PEDIA'];TEXT['TRAINER_TEXT_1']=TEXT['LEADER_PEDIA']
TEXT['TRAINER']=TEXT['LEADER'];TEXT['CIV5']=TEXT['CIV']
CITIES=['Pallet Town','Viridian City','Pewter City','Cerulean City','Vermilion City','Lavender Town','Celadon City','Fuchsia City','Saffron City','Cinnabar Island','Indigo Plateau','Mt. Moon','Rock Tunnel','Safari Zone','Seafoam Islands','Power Plant','Victory Road','Route 22','Pokémon Tower','Mt. Silver']
SPIES=['Blue','Leaf','Chase','Elaine','Ethan','Lyra','Kris','Brendan','May','Lucas']
TEXT.update({f'CITY_{i}':n for i,n in enumerate(CITIES,1)})
TEXT.update({f'SPY_{i}':n for i,n in enumerate(SPIES,1)})

def main():
 d=database();(V/'SQL').mkdir(parents=True,exist_ok=True)
 core="""-- Authoritative CP v151 events; one Red simulation owner, single-player only.
UPDATE CustomModOptions SET Value=1 WHERE Name IN
 ('EVENTS_CITY','EVENTS_NEW_ERA','EVENTS_UNIT_CREATED','EVENTS_UNIT_CONVERTS','EVENTS_UNIT_UPGRADES',
  'EVENTS_PLAYER_TURN','EVENTS_BARBARIANS','EVENTS_BATTLES','EVENTS_BATTLES_DAMAGE',
  'EVENTS_RED_COMBAT','EVENTS_RED_COMBAT_RESULT','EVENTS_RED_COMBAT_ENDED','EVENTS_CITY_AIRLIFT');
INSERT INTO Colors(Type,Red,Green,Blue,Alpha) VALUES
 ('COLOR_RED_CRIMSON',0.68,0.055,0.09,1),('COLOR_RED_SILVER',0.93,0.95,0.97,1);
INSERT INTO PlayerColors(Type,PrimaryColor,SecondaryColor,TextColor) VALUES
 ('PLAYERCOLOR_RED_INDIGO','COLOR_RED_CRIMSON','COLOR_RED_SILVER','COLOR_PLAYER_WHITE_TEXT');
INSERT INTO Traits(Type,Description,ShortDescription) VALUES ('TRAIT_RED_LIVING_LEGEND','TXT_KEY_RED_TRAIT_HELP','TXT_KEY_RED_TRAIT');
"""
 core+=clone('Civilizations','CIVILIZATION_AMERICA',CIV,Description='TXT_KEY_RED_CIV',ShortDescription='TXT_KEY_RED_SHORT',Adjective='TXT_KEY_RED_ADJECTIVE',Civilopedia='TXT_KEY_RED_CIV_PEDIA',CivilopediaTag='TXT_KEY_RED_CIV5',Strategy='TXT_KEY_RED_STRATEGY',DefaultPlayerColor='PLAYERCOLOR_RED_INDIGO',Playable=1,AIPlayable=1,PackageID=None,DawnOfManQuote='TXT_KEY_RED_DAWN',DawnOfManAudio='',DawnOfManImage='RED_Dawn.dds',MapImage='RED_Map.dds',PortraitIndex=0,IconAtlas='RED_CIV_ATLAS',AlphaIconAtlas='RED_ALPHA_ATLAS')
 core+=clone('Leaders','LEADER_WASHINGTON',LEADER,Description='TXT_KEY_RED_LEADER',Civilopedia='TXT_KEY_RED_LEADER_PEDIA',CivilopediaTag='TXT_KEY_RED_TRAINER',PackageID=None,VictoryCompetitiveness=9,WonderCompetitiveness=6,Boldness=8,DiploBalance=4,WarmongerHate=5,DenounceWillingness=2,DoFWillingness=2,Loyalty=9,Forgiveness=3,Meanness=2,Chattiness=0,MinorCivCompetitiveness=3,PortraitIndex=0,IconAtlas='RED_LEADER_ATLAS',ArtDefineTag='RED_LeaderScene.xml')
 core+=insert('Civilization_Leaders',CivilizationType=CIV,LeaderheadType=LEADER)+insert('Leader_Traits',LeaderType=LEADER,TraitType='TRAIT_RED_LIVING_LEGEND')
 for table,old,new,fields in [('Units','UNIT_GREAT_GENERAL','UNIT_RED_POKEMON_ACE',dict(Moves=3,UnitFlagAtlas='RED_FLAG_ATLAS',UnitFlagIconOffset=0)),('Buildings','BUILDING_HOSPITAL','BUILDING_RED_POKEMON_CENTER',dict(PrereqTech='TECH_BIOLOGY',GoldMaintenance=4,FoodKept=25,HealRateChange=5,Airlift=0)),('Buildings','BUILDING_HEROIC_EPIC','BUILDING_RED_INDIGO_PLATEAU',dict(MilitaryProductionModifier=15,TrainedFreePromotion='PROMOTION_MORALE'))]:
  key='ACE' if table=='Units' else 'CENTER' if 'CENTER' in new else 'PLATEAU'
  core+=clone(table,old,new,Description=f'TXT_KEY_RED_{key}',Help=f'TXT_KEY_RED_{key}_HELP',Civilopedia=f'TXT_KEY_RED_{key}_PEDIA',Strategy=f'TXT_KEY_RED_{key}_HELP',IconAtlas='RED_OBJECT_ATLAS',PortraitIndex={'ACE':0,'CENTER':1,'PLATEAU':2}[key],**fields)
 core+=insert('Civilization_UnitClassOverrides',CivilizationType=CIV,UnitClassType='UNITCLASS_GREAT_GENERAL',UnitType='UNIT_RED_POKEMON_ACE')
 for cls,bld in [('HOSPITAL','POKEMON_CENTER'),('HEROIC_EPIC','INDIGO_PLATEAU')]:core+=insert('Civilization_BuildingClassOverrides',CivilizationType=CIV,BuildingClassType='BUILDINGCLASS_'+cls,BuildingType='BUILDING_RED_'+bld)
 inherit=''
 for table,col,old,new in [('Civilization_','CivilizationType','CIVILIZATION_AMERICA',CIV),('Leader_','LeaderType','LEADER_WASHINGTON',LEADER),('Unit_','UnitType','UNIT_GREAT_GENERAL','UNIT_RED_POKEMON_ACE'),('Building_','BuildingType','BUILDING_HOSPITAL','BUILDING_RED_POKEMON_CENTER'),('Building_','BuildingType','BUILDING_HEROIC_EPIC','BUILDING_RED_INDIGO_PLATEAU')]:
  inherit+=companions(d,table,col,old,new,skip=('Civilization_Leaders','Civilization_UnitClassOverrides','Civilization_BuildingClassOverrides','Civilization_CityNames','Civilization_SpyNames','Leader_Traits'))
 effects="""DELETE FROM Building_YieldChanges WHERE BuildingType='BUILDING_RED_POKEMON_CENTER' AND YieldType='YIELD_FOOD';
INSERT INTO Building_YieldChanges VALUES ('BUILDING_RED_POKEMON_CENTER','YIELD_FOOD',5);
-- Native CanAirlift performs plot, movement, enemy adjacency and city checks.
-- The per-source-city allowance is gated by CityCanAirlift and explicit commands.
UPDATE Buildings SET Airlift=0 WHERE Type='BUILDING_RED_POKEMON_CENTER';
"""
 for i in range(1,len(CITIES)+1):effects+=insert('Civilization_CityNames',CivilizationType=CIV,CityName=f'TXT_KEY_RED_CITY_{i}')
 for i in range(1,len(SPIES)+1):effects+=insert('Civilization_SpyNames',CivilizationType=CIV,SpyName=f'TXT_KEY_RED_SPY_{i}')
 # Modern Statue of Liberty baseline, resolved at activation after other balance mods.
 effects+="""INSERT INTO Projects(Type,Description,Help,Civilopedia,Strategy,MaxGlobalInstances,MaxTeamInstances,Cost,TechPrereq,PortraitIndex,IconAtlas)
SELECT 'PROJECT_RED_MT_SILVER','TXT_KEY_RED_JOURNEY','TXT_KEY_RED_JOURNEY_HELP','TXT_KEY_RED_JOURNEY_PEDIA','TXT_KEY_RED_JOURNEY_HELP',-1,-1,CAST(Cost*0.65+0.5 AS INTEGER),NULL,3,'RED_OBJECT_ATLAS' FROM Buildings WHERE Type='BUILDING_STATUE_OF_LIBERTY';
"""
 flavors={'OFFENSE':7,'DEFENSE':9,'CITY_DEFENSE':9,'MILITARY_TRAINING':10,'RECON':7,'DIPLOMACY':3,'EXPANSION':4,'SCIENCE':8,'CULTURE':5,'GOLD':5,'WONDER':6,'SPACESHIP':8,'GROWTH':5,'MOBILE':7,'AIR':6}
 for name,n in flavors.items():effects+=f"DELETE FROM Leader_Flavors WHERE LeaderType='{LEADER}' AND FlavorType='FLAVOR_{name}';\nINSERT INTO Leader_Flavors SELECT '{LEADER}',Type,{n} FROM Flavors WHERE Type='FLAVOR_{name}';\n"
 for obj,flav,n in [('BUILDING_RED_INDIGO_PLATEAU','MILITARY_TRAINING',50),('BUILDING_RED_POKEMON_CENTER','DEFENSE',15)]:effects+=insert('Building_Flavors',BuildingType=obj,FlavorType='FLAVOR_'+flav,Flavor=n)
 effects+=insert('Project_Flavors',ProjectType='PROJECT_RED_MT_SILVER',FlavorType='FLAVOR_MILITARY_TRAINING',Flavor=80)
 # Every response category uses silence, with a single stage direction at first greeting.
 responses=[r[0] for r in d.execute('SELECT DISTINCT ResponseType FROM Diplomacy_Responses')]
 for response in responses:effects+=insert('Diplomacy_Responses',LeaderType=LEADER,ResponseType=response,Response='TXT_KEY_RED_'+('GREETING_%' if response=='RESPONSE_FIRST_GREETING' else 'SILENT_%'),Bias=1)
 # Active Washington soundtrack definitions are inherited. No commercial audio is distributed.
 promotions={
 'CAUGHT':{},'TRAINED':dict(CombatPercent=5),'PROVEN':dict(CombatPercent=10),'CHAMPION':dict(CombatPercent=15,MovesChange=1),'LEGENDARY':dict(CombatPercent=20),
 'TEAM':dict(CannotBeCaptured=1,ExperiencePercent=25),'BOND':dict(CombatPercent=15),'SUMMIT':dict(CombatPercent=15,MaxHitPointsChange=10,IgnoreZOC=1,CanMoveAfterAttacking=1),
 'PIKACHU':dict(MovesChange=2),'CHARIZARD':dict(CityAttack=25,AttackFortifiedMod=25,IgnoreTerrainCost=1),'BLASTOISE':dict(DefenseMod=25),'VENUSAUR':{},'SNORLAX':dict(FortifiedModifier=40),'LAPRAS':dict(Amphib=1,AllowsEmbarkation=1,EmbarkedAllWater=1),
 'BLOOM_STATUS':dict(CombatPercent=-15,MovesChange=-1),'HORIZON':dict(MovesChange=1,EmbarkDefenseModifier=15),
 'BOND_SIGHT':dict(VisibilityChange=1),'RANGE':dict(RangeChange=1),'PIKACHU_STRONGER':dict(CombatPercent=25),'LAPRAS_OCEAN':dict(CanCrossOceans=1),'BLASTOISE_FORTIFY':dict(DefenseMod=20),
 }
 promo=''
 for i,(name,fields) in enumerate(promotions.items()):
  visible=name in TEXT
  promo+=insert('UnitPromotions',Type='PROMOTION_RED_'+name,Description='TXT_KEY_RED_'+(name if visible else 'INTERNAL'),Help='TXT_KEY_RED_'+(name+'_HELP' if visible else 'INTERNAL_HELP'),CannotBeChosen=1,LostWithUpgrade=0,PortraitIndex=i,IconAtlas='RED_PROMOTION_ATLAS',PediaType='PEDIA_ATTRIBUTES',PediaEntry='TXT_KEY_RED_'+(name if visible else 'INTERNAL'),**fields)
 for i in range(1,6):promo+=insert('UnitPromotions',Type=f'PROMOTION_RED_RIBBON_{i}',Description='TXT_KEY_RED_RIBBON',Help='TXT_KEY_RED_RIBBON_HELP',CombatPercent=3*i,CannotBeChosen=1,LostWithUpgrade=0,PortraitIndex=5,IconAtlas='RED_PROMOTION_ATLAS',PediaType='PEDIA_ATTRIBUTES',PediaEntry='TXT_KEY_RED_RIBBON')
 for i in range(1,33):promo+=insert('UnitPromotions',Type=f'PROMOTION_RED_SNORLAX_LIMIT_{i}',Description='TXT_KEY_RED_SNORLAX',Help='TXT_KEY_RED_SNORLAX_HELP',MovesChange=-i,CannotBeChosen=1,LostWithUpgrade=0,PortraitIndex=12,IconAtlas='RED_PROMOTION_ATLAS')
 for feature in ['FOREST','JUNGLE']:promo+=insert('UnitPromotions_Features',PromotionType='PROMOTION_RED_VENUSAUR',FeatureType='FEATURE_'+feature,Attack=25,Defense=25)
 # Binary dummy buildings are set to 0/1, never accumulated.
 for name,bits in [('RANK',5),('HALL',3),('ABSENCE',1)]:
  for bit in range(bits):
   suffix=name+'_'+str(bit);b='BUILDING_RED_'+suffix
   effects+=insert('BuildingClasses',Type='BUILDINGCLASS_RED_'+suffix,DefaultBuilding=b,Description='TXT_KEY_RED_INTERNAL')
   effects+=insert('Buildings',Type=b,BuildingClass='BUILDINGCLASS_RED_'+suffix,Description='TXT_KEY_RED_INTERNAL',Help='TXT_KEY_RED_INTERNAL_HELP',Cost=-1,FaithCost=-1,GreatWorkCount=-1,NeverCapture=1,NukeImmune=1,ConquestProb=0,IsDummy=1,ShowInPedia=0,IconAtlas='RED_OBJECT_ATLAS',PortraitIndex=2,**({'Happiness':2**bit} if name=='HALL' else {}))
   for y in (['GOLD','PRODUCTION'] if name=='ABSENCE' else ['CULTURE','SCIENCE']):effects+=insert('Building_YieldModifiers' if name=='ABSENCE' else 'Building_YieldChanges',BuildingType=b,YieldType='YIELD_'+y,Yield=-10 if name=='ABSENCE' else 2**bit*(2 if name=='HALL' else 1))
 art=''
 for atlas,stem,cols,rows in [('CIV','Icon',1,1),('ALPHA','Alpha',1,1),('OBJECT','Objects',4,1),('PROMOTION','Promotions',8,4),('IDENTITY','Identities',6,1),('LEADER','Portrait',1,1)]:
  for size in [16,24,32,45,48,64,80,128,256]:art+=insert('IconTextureAtlases',Atlas='RED_'+atlas+'_ATLAS',IconSize=size,Filename=f'RED_{stem}{size}.dds',IconsPerRow=cols,IconsPerColumn=rows)
 art+=insert('IconTextureAtlases',Atlas='RED_FLAG_ATLAS',IconSize=32,Filename='RED_Flag32.dds',IconsPerRow=1,IconsPerColumn=1)
 text=''.join(insert('Language_en_US',Tag='TXT_KEY_RED_'+k,Text=v).replace('INSERT INTO','INSERT OR REPLACE INTO',1) for k,v in sorted(TEXT.items()))
 for name,body in [('00_RED_Core',core),('01_RED_Inheritance',inherit),('02_RED_Effects',effects),('03_RED_Promotions',promo),('04_RED_Art',art),('10_RED_Text',text)]: (V/'SQL'/(name+'.sql')).write_text(body,encoding='utf-8',newline='\n')
 print('Generated Red SQL:',len(TEXT),'localizations,',len(promotions)+5,'promotions')

if __name__=='__main__':main()
