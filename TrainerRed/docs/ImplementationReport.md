# Implementation report — 2026-10-16

Trainer Red is integrated into Cool Wacky Civs 2 version 7. **Automated validation is not native gameplay certification.** This report records both implemented mechanics and their boundaries.

## Files

- `TrainerRed/SQL`: six ordered SQL files for identity, active General/Hospital/Heroic Epic inheritance, effects/projects, promotions, atlases and English text.
- `TrainerRed/Lua`: `RED_Core`, `RED_SaveData`, `RED_Training`, `RED_Combat`, `RED_PokemonAce`, `RED_PokemonAbilities`, `RED_MtSilver`, `RED_AI`, `RED_Events`. One simulation owner, small per-player ledgers and event-driven work.
- `TrainerRed/UI/RED_TeamPanel.xml` and `.lua`: six-slot panel, separate world-map launcher and explicit action gateway.
- `TrainerRed/Art`: 58 mipmapped DDS textures and static leader-scene XML. Custom civ/unit/building/project/rank/Ribbon/Bond/Summit/identity/status symbols, alpha atlas, unit flag, map, leader art and Dawn artwork.
- `art-source/TrainerRed`: two original generated illustrations, icon preview, prompts/provenance; four retained icon masters under `art-source/IconAtlasMasters`.
- `TrainerRed/README.md`, `CHANGELOG.md`, this report, `Testing.md`, `OriginalSpecification.md`; `docs/civilizations/TrainerRed.md` and root roster/changelog updates.
- `Shared/SQL/00_OptionalCompatibility.sql`: preserves optional legacy metadata tables when installed and supplies empty compatible definitions when absent. Red skips optional American cultural/colonial metadata; the collection no longer accidentally requires JFD tables from the development cache.
- `tools/generate_red.py`, `prepare_red_art.py`, `validate_red.py`, and Red simulation fixtures. Builder, shared icon finisher, project and modinfo updated for the third civilization and version 7.

## Implemented systems

The civilization/leader are playable and AI-playable. Every specified baseline Training source and exclusive rank, team capacity tier, team XP/capture protection/healing, strongest-type Momentum claim, original-capital Ribbon/General reward, dynamic Plateau/Hall yields, Ace lifecycle, item cooldown, Center food/healing/training/refund/airlift, Mt. Silver journal/countdown/penalties/return, six identities, Summit benefits, AI commands and roster controls have executable implementations. No military replacement party is synthesized. City/spy names and near-silent diplomacy use the supplied identities.

The full numerical rules are in the gameplay README and localized help. SQL uses actual schema fields. General, Hospital and Heroic Epic companion tables are inherited at activation, preserving supported CP relationships and native General generation rather than reproducing a partial approximation.

## Persistence and transaction boundaries

Native Player ScriptData holds a length-prefixed, bounded, deterministic version-1 ledger. Unit ScriptData carries a namespaced owner/serial tag; it is explicitly transferred in `UnitConverted` **before the source dies**. IDs are merely lookup hints. Destroyed serials become tombstones; copied or resurrected tags cannot reclaim a dead veteran. Different owners receive new records. Foreign converted units lose this mod's private promotions.

The ledger includes Training, roster slots/manual mode, Ribbons, identities, upgrade lineage, Ace snapshots/tokens, item/withdrawal/turn cooldowns, Momentum/capital claims, Hall count, full-capacity unlock, healing/refund journals, airlift allowances and Mt. Silver snapshots/phases. Snapshots preserve type, ScriptData, name, original owner, base HP, damage, XP, level, promotions, facing, AI role, movement/attack/activity/embark information, promotion readiness, native leader/religion values and temporary-promotion expiry. Expired temporary effects are not restored; surviving veteran expirations retain their original deadline. Return restores recoverable information, safely exhausts movement and chooses a legal friendly domain plot. Arbitrary third-party unit-private C++ fields, mission queues, transport relationships and third-party Lua tables have no generic serialization interface and cannot be reconstructed by this mod.

Withdrawal saves the whole party before removing any member. Returning saves each recovered serial and clears its withdrawn flag. Blocked members remain pending while completed members remain mapped. Penalties are replacement bits, and are removed at the countdown boundary even if a return is pending. No `OpenSaveData` mirror is used as authority: loading an older save rolls claims and snapshots back with that save. Corrupt/newer envelopes cause a logged error rather than a fresh team or overwritten payload.

## Verified CP source contracts and workarounds

