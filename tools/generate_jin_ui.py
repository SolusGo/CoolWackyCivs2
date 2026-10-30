"""Generate the Jin council layout using installed Civ V control styles."""
from pathlib import Path
from xml.etree import ElementTree as ET

R=Path(__file__).resolve().parents[1]
TABS=[('Overview','Grasslands'),('Landmarks','Landmarks'),('Recruit','Recruit'),('Emissaries','Emissaries'),('Upgrades','Upgrades'),('Defense','Defenses')]
def main():
 root=ET.Element('Context',ID='JIN_Dynasty')
 def node(parent,tag,**props):return ET.SubElement(parent,tag,{k:str(v) for k,v in props.items()})
 def image(parent,texture,size,offset='0,0',**props):return node(parent,'Image',Anchor='L,T',Offset=offset,Size=size,Texture=texture,ConsumeMouse=0,**props)
 def label(parent,offset,font='TwCenMT16',**props):return node(parent,'Label',Anchor='L,T',Offset=offset,Font=font,**props)
 def button(parent,**props):
  b=node(parent,'GridButton',Font='TwCenMT16',ColorSet='Beige_Black_Alpha',**props)
  node(b,'GridData',Style='Grid9FrameButtons',Texture='JIN_UI_Buttons.dds');return b
 launcher=button(root,ID='Open',Anchor='R,T',Offset='15,315',Size='245,42',String='JIN DYNASTY',Hidden=1)
 image(launcher,'JIN_Icon32.dds','30,30','10,6')
 panel=node(root,'Grid',ID='Panel',Anchor='C,C',Size='980,680',Style='GridBlackIndent8',ConsumeMouse=1,Hidden=1)
 image(panel,'JIN_UI_Panel.dds','980,680');image(panel,'JIN_Header.dds','964,124','8,8');image(panel,'JIN_Icon80.dds','80,80','24,24')
 label(panel,'118,28','TwCenMT24',Color0='255,232,180,255',Color1='0,0,0,220',FontStyle='Shadow',String='THE JIN DYNASTY')
 label(panel,'120,65','TwCenMT18',Color0='220,185,125,255',Color1='0,0,0,220',FontStyle='Shadow',String='JURCHEN LEGACY')
 button(panel,ID='Close',Anchor='R,T',Offset='22,20',Size='40,32',String='X')
 for i,(key,title,symbol,symbol_id) in enumerate([
  ('Horse','HORSES','Horse','HorseSymbol'),('Tribute','TRIBUTARIES','Tributary','TributarySymbol'),
  ('Villager','VILLAGERS','Grassland','GrasslandSymbol'),('Karma','KARMA','Karma','KarmaSymbol'),('Landmark','LANDMARKS','Mengan','MenganSymbol')]):
  card=node(panel,'Grid',ID=key+'Card',Anchor='L,T',Offset=f'{24+i*188},142',Size='180,80')
  image(card,'JIN_UI_Metric.dds','180,80');image(card,f'JIN_{symbol}UI64.dds','40,40','10,13',ID=symbol_id)
  label(card,'56,10','TwCenMT14',Color0='214,180,118,255',String=title)
  label(card,'56,28','TwCenMT20',ID=key+'Value',ColorSet='Beige_Black_Alpha')
  label(card,'12,59','TwCenMT14',ID=key+'Detail',Color0='192,178,159,255')
 node(panel,'Label',ID='Overview',Font='TwCenMT16',Hidden=1)
 tabs=node(panel,'Stack',Anchor='L,T',Offset='24,236',StackGrowth='Right',Padding=8)
 for key,title in TABS:
  b=button(tabs,ID=key+'Tab',Size='148,38',String=title)
  node(b,'Image',ID=key+'Active',Anchor='C,B',Offset='0,3',Size='120,3',Texture='JIN_UI_Accent.dds',ConsumeMouse=0)
 label(panel,'28,291','TwCenMT20',ID='SectionTitle',Color0='245,222,177,255')
 label(panel,'250,297','TwCenMT14',ID='SectionDetail',Size='690,20',Color0='180,168,152,255')
 scroll=node(panel,'ScrollPanel',ID='Scroll',Anchor='L,T',Offset='24,322',Size='932,276',VerticalScrollBar='ScrollBar')
 node(scroll,'Stack',ID='Rows',Anchor='L,T',StackGrowth='Bottom',Padding=6)
 node(panel,'ScrollBar',ID='ScrollBar',Anchor='R,T',Offset='12,322',Size='12,276',Style='VertSlider')
 label(panel,'28,616',ID='Message',Size='920,44',WrapWidth=920,ColorSet='Beige_Black_Alpha',String='Select a tab to manage the dynasty. Hover an entry for its full requirements.')
 instance=node(root,'Instance',Name='JIN_Row');row=node(instance,'Grid',ID='Root',Size='910,94',Style='GridBlackIndent8')
 image(row,'JIN_UI_Row.dds','910,94');image(row,'JIN_Icon64.dds','64,64','12,15',ID='Art')
 label(row,'90,9','TwCenMT18',ID='Title',Size='620,22',Color0='240,216,170,255')
 label(row,'90,34',ID='Text',Size='620,54',WrapWidth=620,ColorSet='Beige_Black_Alpha')
 button(row,ID='Action',Anchor='R,T',Offset='10,20',Size='162,38')
 node(row,'Label',ID='Status',Anchor='R,T',Offset='12,66',Size='158,18',Align='Center',Font='TwCenMT14',Color0='190,165,119,255')
 ET.indent(root,' ')
 with (R/'JinDynasty/UI/JIN_Dynasty.xml').open('wb') as output:ET.ElementTree(root).write(output,encoding='utf-8',xml_declaration=True)
 print('Generated Jin council layout: five metric cards, six tabs and illustrated rows')
if __name__=='__main__':main()
