"""Register Covenant documentation; regenerate only its overlay and shared indexes."""
import json
from generate_strategy_guides import ROOT, render_sql, render_markdown, render_index, render_matchups, write


def main():
    path = ROOT / 'docs/StrategyGuides.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    record = {
        'folder': 'TheCovenant', 'repo': 'CoolWackyCivs2', 'civ': 'CIVILIZATION_COVENANT_MEMORY',
        'name': 'The Covenant', 'leader': 'LEADER_COVENANT_SCRIBE', 'leader_name': 'The Scribe',
        'civ_prefix': 'TXT_KEY_CIV5_COVENANT', 'civ_pedia': 'TXT_KEY_COVENANT_PEDIA',
        'leader_prefix': 'TXT_KEY_CIVILOPEDIA_LEADERS_COVENANT', 'leader_pedia': 'TXT_KEY_COVENANT_LEADER_PEDIA',
        'description_key': 'TXT_KEY_COVENANT_DESC', 'short_key': 'TXT_KEY_COVENANT_SHORT',
        'leader_name_key': 'TXT_KEY_COVENANT_LEADER',
        'sources': ['TheCovenant/README.md', 'TheCovenant/Lua/CovenantMemory.lua',
                    'TheCovenant/UI/CovenantGate.lua', 'TheCovenant/SQL/00_COVENANT_Core.sql'],
        'role': 'Mandatory Scripture recall with a conventional Faith and Culture economy',
        'victory': 'Culture or a protected research economy',
        'plan': 'Protect population, production and borders while learning five passages. Written on the Heart adds +1 Culture per city. An unaided review earns 10 Faith and 5 Culture multiplied by the era index plus one, at most once per game turn, including examinations.',
        'opening': 'Recall Revelation before moving starting units. Study its five numbered sections aloud, hide the text, then enter the reference and every section in order. The next four introductions cover the remaining passages. Settle, explore and defend normally; a Scriptorium supplies 2 Faith and 1 Culture.',
        'development': 'Tabernacles supply 3 Faith and 1 Science with the Temple cost, technology, maintenance and prerequisite building classes. Recall rewards supplement infrastructure. Successful unaided reviews expand intervals to 2, 4, 8 and 12 turns; at most one ordinary review occurs per turn.',
        'finish': 'Use religious and cultural development for normal victory routes. Every tenth campaign turn requires all five passages in rotating order. Three consecutive unaided reviews mark mastery, but mastered passages remain in the review schedule. A failed or studied attempt resets that passage streak.',
        'strengths': ['Frequent retrieval practice links references, exact wording and repeated reviews.',
                      'City Culture and early religious buildings support gradual economic development.',
                      'Successful unaided recall converts memory practice into useful era-scaled yields.'],
        'weaknesses': ['Mandatory recall interrupts play and provides no skip button.',
                       'Mistakes or studying forfeit that passage reward and shorten review spacing.',
                       'The civilization has no unique military unit or special combat advantage.'],
        'counterplay': ['Pressure infrastructure and deny safe growth with ordinary military and diplomatic tools.',
                        'Protect exposed borders rather than treating memory rewards as military strength.',
                        'Compare sustained city yields and conventional research against individual recall payouts.'],
        'mistakes': ['Recognising the displayed passage without rehearsing its reference and exact words.',
                     'Neglecting defense or population while concentrating exclusively on Faith generation.',
                     'Assuming mastery ends examinations or that each examination passage grants another reward.'],
        'favourable': [['TheRepublicOfPigeons', 'Safe development supports both economies; compare sustained city yields rather than individual recall rewards.'],
                       ['TheChildrenOfTheKingdom', 'Both support religious development, while prayer and Grace remain distinct from Covenant word recall.']],
        'unfavourable': [['TheTriumphalImperium', 'An under-defended border invites military pressure; recall rewards do not counter Victory Momentum.'],
                         ['TheBoundlessCity', 'Compact territorial development can pressure conventional multiple cities; recall yields do not replace workforce infrastructure.']],
        'limits': 'The gate requires manual entry, tolerates case and punctuation in words, and compares reference components separately. Bulk insertion changes are rejected, but clipboard origin cannot be proven from EditBox text changes. Native keyboard dispatch, popup ordering and save-file continuation require in-game acceptance testing. See TheCovenant/docs/Testing.md.'
    }
    data['civilizations'] = [c for c in data['civilizations'] if c['folder'] != record['folder']] + [record]
    data['opponents'][record['folder']] = {'name': record['name'], 'repo': record['repo']}
    write(path, json.dumps(data, ensure_ascii=False, indent=2))
    write(ROOT / 'TheCovenant/SQL/90_PlayerGuide.sql', render_sql(record, data['opponents']))
    write(ROOT / 'docs/strategy/TheCovenant.md', render_markdown(record, data['opponents']))
    write(ROOT / 'docs/StrategyGuide.md', render_index(data))
    write(ROOT / 'docs/Matchups.md', render_matchups(data))
    print('Registered Covenant guide, Civilopedia overlay and shared indexes; other civilization files untouched')


if __name__ == '__main__':
    main()
