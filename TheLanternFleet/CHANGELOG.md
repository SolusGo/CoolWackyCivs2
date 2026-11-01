# Changelog

## Corrective audit — 2026-11-01

- Preserve the exact civ design, SQL, 40 DDS assets, models and existing-save completion receipts. Preserve newer commits and unrelated uncommitted work; no new collection version.
- Prevent initial fresh/scenario turn suppression; use native loaded/start-turn predicates and a non-economic late observer. Native lifecycle/event delivery still requires acceptance.
- Journal all frozen city targets before setters, acknowledge writes, commit completion afterward, retain pending recovery across reload and cancel captured targets. Add independent persistent zero-only capture cleanup and safe receipt quarantine.
- Retain the original 27 scenarios; pass 75 Lua 5.1 scenarios and eight failing-before/fixed-after baseline regressions. Add actual research-progress/stock diagnostic samples and a report-preserving collection runner.
- Native tests not run: user explicitly prohibited launching Civ V. Verdict: **STATICALLY VALIDATED, NATIVE ACCEPTANCE PENDING**. [Report](docs/Hardening.md).

## 1.0.0 — 2026-11-01

- Add High Keeper Maren, First Beacon, No Harbor Goes Dark, Beacon Cutter and Signal Lighthouse with the exact requested yield/combat values.
- Append database records after released content; clone active Trireme/Lighthouse scalar fields and available companion tables. Include coastal bias, human-only selection, English Civilopedia, requested Dawn text and dialogue.
- Store economic snapshots only in the two specified real dummy buildings. Add a separate saved turn receipt for duplicate/reload suppression; clear both buildings on every city capture.
- Include five original paintings, 40 mipmapped DXT5 DDS assets and one invisible simulation entry. No custom 3D models or panel.
- Pass 27 Lua 5.1 scenarios and actual-schema/inheritance/art/registration checks. Native launch attempted but blocked by Computer Use application permission; executable event mapping, synchronous dispatch and actual same-turn settlement remain unverified.
