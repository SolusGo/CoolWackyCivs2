# Exact engine limitations

This file is part of the release contract. The original request permits a closest robust implementation when DLL restrictions prevent a perfect one, provided differences are disclosed. **This implementation does not satisfy every non-negotiable check in the original specification.**

| Requirement | Implemented behavior / remaining gap |
| --- | --- |
| Unlimited potential cultural territory | Implemented. Custom claims use map adjacency and native ownership, with no mod radius limit. Water and wrapped maps are supported by the algorithm; live verification remains open. |
| Work any-distance eligible owned tile | Implemented through virtual assignments and six evaluated plot yields. Distance itself is not capped. |
| Remote count limited only by population | **Unmet.** Each safe forced reservation comes from withdrawing one native tile worker. Available native workers, preserved local locks and specialists impose an additional structural capacity limit. Surplus unemployed population cannot be safely forced into an arbitrarily large reservation pool through the verified APIs. |
| No free/doubled citizen yields | Implemented for supported assignments: one real reserved citizen per credited plot, original native plot unworked, native labourer yields subtracted, ledger deltas applied once. Mid-action validation trims unsafe/invalid contributions. Native event order still needs live regression testing. |
| Native worked-tile behavior | **Partial.** A virtual tile is not marked natively worked. Worked-terrain/improvement/resource counters, Village-style worked development, worked-only Tourism, Golden Age yields dependent on worked state, and conditional “has worked tile” triggers are not comprehensively simulated. `GetYield` reflects the native evaluated value, but cannot force every worked-state-dependent effect. |
| Additional CP/custom yields | Food, Production, Gold, Science, Culture and Faith are supported. Other yields and separate plot Tourism are not injected. |
| Never retain another city under any mechanism | **Unmet for arbitrary external transfers.** Normal founding/training and military acquisition are prevented. Unexpected city ownership is corrected after the native action; a transient second city can exist. If there is no eligible living non-Boundless recipient, a city remains quarantined rather than being illegally deleted. |
| Destroy ordinary conquered cities automatically | **Unmet.** Military capture is blocked for all cities. Units can besiege them but cannot occupy or initiate automatic destruction. |
| Protected capital safety | Implemented conservatively: no forced deletion/illegal razing; native acquisition is not recursively mutated in its capture hook. |
| Standard Domination | Not normally available because foreign original capitals cannot be held. No global victory rules are changed and no untested alternative is supplied. |
| AI long-distance development | Shared frontier/workforce and idle Worker mission support are implemented. Ocean/other-area development and interactions with later homeland-AI orders are not fully covered or verified. |
| No continuous UI polling | Implemented. Dirty events coalesce into one callback that uninstalls itself before execution; unchanged state does not mutate native workers. UI refreshes are event-driven and rows are paged. |
| Full native game verification | **Not run.** SQL and simulations are not a substitute for a launched CP v151 game. |

The current API cannot safely meet the full combination of arbitrary-distance native working, unlimited forced reservations and synchronous interception of every acquisition without DLL support or invasive global engine changes. This repository intentionally contains no custom DLL and makes no such global changes.

Use this preview for testing and development. If a future CP version exposes a population-reservation setter or safe pre-acquisition veto, those APIs should replace the structural workarounds. Do not remove these disclosures until the new behavior passes native game tests.
