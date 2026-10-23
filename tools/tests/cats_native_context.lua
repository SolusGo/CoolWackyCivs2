local H=MapModData.THE11CATS;H.InterfaceReady=function() return true end
local p=Players[0];local s=H.State(0);assert(UnitAITypes==nil)
assert(s.cats.LUNA.status==3 and s.cats.LUNA.recovery==0 and UnitCount(0)==0)
local init=p.InitUnit;local births=0
p.InitUnit=function(self,kind,x,y,...)
 assert(select('#',...)==0,'use the native optional NO_UNITAI default, not a UI enum')
 births=births+1;return init(self,kind,x,y)
end
local home=City(0,1,10,10)
-- Reproduce an existing stalled save: unlocked Luna, zero due timer, home exists.
H.Save(s)
Reload();H=MapModData.THE11CATS;H.InterfaceReady=function() return true end;s=H.State(0)
assert(s.cats.LUNA.status==1 and H.Unit(s,'LUNA') and births==1 and not H.spawning)
for i=1,5 do GameEvents.PlayerDoTurn(0);Events.SerialEventGameDataDirty();Flush() end
assert(UnitCount(0)==1 and births==1 and s.chapters==1 and s.latest==1)
Settle('LUNA',home)
-- Argument evaluation belongs inside the protected spawn too.
local x=home:Plot().GetX;home:Plot().GetX=function() error('plot accessor interrupted') end
assert(not H.Command(0,'LUNA','REHOME') and not H.spawning and s.cats.LUNA.status==2 and s.cats.LUNA.cooldown==0)
home:Plot().GetX=x
assert(H.Command(0,'LUNA','REHOME'));assert(births==2 and s.cats.LUNA.cooldown==10)
H.Unit(s,'LUNA'):Kill();local due=s.cats.LUNA.recovery
Advance(3);GameEvents.PlayerDoTurn(0);Flush()
assert(s.cats.LUNA.status==1 and births==3 and UnitCount(0)==1 and s.cats.LUNA.cooldown==10)
assert(due==3 and not H.spawning and not H.busy and not H.syncing)
print('PASS native UI without UnitAITypes: zero-turn pending Luna save resumes, exactly one arrival, rehome and recovery retain cooldown')
