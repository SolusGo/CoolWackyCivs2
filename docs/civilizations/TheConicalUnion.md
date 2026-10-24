# The Conical Union

**Leader:** High Marshal Bollard · **Capital:** Permanent Detour · **Victories:** Science / Domination · **Complexity:** 3/5 · **Human only**

Sentient traffic cones administer an efficient empire of roads, defensive offices and extremely durable temporary closures.

- **Sorry for the Inconvenience:** +2 Production/+1 Culture in every connected non-capital city.
- **Road Crew:** Worker replacement with +1 Movement and +25% base Work Rate for all ordinary Worker actions; inherits the active CP Worker.
- **Detour Office:** Walls replacement retaining its active benefits, adding +1 permanent Culture and +2 Gold when connected outside the Capital.

Use faster improvements to support expansion, connect settlements and protect them with Offices. Connections are binary and use native CP semantics, including qualifying Harbors. The Capital gains only an Office's permanent Culture. Costs, road upkeep, technology and other native restrictions remain unchanged.

The economy rewards infrastructure investment and can be disrupted by broken connections. No direct combat or Science bonus, era scaling or extra unique system is present. The connection flag is cached; reconciliation uses lifecycle/targeted city events and owner-turn fallbacks, so the first settlement after a refresh may still use the old state. Native gameplay, rendering and save compatibility remain unverified.

[Full guide](../../TheConicalUnion/README.md) · [Implementation and timing](../../TheConicalUnion/docs/Implementation.md) · [Testing record](../../TheConicalUnion/docs/Testing.md) · [Artwork](../../art-source/TheConicalUnion/README.md)
