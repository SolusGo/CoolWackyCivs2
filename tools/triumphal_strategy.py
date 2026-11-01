"""Append one strategy record and generate ONLY its guide plus shared indexes.

Never regenerate or modify another civilization's SQL or guide.
"""
import json
from generate_triumphal import R,CIV,LEADER
from generate_strategy_guides import render_sql,render_markdown,render_index,render_matchups,write

def main():
    path=R/'docs/StrategyGuides.json';data=json.loads(path.read_text(encoding='utf-8'))
    record={
      'folder':'TheTriumphalImperium','repo':'CoolWackyCivs2','civ':CIV,
      'name':'The Triumphal Imperium','leader':LEADER,'leader_name':'Imperator Aurelion',
      'civ_prefix':'TXT_KEY_TRI_CIV5','civ_pedia':'TXT_KEY_TRI_CIV_PEDIA',
      'leader_prefix':'TXT_KEY_TRI_AURELION','leader_pedia':'TXT_KEY_TRI_LEADER_PEDIA',
      'description_key':'TXT_KEY_TRI_CIV','short_key':'TXT_KEY_TRI_SHORT','leader_name_key':'TXT_KEY_TRI_LEADER',
      'sources':['TheTriumphalImperium/README.md','TheTriumphalImperium/SQL/00_TRI_Core.sql',
                 'TheTriumphalImperium/SQL/01_TRI_Inheritance.sql','TheTriumphalImperium/SQL/02_TRI_Effects.sql',
                 'TheTriumphalImperium/Lua/TRI_Gameplay.lua','TheTriumphalImperium/Lua/TRI_Bonuses.lua'],
      'role':'Victory-fed military strength and mobilisation that fade during quiet campaigns',
      'victory':'Domination',
      'plan':'Prepare a sustainable army, then chain major-civilization combat victories. Momentum starts at 0, caps at 6 and grants +2% military Strength and +4% military Production per point. A complete owner-turn cycle without a qualifying victory loses 1. Defensive victories between your turns also count.',
      'opening':'Secure Food, Production, Iron and normal research. Build or acquire a Hall of Triumphs for Barracks experience and +1 Culture. The civilization has no unearned empire Momentum bonus: choose the first war for achievable kills rather than expecting the laurel to win it.',
      'development':'Support Unbroken with ranged units and replacements. They retain the active Swordsman balance and gain a permanent +10% attacking bonus. At 4 Momentum original Unbroken gain +1 Movement and Hall cities gain +10% military Production. A major conquest gives +2 Momentum once per city site and a Hall after Bronze Working.',
      'finish':'Use high Momentum to replace losses and exploit decisive openings. At 6 the empire has +12% military Strength and +24% military Production; a Hall adds 10 percentage points locally. Upgrade experienced Unbroken to preserve their attack promotion, while accounting for the loss of their original-type temporary movement.',
      'strengths':['Offensive, defensive, ranged, naval and air combat kills against major military units can sustain Momentum.',
                   'Earned strength and native military Production reinforce successive successful campaigns.',
                   'Captured cities receive the actual Hall once Bronze Working is known, including puppets.'],
      'weaknesses':['The economy, strategic resources, Happiness and technology obey normal rules.',
                    'Quiet or unsuccessful cycles decay Momentum and can switch both threshold abilities off.',
                    'Barbarian, City-State and civilian deaths cannot build the engine.'],
      'counterplay':['Protect exposed units and withdraw damaged armies to deny easy combat kills.',
                    'Force pauses, threaten supply routes and exploit the loss of March below 4 Momentum.',
                    'Use terrain and coordinated fire; the earned strength cap is only +12%, not permanent growth.'],
      'mistakes':['Starting a war before assembling the units and resources to earn the first victories.',
                  'Treating the temporary extra Movement as an immediate movement refill.',
                  'Expecting repeated recaptures of one city to grant unlimited conquest Momentum.'],
      'limits':'Each captured city site grants conquest Momentum once per Imperium player; recaptures still refresh victory activity and Hall eligibility. Movement activation does not refill moves. Owner-start decay uses the native PlayerDoTurn boundary, after the preceding cycle production settles. Source/database and Lua-mock checks are separate from native in-game acceptance.',
      'favourable':[['TheConicalUnion','An exposed network of secondary cities can offer distinct conquest targets; secured connections still support a normal defense.'],
                    ['TheLanternFleet','Capturing accessible coastal cities can establish new training centers, but naval defenders can deny safe landings.']],
      'unfavourable':[['TheLaureateCommonwealth','A prepared defender that finishes wounded units can trade efficiently and deny a sustained imperial offensive.'],
                      ['TheThresholdCourt','Paid doorway reinforcement can make isolated city targets less vulnerable than they first appear.']]
    }
    data['civilizations']=[c for c in data['civilizations'] if c['folder']!=record['folder']]+[record]
    data['opponents'][record['folder']]={'name':record['name'],'repo':record['repo']}
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    write(R/'TheTriumphalImperium/SQL/90_PlayerGuide.sql',render_sql(record,data['opponents']))
    write(R/'docs/strategy/TheTriumphalImperium.md',render_markdown(record,data['opponents']))
    write(R/'docs/StrategyGuide.md',render_index(data));write(R/'docs/Matchups.md',render_matchups(data))
    print('Added Imperium guide and indexes; no existing civilization files regenerated')

if __name__=='__main__':main()
