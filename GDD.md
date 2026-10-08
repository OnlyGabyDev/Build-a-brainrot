# Build a Brainrot — Game Design Document

> Living document. Update it whenever a mechanic changes, is cut, or is promoted from "Later" to "MVP".
> **Status legend:** 🟢 MVP (build in the 2-day sprint) · 🟡 Later (planned, not now) · 💡 Proposed (idea, needs approval) · ⏸️ On hold

---

## 1. Vision

A joyful, colorful **brainrot factory tycoon**. The factory *is* the brainrot builder. **Assembly lines** of part droppers (Head, Body, Arms, Legs) feed an **Assembler** that builds brainrots and ships them for Coins. Players hunt **loot boxes** to unlock new parts for their droppers. The factory then grows into ever-crazier **zones**: a toy workshop, a sewing room, a candy factory, a mad-science lab, a secret bunker… Each zone builds brainrots in its own **edition** (size and style) with its own over-the-top assembly animation.

**Pillars**
1. **Number goes up.** Constant income, big popups, and satisfying upgrades (money-farming loop).
2. **Gotta collect 'em all.** The sticker album makes missing parts itch, and every full brainrot is a sticker to claim.
3. **Visual candy.** Every zone has its own assembly show, and the rarer the zone, the crazier the animation.
4. **Hype moments.** Wheel spins, rare pulls, the first PERFECT, claiming a brainrot, and rebirths all get loud, flashy feedback.
5. **Simple first.** Ship a tight core loop, then expand zone by zone.

**Aesthetic:** Pet Simulator X–style UI. Bright saturated colors, thick outlines, rounded bouncy buttons, chunky fonts (FredokaOne / LuckiestGuy), rarity-colored glows, confetti, and sound on every click.

---

## 2. Core Loop 🟢

```
   Open loot boxes / Rolls (wheel) ──► Unlock parts ──► Configure assembly lines (menu)
              ▲                                                   │
              │                                                   ▼
   Rebirth: new zones,             Coins ◄── Ship brainrots ◄── Droppers → Assembler
   rarer loot, multipliers                  (full match = PERFECT, x2 Coins; all 4 parts = CLAIM in the Album → Gems, gadget, morph)
```

1. On join, the player gets a **tycoon plot** automatically. New players start with:
   - the **starter brainrot** (all 4 Tralalero Tralala parts), so the first line can run a full match right away;
   - **3 free Rolls**, so they get new parts in their first minute.
   - **Tralalero's guide** (newcomers only; players from before it skip it): a short camera flight onto YOUR factory (your name on its sign; any press skips it), then Tralalero says each goal in a speech bubble at the bottom (a few words and a big icon), a big 3D arrow bounces over it (seen through walls) with a ring round it, and a trail of chevrons at your feet points the way. The goals: step on FREE (+20 💰) → grab your cash (+20 💰; "Watch it build!" at the line until the first Coins land) → open your gift box (a box of your own in your front yard; +1 🎲) → buy the Body (+60 💰), the Arms (+150 💰), the Legs (+1 🎲) → watch the first PERFECT → a gift: a new **Rare+ part** (and, once ever, the favorite prompt) → **upgrade your line** (+1 🎲: the arrow leads to its tablet; the Line menu opens on UPGRADES with a big yellow arrow bouncing under the button to press; any track's first level counts) → **meet your mascot** (+1,000 💰: walk up to it out front; then "REBIRTH to make it grow!") → **open the Plushie room** (+2 🎲; the long goal, ~5–8 min). Short of Coins with enough on the Cash Pad, it sends you there first; short of Coins for a goal, a gold bar in the bubble fills with them ("4.7K / 25K"), and on the long goal the bubble shrinks out of the way after a few seconds and comes back full size once the Coins are there. Every goal is walked to, or a button the guide points at, so it plays the same on PC, phones and consoles. Until the long goal (v4.8) only the first line's buttons show (no rooms, floors, room upgrades or more lines), no ads or join popups show, and the affordable buttons' own arrows hide; from the long goal everything comes back (the daily calendar, then the Starter Pack). ~1 min to the PERFECT for a quick player, ~1.5 min to the long goal.
2. They build **assembly lines** in the **Toy Workshop** with Coins. Each line has 4 part droppers, an Assembler, upgrade stations and a shipping chute.
3. The Assembler combines the parts into a brainrot and ships it. Coins go into the **collector**. The player steps on the **Cash Pad** to bank them (Coins that land while they stand on it go straight in; the Auto-Collect gamepass skips the pad). Coins still on the pad when you leave are banked (v4.3).
4. **Loot boxes** spawn around the map. Opening one (or using a Roll) spins a **wheel** that unlocks a new part.
5. Owning all **4 parts** of a brainrot lets you **claim** it in the **Album** (v4.1): its Gems, its gadget and its morph. Shipping one whose 4 parts all match is a **PERFECT** (×2 Coins).
6. **Rebirth** resets the tycoon but slowly unlocks new **zones**, more luck (rarer loot), and permanent multipliers.

---

## 3. Brainrots & Parts 🟢

- Every brainrot has exactly **4 parts: Head, Body, Arms, Legs**.
- A part belongs to one specific brainrot, e.g. *Tung Tung Tung Sahur — Head*.
- A brainrot's rarity is the rarity of all 4 of its parts.
- Parts are **unlocked or locked**. There are no stacks, because duplicates convert to currency (see §5).

### The roster (50 planned, in 3 waves)

**Real memes only** (the user, 2026-10-07): every brainrot comes from its creator's original post in the 2025 "Italian brainrot" wave (TikTok), never one a game made up. *Steal a Brainrot* invented many of its own (Noobini Pizzanini, Cocofanto Elefanto, Gattatino Neonino, Raccooni Jandelini, Chimpanzini Spiderini, its "67"...): those are out, and so are its 3D models: our block art follows **the original meme image** (how to find it: docs/reference.md). Also out: names that read badly to kids (Brri Brri Bicus Dicus Bombicus, Graipuss Medussi, the "Pipi" ones, Gangster Footera) and, while their owner's lawsuit against *Steal a Brainrot* runs (2026), the other characters of Tung Tung Tung Sahur's creator (Odin Din Din Dun, Garama and Madundung, Esok Sekolah). Tung Tung Tung Sahur stays (the user's call). Original images with guns or cigars get neither (Bandito Bobritto).