The reference is [official Community Patch v151 source at commit 44c1e14](https://github.com/LoneGazebo/Community-Patch-DLL/tree/44c1e14ff75d80c1dba5c8a71e8289439a53aafb). `validate_red.py` checks registered native method names and event ABIs, including conversion-before-kill and the damage callback's actual semantics. Supplemental fetched sources remain under ignored `tools/reference`.

1. **Damage:** `CvCombatInfo::getDamageInflicted` invokes `BattleDamageDelta` repeatedly. The callback consumes no cooldown, deals no damage, and claims no reward. Blastoise's incoming ranged reduction and lethal Pikachu escape use nonpositive deltas. CP v151's positive-delta path clamps against the **source** HP, which can reduce damage or dereference an absent city attacker. Pikachu's flat bonus and Lapras's +25% therefore apply once after native resolution; real surviving targets can die to those bonuses before the single original-combat reward pass. Collateral/retaliation damage never recursively farms combat rewards. Combat previews may not include these post-combat bonus points.
2. **Pikachu withdrawal:** the incoming lethal melee blow and retaliation are canceled, then the survivor moves to a prevalidated adjacent tile and commits its cooldown after resolution. No legal tile means no escape. This models a withdrawal without moving a live native combat pointer in the damage getter. It retains ordinary attack/animation sequencing rather than replacing CP combat.
3. **Blastoise fortification:** CP exposes `CanFortify`/activity but no Lua `SetFortified`. A +20 Defence bridge supplies native v151's normal fortification bonus after an attack while sleep activity is set. The bridge disappears on movement/new attack or when native fortification starts, preventing double credit.
4. **Snorlax:** mutually exclusive movement-limit promotions reduce native maximum Movement to one; movement events enforce the one-tile anchor even on roads. Reactive ZOC exhausts land movement when traversing two adjacent tiles, including units with normal ZOC immunity. CP exposes no universal force-retreat veto. Native heavy-charge displacement is corrected back to the saved anchor **when that tile remains legal**. If occupied, or if another mod forces movement outside the observed combat path, absolute displacement immunity is unavailable. This is the remaining gameplay equivalence limit, not a claimed universal immunity.
5. **Healing:** guarded native damage notifications detect actual HP recovery. Proven's extra heal is exclusive and nonrecursive. Center territory is defined as owned tiles within three hexes; its extra healing is capped once per turn. Saved damage observations provide an owner-turn fallback. Native animation/visibility event behavior still requires live verification.
6. **Airlift:** a query-scoped `CityCanAirlift` response permits the explicit native mission without `Airlift=1` on the Center. Native legality remains authoritative; one source-city departure is saved per turn. Center-to-Center or Center-to-owned-Airport is allowed; an Airport-only origin uses the game's ordinary action. A queued asynchronous native mission must be checked in game; the command checks resulting coordinates before committing its allowance.
7. **Maximum HP/ZOC/terrain:** Summit uses verified `MaxHitPointsChange`, `IgnoreZOC`, `CanMoveAfterAttacking`; other scalar effects use real CP promotion fields. Range is a separate mutually exclusive grant removed when another positive Range promotion exists. Naval Lapras gets native ocean crossing; land Lapras gets native embarkation and Amphibious, never naval domain or direct placement on Ocean.
8. **War Weariness:** cache Red's bilateral value before the battle and reimburse only an increase from Summit combat after resolution. Pre-existing weariness is retained. CP-only games often have no such increment; full VP behavior is unverified.
9. **Four versus six:** the project explicitly permits four partners. Its return preserves exactly those partners. All six identities remain visible in the panel; unused identities may bind to later eligible recruits without creating units or retroactively granting Summit/Legendary/Ribbons.

## Art, audio and performance

The built-in image tool generated an original adventurer homage after rejecting the first named-character image. Both approved paintings are retained locally and copied into runtime DDS files. Strategy-game medallions follow the existing collection's code-native icon system and shared gold-frame/padding rules. Legacy DXT5 textures use complete mip chains; non-multiple-of-four atlas dimensions use legacy RGBA with explicit full mip chains. The map is an original Kanto/Johto-inspired drawing. The detached Ace uses the native General world model, with custom portrait/flag.

The inherited America `SoundtrackTag` is the valid installed-game peace/war fallback. No new commercial music, silent missing-file stub or invented audio ID is distributed. Optional post-summit music is not implemented.

Turn reconciliation scans Red's units/cities, not the world. Aura work visits small radii around team identities. Strongest-type scans occur for relevant Red team combat only. The deterministic full-map spawn search runs only for return/detachment/recovery. Deferred creation/death reconciliation removes its update callback before executing. The UI has no frame polling and refreshes through events/explicit open.

## Verification status

See [Testing.md](Testing.md) for commands and required native checks. Automated tests cover actual-schema load/inheritance, collection loading with optional third-party metadata tables removed, Lua 5.1 parse/execution, rank exclusivity, capacity, healing, dynamic yields, serial conversion, trainer lifecycle, cooldowns, one-time rewards, save rollback, full/four-member/partial/crowded/capital-loss return, elimination, UI read-only behavior and AI project scheduling. Package validation decodes DDS and verifies manifest/project/VFS/MD5/load order.

**Not executed:** native Civ V playthroughs, live font/layout/leader selection/production/Civilopedia/audio, AI-only matches, native save round trips, network multiplayer or arbitrary other-mod movement/serialization. The preview does not claim these tests passed. Prior collection saves retain their existing state versions; native upgrades from version 6 remain a manual test.
