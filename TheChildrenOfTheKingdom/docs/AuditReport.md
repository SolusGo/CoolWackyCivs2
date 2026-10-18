# Implementation audit — 2026-10-18

Baseline: `e292435`. Scope: targeted correctness and compatibility fixes for the existing civilization. No civilization rewrite, balance pass, art replacement, DLL change or save-schema migration.

## Confirmed defects and fixes

| Severity | Confirmed issue | Correction |
| --- | --- | --- |
| P2 — medium | A direct `K.Pray`/`CKPrayer_Pray` request succeeded in City View or other incompatible screens because only the button checked interface state. A leader message could also be ignored while an existing leader root was still hidden. | `CK_Interface.lua` now owns one shared native interface gate used by both `K.CanPray` and the panel. It checks selection mode, City View, leader messages/root visibility, modal contexts, pending transitions and addon visibility. Missing required UI APIs fail closed. Existing active-human/turn/cooldown/stage/deadline guards remain; capital ownership and reconciliation-in-progress are also checked. Rejected requests grant nothing and do not change saved progression. |
| P2 — medium | A tracked player's saved blessing clock stopped during temporary nonhuman control. Returning control after its expiry could revive a temporary blessing. | `PlayerDoTurn` continues aging the existing tracked clock, including while control is nonhuman. Human checks still remove all effects and reject prayer. No AI prayer state is initialized, and stage/Grace/rewards never advance automatically. |
| P3 — low | With a missed popup event, native visibility hid Prayer but left its internal opened flag set, so the panel unexpectedly reopened after the modal closed. Closed-panel city dirtiness also skipped visibility recovery. | Hiding the interface now closes its panel state. City and game dirtiness share the existing coalesced one-shot refresh, including while the panel is closed. The callback detaches before rendering; rapid transitions and idle frames do not leave an update loop. |

Each of these three defects was reproduced by a failing regression before its correction. The expanded tests now pass. Missing capital ownership, stale/malformed requests and reentrancy are defensive validation coverage, not claims that the native capital API normally returns a foreign city.

## Protection: native city defense versus ranged attacks

**Decision: retain `Policies.CityStrengthMod=20`. It increases both native city defense and ranged-strike strength.** The Prayer effect text and policy help now disclose the ranged effect as well as the existing guide/implementation notes. Unit Protection remains a separate, strictly defensive +15% in friendly territory, including the native embarked-defense path.

The pinned official CP v151 source is commit `44c1e14ff75d80c1dba5c8a71e8289439a53aafb`:

- `CvPlayer::processPolicies` passes `GetCityStrengthMod()` to `ChangeCityStrengthMod`; that setter refreshes city strength.
- `CvCity::updateStrengthValue` applies the percentage before capturing `iStrengthValueRanged`. Both defense and ranged caches therefore contain the policy's effect.
- `CvCity::getStrengthValue(true, ...)` starts from that ranged cache. Native CP ranged adjustments do not cancel this policy percentage.

Alternatives were inspected against the active schema and native implementation:

| Candidate | Why it is not a safe equivalent |
| --- | --- |
| `Policies.DefenseBoostAllCities` | A flat strength addition, applied before the ranged cache is captured. It is neither the requested blanket percentage nor defense-only. |
| `Buildings.BuildingDefenseModifier` / flat building `Defense` | Modify building-derived defense rather than the full native city-strength formula. They do not provide the requested blanket +20% and can interact with ranged calculations. |
| `UnitPromotions.AdjacentCityDefenseMod` | This native percentage is defense-only, but depends on nearby or garrisoned units and sums their contributions. Requiring defenders changes the blessing; adding hidden dummy units introduces occupation, stacking, ownership and maintenance concerns. |
| Production-process defense | Depends on city Production and the selected process. Replacing queues would interfere with ordinary city behavior and ASK. |
| Negative garrisoned ranged modifier | Only applies with a garrison; an additive ranged modifier cannot exactly cancel the city-base percentage across different native modifiers and rounding. |
| Direct city-strength setter / legacy player defense field | The inspected Lua city bindings expose strength query/update, not a direct strength setter. The legacy `GetCityDefenseModifier` getter provides no usable blanket defense-only city setter. |

No safe, unconditional native defense-only +20% replacement was found. Per the audit request, the reliable existing policy is preserved instead of adding a combat-damage interception or hidden-unit workaround. Source-contract tests lock in the relevant cache ordering and this documented behavior. Actual native attack/defense previews and damage remain to be verified in game.

## Systems verified without rewriting

- **ASK is unchanged.** Food is granted once after the saved stage/deadline advances. Production credit fills only the remaining whole-point cost of a finite unit/building/project queue, preserving fractional progress. Empty and Wealth/Research/process queues retain the full reserve. It survives reload and follows the player's legitimate capital; a captured city cannot consume it. The expanded lifecycle test covers relocation, capture, reload, an oversized reserve and a stale ASK replay.
- **Grace and prayer progression are unchanged.** All seven stages, every reward, completed-House counting, the seven-stack cap, +1 Faith/+1 Culture per stack, extra 25 Golden Age Points per Era level at the cap, and game-speed rounding retain their existing values. Exact dummy counts and saved deadlines continue to reconcile without cumulative reload rewards.
- **Keeper healing, defense and upgrades are unchanged.** Stand Firm still gives +5 eligible friendly healing and persists through upgrades; its +15% defense stacks with the independent temporary +15%. `DefenseMod` affects native melee/ranged defense, `EmbarkDefenseModifier` covers the separate embarked path, and neither adds attack strength. The native city healing formula uses a neutral branch for another team's cities, but movement eligibility must be checked first: `canMoveInto` forbids ordinary military destinations in another player's city, and `canEndTurnAtPlot` uses that destination check. A heal-rate-only model initially suggested a missing bonus in a position a Keeper cannot legally reach; that proposed change was removed. No reachable native healing defect was established, so all three existing promotion definitions remain unchanged.
- **House of Prayer is unchanged.** Exact active Temple inheritance, human-only +1 Faith/+1 Culture and 10 Faith per completed currently owned House at Closing Glory are preserved.
- `AIPlayable=0`, human-only gameplay guards, existing civilization/unit/building IDs, collection UUID, native version 8, all art assets, other civilizations and the original nine-field `CKPRAYER1` save block are preserved. No AI strategy or automation was added.

