# Progress map

_Last updated: 2026-09-30. Keep this current: it's how a new chat picks up the work._

**New chat? Read [CLAUDE.md](CLAUDE.md) first, then take the first unchecked task in the [Task queue](#task-queue).** One task per chat: finish it (type-check, playtest, commit and push), tick it off here, add anything the next chat needs, and tell the user it's done.

## Where we are
The core game is **complete and playtested** (GDD §15, sprint steps 1–12). We're in **step 13: polish**. The core loop's juice pass (sounds, effects, lights) is done; brainrot art is next.

### Built (all playtested in Studio)
| Area | What works | Where |
|---|---|---|
| Data | Session-locked saving, currencies, parts, completions, rebirth data, receipts, boosts, wheel spins | `Services/DataManager` |
| Tycoon | 6 plots, purchase buttons, Cash Pad, Zone 1 (Toy Workshop) + Zone 2 (Plushie Sewing Room, a back room) | `Services/TycoonManager` |
| Production | Server-timed lines, one-part-one-line rule, Equip Best, completions + edition jackpot, mixed-part sockets | `Services/ProductionManager`, `Shared/BrainrotModels` |
| Assembly animations | Part by part. Toy Workshop: claw + wooden pusher robots. Plushie room: sewing needle, thread spools, stuffing pump | `StarterPlayerScripts/ProductionVisuals` |
| Core-loop juice | Per-step sounds (plop, boing, servo, BONK, ratchet, sewing, squeak, pop), dropper squash, Assembler beacon, station paint/glitter with ×multiplier popups, coins hopping to the Cash Pad, PERFECT! confetti, rolling belts, build-in animation on purchase, Cash Pad coin pile + collect burst (coins fly to the HUD), arrows over affordable buttons | `ProductionVisuals`, `TycoonFX.client`, `Client/Effects` |
| Atmosphere | Lighting, bloom (Neon parts glow), color grading, pastel haze, shuffled background music, mute button (top right) | `Atmosphere.client` |
| Loot | Rolls + shared map loot boxes (rarity gating, upgrade odds, Rare+ announcements), prize wheel + reveal | `Services/LootManager`, `Client/UI/Loot`, `LootBoxes.client` |
| UI | HUD counters, Line menu, Index (catalog), completion banner, Rebirth menu, Shop, Daily Wheel | `Client/UI/*`, `UIController.client` |
| Gadgets | Morphs + Tralalero Sneakers, Sahur Baton (knockback, safe in plots), Ballerina Dance | `Services/GadgetManager`, `GadgetsClient.client` |
| Rebirths | 50K ×3 cost, +25% income each, Rebirth Shop (Income, Speed, Luck) | `Services/RebirthManager`, `Client/UI/RebirthMenu` |
| Monetization | 5 gamepasses (config-driven perks), Gem/Roll/Spin products with receipt de-dup, Daily Wheel | `Services/MonetizationManager`, `Services/DailyWheelManager` |
| Art | Voxel pipeline (`Shared/VoxelArt`) plus voxel Tralalero and Tung Tung Tung Sahur (13 brainrots still placeholders) | `Shared/Art/*` |

## Task queue
Roughly in priority order (the user: polish first, and the core loop matters most). Each task is sized for one chat.

- [x] **Core-loop juice pass** (2026-09-30): sounds, particles, lights, bloom, music. See the table above.
- [ ] **Brainrots A: Commons.** Voxel art for BrrBrrPatapim, LiriliLarila, TrippiTroppi, plus the *Steal a Brainrot* reference check for the two done ones (Tralalero's legs didn't show clearly in the preview). How-to: [Voxel brainrots](#voxel-brainrots-how-to).
- [ ] **Brainrots B: Uncommons.** BallerinaCappuccina, ChimpanziniBananini, BonecaAmbalabu.
- [ ] **Brainrots C: Rares.** CappuccinoAssassino, BombombiniGusini, FrigoCamelo.
- [ ] **Brainrots D: Legendary, Mythic, Godly.** GlorboFruttodrillo, BombardiroCrocodilo, LaVacaSaturnoSaturnita, SupremoBrainrotto (Godly: our own original design, GDD §3 and §16.11; propose the design in the chat before building it).
- [ ] **UI: the sticker-book Index** (GDD §8 polish target): big popped-out brainrots on rarity backgrounds, round edition buttons (gray/blue/green), more color everywhere. Needs the brainrot art first.
- [ ] **UI: the loot wheel** (the user finds it ugly) plus UI juice: sounds on opens/reveals, bouncier panels, the whole HUD more Pet Simulator–style (GDD §13, §15).
- [ ] **Facility and map:** real factory rooms instead of flat plots, and a hub map instead of the baseplate (GDD §15). Build it ourselves in code first (see CLAUDE.md, art preferences).
- [ ] **Per-rarity loot box looks and effects** (GDD §5, §16.16): a Godly box arrives through a black hole.

**Needs the user:** Claude can't hear audio, so every sound was picked by its library description. Ask the user to listen in a playtest and name any sound to swap; the ids are all in `Config/Sounds`.

## Voxel brainrots how-to
The pipeline works: the voxel Tralalero already runs on the lines in game (60 fps, no errors).
- Each brainrot gets `sync/ReplicatedStorage/Shared/Art/<BrainrotId>.luau`, which returns `{ VoxelSize, Palette, Parts = { Legs, Body, Arms, Head } }`. Each part is a list of shapes from `Shared/VoxelArt.luau`: `box`, `ball`, `cylinder` (upright), `carve`, `mirror`.
- Voxel units: X is left/right (0 = the center line), Y is up (0 = the ground), **-Z is the front** (the face). Voxel size is 0.25 studs, and brainrots are ~22–28 voxels tall (~6–7 studs, like the placeholders).
- Later shapes paint over earlier ones. Keep **different parts from overlapping** (overlapping cells of different colors flicker).
- `BrainrotModels` uses the art automatically (template cached per part, then cloned). No art means colored placeholder blocks. Mixed-part builds attach at the body's sockets (bounding-box centers), so a head from one brainrot lands where the body's own head would be.
- Copy the style of `Art/TralaleroTralala.luau` (a head in front of the body, sneakers made with a helper) and `Art/TungTungTungSahur.luau` (face features painted onto a cylinder's front surface).

**Reference: *Steal a Brainrot*** (the user asked for this):
1. Search the web for each brainrot's *Steal a Brainrot* look (the fandom wiki has renders).
2. Download an image into the session scratchpad with curl, and look at it with the Read tool (it shows images).
3. Keep the silhouette and signature colors. Split into Head/Body/Arms/Legs in a way that makes sense for the character (e.g. Tralalero's "arms" are fins, and a bomber's could be its wings).

**Previewing in Studio** (edit mode, no playtest needed):
1. With `execute_luau` (Edit), require `ReplicatedStorage.Shared.BrainrotModels`, build all 4 parts with `CreatePart(id, partType)` into a Model in `Workspace.ArtPreview`, and `PivotTo` it somewhere empty like (300, 0, 0).
2. Aim the camera from the model's pivot: `cam = pivot.Position + pivot.LookVector*10 + pivot.RightVector*5 + (0,4,0)`, looking at `pivot.Position + (0,3.2,0)`. Take **one** `screen_capture`.
3. **Delete `Workspace.ArtPreview` when done.** It's a Studio instance and isn't synced.

After each brainrot: `sh tools/typecheck.sh`, a preview screenshot, then commit and push. Tick it off in the task queue.

## Before going live
- Create the gamepasses and developer products on the Creator Dashboard, and paste their ids into `Config/Gamepasses` and `Config/Products`.
- Set the place's Max Players to 6 (one plot each).
- Test on a live server (DataStores, purchases).

## Known quirks
- Azul's sourcemap can miss new modules; `tools/typecheck.sh` works around it.
- Studio test data lives in the `PlayerData_Studio` DataStore. The user's profile has ~4.4K Coins and 2 lines; Snapshot/Restore around spending tests.
- `get_console_output` often comes back empty even when things run fine; probe state with `execute_luau` instead.
