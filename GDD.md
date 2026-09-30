# Build a Brainrot — Game Design Document

> Living document. Update it whenever a mechanic changes, is cut, or is promoted from "Later" to "MVP".
> **Status legend:** 🟢 MVP (build in the 2-day sprint) · 🟡 Later (planned, not now) · 💡 Proposed (idea, needs approval) · ⏸️ On hold

---

## 1. Vision

A joyful, colorful **brainrot factory tycoon**. The factory *is* the brainrot builder. **Assembly lines** of part droppers (Head, Body, Arms, Legs) feed an **Assembler** that builds brainrots and ships them for Coins. Players hunt **loot boxes** to unlock new parts for their droppers. The factory then grows into ever-crazier **zones**: a toy workshop, a sewing room, a candy factory, a mad-science lab, a secret bunker… Each zone builds brainrots in its own **edition** (size and style) with its own over-the-top assembly animation.

**Pillars**
1. **Number goes up.** Constant income, big popups, and satisfying upgrades (money-farming loop).
2. **Gotta collect 'em all.** The silhouette catalog makes missing parts and editions itch.
3. **Visual candy.** Every zone has its own assembly show, and the rarer the zone, the crazier the animation.
4. **Hype moments.** Wheel spins, rare pulls, the first full ship, edition jackpots, and rebirths all get loud, flashy feedback.
5. **Simple first.** Ship a tight core loop, then expand zone by zone.

**Aesthetic:** Pet Simulator X–style UI. Bright saturated colors, thick outlines, rounded bouncy buttons, chunky fonts (FredokaOne / LuckiestGuy), rarity-colored glows, confetti, and sound on every click.

---

## 2. Core Loop 🟢

```
   Open loot boxes / Rolls (wheel) ──► Unlock parts ──► Configure assembly lines (menu)
              ▲                                                   │
              │                                                   ▼
   Rebirth: new zones,             Coins ◄── Ship brainrots ◄── Droppers → Assembler
   rarer loot, multipliers                  (full match = COMPLETION → Gems, gadget, morph)
```

1. On join, the player gets a **tycoon plot** automatically. New players start with:
   - the **starter brainrot** (all 4 Tralalero Tralala parts), so the first line can run a full match right away;
   - **3 free Rolls**, so they get new parts in their first minute.
2. They build **assembly lines** in the **Toy Workshop** with Coins. Each line has 4 part droppers, an Assembler, upgrade stations and a shipping chute.
3. The Assembler combines the parts into a brainrot and ships it. Coins go into the **collector**. The player steps on the **Cash Pad** to bank them (the Auto-Collect gamepass skips this).
4. **Loot boxes** spawn around the map. Opening one (or using a Roll) spins a **wheel** that unlocks a new part.
5. Shipping a brainrot whose **4 parts all match** **completes** it in that zone's **edition**: Gems, plus a gadget and morph the first time.
6. **Rebirth** resets the tycoon but slowly unlocks new **zones**, rarer loot, and permanent multipliers.

---

## 3. Brainrots & Parts 🟢

- Every brainrot has exactly **4 parts: Head, Body, Arms, Legs**.
- A part belongs to one specific brainrot, e.g. *Tung Tung Tung Sahur — Head*.
- A brainrot's rarity is the rarity of all 4 of its parts.
- Parts are **unlocked or locked**. There are no stacks, because duplicates convert to currency (see §5).

### Draft roster (placeholder, tune freely)

| Rarity | Brainrots | Gadget (first completion) |
|---|---|---|
| Common | **Tralalero Tralala** (shark with shoes, *starter*), Brr Brr Patapim, Lirilì Larilà, Trippi Troppi | Tralalero: speed-boost sneakers · others: archetype defaults |
| Uncommon | Ballerina Cappuccina, Chimpanzini Bananini, Boneca Ambalabu | Ballerina: **dance emote** |
| Rare | Cappuccino Assassino, Bombombini Gusini, Frigo Camelo | archetype defaults |
| Legendary | **Tung Tung Tung Sahur**, Glorbo Fruttodrillo | Sahur: **high-knockback baton** |
| Mythic | **Bombardiro Crocodilo**, La Vaca Saturno Saturnita | Bombardiro: **rideable bomber** 🟡 |
| Godly | **Supremo Brainrotto**, the Risotto King (our own signature brainrot): a crowned pink brain with googly eyes and a mustache, popping out of a golden pot of risotto that steams in rainbow colors, holding a giant spoon and fork, on chef boots | TBD |

**Gadget archetypes.** Every brainrot's gadget is one of a few reusable templates plus config:
- **Emote** (dance, pose) 🟢
- **Melee** (knockback baton, slap) 🟢
- **Movement** (speed, jump, glide) 🟢
- **Mount / Vehicle** (rideable bomber) 🟡
- **Toy / Projectile** (throwables, confetti cannon) 🟡

