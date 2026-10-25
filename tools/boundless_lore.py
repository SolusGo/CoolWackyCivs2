"""Compile the shared Markdown setting books into native Civilopedia strings."""
from pathlib import Path
import re

R=Path(__file__).resolve().parents[1]
BOOKS=R/'TheBoundlessCity/Lore'
CIV_PREFIX='TXT_KEY_CIV5_BC'
LEADER_PREFIX='TXT_KEY_CIVILOPEDIA_LEADERS_BC_ARCHITECT'


def game_text(markdown):
    """Our books use paragraphs, quotes and inline emphasis; keep native markup small."""
    paragraphs=[]
    for paragraph in re.split(r'\n\s*\n',markdown.strip()):
        lines=[re.sub(r'^>\s?','',line.strip()) for line in paragraph.splitlines()]
        text=' '.join(lines)
        text=re.sub(r'\[([^\]]+)\]\([^)]+\)',r'\1',text)
        text=text.replace('**','').replace('`','')
        assert '|' not in text,'Literal pipes select localization forms'
        assert '[' not in text and ']' not in text,'Unexpected source markup'
        if text:paragraphs.append(text)
    return '[NEWLINE][NEWLINE]'.join(paragraphs)


def read_book(filename):
    source=(BOOKS/filename).read_text(encoding='utf-8')
    lines=source.splitlines();assert lines and lines[0].startswith('# '),filename
    title=lines[0][2:];body=[];sections=[]
    for line in lines[1:]:
        if line.startswith('## '):
            if ''.join(body).strip():sections.append((title,game_text('\n'.join(body))))
            title=line[3:];body=[]
        else:
            assert not line.startswith('#'),'Use level-two chapter headings: '+filename
            body.append(line)
    if ''.join(body).strip():sections.append((title,game_text('\n'.join(body))))
    assert sections and all(title and body for title,body in sections)
    assert len({title for title,_ in sections})==len(sections),'Duplicate chapter title'
    return sections


def whole_book(sections):
    parts=[sections[0][1]]
    parts.extend('[COLOR_YELLOW]'+title+'[ENDCOLOR][NEWLINE]'+body for title,body in sections[1:])
    return '[NEWLINE][NEWLINE]'.join(parts)


def localization():
    city=read_book('TheCity.md');leader=read_book('TheFirstArchitect.md')
    registry=read_book('TheGrandRegistry.md');surveyors=read_book('FrontierSurveyors.md')
    fallback_titles={'What the word city means','The Council of Wards','How distant work is organized','One program of great works'}
    # The native civilization article uses all numbered chapters. Retain a useful,
    # bounded overview for consumers of the older Civilopedia field.
    fallback=[city[0]]+[section for section in city if section[0] in fallback_titles]
    bc={'CIV_PEDIA':whole_book(fallback),'LEADER_PEDIA':whole_book(leader),
        'REGISTRY_PEDIA':whole_book(registry),'SURVEYOR_PEDIA':whole_book(surveyors),
        'DAWN':read_book('Dawn.md')[0][1]}
    native={}
    for prefix,sections in [(CIV_PREFIX,city),(LEADER_PREFIX,leader)]:
        for number,(title,body) in enumerate(sections,1):
            native[prefix+'_HEADING_'+str(number)]=title
            native[prefix+'_TEXT_'+str(number)]=body
    native.update({
        CIV_PREFIX+'_FACTOID_HEADING':'One address, many mornings',
        CIV_PREFIX+'_FACTOID_TEXT':'A resident of a distant orchard ward can name the Heart as their city without visiting its central square. Their immediate services belong to the ward, their standing belongs to the common charter, and their right of appeal travels with them.',
        LEADER_PREFIX+'_NAME':'The First Architect',
        LEADER_PREFIX+'_SUBTITLE':'Keeper of the First Promise',
        LEADER_PREFIX+'_LIVED':'Founding Age; precise dates disputed',
        LEADER_PREFIX+'_TITLES_1':'Steward of the One Charter',
        LEADER_PREFIX+'_TITLES_2':'First Servant of the Common Works',
        LEADER_PREFIX+'_FACT_1':'The unfinished arch on the seal of office signifies public work still owed. Later holders inherit the obligation attached to the first signature.',
        LEADER_PREFIX+'_FACT_2':'The phrase "Return the plan across the table" asks a planner to receive the knowledge of residents with the seriousness given to an official drawing.',
        LEADER_PREFIX+'_FACT_3':'Public portraits commemorate the mortal founder. The long history of the office belongs to successive generations, each answerable for the promises it chooses to keep.',
    })
    return bc,native


if __name__=='__main__':
    bc,native=localization()
    print('Compiled',len(bc),'existing lore fields and',len(native),'native Civilopedia chapter/metadata strings')
