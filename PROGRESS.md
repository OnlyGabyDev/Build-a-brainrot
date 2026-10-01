# Progress map

_Last updated: 2026-09-30. Keep this current: it's how a new chat picks up the work._

**New chat? Read [CLAUDE.md](CLAUDE.md) first, then take the first unchecked task in the [Task queue](#task-queue).** One task per chat: finish it (type-check, playtest, commit and push), tick it off here, add anything the next chat needs, and tell the user it's done.

## Where we are
The core game is **complete and playtested** (GDD §15, sprint steps 1–12). We're in **step 13: polish**. The core loop's juice pass (sounds, effects, lights) is done, and **all 15 brainrots have voxel art**. The plot-reset payout bug is fixed, **the map is done** (v2: a terrain valley with a plaza, river, bridges, hills, streams, a skybox and store textures; the user likes it), and **the factories are redesigned** (a 2-storey toy house per plot with crossed gabled roofs, a turret, outside stairs; the 2nd floor is locked). **Next: the ceiling chutes** (the Themed droppers task). Then the themed finishing stages, the Paint Booth options, the Sprint pass and the Photobooth; after those, gadgets and the like (the user's order).

### Built (all playtested in Studio)
| Area | What works | Where |
|---|---|---|
| Data | Session-locked saving, currencies, parts, completions, rebirth data, receipts, boosts, wheel spins | `Services/DataManager` |
| Tycoon | 6 plots, purchase buttons, Cash Pad, Zone 1 (Toy Workshop) + Zone 2 (Plushie Sewing Room, a back room) | `Services/TycoonManager` |
| World map | A terrain valley (cartoon-textured grass, lusher patches, hills, mountains) with the 6 factories around it. In the middle, a tiled stone plaza under a pink-and-white carousel tent (fountain + giant Tralalero, flagstone carpets in each factory's color, planters, benches, lamps hung with bunting, flowered hedges along the rim) ringed by a river with 6 arched bridges; winding flagstone paths in each factory's color, with white curbs, lead on to the entrances. Between the factories: hills, 2 winding streams ending in ponds (footbridges, lily pads, reeds, logs, rubber ducks), brainrot showcase statues, picnics, fenced gardens, toy blocks, giant lollipops, ~190 trees, bushes, flower beds, rocks, mushrooms, balloons. Cartoon water texture drifts on the river and streams | `Services/MapBuilder`; statue spin, balloon bob and water drift in `Atmosphere.client` |
| Factory buildings | A 2-storey toy house per plot, tinted by the plot's color: ground floor (Toy Workshop front, Plushie room back) in colored brick with chunky dark trims, flower boxes, round corner pillars and a stone plinth; 2nd floor (Clay Studio, Vinyl Collectibles: locked shells, 🔒 REBIRTH 4/6, or 🚧 COMING SOON past that) in wood siding of the opposite pastel hue with shutters; a front gable with a clock facing the hub and a crossed back roof (shingles), a crooked-roofed turret, a crooked smoking chimney, pipes, and outside stairs up to the 2nd floor's locked side door. Dollhouse cutaway: every floor above yours (and the roofs) fades while the camera is above your ceiling | `Services/FactoryBuilder`, cutaway in `TycoonFX.client` |
| Production | Server-timed lines, one-part-one-line rule, Equip Best, completions + edition jackpot, mixed-part sockets | `Services/ProductionManager`, `Shared/BrainrotModels` |
| Assembly animations | Part by part. Toy Workshop: claw + wooden pusher robots. Plushie room: sewing needle, thread spools, stuffing pump | `StarterPlayerScripts/ProductionVisuals` |
| Core-loop juice | Per-step sounds (plop, boing, servo, BONK, ratchet, sewing, squeak, pop), dropper squash, Assembler beacon, station paint/glitter with ×multiplier popups, coins hopping to the Cash Pad, PERFECT! confetti, rolling belts, build-in animation on purchase, Cash Pad coin pile + collect burst (coins fly to the HUD), arrows over affordable buttons | `ProductionVisuals`, `TycoonFX.client`, `Client/Effects` |
| Atmosphere | Dreamy anime skybox (Creator Store), warm saturated lighting, bloom (Neon parts glow), color grading, pastel haze, shuffled background music, mute button (top right) | `Atmosphere.client` |
| Loot | Rolls + shared map loot boxes (rarity gating, upgrade odds, Rare+ announcements), prize wheel + reveal. Boxes spawn anywhere dry and clear in the valley up to the entrances (hills too), via `MapBuilder.FindSpot` | `Services/LootManager`, `Client/UI/Loot`, `LootBoxes.client` |
| UI | HUD counters, Line menu, Index (catalog), completion banner, Rebirth menu, Shop, Daily Wheel | `Client/UI/*`, `UIController.client` |
| Gadgets | Morphs + Tralalero Sneakers, Sahur Baton (knockback, safe in plots), Ballerina Dance | `Services/GadgetManager`, `GadgetsClient.client` |
| Rebirths | 50K ×3 cost, +25% income each, Rebirth Shop (Income, Speed, Luck) | `Services/RebirthManager`, `Client/UI/RebirthMenu` |
| Monetization | 5 gamepasses (config-driven perks), Gem/Roll/Spin products with receipt de-dup, Daily Wheel | `Services/MonetizationManager`, `Services/DailyWheelManager` |
| Art | Voxel pipeline (`Shared/VoxelArt`) plus voxel Tralalero, Tung Tung Tung Sahur, Brr Brr Patapim, Lirilì Larilà, Trippi Troppi, Ballerina Cappuccina, Chimpanzini Bananini, Boneca Ambalabu, Cappuccino Assassino, Bombombini Gusini, Frigo Camelo, Glorbo Fruttodrillo, Bombardiro Crocodilo and La Vaca Saturno Saturnita, all checked against *Steal a Brainrot*, plus our own Godly, Supremo Brainrotto (the Risotto King, with glowing Neon gems and steam) | `Shared/Art/*` |

## Task queue
Roughly in priority order (the user: polish first, and the core loop matters most). Each task is sized for one chat.

- [x] **Core-loop juice pass** (2026-09-30): sounds, particles, lights, bloom, music. See the table above.
- [x] **Brainrots A: Commons** (2026-09-30): Patapim (mossy hood, droopy nose), Lirilì (elephant head on a cactus, sandals), Trippi (cat face on a shrimp). SaB check: Tralalero got longer legs, gills, a pink mouth and dark swooshes; Tung got more orange with longer legs. (Tralalero's legs "not showing" was a preview bug: the model sank into the ground.)
- [x] **Brainrots B: Uncommons** (2026-09-30): Ballerina (cappuccino-cup head, tutu, one leg lifted), Chimpanzini (grumpy chimp in a banana; the arms are peel flaps, and it stands on the banana's curled bottom), Boneca (frog head, see-through tire body, skinny legs).
- [x] **Brainrots C: Rares** (2026-09-30): Cappuccino Assassino (ninja cup, headband, two katanas), Bombombini Gusini (goose bomber: wings with propellers as arms, goose feet), Frigo Camelo (fridge body, camel neck and head, laced boots).
- [x] **Brainrots D: Legendary, Mythic** (2026-09-30): Glorbo (croc in a striped watermelon), Bombardiro (croc-nosed bomber: wings with propellers and bombs as arms, landing gear as legs), La Vaca (cow in sunglasses on a striped Saturn; the ring is its arms, big bare feet).
- [x] **Brainrots E: the Godly** (2026-09-30): Supremo Brainrotto, the Risotto King (the user picked it from 3 concepts): a crowned pink brain with googly eyes and a mustache in a golden risotto pot with rainbow steam, a giant spoon and fork, chef boots. `VoxelArt` got per-color `Materials` for the Neon glow.
- [x] **Bug: payouts in flight survive a plot reset** (2026-09-30). The plot has a `Generation` number, bumped by `ResetPlot` and `releasePlot`; the delayed payout in `ProductionManager.ship` checks it. On the client, `ProductionVisuals` drops a brainrot whose line vanished (no "+💰" popup), and the Cash Pad's `Generation` attribute stops `TycoonFX` from playing a fake collect burst when a reset wipes the pad. Playtested with two `Restore`s mid-cycle: no leaks, and Coins came back exactly.
- [x] **Facility A: factory buildings** (2026-09-30; the user moved the facility ahead of the chutes, so the chutes have a ceiling to hang from). `FactoryBuilder` builds each plot's rooms (see the table above). Rooms are 140×120 with 28-stud walls; the ceiling is at Y = 29 in plot space (floor top 1 + 28), so ceiling chutes hang from there.
- [x] **Facility B: the world map** (2026-09-30, many rounds with the user; they like the result). `MapBuilder` (runs after TycoonManager) builds the whole world, see the table above and the **World notes** below. The factories moved out to radius 300 (entrances at 240). References the user picked: *Pet Simulator 99* and *Adopt Me!* (the carousel tent echoes Adopt Me's central tent). Store assets now OK for polish (the user said so): skybox, grass, water and paving textures.
- [x] **Factory redesign** (2026-09-30; the user found the old buildings "super feias"; references *Pet Simulator 99*, *Adopt Me!*, *Hello Neighbor*). See the table above. The user hasn't seen it yet: **ask them what to change**. Notes for later chats:
  - **Layout:** `FactoryBuilder.Layout` places each zone's room by zone index (storey + Z); `FactoryBuilder.RoomCFrame(zoneIndex)` gives its floor center in plot space (TycoonManager's line origins use it). Storeys are 30 studs floor to floor (`StoreyHeight`: 28 of room, `CeilingHeight`, then the slab), so the 2nd floor's floor top is Y = 31 in plot space and its ceiling 59. A 3rd storey means: `STOREYS` and `FACADES` in FactoryBuilder (`ROOF_BASE` follows).
  - **Textures** (Creator Store, white, tinted per plot): brick decal 92246549548513, siding 2448219602, shingles 9583141664 (image ids in FactoryBuilder's constants). A wall's texture sits on its outer face only, so the same part shows the room's color inside.
  - **Cutaway:** everything above the ground floor's ceiling lives in two Models per plot tagged `Cutaway` (`UpperFloor` Level 2, `Roof` Level 3; Atomic streaming). `TycoonFX` fades the ones above your storey while you're inside the building and the camera is above your ceiling, fading Textures too (they don't follow their part's LocalTransparencyModifier) and switching off their SurfaceGuis and smoke. It also turns those upper parts' collisions off locally while you're below them: otherwise the 2nd floor's (solid) floor would pop the camera down under the ceiling and the fade would never start. Upstairs parts cast no shadows, so the rooms stay sunny.
  - **Making the 2nd floor playable later:** its rooms already have floors, walls, windows, ceilings, a doorway between them (shuttered) and the side door off the outside stairs (shuttered, sign outside). Set the zones `Available`, give them items in `Config/TycoonItems`, and their machines go in at `RoomCFrame`.
  - `FactoryBuilder.Lot` (the building plus stairs and overhangs) sizes MapBuilder's lawn and `TycoonManager.IsInPlot` (the safe zone).
  - Proposed (ask the user): the next locked floor (3rd: Candy Factory) shows on the roof as scaffolding with a 🔒 sign.
- [ ] **Ceiling chutes** = the **Themed droppers** task below (the Toy Workshop's droppers become chutes from the ceiling; `FactoryBuilder.CeilingHeight` is exported for it).
- [ ] **Finishing stage + finishing upgrader** (GDD §6, the user's request; assembly animations are HIGH priority): every zone gets a themed last step after the stations, then one more themed upgrade station. Toy Workshop: the brainrot hops to the floor, a toy box pops up and opens, the toy jumps in, and the box closes. Plushie room: filled with foam. Robot Plant (later): a wind-up key turns and it moves. Start with the Toy Workshop and the Plushie room.
- [ ] **Themed droppers** (GDD §6, the user's request): every zone's droppers match its theme, like the rest of its machines. Toy Workshop: **chutes** that drop the parts onto the belt, coming out of the **ceiling** (the user picked it). Other zones: not decided yet, so propose ideas to the user before building. The drop animation is part of the show (HIGH priority), so keep the squash, sounds and timing of the current droppers (`ProductionVisuals`).
- [ ] **Paint Booth options** (GDD §6, §12): pick the paint color or turn the booth off, plus a **Custom Paint** gamepass to paint each limb differently.
- [ ] **Sprint gamepass** (GDD §12): hold Shift to run. Small.
- [ ] **UI: the sticker-book Index** (GDD §8 polish target): big popped-out brainrots on rarity backgrounds, round edition buttons (gray/blue/green), more color everywhere. Needs the brainrot art first.
- [ ] **UI: the loot wheel** (the user finds it ugly) plus UI juice: sounds on opens/reveals, bouncier panels, the whole HUD more Pet Simulator–style (GDD §13, §15).
- [ ] **Room interiors:** themed props inside each room (toy shelves, giant blocks, posters; sewing baskets, yarn), hanging lamps. Could fold into the factory redesign.
- [ ] **Gadgets and the like** (the user: after the tasks above).
- [ ] **Per-rarity loot box looks and effects** (GDD §5, §16.16): a Godly box arrives through a black hole.
- [ ] **Photobooth on every floor** (GDD §6): save a brainrot as the player painted it, for a colorful statue, a factory photo and/or an in-game icon, on a background themed to the floor. Best after the Paint Booth options and the facility.

**Needs the user:** Claude can't hear audio, so every sound was picked by its library description. Ask the user to listen in a playtest and name any sound to swap; the ids are all in `Config/Sounds`.

## Voxel brainrots how-to
The pipeline works: the voxel Tralalero already runs on the lines in game (60 fps, no errors).
- Each brainrot gets `sync/ReplicatedStorage/Shared/Art/<BrainrotId>.luau`, which returns `{ VoxelSize, Palette, Parts = { Legs, Body, Arms, Head }, Joints? }`. Each part is a list of shapes from `Shared/VoxelArt.luau`: `box`, `ball`, `cylinder` (upright), `carve`, `paint`, `mirror`.
- `Materials = { [paletteKey] = Enum.Material.Neon }` makes those colors glow (Supremo's gems and steam). Zone editions with their own material override it.
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

**On a line (playtest):** `Snapshot`, then `DevCommand:Invoke("ShowOnLine", player, id, "ToyWorkshop_1")` (the user's lines are `ToyWorkshop_1` and `ToyWorkshop_2`), probe the Client for the part models, and `Restore` at the end (it drops the builds still in flight, so nothing leaks past it).

**In-game screenshot** (with bloom): the camera script resets the camera every frame, so pin it on the Client with `RunService:BindToRenderStep("ShotCam", Enum.RenderPriority.Last.Value, fn)` (set `Scriptable` and the CFrame inside), `screen_capture` with no camera arguments, then unbind and set the camera back to `Custom`.

After each brainrot: `sh tools/typecheck.sh`, a preview screenshot, then commit and push. Tick it off in the task queue.

## World notes
How `MapBuilder` builds the world (read this before touching the map or anything that sits on it):
- **Layout** (studs from the hub, the world's origin): plaza to 116 (a 3-stud-thick tiled platform, top Y = 0.4), river 125–147, bridges 112–160, factories at radius 300 (entrances at 240), streams in the 2nd and 5th gaps out to ponds at ~640, mountains at ~900, terrain 2200 wide. Loot boxes: radius 30–225 (`Config/Loot`), placed by `MapBuilder.FindSpot` (raycast to dry ground, clear of decor).
- **Terrain levels** (Terrain snaps flat tops to its 4-stud grid; measured): a block filled up to Y = t has its surface at t + 2, so the valley's grass (filled to -2) is at **Y = 0**; a cylinder filled to -4 has its surface at -2 (sand banks, beaches); water filled to -4 stands at **-4**. Use `FillBlock` for exact heights. Fresh terrain only answers raycasts from the **next frame** (`task.wait()` after filling).
- **Tall animated grass** grows only on the Grass material. `paint(...)` repaints the ground with LeafyGrass (a trimmed lawn) under paths, factories, bridge landings and props, and with Ground (soil) under flower beds. Painting fills the volume, so never paint over water.
- **Cartoon grass** is a MaterialVariant (`MaterialService.CartoonGrass`, overriding Grass) that **lives in the place file**: scripts can't create MaterialVariants (Plugin security). Recreate it with [tools/SetupMaterials.luau](tools/SetupMaterials.luau). **The user must save the place** to keep it.
- **Textures from the Creator Store:** a decal's image id comes from `InsertService:LoadAsset(decalId)` in Edit (read the Decal's `Texture`); other people's **models** (like the skybox) only insert with the MCP's `insert_asset`. Preview thumbnails side by side with `thumbnails.roblox.com` + PIL. Ids in use: skybox (`Atmosphere.client`), water, flagstones, tiles (`MapBuilder` constants), grass (`tools/SetupMaterials.luau`).
- **Seamless textures on stretches:** `tile(...)` / `waterSkin(...)` offset each stretch's texture by its distance along the path or flow, so the pattern runs on; stretches overlap a little, every other one a hair higher (no flicker).
- **Client side** (`Atmosphere.client`): the skybox and lighting, the statues' spin (tag `SpinningStatue`, only near the camera), the balloons' bob, the water texture's drift (tag `FlowingWater`).

## Before going live
- Create the gamepasses and developer products on the Creator Dashboard, and paste their ids into `Config/Gamepasses` and `Config/Products`.
- Set the place's Max Players to 6 (one plot each).
- Test on a live server (DataStores, purchases).

## Known quirks
- Azul's sourcemap can miss new modules; `tools/typecheck.sh` works around it.
- Studio test data lives in the `PlayerData_Studio` DataStore. The user's profile has 2 Toy Workshop lines and ~41.7K Coins (2026-09-30; +1.7K came from a loot box the test character walked into while being teleported: for screenshots, park the character inside an empty plot, out of the loot ring). Snapshot/Restore around spending tests. `ListVersionsAsync` on key `Player_<UserId>` shows the save history.
- `get_console_output` often comes back empty even when things run fine; probe state with `execute_luau` instead.
- Playtest FPS reads ~15 while Studio isn't the focused window, even on the old lines. Compare against a baseline before blaming new content.
- The user often plays in Studio while Claude works: a playtest may already be running. Check `get_studio_state` and **stop it before editing code**. Release a pinned screenshot camera right after the capture.
- The world (Hub folder + terrain) is built at server start in ~0.75 s and has ~7.4K parts; the factories add ~5.4K (~900 per plot). FPS showed no drop in the playtest (~20 with Studio unfocused).
