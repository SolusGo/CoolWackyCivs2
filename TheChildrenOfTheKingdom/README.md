# The Children of the Kingdom

**The Faithful · Sanctuary · Thy Kingdom Come**

A sincere, fictional civilization inspired by the Lord's Prayer (Matthew 6:9–13), for Civilization V: Brave New World with **Community Patch v151**. Favor Culture and Diplomacy, build Houses of Prayer, and protect experienced Keepers while consistent prayer strengthens the capital.

This civilization is **human-playable only**. `Civilizations.AIPlayable=0` prevents ordinary random AI assignment. Every custom reward, building bonus and promotion is restricted to a living human Kingdom player. Forced AI instances receive ordinary inherited Pikeman/Temple functionality without custom extras. There is no prayer automation or AI strategy implementation. Multiplayer and hotseat are unsupported by the collection.

## Prayer

Choose The Faithful in modded single-player setup, found Sanctuary, then select **Prayer** at the upper right of the map. The panel shows the next petition, its words and effect, all seven stages, cooldown, Grace, temporary blessings and any saved Production reserve. Select **PRAY** once to receive the current blessing and advance. A notification confirms the action. The panel closes for city view, diplomacy, interface-mode changes and modal screens; it can be reopened on the world map.

The first petition is available immediately after founding a capital. Pray at most once every **5 Standard turns**. Cooldown and temporary durations both use the active speed's actual `TrainPercent`, rounded to the nearest whole turn, minimum 1: Quick 3, Standard 5, Epic 8, Marathon 15. Era level is the native current era plus one, starting at 1. Instant rewards are not additionally speed-scaled.

| Order | Petition | Blessing |
| --- | --- | --- |
| 1 | Address — Our Father in heaven | Capital +2 Faith and +1 Food per turn for the scaled duration |
| 2 | Opening Glory — Hallowed be Your name | Immediately 10 Faith per Era level |
| 3 | Seek — Your kingdom come, Your will be done | All owned cities +15% actual Culture production for the scaled duration |
| 4 | Ask — Give us this day our daily bread | Capital immediately receives 8 Food per Era level; 8 Production per Era level is credited safely to its queue/reserve |
| 5 | Repent — Forgive us our debts, as we forgive our debtors | +2 Global Happiness, counted once, for the scaled duration |
| 6 | Protection — Lead us not into temptation, but deliver us from evil | +20% native City Strength throughout the empire; military units +15% defensive strength in friendly territory for the scaled duration |
| 7 | Closing Glory — For Yours is the kingdom, the power, and the glory forever | 20 Golden Age Points per Era level, one permanent Grace, 10 Faith per currently owned completed House; reset to Address |

Every Grace adds **+1 Faith and +1 Culture per turn in the current capital**, permanently. At the maximum of seven Grace, further complete cycles give **25 extra Golden Age Points per Era level** instead of another stack, in addition to the ordinary 20. Capital-specific effects move when the capital changes; neither capture nor reload duplicates them.

**ASK production safety:** all 8 × Era Production is awarded once. The current finite unit/building/project receives only its remaining cost. Excess, or the entire award when the queue is empty or running a process, stays in the saved Daily Bread reserve shown in Prayer. It is applied when another finite capital queue is selected or at the next turn. The reserve follows the capital; it never edits native overflow, completes arbitrary orders, creates objects or converts a process into a free unit. This explicitly disclosed queue-safety behavior can delay using some Production. Food uses the native stored-Food API; ordinary growth occurs at the normal economic tick.

## Unique content

**Keeper of the Faith** replaces Pikeman with its active base statistics, normal model, anti-mounted promotions and upgrade path. Human Kingdom Keepers receive **Stand Firm**, retained through upgrades: +15% defensive strength in friendly territory and +5 HP per eligible friendly-territory healing turn. Normal healing rules apply; this grants no healing after moving or automatic instant healing. Protection provides a distinct temporary +15% defense, so a Keeper defending at home can receive both, +30 percentage points in total. Neither promotion adds attack strength.

**House of Prayer** replaces Temple and retains every active native scalar and companion row, including CP prerequisites, costs, maintenance and religion interactions. Completed Houses owned by a human Kingdom player additionally grant +1 Faith and +1 Culture through a removable dummy. Closing Glory counts real completed Houses only, once per petition. Houses under construction and foreign-owned Houses do not count.

The closing doxology is retained as a seventh gameplay stage. Its use varies among Christian traditions; the Civilopedia explains the fictional framing respectfully.

## Installation and development

Enable BNW, Community Patch v151, and **Cool Wacky Civs 2 (v 8)** through Mods. This civilization is included in the collection; it has no standalone mod UUID and adds no external sound or music assets. The existing four civilizations remain in the same collection.

```powershell
.\.venv\Scripts\python.exe tools/generate_kingdom.py
.\.venv\Scripts\python.exe tools/prepare_kingdom_art.py
.\.venv\Scripts\python.exe tools/standardize_icons.py --refresh-sources CK_CIV_ATLAS CK_OBJECT_ATLAS CK_LEADER_ATLAS
.\.venv\Scripts\python.exe tools/build_mod.py --manifest-only
.\.venv\Scripts\python.exe tools/validate_kingdom.py
.\.venv\Scripts\python.exe tools/validate_mod.py
.\.venv\Scripts\python.exe tools/build_mod.py
```

Regenerating SQL requires the installed read-only game cache and CP database files described in the collection README. The committed SQL and DDS are sufficient for installation. Source audits use ignored pinned official sources; `tools/audit_cp.py --fetch` fetches shared sources and `tools/validate_kingdom.py --fetch` fetches the additional policy source. New development environments can create `.venv` and install `requirements-dev.txt` first.

See [implementation and file inventory](docs/Implementation.md), [actual validation and native checklist](docs/Testing.md), [art provenance](../art-source/TheChildrenOfTheKingdom/README.md), and [changelog](CHANGELOG.md). **Automated simulation/static validation is distinct from unperformed native gameplay and save testing.**
