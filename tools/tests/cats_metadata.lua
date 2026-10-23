local H=MapModData.THE11CATS
local expected={
 {'AUSTIN','Male',-1,'',0},{'LUNA','Female',0,'',0},{'BONNIE','Female',1,'',0},
 {'APPA','Male',2,'BONNIE',1},{'LOKI','Female',2,'BONNIE',1},{'KURO','Female',2,'BONNIE',1},
 {'OSCAR','Male',3,'BONNIE',2},{'BOOMIE','Female',3,'BONNIE',2},{'CHARLOTTE','Female',4,'',0},
 {'SISI','Female',4,'CHARLOTTE',0},{'MAX','Male',5,'',0},
}
local seen={};assert(#H.Order==11 and not H.State(0).cats.AUSTIN)
for index,row in ipairs(expected) do
 local id,gender,era,mother,litter=unpack(row);local cat=H.Cats[id]
 assert(H.Order[index]==id and cat.id==id and cat.portrait==index-1 and not seen[id])
 assert(cat.gender==gender and cat.era==era and cat.mother==mother and cat.litter==litter)
 seen[id]=true
end
include('THE11CATS_Manager');assert(MapModData.THE11CATS==H and GameEvents.PlayerDoTurn.Count()==1)
print('PASS eleven canonical identities: gender, mother/litter, era, exact portrait index, leader-only Austin and inert same-context include')
