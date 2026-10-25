# The Kingdom of the Unrung Bell

**Keeper Sable · Stillhaven · Culture / Science · Advanced · intentionally human-only.** Requires Windows Civilization V: Brave New World and standalone Community Patch v151. Part of Cool Wacky Civs 2, mod version 14 / 1.11.0 preview.

Implementation preview: database, gameplay Lua, persistence, English Civilopedia/diplomacy and original artwork are integrated and automated checks pass. **Native gameplay is not verified. Exact exclusively owned-target combat behavior is not available through CP v151's native friendly-land modifier.** See the limits below; this is not a claim that every specification requirement has been met.

## Silence Before the Storm

At the end of each uninterrupted peaceful owner-turn, advance a persistent civilization-wide counter. Quietude is `min(3, floor(counter / 5))`: 0 at 4 turns, 1 at 5, 2 at 10, and 3 at 15 or any later count. Each stack gives every currently owned city **+1 Culture** through genuine city building yields. Newly founded or acquired cities inherit the current stack count. Barbarians never interrupt this counter; wars with majors or city-states do.

A qualifying war immediately snapshots and consumes Quietude, resets the peaceful counter, removes the ability Culture and conditional Belfry Science, and activates the Great Toll at the consumed strength: **+5% / +10% / +15%** friendly-land combat for eligible land military units. Zero Quietude grants no Toll. Additional wars during the same continuous wartime period neither stack nor refresh it. Complete peace ends it immediately; new Quietude must be earned for another activation.

## Bellwarden — replaces Pikeman

Inherits the active Pikeman's entire scalar row and all installed companion tables, including costs, technology/resources, combat class, anti-mounted promotions, sounds, upgrade class, flag and strategic/model art. Its additional permanent **Vigil of the Bell** promotion grants **+1 Sight and +15% friendly-land combat**, retained on upgrade. No 3D model is added or replaced. During Toll III the unique modifiers add to **+30%**, alongside ordinary combat modifiers.

## Silent Belfry — replaces Temple

Inherits all active Temple scalar/companion properties and requirements. Adds **+1 permanent Culture** in the database. A Belfry city also gains **+1 Science per Quietude stack**, up to +3; an ordinary Temple does not qualify. At three stacks the total unique additions are **+4 Culture and +3 Science**, above ordinary Temple benefits. War removes +3 Culture and +3 Science but leaves the permanent +1 Culture and inherited Temple benefits.

## Great Toll timing

A full owner-turn window runs from that player's `PlayerDoTurn` callback to the next such callback, including intervening enemy turns. Activation is immediate. If the owner turn has already begun, its remaining portion is an extra partial window and does not count. The next five full windows retain the Toll; the start of the sixth removes it. An off-turn activation also lasts immediately until the next start, then through five full windows. Peace can cut any window short. No other player's turn increments this clock. `Game.GetGameTurn()` is used only to deduplicate callbacks and identify the partial activation turn, never to calculate elapsed duration.

Quietude increments on `PlayerDoneTurn`, after the owner's actions. It becomes visible immediately then and feeds the next native yield settlement. CP settles city yields before `PlayerDoTurn`; initialization never pretends to award a prior yield or a completed turn.

## War events and save data

`Events.WarStateChanged(teamA, teamB, atWar)` follows the DLL's change to one side's relationship. The handler overlays that notified pair while querying other qualifying wars, so it works for either direction and does not wait for the other team's flag. Duplicate notifications cannot consume twice. The pre-change `GameEvents.DeclareWar` and `MakePeace` hooks have option-dependent ABIs and are deliberately unused. Owner-turn boundaries and context initialization reconcile against actual relationships as a scoped fallback. War beginning and ending between owner turns is handled by the notification, not inferred later.

One versioned `Modding.OpenSaveData()` record per player (`UNRUNG_STATE_V1_<playerID>`) stores peace progress, war guard, Toll strength, begun windows, last begin/end tokens and interrupted/activation-turn guards. Writes use Firaxis dot calls and readback. Consumption and duration are committed together before effects are applied. Unknown/corrupt records are preserved and conditional effects disabled; no free replacement state is awarded. Ordinary globals only cache controller ownership, not authoritative gameplay state.

Loading restores records, reconciles actual war, repairs city yields and units, and sanitizes foreign city/unit lists once. It never awards a peaceful turn or advances the Toll. Recreated contexts retire old handlers. Binary dummy setters are idempotent and suppress construction rewards. Native save rollback, end-turn autosave resumption and quick-load ordering still require in-game acceptance.

## Compatibility and verified limits

- **Combat deviation:** CP v151 `FriendlyLandsModifier` checks the melee battle plot, but treats same-team and open-border territory as friendly. Ranged combat uses the shooter's plot. A ranged unit can therefore receive its bonus while firing from friendly land at an enemy-owned target; an attack from foreign land into owned land does not receive the native ranged bonus. This differs from the requested exclusively Kingdom-owned target rule. `FriendlyLandsAttackModifier` would use the origin and double-count some cases, so it remains zero. No worldwide `CombatPercent` is granted. An exact solution requires a compatible DLL modification; none is bundled.
- Source and schema checks use the pinned official v151 code and installed CP schema. The backup database is a menu/vanilla cache with installed schema additions, **not an observed CP-activated gameplay database**. Runtime inheritance reads active rows when the mod is activated, including changed costs/stats and installed companion effects. Full Vox Populi, later CP, third-party schema extensions added after generation, multiplayer, hotseat and Mac are outside this target.
- The post-change DLL call to `GameplayWarStateChanged` is verified in source; synchronous delivery to the UI Lua event and resulting native yield/combat refresh are still in-game tests. No per-frame polling, global CityView replacement, map-wide scanning, custom audio or DLL dependency is introduced.
- City/unit setter or save API failures log bounded diagnostics and are repaired on later lifecycle/owner-turn events. An unavailable native setter can leave an existing effect stale until it recovers; corrupt/newer save data requires investigation rather than automatic resetting.
- The specified diplomacy lines are registered under existing response categories. As the civilization is human-only and this collection supports single-player, routine AI encounters with Sable are intentionally unavailable.

## Installation, saves and testing

Build with `python tools/build_mod.py` and install `dist/Cool Wacky Civs 2 (v 14).zip` through the Mods folder as described in the collection README. Remove the older collection folder before installing. **Start a new game to select Sable.** Existing identifiers and insertion order precede this addition; the collection UUID and minimum compatible save version are retained, but older-save continuation is unverified. Back up saves. This is not a migration promise.

Run `python tools/validate_unrung.py`, then `python tools/validate_mod.py`, build, and `python tools/verify_release.py`. These test SQL in memory, inspect pinned source, decode DDS and execute the shipped controller under Lua 5.1 mocks. They do not launch Civ V. See the [full acceptance matrix](docs/Testing.md), [implementation details](docs/Implementation.md), [source evidence](docs/SourceAudit.json), and [machine-readable validation](docs/Validation.json).

In game, select Sable in modded single-player, verify absence from AI leader selection, settle two cities and construct a Belfry in one. End 4, 5, 10 and 15 peaceful turns and inspect building/city Culture and Science. Save at each boundary, declare both directions of war, test city-state involvement, and compare the next five full windows and sixth-start expiration. Check combat previews for both sides, owned/enemy/open-border plots and ranged firing tiles, keeping the documented native deviations explicit.
