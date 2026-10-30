"""Focused Workforce localization, layout-contract and live-summary regressions.

Uses actual SQL text with a small first-form/positional-token formatter model.
This does not execute the native localization DLL or measure native font layout.
"""
from pathlib import Path
from xml.etree import ElementTree as ET
import re, sqlite3, struct
from lupa.lua51 import LuaRuntime

R = Path(__file__).resolve().parents[1]
V = R / 'TheBoundlessCity'
FIELDS = {
    'Population': 'population', 'OwnedPlots': 'owned', 'FrontierCulture': 'progress',
    'FrontierCost': 'cost', 'LocalWorkers': 'localCount', 'RemoteWorkers': 'remote',
    'Specialists': 'specialists', 'IdleLabourers': 'idle', 'UnassignedCitizens': 'unassigned',
    'AvailableCitizens': 'availableCitizens', 'AdditionalRemoteCapacity': 'availableRemote',
    'MaximumRemoteCapacity': 'maximumRemote', 'PendingRequests': 'pending', 'LockedRequests': 'locks',
}


def layout(text):
    root = ET.parse(V / 'UI/BoundlessWorkforce.xml').getroot()
    ids = {node.get('ID'): node for node in root.iter() if node.get('ID')}
    assert ids['Panel'].get('Size') == '900,700', 'Do not enlarge the existing panel'
    scroll = ids['OverviewScroll']
    assert scroll.tag == 'ScrollPanel' and scroll.get('Vertical') == '1'
    overview = scroll.find("Stack[@ID='Overview']")
    assert overview is not None and overview.get('StackGrowth') == 'Bottom'
    assert ids['Yields'] in list(overview), 'Wrapped yields must share the safe scrolling area'
    body = overview.find("Grid[@ID='SummaryBody']")
    assert body is not None
    width = int(body.get('Size').split(',')[0])
    previous_right = 0
    for column in body.findall('Stack'):
        x = int(column.get('Offset', '0,0').split(',')[0])
        assert column.get('StackGrowth') == 'Bottom' and x >= previous_right
        labels = column.findall('Label')
        assert labels
        for label in labels:
            wrap = int(label.get('WrapWidth'))
            assert 0 < wrap <= width - x
            assert 'Size' not in label.attrib, 'Natural label height must be free to grow'
            if label.get('String'):
                assert label.get('String') in text
        previous_right = x + max(int(label.get('WrapWidth')) for label in labels)
    for name in [*FIELDS, 'SubjugationProgress']:
        assert ids[name] in list(body.iter('Label')), name
    bounds = []
    for name in ['OverviewScroll', 'Mode', 'Priority', 'Direction', 'Sort', 'Scroll', 'Previous', 'Next', 'Help']:
        node = ids[name]
        x, y = map(int, node.get('Offset').split(','))
        w, h = map(int, node.get('Size').split(','))
        # Right-anchored pagination uses a right margin, not a left offset.
        if node.get('Anchor').startswith('R,'):
            x = 900 - x - w
        assert x >= 0 and y >= 0 and x+w <= 900 and y+h <= 700, name
        for other, ox, oy, ow, oh in bounds:
            assert x+w <= ox or ox+ow <= x or y+h <= oy or oy+oh <= y, (name, other)
        bounds.append((name, x, y, w, h))
    for node in root.iter():
        key = node.get('String', '')
        if key.startswith('TXT_KEY_BC_'):
            assert key in text, key
    print('PASS summary XML: 15 statistics, natural-height wrapped columns, scrolling yields, unchanged 900x700 panel and disjoint action/list bounds')


