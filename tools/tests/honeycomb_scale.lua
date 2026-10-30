-- Native-call-count bounds; times measure a Lua mock, never the game's DLL.
local T=HCC_Test
for owner=0,33 do
  if not Players[owner] then
    local p={id=owner,civ=99,alive=true,cities={},data='FOREIGN:'..owner}
    for key,value in pairs(Players[1]) do if type(value)=='function' then p[key]=value end end
    Players[owner]=p
  end
  for j=1,20 do
    local c=T.City(3000+owner*20+j,owner)
    if owner==0 or owner==2 then T.Assign(c,8); c.buildings[30]=1 end
  end
end
local q,w,d=T.Queries(),T.Writes(),T.DataWrites()
local started=os.clock()
for owner=0,33 do if owner~=0 and owner~=2 then GameEvents.PlayerDoTurn.Fire(owner) end end
for n=1,4000 do
  local owner=1+(n%32); if owner==2 then owner=33 end
  Events.SpecificCityInfoDirty.Fire(owner,3000+owner*20+1)
end
assert(T.Queries()==q and T.Writes()==w and T.DataWrites()==d,'foreign events performed economic work')
local foreignMS=(os.clock()-started)*1000
local cities=0; for city in Players[0]:Cities() do cities=cities+1 end
started=os.clock(); q=T.Queries(); d=T.DataWrites(); T.Boundary(0)
assert(T.Queries()-q==cities*36,'snapshot repeated or exceeded native citizen plot list')
assert(T.DataWrites()-d==2,'ordinary snapshot needs exactly journal and receipt writes')
local snapshotMS=(os.clock()-started)*1000
q,w,d=T.Queries(),T.Writes(),T.DataWrites()
for n=1,100 do GameEvents.PlayerDoneTurn.Fire(0) end
assert(T.Queries()==q and T.Writes()==w and T.DataWrites()==d,'duplicates scanned/wrote state')
local total=0; for owner=0,33 do for city in Players[owner]:Cities() do total=total+1 end end
HCC_Performance={players=34,added_cities=680,total_cities=total,foreign_dirty_events=4000,owner_cities=cities,
  owner_plot_reads=cities*36,script_writes_per_snapshot=2,foreign_plot_reads=0,
  foreign_building_writes=0,duplicate_plot_reads=0,foreign_mock_ms=foreignMS,snapshot_mock_ms=snapshotMS}
print('PASS HCC scale: 34 owners/680 added cities, 4,000 foreign dirty events, one 36-plot scan per HCC city, two ScriptData writes, zero duplicate/foreign economic work (mock)')
