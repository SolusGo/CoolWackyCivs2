for name,values in pairs({GAMESPEED_QUICK={3,1},GAMESPEED_STANDARD={5,2},GAMESPEED_EPIC={7,3},GAMESPEED_MARATHON={12,6},CUSTOM={12,5}}) do
 speed=name;speedPercent=name=='CUSTOM' and 240 or 999
 now=100;Players[0].raw='OTHER_MOD_DATA';Players[0].units={};Players[0].era=0;NewUnit(1,0)
 NewContext();LoadUrgal();local U=MapModData.URGAL
 assert(U.Duration()==values[1] and U.Aftertaste()==values[2])
 local s=U.State(0);s.potions=4;U.Save(0,s)
 assert(U.Drink(0));local raw=Players[0].raw
 for offset=0,values[1]+values[2]-1 do
  now=100+offset
  -- Recreate the shipped controller at every boundary; absolute saved deadlines
  -- must remain unchanged even on duplicate begin events and reloads.
  NewContext();LoadUrgal();U=MapModData.URGAL
  GameEvents.PlayerDoTurn.Fire(0);GameEvents.PlayerDoTurn.Fire(0)
  assert(Players[0].raw==raw,'reload cannot rewrite the committed window')
  Check(Players[0].units[1],offset<values[1],false)
  assert(not U.CanDrink(0) and not U.Drink(0),'no early reactivation on '..name..' offset '..offset)
 end
 now=100+values[1]+values[2];GameEvents.PlayerDoTurn.Fire(0)
 assert(U.CanDrink(0) and U.Drink(0),'first legal reactivation turn on '..name)
 assert(U.State(0).potions==2)
end
speed='CUSTOM';speedPercent=0
assert(MapModData.URGAL.Duration()==5 and MapModData.URGAL.Aftertaste()==2,'invalid percentage uses Standard')
speedPercent=20
assert(MapModData.URGAL.Duration()==1 and MapModData.URGAL.Aftertaste()==1,'minimum one turn')
-- Preserve a v15 Marathon save's already-committed legacy two-turn Aftertaste.
-- New drinks use six turns. Loading never extends/rejects the saved window.
speed='GAMESPEED_MARATHON';now=5
Players[0].raw='OTHER_MOD_DATA[URGAL_P1:3:0:12:14:1]';Players[0].era=0
NewContext();LoadUrgal();local U=MapModData.URGAL
assert(U.State(0).ready==14 and not U.CanDrink(0))
now=14;assert(U.Drink(0));assert(U.State(0).finish==26 and U.State(0).ready==32)
print('PASS exact activation/expiration/reactivation on four named speeds and custom speed, per-boundary reloads and legacy deadline continuity')