| Rarity | In the game (38) | Wave 3 (12) |
|---|---|---|
| Common (14) | **Tralalero Tralala** (*starter*), Brr Brr Patapim, Lirilì Larilà, Trippi Troppi, Tim Cheese, Ta Ta Ta Ta Sahur, Tric Trac Baraboom, Fluriflura, Talpa Di Fero, Svinina Bombardino, Cacto Hipopotamo | Bambini Crostini, Moranguete, Abacatudo |
| Uncommon (11) | Ballerina Cappuccina, Chimpanzini Bananini, Boneca Ambalabu, Bandito Bobritto, Trulimero Trulicina, Bananita Dolphinita, Perochello Lemonchello, Mangolini Parrocini, Penguino Cocosino | Spioniro Golubiro, Lionel Cactuseli |
| Rare (9) | Cappuccino Assassino, Bombombini Gusini, Frigo Camelo, Burbaloni Loliloli, Blueberrinni Octopusini, Strawberrelli Flamingelli, Rhino Toasterino | Cavallo Virtuoso, Cocosini Mama |
| Legendary (7) | **Tung Tung Tung Sahur**, Glorbo Fruttodrillo, Orangutini Ananassini, Zibra Zubra Zibralini, Gorillo Watermelondrillo | "67" (our own look: the meme is real, the *Steal a Brainrot* figure isn't), Ballerino Lololo |
| Mythic (5) | **Bombardiro Crocodilo**, La Vaca Saturno Saturnita, Girafa Celestre, Orcalero Orcala | Espresso Signora |
| Godly (4) | **Dragon Cannelloni** (glowing fire breath), Trenostruzzo Turbo 3000 | Nuclearo Dinossauro, Ketupat Kepat |

Every brainrot has a gadget (`Config/Gadgets`, one of the archetypes below): Tralalero's speed sneakers, Ballerina's **dance emote**, Sahur's **high-knockback baton**, Bombardiro's jet launch, Dragon Cannelloni's dragon-wing launch, and simple ones for the rest. Our own Supremo Brainrotto (the old Godly) left in v5.7; saves that had it got Dragon Cannelloni instead. Wave 3: check each one's creator and original image first (`tools/brainrot_refs.py`; Moranguete and Abacatudo come from the Brazilian AI fruit soap operas, not that wiki); swap any that can't be traced to its creator.

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
- **Mixed parts use the body's sockets** ✅: the body anchors the build. The legs stand on the ground, the body sits on the legs' hip, and a head or arms from another brainrot go **where that body's own head or arms would be**. A head on a Tralalero body lands where the shark's head is, in front of the body, and on top for Sahur. This gives each brainrot its own silhouette. (v3.0: the sockets are measured from the art, the middle of where each part touches its own body, each shoulder for two-sided arms, and a swapped-in part that still doesn't touch is pulled in until it does: mixes used to float, e.g. a Chimpanzini head hanging in front of a Frigo Camelo.)
  - Optional: a part can mark its exact connection point with an Attachment named `Joint` (Legs: the hip; Head and Arms: the point that meets the body). Without one, the game uses the part's bounding box.
- Until a brainrot has a model, the game uses **colored placeholder blocks** in the brainrot's color. Everything stays playable while art is added one brainrot at a time.
- **Art sourcing:** toolbox models first. Roblox AI generation only as a last resort. The AI mesh splitter only works on meshes we own, so prefer toolbox models that are already built from separate parts (rigs, multi-mesh models). Art polish is deferred until the loop is complete; most toolbox brainrots tried so far looked too rough.

---

## 4. Rarities 🟢

All numbers are **placeholders**. Tune them in playtests.

| Rarity | Color | Base loot weight | Duplicate reward | Part value (Coins) | Claim Gems |
|---|---|---|---|---|---|
| Common | Light grey `#C8CDD2` | 65% | Coins | 20 | 10 |
| Uncommon | Green `#5BE35B` | 26% | Coins | 48 | 25 |
| Rare | Blue `#3DA5FF` | 6.5% | Coins | 120 | 60 |
| Legendary | Gold `#FFC53D` | 2% | **Gems** | 400 | 150 |
| Mythic | Pink `#FF4FD8` | 0.4% | **Gems** | 1,400 | 400 |
| Godly | Animated rainbow | 0.06% | **Gems** | 6,000 | 1,000 |

- **No rarity cap** (v3.4, the user, 2026-10-06): every rarity drops from the start; the weights keep the high ones rare, and each rebirth adds +0.1 luck (rebirth 10: luck 1). Was: Rare at Rebirth 1, Legendary 4, Mythic 10, Godly 20 (before Rebirth 1 only Common/Uncommon dropped: 28 of 60 parts, all found in ~30 min).
- A newcomer's first 3 Rolls (the starter ones) and first box always give a part they don't have yet (of the rolled rarity, while any is left; `Config/Loot.SureNew`).
- A **Luck** stat (from rebirths, rebirth upgrades, gamepass, boosts) shifts weight toward rarer tiers: each tier above Common gets +25% weight per point of luck per rank (luck 1: Rare ×1.5, Legendary ×1.75, Godly ×2.25), and a box upgrades a tier 8% of the time (+50% per point of luck). v3.2 (the user, 2026-10-03: the high rarities came too easily): the weights above were 60/25/10/4/0.9/0.1, luck was +100% per rank and the upgrade 15% (+100% per luck): at full luck a Legendary Roll was 12.6% (now 3.9%) and a Godly map box at Rebirth 20 1 in 48 (now 1 in 550).

---

## 5. Loot Boxes, Rolls & the Wheel 🟢

**Map loot boxes**
- Boxes spawn all over the map (v3.4, the user: not only round the plaza, so players without fast gadgets get some too): half of them round a random player's front yard (just past their factory lot), the rest anywhere 40–600 studs from the hub, hills included (never on water or a factory lot). Each box has a visible **rarity** (color and glow) and a **part type** (label on top).
- **Decision (v0.4):** boxes are **shared**. Anyone can grab any box, first come first served. This gets players out of their tycoons to interact (and later, use their gadgets on each other), and gives them something to do while saving up for the next purchase.
  - Box count grows with the server: 18 with one player, +6 per extra player, 50 max (v3.4: the area is ~7× bigger). A replacement spawns 10–20 s after one is opened.
  - Map boxes roll their rarity like a Roll without luck (v3.4: they rolled from the server's best rebirths, and newcomers saw boxes locked `🔒 Rebirth 4`); anyone can open any box.
  - **Rare+ spawns are announced** to the whole server, and so is who grabbed them. (v4.4, the user: the big banner was too much) A small card slides down under the top bar: the rarity's colors with white stripes and a neon rim, a gift, "LEGENDARY BOX" and its part, and an arrow that points at the box from where you look, with its distance counting down as you run; it goes after 8 s or once the box is taken. The **Box Radar** pass lays three neon chevrons (with a dark outline) on the floor ahead of you, rippling toward the nearest Rare+ box you can open, with a pill over your head: its rarity and distance.
  - **What a box gives** ✅: mostly a part of its own rarity, sometimes a rarer one. Each tier above is 15% as likely as the one below (Common box ≈ 87% Common, 13% Uncommon, 2% Rare…). Upgrades get a "RARITY UP!" reveal. Odds live in `Config/Loot`, so the wheel shows exactly what the server rolls.
  - ✅ (v3.7, the user: a rarer box is worth the run) **Every box also pays Coins by its own rarity**: a base plus some seconds of your income (Common 25 + 10 s, Uncommon 75 + 20 s, Rare 250 + 45 s, Legendary 1K + 90 s, Mythic 4K + 180 s, Godly 15K + 360 s; `Loot.BoxCoins`), on top of the part. A gold "+X" rises from the box and coins fly to you.
  - ✅ (v3.7, the user: crowded boxes cluttered the screen) Map boxes land at least 30 studs apart (bought ones 7), and labels show only up close: the nearest 5 within 60 studs, Rare and up within 140.
- ✅ (v4.4) **Boxes float** a little over a glowing neon pad in their color (the tall grass hid them), with **white candy stripes** round their sides and white edges (glowing from Rare up), a soft beam over Rare ones, and a dark pill behind their labels. **A warning before each arrival near you** (~2.6 s, long enough to run there): a target ring closing in on the spot, blinking and ticking faster, a pillar of light and a "V" over it seen from afar; things that fall (Common, Uncommon, Legendary) cast a shadow that grows darker and bigger, with a shell's whistle; things that come up (Rare, Godly) crack the ground and shake it. No warnings in a box storm (more than 4 arrivals in 3 s, or a bought drop of 5+).
- ✅ (v2.8) Per-rarity looks, arrivals and openings: the rarer, the bigger and louder. (v3.7: the ribbon and bow are plain white and smaller, under a neon band in the rarity's color: the rarity is what you see from afar, not a gold ribbon.) Rare boxes glow at the edges; Legendary ones are gold under a halo in a beam of light; Mythic ones are crystal with a glowing core and orbiting stars; Godly ones cycle through the rainbow over a black hole, which closes when they're opened. Opening one bursts in confetti, a shockwave and a flash, bigger with its rarity.
- ✅ (v2.9, the user: every rarity its own arrival) **Arrivals:** Common drops out of the sky and bounces; Uncommon floats down under a striped parachute that collapses onto it; Rare bursts up out of the ground in a spray of dirt and leaves a mound; Legendary is a meteor (a fireball streaking in at a slant, trailing fire and smoke, a boom, a camera shake, a scorched crater that cools); Mythic is summoned (a magic circle lights up, lightning strikes it, the box materializes in stars); Godly rises out of its black hole. Only boxes near the camera animate (a box storm can put ~150 on the map).
- ✅ (v2.9, the user) **Bought box drops** (§12): 1, 5, 10, 25 or 100 boxes (a "BOX STORM") rain onto the map round the buyer, one every 0.12 s. Each rolls its rarity like a Roll with the buyer's luck +1; they're the buyer's alone for 2 minutes (their name and a countdown over each), then anyone's, at once if the buyer leaves. They don't count toward the map's own boxes and aren't replaced; at most 120 are out at once (the rest wait). The whole server sees "NAME started a BOX STORM!". Tuning: `Config/Loot.Drops`.
- ✅ (v2.9) Results that pile up (a storm) skip the reel: they pop into a quick feed on the right (new part or the duplicate's reward), and a new Rare+ part still gets its full reel.

**Rolls**
- A **Roll** is a loot box you carry. Open it from the HUD any time, and it gives a random rarity (with the player's luck) and a random part type.
- Sources: **3 free Rolls for new players**, the daily wheel, and Robux Roll packs. Roll packs are paid random items, so the UI must show their odds (see §12).

**Opening (box or Roll)**
1. The server validates the request: the box exists, belongs to the player and is in range, or the player has a Roll.
2. The **server rolls the result first**.
3. The client plays the **wheel animation**, which lands on the server's result. It is purely visual. ✅ (v2.5) The wheel is a **prize reel**: a strip of glossy rarity cards slides through a lit gold frame and stops on the result under a gold marker, ticking as each card passes (the Daily Wheel uses it too). **v3.3 (the user, before the release): no reel any more.** The screen dims, flashes in the rarity's color and the reveal card pops up with the part won; the Daily Wheel shows its prize the same way. **v3.6:** the card shows the part on its whole brainrot (the part in color, hopping out and back; the rest a dark see-through silhouette), at three quarters.
4. The reveal plays: a new part is unlocked (with an "Equip it on a line?" shortcut), or a duplicate is converted to currency.

**Duplicates**
- Common, Uncommon and Rare duplicates give **Coins**: a base by rarity (100 / 250 / 600) plus seconds of the player's current income by rarity (15 / 30 / 60 s; v5.2: was 15 s for all three, so with a big income a Common duplicate paid about what a Rare did), so a rarer duplicate always pays more and it stays relevant. A box also pays its own Coins by its rarity (above), and a box never gives a part below its own rarity.
- Legendary, Mythic and Godly duplicates give **Gems**.

### Daily login streak ✅ (v4.2, the user)
A reward a day, so newcomers come back on day 2 (the 500-engaged-players goal). A **7-day calendar** (`Config/DailyLogin`) pops up on the first join of each UTC day (after Tralalero's guide for a newcomer; the Starter Pack offer waits for it) and opens from a calendar button on the HUD (top right, under the gear, a "!" while today's waits). Each day's card shows its reward's icon (a box day shows the box itself turning, on its rarity's colors); the ones claimed in this streak are ticked, today's is gold and pulsing over a sunburst, day 7 is the big one; a huge **CLAIM!**, then a countdown to the next. **Rewards:** day 1 Coins (5 min of income, at least 1K), day 2 1 Roll, day 3 25 Gems, day 4 Coins (20 min of income, at least 10K), day 5 a **Rare box** of your own in your front yard, day 6 3 Rolls, day 7 a **MYTHIC box** of your own in your front yard (v5.2, the user; was a new Rare+ part + 100 Gems), its card glowing pink over a sunburst. A missed day doesn't start it over (v4.4, the user: that could be farmed): the next visit gets the next day. **It happens once** (v4.4b, the user): when day 7 is claimed it's over for good (the calendar button goes away and it never pops up again; no new round). Saved as `DailyLogin = { Day, LastDay }`.

### Coming back ✅ (v4.3)
- **Offline earnings** (§16.7): the factory keeps working while you're away. On joining you get **25% of your income for the time away, up to 2 h** (nothing under 2 min: a quick rejoin). A gold **WELCOME BACK!** popup shows it: "Your factory kept working!", the time away, a big coin over a sunburst with the amount counting up, and a huge **COLLECT!** that sends the coins flying into the counter (closing it collects too; leaving without collecting banks it). It's the first join popup, before the daily calendar. Every save stamps the time and the income then (`Stats.LastSeen`, `Stats.LastIncome`).
- **Favorite prompt:** once ever, right after Tralalero's guide ends (its gift revealed), Tralalero says "Like it? Favorite the game!" and Roblox's favorite prompt opens (skipped if it's already a favorite). No reward for it: Roblox's rules forbid paying for favorites. The join popups wait for it.

### Achievements ✅ (v4.9, the user, 2026-10-07)
Long goals in **tiers** (§16.25): claiming a tier opens the next, which asks more and pays more. A **QUESTS** button on the HUD (a trophy, teal; a pulsing gold CLAIM! on it while a tier waits) opens the ACHIEVEMENTS menu: a card per achievement, in the colors of the tier it's on, like a rarity (tier 1 Common silver, 2 Uncommon green, 3 Rare blue, 4 Legendary gold, 5 Mythic pink, 6 and up the Godly rainbow), each tier dressed up more (a gloss from 2, a neon rim from 3, a sweeping sheen and twinkles from 4, more twinkles each tier, a sunburst behind the icon from 6), a star per tier and a TIER pill under its icon; its goal, a progress bar and what the tier pays. A finished tier gets a gold outline, gold rays and a pulsing **CLAIM!**; claiming it flashes, bursts into confetti and the card steps up into the next tier's colors. Ready ones come first, maxed ones last (a crown, "MAX", the rainbow). With two or more ready, a gold **CLAIM ALL (n)** over the cards claims every done tier at once (several tiers of one achievement too) in one burst and one toast with the total. A toast says when one is done ("2 achievements done!" if several), but not during Tralalero's guide or while the menu is open.
- **The list** (`Config/Achievements`): GRAND OPENING (open the Plushie room, the Clay Studio, Vinyl: ever, so a rebirth doesn't undo it), BUILDER (brainrots built, 25 to 1M), COLLECTOR (parts owned, 8 to all 60), RARITY HUNTER (claim a brainrot of each rarity, Common up to Godly), BOX HUNTER (boxes opened, 5 to 5,000), TYCOON (Coins earned, 10K to 1Qi), REBORN (rebirths, 1 to 30), PERFECTIONIST (PERFECTs, 1 to 25K), TIME FLIES (time played, 10 min to 100 h), COME BACK (days played, 2 to 100), UPGRADER (line upgrade levels bought, 5 to 1,500), LUCKY ROLLER (Rolls opened, 3 to 500), SPINNER (wheel spins, 1 to 250).
- **Rewards:** Gems from a ladder (5, 10, 20, 30, 50, 75, 100, 150, 200, 300 by tier; ×2 for rooms, rarities, rebirths and days) and/or Coins as seconds of your income (2, 5, 10, 15, 20, 30, 45, 60, 90, 120 min by tier; at least 10 Coins a second of it). Builder, Tycoon and Upgrader pay Coins; Collector, Rarity, Rebirths, Days and Rolls Gems; the rest both.
- Old saves start with what the stats already knew (Coins earned, PERFECTs, time played, rebirths, parts, claims): many tiers wait for them. Saved as `Achievements = { [id] = tiers claimed }` and lifetime `Counters` (Built, Boxes, Rolls, Spins, Upgrades, Days, Room_<zone>).

### Daily quests ✅ (v5.0, the user, 2026-10-07)
Three quests a UTC day, so there's a reason to play today (`Config/DailyMissions`): picked at random from a pool on your first moment in the game that day, the first **EASY** (green), the second **MEDIUM** (blue), the third **HARD** (purple), each counting from that moment. The pool: open boxes (4 / 8 / 15), build brainrots (3 / 7 / 15 min of what your lines build, at least 40 / 100 / 250), make PERFECTs (2 / 5 / 10 min of your full-brainrot lines, at least 5 / 15 / 40), buy line upgrades (2 / 5 / 10, +50% per line owned past the first, never more than the levels left; skipped when every line is maxed), play (10 / 20 / 40 min), earn Coins (5 / 10 / 20 min of your income then, at least 5K / 10K / 20K), spin the wheel (1). **Goals scale with the player** (v5.2, the user): measured when the day's quests are picked, so a quest takes about as long for a big factory as for a newcomer (goals rounded to two digits: 1,400, 36K); boxes, minutes and spins don't depend on the factory and stay the same. **Rewards:** EASY Coins (5 min of income, at least 2K), MEDIUM 25 Gems, HARD 1 Roll; claiming all three opens a gold bonus row: **2 Rolls**. They're the **DAILY** tab of the QUESTS menu (the other tab: ACHIEVEMENTS; each tab shows a gold count of what waits; the menu opens on DAILY while something there waits or isn't claimed): a wide row per quest with its icon, its difficulty pill, its goal, a progress bar and its reward on a white chip, a pulsing CLAIM! once done, a big tick once claimed; the bonus row with a tick per quest claimed; "NEW QUESTS IN 5h 12m". A quest done gets the toast ("DAILY QUEST done! Claim it!"). New quests replace the old at the next UTC day, claimed or not. Saved as `Missions = { Day, List = { { Id, Goal, Base, Claimed } }, Bonus }`.
- **The join popups wait for an open menu** (v5.0): the welcome back, the calendar and the Starter Pack offer never cover a menu you're using; they come once it's closed.

### Free gifts ✅ (v5.1, the user, 2026-10-07; *Pet Simulator 99*'s "Free Gifts")
**Nine gifts a UTC day** for time played (`Config/FreeGifts`), counted over the whole day (every session adds up, so leaving doesn't start them over and rejoining can't farm them): 1 min Coins (1 min of income, at least 500), 3 min 10 Gems, 5 min Coins (3 min, at least 2K), 10 min 1 Roll, 15 min 25 Gems, 20 min a 10-minute Luck boost, 30 min Coins (10 min, at least 10K), 45 min 2 Rolls, 60 min a **Rare box** of your own in your front yard. A pink **gift button** on the HUD's right column (under the calendar, or in its place once the calendar is over) wobbles over a pill with the time to the next gift, or a gold **OPEN!** while one waits; it goes away once all nine are open (until tomorrow). Its **FREE GIFTS** menu: "PLAYED TODAY: 12m" and "NEW GIFTS IN 5h", then nine cards, each a rarer color than the last (Common up to the Godly rainbow) with a bigger gift, what's inside on a white chip and its countdown; a ready one wobbles over a gold sunburst with a pulsing **OPEN!**, an opened one gets a tick. A toast says "FREE GIFT ready!" (not during the guide or with the menu open). Saved as `Gifts = { Day, Played, Claimed }` (the time played today before this session; each save adds the session in).

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
- **The brainrot is the star** ✅ (v1.7; the user: "the brainrots don't stand out, it's hard to see what the player built"). It was a speck in the machines (a 0.7× edition in the big v2 lines, fully in view for about a second) among busy, saturated rooms. Now: editions are ~1.6× bigger (Toy 1.15, Plushie 1.25, the later ones scaled to match) and the machines grew to fit; after the pop the finished brainrot steps off the pad and **shows itself off** (a spin under a spotlight, sparkles, a chime); a **name tag** (its name, or a mash-up for mixes like "Tung Tralala", and its rarest tier, ⭐ for a full match, Godly in a rainbow) rides over it until it's packed; on your own lines it gets a **cartoon outline** and a soft glow; the ride, the special and the delivery run a little longer. The brainrot art v2 will help too, but size, screen time and contrast were the main problem.
- **The lines' size** ✅ (v1.6): the belt stands on a chunky raised frame (its top 4 studs up, 10 wide, 78 long: side girders with a white stripe, glowing rails, short legs, rollers at the ends), and the machines are bigger to match (a taller gantry, punch presses and spools on pedestals, arches with legs to the floor, the delivery on a platform level with the belt). Lines fill the rooms without crowding them. (v1.7: taller still, for the bigger brainrots.)
- **The capsule and the stations beside the belt** ✅ (v1.8; the user: the machines looked lifeless, and the arches, in a jumble of colors and crammed together, buried the brainrot). The **Assembler is a glass capsule**: a ring of glass panes on a glowing base, doorways front and back where the belt runs through, a glass roof under a ring with a white stripe, a neon band and lights turning slowly round it, the zone's machines hanging from a crossbar inside. The brainrot is built and shows itself off **inside** it, in view from every side. The **upgrade stations are machines beside the belt**, on its far side from the button path, never over it: each in its room's colors (one hue family with white, gold and one neon, no rainbow), with a neon sign facing the path, and a nozzle that shoots at the brainrot just as it arrives (paint, glitter, dye, clay, glaze, gloss, gold). The line sits 10 studs further back in its room and the droppers are 8 studs apart, so the stations have room around them. Toy Workshop: the **Paint Booth** is a robot arm with a spray gun (an exhaust fan, paint cans), the **Glitter Blaster** a glitter cannon with a sparkling hopper. Plushie room: the **Dye Bath** (a glass tank of glowing dye, bubbling, piped to a spout over the belt) and the **Sequin Shower** (a disco ball on an arm). Clay Studio: the **Color Squish** (a clay extruder with a hopper of clay balls and a turning crank) and the **Sparkle Glaze** (a pot of glaze dripping from its spout arm). Vinyl: the **Gloss Coat** (a robot arm with a gloss gun) and the **Gold Leaf** (a gold roll turning, a blower). The specials still stand over the belt's end (the Toy Packer is purple and gold now, not yellow).
- **A line layout of its own per room** 🟡 (the user, 2026-10-02: "every room's lines look alike, only the sprites and animations change"; the layout, the upgrade looks and the like should differ a lot from room to room). Each room's line takes its own path and shape, with the same server timing (so payouts don't change), and its line upgrades light it up in the room's own way. The user picked:
  - **Toy Workshop:** the classic straight conveyor (as now), the baseline the others contrast with; only its upgrade looks get more toy-themed.
  - ✅ **Plushie room: an overhead rail** (v2.0). No belt: the capsule is open (no roof, a slot up its front) round a cushy drum, and the 4 knitting machines stand in an arc behind it, their arms reaching in over the glass, knitting each part straight into it. While the finished plush shows itself off, a hook (a pink trolley, a chrome cable, gold clip jaws) comes out of its garage under the ceiling; it clips the top of its head and carries it out through the slot, swinging like a pendulum, along a **3D rail** (a chunky white beam with a gold cap): up over a hump where the hook **dunks it whole into the Dye Bath, a giant paint bucket** (a splash, it's gone under, bubbles; it comes out painted in the paint's color, shining wet and dripping, and the paint turns the next color for the next one), then low past the other stations, at the belt's height so it's easy to watch: under the Sequin Shower's disco ball, then the Bow Tier's ribbon spool flings a satin bow onto its front; up over an open glass **fluff jar**, where it's lowered in and let go; the hook rolls into the garage at the rail's end (each plush gets its own hook). The rail's ride is slower than a belt's (4.6 s, was 2.4: payouts land 2.2 s later, same amounts). Upgrade looks: thick yellow neon turbo threads along the rail (the Speed upgrades); Belt Boost: the rail's glow in the tier's color, more little gold hooks along it each level, a gold thread from tier 2, sparkles, chasing lights at 10. (The user's notes, 2026-10-02: the first rail ran near the ceiling, above the camera's view, and its magenta vanished in the pink room; the plush should be dunked by the hook, not have the dye rise round it; dye behind glass looked pale or vanished; the first bow was "super ugly".)
  - **Clay Studio: a stop-motion turntable.** A big round table: the play-dough presses stand round it and the brainrot is modeled in the middle under the camera; then the table turns in stop-motion clicks (a flash each frame), carrying it round the rim past the Color Squish, the Sparkle Glaze and the Stop-Motion Camera, then into the kiln. Upgrade looks: studio lights, clay splats, a golden clapperboard.
  - ✅ **Vinyl Collectibles: a spiral tower** (v2.4). The gacha machines stand in an arc behind an open capsule and drop their capsules right into it. The finished figure gets a little gold display stand under its feet and rides it out of the capsule's front and up a glossy white ramp (gold curb, glowing pink edge) spiralling three quarters of the way round a glass display tower full of gacha capsules (some turning slowly inside), facing out as it passes: the Gloss Coat a third of the way up, the Gold Leaf two thirds; at the top it turns to face the **Holo Sticker cannon** out front, which fires a holographic star onto it in an arc; then it hops onto the lit display shelf on top, where the glass case drops over it ("MINT!") and shrinks away into the collection. The line goes vertical (the shelf is 12 up, so the figure stays under the ceiling) and changes the room's silhouette. Upgrade looks: turbo stripes up the ramp (Speed); Belt Boost: display lights on stands round the tower, the chrome curb turning gold from tier 2, holographic strips up the tower and sparkles from tier 3, chasing lights up the ramp at 10. The ride takes 5.2 s.
- **Line tablet** ✅ (v1.5): a little stand with a tablet beside each line, themed per floor (toy blocks; a thread spool). Interacting flies the camera onto the tablet and the Line menu opens right on its screen; closing it flies back.
- **Line menu:** each dropper has a slot showing the **unlocked** parts of its type. The player picks one per slot, or presses **Equip Best**. A new line auto-equips the best available parts.
- **One part, one line:** a part can be used on **only one line at a time**.
  - **Exception:** when every unlocked part of that type is already in use, a **Common** part can be reused on another line, so no line ever sits idle.
- **Speed upgrades** shorten the cycle time. **Upgrade stations** multiply the value of passing brainrots.
- **Shipping value** = sum of the part values × zone multiplier (§7) × upgrade stations × global multipliers (rebirth, gamepasses).
- **Full-match bonus:** if all 4 parts come from the same brainrot, the ship is worth **×2**: a **PERFECT**. (Until v4.1 it also completed the brainrot in the zone's edition; now brainrots are claimed in the Album, §7.)
- Line configurations are **remembered across rebirths**.
- **Finishing stage** (requested 2026-09-30): every zone ends its line with its own themed, cute last step, past the end of the belt; the payout lands as the brainrot is sent off. ✅ Toy Workshop (v1.2): a toy box pops up out of a trapdoor, flips its lid open, the brainrot jumps in, the lid slams ("PACKED!"), the box wiggles and drops back down the trapdoor. ✅ Plushie room (v1.2): the brainrot hops into a fluff machine's glass dome, fluff swirls around it until it puffs up ("FLUFFY!"), and it sinks into the cushy base. 🟡 Robot Plant: a wind-up key turns and the brainrot starts moving. Each new zone gets one.
- **Special upgrade per floor** ✅ (v1.3; replaces the "finishing upgrader" idea): the last upgrade on every line is the zone's own, standing over the end of the belt, before the delivery (×2, placeholder price 25,000 × line scale). Toy Workshop: the **Toy Packer** boxes the brainrot up in toy-store packaging (v1.6: a card back printed with a sunburst, a BRAINROT TOYS header with a hanging hole and a NEW! sticker, a name plate with the brainrot's name (a mash-up for mixes), and clear plastic over the front and sides with white glints and a shine that sweeps across) and then it goes into the toy box. Plushie room: the **Bow Tier** ties a big ribbon bow on its head before the fluff machine. v3.0: a special takes 2.6 s (was 1.3): it does its thing in the first half, then the brainrot **shows the result off** (a slow turn with a glint) before the delivery, so the player sees it (the user: the packaged toy went straight into the toy box). **Design rule:** every floor gets a themed delivery (free, cosmetic, always in the same place with the same timing and coin burst, so it reads at once) and a themed special upgrade (bought, ×value).
- **Themed droppers** (requested 2026-09-30): every zone's droppers match its theme, like its other machines. ✅ Toy Workshop (v1.1): glass chutes from the **ceiling** (§16.15): each part pops out of a collar in the ceiling, slides down the tube in plain sight (the bands bulge as it passes), and the chute squashes and stretches like rubber as its chunky nozzle spits the part onto the belt, with a puff, sparkles and a squishy boing. ✅ Plushie room (v1.6): **sock-knitting machines**: a magenta column beside the belt (violet foot with a gold ring, white cuff stripes, a thread cone on top, a crank, a neon bracelet naming the part) whose arm reaches over the belt with a round knitting head in the part's color; the needle ring whirls, the yarn ball on top spins, the crank turns, and the part is knitted down out of the head's mouth, then drops onto the belt in a puff of fluff. (The crochet robots, block-built and then a Creator Store robot, didn't fit the style.) Droppers needn't hang from the ceiling (the user). 🟡 Later zones: ideas in §16.18. **Every zone's upgrade stations are themed too** where it makes sense: the Plushie room has the **Dye Bath** (fabric dye) and the **Sequin Shower** (disco ball, sequins) instead of the Paint Booth and Glitter Blaster.
- **Room upgrades** ✅ (v1.6, the user's request; v2.1: they grow): besides the free decor (every room is lovely and complete on its own, §10), each room has themed things to buy with tycoon buttons (in `Config/RoomUpgrades`), each in levels that make **every line in the room** ship for more (×1.1 to ×2 per level). **Every level visibly grows** (the user, 2026-10-01): bigger, and more stuff, not just a recolor, gold at the top. Buying a level plays a **drop-in**: the thing vanishes and reassembles falling from above in the order it's built (a track segment by segment, a tower present by present), each piece landing with a squash and stretch, a dust puff and sparkles; a whole plot drops in the same way when it's claimed or rebuilt. Some levels need rebirths, so the early rooms keep growing after you rebirth (Cookie Clicker style); their buttons show gray with 🔒 REBIRTH N until then. They reset on rebirth like the rest of the tycoon. A floating tag by each shows its name, level and bonus (+39% room 💰).
  - Toy Workshop: **Gift Tower** (a tower of presents, a tier more each level: a little pile; balloons; a third tier on a red stage ringed with chasing lights and a giant bow on top; R2: a wider fourth tier, gold ribbons, and a golden present floating and spinning over it in a halo of lights), **Bubble Wrap Popper** (a packing bench that grows longer each level, its bubbles popping one by one, faster on a bigger bench: a roll, a sheet and a wrapped box; a stamping press and spare rolls on a wall shelf; two presses, rainbow bubbles, a glowing trim and a POP! POP! neon sign), **Box Conveyor** (a rail looping round the room near the ceiling, packages swaying on hooks: a few small presents; twice as many with starred crates among them; R1: a golden rail glowing underneath, golden presents, the most and the biggest), **Jack-in-the-Box** (at the front of the walkway between the middle and side lines, facing the entrance and the Cash Pad; R1: every few seconds the crank whirs, the lid flips and a brainrot head springs out on a coil with confetti, spilling coins onto the Cash Pad; R3: a bigger box on a gold-rimmed stage, glowing question marks, chasing lights and heaps of gold coins), **Toy Train** (R2: a train round a little round table, puffing smoke and whistling; each level the table, track and train grow, more wagons join and one carries loot: coins, then diamonds, then both; pine trees, a hill, a snowy mountain and a BRAINROT EXPRESS neon sign; R4: a golden engine, a glowing track and chasing lights).
  - Plushie room (in the plush factory's magenta, violet, gold and chrome, not nursery pastels): **Yarn Spinner** (a giant spinning wheel, bigger each level: cream yarn; magenta yarn and a chrome stand of yarn cones; rainbow yarn, chasing lights round the wheel, more cones and a neon sign; R3: a glowing golden wheel, golden thread and golden cones), **Pillow Pile** (plump satin cushions with gold tassels: a stack; two stacks on a round velvet display stand and a heap beside it; taller, chasing lights, and a golden cushion on top with a knitted Tralalero sitting on it), **Button Jar** (giant jars of sewing buttons filling up, more jars each level; R4: a huge jar brimming over, golden buttons glowing, a spill round its foot and a hanging neon sign), **Giant Plushie** (R3: a giant knitted Tung Tung Tung Sahur on a magenta cushion with gold piping; it grows each level as little plushies gather round its feet, then chasing lights; R5: crowned in gold, sparkling; it stays under the ceiling).
- **Line upgrade tracks** ✅ (v1.7, the user's request): besides the room upgrades, every line has 4 tracks of 10 levels, bought from its tablet (the Line menu's ⚡ UPGRADES tab, so the floor doesn't fill with buttons): **Dropper Power** (+5% speed per level), **Belt Boost** (+3% speed), **Super Upgraders** (+4 base Coins per brainrot, before every multiplier) and **Premium Shipping** (+5% sale value); each level costs 1.35× the last (v5.6, the economy study: Upgraders was +24 and Shipping +10%, and levels cost 1.7–1.8× the last). Each level lights the line up more: halos of lights under the droppers, glowing chevrons on the belt, bulbs and a gold star on the stations, a ring of lights round the delivery; cyan, then pink and gold, then gold with sparkles, and chasing lights at level 10. They reset on rebirth. **Buying several at once** (v4.7, the user: one level at a time was slow): pills **x1 / x5 / MAX** over the cards pick how many levels each card's button buys; the button shows the total (a gold "+5" tag when it's more than one), the levels it buys blink in the card's pips, and the card shows the value at the level it reaches. x5 buys 5 levels (or what's left) only if the Coins pay for all of them; **MAX buys as many as the Coins pay for** (at least the next one), and the cards follow the Coins while the menu is open.
- **Line upgrade cards** 🟡 (the user, 2026-10-02): the tracks stay in the tablet only (no floor buttons), and each card shows how the line will look at the next level, plus what improves.
- **Paint Booth options** 🟡: the player picks the paint color, or turns the booth off. A gamepass (§12) paints each limb a different color.
- **Photobooth** 🟡 (on every floor): saves a brainrot exactly as the player painted it, to use as a colorful statue, a photo in the factory, an in-game icon, or all of them. The photo's background matches the floor it was taken on.

---

## 7. Editions & Claiming Brainrots 🟢

Every zone builds brainrots in its own **edition**: its own size, material and texture (see §10). ✅ The Plushie edition is **knitted** (v1.7): a chunky knit texture (the `PlushKnit` MaterialVariant) tinted by each part's color. ✅ The Clay edition is **play-dough** (v1.9): matte and hand-pressed, with soft lumps, dents and fingerprints (`PlayDough`, with a normal map so the dents catch the light). ✅ The Vinyl edition is **glossy vinyl** (v1.9): saturated colors with crisp highlights (`VinylGloss`, a low roughness; Reflectance washed the colors out). The Toy edition is plain glossy plastic; the Candy edition comes with its room (e.g. a chocolate-bar look). **Editions are only a look** (v4.1, the user's new-player review): they're no longer collected, and nothing is claimed by shipping.

**Claiming** ✅ (v4.1): owning all **4 parts** of a brainrot (from Rolls, boxes, the guide's gift...) makes its sticker in the Album (§8) say **CLAIM!**; pressing it, once per brainrot:
- **Gems:** the rarity's Claim Gems (§4: 10 Common to 1,000 Godly).
- **Its themed gadget** (§3).
- **Its Morph:** the player can transform into the brainrot (the model is welded to the character and the default avatar is hidden), toggled from the Album.
- A big celebration: the brainrot over a sunburst in its rarity's color, confetti, its Gems, and MORPH / GADGET buttons to use them right away. Rare and up are announced to the server.

The HUD's ALBUM button wears a pulsing gold **CLAIM!** while a brainrot waits to be claimed (a red NEW! after a new part otherwise), and a toast says so when a part completes a set. Tralalero's guide ends on "Claim it in the ALBUM!" (the first PERFECT's brainrot). **Old saves:** whatever they had completed in any edition is claimed (and their first PERFECT counts as done).

~~**Edition jackpot**~~, ~~per-edition Gems~~ and the ~~Full Set bonus~~ idea left with the edition collection (v4.1).

---

## 8. The Album (was the Index) 🟢

✅ (v4.1, the user's new-player review: the Index was cluttered and not special) A **sticker album** in the blue-inventory style (*Pet Simulator 99*), its button on the HUD named **ALBUM**:
- **A page per rarity**, tabs across the top in the rarity's colors (Godly a turning rainbow) with how many are claimed (e.g. 1/4) and a "!" where something can be claimed; it opens on the first page with a sticker to claim. The title counts every claim (ALBUM 3/15).
- **Each page has its own scenery:** Common a sunny meadow (sky over a grass horizon, clouds drifting), Uncommon leafy green (leaves floating up), Rare the sea (bubbles rising), Legendary gold under a turning sunburst, Mythic a pink night of twinkles, Godly a turning rainbow with twinkles.
- **Stickers are big** (4 a sheet; a page with more turns its sheets with gold arrows on its sides, a "!" on an arrow when a sticker that way can be claimed, and a dot per sheet under them, v5.7; it opens on the sheet with the sticker to claim): a white die-cut card with the whole brainrot filling its face (framed to fit whatever its shape, swaying at three quarters), the parts you're missing dark, its name ("???" until you find a part), a dot per part (green with a tick once it's yours), and what's next: **x/4 PARTS**, a pulsing gold **CLAIM!** (the card rimmed in gold neon), or claimed (a tick on the corner, its morph and gadget icons).
- **A sticker opens its spread:** the big brainrot, its name, its rarity with stars, its **4 part slots** (each part turning, dark if missing, a tick or a lock) and **one button**: missing parts → how many are left and OPEN A ROLL (or a hint about map boxes); all 4 → what claiming gives (morph, gadget, Gems) and a huge **CLAIM!** over a sunburst; claimed → **MORPH / GADGET** (on and off) and **BUILD IT ON A LINE** (a button per line).

---

## 9. Currencies 🟢

| Currency | Source | Spent on | Reset on rebirth? |
|---|---|---|---|
| **Coins** | Shipping brainrots, low-tier duplicates, daily wheel | Lines, droppers, upgrades, stations, decorations | ✅ Yes |
| **Gems** (premium) | Claiming brainrots in the Album, high-tier duplicates, daily wheel, Robux packs, bosses 🟡 | Loot boosts, extra Rolls, premium boxes, cosmetics | ❌ No |
| ~~**Rebirth Points**~~ | (v4.5: gone with the Rebirth Shop; the mascot levels up by itself) | | |

We also track the **Rebirths** count (not a currency), which gates zones and rarities, and **Rolls** (an item count).

---

## 10. Rebirths & Zones 🟢

- Rebirthing requires a Coin threshold that grows each rebirth.
- **Resets:** Coins (including those waiting on the Cash Pad), purchased tycoon items. Brainrots still on the belts are dropped and don't pay out.
- **Keeps:** Gems, Rebirth Points, Rolls, unlocked parts, claimed brainrots (their morphs and gadgets), line configurations, and gamepass perks.
- **Grants:** a level of the **company mascot** (v4.5): +25% Coins, +5% line speed and +0.1 luck, forever (§4; v3.4, was rarity unlocks), and new zones.

### The company mascot ✅ (v4.5, the user, 2026-10-07; it replaces the Rebirth Shop; v4.6: a giant statue, visual pickers)
Every factory has a **mascot** out front, beside the path to the hub: a brainrot its owner **builds part by part** (head, body, arms, legs: any part they own, mixes allowed; it starts as the starter, Tralalero). **Its level is your rebirth count**: each rebirth levels it up, and each level is +25% Coins, +5% line speed and +0.1 luck, forever. It **starts small and grows into a giant statue** (v4.6, the user: like the store signs in *Retail Tycoon* that grow with each upgrade): every level makes the brainrot (1.3× at LV 0, 5× at LV 10, ~6.5× at LV 20, kept within 24 studs of its middle as it turns) and its pedestal bigger, and new looks join on the way, a new stand every few levels: a wooden crate (LV 0), a bigger crate wrapped in the factory's color (1), a marble pedestal with a neon trim (2), two spotlights with beams (3), banners on tall poles (4), a gold stand: a wide step, gold trims, sparkles (5), chasing marquee bulbs (6), a fountain with a gold rim and jets (7), two searchlights sweeping the sky (8), gold columns with neon flames and garlands behind it (9), a giant monument: three steps, its owner's name in neon on a plaque, fireworks (10), a golden crown floating over its head (12), two golden rings orbiting it (15), rainbow neon trims and bulbs (20). About 10 studs tall at LV 0, 25 at LV 5, 43 at LV 10, 53 at LV 20. It stands on a trimmed lawn (the tall grass hid its steps), and a walk of stepping stones leads to its front from an opening in the path's curb (v5.3). A **neon sign** over it says whose it is, its level and its bonuses ("+125% COINS · +25% SPEED · +50% LUCK"; at LV 0 "REBIRTH TO LEVEL ME UP!"). Its **prompt** opens its menu for anyone: the brainrot turning, LEVEL n, "Levels up every time you REBIRTH!", what it gives now and at the next rebirth, the look it gets next; its four parts on cards under it; its owner taps a part's card to pick another from big cards (every part of that kind they own, on its rarity's colors, the rarest first, like the Line menu's picker) and has a REBIRTH button. A level-up plays a fanfare round it (confetti, sparkles, a flash, "LEVEL n!"). Map boxes keep 24 studs off every mascot. The Rebirth menu's right side shows the mascot (now → after this rebirth) instead of the shop. Data: `Mascot = { Head, Body, Arms, Legs }`; Config/Mascot, Services/MascotManager, Client/UI/MascotMenu.

~~**Rebirth Shop**~~ (gone in v4.5: the mascot replaces it; levels bought there still count, shown as part of the mascot's bonuses; Rebirth Points are no longer given).
- ✅ Built (v0.5), numbers in `Config/Rebirths`:
  - Rebirth costs **100M × (rebirths + 1)³** Coins: 100M, 800M, 2.7B, 6.4B ... 100B for the 10th (v5.6, the economy study; was 60B ×3 per rebirth, v3.4, and 100B, v2.3), and gives a mascot level.
  - Shop: **Income** (+10%/lv), **Dropper Speed** (+5%/lv), **Luck** (+10%/lv: rarer tiers weigh more, boxes upgrade more often).
  - Box cap and box respawn don't fit shared boxes, so they're dropped. Walk Speed comes later.
- Line setups of lines you haven't bought back since a rebirth are remembered, but don't hold their parts, so those parts are free for your other lines.
- Each zone is a room of the factory, further back from the hub. Zone 2's room gets its free first line the moment it unlocks. ✅ Each plot is a real building: a 3-storey toy house (v1.0) with the Toy Workshop and the Plushie room on the ground floor, the Clay Studio and Vinyl Collectibles on the 2nd floor and the Candy Factory on the 3rd (built but locked until those zones exist), a glass door (🔒 REBIRTH N) into each locked room so you can peek at its theme, and outside stairs up to the 2nd floor and the terrace.

### Zones

Zones aren't only floors. The factory **physically expands**: new floors, annexes, a giant lab bolted onto the side, an underground bunker, a rooftop launchpad. Progression is **slow and gradual**: each step is a small, believable upgrade over the last, and the jumps get more absurd as things get rarer.

**The crazy building** (the user's direction, 2026-09-30): the factory grows **upward** as zones unlock, and the more it grows, the more it looks like a ramshackle, *Hello Neighbor*–style tower: floors stacked on floors, each in its own style (toy factory, sewing room, lab, bunker…), crooked add-ons bolted on, outside stairs and bridges, pipes and chimneys everywhere. Zones 1–2 are the ground floor (front room and back room); the next zones stack on top (and later sideways and underground, per the table). A late-game plot should be the craziest building on the map.
- 💡 Proposed: the next locked floor shows on top as scaffolding with a 🔒 REBIRTH N sign, so players see what they're working toward.
- Camera: the roof and the floors above never disappear (v4.1, the user: no reason for it in a tycoon like this; it was a dollhouse cutaway that faded them while the camera was above your ceiling, and the intro's flight faded the roof). The camera stays under your ceiling like in any building.
- ✅ **The building (v0.9, v1.0):** references *Pet Simulator 99* (colored brick, thick dark trims, chunky window frames, light-blue glass) and *Adopt Me!* (rounded pillars, pastel, shutters, flower boxes). Ground floor: brick in the plot's color with dark trims and a stone plinth. 2nd floor: wood siding in a lighter tint of the plot's color, with shutters. A front gable with a clock faces the hub, a second gabled roof crosses behind it, and the ramshackle bits start: a turret with a crooked cone roof, a crooked smoking chimney, pipes, and outside stairs to the 2nd floor's side door (v3.9: at the bottom they turn away from the lift tower onto a short flight out to the lawn, and a path of stepping stones with flowers and two little lamp posts curves round the tower to the front yard; v5.3: it carries on along the front and into an opening in the path's curb, so it joins the path to the hub). ✅ **The lift tower** (v3.8): an elevator tower of its own by the front corner (on the side with the outside stairs, mirroring the turret), dressed like the factory: each storey in that storey's skin (brick, siding, candy) with its trims, big windows to watch the cabin go by, a machine room on top where the pulley turns under a neon "LIFT" sign, and a crooked stepped roof with a flag like the turret's. A neon-framed "LIFT" door leads into it from every storey, and on the ground floor a hanging "LIFT" sign with a neon arrow points the way (v3.9: calm white letters, so it reads from the entrance). Its cabin (a box in the plot's deepest color with neon rims) really rides up and down, hung from the pulley with a counterweight going the other way. You never wait for it: it's always on the floor you're on (it hurries there when you change floors, and back down while you're out). Inside, two prompts, **Up** and **Down** (v3.9), each ride one floor (stacked: E the top one, F the other) with a hum and a ding.
  - v1.0: a 3rd floor (the Candy Factory) over the front half, with a terrace on the back half (water tower, chimney, garden, lollipops, bunting). **Colors:** every storey is the plot's own hue at a different strength (the user found mixed hues ugly, and near-white upper floors dead): brick, then lighter siding with bold shutters and flower boxes, then the candy floor, boldest, under white stripes, with a white frosting band full of rainbow sprinkles and drips, candy-cane pillars and a giant **spinning donut** ringed by **chasing marquee bulbs**. A rainbow **pinwheel** spins on the gable, **balloons** bob on the balcony, the terrace and the mailbox. Rainbow colors only on small things.
  - The rooms upstairs are themed inside too: patterned floors and wallpaper (Candy: pink-and-white checker, striped pink walls, mint band; Vinyl: blue checker, gold frames, stars), and props (Candy: gumball machines, cupcakes, spinning lollipops, giant candy canes, gumdrops, a chocolate vat; Clay: paint splats on the walls, pots, wheels, a sculpture).
  - ✅ **The Clay Studio is a stop-motion film studio** (v2.2; the user found the Clay and Vinyl rooms "nem perto" of the ground floor's): a glossy deep terracotta checker floor, warm orange striped walls over a dark band, teal trims; film-strip runners down the walkways under lighting trusses with spotlights on the turntables, hanging neon signs, an ON AIR sign, brainrot claymation posters (TUNG TUNG: THE MOVIE, JAWS OF TRALALERO...), two giant film reels turning on the back wall with film between them, a storyboard, shelves of miniature sets and tubs of clay, a pegboard of sculpting tools, a giant clapperboard, a movie camera on a dolly by the director's chair, a sculpting desk, a giant sculpture turning on its plinth, splats of clay on the floor. Every stop-motion frame and snap uses a real camera-shutter sound.
  - ✅ **Vinyl Collectibles is a designer-toy gallery** (v2.4): a glossy navy checker floor, royal blue striped walls over a hot-pink band, gold trims; the spiral display towers (§6); THE GRAIL (the rarest figure, a vinyl Supremo Brainrotto, turning in a gold-framed glass case behind velvet ropes), a giant gacha machine (a clear globe of capsules swirling, a gold crank, GACHA!), a wall of mystery boxes, drop and chase posters (NEW DROP!, LIMITED RUN, CHASE 1/144, SOLD OUT!), real vinyl figures on pedestals under spotlights, THE COLLECTION case, shelves of boxed figures, royal blue carpets with chasing lights, string lights, lamps and hanging neon signs.
  - ✅ The ground-floor rooms are lived in (v1.6), lovely without any upgrade: a neon sign over the door, flags round the walls, toy race tracks down the walkways with lamps and hanging neon signs over them, shelves of collectible blind boxes, wind-up robots, rockets and cars, brainrot posters, a pegboard of giant tools and a big clock, an arcade claw machine and branded shipping crates (Toy).
  - ✅ **The Plushie room is a plush factory** (v1.7; the user found the v1.6 room "still very childish, inferior to the toy room"): no more pom-poms, clouds, teddies, hearts or pastel. A glossy plum checker floor, hot-pink striped walls over a deep violet band, gold trims; chasing string lights round the walls; magenta catwalks with gold edges, white stitches and chasing floor lights down the walkways; giant thread spools hanging and turning as lamps; a rack of industrial thread cones and a rack of fabric bolts; a ROT-O-MATIC 3000 giant sewing machine; a stuffing silo with fluff tumbling inside; dress forms in knitted brainrot sweaters; a gold-framed **BEST SELLERS** case of real knitted brainrot plushies; brainrot plush ads (TRALALERO PLUSH, NEW DROP!, LIMITED!).

| # | Zone | Where | Edition (size & style) | Assembly animation | Unlock | Status |
|---|---|---|---|---|---|---|
| 1 | **Toy Workshop** | Ground floor | Toy: glossy plastic | ✅ The legs hop onto the pad, a claw lifts the body onto them, two punch presses BONK the arms in with boxing gloves (v1.7; the wooden robots looked awful), and the claw screws the head on with a spin. *Pop!* | Start | 🟢 |
| 2 | **Plushie Sewing Room** | Ground floor, back room | Plushie: knitted | ✅ The legs plop onto a cushion, the needle stitches the body down, thread spools reel the arms in, and the needle pumps the head full of stuffing. *Pop!* | Rebirth 2 | 🟢 |
| 3 | **Clay Studio** | 2nd floor | Clay: matte | ✅ (v1.7) Play-dough presses squeeze the parts out; two big white gloves mold them together while a stop-motion camera flashes at every step: the legs plop, a glove presses the body on, the gloves squish the arms in, the head jumps into place frame by frame. Special: the Stop-Motion Camera (3 poses, 3 flashes, a photo). Delivery: a brick kiln ("BAKED!") | 400K (first run) | 🟢 |
| 4 | **Vinyl Collectibles** | 2nd floor | Collectible: glossy | ✅ (v1.7) Gacha machines drop the parts in capsules that pop open on the belt; the legs clack onto a gold-ringed pad, a suction arm sets the body, two spray robots gloss the arms in, the suction arm twists the head on. Special: the Holo Sticker (a holographic LIMITED EDITION star). Delivery: a glass display case drops over it ("MINT!") | 6M (first run) | 🟢 |
| 5 | **Candy Factory** | 3rd floor | Candy: medium, gummy and translucent | Poured into a mold, blasted with sprinkles | Rebirth 9 | 🟡 |
| 6 | **Robot Plant** | Annex building | Animatronic: medium-large, metal | Robot arms weld it with sparks, and its eyes boot up | Rebirth 12 | 🟡 |
| 7 | **Mad Science Lab** | Giant lab on the side of the building | Living: life-size, wanders the lab | Crazy-scientist table: lightning bolts bring it to life | Rebirth 16 | 🟡 |
| 8 | **Secret Bunker** | Underground | Clone: life-size, glowing | Cloning vats fill with green goo while alarms flash | Rebirth 20 | 🟡 |
| 9 | **Titan Foundry** | Giant hangar | Giant: huge, forged metal | Cranes pour molten metal and sparks rain down | Rebirth 25 | 🟡 |
| 10 | **Orbital Forge** | Rooftop launchpad, then orbit | Cosmic: huge, galaxy texture | Tractor beams fuse it in space | Rebirth 30 | 🟡 |

**Decided, not built yet (the user, 2026-10-02):**
- **The first run holds every room up to the Candy Factory.** The Toy Workshop, the Plushie room, the Clay Studio and Vinyl Collectibles are all bought with Coins before the first rebirth; the Candy Factory needs Rebirth 1. Reaching the first rebirth should take **about 1 hour** (the user, 2026-10-06, for the first minutes and retention; it was ~5 h, and ~3 h before that), with many upgrades along the way. ✅ (v1.7) Rooms open with Coins at their door (v5.6: Plushie 10K, Clay 50K, Vinyl 600K; v2.3: 25K, 80M, 4B; the Candy Factory at Rebirth 1 once its floor is bought; later zones at Rebirths 2/3/4/6/8). ✅ The Clay Studio and Vinyl Collectibles are playable (v1.7). ✅ (v2.3) The economy pass: see **Economy** below. 🟡 Left: room upgrades for those two rooms. (The table's unlock column is the old plan.)
- ✅ **Floors are bought** (v1.7; v3.1: the factory starts with **1 storey**, and the 2nd comes with the Clay Studio: its button waits in front of the lift's door, downstairs, and opening it drops the 2nd floor in). The 3rd floor and up are bought from a big button on the lawn out front (the 3rd floor, the Candy Factory's: 250K placeholder, 🔒 Rebirth 1), for the sense of discovering new things. The new storey **drops in**: the old roof lifts away and the storey falls into place chunk by chunk, bottom first, then the roof lands on top ("🏗️ NEW FLOOR!"). Floors reset on rebirth like the rest of the tycoon.
- **From the Candy Factory on, assembly animations must be far superior** to the first run's rooms (the user accepts the current ones for those).
- **Rebirth will reset the whole factory but unlock many cool new upgrades per rebirth**, like minigames (e.g. a claw machine in the Toy Workshop). Rebirth work comes only after the main loop, the HUD, the bosses and the gadgets.

Rule of thumb: **the rarer the zone, the cooler the animation.** Every zone follows the Toy Workshop pattern: the brainrot is built **part by part** (Legs → Body → Arms → Head), and each part gets its own creative, funny, cute animation by machines themed after the zone. For example, the Plushie room's sewing machine stitches the arms on, and the Candy Factory pours the head from a mold.

**Economy** ✅ (v2.3, the economy pass; tuned with `tools/economy_sim.py`, a greedy buyer). A line's upgrades multiply it by ~300× (stations, speed, room upgrades, the line tracks), so small zone multipliers made every new room worthless next to the old, upgraded ones (a perfect player never opened Vinyl). Now **each room earns and costs 15× the one before** (ship value × = price × = 15^(zone − 1)): a new room's buttons pay back as fast as the first room's, and opening it is always worth it. A room's 2nd and 3rd lines cost 3× and 9× for the same output. Room openings: Plushie 25K, Clay 80M, Vinyl 4B; the first rebirth 60B. (v5.6 shrank all of this: see **the economy study** below.)
- ✅ **The pacing pass** (v3.4, the user, 2026-10-06: the first PERFECT in ~1 min, the Plushie room ~10 min, Rebirth 1 ~1 h). Part values ×4 (Common 20 ... Godly 6,000) and the Upgraders track's flat bonus with them (+24 a level); the first line's droppers cost 40/120/300 (were 80/240/600); the first rebirth 60B (was 100B). `tools/economy_sim.py` now rolls the player's parts like the game (the starter brainrot, the 3 starter Rolls, a map box a minute, every rarity) over 40 seeds: for a perfect player (median, 10th–90th percentile) the first full line (the first PERFECT) at 0.7 min, the Plushie room at 7.3 min (3–28), the Clay Studio at 14 min, Vinyl at 34 min, the rebirth at 50 min (29–65) with ~60% of the buttons bought (a real player: ~1 h). Luck now swings the run a lot (a Legendary part early is 20× a Common). The rebirth-locked room upgrades are the content after Rebirth 1. Was (v2.3, Commons and Uncommons only): the Plushie room at ~30 min, the rebirth at ~4 h with 98% of the buttons bought. The 3rd floor (Rebirth 1) costs 1B; the later zones follow the same ×15 rule until their content is built.
- ✅ **The economy study** (v5.6, the user, 2026-10-07: "inflation; the numbers grow exponentially far too fast"; the user's calls: numbers in **millions**, and **every rebirth a little longer than the last**, to enjoy the new mechanics of future rooms). `tools/economy_sim.py` now plays rebirths in a row (the mascot's Coins, speed and luck, the rebirth-gated room upgrades, the collection carried over), buys anything costing ≤ 20 s of income at once like a real player, gives the best parts to the lines that pay most and opens rooms in order. It found: a run grew ~10 million× (5 Coins/s to ~100M/s in 50 min: rooms ×15 each, a line's upgrades ×~200), and a rebirth tripled in cost while the mascot gave +25%, so the 5th took ~1.5 h, the 7th ~4 h and the 10th ~30 h (1.2 quadrillion Coins; 66 h in all); the 10th zone would have been ×38 billion. Now: **each room earns and costs 3× the one before** (3^(zone − 1): the 10th zone ×19,683); speed buttons ×1.25 (were ×1.5), stations ×1.25/×1.5/×1.5 (were ×1.5/×2/×2); the line tracks gentler and cheaper (above); a room's 2nd and 3rd lines cost 2× and 4×; room openings Plushie 10K, Clay 50K, Vinyl 600K; the 3rd floor 25M; a rebirth 100M × (n + 1)³. A run's buttons are all bought in ~40 min, then you save at your best income, so the rebirth's cost grows gently and each run takes a bit longer. Simulated (a perfect player, median): the first PERFECT at 0.7 min, Plushie 6 min, Clay 22, Vinyl 32, Rebirth 1 at 46 min (100M, ~170K Coins/s then); then runs of 44, 56, 45, 48, 56, 61, 61, 65 and 74 min, 9.3 h to Rebirth 10 (100B, ~16M Coins/s). Rewards were already seconds of income, so they follow the new scale; the TYCOON achievement asks 10K ... 100T. **Old saves** (DataManager migration 1 → 2): Coins, the lifetime Coins earned, the offline income and today's Coins quest shrink by the new rebirth cost over the old one at the player's rebirth count (1/600 at Rebirth 0), so everyone is as far toward the next rebirth as before; the TOP MONEY EARNED board starts a fresh store.

**Zone multipliers** (v5.6: 3^(zone − 1); were 15^(zone − 1))

| Zone | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Ship value × (and price ×) | 1 | 3 | 9 | 27 | 81 | 243 | 729 | 2,187 | 6,561 | 19,683 |

(Until v4.1 each zone also multiplied the completion Gems of its edition, 1 to 33, and the edition jackpot paid them all at once; editions left the collection.)

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
- **Fast Open:** skips the reveal: loot goes straight to the quick feed (a new Rare+ part still gets its card). (v3.3: the spinning reel is gone; every result opens straight onto its card.)
- ✅ **Sprint** (v2.6): hold Shift to run 60% faster (a SPRINT button on touch screens).
- ✅ (v2.6) The shop shows each pass as a glossy card in its own colors with a list of what you get, its icon bobbing, and a BEST VALUE / POPULAR ribbon on VIP and 2x Coins. The VIP lounge isn't built yet.
- ✅ **Starter Pack** (v3.3, the user): a newcomer's offer, sold only for **24 h after the first join** (a countdown on its shop card and in its corner ad; then it's gone from the game). Once: a full Bombardiro Crocodilo (Mythic), a **Legendary box** of your own in your front yard (v4.1, the user: it was Tung Tung Tung Sahur's arms; yours alone for 10 min), 250K Coins, 3 Rolls and 10 loot boxes raining round you (random rarities the player can open), all once. The big offer shows it as pictures (v4.1): the Bombardiro and the Legendary box turning on big cards over sunbursts, then Coins, boxes and Rolls on colored chips with their icons. `Services/StarterPack` (DataManager claims, so nothing is given twice). ⚠️ A Mythic full match at Rebirth 0 earns far more than the first run's Commons: it shortens the first run for buyers (that's the deal), and it's the reason to price it high.
- ✅ **Corner ads** (v3.3, the user): a small card slides in at the top right (beside 🎵/⚙️) offering a pass when it would help: Sprint when you press Shift without it, Lucky / Fast Open when loot opens, 2x Coins / Auto-Collect / VIP when you collect the Cash Pad, the Starter Pack a little after joining. One at a time, at most one every 45 s, the same pass at most every 4 min; never an owned pass or one not on the dashboard yet. `Client/UI/Upsell`.
- **Custom Paint** 🟡 (requested): paint each limb a different color at the Paint Booth (§6).

**Developer Products**
- **Gem packs** (S / M / L / XL)
- ~~Roll packs~~ (removed before the release, the user 2026-10-03)
- **Daily wheel spins** (x1, x5): **bought with Gems** (v3.3, the user; 40 / 180 💎, placeholders)
- ✅ **Coin packs** (v2.9, the user): 10 min / 1 h / 4 h / 12 h of the buyer's own income, never less than 5K / 40K / 200K / 800K, so they stay worth buying as the factory grows. Suggested 49 / 199 / 599 / 1,299 R$.
- ✅ **Box drops** (v3.3: **bought with Gems**, 50 / 225 / 400 / 900 / 3,000 💎, placeholders; the server checks and takes them, remote BuyWithGems) (v2.9, the user asked for 1/5/10/25/100, the 100 at "5000 R$ or less, by other games' prices"): see §5. Suggested 39 / 179 / 329 / 749 / **2,499** R$ (~40 down to 25 R$ a box). Why not 5,000: *Steal a Brainrot*'s dearest single item is a 2,399 R$ Secret Lucky Block (one box), its 15 min of 2x Server Luck is 249 R$, and *Pet Simulator 99*'s packs run 50–2,400 R$; a 100-box storm near 2,500 reads as the top deal, at 5,000 it would be twice the genre leader's dearest item.
- Prices are set on the Creator Dashboard; `SuggestedPrice` in `Config/Products` is the note for Go live.
- **Server Luck Boost** 💡: everyone in the server gets 2x Luck for 15 min, with a server-wide announcement of who bought it.

- ✅ **NUKE** (v2.7, a developer product, 2000 R$; the user's request): the whole server is warned (a flashing banner and a chat message: "⚠️ NAME BOUGHT A NUKE! ⚠️", an air-raid siren), a giant Bombardiro Crocodilo slowly fades in over the valley and drops a nuke on the hub; when it hits the ground every screen goes white and everyone dies (every Humanoid: players and, later, bosses), then a mushroom cloud rises. Bought again and again (a product, not a pass).

**Leaderboards** ✅ (v2.7, the user's request): four boards round the hub's fountain with the all-time top 10 for the most Robux spent, the most playtime, the most rebirths and the most money earned, and a podium with the top 3 by money earned standing on it as their own avatars, their names over their heads.

**Daily Wheel**
- 1 free spin every 24 h (rolling timer). Paid spins with Robux (and maybe Gems).
- Prizes: Coins, Gems, Rolls, temporary Luck boosts, and a small chance at a Mythic box.
- ✅ Built (`Config/DailyWheel`): Coins (2 min of income) 30%, 25 Gems 22%, 1 Roll 18%, Luck boost 15 min 12%, 100 Gems 8%, 3 Rolls 7%, **500 Gems jackpot 3%**. The jackpot replaces the Mythic box, because rarities stay locked behind rebirths. VIP gets 2 free spins a day.

**Badges** ✅ (v2.9, the user): "Welcome to the Factory!" for joining, "Finders Keepers" for the first loot box opened **on the map** (Rolls and the wheel don't count; bought drop boxes do, they're on the map). `Config/Badges` (ids from the Creator Dashboard), `Services/BadgeManager` (checks Roblox once per session).

**Compliance:** anything bought with Robux that grants random rewards (Roll packs, paid wheel spins, box drops) must **show the odds in the UI before purchase** (Roblox paid random items policy). The BOXES tab shows each box's final odds (its rarity roll and the upgrade when it's opened, combined: `Loot.DropPartOdds`). All purchases are handled server-side via `ProcessReceipt`, with receipt IDs stored to prevent double-granting.

---

## 13. Aesthetic & Juice 🟢

- **UI:** rounded corners (UICorner), thick dark outlines (UIStroke), gradients (UIGradient), drop shadows, and big icons. Buttons bounce on hover and click.
- **Feedback:** floating `+1.2K` popups (gold) over the shipping chute, a currency counter that ticks up, screen shake and a rarity-colored flash on rare pulls, and a rainbow shimmer for Godly.
- **Audio:** a click SFX on every button, machine clanks, a cash-register sound on each ship, a wheel tick, a rarity reveal stinger, and upbeat background music.
- ✅ **Core-loop juice pass (v0.7):** every assembly step has its own sound (plop, boing, servo whir, BONK, ratchet, sewing, squeak, pop), the droppers squash and spit, the Assembler's beacon flashes while it builds, the upgrade stations paint or glitter each brainrot as it passes (with its ×multiplier), coins hop from the chute to the Cash Pad, full matches get confetti and "PERFECT!". The belts scroll, bought items pop in piece by piece, the Cash Pad piles up coins and bursts (coins fly into the HUD counter) when collected, and affordable buttons get a bouncing arrow. Lighting: bloom (Neon glows), color grading, pastel haze; shuffled background music with a mute button. Ids live in `Config/Sounds`.
- **Numbers:** abbreviated (1.2K, 3.4M, 5.6B…).
- ✅ **UI juice (v2.5):** glossy highlights on every button and pill, menus whoosh and bounce up into place and pop shut, a sunburst behind reveals, a shake on Rare+ reveals; the HUD has the counters top left (icon bubbles, "+N" floating up as they rise) and the menu buttons in a grid under them with bobbing icons.
- ✅ **Clear of the Roblox chat (v3.6):** the counters and menu buttons are one left column; while the chat is open on a computer it moves down under the chat (and its input bar), shrinking to fit if it must; with the chat closed, and always on phones and consoles (their chat starts closed), it sits top left. Brainrots in menus and cards are seen at three quarters, swaying, never head-on (Tralalero head-on is a blue column). A part won shows on its whole brainrot: the part in color hopping out and back, the rest a dark see-through silhouette.
- ✅ **UI v3: the factory look, no emojis (v4.0, the user's new-player review):** every menu inherits one restyle from the Kit: each menu has its own hue family like each factory building (Lines purple, Index blue, Rebirth gold, Wheel pink, Shop green, Settings teal, Dev red; an offer takes its pass's colors), a tinted glossy panel with faint white stripes and a pulsing neon rim inside its thick dark outline, a striped header with a slow sheen, the menu's icon big and tilted over its top-left corner (bobbing), a red close button on the top-right corner, pop-in motion. **Our own icon set** replaces every emoji in the UI: ~40 glossy outlined stickers (coin, gem, dice, gift, star, lock, wheel, factory, album, rebirth arrows, cart, clover, crown, magnet, radar, shoe, mask, rocket...) drawn in Python and uploaded as images (`Config/Icons`); configs name their icon (a pass, a product, a wheel prize, a rebirth upgrade, a line upgrade track, a gadget: Shoe for movement, Hammer for melee, Rocket for launch, Music for the dance). Buttons carry an icon beside their word (prices: a coin or gem and the number), toasts are a dark pill with an icon at the top of the screen, banners show the icon and sparkle images, rarity stars are star images. Fewer words everywhere (short toasts and tips, no emoji decorations). In the world: the buy buttons' labels show the name and, under it, a gold coin with the price (or a lock with the rebirth it needs); the Cash Pad says COLLECT! over its coin and amount. The rooms' decor (posters, neon signs) keeps its emoji art.
- ✅ **Loading screen (v3.6):** our real brainrots, built by the server into ReplicatedFirst first thing: a big one in each bottom corner on a glow in its rarity's color (its stars and rarity under it) popping in a new one every 3 s, Tralalero bouncing over the title, small ones drifting up behind, turning rays; the progress bar and tips as before. v3.9: it waits until the world round you has streamed in and its textures, the menus' images and the sound effects have downloaded (25 s at most once your character is in; 60 s at most overall).
- **Assets:** toolbox models, maps and UI kits are allowed. Restyle them to fit the palette.
- ✅ **Low Performance** (v2.9, the user: never cut the decor, make it an option; v3.0: a **Lower Graphics** ON/OFF switch in the Settings menu, the gear under the music button), saved per player. On: no shadows, bloom or sun rays; the world's particles and lights off; the hub's small decor hidden (tulip fields, flowers, reeds, rocks...: MapBuilder tags it `Detail`); moving decor holds still; fewer particles in effects; builds just appear. Off (the default): everything, as designed.

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
    ProductionManager.luau      -- line config (one part, one line), production timers, shipping, PERFECTs, Line menu view
    LootManager.luau            -- shared loot boxes, Rolls, server rolls, duplicates
    RebirthManager.luau         -- rebirths
    MascotManager.luau          -- the company mascot out front
    GadgetManager.luau          -- gadgets and morphs
    MonetizationManager.luau    -- gamepasses (perks from config), dev products (ProcessReceipt)
    DailyWheelManager.luau      -- the Daily Wheel (free + bought spins, prizes)
    DevTools.luau               -- Studio only: ServerStorage.DevCommand (AddCoins, Snapshot, Restore…) for playtests
    AnalyticsManager.luau       -- Roblox Analytics: the onboarding funnel (each step once per new player) and economy events (Coins/Gems sources and sinks, summed per minute)
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
    Catalog.luau                -- the Album (claiming brainrots)
    Celebration.luau            -- the claim celebration (queued)
    RebirthMenu.luau            -- rebirth + the mascot it levels up
    MascotMenu.luau             -- the mascot's menu (its prompt)
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
    Claimed = {},   -- [brainrotId] = os.time() it was claimed in the Album
    Completed = {}, -- from before the Album (editions): only read to claim what old saves had
  },
  Tycoon = {
    Purchased = {}, -- [itemId] = true (reset on rebirth)
    Lines = {},     -- [lineId] = { Head = brainrotId, Body = ..., Arms = ..., Legs = ... } (kept on rebirth)
  },
  Stats = {
    TotalCoinsEarned = 0,
    FirstJoin = 0,
    LastJoin = 0,
    RobuxSpent = 0,
    Playtime = 0,
  },
  Achievements = {}, -- [achievementId] = tiers claimed (v4.9)
  Missions = { Day = 0, List = {}, Bonus = false }, -- today's daily quests (v5.0): { Id, Goal, Base, Claimed } each
  Gifts = { Day = 0, Played = 0, Claimed = {} },    -- today's free gifts (v5.1): seconds played before this session, gifts opened
  Counters = {},     -- lifetime counts for the achievements: Built, Boxes, Rolls, Spins, Upgrades, Days, LastDay, Room_<zoneId>
  Settings = {
    LowGraphics = false, -- the player's own (v2.9), set through the SetSetting remote
  },
}
```

---

## 16. Proposed Ideas 💡

1. ~~**Full Set bonus**~~ (dropped with the edition collection, v4.1).
2. **Hybrid brainrots:** mixed-part ships get mashup names ("Tung Tralala": ✅ v1.7, on the name tag and the packaging) and a funny "Hybrid" popup. A Hybrid Index could come later.
3. ⏸️ **Showcase multiplier (on hold):** completed brainrots stand on pedestals in your tycoon, and each one adds +X% income. Kept on the table, not planned.
4. **Gold / Rainbow part variants:** a rare roll on the wheel upgrades a part to Gold or Rainbow for bonus value and flex. No new models needed.
5. **Index milestones:** completing X brainrots of a rarity grants permanent buffs (the Pet Sim index loop).
6. **Loot Rain event:** every ~15 min, the map floods with shared boxes for 60 s.
7. ✅ **Offline earnings** (v4.3, §5 "Coming back"): 25% of income while away, up to 2 h, with a "Welcome back!" popup. Later: a longer cap or a bigger share as a Rebirth/mascot level, or a "×2 for Robux" button on the popup.
8. **Weekly brainrot drops:** new brainrots in updates: new stickers to claim bring veterans back.
9. **Morph edition:** your morph uses the style of your best completed edition (a Candy Sahur, a Cosmic Sahur…).
10. **Codes, group rewards, like goals, global leaderboards.** A cheap launch-growth toolkit.
11. **Original Godly brainrot:** our own signature character, for brand identity and thumbnails.
12. ✅ **Remote line config as a gamepass perk:** decided and built, bundled with Auto-Collect (§12).
13. **Control Room computer:** a computer on a higher floor that configures every line in the whole facility from one place.
14. **The facility grows up and out:** each expansion adds floors and side wings, and the whole place looks more and more like a dreamy science factory.
15. ✅ **Toy Workshop chutes:** parts slide out of chutes onto the belt instead of dropping from boxes. Decided: part of the themed droppers (§6).
16. **Per-rarity box effects:** unique looks, particles, spawn and open animations per rarity. Godly boxes arrive through a black hole (§5).
17. **Signature idle touches:** finished brainrots get a small idle animation or prop from their meme, like *Steal a Brainrot* does: Lirilì's floating clock, Tung tapping his bat, Tralalero's tail wag, Trippi's antennae wobble.
18. **Themed droppers for the next zones** (§6), to pick from: *Plushie room:* a big sewing basket on a shelf that tosses each part in an arc, or a fluffy pillow that squishes and poofs the part out in a burst of feathers. *Clay Studio:* a play-dough press that squeezes a blob out, which pops into the part. *Vinyl Collectibles:* gacha capsules rolling out of a vending machine and popping open. *Candy Factory:* a gumball machine that drops each part as a gumball that cracks open.
19. **Golden (shiny) parts** (the user, 2026-10-01): a general Rebirth Shop upgrade gives every room a chance to make **golden parts**, and rebirth-locked room upgrades raise the golden chance for the whole factory. In the Index (sticker book, §8) a golden part is stuck **over** the standard one, like a "shiny", which leaves room for more shiny tiers later (e.g. rainbow, diamond), maybe even shinies that pay out Gems.
20. ⏸️ **A 4th line per room** (parked by the user, 2026-10-01): it doesn't fit nicely in a 140-wide room with the bigger lines and the wall upgrades. Think about it later: bigger floors further up, or other kinds of droppers in some corners of a room.

21. **The Candy Factory** (the user's idea, refined together, 2026-10-02; the user liked this version). The first room where brainrots have a use, and where the line itself grows stage by stage:
    - **Chocolate Block dropper** (free): a block of chocolate rides the belt and sells as it is.
    - **Melting Pot** (a giant oven): the blocks melt; the melt splits into 4 pipes.
    - **4 Part Molds** (they replace the droppers, bought one by one): each pipe fills a mold shaped like the equipped part (Head, Body, Arms, Legs), so the parts you collected shape the molds. The Assembler sticks them together with warm chocolate: a **chocolate brainrot** (brown, one color).
    - Stations, then the **Magic Oven** (special 1): bakes it into the real brainrot, full color, in the gummy Candy edition (a big "wow" transformation).
    - **The Enchanter** (special 2): ×value, a giant candy wrapper, and a **chance** (or every PERFECT) of a **Giant Candy** on a pedestal. You carry it as a tool (others see it) and eat it for a timed buff through the existing Boosts: rarity sets strength and duration (Common: +10% speed for 2 min ... Godly: ×2 income for 5 min), a full match adds a bonus; you hold at most ~3. Later: themed buffs per brainrot (Tralalero: speed, Sahur: the bat).
    - Economy: the plain block already sells for more than a Vinyl brainrot, so money never drops when you enter the room. The chocolate stages (melting, pouring, molds filling) suit the far better animations the user wants from this room on.
22. **Rebirth unlocks** (the user, 2026-10-02; after the main loop, the HUD, the bosses and the gadgets): each rebirth unlocks cool new upgrades for the rooms you already have, like minigames (a playable claw machine in the Toy Workshop).
23. **A new verb per room** (proposed 2026-10-02; the user worried every room is the same loop, droppers into an Assembler, at least until the first rebirth). Classic dropper tycoons repeat their loop floor after floor, and ours already varies the machines and animations per room, but what the player *does* stays the same. Each room could add one small mechanic of its own: *Plushie room:* an **orders board** (a customer wants, say, a Tralalero head on any body, for a big bonus), so the tablet's choices matter. *Clay Studio:* **customizing** (the Paint Booth options and the Photobooth, §6). *Vinyl:* **limited editions** (a chance of a holo or gold variant to collect in the Index). *Candy Factory:* the chocolate line (21). To decide.
24. 🟡 (Moranguete, Abacatudo and "67" are in the roster's waves 2-3, §3) **New brainrots** (the user, 2026-10-02): **Moranguete** (a strawberry) and **Abacatudo** (an avocado), from the viral AI fruit soap operas: simple names foreign players can say too. Commons, to fill out the roster and push the coolest brainrots a few tiers up. Also the **"67"** meme, as a **Legendary**. Design our own look for each (never copy the videos' renders, the song or the real people), and prefer names that are generic wordplay. The main players are foreign, so no Portuguese-only names.

25. ✅ (v4.9, §5 "Achievements": tiers in rarity colors; no Roblox badges yet) **Achievements** (the user, 2026-10-02: before the release): an in-game list (first brainrot built, first full match, N completions, a brainrot of each rarity, every room opened, the first rebirth, boxes opened, bosses beaten...) with Gem and Roll rewards, a popup when one is earned, a page in the UI, and Roblox badges for the big ones.

26. ✅ (v4.5, §10 "The company mascot": it levels up by itself, 1 level per rebirth; built part by part) **The company mascot** (the user, 2026-10-06): a way to show off your favorite creation, like a company's mascot, in front of your factory where everyone walks past. It starts small (a sign with your mascot's name and a little figure on it) and grows into a statue: **Rebirth Points level it up** (each level bigger and more eye-catching: a sign, a figure on a crate, a stone pedestal, a spotlight, then gold, fountains and fireworks at the top), and each level gives **+Coins**; later levels add **luck** and **line speed** too. You build the mascot right there (pick any unlocked part for each slot, mixes allowed) or copy one of your lines. It **replaces the Rebirth Shop** (Income, Dropper Speed, Luck): the points already spent there are refunded. Proposal, to confirm when built: the stand appears with your first PERFECT (Tralalero's guide shows it), so every new player has one.

---

## 17. Open Questions

1. **Zone list and pacing (§10):** does the 10-zone progression feel right? Names, order and rebirth requirements are all easy to change in `Config/Zones`.
2. ~~Loot boxes: personal or shared?~~ Shared (v0.4, §5).
4. ~~Remote line config: free or gamepass?~~ Gamepass, bundled with Auto-Collect (§12).
3. **Rebirth:** keep unlocked parts, claimed brainrots and line configurations through rebirths (§10). OK?

---

The changelog lives in [docs/changelog.md](docs/changelog.md).
