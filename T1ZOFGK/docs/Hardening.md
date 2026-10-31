# Corrective audit — 2026-10-31

This is a reliability correction to version 19. Every combat, experience, healing, production, formation and cooldown number remains unchanged. Existing art and unit models are preserved.

## Confirmed failures and corrections

| Finding | Evidence | Correction |
| --- | --- | --- |
| Delayed city-state gifts leaked roles/formation | `CvPlayer::AddIncomingUnit` snapshots before prekill. `CvMinorCivIncomingUnitGift::applyToUnit` later restores saved promotions after UnitCreated without UnitConverted. Original `Created`/foreign turns never validated that later copy. | Native `LostOnGifting=1` on the five roles and four temporary effects; targeted post-gift, movement, creation-queue and load reconciliation. Scouted Talent and development retain gifting/upgrading persistence. |
| Returned delayed gifts bypassed that native filter | `applyToUnit(..., bReturn=true)` explicitly ignores LostOnGifting. Original movement only refreshed auras and did not reject unauthorized owned roles. | Validate the current owner, saved slot/token and registered unit identity before retaining a role. Returns cannot reclaim a vacancy or consume another initial slot. |
| A roleless acquired Recruit could return as an apparent local birth | CP serializes promotions but not unit ScriptData in its delayed gift record. A same-turn roleless return has neither a changed birth turn nor an old role to identify it. | Append one hidden, zero-bonus acquired-provenance promotion. It survives native snapshots/upgrades and mirrors existing FOREIGN state. It excludes acquisition from initial recruitment while preserving earned history. |
| Foreign synergy alone survived loading | Original initialization stripped foreign synergy only when a role promotion was also present. | Clear unauthorized formation independently of role presence; recompute pressure/support from current sources. |
| A copied token could steal a real member's role or vacancy | A synthetic copy of a token and promotion passed the original conversion/prekill slot comparison even while the actual member remained alive. | Require the registered owner, ID, unit type, native birth turn and lifetime token together. Prefer the existing registered member during reconciliation. Dying authorized units still create their vacancy even at lethal HP. |
| Damage/health morphs and class replacement earned false development | CP calls `convert(..., true, false)` for `DoConvertOnDamageThreshold` and `SetUnitClassReplacement` without emitting UnitUpgraded. The original code counted the generic flag. | UnitUpgraded records a persistent destination proof; UnitConverted consumes it once after copying. Normal and goody upgrades count; health morphs, class substitutions, level-ups and duplicate callbacks do not. |
| Militaristic gifts could enter the initial roster | Native DoSpawnUnit creates the receiving player's type, then emits MinorGiftUnit. OriginalOwner can therefore already be the receiving player. | Treat the post-spawn MinorGiftUnit callback as acquisition proof for the pending recipient/type, before initial recruitment. |
| Fresh checkout setup was incomplete | T1 needed promotion/unit source files absent from the old fetch inventory; paths were hardcoded and missing inputs failed deep inside tests. | Shared standard-library preflight, configurable snapshot/CP paths, verified v151 mod metadata and pinned source manifest, full source fetch inventory and explicit setup guide. |

The controller now keeps immutable lookup records for roster identities instead of trusting cached unit userdata. A vanished source cannot contribute a phantom aura. A bounded queue visits newly created objects after native initialization settles; it never enumerates foreign armies on every turn. Duplicate Created callbacks do not requeue settled members. Pressure/support is reconciled even when an unauthorized unit moves outside every source's ring.

## Suspicions disproved or bounded by source

- **Ordinary direct CP capture does not copy the defeated unit's promotions.** `getCaptureDefinition` has no promotion snapshot; `createCaptureUnit` initializes a new type and applies its native free/capture rules. It does not use `convert` or restore the deceased veteran's individual promotion history. A captured Recruit can receive Scouted Talent from its type, not from copying the old unit. The confirmed leak is delayed gifting, not a demonstrated ordinary capture exploit.
- Immediate native gifts and enemy-to-barbarian conversions call `convert`, whose event follows promotion copying and precedes source death. The original ordinary gift/upgrade regressions already passed; the new guards preserve that behavior.
- UnitUpgraded occurs before native promotion copying for both ordinary and goody upgrades. It is safe as a proof event, not as the point to mutate the destination's final development tier.
- Keria's receiver promotion only adds native territory healing. The movement/embarkation/blockade checks in `canHeal` remain in control; no Lua damage/heal grant was added. These are source and simulated checks, not native healing acceptance.
- In-place ownership mutation and manual late promotion copies in tests are **defensive other-mod scenarios**. They do not establish that CP exposes an ordinary Lua SetOwner API or that direct captures copy roles.

