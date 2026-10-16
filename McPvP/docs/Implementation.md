# Implementation and engine boundaries

`MCP_Core.lua` creates the isolated `MapModData.MCPVP` namespace and includes persistence, matches, kits, AI and events. Only `MCP_ServerBrowser.xml` is an InGameUIAddin. Its Lua renderer reads existing state and submits validated explicit commands; rendering never creates records or grants rewards. One-shot post-native dispatch clears its update callback before doing queued work. No idle polling, timers or custom DLL are used.

## Database and native interfaces

SQL clones the active America's identity defaults, Washington's leader defaults, the active Scout and Barracks, then all relevant available unit/building companion tables. The only Scout scalar gameplay change is strength 6; the Hub's bonuses are additive. Scoped `MCPVP` identifiers and unique VFS basenames prevent collisions. The builder loads Shared compatibility tables first, before alphabetically ordered civilization modules; this is necessary because McPvP sorts before Shared. Existing native types are not rewritten.

Promotions provide Veteran/Final Battle/remembrance XP, Grace defense, kit indicators, Kangaroo mobility/defense, Flag defense and status indicators. Capital Culture uses five hidden binary-weighted buildings, giving an exact 0–18 total. Sabotage uses one noncapturable hidden building with verified `Building_YieldModifiers` rows. The union of all active attackers maintains it; it never stacks and ownership changes remove stale effects.

Source audits use official CP v151 commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`, retained in ignored `tools/reference/`. The audit verifies 71 invoked native method names, critical methods on their exact native objects, event argument signatures, damage forwarding and movement flag semantics. Native `SetXY` and `CanMoveOrAttackInto` require integer optional flags; `SetMadeAttack` and `IsInvisible` use actual booleans. BNW/CP's Information Era is **ERA_FUTURE**, confirmed by CP's `INFORMATION_ERA` define.

`UnitConverted(oldOwner,newOwner,oldID,newID,isUpgrade)` fires before the source unit is killed. A same-owner upgrade rebinds its serial, creation turn, Veteran identity, kit and outstanding cooldowns to the successor. Native conversion does not copy ScriptData, so the handoff explicitly tags the successor. The source's later prekill cannot delete its successor record. Non-upgrade or ownership-changing conversions clear transferable rights. Poison is explicitly transferred only across same-owner upgrades.

CP's `OnlyDefensive` promotion blocks melee, but `IsCanAttackRanged` ignores it. Flag carriers also exhaust ordinary attacks when their status is applied; the verified `MustAbortAttack` hook guards combat resolution, including Blitz/ranged edge cases. Ordinary upgrade/gift/delete commands are vetoed by `CanDoCommand`; `UnitCanHaveAnyUpgrade` blocks other normal upgrade paths. Forced conversion safely loses flags and infiltration.

## Persistence and idempotency

Length-delimited, deterministic, bounded table encoding is stored inside `MCPSTATE1` player ScriptData. Unit records use an owner-scoped monotonically increasing serial plus native ID and creation turn; copied tags cannot impersonate a different current native unit. City references use plot coordinates, original owner and founding turn, checked against current ownership. Current/lifetime Legacy, cycle boundaries, all ledgers, Feast status, flags, cooldowns, missions, debuffs and remembrance are saved after changes. Poison resides in the affected unit's `MCPPOISON1` block, with remaining ticks, source and last processed owner turn. Unrelated ScriptData is preserved.

Claims are committed before native rewards, training is recorded once per unit, city raid/mission ledgers reset only at cycle boundaries, and kill identities are deduplicated per cycle. Hardcore ordinary kill Legacy is capped at 15 and the active-Feast battle bonus at 10. Barbarians, city-states and zero-cost military types cannot supply kill Legacy. Kills originate from actual native prekill events; no artificial opponents are spawned. Claims and all economic rewards work for rival Feast claimants.

Native public Lua does not reliably identify a third-party script summoning a permanent ordinary paid unit type. Such a unit can be a normal war casualty. No reward is granted merely for arbitrary unit creation, conversion or a repeated hit on a living unit. Other mods that fabricate native training/kill events or rewrite ScriptData remain outside the guarantee.

The Feast search runs at most three times during Hardcore preparation: initially, after Grace Period and at the announcement deadline. This accommodates turn-zero games with no capital and gives the first Scouts time to explore; it never announces with less than three scaled turns of preparation. Ability targeting scans only its one/two-tile radius, AI city targets are bounded by distance, and ordinary foreign movement is ignored unless it reaches a live Feast. McPvP units reconcile on their owner turn and relevant events; active poison only scans affected owners. Debuff reconciliation scans cities once per global turn or after city ownership changes. No per-frame map scan exists.

## Deliberate translations and limitations

- Static original geometric art, original insignia and native Scout battlefield/unit-flag art replace custom animated art. No external copyrighted textures, music or voice lines are required. Native diplomacy supplies generic fallback situations beyond the authored greeting, war, peace and defeat text.
- A Feast's notification coordinates and Locate button are the map indication. It is an objective recorded on a plot, not a new permanent improvement that could destroy an existing improvement. A unit must remain at the tile for the deferred native check; passing through it is insufficient.
- The site search checks land-area connectivity, legal terrain and neighboring exits, not full route reachability. Narrow bridges, closed borders beyond the site and tactical obstacles can still make a particular site difficult. If none exists, the match proceeds without a Feast victory.
- Endermage uses the victim's native destination legality and an empty adjacent tile. It never forces a stack, enters a city or bypasses impassable terrain. Stomper and Thor also exclude units occupying cities. Direct damage uses native death handling rather than artificial combat.
- Flag return requires an owned city/working-city tile. Death loses the flag and notifies both sides; there is no separate dropped-flag object. A city's raid remains consumed after failure, deliberately preventing repeated flag farming.
- Poison always has two fixed damage ticks, rather than adding ticks on slow speeds. Ability damage and XP awards are unscaled. Economic/Culture awards scale by the actual speed and era, as documented in the guide.
- AI follows conservative native adjacent steps and actual objectives. It can stall, and the game's subsequent tactical AI may change its plans. No free scores or fake enemies compensate for this.
- The human Browser submits gameplay commands to the owning addin, using the established collection single-player architecture. Network commands are rejected; multiplayer/hotseat are unsupported and unverified.
- Corrupt/newer McPvP state is preserved and refused, with Lua.log diagnostics. Native engine exceptions can interrupt a reward after a claim is committed; it will not pay twice.

All systems remain active after Legacy Unforgotten. No calendar-year test, collapse, unit deletion, arbitrary Legacy spending or permanent native building/yield alteration is used.
