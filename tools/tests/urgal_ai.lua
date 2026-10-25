-- Legacy filename: human-only isolation, not AI tactics.
Players[0].human=false
local a=NewUnit(1,0);a:SetHasPromotion(101,true);a:SetHasPromotion(103,true)
LoadUrgal();local U=MapModData.URGAL
assert(not U.Civ(0) and U.State(0)==nil and not U.Drink(0))
assert(Players[0].raw=='OTHER_MOD_DATA','AI must not receive an inventory')
Check(a,false,false)
GameEvents.PlayerDoTurn.Fire(0);GameEvents.TeamSetEra.Fire(0,4,false)
assert(Players[0].raw=='OTHER_MOD_DATA')
assert(U.AITurn==nil,'human controller must not load or depend on the AI module')
include('URGAL_AI');assert(not U.AITurn(0),'legacy AI entry remains inert')
Players[0].human=true
assert(U.State(0).potions==1 and U.CanDrink(0))
assert(not U.AITurn(0),'legacy entry must not auto-activate for humans either')
assert(U.Drink(0));Check(a,true,false)
print('PASS human-only runtime isolation, AI residue cleanup and dormant legacy module')