## Save compatibility and implementation evidence

The new interface module holds only transient screen flags. It is imported through the existing addin and does not introduce another simulation owner or save block.

The three original promotion definitions and their numerical fields are unchanged. CP serializes unit modifier counters such as `m_iExtraNeutralHeal`; preserving the definitions avoids unnecessary cached-counter compatibility risks. No new promotion, migration or additional persistent player/unit state is introduced.

Native UI calls and context names were inspected in the installed BNW `Assets/DLC/Expansion2/UI/InGame` sources: `InGame.lua`, `InGame.xml`, `TopPanel.lua`, `LeaderHead/LeaderHeadRoot.lua` and `Popups/SocialPolicyPopup.lua`. These verify interface mode, City View, leader-root state, actual modal visibility and the context callback/control APIs used by the shared gate. Missing required APIs reject activation safely.

Native source/schema checks and save-counter models support compatibility; they are not a native saved-game round trip. Existing saves still require the checklist below.

## Exact changed files

| File | Change |
| --- | --- |
| `TheChildrenOfTheKingdom/Lua/CK_Interface.lua` (new) | Shared interface gate and transient screen state, moved from the panel |
| `TheChildrenOfTheKingdom/Lua/CK_Core.lua` | Loads shared gate |
| `TheChildrenOfTheKingdom/Lua/CK_Blessings.lua` | Authoritative interface/ownership/busy validation |
| `TheChildrenOfTheKingdom/Lua/CK_Events.lua` | Ages tracked nonhuman-control deadlines |
| `TheChildrenOfTheKingdom/UI/CK_Prayer.lua` | Uses shared flags/gate; closes hidden panels and coalesces city dirtiness |
| `TheChildrenOfTheKingdom/SQL/10_CK_Text.sql` | Availability/help text and explicit ranged-city-strength disclosure |
| `tools/generate_kingdom.py` | Reproducible availability/help text changes |
| `tools/validate_kingdom.py` | Seven suites; expanded native city/healing/movement/save contracts; preserves three existing promotions |
| `tools/tests/kingdom_activation.lua` (new) | Direct invalid requests, native/missing APIs, transitions, stale/reentrant payloads and exact no-side-effect checks |
| `tools/tests/kingdom_unit_rules.lua` (new) | Native healing/movement eligibility models, upgrades, combined defense and AI cleanup |
| `tools/tests/kingdom_lifecycle.lua` (new) | Temporary nonhuman control, unchanged reserve capital/capture/reload behavior and Grace/elimination |
| `tools/tests/kingdom_ui.lua` | Missed-event panel closure, 50 rapid transition sequences, mixed dirty-event coalescing and idle frames |
| `tools/tests/kingdom_mock.lua` | Native city ownership in the engine double |
| `Cool Wacky Civs 2 (v 8).modinfo` | Registers the shared include, updated file checksums |
| `CoolWackyCivs2.civ5proj` | Matching VFS/project inventory |
| `TheChildrenOfTheKingdom/README.md` | Audit link and current testing status |
| `TheChildrenOfTheKingdom/CHANGELOG.md` | Dated audit fixes |
| `TheChildrenOfTheKingdom/docs/Implementation.md` | Current gate/healing/clock architecture and retained constraints |
| `TheChildrenOfTheKingdom/docs/Testing.md` | Expanded automated coverage and native checklist |
| `TheChildrenOfTheKingdom/docs/AuditReport.md` (new) | This report |
| `README.md` | Current suite count and audit link |
| `CHANGELOG.md` | Collection audit entry |

## Validation and remaining native work

Automated verification executes the shipped Lua under Lua 5.1 with a native-engine double and executes SQL against an in-memory copy of the installed BNW/CP schema. Models and source contracts are explicitly identified; no Civilization V launch is claimed.

The validation record covers:

1. `tools/validate_kingdom.py`: all seven suites, complete collection SQL, exact Pikeman/Temple inheritance, speed/reward invariants, native source contracts, XML, localization and all 34 DDS references.
2. `tools/validate_mod.py`: the entire collection's regression suite, manifest/project/VFS checks, original-collection coexistence and icon/DDS checks.
3. `tools/audit_cp.py`: the shared pinned CP v151 source/ABI assertions.
4. `tools/build_mod.py`: updated ZIP and genuine 7z/LZMA Civ5Mod; package integrity and packaged manifest checksums are checked separately.

Execution results and local logs are recorded in [Testing.md](Testing.md). The following remain **unverified in the native game**: direct-command rejection during real diplomacy/city/modal transitions; actual city defense/ranged previews and damage; legal friendly-territory healing, moving/healing eligibility and upgrade/transfer cleanup; native old-save load/save round trips for Grace, cooldowns, blessings and reserves; capital capture/recapture; all four game speeds; long campaigns and live coexistence/rendering. The full native checklist remains in Testing.md.

All seven petitions, Grace, UU, UB, narrative and human-only restrictions remain intact. There are no numerical balance changes.
