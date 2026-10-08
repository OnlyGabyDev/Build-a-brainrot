"""Economy simulator: the first run, then rebirths in a row (docs/history.md: the economy
pass, the pacing pass, the economy study).

A greedy player buys whatever button pays back best (income gained per Coin, a little
less if it has to wait for it), buys at once anything costing a few seconds of income
(as real players do), and stops buying once saving for the rebirth is quicker than
anything left would pay back. A room or line is worth what its first line's buttons
pay; the best parts go to the lines that pay most for a brainrot. It follows Config/TycoonItems, Zones,
LineUpgrades, RoomUpgrades and ProductionManager.getLineStats/evaluate/pickBest; the
numbers below are copied from those configs (keep them in step when tuning).

The player's parts are rolled like the game does (Config/Loot, Rarities, Brainrots):
the starter brainrot, the 3 starter Rolls, then a map box every `box_every` seconds;
every rarity can drop (no rarity cap since 2026-10-06). Each line gets the best legal
setup (one part, one line; a Common may be reused once a type runs out), the best
parts on the richest lines. Luck varies a lot, so it runs many seeds.

Each rebirth after the first keeps the collection, levels the mascot (more Coins, speed
and luck) and unlocks the rebirth-gated room upgrades.

Assumptions (a box a minute, a perfect player: no walking or menus) are rough. Real
players take ~1.2x longer.

    python tools/economy_sim.py        # one run's timeline, the spread over seeds, 10 rebirths
"""
import math, random, statistics

PART_TYPES = ("Head", "Body", "Arms", "Legs")

BASE = dict(
    zones=[  # id, unlock price, value mult, price mult (Config/Zones)
        ["ToyWorkshop", 0, 1, 1],
        ["PlushieRoom", 10_000, 3, 3],
        ["ClayStudio", 50_000, 9, 9],
        ["VinylCollectibles", 600_000, 27, 27],
    ],
    line_unlock=[0, 5000, 60000],  # Config/TycoonItems
    line_scale=[1, 2, 4],
    items=[
        ("Head", "Dropper", 0, None), ("Body", "Dropper", 40, None), ("Arms", "Dropper", 120, None),
        ("Legs", "Dropper", 300, None), ("Speed1", "Speed", 1400, 1.25), ("Station1", "Station", 3000, 1.25),
        ("Speed2", "Speed", 8000, 1.25), ("Station2", "Station", 18000, 1.5), ("Station3", "Station", 50000, 1.5),
    ],
    tracks=[  # Config/LineUpgrades
        ("Droppers", "Speed", 0.05, 600, 1.35, 10, "Legs"),
        ("Belt", "Speed", 0.03, 500, 1.35, 10, "Speed1"),
        ("Upgraders", "Flat", 4, 800, 1.35, 10, "Station1"),
        ("Shipping", "Percent", 0.05, 1000, 1.35, 10, "Legs"),
    ],
    # (the Clay and Vinyl room upgrades aren't built: docs/history.md has their prices)
    room_upgrades=[  # Config/RoomUpgrades: (price, multiplier, rebirths needed)
        ("ToyWorkshop", "GiftTower", [(1000, 1.1, 0), (8000, 1.1, 0), (40000, 1.15, 0), (400000, 1.5, 2)]),
        ("ToyWorkshop", "BubbleWrap", [(3000, 1.1, 0), (20000, 1.15, 0), (100000, 1.2, 0)]),
        ("ToyWorkshop", "BoxConveyor", [(16000, 1.15, 0), (70000, 1.2, 0), (180000, 1.5, 1)]),
        ("ToyWorkshop", "JackBox", [(80000, 1.5, 1), (1600000, 2, 3)]),
        ("ToyWorkshop", "ToyTrain", [(300000, 1.3, 2), (1200000, 1.3, 2), (3000000, 1.35, 3), (6000000, 1.35, 4)]),
        ("PlushieRoom", "YarnSpinner", [(4000, 1.1, 0), (24000, 1.15, 0), (120000, 1.2, 0), (600000, 1.5, 3)]),
        ("PlushieRoom", "PillowPile", [(1600, 1.1, 0), (12000, 1.1, 0), (60000, 1.15, 0)]),
        ("PlushieRoom", "ButtonJar", [(8000, 1.1, 0), (50000, 1.15, 0), (800000, 1.5, 4)]),
        ("PlushieRoom", "GiantPlushie", [(300000, 1.3, 3), (1000000, 1.3, 3), (2400000, 1.35, 4), (5000000, 1.35, 5)]),
    ],
    rebirth_cost=100_000_000,  # Config/Rebirths: BaseCost x (rebirths + 1)^CostPower
    rebirth_power=3,
    rebirth_income=0.25, rebirth_speed=0.05, rebirth_luck=0.1,  # per rebirth (the mascot's level)
    luck_per_rank=0.25, box_luck=0.5,  # Config/Loot
    base_cycle=4.0,  # Config/Production
    match_mult=2,  # Config/Production.FullMatchMultiplier
    rarities=[  # id, loot weight, part value, duplicate Coins (0: Gems) (Config/Rarities)
        ("Common", 65, 20, 100), ("Uncommon", 26, 48, 250), ("Rare", 6.5, 120, 600),
        ("Legendary", 2, 400, 0), ("Mythic", 0.4, 1400, 0), ("Godly", 0.06, 6000, 0),
    ],
    brainrots=dict(Common=8, Uncommon=6, Rare=5, Legendary=3, Mythic=3, Godly=1),  # Config/Brainrots
    starter="Common",  # Brainrots.StarterId's rarity: its 4 parts from the start
    starter_rolls=3,  # DataManager STARTER_ROLLS
    sure_new=dict(Roll=3, Box=1),  # Config/Loot.SureNew
    box_upgrade=0.08,  # Config/Loot.BoxUpgradeChance (no luck before the first rebirth)
    dup_income_seconds=dict(Common=15, Uncommon=30, Rare=60),  # Config/Loot.DuplicateIncomeSeconds
    # map loot boxes the player opens: one every `box_every` s from `box_from`
    box_from=60, box_every=60,
    patience=900,  # seconds of waiting that halve a button's appeal
    impulse=20,  # any button costing at most this many seconds of income is bought at once
)


