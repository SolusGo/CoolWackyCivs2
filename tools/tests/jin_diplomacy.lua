local J=MapModData.JIN
Complete('GREAT_PASTURE');Complete('DRAGON_PAVILION')
assert(J.Count(0,'EMISSARY')==1 and not J.State(0).freeEmissary)
J.Bootstrap();assert(J.Count(0,'EMISSARY')==1)
local emissary;for u in Players[0]:Units()do if u.typ==GameInfoTypes.UNIT_JIN_EMISSARY then emissary=u end end
emissary.x=15;emissary.y=8;assert(Action('TRIBUTARY',emissary.id,2));assert(not Action('TRIBUTARY',emissary.id,2))
local s=J.State(0);assert(J.Tributaries(0,s)==1 and cap:GetNumBuilding(J.Building('TRIBUTE'))==1);assert(Players[0]:HasPolicy(GameInfoTypes.POLICY_JIN_TRIBUTARY_TRADE))
emissary.moves=120;emissary.x=15;emissary.y=12;assert(Action('TRIBUTARY',emissary.id,3));assert(cap:GetNumBuilding(J.Building('TRIBUTE'))==2)
assert(J.Tributaries(0,J.State(0))==2);Spawn('EMISSARY');assert(not J.TrainAllowed(0,cap.id,GameInfoTypes.UNIT_JIN_EMISSARY))
local raw=Players[0].raw;LoadJin();J=MapModData.JIN;assert(J.Tributaries(0,J.State(0))==2)
War(0,2,true);GameEvents.DeclareWar.Fire(0,2,false);assert(J.Tributaries(0,J.State(0))==1)
Players[3].alive=false;J.Economy(0,J.State(0));assert(cap:GetNumBuilding(J.Building('TRIBUTE'))==0 and not Players[0]:HasPolicy(GameInfoTypes.POLICY_JIN_TRIBUTARY_TRADE))
War(0,1,true);emissary.x=11;emissary.y=10;emissary.moves=120
local enemy=Spawn('UNIT_WARRIOR',12,10,1);enemy.damage=25
local civilian=Spawn('UNIT_WORKER',12,11,1);Players[3].alive=true;local neutral=Spawn('UNIT_WARRIOR',11,11,3)
assert(J.BribeTarget(0,civilian)==nil and J.BribeTarget(0,neutral)==nil)
local gold=Players[0].gold;Players[4].failSpawn=true
assert(not Action('BRIBE',emissary.id,enemy:GetPlot().index));assert(not enemy.dead and Players[0].gold==gold)
Players[4].failSpawn=false;assert(Action('BRIBE',emissary.id,enemy:GetPlot().index));assert(enemy.dead and not civilian.dead and not neutral.dead)
local rebel;for u in Players[4]:Units()do rebel=u end;assert(rebel and rebel.owner==4 and rebel.damage==25)
assert(Teams[4]:IsAtWar(0) and Teams[4]:IsAtWar(1));assert(Players[0].gold<gold)
emissary.moves=120;local target=Spawn('UNIT_WARRIOR',12,10,1);assert(not Action('BRIBE',emissary.id,target:GetPlot().index),'cooldown ignored')
local cooldown=J.State(0).emissaryCooldown[emissary.id].ready;LoadJin();J=MapModData.JIN;assert(J.State(0).emissaryCooldown[emissary.id].ready==cooldown)
Players[0].alive=false;LoadJin();J=MapModData.JIN
now=now+J.Scale(J.C.rebelLifetime);GameEvents.PlayerDoTurn.Fire(1);assert(rebel.dead,'rebels survived Jin elimination/reload without a Barbarian turn')
print('PASS Jin diplomacy: two Emissaries, independent tribute/native yields, war/elimination, protected targets, neutral rebels and cooldown persistence')
