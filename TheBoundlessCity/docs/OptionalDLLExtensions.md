# Optional minimum DLL interfaces

**Proposal only.** No replacement DLL or native source patch is implemented/distributed. These interfaces do not exist in supported CP v151. Their names describe contracts, not callable Lua APIs. Any implementation would require separate authorization and upstream/DLL compatibility testing.

## Selective original-capital capture

Add a native capture-permission decision receiving actual attacker/unit/city before every city-acquisition path in movement/combat. Permit an exception to NoCapture only when the unit's living owner has zero cities and Lua verifies the immutable original coordinates/founding/original owner/native flag. Repeat the decision immediately before acquisition; unit movement/combat stays native. An ordinary CanMoveInto event is too late for the existing NoCapture rejection and is per-unit opt-in.

Existing StaysAliveZeroCities already provides new-game survival with units; no new hidden-city/elimination mechanism is required. A small explicit **RefreshPlayerTraits** binding would allow older native saves to recalculate the serialized trait cache without changing leader/personality or toggling policy/tech rewards. Already eliminated players should stay eliminated unless a separately authorized native liberation occurs.

## Independent demolition permission and execution

Extract a native destruction predicate that can evaluate a city while it remains owned by the enemy. Bypass only the interface ownership/own-founded restrictions required for conquest without occupation. Preserve no-raze/OCC rules, genuine original-capital and city-state/holy protections, unique-civilization luxuries, CP flags and applicable native/mod vetoes. Make the new operation queryable without mutation; let scripts veto independently if old hooks cannot express this context safely.

The matching native operation should recheck permission and city generation identity, validate attacker/war/defeat/unit movement, consume movement, execute city.kill/native unit/resource/wonder/trade cleanup outside active capture stacks, and release territory according to its native contract. It must not temporarily give Boundless the city, invoke an unguarded Disband, suppress another mod's veto or fabricate capture rewards. Tests must cover both own-founded and previously captured towns, all hard protections and stale city generations.

## Authoritative remote citizen reservations

The smallest virtual-yield extension is a scoped, atomic reservation API: reserve N existing ordinary defaults/local workers for a mod key, report the actual granted count and release only that key's reservations. Expose a trustworthy forced-default/reservation count. Enforce `N <= population - native building specialists - other protected roles`, convert actual jobs/defaults without creating population, and prevent the governor from reusing reserved citizens. Handle native starvation, population loss, specialists, automatons, save/reload and other reservation users synchronously.

A bare forced-default setter/getter could support the current algorithm only if it preserves native forced counts and grants real exclusivity across governor resets. A mod-owned reservation contract avoids erasing another user's locks. TASK_SET_AUTOMATED_CITIZENS must either become functional or remain irrelevant to the reservation guarantee. No negative automatons or extra specialist slots are necessary.

## Full native remote worked integration

For complete effects, add a remote job collection independent of fixed local-index arrays, containing unique map-plot indices and owner/city identities. Its population count must share the citizen allocator. Integrate it into terrain sources, working queries, GetWorkedPlots, worked counters, religion/per-X thresholds, GP improvement rates, Tourism, improvement development/resource discovery, plot yield-change notifications, city acquisition/destruction and serialization. Ownership/blockade/native takeover must remove a remote job immediately and once. Local and remote collections must never contain the same counted job. This is more than exporting SetWorkingPlot: its current local-index preconditions would still be invalid.

## Universal one-city acquisition gate

Add a pre-acquisition test-all decision in CvPlayer::acquireCity before native mutation, and ensure gifts, peace deals, liberation, special abilities and direct scripting reach it. For Boundless, accept only its original city while it owns zero cities; reject all other acquisitions atomically. Keep ordinary player behavior unchanged. A refusal must leave cities/territory/trade/wonders untouched and return a clear result to callers, which must not assume acquisition succeeded.

If an existing extra city must remain recoverable, an optional scoped disabled-city flag could suppress production/purchases, ordinary yields, specialist GPP, resources/Happiness/global buildings/trade access, population/city-count/national prerequisite effects and military infrastructure while preserving restoration data. Resistance alone has a narrower contract. Absolute ownership enforcement is best achieved before acquisition, not by hiding the extra city from one UI counter.

## Domination

No additional DLL victory API is necessary for the implemented alternative: CP v151 exposes Game.SetWinner and its native completion path. Live tests must establish popup/save/scenario interaction. A native source-integrated subjugation tracker would improve victory UI/AI awareness, but must preserve other teams' ordinary Domination rules and all prior results.

Each proposal needs read-back/identity tests, save compatibility/versioning, native event-order tests and Huge-map profiling before distribution. The current mod continues using only the audited v151 interface.
