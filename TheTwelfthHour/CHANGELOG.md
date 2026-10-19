# The Twelfth Hour changelog

## 2026-10-19 — Initial implementation

- Added the human-only Keeper of Seconds, Last Minute and all twenty city names, When the Clock Strikes, Pendulum Guard and Municipal Clocktower.
- Added six-played-turn Chimes through native Production/Science modifiers; synchronized next-turn staging at CP PlayerDoneTurn avoids relying on the post-harvest PlayerDoTurn hook.
- Added deterministic save reconstruction, interturn phase persistence, once-per-Chime notifications and city/building/ownership lifecycle cleanup.
- Preserved all active Pikeman/Workshop scalar and installed direct companion rows; added upgrade-retained Movement/friendly-territory strength and additive permanent Culture.
- Added original painted icons/leader/loading art, alpha/flag assets, complete English text, generated packaging and validation.
- Added actual-schema SQL, altered baseline inheritance, ten Lua 5.1 simulation runs, seventeen pinned CP source contracts and full-collection packaging/regression checks. Native Civ V execution, actual yield settlement, autosave resumption and rendered UI acceptance remain pending.
