# Reference: art, the lab, the world

How-tos for specific kinds of work. Read only the section your task needs.

## Voxel brainrots how-to
The pipeline works: the voxel Tralalero already runs on the lines in game (60 fps, no errors).
- Each brainrot gets `sync/ReplicatedStorage/Shared/Art/<BrainrotId>.luau`, which returns `{ VoxelSize, Palette, Parts = { Legs, Body, Arms, Head }, Joints? }`. Each part is a list of shapes from `Shared/VoxelArt.luau`: `box`, `ball`, `cylinder` (upright), `carve`, `paint`, `mirror`.
- `Materials = { [paletteKey] = Enum.Material.Neon }` makes those colors glow (Dragon Cannelloni's fire, Girafa Celestre's star; in a spec, `"Materials": {"Fire": "Neon"}`). There's no transparency (a space helmet is an open rim). Zone editions with their own material override it.
- `paint(shape)` only recolors voxels that are already filled: use it for stripes and spots on curved surfaces (cactus ribs, gills, bark), because a plain box there adds stray voxels.
- `Joints = { Head = Vector3 }` (voxels) overrides a part's socket when its bounding box misleads: a hanging nose or trunk, antennae (Patapim, Lirilì, Trippi). `Legs` is the hip, where the body's bottom sits (Tralalero). Mixed builds use these, so check one in the preview.
- To end a leg exactly on a curved belly, reach up into the torso and `carve` the torso shapes from the legs (see Tralalero).
- Voxel units: X is left/right (0 = the center line), Y is up (0 = the ground), **-Z is the front** (the face). Voxel size is 0.25 studs, and brainrots are ~22–28 voxels tall (~6–7 studs, like the placeholders).
- Later shapes paint over earlier ones. Keep **different parts from overlapping** (overlapping cells of different colors flicker).
- `BrainrotModels` uses the art automatically (template cached per part, then cloned). No art means colored placeholder blocks. Mixed-part builds attach at the body's sockets (bounding-box centers), so a head from one brainrot lands where the body's own head would be.
- Copy the style of the done ones: a `both(shapes, { ... })` helper adds shapes with their mirrors (`BrrBrrPatapim`, `LiriliLarila`, `TrippiTroppi`); `TralaleroTralala` has a head in front of the body, and `TungTungTungSahur` paints face features onto a cylinder's front.
- Use whole-number box corners: a voxel is filled when its center (x.5) is inside, so integer bounds fill exactly the cells you expect.

**Reference: the original meme image** (the user, 2026-10-07: real memes only, and no copying *Steal a Brainrot*):
1. `python tools/brainrot_refs.py <scratchpad>/refs.png "<Wiki Page Title>" ...` prints each name's `creator` and `rarity` from the *Steal a Brainrot* fandom wiki and saves the **original meme image** its page or /Gallery keeps ("Origin Images", "the image it is based on") side by side in refs.png. Look with the Read tool.
2. **Is it a real meme?** A TikTok handle as creator (@alexey_pigeon, @ofuscabreno, @__chenesacc__...) means yes. "BRAZILIAN SPYDER" or "SpyderSammy" (the game's developers) means the game made it up: don't use it. No original image or no creator: find it elsewhere first (a web search), or pick another. The wiki is fan-made, so check a surprising one elsewhere too.
3. **Draw from the original image**, never from the game's 3D figure (their figures are their work; their outfits and colors that aren't in the meme stay theirs). Keep the original's silhouette and signature colors in our blocks; leave out guns, cigars and the like. Split into Head/Body/Arms/Legs in a way that makes sense for the character (Tralalero's "arms" are fins, a bomber's its wings, a quadruped's front legs or side fins, a teapot's spout and handle).
4. The renders of the game's own figures still load with `action=query&titles=<Page_Title>&prop=pageimages&pithumbsize=600` (curl with the browser headers in the script; WebP, convert with PIL), only to understand a shape the original hides.

**Previewing in Studio** (edit mode, no playtest needed):
1. Paste [tools/ArtPreview.luau](tools/ArtPreview.luau) into `execute_luau` (Edit), after setting its `IDS` (and `MIXES` for a mixed build). It builds them side by side from x = 300, and reports part counts and **flicker between parts**: faces of two parts in one plane, facing the same way, in different colors (it must be "none"). A block of one part reaching into another is fine. `voxel_art.py`'s "cells shared between parts" skips `block`/`wedge`/`rod` solids, so for block art it's always 0: trust the Studio check.
2. `screen_capture` from `(x + 3, 4.5, -7.5)` looking at `(x, 3.2, 0)`. Edit mode is flatly lit, so colors look paler than in game.
3. **Delete `Workspace.ArtPreview` when done.** It's a Studio instance and isn't synced.

