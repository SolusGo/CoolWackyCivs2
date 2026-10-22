for _,start in ipairs({{0,2},{2,6},{5,11}}) do
 Players[0].era=start[1];Players[0].script='other-mod:preserved';Reload()
 local H=MapModData.THE11CATS;local s=H.State(0);local n=1
 for _,cat in pairs(s.cats) do if cat.status>0 then n=n+1;assert(cat.status==3) end end
 assert(n==start[2] and UnitCount(0)==0)
 local notices=#Players[0].notifications;local script=Players[0].script
 Reload();H=MapModData.THE11CATS;s=H.State(0)
 assert(Players[0].script==script and #Players[0].notifications==notices)
end
Players[0].era=0;Players[0].script='other-mod:preserved';Reload()
local H=MapModData.THE11CATS;local totals={2,3,6,8,10,11}
for era=0,5 do
 Players[0].era=era;GameEvents.TeamSetEra(0,era,false)
 local s=H.State(0);local n=1;for _,c in pairs(s.cats) do if c.status>0 then n=n+1 end end
 assert(n==totals[era+1]);local notices=#Players[0].notifications
 GameEvents.TeamSetEra(0,era,false);assert(#Players[0].notifications==notices)
end
print('PASS fresh Ancient/Medieval/Modern pre-capital starts, immediate save/load and six exact chapter totals without replay')
