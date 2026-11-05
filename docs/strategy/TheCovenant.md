# The Covenant - strategy guide

[Player handbook](../StrategyGuide.md) · [Matchups](../Matchups.md) · [Full mechanics](../../TheCovenant/README.md)

**Leader:** The Scribe  
**Playstyle:** Mandatory Scripture recall with a conventional Faith and Culture economy  
**Suggested victories:** Culture or a protected research economy

Protect population, production and borders while learning five passages. Written on the Heart adds +1 Culture per city. An unaided review earns 10 Faith and 5 Culture multiplied by the era index plus one, at most once per game turn, including examinations.

## Opening priorities

Recall Revelation before moving starting units. Study its five numbered sections aloud, hide the text, then enter the reference and every section in order. The next four introductions cover the remaining passages. Settle, explore and defend normally; a Scriptorium supplies 2 Faith and 1 Culture.

## Develop the engine

Tabernacles supply 3 Faith and 1 Science with the Temple cost, technology, maintenance and prerequisite building classes. Recall rewards supplement infrastructure. Successful unaided reviews expand intervals to 2, 4, 8 and 12 turns; at most one ordinary review occurs per turn.

## Convert the advantage

Use religious and cultural development for normal victory routes. Every tenth campaign turn requires all five passages in rotating order. Three consecutive unaided reviews mark mastery, but mastered passages remain in the review schedule. A failed or studied attempt resets that passage streak.

## Pros

- Frequent retrieval practice links references, exact wording and repeated reviews.
- City Culture and early religious buildings support gradual economic development.
- Successful unaided recall converts memory practice into useful era-scaled yields.

## Cons and opportunity costs

- Mandatory recall interrupts play and provides no skip button.
- Mistakes or studying forfeit that passage reward and shorten review spacing.
- The civilization has no unique military unit or special combat advantage.

## Playing against this civ

- Pressure infrastructure and deny safe growth with ordinary military and diplomatic tools.
- Protect exposed borders rather than treating memory rewards as military strength.
- Compare sustained city yields and conventional research against individual recall payouts.

## Common mistakes

- Recognising the displayed passage without rehearsing its reference and exact words.
- Neglecting defense or population while concentrating exclusively on Faith generation.
- Assuming mastery ends examinations or that each examination passage grants another reward.

## Who pressures whom

Named custom-civilization matchups are conditional mechanical analysis, not tested win rates. All custom civs are human-only and multiplayer is unsupported; these comparisons are for theorycraft or explicitly configured scenarios, not ordinary random AI opponents. General counterplay applies to normal single-player games.

| Situation | Other civ | Why it matters |
| --- | --- | --- |
| Opportunity | [Pigeon Republic](TheRepublicOfPigeons.md) | Safe development supports both economies; compare sustained city yields rather than individual recall rewards. |
| Opportunity | [Children of the Kingdom](TheChildrenOfTheKingdom.md) | Both support religious development, while prayer and Grace remain distinct from Covenant word recall. |
| Threat | [The Triumphal Imperium](TheTriumphalImperium.md) | An under-defended border invites military pressure; recall rewards do not counter Victory Momentum. |
| Threat | [The Boundless City](TheBoundlessCity.md) | Compact territorial development can pressure conventional multiple cities; recall yields do not replace workforce infrastructure. |

## Implementation limits

The gate requires manual entry, tolerates case and punctuation in words, and compares reference components separately. Bulk insertion changes are rejected, but clipboard origin cannot be proven from EditBox text changes. Native keyboard dispatch, popup ordering and save-file continuation require in-game acceptance testing. See TheCovenant/docs/Testing.md.

## Rules and evidence

Advice follows the shipped mechanics. Map, era, army composition, difficulty and execution can reverse a matchup. Culture supports policies; a Culture victory still needs Tourism and its normal conditions. Native inherited unit/building statistics follow the active CP ruleset.

- [TheCovenant/README.md](../../TheCovenant/README.md)
- [TheCovenant/Lua/CovenantMemory.lua](../../TheCovenant/Lua/CovenantMemory.lua)
- [TheCovenant/UI/CovenantGate.lua](../../TheCovenant/UI/CovenantGate.lua)
- [TheCovenant/SQL/00_COVENANT_Core.sql](../../TheCovenant/SQL/00_COVENANT_Core.sql)

The same authored material generates the civilization and leader Civilopedia guides. Existing narrative chapters follow the gameplay guidance.
