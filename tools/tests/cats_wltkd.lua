local H=MapModData.THE11CATS;local p=Players[0]
local a=City(0,1,10,10);local b=City(0,2,20,20);local enemy=City(1,1,60,60)
for _,percent in ipairs({67,100,150,300}) do
 GameInfo.GameSpeeds[0].TrainPercent=percent
 a:Plot().script='external:keep';b:Plot().script='external:keep'
 a.wltkd=0;b.wltkd=0;local suppliedA,suppliedB=0,0
 for i=1,60 do
  local added=math.max(1,math.floor((i%7+1)*percent/100))
  local city=i%2==0 and a or b
  if city==a then suppliedA=suppliedA+added else suppliedB=suppliedB+added end
  city.wltkd=city.wltkd+added
  GameEvents.CityExtendsWLTKD(0,city.x,city.y,added)
  assert(a.wltkd==suppliedA+math.floor(suppliedA/4))
  assert(b.wltkd==suppliedB+math.floor(suppliedB/4))
 end
 local beforeA,beforeB=a.wltkd,b.wltkd
 Reload();H=MapModData.THE11CATS;assert(a.wltkd==beforeA and b.wltkd==beforeB)
 p.capital=b;GameEvents.CapitalChanged(0,2,1);assert(a.wltkd==beforeA and b.wltkd==beforeB)
 enemy.wltkd=20;GameEvents.CityBeginsWLTKD(1,60,60,20);assert(enemy.wltkd==20)
end
GameInfo.GameSpeeds[0].TrainPercent=100
-- Transfer does not extend an existing celebration or give the foreign owner carry.
local remaining=a.wltkd;Transfer(a,1);GameEvents.CityExtendsWLTKD(1,10,10,4)
assert(a.wltkd==remaining)
Transfer(a,0);assert(a.wltkd==remaining)
-- A different founding identity cannot inherit the old quarter-turn remainder.
a:Plot().script='external:keep|THE11CATS_WLTKD:0:0:3|';Advance(1)
Players[0].cities[a.id]=nil;a:Plot().city=nil
local replacement=City(0,4,10,10);replacement.wltkd=1
GameEvents.CityBeginsWLTKD(0,10,10,1);assert(replacement.wltkd==1)
assert(replacement:Plot().script:find('external:keep',1,true))
replacement:Plot().script='external:keep|THE11CATS_WLTKD:0:1:9|';replacement.wltkd=1
GameEvents.CityBeginsWLTKD(0,10,10,1);assert(replacement.wltkd==1)
print('PASS 240 genuine WLTKD events: independent cities, four speeds, silent reload, capital/ownership/refounding and bounded fractional carry')