**On a line (playtest):** `Snapshot`, then `ShowOnLine` with `id` and `"ToyWorkshop_1"` (through `DevRequest`, see Known quirks) (the user's lines are `ToyWorkshop_1` and `ToyWorkshop_2`), probe the Client for the part models, and `Restore` at the end (it drops the builds still in flight, so nothing leaks past it).

**In-game screenshot** (with bloom): the camera script resets the camera every frame, so pin it on the Client with `RunService:BindToRenderStep("ShotCam", Enum.RenderPriority.Last.Value, fn)` (set `Scriptable` and the CFrame inside), `screen_capture` with no camera arguments, then unbind and set the camera back to `Custom`.

**Details must stand off their face:** `tools/voxel_art.py` runs `standoff()` on every spec (a thin solid within 0.35 voxel of a parallel face under it grows outward to 0.35), because details a hair off a face vanished from a few studs away (Tung's face, Tralalero's eyes, 2026-10-03). Regenerate a spec after editing it; never hand-place a plate flush.

After each brainrot: `sh tools/typecheck.sh`, a preview screenshot, then commit and push. Tick it off in the task queue.

## The lab (tools/lab)
Runs the server's builders without Studio and writes every part down, for geometry checks from a terminal (made in a cloud session with no MCP; useful anywhere):
- `lune run tools/lab/lab.luau [plots|world] out.json [sync folder]`: `plots` builds the 6 factories and furnishes the first for a lab player who owns everything (Rebirth 99); `world` adds the hub. Needs [Lune](https://lune-org.github.io) (0.10.4 used; on Windows, the release's `lune.exe`).
- `lune run tools/lab/lab.luau mixes out.json` (every mixed brainrot build) with `analyze.py gaps out.json` (floating parts); `python3 tools/lab/render.py out.json out.png "<path filter>"...` renders parts to a PNG (four views; needs PIL).
- `python3 tools/lab/analyze.py counts out.json [depth]` (parts per branch, other instances, tags), `zfight out.json [path filter] [x1,y1,z1,x2,y2,z2]` (coplanar overlapping faces facing the same way, minus faces pressed against another part and same-color pairs; faces facing down at the ground are usually hidden by terrain the lab doesn't have).
- How: `tools/lab/dom.luau` is a small Instance tree (pivots, ScaleTo, GetBoundingBox, tags, attributes, fake events); services the builders only talk to (DataManager, MonetizationManager, Remotes) are stubs in lab.luau; the ground is flat at Y = 0 (no terrain), raycasts hit only it, and Random is another generator (jittered decor lands differently). `tools/lab/types.luau` wraps Lune's Vector3/CFrame because **Lune 0.10's `CFrame.lookAt` is wrong** (the look direction's Y and Z come out backwards) and its types can't be multiplied number-first (`2 * v`); everything else matched Roblox in tests.
- To check work in progress against a broken config (e.g. a room upgrade without a builder), copy `sync/` and point the third argument at the copy.

## World notes
How `MapBuilder` builds the world (read this before touching the map or anything that sits on it):
- **Layout** (studs from the hub, the world's origin): plaza to 116 (a 3-stud-thick tiled platform, top Y = 0.4), river 125–147, bridges 112–160, factories at radius 300 (entrances at 240), streams in the 2nd and 5th gaps out to ponds at ~640, mountains at ~900, terrain 2200 wide. Loot boxes: radius 30–225 (`Config/Loot`), placed by `MapBuilder.FindSpot` (raycast to dry ground, clear of decor).
- **Paths to the factories** are laid in each plot's space with the same sway, so the front yard's walks (stepping stones: from the outside stairs' path at `FactoryBuilder.GardenPath.End`, and to the mascot) meet them at the same curb openings (`GARDEN_GAP`, `MASCOT_GAP` in `MapBuilder`). `FactoryBuilder.SteppingStones` lays stones along any curve in plot space.
- **Terrain levels** (Terrain snaps flat tops to its 4-stud grid; measured): a block filled up to Y = t has its surface at t + 2, so the valley's grass (filled to -2) is at **Y = 0**; a cylinder filled to -4 has its surface at -2 (sand banks, beaches); water filled to -4 stands at **-4**. Use `FillBlock` for exact heights. Fresh terrain only answers raycasts from the **next frame** (`task.wait()` after filling).
- **Tall animated grass** grows only on the Grass material. `paint(...)` repaints the ground with LeafyGrass (a trimmed lawn) under paths, factories, bridge landings and props, and with Ground (soil) under flower beds. Painting fills the volume, so never paint over water.
- **Cartoon grass** is a MaterialVariant (`MaterialService.CartoonGrass`, overriding Grass) that **lives in the place file**: scripts can't create MaterialVariants (Plugin security). Recreate it with [tools/SetupMaterials.luau](tools/SetupMaterials.luau). **The user must save the place** to keep it.
- **Textures from the Creator Store:** a decal's image id comes from `InsertService:LoadAsset(decalId)` in Edit (read the Decal's `Texture`); other people's **models** (like the skybox) only insert with the MCP's `insert_asset`. Preview thumbnails side by side with `thumbnails.roblox.com` + PIL. Ids in use: skybox (`Atmosphere.client`), water, flagstones, tiles (`MapBuilder` constants), grass (`tools/SetupMaterials.luau`).
- **Seamless textures on stretches:** `tile(...)` / `waterSkin(...)` offset each stretch's texture by its distance along the path or flow, so the pattern runs on; stretches overlap a little, every other one a hair higher (no flicker).
- **Client side** (`Atmosphere.client`): the skybox and lighting, the statues' spin (tag `SpinningStatue`, only near the camera), the balloons' bob, the water texture's drift (tag `FlowingWater`).