def round2(price):
    if price <= 0:
        return 0
    unit = 10 ** max(math.floor(math.log10(price)) - 1, 0)
    return math.floor(price / unit + 0.5) * unit


class Collection:
    """The player's parts, rolled like LootManager does."""

    def __init__(self, c, rng):
        self.c, self.rng = c, rng
        self.rarities = c["rarities"]
        self.value = {r[0]: r[2] for r in self.rarities}
        self.dup = {r[0]: r[3] for r in self.rarities}
        self.brainrots = [(f"{rid}{i}", rid) for rid, n in c["brainrots"].items() for i in range(n)]
        starter = next(b for b, rid in self.brainrots if rid == c["starter"])
        self.owned = {(starter, t) for t in PART_TYPES}
        self.used = dict(Roll=0, Box=0)
        self.version = 0
        self.next_time = c["box_from"]
        self.luck = 0.0  # the mascot's (rebirths): rarer tiers weigh more, boxes upgrade more often

    def roll_rarity(self, box=False):
        weights = [r[1] * (1 + self.luck * self.c["luck_per_rank"] * i) for i, r in enumerate(self.rarities)]
        rank = self.rng.choices(range(len(weights)), weights)[0]
        if box:  # a box mostly gives its own rarity, each tier above box_upgrade as likely
            up = self.c["box_upgrade"] * (1 + self.luck * self.c["box_luck"])
            ups = [up ** k for k in range(len(weights) - rank)]
            rank += self.rng.choices(range(len(ups)), ups)[0]
        return self.rarities[rank][0]

    def open(self, kind, income):
        """Opens a Roll or a box: Coins from a duplicate (0 for a new part or Gems)."""
        rarity = self.roll_rarity(kind == "Box")
        pool = [b for b, rid in self.brainrots if rid == rarity]
        part = (self.rng.choice(pool), self.rng.choice(PART_TYPES))
        self.used[kind] += 1
        if self.used[kind] <= self.c["sure_new"][kind]:
            types = PART_TYPES if kind == "Roll" else (part[1],)
            fresh = [(b, t) for b in pool for t in types if (b, t) not in self.owned]
            if fresh:
                part = self.rng.choice(fresh)
        if part in self.owned:
            return self.dup[rarity] + self.c["dup_income_seconds"].get(rarity, 0) * income
        self.owned.add(part)
        self.version += 1
        return 0

    def setups(self, count):
        """The best legal setup for each of `count` lines, richest first: per line a
        {partType: value} and whether it's a full match (ProductionManager.pickBest)."""
        rarity_of = dict(self.brainrots)
        used = set()
        out = []
        for _ in range(count):
            mixed, ids = {}, {}
            for t in PART_TYPES:
                best = None
                for b, pt in self.owned:
                    if pt == t and (b, t) not in used and (best is None or self.value[rarity_of[b]] > self.value[rarity_of[best]]):
                        best = b
                if best is None:  # every part of this type is in use: a Common may be reused
                    commons = [b for b, pt in self.owned if pt == t and rarity_of[b] == "Common"]
                    if commons:
                        mixed[t], ids[t] = self.value["Common"], None
                    continue
                mixed[t], ids[t] = self.value[rarity_of[best]], best
            full = None
            for b, rid in self.brainrots:
                if all((b, t) in self.owned and (b, t) not in used for t in PART_TYPES):
                    if full is None or self.value[rid] > self.value[rarity_of[full]]:
                        full = b
            match_ids = set(i for i in ids.values() if i)
            is_match = len(ids) == 4 and len(match_ids) == 1 and None not in ids.values()
            if full and not is_match and 4 * self.value[rarity_of[full]] * self.c["match_mult"] > sum(mixed.values()):
                setup, is_match = {t: self.value[rarity_of[full]] for t in PART_TYPES}, True
                used.update((full, t) for t in PART_TYPES)
            else:
                setup = mixed
                used.update((b, t) for t, b in ids.items() if b)
            out.append((setup, is_match))
        return out