The pinned files and exact checks are recorded in [Validation.json](Validation.json). Original failing cases and the corrected production controller are replayed by [HardeningValidation.json](HardeningValidation.json). [ArtInventory.json](ArtInventory.json) freezes all 49 DDS, the static scene and the official emblem source against the original release.

## Timing boundaries and remaining limits

Delayed gifts apply promotions after Created and provide no UnitConverted callback. Forward city-state gifts have a post-copy PlayerGifted callback. Returns can be reconciled on post-copy movement; if there is no movement, the queued unit is reconciled at the first subsequent native player boundary. Native flags prevent forward role transfer, but the return filter is explicitly bypassed by the engine, so an old copied role may exist within that synchronous native operation until the first available hook. No frame polling or unsupported hook is claimed.

Gift callbacks identify recipient/type, not a destination unit ID. Only still-pending matching births are quarantined; normal trained/purchased units have already consumed their birth receipt. A scripted free Recruit created reentrantly for the same recipient/type can also be conservatively excluded. The existing exact-site/same-turn direct-capture quarantine remains. Native free Recruit births otherwise settle at an owner boundary; loading a partially initialized object does not promote it prematurely. Starting replacements still settle during the initial game setup.

Legacy in-flight gifts contain their old promotion snapshot. Unauthorized roles are removed even without the new provenance bit. Existing FOREIGN-tagged units gain that bit when reconciled. A legacy roleless, same-turn gift snapshot without ScriptData/provenance cannot always be distinguished from an unrelated scripted fresh birth; CP exposes no correlated identity for that case. Future recognized acquisitions carry the provenance bit. Native acceptance must include legacy in-flight delivery and return.

No-event changes by other mods are reconciled when the affected unit is next observed through a known movement/lifecycle event, an owner reconciliation or loading. Arbitrary third-party state injection between hooks cannot be intercepted immediately without scanning/polling, which this controller avoids.

## Save compatibility

Existing saves are **expected to remain compatible**, subject to the pending native tests. Civilization/unit/building identities, collection UUID/version, old promotion identifiers, token strings, slot encodings, cooldowns and previous development tiers are preserved. The acquired marker is appended after every released promotion, leaving earlier insertion order intact. It has zero combat/XP effects and is hidden from the unit panel.

`[T1Z1_UP=...]` is an optional in-progress upgrade proof. Completed old upgrades require no receipt or migration. Existing `[T1Z1_FOREIGN=1]` data is preserved and gains native acquired provenance as needed. Other mods' ScriptData remains intact. Native direct capture recreates a unit without the old XP/development; the controller does not invent that lost history. Immediate/delayed conversions which actually carry Scouted Talent/development keep it.

The simulated upgrade checkpoints recreate the Lua controller while the modeled native operation continues. They are not a claim that arbitrary mid-C++ `.Civ5Save` checkpoints can resume. Real disk saves before/after upgrades, transfers and cooldowns remain in the [native checklist](Testing.md).

## Files and validation

Gameplay changes are localized to `Lua/T1Z_Controller.lua` and the matching SQL/generator flag/marker definitions. Dedicated mocks/cases exercise that production controller; shared changes cover preflight, read-only database paths and CP source fetching. Modinfo hashes are rebuilt. No texture, portrait, map, flag, original painting or 3D model is regenerated.

Executed on 2026-10-31:

| Check | Actual result |
| --- | --- |
| Original v19 replay | 25 isolated Standard-speed cases; 14 failures reproduced |
| Corrected shipped controller | 25 isolated cases at four speeds; 100 runs, 308 assertions, zero failures |
| Existing lifecycle suite | 183 assertions at each of four speeds; 732 assertions passed |
| Prerequisite/read-only fixtures | 12 tests passed |
| CP v151 contracts | 74 T1 static checks and 184 shared source-audit checks passed |
| Full collection validator | Passed, including all civilization regressions, Lua/XML, DDS and registration checks |
| Released identities and art | Baseline comparison preserved every earlier type/ID; all 49 DDS and frozen source/scene hashes matched |
| Native Civ V | **NOT RUN**; real combat/healing, disk saves and the manual checklist remain pending |

The database profile was an archived BNW snapshot with installed CP v151 schema overlaid in memory. This is SQL compatibility evidence, not proof of a live activated CP session. Before/after results and the current controller hash are recorded in `HardeningValidation.json`; detailed current results are in `Validation.json`.

[Reproduction prerequisites](../../docs/ValidationSetup.md) · [Testing and native acceptance](Testing.md). Validation results are updated only after execution; no native game/render/save acceptance is claimed.
