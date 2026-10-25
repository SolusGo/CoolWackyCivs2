"""Check shipped localization, real database pointers and Firaxis chapter discovery.

Executes the installed BNW heading loops with a small localization/control model.
This does not run the native font renderer, UI layout or game localization DLL.
"""
from pathlib import Path
import hashlib,os,re
from lupa.lua51 import LuaRuntime
from boundless_lore import R,BOOKS,CIV_PREFIX,LEADER_PREFIX,read_book,localization


def native_source():
    roots=[Path(os.environ['CIV5_PATH'])] if os.environ.get('CIV5_PATH') else []
    roots += [Path("G:/SteamLibrary/steamapps/common/Sid Meier's Civilization V"),
              Path("C:/Program Files (x86)/Steam/steamapps/common/Sid Meier's Civilization V")]
    relative='Assets/DLC/Expansion2/UI/Civilopedia/CivilopediaScreen.lua'
    return next((root/relative for root in roots if (root/relative).is_file()),None)


def execute_loop(fragment,prefix,strings):
    lua=LuaRuntime();lua.globals().Strings=lua.table_from(strings)
    lua.execute('''
        Rendered={}
        function TagExists(key) return Strings[key]~=nil end
        Locale={ConvertTextKey=function(key) return Strings[key] or key end}
        g_FreeFormTextManager={GetInstance=function(self)
            local r={};Rendered[#Rendered+1]=r
            return {FFTextHeader={SetText=function(_,text) r.heading=text end},
                    FFTextLabel=r,FFTextInnerFrame={},FFTextFrame={}}
        end}
        function UpdateTextBlock(text,label,inner,frame) label.body=text end
    ''')
    lua.execute('local tagString = ...\n'+fragment,prefix)
    rendered=lua.globals().Rendered
    return [(rendered[n].heading,rendered[n].body) for n in range(1,len(rendered)+1)]


def validate(d=None):
    if d is None:
        from database import database
        d=database()
        for path in sorted((R/'TheBoundlessCity/SQL').glob('*.sql')):
            d.executescript(path.read_text(encoding='utf-8'))
    from generate_database import text_sql
    assert (R/'TheBoundlessCity/SQL/10_BC_Text.sql').read_text(encoding='utf-8')==text_sql(),'Stale generated lore SQL'
    bc,native=localization();expected={'TXT_KEY_BC_'+key:value for key,value in bc.items()}|native
    strings=dict(d.execute('SELECT Tag,Text FROM Language_en_US'))
    for key,value in expected.items():
        assert strings.get(key)==value,(key,'missing/stale native localization')
        assert '|' not in value and len(value)<16000,(key,'unsafe form delimiter or single field size')
        tokens=re.findall(r'\[([^\]]+)\]',value)
        assert set(tokens)<={'NEWLINE','COLOR_YELLOW','ENDCOLOR'},key
        assert value.count('[COLOR_YELLOW]')==value.count('[ENDCOLOR]'),key
        assert not re.search(r'^#|\*\*|\]\(',value),key
    civ=d.execute("SELECT CivilopediaTag,Civilopedia,DawnOfManQuote FROM Civilizations WHERE Type='CIVILIZATION_BOUNDLESS_CITY'").fetchone()
    leader=d.execute("SELECT CivilopediaTag,Civilopedia FROM Leaders WHERE Type='LEADER_BC_ARCHITECT'").fetchone()
    assert tuple(civ)==(CIV_PREFIX,'TXT_KEY_BC_CIV_PEDIA','TXT_KEY_BC_DAWN')
    assert tuple(leader)==(LEADER_PREFIX,'TXT_KEY_BC_LEADER_PEDIA')
    for table,kind,key in [('Buildings','BUILDING_BC_REGISTRY','TXT_KEY_BC_REGISTRY_PEDIA'),
                           ('Units','UNIT_BC_SURVEYOR','TXT_KEY_BC_SURVEYOR_PEDIA')]:
        assert d.execute('SELECT Civilopedia FROM '+table+' WHERE Type=?',(kind,)).fetchone()[0]==key
    source=native_source();fragments=[]
    if source:
        raw=source.read_bytes();text=raw.decode('utf-8-sig')
        position=text.index('CivilopediaCategory[CategoryCivilizations].SelectArticle =')
        for _ in range(2):
            start=text.index('local headerString = tagString .. "_HEADING_";',position)
            end=text.index('until notFound;',start)+len('until notFound;')
            fragments.append(text[start:end]);position=end
        assert 'tagString.."_NAME"' in text and 'tagString.."_LIVED"' in text
        print('PASS primary BNW chapter-loop source:',hashlib.sha256(raw).hexdigest())
    groups=[(CIV_PREFIX,read_book('TheCity.md')),(LEADER_PREFIX,read_book('TheFirstArchitect.md'))]
    for index,(prefix,sections) in enumerate(groups):
        for n,(title,body) in enumerate(sections,1):
            assert strings[prefix+'_HEADING_'+str(n)]==title and strings[prefix+'_TEXT_'+str(n)]==body
        assert prefix+'_HEADING_'+str(len(sections)+1) not in strings
        if fragments:
            assert execute_loop(fragments[index],prefix,strings)==sections
            missing=dict(strings);missing.pop(prefix+'_HEADING_1')
            assert execute_loop(fragments[index],prefix,missing)==[],'Native first-heading negative regression'
            missing=dict(strings);missing.pop(prefix+'_TEXT_2')
            assert execute_loop(fragments[index],prefix,missing)==sections[:1],'Native first-gap termination'
    if not source:print('SKIP installed BNW loop execution: set CIV5_PATH; localization/pointer checks still ran')
    for suffix in ['_NAME','_SUBTITLE','_LIVED','_TITLES_1','_TITLES_2','_FACT_1','_FACT_2','_FACT_3']:
        assert strings.get(LEADER_PREFIX+suffix)
    words=sum(len(re.findall(r"\b[\w'-]+\b",p.read_text(encoding='utf-8'))) for p in BOOKS.glob('*.md') if p.name!='README.md')
    print('PASS Boundless lore:',len(groups[0][1]),'city chapters,',len(groups[1][1]),'leader chapters,',len(expected),'lore keys and',words,'source words; native rendering remains untested')


if __name__=='__main__':validate()
