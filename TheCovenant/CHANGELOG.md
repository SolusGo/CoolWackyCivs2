# Covenant changelog

## Action recovery / v24 — 2026-11-06

- Release the Submit/Study re-entry guard even when a save, UI refresh or reward call throws. Retry persistence and repaint the current prompt before accepting another action; never replay the submitted answer or a partially applied reward.
- Add four fault-injection regressions covering Submit/Study rendering, transient save failure, an exception after native Faith mutation and a newly due exam after recovery. Refresh the new exam prompt while retaining queue/timer ownership. Preserve the curriculum, balance, save encoding and all original art.

## Original graphics / v24 — 2026-11-06

- Replace stock 2D portraits with original Scribe, Scriptorium and Tabernacle paintings, a Scripture/quill emblem, loading illustration and fictional map. Add a static leader scene using the same format as the other civilizations.
- Compile 43 full-mip legacy DDS textures: nine-size colour/alpha/leader/building families, a monochrome flag, three scene textures and three recall-panel materials. Retain the pack's gold rims and 90%/75% icon padding.
- Give mandatory recall a navy-and-gold panel and native four-state button skin; preserve all controls and queue/input behavior. Use the installed TwCenMT24 title font.
- Retain raw paintings, exact built-in imagegen prompts, deterministic heraldry and repeatable compiler/preview tools. Gameplay values, Scripture and save keys are unchanged.

## v24 reliability revision — 2026-11-06

- Parse book/chapter/verse/range independently; reject digit collisions and malformed references. Preserve all five supplied passages and numerical balance.
- Retain hidden queue ownership without periodic dequeue/requeue churn; make semaphore transitions idempotent and preserve drafts on reopening.
- Follow shipped SaveData dot-call usage, migrate valid original v24 payloads in place, and journal completion/reward caps together before granting yields.
- Settle carried reviews on their actual completion turn; catch up overdue examinations and keep a newly due exam mandatory before releasing the gate.
- Accept UTF-8 single-character edits, guard repeated submit callbacks, extend offline regression coverage and document native input/paste/foreign-queue limits.
- Register the existing Covenant strategy content in the collection's generated guide/Civilopedia workflow, repairing full-pack roster validation.

## Initial addition — 2026-11-06

- Added The Scribe, Written on the Heart, Scriptorium and Tabernacle.
- Added mandatory typed reference/word recall, timed study, exact word matching, spaced reviews, recurring five-passage exams and saved progress.
- Used the five player-supplied NIV passages with corrected John 14:29.
- Added Lua 5.1 engine and UI-model checks, actual-schema SQL and pack checks. Native gameplay, rendering, keyboard dispatch and save-file acceptance remain unverified.