class Line:
    def __init__(self, zone, index):
        self.zone, self.index = zone, index
        self.open = False
        self.drops = 0
        self.speed = 1.0
        self.stations = 1.0
        self.tracks = {}


class Sim:
    """One run, from a reset factory to the next rebirth, `rebirths` rebirths in. The
    collection carries over from the run before (pass it in)."""

    def __init__(self, c, seed=0, rebirths=0, col=None):
        self.c = c
        self.rebirths = rebirths
        self.col = col or Collection(c, random.Random(seed))
        self.col.luck = c["rebirth_luck"] * rebirths
        self.col.next_time = c["box_from"]
        self.income_mult = 1 + c["rebirth_income"] * rebirths
        self.speed_mult = 1 + c["rebirth_speed"] * rebirths
        self.zone = {z[0]: z for z in c["zones"]}
        self.items = []
        self.byid = {}
        self.lines = {}
        prev_room = None
        for zid, zprice, zval, zpm in c["zones"]:
            if zprice:  # rooms open in order (Vinyl is on the 2nd floor, which comes with the Clay Studio)
                self.add(dict(id=f"{zid}_Room", zone=zid, kind="Room", price=zprice, req=prev_room))
                prev_room = f"{zid}_Room"
            for li in range(3):
                lid = f"{zid}_{li+1}"
                self.lines[lid] = Line(zid, li)
                self.add(dict(id=f"{lid}_Line", zone=zid, line=lid, kind="Line", price=round2(c["line_unlock"][li] * zpm),
                              req=f"{zid}_{li}_Legs" if li else None))
                prev = f"{lid}_Line"
                for key, kind, price, mult in c["items"]:
                    self.add(dict(id=f"{lid}_{key}", zone=zid, line=lid, kind=kind, key=key,
                                  price=round2(price * c["line_scale"][li] * zpm), mult=mult, req=prev))
                    prev = f"{lid}_{key}"
                for key, eff, step, base, growth, levels, gate in c["tracks"]:
                    prev = f"{lid}_{gate}"
                    for lv in range(1, levels + 1):
                        iid = f"{lid}_Up{key}_{lv}"
                        self.add(dict(id=iid, zone=zid, line=lid, kind="Track", key=key, eff=eff, step=step,
                                      price=round2(round2(base * growth ** (lv - 1)) * c["line_scale"][li] * zpm), req=prev))
                        prev = iid
        for zid, key, levels in c["room_upgrades"]:
            zpm = self.zone[zid][3]
            prev = None
            for lv, (price, mult, need) in enumerate(levels, 1):
                if need > rebirths:
                    break
                iid = f"{zid}_Decor_{key}_{lv}"
                self.add(dict(id=iid, zone=zid, kind="Decor", price=round2(price * zpm), mult=mult, req=prev))
                prev = iid
        self.decor = {z: 1.0 for z in self.zone}
        self.owned = set()
        self.cache = {}

    def add(self, it):
        self.items.append(it)
        self.byid[it["id"]] = it

    REFERENCE = ({t: 20 for t in PART_TYPES}, True)  # a full Common brainrot, to rank the lines

    def assign(self, open_ids, extra=None):
        """Setups for the open lines: the lines that pay most for a brainrot (their room
        and upgrades) get the best parts. `extra`: (line id, items it would get)."""
        worth = {lid: self.line_income(self.lines[lid], self.REFERENCE, extra[1] if extra and extra[0] == lid else None)
                 for lid in open_ids}
        order = tuple(sorted(open_ids, key=lambda lid: (-worth[lid], self.lines[lid].index)))
        key = (self.col.version, order)
        if key not in self.cache:
            self.cache[key] = dict(zip(order, self.col.setups(len(order))))
        return self.cache[key]

    def line_income(self, line, setup, extra=None):
        drops, speed, stations, tracks, decor = line.drops, line.speed, line.stations, dict(line.tracks), self.decor[line.zone]
        for it in extra or ():
            k = it["kind"]
            if k == "Dropper":
                drops += 1
            elif k == "Speed":
                speed *= it["mult"]
            elif k == "Station":
                stations *= it["mult"]
            elif k == "Track":
                tracks[it["key"]] = tracks.get(it["key"], 0) + 1
            elif k == "Decor":
                decor *= it["mult"]
        parts, is_match = setup
        value = sum(parts.get(t, 0) for t in PART_TYPES[:drops])  # droppers are bought Head first
        if value == 0:
            return 0.0
        cycle = self.c["base_cycle"] / speed / self.speed_mult
        mult = stations * decor * self.zone[line.zone][2] * self.income_mult
        for key, eff, step, *_ in self.c["tracks"]:
            l = tracks.get(key, 0)
            if eff == "Speed":
                cycle /= 1 + step * l
            elif eff == "Percent":
                mult *= 1 + step * l
            else:
                value += step * l
        if drops == 4 and is_match:
            value *= self.c["match_mult"]
        return value * mult / cycle

    def open_ids(self):
        return tuple(lid for lid, l in self.lines.items() if l.open)

    def income(self):
        setups = self.assign(self.open_ids())
        return sum(self.line_income(self.lines[lid], s) for lid, s in setups.items())

    def apply(self, it):
        self.owned.add(it["id"])
        k = it["kind"]
        if k == "Decor":
            self.decor[it["zone"]] *= it["mult"]
            return
        if k == "Room":
            return
        line = self.lines[it["line"]]
        if k == "Line":
            line.open = True
        elif k == "Dropper":
            line.drops += 1
        elif k == "Speed":
            line.speed *= it["mult"]
        elif k == "Station":
            line.stations *= it["mult"]
        elif k == "Track":
            line.tracks[it["key"]] = line.tracks.get(it["key"], 0) + 1

    def zone_open(self, zid):
        return self.zone[zid][1] == 0 or f"{zid}_Room" in self.owned

    def visible(self):
        out = []
        for it in self.items:
            if it["id"] in self.owned:
                continue
            if it["kind"] != "Room" and not self.zone_open(it["zone"]):
                continue
            if it["req"] and it["req"] not in self.owned:
                continue
            out.append(it)
        return out

    def grant_free(self):
        changed = True
        while changed:
            changed = False
            for it in self.visible():
                if it["price"] == 0:
                    self.apply(it)
                    changed = True

    def gain(self, it, now):
        """Income gain of buying `it`. A room or line counts with its first line's droppers
        and as many of the next buttons as pay back best (opening it is worth what it leads
        to, not only its first brainrot)."""
        k = it["kind"]
        if k == "Room" or k == "Line":
            lid = it.get("line") or f"{it['zone']}_1"
            fee = it["price"] + (self.byid[f"{lid}_Line"]["price"] if k == "Room" else 0)
            chain = [self.byid[f"{lid}_{key}"] for key, *_ in self.c["items"]]
            best = None
            for n in range(4, len(chain) + 1):
                bundle = chain[:n]
                setups = self.assign(self.open_ids() + (lid,), (lid, bundle))
                total = sum(self.line_income(self.lines[l], s, bundle if l == lid else None) for l, s in setups.items())
                g, p = total - now, fee + sum(b["price"] for b in bundle)
                if best is None or g * best[1] > best[0] * p:
                    best = (g, p)
            return best
        setups = self.assign(self.open_ids())
        if k == "Decor":
            g = sum(self.line_income(self.lines[l], s, [it]) - self.line_income(self.lines[l], s)
                    for l, s in setups.items() if self.lines[l].zone == it["zone"])
            return g, it["price"]
        line = self.lines[it["line"]]
        s = setups[it["line"]]
        return self.line_income(line, s, [it]) - self.line_income(line, s), it["price"]

    def run(self, rebirth_cost, log=False, horizon=30 * 3600):
        c = self.c
        self.grant_free()
        coins, t = 0.0, 0.0
        for _ in range(c["starter_rolls"] if self.rebirths == 0 else 0):
            coins += self.col.open("Roll", 0)
        marks, trace = {}, []
        while t < horizon and coins < rebirth_cost:
            inc = self.income()
            best, best_score, bg, bp = None, -1, 0, 0
            visible = self.visible()
            cheap = [it for it in visible if 0 < it["price"] <= c["impulse"] * inc]
            for it in [min(cheap, key=lambda it: it["price"])] if cheap else visible:
                g, p = self.gain(it, inc)
                if cheap:  # a real player buys any button this cheap, whatever it pays
                    best, bg, bp = it, max(g, 1e-9), p
                    break
                if g <= 0 or p <= 0:
                    continue
                wait = max(0, (p - coins) / max(inc, 1e-9))
                score = g / p / (1 + wait / c["patience"])
                if score > best_score:
                    best, best_score, bg, bp = it, score, g, p
            if best is not None and not cheap and bp / bg > (rebirth_cost - coins) / max(inc, 1e-9):
                best = None  # saving up for the rebirth is quicker
            target = best["price"] if best else rebirth_cost
            while coins < target:  # earn, opening a box a minute on the way
                dt = (target - coins) / max(inc, 1e-9)
                if self.col.next_time < t + dt:
                    coins += inc * (self.col.next_time - t)
                    t = self.col.next_time
                    coins += self.col.open("Box", inc)
                    self.col.next_time += c["box_every"]
                    inc = self.income()
                else:
                    coins, t = target, t + dt
            if not best:
                break
            coins -= best["price"]
            self.apply(best)
            self.grant_free()
            if best["kind"] == "Dropper" and self.lines[best["line"]].drops == 4 and "line1" not in marks:
                marks["line1"] = t  # the first full line: the starter brainrot's first PERFECT
            if best["kind"] == "Room":
                marks[best["zone"]] = t
            if log and best["kind"] in ("Room", "Line"):
                what = f"open {best['zone']}" if best["kind"] == "Room" else best["id"]
                trace.append(f"{t/60:6.1f} min {what:<24} {best['price']:>14,.0f}  income {self.income():>12,.0f}/s")
        marks["rebirth"] = t
        return dict(t=t, share=len(self.owned) / len(self.items), marks=marks, income=self.income(), trace=trace,
                    parts=len(self.col.owned))


