# The Wandering Circus — Ringmaster Aurelio

A whimsical civilization of performers, musicians and stagehands, settled around **Grand Pavilion**. Its crimson tents and golden lanterns turn patient infrastructure work into local celebrations. Human-only, BNW/CP v151; favor **Culture**, with **Science** second.

- **The Show Must Go On:** a Carnival Crew ending a turn in your city can begin a three-owner-turn Grand Festival next turn, providing +3 Culture/+2 Gold. Each city can start again twelve turns after its previous start. No consumption, no stacking; departure after activation does not interrupt the show.
- **Carnival Crew (Worker):** all active CP Worker properties and build actions, exactly +1 Movement and ordinary WorkRate.
- **Ticket Office (Market):** all active CP Market benefits, +1 permanent Culture and +2 flat Production during that city's festival only.

Improve the land, then bring a Crew home before a ready performance. Rotate Crews between cities or leave one stationed for automatic shows at T, T+12 and T+24. The opportunity cost is infrastructure labor: every permanent host is a Worker away from the fields. Festivals are local; six cities can celebrate on six different schedules.

At T+3 the first show ends; T+11 remains on cooldown; T+12 is eligible. Exact 3/12 timing is independent of game speed. Native building counts preserve each city's boundaries through saves. Foreign ownership transfers clear all state. Ordinary and captured foreign Workers cannot host shows.

Original artwork, English text, actual-schema SQL, 40 Lua 5.1 suite runs and 59 CP source contracts are provided. The [final audit](../../TheWanderingCircus/docs/AuditReport.md) repairs conditional owner-entry cancellation and per-city error isolation without changing balance or saved marker layouts. Native yields, save round trips and rendering require acceptance testing; older-save compatibility is unverified. See the [complete guide](../../TheWanderingCircus/README.md), [implementation](../../TheWanderingCircus/docs/Implementation.md) and [test plan](../../TheWanderingCircus/docs/Testing.md).
