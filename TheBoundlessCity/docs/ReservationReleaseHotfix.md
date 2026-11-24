# Citizen-reassignment crash repair — 2 November 2026

The turn-135 campaign dump records a deliberate CP v151 fatal stop at `CvCityCitizens.cpp:1550`, inside `DoApplyTileChange`: initial allocation attempted to add an already-worked plot. The native stack runs through Lua `City:DoTask`, the remove-labourer branch, `DoReallocateCitizens` and `DoInitialAssigment`. Boundless v23's reservation reset called that branch once per withdrawn labourer. The latest turn-130 autosave had seven withdrawals and a completed schema-3 state. The exact reason the governor's batch became stale remains unproven; this repair removes that bulk governor invocation from Boundless workforce reconciliation.

## Changed behavior

Reservation reset first removes this mod's remote credits and their labourer compensation through the existing journal. It then returns each real ordinary labourer individually to a legal, currently unworked native local tile using `AlterWorkingPlot`. It prefers previously withdrawn jobs, then the existing local score. Each call rechecks native `CanWork`, work status, ordinary defaults and absence of automatons. It never clicks the city center. Checking `CanWork` avoids the native ownership-override branch, which would otherwise run the full governor again.

The observed transition must both work the chosen tile and decrease the native default count by one. A completed transition is journalled even if an external Lua callback raises afterward. The withdrawal side also rechecks each planned row so an intervening callback cannot turn a stale withdrawal into a return.

Blocked or resisting cities retain `releasePending` for later attempts. Pending returns provide no forced-reservation proof and earn no remote credit of their own. Actual ordinary labourer losses clamp the retry count. Unknown external automatons suspend returns. With no legal native local job, a person may remain an idle labourer until a tile becomes available; this repair does not force them into a specialist slot or call the bulk governor to find another job.

The native single-tile return sets that tile's forced-work flag. The optional saved `nativeReturns` map distinguishes these mod-created flags from the player's locks, so the remote planner can move those people again in Manual and Hybrid modes. The native governor can still honor that flag, as with a manual tile click; it is cleared when that job is withdrawn or ceases to be forced/worked. No unsupported native unlock API is used.

Both new fields are optional within schema 3; existing snapshots load with empty defaults. Collection UUID, package version 23, minimum compatible save version, yields, population, and the BCY2 ledger format are unchanged. A new campaign is not required. Avoid downgrading after saving the new optional ownership records.

## Installation and verification

Run `python tools/hotfix_boundless_reservations.py` for a read-only preflight, then add `--apply` to install. The installer accepts only the reviewed v23 UUID, original source hashes or an already installed repair, and matching manifest MD5s. It refuses a running game, preserves backups under `dist/turn135-backups/`, changes only three Lua files and their manifest checksums, verifies the written bytes, and rolls back on failure. Other installed versions and unrelated files are untouched.

`reservation_release.lua` rejects any workforce call to the captured bulk-governor task, exercising release/reassignment, twenty end-turn renewals, reload and legacy snapshots, returned-lock ownership, blocked/no-op returns, callback errors after mutation, automatons, population loss and stale withdrawal rows. It fails against the captured original Citizens source and passes with the repair. The existing workforce, frontier, UI, Food, planner, fault, siege and AI suites also pass. These are Lua simulations and API/source checks, not a native campaign replay.

Native acceptance: fully restart through Mods with the same roster, reload the turn-130 autosave, advance past turn 135 and complete another turn. Check remote and local workers, Food, and that `crashlogs` has no new citizen-reassignment dump. Preserve the original save and dump until that replay succeeds. Separate Tokenized Intelligence startup/UI and White Room combat errors are outside this repair.
