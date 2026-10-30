# T1 ZOFGK art sources and provenance

The **official red T1 emblem** is the unmodified original PNG `T1-Official-Red.png`, retrieved 2026-10-31 from [T1's official website](https://www.t1.gg/): [source image](https://images.squarespace-cdn.com/content/v1/62d09f54a49d6f1c78455cce/970025c6-e0f5-43bc-b4eb-73d6c1903c8c/T1%2Bred.png). T1 owns its name and emblem; no ownership or official endorsement is implied. The asset has a real alpha channel. The export crops transparent padding, preserves the authentic red silhouette and places it on charcoal inside the collection's gold-rimmed circle. Alpha/flag variants reuse the same silhouette in tintable white.

`Faker.png`, `ZOFGK.png`, `Recruit.png` and `Headquarters.png` are original paintings created for this mod using the built-in **imagegen** tool on 2026-10-31, from the prompts in [Prompts.json](Prompts.json). They are artistic interpretations, not archival photographs. The historical roster painting depicts five members of the 2023-2024 team; Faker's static scene supplies the leader portrait crop. The Recruit and Headquarters use a timeless Korean-influenced visual vocabulary compatible with Civ V's existing Warrior model. No generated logo replaces the official emblem in the civilization atlas.

Symbolic promotion artwork is original code-native heraldry, reproducible and editable in [prepare_t1zofgk_art.py](../../tools/prepare_t1zofgk_art.py): Zeus lightning, Oner jungle tracks, Faker crown/eye, Gumayusi bow, Keria shield/cross, Scouted Talent star, development chevrons, connected formation nodes, pressure crown and support shield. The `*Symbol.png` files and `Promotions.png` are lossless source renders. `Map.png` is an original commemorative Seoul/London route chart, not a real geographic or gameplay map.

`Icon.png`, `Alpha.png`, `Portrait.png`, `Objects.png` and `Promotions.png` are editable atlas masters. Retained collection atlas masters also live in `art-source/IconAtlasMasters/T1Z_*`. `Preview.png` shows the final framing; individual atlas sizes can be inspected in the Art folder. All outputs have complete legacy RGBA DDS mip chains, including the 45px UI sizes. Dawn is 1024x768; the static leader scene is 1600x900.

Regenerate only this civilization with:

```powershell
python tools/prepare_t1zofgk_art.py
python tools/build_mod.py --manifest-only --preserve-art
python tools/validate_t1zofgk.py
```

Historical reference: [Riot Games: Worlds 2024 Winners](https://www.leagueoflegends.com/en-sg/news/esports/worlds-2024-winners/). The in-game text explicitly treats ZOFGK as a historical lineup and credits the 2022 final appearance and 2023/2024 championships.
