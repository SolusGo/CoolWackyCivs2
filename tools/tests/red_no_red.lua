local R=MapModData.RED_Legend
assert(#GameEvents.CityCanCreate.handlers==1 and #GameEvents.PlayerCanCreate.handlers==1)
for pid=0,3 do
 assert(not GameEvents.CityCanCreate(pid,0,R.PROJECT))
 assert(not GameEvents.PlayerCanCreate(pid,R.PROJECT))
 assert(GameEvents.CityCanCreate(pid,0,-123) and GameEvents.PlayerCanCreate(pid,-123))
end
assert(next(R.States)==nil and not ContextPtr.update,'no Red simulation in an absent-Red game')
print('PASS Red absent-game global project vetoes')
