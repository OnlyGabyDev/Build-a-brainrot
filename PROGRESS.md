# Progress map

_Last updated: 2026-09-30. Keep this current: it's how a new chat picks up the work._

**New chat? Read [CLAUDE.md](CLAUDE.md) first, then take the first unchecked task in the [Task queue](#task-queue).** One task per chat: finish it (type-check, playtest, commit and push), tick it off here, add anything the next chat needs, and tell the user it's done.

## Where we are
The core game is **complete and playtested** (GDD §15, sprint steps 1–12). We're in **step 13: polish**. The core loop's juice pass (sounds, effects, lights) is done, and the brainrot art is underway (all 14 *Steal a Brainrot* ones are done; only the Godly, our own design, is left).

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
| Art | Voxel pipeline (`Shared/VoxelArt`) plus voxel Tralalero, Tung Tung Tung Sahur, Brr Brr Patapim, Lirilì Larilà, Trippi Troppi, Ballerina Cappuccina, Chimpanzini Bananini, Boneca Ambalabu, Cappuccino Assassino, Bombombini Gusini, Frigo Camelo, Glorbo Fruttodrillo, Bombardiro Crocodilo and La Vaca Saturno Saturnita, all checked against *Steal a Brainrot* (only Supremo Brainrotto is still a placeholder) | `Shared/Art/*` |

## Task queue
Roughly in priority order (the user: polish first, and the core loop matters most). Each task is sized for one chat.

- [x] **Core-loop juice pass** (2026-09-30): sounds, particles, lights, bloom, music. See the table above.
- [x] **Brainrots A: Commons** (2026-09-30): Patapim (mossy hood, droopy nose), Lirilì (elephant head on a cactus, sandals), Trippi (cat face on a shrimp). SaB check: Tralalero got longer legs, gills, a pink mouth and dark swooshes; Tung got more orange with longer legs. (Tralalero's legs "not showing" was a preview bug: the model sank into the ground.)
- [x] **Brainrots B: Uncommons** (2026-09-30): Ballerina (cappuccino-cup head, tutu, one leg lifted), Chimpanzini (grumpy chimp in a banana; the arms are peel flaps, and it stands on the banana's curled bottom), Boneca (frog head, see-through tire body, skinny legs).
- [x] **Brainrots C: Rares** (2026-09-30): Cappuccino Assassino (ninja cup, headband, two katanas), Bombombini Gusini (goose bomber: wings with propellers as arms, goose feet), Frigo Camelo (fridge body, camel neck and head, laced boots).
- [x] **Brainrots D: Legendary, Mythic** (2026-09-30): Glorbo (croc in a striped watermelon), Bombardiro (croc-nosed bomber: wings with propellers and bombs as arms, landing gear as legs), La Vaca (cow in sunglasses on a striped Saturn; the ring is its arms, big bare feet).
- [ ] **Brainrots E: the Godly, SupremoBrainrotto.** Our own original design (GDD §3, §16.11). Propose the design in the chat before building it.
- [ ] **UI: the sticker-book Index** (GDD §8 polish target): big popped-out brainrots on rarity backgrounds, round edition buttons (gray/blue/green), more color everywhere. Needs the brainrot art first.
- [ ] **UI: the loot wheel** (the user finds it ugly) plus UI juice: sounds on opens/reveals, bouncier panels, the whole HUD more Pet Simulator–style (GDD §13, §15).
- [ ] **Facility and map:** real factory rooms instead of flat plots, and a hub map instead of the baseplate (GDD §15). Build it ourselves in code first (see CLAUDE.md, art preferences).
- [ ] **Per-rarity loot box looks and effects** (GDD §5, §16.16): a Godly box arrives through a black hole.

**Needs the user:** Claude can't hear audio, so every sound was picked by its library description. Ask the user to listen in a playtest and name any sound to swap; the ids are all in `Config/Sounds`.

## Voxel brainrots how-to
The pipeline works: the voxel Tralalero already runs on the lines in game (60 fps, no errors).
- Each brainrot gets `sync/ReplicatedStorage/Shared/Art/<BrainrotId>.luau`, which returns `{ VoxelSize, Palette, Parts = { Legs, Body, Arms, Head }, Joints? }`. Each part is a list of shapes from `Shared/VoxelArt.luau`: `box`, `ball`, `cylinder` (upright), `carve`, `paint`, `mirror`.
- `paint(shape)` only recolors voxels that are already filled: use it for stripes and spots on curved surfaces (cactus ribs, gills, bark), because a plain box there adds stray voxels.
- `Joints = { Head = Vector3 }` (voxels) overrides a part's socket when its bounding box misleads: a hanging nose or trunk, antennae (Patapim, Lirilì, Trippi). `Legs` is the hip, where the body's bottom sits (Tralalero). Mixed builds use these, so check one in the preview.
- To end a leg exactly on a curved belly, reach up into the torso and `carve` the torso shapes from the legs (see Tralalero).
- Voxel units: X is left/right (0 = the center line), Y is up (0 = the ground), **-Z is the front** (the face). Voxel size is 0.25 studs, and brainrots are ~22–28 voxels tall (~6–7 studs, like the placeholders).
- Later shapes paint over earlier ones. Keep **different parts from overlapping** (overlapping cells of different colors flicker).
- `BrainrotModels` uses the art automatically (template cached per part, then cloned). No art means colored placeholder blocks. Mixed-part builds attach at the body's sockets (bounding-box centers), so a head from one brainrot lands where the body's own head would be.
- Copy the style of the done ones: a `both(shapes, { ... })` helper adds shapes with their mirrors (`BrrBrrPatapim`, `LiriliLarila`, `TrippiTroppi`); `TralaleroTralala` has a head in front of the body, and `TungTungTungSahur` paints face features onto a cylinder's front.
- Use whole-number box corners: a voxel is filled when its center (x.5) is inside, so integer bounds fill exactly the cells you expect.

**Reference: *Steal a Brainrot*** (the user asked for this):
1. Get the render from the fandom wiki's API: `curl -s "https://stealabrainrot.fandom.com/api.php?action=query&titles=<Page_Title>&prop=pageimages&pithumbsize=600&format=json"` gives the image URL.
2. Download it into the scratchpad with curl **plus browser headers** (`-A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36" -H "Referer: https://stealabrainrot.fandom.com/"`; without them Cloudflare returns an HTML page). It comes as WebP: convert it to PNG with Python's PIL (installed), ideally several side by side on a gray background, and look with the Read tool.
3. Keep the silhouette and signature colors. Split into Head/Body/Arms/Legs in a way that makes sense for the character (e.g. Tralalero's "arms" are fins, and a bomber's could be its wings).

**Previewing in Studio** (edit mode, no playtest needed):
1. Paste [tools/ArtPreview.luau](tools/ArtPreview.luau) into `execute_luau` (Edit), after setting its `IDS` (and `MIXES` for a mixed build). It builds them side by side from x = 300, and reports part counts and **overlaps between parts** (they must be "none").
2. `screen_capture` from `(x + 3, 4.5, -7.5)` looking at `(x, 3.2, 0)`. Edit mode is flatly lit, so colors look paler than in game.
3. **Delete `Workspace.ArtPreview` when done.** It's a Studio instance and isn't synced.

**On a line (playtest):** `Snapshot`, then `DevCommand:Invoke("ShowOnLine", player, id, "ToyWorkshop_1")` (the user's lines are `ToyWorkshop_1` and `ToyWorkshop_2`), probe the Client for the part models, and `Restore` at the end. The Restore warns "can't complete …: missing …" for builds already in flight; that's expected.

After each brainrot: `sh tools/typecheck.sh`, a preview screenshot, then commit and push. Tick it off in the task queue.

## Before going live
- Create the gamepasses and developer products on the Creator Dashboard, and paste their ids into `Config/Gamepasses` and `Config/Products`.
- Set the place's Max Players to 6 (one plot each).
- Test on a live server (DataStores, purchases).

## Known quirks
- Azul's sourcemap can miss new modules; `tools/typecheck.sh` works around it.
- Studio test data lives in the `PlayerData_Studio` DataStore. The user's profile has ~4.4K Coins and 2 lines; Snapshot/Restore around spending tests.
- `get_console_output` often comes back empty even when things run fine; probe state with `execute_luau` instead.
- Playtest FPS reads ~15 while Studio isn't the focused window, even on the old lines. Compare against a baseline before blaming new content.
