"""Render player guides and native Civilopedia chapters from curated strategy data."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
MATCHUP_NOTE = ('Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. '
                'All custom civs are human-only and multiplayer is unsupported; these comparisons are for '
                'theorycraft or explicitly configured scenarios, not ordinary random AI opponents. '
                'General counterplay applies to normal single-player games.')


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + '\n', encoding='utf-8', newline='\n')


def quote(text):
    return "'" + text.replace("'", "''") + "'"


def prefix(c):
    return ('TXT_KEY_CWC2_GUIDE_' if c['repo'].endswith('2') else 'TXT_KEY_CWC_GUIDE_') + c['folder'].upper()


def opponent_link(folder, registry, own_repo):
    other = registry[folder]
    target = (folder + '.md' if other['repo'] == own_repo else
              'https://github.com/SolusGo/' + other['repo'] + '/blob/main/docs/strategy/' + folder + '.md')
    return '[' + other['name'] + '](' + target + ')'


def sections(c, registry):
    bullet = lambda items: '[NEWLINE]'.join('- ' + x for x in items)
    matchups = [MATCHUP_NOTE, 'FAVOURABLE OPPORTUNITIES']
    matchups += [registry[o]['name'] + ': ' + reason for o, reason in c['favourable']]
    matchups += ['THREATS TO RESPECT']
    matchups += [registry[o]['name'] + ': ' + reason for o, reason in c['unfavourable']]
    result = [
        ('Playstyle and victory plan', c['name'] + '[NEWLINE]' + c['role'] + '[NEWLINE]' + c['victory'] + '[NEWLINE][NEWLINE]' + c['plan']),
        ('Opening priorities', c['opening']),
        ('Develop the engine', c['development']),
        ('Convert the advantage', c['finish']),
        ('Strengths', bullet(c['strengths'])),
        ('Weaknesses and costs', bullet(c['weaknesses'])),
        ('How to play against this civilization', bullet(c['counterplay'])),
        ('Common mistakes', bullet(c['mistakes'])),
        ('Matchup examples - conditional analysis', '[NEWLINE][NEWLINE]'.join(matchups)),
    ]
    if c.get('limits'):
        result.append(('Implementation and timing limits', c['limits']))
    return result


def render_sql(c, registry):
    base = prefix(c)
    rows = []
    def put(tag, text):
        rows.append('INSERT OR REPLACE INTO Language_en_US(Tag,Text) VALUES (' + quote(tag) + ',' + quote(text) + ');')
    def copy_text(old, new, fallback):
        put(new, fallback)
        if old:
            rows.append('INSERT OR REPLACE INTO Language_en_US(Tag,Text) SELECT ' + quote(new) + ',Text FROM Language_en_US WHERE Tag=' + quote(old) + ';')
    def old_article(old, new, shift, biography):
        if old:
            # Copy nonchapter leader metadata (NAME, TITLES, LIVED, factoids)
            # separately; put the original sequential lore after the play guide.
            rows.append('INSERT OR REPLACE INTO Language_en_US(Tag,Text) SELECT ' + quote(new) + ' || substr(Tag,' + str(len(old) + 1) + '),Text FROM Language_en_US WHERE (Tag=' + quote(old) + ' OR Tag GLOB ' + quote(old + '_*') + ') AND Tag NOT GLOB ' + quote(old + '_HEADING_*') + ' AND Tag NOT GLOB ' + quote(old + '_TEXT_*') + ';')
            for kind in ['HEADING', 'TEXT']:
                stem = old + '_' + kind + '_'
                rows.append('INSERT OR REPLACE INTO Language_en_US(Tag,Text) SELECT ' + quote(new + '_' + kind + '_') + ' || (CAST(substr(Tag,' + str(len(stem) + 1) + ') AS INTEGER)+' + str(shift) + '),Text FROM Language_en_US WHERE Tag GLOB ' + quote(stem + '[0-9]*') + ';')
        # Some old articles contain only a direct Civilopedia entry. Retain it.
        condition = ('NOT EXISTS (SELECT 1 FROM Language_en_US WHERE Tag=' + quote((old or '') + '_HEADING_1') + ')')
        rows.append('INSERT OR REPLACE INTO Language_en_US(Tag,Text) SELECT ' + quote(new + '_HEADING_' + str(shift + 1)) + ",'Background and history' WHERE " + condition + ';')
        rows.append('INSERT OR REPLACE INTO Language_en_US(Tag,Text) SELECT ' + quote(new + '_TEXT_' + str(shift + 1)) + ',Text FROM Language_en_US WHERE Tag=' + quote(biography) + ' AND ' + condition + ';')
    rows += ['-- Generated from docs/StrategyGuides.json. Presentation metadata only.',
             '-- Original lore and biography remain available after the practical guide.',
             'DELETE FROM Language_en_US WHERE Tag=' + quote(base) + ' OR Tag GLOB ' + quote(base + '_*') + ';']
    guide = sections(c, registry)
    for i, (heading, body) in enumerate(guide, 1):
        put(base + '_CIV_HEADING_' + str(i), heading)
        put(base + '_CIV_TEXT_' + str(i), body)
    copy_text(c['description_key'], base + '_DESCRIPTION', c['name'])
    copy_text(c['short_key'], base + '_SHORT', c['name'])
    copy_text(c['leader_name_key'], base + '_LEADER_DESCRIPTION', c['leader_name'])
    copy_text(c['civ_pedia'], base + '_BACKGROUND', c['plan'])
    copy_text(c['leader_pedia'], base + '_LEADER_BACKGROUND', c['plan'])
    put(base + '_STRATEGY', c['plan'] + '[NEWLINE][NEWLINE]' + c['opening'] + '[NEWLINE][NEWLINE]' + c['development'] + '[NEWLINE][NEWLINE]' + c['finish'])
    old_article(c['civ_prefix'], base + '_CIV', len(guide), base + '_BACKGROUND')
    old_article(c['leader_prefix'], base + '_LEADER', 3, base + '_LEADER_BACKGROUND')
    # Stable fallbacks for incomplete old leader metadata; do not overwrite
    # source-provided subtitles, titles or lived dates when they exist.
    for suffix, text in [('NAME', c['leader_name']), ('SUBTITLE', c['name']), ('LIVED', 'A leader of ' + c['name']), ('TITLES_1', 'Leader of ' + c['name'])]:
        rows.append('INSERT OR IGNORE INTO Language_en_US(Tag,Text) VALUES (' + quote(base + '_LEADER_' + suffix) + ',' + quote(text) + ');')
    for i, (heading, body) in enumerate([guide[0], ('Priorities and decisions', c['opening'] + '[NEWLINE][NEWLINE]' + c['development'] + '[NEWLINE][NEWLINE]' + c['finish']), guide[8]], 1):
        put(base + '_LEADER_HEADING_' + str(i), heading)
        put(base + '_LEADER_TEXT_' + str(i), body)
    rows.append('UPDATE Civilizations SET Description=' + quote(base + '_DESCRIPTION') + ',ShortDescription=' + quote(base + '_SHORT') + ',Civilopedia=' + quote(base + '_BACKGROUND') + ',CivilopediaTag=' + quote(base + '_CIV') + ',Strategy=' + quote(base + '_STRATEGY') + ' WHERE Type=' + quote(c['civ']) + ';')
    rows.append('UPDATE Leaders SET Description=' + quote(base + '_LEADER_DESCRIPTION') + ',Civilopedia=' + quote(base + '_LEADER_BACKGROUND') + ',CivilopediaTag=' + quote(base + '_LEADER') + ' WHERE Type=' + quote(c['leader']) + ';')
    return '\n'.join(rows) + '\n'


def render_markdown(c, registry):
    out = ['# ' + c['name'] + ' - strategy guide', '', '[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../' + c['folder'] + '/README.md)', '',
           '**Leader:** ' + c['leader_name'] + '  ', '**Playstyle:** ' + c['role'] + '  ', '**Suggested victories:** ' + c['victory'], '', c['plan'], '']
    for heading, field in [('Opening priorities', 'opening'), ('Develop the engine', 'development'), ('Convert the advantage', 'finish')]:
        out += ['## ' + heading, '', c[field], '']
    for heading, field in [('Pros', 'strengths'), ('Cons and opportunity costs', 'weaknesses'), ('Playing against this civ', 'counterplay'), ('Common mistakes', 'mistakes')]:
        out += ['## ' + heading, ''] + ['- ' + x for x in c[field]] + ['']
    out += ['## Who pressures whom', '', MATCHUP_NOTE, '', '| Situation | Other civ | Why it matters |', '| --- | --- | --- |']
    for kind, label in [('favourable', 'Opportunity'), ('unfavourable', 'Threat')]:
        for other, reason in c[kind]:
            out.append('| ' + label + ' | ' + opponent_link(other, registry, c['repo']) + ' | ' + reason + ' |')
    if c.get('limits'):
        out += ['', '## Implementation limits', '', c['limits']]
    out += ['', '## Rules and evidence', '', 'Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.', '']
    for source in c['sources']:
        out.append('- [' + source + '](../../' + source + ')')
    out += ['', 'The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.']
    return '\n'.join(out)


def render_index(data):
    out = ['# Player handbook', '', 'Choose a plan, learn the opening, then read the full mechanics when a condition or timing matters. Every civ has its own strengths, costs, counterplay and named matchup examples.', '',
           '[Who pressures whom](Matchups.md) · [Collection and installation](../README.md)', '',
           'All custom civs are human-only. Named custom-civ comparisons are theorycraft/scenario analysis; normal single-player opponents use the ordinary available AI roster. Multiplayer is unsupported. These guides change information and article metadata, not balance or saved progress.', '',
           '| Civilization | Playstyle | Suggested route |', '| --- | --- | --- |']
    for c in data['civilizations']:
        out.append('| [' + c['name'] + '](strategy/' + c['folder'] + '.md) | ' + c['role'] + ' | ' + c['victory'] + ' |')
    out += ['', '## Reading an advantage', '', 'An opportunity names a condition you can exploit. A threat names a timing, resource or position to respect. Neither is an automatic counter or a tested ranking. Start with food, sustainable expansion, defense and a viable treasury; a signature mechanic does not exempt its owner from those costs.', '',
            'For each civ, read Opening priorities, Develop the engine and Convert the advantage in order. Pros and cons explain the tradeoffs; Common mistakes covers the most likely misread rules. Exact values and engine limits remain in the linked full mechanics guides.', '',
            '## In-game reference', '', 'Open Civilopedia and select the civilization or its leader. Practical strategy appears first, followed by the existing lore/biography. Each collection uses unique article keys, preserving independent guide text when both are loaded. English is supplied; other translations are not claimed.', '',
            '## Maintaining the guides', '', 'Edit `docs/StrategyGuides.json`, then run `python tools/generate_strategy_guides.py`. `python tools/validate_strategy_guides.py` checks generated files, complete article chapters, preserved lore and gameplay data. Rebuild the package after regeneration.']
    return '\n'.join(out)


def render_matchups(data):
    registry = data['opponents']
    out = ['# Who pressures whom', '', '[Player handbook](StrategyGuide.md) · [Civilization roster](../README.md)', '', MATCHUP_NOTE, '',
           'These are conditional opportunities and threats, not a tier list. Read the linked guide for the reason and timing. Terrain, technology, preparation and who can act first can reverse the apparent advantage.', '',
           '| Civilization | Opportunities to examine | Threats to respect |', '| --- | --- | --- |']
    for c in data['civilizations']:
        def links(kind):
            return ', '.join(opponent_link(o, registry, c['repo']).replace('](' + o + '.md)', '](strategy/' + o + '.md)') for o, _ in c[kind])
        out.append('| [' + c['name'] + '](strategy/' + c['folder'] + '.md) | ' + links('favourable') + ' | ' + links('unfavourable') + ' |')
    other = 'CoolWackyCivs' if data['collection'].endswith('2') else 'CoolWackyCivs2'
    out += ['', '[Matchups in the other collection](https://github.com/SolusGo/' + other + '/blob/main/docs/Matchups.md)', '',
            '## General counterplay', '',
            '- Burst attackers: protect vulnerable units, delay contact and counterattack after the actual window ends.',
            '- Veteran armies: focus a valuable unit to completion, deny easy kill-healing and attack a different front.',
            '- Trade and connection economies: identify the qualifying origin or bottleneck; disruption follows each system\'s real update timing.',
            '- Concentrated capitals: threaten productive tiles and support, or pursue a conventional victory they cannot answer with local defense alone.',
            '- Peace and construction engines: apply meaningful pressure that forces different spending; avoid feeding their preferred long safe sequence.',
            '- Resource or active-ability economies: create competing demands, observe cooldowns and punish an exhausted reserve.']
    return '\n'.join(out)


def generate(root=ROOT):
    data = json.loads((root / 'docs/StrategyGuides.json').read_text(encoding='utf-8'))
    registry = data['opponents']
    for c in data['civilizations']:
        write(root / c['folder'] / 'SQL/90_PlayerGuide.sql', render_sql(c, registry))
        write(root / 'docs/strategy' / (c['folder'] + '.md'), render_markdown(c, registry))
        readme = root / c['folder'] / 'README.md'
        text = readme.read_text(encoding='utf-8-sig')
        link = '**Player guide:** [Opening, playstyle, pros/cons and matchups](../docs/strategy/' + c['folder'] + '.md).'
        if link not in text:
            first, rest = text.split('\n', 1)
            write(readme, first + '\n\n' + link + '\n' + rest)
        roster = root / 'docs/civilizations' / (c['folder'] + '.md')
        if roster.is_file():
            text = roster.read_text(encoding='utf-8')
            link = '**Strategy:** [Opening, strengths, weaknesses and matchups](../strategy/' + c['folder'] + '.md).'
            if link not in text:
                first, rest = text.split('\n', 1)
                write(roster, first + '\n\n' + link + '\n' + rest)
    write(root / 'docs/StrategyGuide.md', render_index(data))
    write(root / 'docs/Matchups.md', render_matchups(data))
    print('Generated', len(data['civilizations']), 'player guides and civilization/leader Civilopedia overlays')


if __name__ == '__main__':
    generate()
