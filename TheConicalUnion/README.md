# The Conical Union

**High Marshal Bollard** leads a human-only society of sentient traffic cones from **Permanent Detour**. Requires Civilization V: Brave New World and **Community Patch v151**, independently of full Vox Populi. Included in Cool Wacky Civs 2 version 13 / 1.10.0 preview.

| Unique | Effect |
| --- | --- |
| **Sorry for the Inconvenience** | Each connected non-capital city receives **+2 Production and +1 Culture**. |
| **Road Crew** — Worker | All active Worker properties/builds, **+1 Movement**, **+25% base Work Rate** across ordinary improvements, roads and repairs. Reuses the Worker 3D model. |
| **Detour Office** — Walls | All active Walls properties/effects, **+1 permanent Culture**, **+2 Gold** in a connected non-capital city with a real Office. |

The Capital never receives the UA or conditional Gold. Multiple roads, railroads, Harbors or mixed connections never multiply the bonuses. Native yield modifiers and suppression rules still apply. Three connected non-capital cities add a total of +6 Production and +3 Culture before Offices.

| City | Office | Additional Production | Additional Culture | Additional Gold |
| --- | --- | ---: | ---: | ---: |
| Capital | No | 0 | 0 | 0 |
| Capital | Yes | 0 | 1 | 0 |
| Disconnected non-capital | No | 0 | 0 | 0 |
| Disconnected non-capital | Yes | 0 | 1 | 0 |
| Connected non-capital | No | 2 | 1 | 0 |
| Connected non-capital | Yes | 2 | 2 | 2 |

Prefer Science or conventional Domination; complexity **3/5**. Improve resources, expand to useful sites and invest in connections. Offices defend vulnerable settlements while contributing modest Culture and Gold. Road upkeep and ordinary construction rules remain in force. The starting Capital receives no immediate UA benefit; disrupted connections interrupt development. There are no direct Science or combat bonuses and no era scaling.

Connections use `City:IsConnectedToCapital()`, the native CP network flag. Qualifying Harbor and mixed routes work by the engine's own rules. **Timing limitation:** this flag is cached, and `PlayerDoTurn` fires after city/economic settlement. Without an earlier lifecycle or targeted city-dirty notification, the first settlement following a network refresh can still use the previous dummy state; the turn callback repairs it for the following settlement. No instantaneous route-change behavior is claimed. See [implementation](docs/Implementation.md).

Install the version 13 collection archive using the [root instructions](../README.md). Enable BNW + CP + the collection, then start a new modded single-player game as Bollard. `Playable=1`, `AIPlayable=0`; no AI strategy or custom gameplay panel. The leader scene is a static original painting and the supplied Dawn of Man narrative is silent.

Automated SQL, source, Lua and DDS checks are separate from native acceptance. Game rendering, actual build progress, yield settlement, save/load and older-save continuation have **not** been verified in Civ V. See [testing](docs/Testing.md), [source contracts](docs/SourceAudit.json), [validation results](docs/Validation.json), [art sources/prompts](../art-source/TheConicalUnion/README.md) and [changelog](CHANGELOG.md).

**THE ROAD WILL BE CLOSED UNTIL FURTHER NOTICE.**