def rebirth_cost(c, rebirths):
    return c["rebirth_cost"] * (rebirths + 1) ** c["rebirth_power"]


def campaign(c, seed, runs):
    """`runs` rebirths in a row with one collection: each run's result."""
    col = Collection(c, random.Random(seed))
    return [Sim(c, rebirths=n, col=col).run(rebirth_cost(c, n)) for n in range(runs)]


def main(seeds=40, runs=10):
    r = Sim(BASE).run(BASE["rebirth_cost"], log=True)
    print("\n".join(r["trace"]))
    print(f"rebirth ({BASE['rebirth_cost']:,.0f} Coins) at {r['t'] / 3600:.2f} h with {r['share'] * 100:.0f}% of the buttons "
          f"bought and {r['parts']} of {sum(BASE['brainrots'].values()) * 4} parts; income then {r['income']:,.0f}/s\n")
    runs1 = [Sim(BASE, seed).run(BASE["rebirth_cost"])["marks"] for seed in range(seeds)]
    print(f"over {seeds} seeds (minutes: 10th percentile / median / 90th):")
    for key in ("line1", "PlushieRoom", "ClayStudio", "VinylCollectibles", "rebirth"):
        values = sorted(m.get(key, math.inf) / 60 for m in runs1)
        q = statistics.quantiles(values, n=10)
        print(f"  {key:<18} {q[0]:7.1f} {statistics.median(values):7.1f} {q[-1]:7.1f}")
    camps = [campaign(BASE, seed, runs) for seed in range(seeds // 4)]
    print(f"\nrebirths in a row over {len(camps)} seeds (medians; a run past 30 h stops):")
    print("  run  cost              minutes  total h  bought  parts  income at the end")
    total = [0.0] * len(camps)
    for n in range(runs):
        for i, camp in enumerate(camps):
            total[i] += camp[n]["t"]
        med = lambda key: statistics.median(camp[n][key] for camp in camps)
        print(f"  {n}->{n+1:<2} {rebirth_cost(BASE, n):>16,.0f} {med('t') / 60:8.1f} {statistics.median(total) / 3600:8.1f}"
              f" {med('share') * 100:6.0f}% {med('parts'):6.0f}  {med('income'):,.0f}/s")


if __name__ == "__main__":
    main()