**Safe zones:** knockback gadgets have no effect inside tycoon plots, so nobody can grief a factory.

### Models: split into 4 parts ✅ decided

Each brainrot is a 3D model split into its 4 parts. The assembly animation moves the real parts, for maximum visual candy.

```
ReplicatedStorage/Assets/Brainrots/<BrainrotId>   (Model, e.g. "TungTungTungSahur")
  Head    (Model or MeshPart)
  Body
  Arms
  Legs
  -- Model pivot: on the ground between the feet, facing -Z (the model's front)
```

- The parts sit in their assembled pose inside the model. The game reads each part's position relative to the model's pivot, so the Assembler knows where every piece snaps.
- **Mixed parts use the body's sockets** ✅: the body anchors the build. The legs stand on the ground, the body sits on the legs' hip, and a head or arms from another brainrot go **where that body's own head or arms would be**. A head on a Tralalero body lands where the shark's head is, in front of the body, and on top for Sahur. This gives each brainrot its own silhouette.
  - Optional: a part can mark its exact connection point with an Attachment named `Joint` (Legs: the hip; Head and Arms: the point that meets the body). Without one, the game uses the part's bounding box.
- Until a brainrot has a model, the game uses **colored placeholder blocks** in the brainrot's color. Everything stays playable while art is added one brainrot at a time.
- **Art sourcing:** toolbox models first. Roblox AI generation only as a last resort. The AI mesh splitter only works on meshes we own, so prefer toolbox models that are already built from separate parts (rigs, multi-mesh models). Art polish is deferred until the loop is complete; most toolbox brainrots tried so far looked too rough.

---

## 4. Rarities 🟢

All numbers are **placeholders**. Tune them in playtests.

| Rarity | Color | Base loot weight | Duplicate reward | Part value (Coins) | Completion Gems (Zone 1) | Unlocked at |
|---|---|---|---|---|---|---|
| Common | Light grey `#C8CDD2` | 60% | Coins | 5 | 10 | Start |
| Uncommon | Green `#5BE35B` | 25% | Coins | 12 | 25 | Start |
| Rare | Blue `#3DA5FF` | 10% | Coins | 30 | 60 | Rebirth 1 |
| Legendary | Gold `#FFC53D` | 4% | **Gems** | 100 | 150 | Rebirth 4 |
| Mythic | Pink `#FF4FD8` | 0.9% | **Gems** | 350 | 400 | Rebirth 10 |
| Godly | Animated rainbow | 0.1% | **Gems** | 1,500 | 1,000 | Rebirth 20 |

- Weights for rarities the player hasn't unlocked are removed and the rest are renormalized.
- A **Luck** stat (from rebirth upgrades, gamepass, boosts) shifts weight toward rarer tiers.

---

## 5. Loot Boxes, Rolls & the Wheel 🟢

**Map loot boxes**
- Boxes spawn around the hub, between the plots. Each box has a visible **rarity** (color and glow) and a **part type** (label on top).
- **Decision (v0.4):** boxes are **shared**. Anyone can grab any box, first come first served. This gets players out of their tycoons to interact (and later, use their gadgets on each other), and gives them something to do while saving up for the next purchase.
  - Box count grows with the server: 6 with one player, +2 per extra player, 20 max. A replacement spawns 10–20 s after one is opened.
  - Boxes only roll rarities that **someone in the server** has unlocked. Players who haven't unlocked a box's rarity see it locked (`🔒 Rebirth 4`) and can't open it, which is a visible reason to rebirth.
  - **Rare+ spawns are announced** to the whole server, and so is who grabbed them.
  - **What a box gives** ✅: mostly a part of its own rarity, sometimes a rarer one. Each tier above is 15% as likely as the one below (Common box ≈ 87% Common, 13% Uncommon, 2% Rare…), limited to tiers the opener has unlocked. Upgrades get a "RARITY UP!" reveal. Odds live in `Config/Loot`, so the wheel shows exactly what the server rolls.
- 🟡 Polish: per-rarity box looks, particles, spawn animations and open effects. For example, Godly boxes arrive through a black hole.

**Rolls**
- A **Roll** is a loot box you carry. Open it from the HUD any time, and it gives a random rarity (from unlocked tiers) and a random part type.
- Sources: **3 free Rolls for new players**, the daily wheel, and Robux Roll packs. Roll packs are paid random items, so the UI must show their odds (see §12).

**Opening (box or Roll)**
1. The server validates the request: the box exists, belongs to the player and is in range, or the player has a Roll.
2. The **server rolls the result first**.
3. The client plays the **wheel animation**, which lands on the server's result. It is purely visual.
4. The reveal plays: a new part is unlocked (with an "Equip it on a line?" shortcut), or a duplicate is converted to currency.

