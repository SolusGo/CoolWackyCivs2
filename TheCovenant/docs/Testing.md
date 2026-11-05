# Covenant validation and native acceptance

Run `python tools/validate_covenant.py` with the repository's development dependencies. Database checks use the existing read-only BNW/CP database adapter and explicit prerequisites.

Offline checks execute the shipped Lua 5.1 engine and mock UI. They cover all supplied wording, corrected John 14:29, missing/extra/reordered words, references, five introductions, same-turn anti-farming, clean streaks, bounded review intervals, rotating five-passage exams, unfinished save restoration, invalid payloads, pasted text changes, study timers, input capture, rewards and balanced timer semaphores. The package check verifies hashes and VFS flags. SQL checks validate human-only selection and replacement rows without modifying installed databases.

The native game has **not** been verified. The attempt to launch the existing Civ V app through the desktop tool timed out during app approval. No test campaign was played. Model input capture is not proof of native keyboard handling, and model reconstruction is not a native save-file round trip.

## Native checklist

1. Enable BNW, Community Patch v151 and Cool Wacky Civs 2 v24. Start a new single-player Covenant game.
2. Confirm the opening study gate precedes unit actions and all numbered Revelation sections fit. Confirm the countdown must expire before recall.
3. Confirm Escape, Return, game shortcuts and outside clicks cannot dismiss the gate. Confirm normal character entry works, and multi-character paste is rejected.
4. Type a wrong word, confirm the passage restarts at its reference, then complete every section. Confirm play resumes and no learning-attempt reward appears.
5. Confirm the first five turns introduce the five passages. Confirm subsequent reviews and the campaign-turn-10 five-passage exam.
6. Save mid-section and during an exam, quit and reload from the modded load screen. Confirm remaining checks, assistance and reward limits persist.
7. Test at 1024×768 and a larger resolution, alongside the pack's other panels and native popups. Test a new game as another pack civilization and confirm no Covenant gate.

Do not report these native checks as passed until they have been played.
