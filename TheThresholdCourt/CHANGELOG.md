# Changelog

## 1.0.1 corrective hardening / collection 1.14.1, mod version 17 — 2026-10-26

- Remove unintended Washington primary/shared gameplay trait inheritance. Only the three native personality companion tables remain eligible for cloning; validate Queen Elsewhere's complete trait relation and generator output.
- Release surviving gifted/converted units after an originating owner's elimination at a safe PlayerDoTurn boundary strictly after the crossing turn. Handle unknown origins with saved quarantine when no Court owner lives; isolate failed unit cleanup and preserve all unrelated state.
- Narrow movement dispatch opt-ins to potential transfer types, preserve pre-existing opt-ins, and require a current validated stamp for movement/upgrade vetoes. Test the actual shipped Jin leash veto on the same event bus.
- Prevent prepared/confirmed receipt recovery from consuming or granting moves/attacks in a later owner-turn; reject semantically invalid numeric receipts. Retain the existing receipt architecture, balance, save blocks, UI, artwork and localization.
- Add four-speed regression cases and expanded pinned CP source contracts. Native runtime acceptance and automatic repair of cached Washington bonuses in old saves remain unverified; start a new game for a clean trait baseline. See [corrective audit](docs/Hardening.md).

## 1.0 implementation preview — 2026-10-26

- Register Queen Elsewhere, The Threshold Court, Hingeguard, Threshold House and complete English Civilopedia/Dawn/diplomacy.
- Implement real same-unit city relocation, exact paid success, T+8 origins, one empire crossing per owner-turn, persistent identity/receipts and exhaustion restrictions.
- Add event-driven destination/confirmation UI, original leader and guardian art, collection-style doorway symbols, DDS atlases and map.
- Add installed-schema SQL/inheritance checks, executable Lua 5.1 scenarios, source audits and package integration. Native gameplay, rendering and real-save acceptance remain pending.
