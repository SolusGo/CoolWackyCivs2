Players[0].human=false
for i=1,3 do local u=NewUnit(i,0);u.x=i-1 end
LoadUrgal();local U=MapModData.URGAL
Teams[0].wars[1]=true
U.AITurn(0);assert(U.State(0).potions==1,'war alone is not enough')
local plot=NewPlot(1,1,1);local enemy=NewUnit(1,1);plot.units={enemy}
U.AITurn(0);assert(U.State(0).potions==1,'one distant opponent is not enough')
local enemy2=NewUnit(2,1);plot.units[2]=enemy2
plot.visible=false;U.AITurn(0);assert(U.State(0).potions==1,'no hidden-map information')
plot.visible=true;enemy.invisible=true;U.AITurn(0);assert(U.State(0).potions==1,'invisible units excluded')
enemy.invisible=false
Teams[0].wars[1]=false;U.AITurn(0);assert(U.State(0).potions==1,'peaceful units excluded')
Teams[0].wars[1]=true
for u in Players[0]:Units() do u.unreachable=true end
U.AITurn(0);assert(U.State(0).potions==1,'blocked approaches cannot waste a potion')
for u in Players[0]:Units() do u.unreachable=false;u.exhausted=true end
U.AITurn(0);assert(U.State(0).potions==1,'spent attacks do not count toward the army')
for u in Players[0]:Units() do u.exhausted=false end
U.AITurn(0);assert(U.State(0).potions==0)
for u in Players[0]:Units() do Check(u,true,false) end
U.AITurn(0);assert(U.State(0).potions==0,'AI cannot stack or overspend')
now=7;Players[0].era=1;GameEvents.TeamSetEra.Fire(0,1,false)
Players[0].units[3].x=20;U.AITurn(0);assert(U.State(0).potions==1,'army must be concentrated')
Players[0].units[3].x=2;plot.units={enemy};plot.owner=0
U.AITurn(0);assert(U.State(0).potions==0,'a concentrated counterattack can answer an invasion')
print('PASS AI war gate, local concentration, visibility, invisibility, threat threshold, invasion and cooldown')