**Duplicates**
- Common, Uncommon and Rare duplicates give **Coins**. The amount scales with rarity and the player's current income, so it stays relevant.
- Legendary, Mythic and Godly duplicates give **Gems**.

---

## 6. Assembly Lines 🟢

Each **zone** has several assembly lines (**3 in the Toy Workshop**). Players buy each line and its upgrades with tycoon buttons.

```
 [Head Dropper] [Body Dropper] [Arms Dropper] [Legs Dropper]
        └──────────────┴──────┬───────┴──────────────┘
                   [ Assembler ]  ← zone-themed assembly animation
                              │
               [ Upgrade stations ] (Paint Booth, Glitter Blaster, ...)
                              │
               [ Finishing stage ]  ← zone-themed last step (🟡 planned)
                              │
               [ Finishing upgrader ]  ← one more zone-themed station (🟡 planned)
                              │
                     [ Shipping chute ] ──► Coins into the collector
```

- **Part droppers:** each line has 4, one per part type, bought one at a time. A line ships with whatever droppers it has, so a floating head on legs is a valid (and hilarious) product. More droppers mean more valuable brainrots.
- **Part-by-part assembly** ✅ (HIGH priority: it's what players watch most). The Assembler builds one part at a time, in the order **Legs → Body → Arms → Head**, and each part has its own animation per zone (see §10). Faster lines (Speed upgrades) speed the show up so one brainrot is always finished before the next arrives. Server payouts follow the same schedule (`Production.Schedule`), so Coins land when the brainrot hits the chute.
- **Line menu:** each dropper has a slot showing the **unlocked** parts of its type. The player picks one per slot, or presses **Equip Best**. A new line auto-equips the best available parts.
- **One part, one line:** a part can be used on **only one line at a time**.
  - **Exception:** when every unlocked part of that type is already in use, a **Common** part can be reused on another line, so no line ever sits idle.
- **Speed upgrades** shorten the cycle time. **Upgrade stations** multiply the value of passing brainrots.
- **Shipping value** = sum of the part values × zone multiplier (§7) × upgrade stations × global multipliers (rebirth, gamepasses).
- **Full-match bonus:** if all 4 parts come from the same brainrot, the ship is worth **×2** and counts as a **completion** (§7).
- Line configurations are **remembered across rebirths**.
- **Finishing stage** 🟡 (requested 2026-09-30): every zone ends its line with its own themed, cute last step. Toy Workshop: the brainrot hops down to the floor, a toy box pops up and opens, the toy jumps in and the box closes. Plushie room: it gets filled with foam. Robot Plant: a wind-up key turns and the brainrot starts moving. Each new zone gets one.
- **Finishing upgrader** 🟡: after the finishing stage, one more upgrade station with the zone's own theme.
- **Paint Booth options** 🟡: the player picks the paint color, or turns the booth off. A gamepass (§12) paints each limb a different color.
- **Photobooth** 🟡 (on every floor): saves a brainrot exactly as the player painted it, to use as a colorful statue, a photo in the factory, an in-game icon, or all of them. The photo's background matches the floor it was taken on.

---

## 7. Editions & Completion Rewards 🟢

Every zone builds brainrots in its own **edition**: its own size, material and texture (see §10). A brainrot is **completed in an edition** the first time a full, matching brainrot ships from that zone. Every brainrot can be completed once **per edition**.

**Rewards**
- **Every new edition:** Gems = rarity's base completion Gems (§4) × the zone's Gems multiplier (§10).
- **First completion in any edition, extra:**
  1. A **themed gadget** (§3).
  2. A **Morph** unlock. The player can transform into the brainrot: the model is welded to the character and the default avatar is hidden. They toggle it from the catalog.
- A big celebration each time: full-screen banner, confetti, and the brainrot's catchphrase SFX. Rarer zones get bigger celebrations.

**Edition jackpot** ✅: shipping a full brainrot in a zone also claims every **earlier zone's edition** not yet claimed. A veteran who unlocks a brand-new Godly and ships it from their best zone collects every edition reward at once, plus a server-wide announcement. This keeps older players chasing every new brainrot, especially the ones added in updates.

**Full Set bonus** 💡: completing a brainrot in **all** editions grants a golden catalog frame and a permanent income bonus.

---

## 8. UI Catalog (Index) 🟢

- A grid of cards, one per brainrot, **sortable by rarity** (plus filters: All / Completed / Missing).
- Each card shows the brainrot's **silhouette**. **Unlocked parts show in color**, locked parts are **blacked out**. The name shows as `???` until at least one part is unlocked.
- Under the silhouette is an **edition badge row**, one badge per unlocked zone, e.g. Toy ✓ · Plushie ✓ · Clay 🔒.
- The header shows overall progress, e.g. `Parts 23/72 · Completed 5/18 · Editions 7/…`.
- Clicking a card opens details: the 4 part slots, rarity, per-edition rewards, and **Morph** / **Equip Gadget** buttons once completed. It also has an **"Equip on a line"** shortcut when every part is unlocked.
- ✅ A functional version is built (grid, silhouettes, filters, details, equip, morph, gadget).

**Polish target (the look we're going for):** a **sticker book**, very colorful and pretty.
- Each brainrot is a big, popped-out sticker. Its **rarity is the sticker's background**, with effects that scale with rarity (sparkles, shine, animated rainbow for Godly).
- Missing parts are empty sticker pieces that fill in as you unlock them. This can be 2D sticker art or 3D models with a nice camera angle, whichever fits the style best.
- Clicking a sticker shows the big picture with **round edition buttons** underneath: **gray** = zone not unlocked, **blue** = can be collected (ship a full one there), **green** = collected.
- Reference the famous simulator games (Pet Simulator 99/X, Bee Swarm, Anime Defenders…) for the whole UI: cute, friendly, VERY colorful, lots of effort on every screen.

---

## 9. Currencies 🟢

| Currency | Source | Spent on | Reset on rebirth? |
|---|---|---|---|
| **Coins** | Shipping brainrots, low-tier duplicates, daily wheel | Lines, droppers, upgrades, stations, decorations | ✅ Yes |
| **Gems** (premium) | Completions (per edition), high-tier duplicates, daily wheel, Robux packs, bosses 🟡 | Loot boosts, extra Rolls, premium boxes, cosmetics | ❌ No |
| **Rebirth Points** | Rebirthing (more points for more Coins at rebirth time) | Rebirth Shop permanent upgrades | ❌ No |

We also track the **Rebirths** count (not a currency), which gates zones and rarities, and **Rolls** (an item count).

---

## 10. Rebirths & Zones 🟢

- Rebirthing requires a Coin threshold that grows each rebirth.
- **Resets:** Coins, purchased tycoon items.
- **Keeps:** Gems, Rebirth Points, Rolls, unlocked parts, completions (all editions), morphs, gadgets, line configurations, and gamepass perks.
- **Grants:** Rebirth Points, a permanent income multiplier, rarity unlocks (§4), and new zones.

**Rebirth Shop** (spend Rebirth Points): Income %, Luck %, Walk Speed, Loot Box cap +1, Faster box respawn, Dropper speed %.
- ✅ Built (v0.5), numbers in `Config/Rebirths`:
  - Rebirth costs 50K Coins ×3 per rebirth, gives +25% Coins forever, and 1 Rebirth Point per full cost's worth of Coins (saving up pays).
  - Shop: **Income** (+10%/lv), **Dropper Speed** (+5%/lv), **Luck** (+10%/lv: rarer tiers weigh more, boxes upgrade more often).
  - Box cap and box respawn don't fit shared boxes, so they're dropped. Walk Speed comes later.
- Line setups of lines you haven't bought back since a rebirth are remembered, but don't hold their parts, so those parts are free for your other lines.
- Each zone is a room of the factory, further back from the hub. Zone 2's room gets its free first line the moment it unlocks.

### Zones

Zones aren't only floors. The factory **physically expands**: new floors, annexes, a giant lab bolted onto the side, an underground bunker, a rooftop launchpad. Progression is **slow and gradual**: each step is a small, believable upgrade over the last, and the jumps get more absurd as things get rarer.

| # | Zone | Where | Edition (size & style) | Assembly animation | Unlock | Status |
|---|---|---|---|---|---|---|
| 1 | **Toy Workshop** | Ground floor | Toy: small, glossy plastic | ✅ Wooden robots build it: the legs hop onto the pad, a claw lifts the body onto them, two robots punch the arms in, and the claw screws the head on with a spin. *Pop!* | Start | 🟢 |
| 2 | **Plushie Sewing Room** | Ground floor, back room | Plushie: small, fabric, stitched seams | ✅ The legs plop onto a cushion, the needle stitches the body down, thread spools reel the arms in, and the needle pumps the head full of stuffing. *Pop!* | Rebirth 2 | 🟢 |
| 3 | **Clay Studio** | 2nd floor | Clay: small, matte, fingerprints | Stop-motion hands mold the parts together | Rebirth 4 | 🟡 |
| 4 | **Vinyl Collectibles** | 2nd floor | Collectible: medium, shiny, boxed | Robot painters spray it, then it's sealed in a display box | Rebirth 6 | 🟡 |
| 5 | **Candy Factory** | 3rd floor | Candy: medium, gummy and translucent | Poured into a mold, blasted with sprinkles | Rebirth 9 | 🟡 |
| 6 | **Robot Plant** | Annex building | Animatronic: medium-large, metal | Robot arms weld it with sparks, and its eyes boot up | Rebirth 12 | 🟡 |
| 7 | **Mad Science Lab** | Giant lab on the side of the building | Living: life-size, wanders the lab | Crazy-scientist table: lightning bolts bring it to life | Rebirth 16 | 🟡 |
| 8 | **Secret Bunker** | Underground | Clone: life-size, glowing | Cloning vats fill with green goo while alarms flash | Rebirth 20 | 🟡 |
| 9 | **Titan Foundry** | Giant hangar | Giant: huge, forged metal | Cranes pour molten metal and sparks rain down | Rebirth 25 | 🟡 |
| 10 | **Orbital Forge** | Rooftop launchpad, then orbit | Cosmic: huge, galaxy texture | Tractor beams fuse it in space | Rebirth 30 | 🟡 |

Rule of thumb: **the rarer the zone, the cooler the animation.** Every zone follows the Toy Workshop pattern: the brainrot is built **part by part** (Legs → Body → Arms → Head), and each part gets its own creative, funny, cute animation by machines themed after the zone. For example, the Plushie room's sewing machine stitches the arms on, and the Candy Factory pours the head from a mold.

**Zone multipliers** (placeholder)

| Zone | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Ship value × | 1 | 2 | 3.5 | 6 | 10 | 17 | 30 | 50 | 85 | 150 |
| Completion Gems × | 1 | 1.5 | 2 | 3 | 4.5 | 6.5 | 10 | 15 | 22 | 33 |

Jackpot example: shipping a new Godly (1,000 base Gems) in Zone 10 claims all 10 editions for 1,000 × 98.5 = **98,500 Gems**.

---

## 11. Map Bosses 🟡 (later, not in MVP)

- Giant brainrots spawn naturally on the map on a timer. Players in the server fight them together.
- Loot is split by damage contribution: Gems, high-rarity loot boxes, and exclusive boss-only parts.
- Idea only. Not designed or implemented yet.

---

## 12. Monetization 🟢

**Gamepasses**
- **VIP:** +25% Coins, VIP chat tag, +1 free daily spin, VIP lounge.
- **2x Coins**
- **Auto-Collect:** collector coins bank automatically, **and you can configure your lines from anywhere** (the HUD LINES button) ✅. Without it, you configure a line by walking up to its robot (free; the server checks reach). Set the pass id in `Config/Gamepasses` once it exists.
- **Lucky:** +Luck on loot box and Roll rarity.
- **Fast Open:** skips or speeds up the wheel animation (Pet Sim–style QoL).
- **Sprint** 🟡 (requested): hold Shift to run.
- **Custom Paint** 🟡 (requested): paint each limb a different color at the Paint Booth (§6).

**Developer Products**
- **Gem packs** (S / M / L / XL)
- **Roll packs** (x3, x10)
- **Daily wheel spins** (x1, x5)
- **Server Luck Boost** 💡: everyone in the server gets 2x Luck for 15 min, with a server-wide announcement of who bought it.

**Daily Wheel**
- 1 free spin every 24 h (rolling timer). Paid spins with Robux (and maybe Gems).
- Prizes: Coins, Gems, Rolls, temporary Luck boosts, and a small chance at a Mythic box.
- ✅ Built (`Config/DailyWheel`): Coins (2 min of income) 30%, 25 Gems 22%, 1 Roll 18%, Luck boost 15 min 12%, 100 Gems 8%, 3 Rolls 7%, **500 Gems jackpot 3%**. The jackpot replaces the Mythic box, because rarities stay locked behind rebirths. VIP gets 2 free spins a day.

**Compliance:** anything bought with Robux that grants random rewards (Roll packs, paid wheel spins) must **show the odds in the UI before purchase** (Roblox paid random items policy). All purchases are handled server-side via `ProcessReceipt`, with receipt IDs stored to prevent double-granting.

---

## 13. Aesthetic & Juice 🟢

- **UI:** rounded corners (UICorner), thick dark outlines (UIStroke), gradients (UIGradient), drop shadows, and big icons. Buttons bounce on hover and click.
- **Feedback:** floating `+1.2K 💰` popups over the shipping chute, a currency counter that ticks up, screen shake and a rarity-colored flash on rare pulls, and a rainbow shimmer for Godly.
- **Audio:** a click SFX on every button, machine clanks, a cash-register sound on each ship, a wheel tick, a rarity reveal stinger, and upbeat background music.
- ✅ **Core-loop juice pass (v0.7):** every assembly step has its own sound (plop, boing, servo whir, BONK, ratchet, sewing, squeak, pop), the droppers squash and spit, the Assembler's beacon flashes while it builds, the upgrade stations paint or glitter each brainrot as it passes (with its ×multiplier), coins hop from the chute to the Cash Pad, full matches get confetti and "PERFECT!". The belts scroll, bought items pop in piece by piece, the Cash Pad piles up coins and bursts (coins fly into the HUD counter) when collected, and affordable buttons get a bouncing arrow. Lighting: bloom (Neon glows), color grading, pastel haze; shuffled background music with a mute button. Ids live in `Config/Sounds`.
- **Numbers:** abbreviated (1.2K, 3.4M, 5.6B…).
- **Assets:** toolbox models, maps and UI kits are allowed. Restyle them to fit the palette.

---

## 14. Technical Architecture

**Sync:** the project uses **Azul** (Studio-first sync into `./sync`).
- Script → `Name.server.luau`
- LocalScript → `Name.client.luau`
- ModuleScript → `Name.luau`

**Studio is the source of truth.** Keep Azul running while code is being written: if it restarts, it rewrites `sync/` from Studio.

```
ServerScriptService/
  Main.server.luau              -- bootstrap: requires and Init()s every service
  Services/
    DataManager.luau            -- profiles, currencies, Rolls, inventory, DataStore saving
    TycoonManager.luau          -- plots, purchase buttons, collector, Cash Pad, placeholder geometry + Assembler machines
    ProductionManager.luau      -- line config (one part, one line), production timers, shipping, completions, Line menu view
    LootManager.luau            -- shared loot boxes, Rolls, server rolls, duplicates
    RebirthManager.luau         -- rebirths and the Rebirth Shop
    GadgetManager.luau          -- gadgets and morphs
    MonetizationManager.luau    -- gamepasses (perks from config), dev products (ProcessReceipt)
    DailyWheelManager.luau      -- the Daily Wheel (free + bought spins, prizes)
    DevTools.luau               -- Studio only: ServerStorage.DevCommand (AddCoins, Snapshot, Restore…) for playtests
ReplicatedStorage/
  Shared/
    Remotes.luau                -- get RemoteEvents/Functions by name (server creates, client waits)
    Format.luau                 -- number abbreviations (1.2K)
    BrainrotModels.luau         -- builds a brainrot part (real model or placeholder), styled per zone; mixed-part layout
    Config/                     -- Rarities, Brainrots, Zones, TycoonItems, Production (+ assembly schedule), Loot,
                                --   Sounds, Rebirths, Gadgets, Gamepasses, Products, DailyWheel
  Client/UI/                    -- client-only UI modules
    Kit.luau                    -- Pet Sim X style building blocks (panels, bouncy buttons, viewports, toasts)
    LineMenu.luau               -- line menu (server-built view, intents only)
    Loot.luau                   -- Roll opening, prize wheel, reveal card (queued)
    Catalog.luau                -- the Index
    Celebration.luau            -- completion banner (queued)
    RebirthMenu.luau            -- rebirth + Rebirth Shop
    Shop.luau                   -- gamepasses and Robux products, with odds for random items
    DailyWheelMenu.luau         -- the Daily Wheel
  Client/Effects.luau           -- world juice: 3D sounds, sparkles, puffs, rings, flashes, popups, flying coins
  Assets/Brainrots/             -- split brainrot models (see §3)
StarterPlayer/StarterPlayerScripts/
  ProductionVisuals.client.luau -- drop → part-by-part assembly (per-zone machines) → stations → ship, with sounds and effects
  TycoonFX.client.luau          -- rolling belts, build-in animations, Cash Pad coin pile, button arrows
  Atmosphere.client.luau        -- lighting, bloom, color grading, background music + mute
  UIController.client.luau      -- HUD counters, menu buttons, "Configure line" prompts
  LootBoxes.client.luau         -- draws the shared boxes, opens them on walk-in, announcements
  GadgetsClient.client.luau     -- the client half of gadgets (emote animations)
```

**Security principles**
- **Server-authoritative.** Clients send *intents* ("I touched box #12", "set Head dropper to Sahur"), never values ("give me 500 coins").
- The server validates every remote: argument types, ownership (e.g. the part is unlocked and free), distance, cooldowns, and rate limits.
- Random results are rolled on the server **before** any client animation.
- **Production is simulated on the server with timers.** The parts moving on the lines are client-side visuals only. Exploiters can't fling parts into the collector, servers don't choke on physics, and each client only animates lines near its camera.
- Only `DataManager` writes player data. Other services go through its API.

**Data saving (DataManager)**
- `UpdateAsync` only, with **session locking** so two servers can't load the same profile and duplicate or roll back items.
- Autosave (~60 s), a save on leave, and `BindToClose` saves on shutdown.
- Retries with exponential backoff. Data is **never saved if it failed to load**, so a failed load can't overwrite real data with defaults.
- Schema versioning and migrations, plus reconciliation with the template (new fields get defaults automatically).
- A separate DataStore in Studio, so testing never touches live data.

### Player data schema (v1)

```lua
{
  Coins = 0,
  Gems = 0,
  RebirthPoints = 0,
  Rebirths = 0,
  Rolls = 3,        -- starter Rolls
  Inventory = {
    Parts = {       -- [brainrotId] = { Head = true, ... } (unlocked parts; starts with the starter brainrot)
      TralaleroTralala = { Head = true, Body = true, Arms = true, Legs = true },
    },
    Completed = {}, -- [brainrotId] = { [zoneId] = os.time() of first full ship in that zone's edition }
  },
  Tycoon = {
    Purchased = {}, -- [itemId] = true (reset on rebirth)
    Lines = {},     -- [lineId] = { Head = brainrotId, Body = ..., Arms = ..., Legs = ... } (kept on rebirth)
  },
  Stats = {
    TotalCoinsEarned = 0,
    FirstJoin = 0,
    LastJoin = 0,
  },
}
```

---

## 15. 2-Day Sprint Plan

**Day 1**
1. ✅ GDD
2. ✅ DataManager (currencies, inventory, per-edition completions, secure saving)
3. ✅ Shared config: rarities, brainrot roster, zones, tycoon items
4. ✅ TycoonManager: auto-assigned plots, purchase buttons, collector, Cash Pad (placeholder geometry)
5. ✅ ProductionManager (Toy Workshop, 3 lines): droppers, one-part-one-line rule, Equip Best, shipping, completions and edition jackpot
6. ✅ Production visuals: Toy Workshop drop → press → ship animation, coin popups

**Day 2**
6b. ✅ Part-by-part assembly (Toy Workshop robots: claw, pushers) + mixed-part sockets
7. ✅ HUD (currencies, Rolls) and Line menu UI (also: "Configure line" prompt on each line's robot)
8. ✅ LootManager: Rolls + shared loot boxes, server roll, spin wheel UI, duplicate conversion, Rare+ announcements
9. ✅ Catalog UI: silhouettes, per-part coloring, edition badges, sort by rarity, filters, "put it on a line"
10. ✅ Completion celebrations (full-screen banner, server announcements), morph, 3 gadgets (Sahur baton, Ballerina emote, Tralalero sneakers)
11. ✅ RebirthManager, Zone 2 (Plushie Sewing Room, with its own sewing-machine assembly), Rebirth Shop (basic)
12. ✅ Monetization: 5 gamepasses (VIP, 2x Coins, Auto-Collect, Lucky, Fast Open), dev products (Gem packs, Roll packs, wheel spins) with receipt de-duplication, the Daily Wheel, and a Shop that shows odds before any random purchase. **To go live:** create the passes/products on the Creator Dashboard and paste their ids into `Config/Gamepasses` and `Config/Products`.
13. Swap placeholders for real models and themed zone art, polish (sounds, juice), publish, test on a live server

**Later 🟡:** Zones 3–10 (themed animations), living brainrots, map bosses, Bombardiro mount, Loot Rain, trading, quests.

**Polish backlog** (flagged, after the loop is complete):
- The loot wheel looks ugly; redesign it.
- All UI: much more effort, cute, friendly and VERY colorful, referencing the famous simulator games. The Index becomes a sticker book (§8 polish target).
- A real map to replace the baseplate hub, and real facility art (the tycoon is placeholder blocks).
- Brainrot models (§3), per-rarity box effects (§5). ~~Sounds and music~~ (first pass done in v0.7; UI sounds and per-zone machine sounds can still grow).
- Art sources, in order: **1) build the assets ourselves first** (voxel brainrots split into parts, props, UI styling, all made in Studio). **2) Only if that falls short:** paid or online asset packs (map, facility, UI), or paid brainrot sets (voxelized to match the style).

---

## 16. Proposed Ideas 💡

1. **Full Set bonus:** all editions completed gives a golden frame and permanent income (§7).
2. **Hybrid brainrots:** mixed-part ships get mashup names ("Tung Tung Tralala") and a funny "Hybrid" popup. A Hybrid Index could come later.
3. ⏸️ **Showcase multiplier (on hold):** completed brainrots stand on pedestals in your tycoon, and each one adds +X% income. Kept on the table, not planned.
4. **Gold / Rainbow part variants:** a rare roll on the wheel upgrades a part to Gold or Rainbow for bonus value and flex. No new models needed.
5. **Index milestones:** completing X brainrots of a rarity grants permanent buffs (the Pet Sim index loop).
6. **Loot Rain event:** every ~15 min, the map floods with shared boxes for 60 s.
7. **Offline earnings:** earn a capped % of income while away, with a "Welcome back! +50K" popup.
8. **Weekly brainrot drops:** new brainrots in updates. Paired with the edition jackpot, veterans rush back.
9. **Morph edition:** your morph uses the style of your best completed edition (a Candy Sahur, a Cosmic Sahur…).
10. **Codes, group rewards, like goals, global leaderboards.** A cheap launch-growth toolkit.
11. **Original Godly brainrot:** our own signature character, for brand identity and thumbnails.
12. ✅ **Remote line config as a gamepass perk:** decided and built, bundled with Auto-Collect (§12).
13. **Control Room computer:** a computer on a higher floor that configures every line in the whole facility from one place.
14. **The facility grows up and out:** each expansion adds floors and side wings, and the whole place looks more and more like a dreamy science factory.
15. **Toy Workshop chutes:** parts slide out of chutes onto the belt instead of dropping from boxes.
16. **Per-rarity box effects:** unique looks, particles, spawn and open animations per rarity. Godly boxes arrive through a black hole (§5).
17. **Signature idle touches:** finished brainrots get a small idle animation or prop from their meme, like *Steal a Brainrot* does: Lirilì's floating clock, Tung tapping his bat, Tralalero's tail wag, Trippi's antennae wobble.

---

## 17. Open Questions

1. **Zone list and pacing (§10):** does the 10-zone progression feel right? Names, order and rebirth requirements are all easy to change in `Config/Zones`.
2. ~~Loot boxes: personal or shared?~~ Shared (v0.4, §5).
4. ~~Remote line config: free or gamepass?~~ Gamepass, bundled with Auto-Collect (§12).
3. **Rebirth:** keep unlocked parts, completions and line configurations through rebirths (§10). OK?

---

## Changelog
- **v0.8 (2026-09-30):**
  - All 15 brainrots have voxel art. The 14 *Steal a Brainrot* ones follow its renders; the Godly is our own **Supremo Brainrotto, the Risotto King** (§3).
  - Requested and planned: a themed **finishing stage** and **finishing upgrader** per zone, **Paint Booth options** and a **Photobooth** (§6); **Sprint** and **Custom Paint** gamepasses (§12).
- **v0.7 (2026-09-30):** Core-loop juice pass (§13): per-step assembly sounds and effects, station effects, flying coins, rolling belts, build-in animations, the Cash Pad coin pile, lighting with bloom, and background music.
- **v0.6 (2026-09-30):**
  - Monetization built: 5 gamepasses with config-driven perks, Gem, Roll and wheel-spin products granted once per receipt, the Daily Wheel (jackpot is 500 Gems instead of a Mythic box), and a Shop that shows odds before purchase.
  - A VIP chat tag was added.
  - Art plan: we build assets ourselves first; paid or online packs only if that falls short.
- **v0.5 (2026-09-30):**
  - Box odds: a box gives mostly its own rarity, sometimes rarer ones (§5).
  - Remote line config is an Auto-Collect gamepass perk (§12).
  - Built:
    - The Catalog (functional; sticker-book look planned for polish, §8).
    - Completion banner and server announcements.
    - Morphs and 3 gadgets.
    - Rebirths and the Rebirth Shop (Income, Speed, Luck).
    - Zone 2, the Plushie Sewing Room, with its sewing-machine assembly.
    - Studio DevTools.
  - Every zone gets its own themed part-by-part assembly (§10). A polish backlog was added (§15).
- **v0.4 (2026-09-30):**
  - **Part-by-part assembly:** Legs → Body → Arms → Head, each with its own animation. The Toy Workshop now has wooden robots: a claw lifts the body and screws the head on, and two pushers punch the arms in. It speeds up on fast lines.
  - **Mixed parts use the body's sockets**: a head goes where that body's own head would be (§3).
  - **Loot boxes are shared** (first come first served), gated by rarity unlocks, with Rare+ announcements (§5).
  - HUD, Line menu, Roll wheel and reveal are built.
  - Art sourcing rule: toolbox first, AI generation only as a last resort; art polish deferred.
  - New ideas: remote line config gamepass, Control Room computer, facility growth, chutes, per-rarity box effects (§16).
- **v0.3 (2026-09-29):**
  - Floors became **zones**: 10 themed zones with slower, gradual progression and a unique assembly animation each. They include expansions like the side lab and the secret bunker.
  - **Sizes** became **editions**: each zone has its own size and style. The **edition jackpot** is confirmed.
  - Assembly lines: several per zone, the **one part, one line** rule with a Common fallback, and Equip Best.
  - New players get **3 free Rolls** plus the starter brainrot. Rolls were added.
  - Brainrot models are **split into 4 parts** (asset spec in §3).
  - The showcase multiplier is on hold.
- **v0.2 (2026-09-29):** Droppers are now part droppers feeding an Assembler. Completion happens on ship, per size. Added the size jackpot and ProductionManager.
- **v0.1 (2026-09-29):** Initial GDD from the mechanics brief.
