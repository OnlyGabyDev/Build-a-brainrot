# Progress map

_Last updated: 2026-09-30. Keep this current: it's how a new chat picks up the work._

## Where we are
The core game is **complete and playtested** (GDD §15, sprint steps 1–12). We're in **step 13: polish**, starting with art.

### Built (all playtested in Studio)
| Area | What works | Where |
|---|---|---|
| Data | Session-locked saving, currencies, parts, completions, rebirth data, receipts, boosts, wheel spins | `Services/DataManager` |
| Tycoon | 6 plots, purchase buttons, Cash Pad, Zone 1 (Toy Workshop) + Zone 2 (Plushie Sewing Room, a back room) | `Services/TycoonManager` |
| Production | Server-timed lines, one-part-one-line rule, Equip Best, completions + edition jackpot, mixed-part sockets | `Services/ProductionManager`, `Shared/BrainrotModels` |
| Assembly animations | Part by part. Toy Workshop: claw + wooden pusher robots. Plushie room: sewing needle, thread spools, stuffing pump | `StarterPlayerScripts/ProductionVisuals` |
| Loot | Rolls + shared map loot boxes (rarity gating, upgrade odds, Rare+ announcements), prize wheel + reveal | `Services/LootManager`, `Client/UI/Loot`, `LootBoxes.client` |
| UI | HUD counters, Line menu, Index (catalog), completion banner, Rebirth menu, Shop, Daily Wheel | `Client/UI/*`, `UIController.client` |
| Gadgets | Morphs + Tralalero Sneakers, Sahur Baton (knockback, safe in plots), Ballerina Dance | `Services/GadgetManager`, `GadgetsClient.client` |
| Rebirths | 50K ×3 cost, +25% income each, Rebirth Shop (Income, Speed, Luck) | `Services/RebirthManager`, `Client/UI/RebirthMenu` |
| Monetization | 5 gamepasses (config-driven perks), Gem/Roll/Spin products with receipt de-dup, Daily Wheel | `Services/MonetizationManager`, `Services/DailyWheelManager` |
| Art | **In progress:** voxel pipeline (`Shared/VoxelArt`) plus voxel Tralalero and Tung Tung Tung Sahur | `Shared/Art/*` |

## Current task: voxel brainrots (START HERE)
The pipeline works: the voxel Tralalero already runs on the lines in game (60 fps, no errors). What's left is art, one brainrot at a time.

**How it works**
- Each brainrot gets `sync/ReplicatedStorage/Shared/Art/<BrainrotId>.luau`, which returns `{ VoxelSize, Palette, Parts = { Legs, Body, Arms, Head } }`. Each part is a list of shapes from `Shared/VoxelArt.luau`: `box`, `ball`, `cylinder` (upright), `carve`, `mirror`.
- Voxel units: X is left/right (0 = the center line), Y is up (0 = the ground), **-Z is the front** (the face). Voxel size is 0.25 studs, and brainrots are ~22–28 voxels tall (~6–7 studs, like the placeholders).
- Later shapes paint over earlier ones. Keep **different parts from overlapping** (overlapping cells of different colors flicker).
- `BrainrotModels` uses the art automatically (template cached per part, then cloned). No art means colored placeholder blocks. Mixed-part builds attach at the body's sockets (bounding-box centers), so a head from one brainrot lands where the body's own head would be.
- Copy the style of `Art/TralaleroTralala.luau` (a head in front of the body, sneakers made with a helper) and `Art/TungTungTungSahur.luau` (face features painted onto a cylinder's front surface).

**Reference: *Steal a Brainrot*** (the user asked for this). Plan:
1. Search the web for each brainrot's *Steal a Brainrot* look (the fandom wiki has renders).
2. Download an image into the session scratchpad with curl, and look at it with the Read tool (it shows images).
3. Keep the silhouette and signature colors. Split into Head/Body/Arms/Legs in a way that makes sense for the character (e.g. Tralalero's "arms" are fins, and a bomber's could be its wings).

**Previewing in Studio** (edit mode, no playtest needed)
1. With `execute_luau` (Edit), require `ReplicatedStorage.Shared.BrainrotModels`, build all 4 parts with `CreatePart(id, partType)` into a Model in `Workspace.ArtPreview`, and `PivotTo` it somewhere empty like (300, 0, 0).
2. Aim the camera from the model's pivot: `cam = pivot.Position + pivot.LookVector*10 + pivot.RightVector*5 + (0,4,0)`, looking at `pivot.Position + (0,3.2,0)`. Take **one** `screen_capture`.
3. **Delete `Workspace.ArtPreview` when done.** It's a Studio instance and isn't synced.

**Status**
- Done (first pass): TralaleroTralala, TungTungTungSahur. Both still need a *Steal a Brainrot* reference check; Tralalero's legs didn't show clearly in the preview, so verify them.
- To do (roster in `Config/Brainrots`, with rarity): BrrBrrPatapim, LiriliLarila, TrippiTroppi (Common); BallerinaCappuccina, ChimpanziniBananini, BonecaAmbalabu (Uncommon); CappuccinoAssassino, BombombiniGusini, FrigoCamelo (Rare); GlorboFruttodrillo (Legendary); BombardiroCrocodilo, LaVacaSaturnoSaturnita (Mythic); SupremoBrainrotto (Godly: our own original design, see GDD §3).
- After each brainrot: `sh tools/typecheck.sh`, a preview screenshot, then commit and push. Tick it off here.

## Next up (after the brainrots)
From the polish backlog (GDD §15), roughly in this order:
1. UI polish: the sticker-book Index (§8 polish target), a nicer loot wheel, more color and effort everywhere.
2. The facility and map: real factory rooms instead of flat plots, and a hub map instead of the baseplate.
3. Per-rarity loot box looks and effects (a Godly black hole).
4. Sounds and music.

## Before going live
- Create the gamepasses and developer products on the Creator Dashboard, and paste their ids into `Config/Gamepasses` and `Config/Products`.
- Set the place's Max Players to 6 (one plot each).
- Test on a live server (DataStores, purchases).

## Known quirks
- Azul's sourcemap can miss new modules; `tools/typecheck.sh` works around it.
- Studio test data lives in the `PlayerData_Studio` DataStore.