def skin():
    from PIL import Image
    from prepare_boundless_ui import SIZES, S
    root=ET.parse(V/'UI/BoundlessWorkforce.xml').getroot()
    used={n.get('Texture') for n in root.iter() if n.get('Texture','').startswith('BC_UI_')}
    assert used<={'BC_UI_'+name+'.dds' for name in SIZES}
    assert {'BC_UI_Row.dds','BC_UI_Assigned.dds','BC_UI_Pending.dds'}<=used
    for name,size in SIZES.items():
        path=V/('Art/BC_UI_'+name+'.dds');raw=path.read_bytes()
        assert raw[:4]==b'DDS ' and raw[84:88]==b'\0'*4,'Legacy RGBA DDS required'
        w,h=size;pixels=0;levels=0
        while True:
            pixels+=w*h*4;levels+=1
            if (w,h)==(1,1):break
            w,h=max(1,w//2),max(1,h//2)
        assert len(raw)==128+pixels and struct.unpack_from('<I',raw,28)[0]==levels
        with Image.open(path) as im,Image.open(S/('BC_UI_'+name+'.png')) as master:
            assert im.size==size and im.convert('RGBA').tobytes()==master.convert('RGBA').tobytes()
    for button in root.iter('GridButton'):
        data=button.find('GridData')
        assert data is not None and data.get('Style')=='Grid9FrameButtons' and data.get('Texture') in {'BC_UI_Buttons.dds','CWC2_TheBoundlessCity_Buttons.dds'}
    with Image.open(V/'Art/BC_UI_Buttons.dds') as sheet:
        assert len({sheet.crop((0,y,44,y+44)).tobytes() for y in [0,45,90,135]})==4
    rows=root.find("Instance/Grid[@ID='Root']")
    assert int(rows.get('Size').split(',')[1])*3+4*2<=210,'Three complete rows must fit'
    for image in root.iter('Image'):
        if image.get('Texture','').startswith('BC_UI_'):assert image.get('ConsumeMouse')=='0'
    print('PASS Workforce skin: six preserved legacy DDS/mip chains, source pixels, themed native nine-slice controls, click-through markers and three complete rows')


def validate():
    d = sqlite3.connect(':memory:')
    d.execute('CREATE TABLE Language_en_US(Tag TEXT PRIMARY KEY,Text TEXT)')
    d.executescript((V / 'SQL/10_BC_Text.sql').read_text(encoding='utf-8'))
    text = dict(d.execute('SELECT Tag,Text FROM Language_en_US'))
    d.close()
    for key, value in text.items():
        if key.startswith('TXT_KEY_BC_SUMMARY') or key in ['TXT_KEY_BC_SUBJUGATION_PROGRESS', 'TXT_KEY_BC_AUTOMATONS']:
            assert '|' not in value, (key, 'Reserved localization form delimiter')
            tokens = re.findall(r'\{([^{}]+)\}', value)
            assert all(re.fullmatch(r'[1-9][0-9]*_[A-Za-z][A-Za-z0-9_]*', token) for token in tokens), key
    layout(text);skin()
    lua = LuaRuntime()

    def include(name):
        if name != 'InstanceManager':
            lua.execute((V / 'Lua' / (name + '.lua')).read_text(encoding='utf-8'))

    lua.globals().include = include
    lua.execute((R / 'tools/tests/boundless_mock.lua').read_text(encoding='utf-8'))
    include('BoundlessCore')
    lua.globals().LoadWorkforceUI = lambda: lua.execute((V / 'UI/BoundlessWorkforce.lua').read_text(encoding='utf-8'))
    # Reuse the existing native-screen/control fixture and all its visibility,
    # military, failure and dispatcher assertions before checking SQL text.
    lua.execute((R / 'tools/tests/ui_assertions.lua').read_text(encoding='utf-8'))
    lua.globals().SummaryText = lua.table_from(text)
    lua.globals().SummaryFields = lua.table_from(FIELDS)
    lua.execute((R / 'tools/tests/summary_assertions.lua').read_text(encoding='utf-8'))
    print('PASS SQL-backed summary formatter and live UI regressions (models, not native rendering)')


if __name__ == '__main__':
    validate()
