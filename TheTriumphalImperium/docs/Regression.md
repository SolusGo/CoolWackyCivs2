# Collection regression

Result: PASS all collection regression checks. The core/package/Pigeon/Red phase and the remaining-civilization phase were run separately after repairing legacy localization-reference parsers. Already-passed core checks were not repeated.

All 1378 files in the twenty pre-existing civilization folders retain their SHA-256 hashes, including every Laureate Commonwealth file. One legacy JSON report write in the final phase was suppressed; earlier phases also suppressed their legacy report writes so the existing files remain unchanged.

This includes database activation, native Civilopedia indexing replay, all shipped Lua syntax, per-civilization mock contracts, UI contracts, DDS decoding, original-collection namespace coexistence and the generated manifest/project inventory. These are not in-game tests.

Final phase elapsed test time: 18.8 seconds. The preceding core and civilization phases ran separately.
