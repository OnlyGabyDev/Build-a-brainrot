"""Economy simulator for the Rebirth 0 -> 1 run (the economy pass, docs/history.md).

A greedy player buys whatever button pays back best (income gained per Coin, a little
less if it has to wait for it), and stops buying once saving for the rebirth is
quicker than anything left would pay back. It follows Config/TycoonItems, Zones,
LineUpgrades, RoomUpgrades and ProductionManager.getLineStats/evaluate; the numbers
below are copied from those configs (keep them in step when tuning).

Assumptions (the player's parts, loot box duplicates) are rough: a perfect player,
no walking or menus. Real players take ~1.2x longer.

    python tools/economy_sim.py        # the timeline to the first rebirth
"""
import math, copy

BASE = dict(
    zones=[  # id, unlock price, value mult, price mult (Config/Zones)
        ["ToyWorkshop", 0, 1, 1],
        ["PlushieRoom", 25_000, 15, 15],
        ["ClayStudio", 80_000_000, 225, 225],
        ["VinylCollectibles", 4_000_000_000, 3375, 3375],
    ],
    line_unlock=[0, 5000, 60000],  # Config/TycoonItems
    line_scale=[1, 3, 9],
    items=[
        ("Head", "Dropper", 0, None), ("Body", "Dropper", 80, None), ("Arms", "Dropper", 240, None),
        ("Legs", "Dropper", 600, None), ("Speed1", "Speed", 1400, 1.5), ("Station1", "Station", 3000, 1.5),
        ("Speed2", "Speed", 8000, 1.5), ("Station2", "Station", 18000, 2), ("Station3", "Station", 50000, 2),
    ],
    tracks=[  # Config/LineUpgrades
        ("Droppers", "Speed", 0.05, 600, 1.75, 10, "Legs"),
        ("Belt", "Speed", 0.03, 500, 1.7, 10, "Speed1"),
        ("Upgraders", "Flat", 6, 800, 1.75, 10, "Station1"),
        ("Shipping", "Percent", 0.1, 1000, 1.8, 10, "Legs"),
    ],
    # (the Clay and Vinyl room upgrades aren't built: without them the first rebirth takes
    # 4.1 h instead of 4.0, so they were left out of the release; docs/history.md has their prices)
    room_upgrades=[  # Config/RoomUpgrades, the levels needing no rebirth
        ("ToyWorkshop", "GiftTower", [(1000, 1.1), (8000, 1.1), (40000, 1.15)]),
        ("ToyWorkshop", "BubbleWrap", [(3000, 1.1), (20000, 1.15), (100000, 1.2)]),
        ("ToyWorkshop", "BoxConveyor", [(16000, 1.15), (70000, 1.2)]),
        ("PlushieRoom", "YarnSpinner", [(4000, 1.1), (24000, 1.15), (120000, 1.2)]),
        ("PlushieRoom", "PillowPile", [(1600, 1.1), (12000, 1.1), (60000, 1.15)]),
        ("PlushieRoom", "ButtonJar", [(8000, 1.1), (50000, 1.15)]),
    ],
    rebirth_cost=100_000_000_000,  # Config/Rebirths
    base_cycle=4.0,  # Config/Production
    # the player's parts: the average part value over time (Commons 5, Uncommons 12
    # before the first rebirth), and the share of full lines that are full matches (x2)
    part_value=[(0, 5), (900, 6.5), (2400, 8), (5400, 9.5)],
    match_share=[(0, 1.0), (600, 0.6), (3600, 0.55)],
    # map loot boxes: a duplicate every `box_every` s pays Coins + 15 s of income (Config/Loot)
    box_every=75, box_coins=150, box_income_seconds=15, box_from=600,
    patience=900,  # seconds of waiting that halve a button's appeal
)


def interp(table, t):
    for (t0, v0), (t1, v1) in zip(table, table[1:]):
        if t <= t1:
            return v0 + (v1 - v0) * (t - t0) / (t1 - t0)
    return table[-1][1]


def round2(price):
    if price <= 0:
        return 0
    unit = 10 ** max(math.floor(math.log10(price)) - 1, 0)
    return math.floor(price / unit + 0.5) * unit


class Line:
    def __init__(self, zone, index):
        self.zone, self.index = zone, index
        self.open = False
        self.drops = 0
        self.speed = 1.0
        self.stations = 1.0
        self.tracks = {}


class Sim:
    def __init__(self, c):
        self.c = c
        self.zone = {z[0]: z for z in c["zones"]}
        self.items = []
        self.byid = {}
        self.lines = {}
        for zid, zprice, zval, zpm in c["zones"]:
            if zprice:
                self.add(dict(id=f"{zid}_Room", zone=zid, kind="Room", price=zprice, req=None))
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
            for lv, (price, mult) in enumerate(levels, 1):
                iid = f"{zid}_Decor_{key}_{lv}"
                self.add(dict(id=iid, zone=zid, kind="Decor", price=round2(price * zpm), mult=mult, req=prev))
                prev = iid
        self.decor = {z: 1.0 for z in self.zone}
        self.owned = set()

    def add(self, it):
        self.items.append(it)
        self.byid[it["id"]] = it

    def line_income(self, line, t, pv, ms, extra=None):
        drops, speed, stations, tracks, decor = line.drops, line.speed, line.stations, dict(line.tracks), self.decor[line.zone]
        if extra:
            for it in extra:
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
        if drops == 0:
            return 0.0
        cycle = self.c["base_cycle"] / speed
        mult = stations * decor * self.zone[line.zone][2]
        flat = 0
        for key, eff, step, *_ in self.c["tracks"]:
            l = tracks.get(key, 0)
            if eff == "Speed":
                cycle /= 1 + step * l
            elif eff == "Percent":
                mult *= 1 + step * l
            else:
                flat += step * l
        base = drops * pv + flat
        if drops == 4:
            base *= 1 + ms
        return base * mult / cycle

    def income(self, t):
        pv, ms = interp(self.c["part_value"], t), interp(self.c["match_share"], t)
        return sum(self.line_income(l, t, pv, ms) for l in self.lines.values() if l.open)

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

    def gain(self, it, t, pv, ms):
        """Income gain of buying `it` (a room or line counts with its 4 droppers)."""
        k = it["kind"]
        if k == "Room" or k == "Line":
            lid = it.get("line") or f"{it['zone']}_1"
            line = self.lines[lid]
            keys = ("Head", "Body", "Arms", "Legs")
            if k == "Room":
                # a new room is worth its first line with its whole button chain
                keys = [key for key, *_ in self.c["items"]]
            bundle = [self.byid[f"{lid}_{d}"] for d in keys]
            if k == "Room":
                bundle = [self.byid[f"{lid}_Line"]] + bundle
            price = sum(b["price"] for b in bundle) + it["price"] if k == "Room" else sum(b["price"] for b in bundle) + it["price"]
            saved = line.drops
            line.drops = 0
            saved_s, saved_st = line.speed, line.stations
            line.speed, line.stations = 1.0, 1.0
            g = self.line_income(line, t, pv, ms, [b for b in bundle if b["kind"] != "Line"])
            line.speed, line.stations = saved_s, saved_st
            line.drops = saved
            return g, price
        if k == "Decor":
            g = sum(self.line_income(l, t, pv, ms, [it]) - self.line_income(l, t, pv, ms)
                    for l in self.lines.values() if l.open and l.zone == it["zone"])
            return g, it["price"]
        line = self.lines[it["line"]]
        return self.line_income(line, t, pv, ms, [it]) - self.line_income(line, t, pv, ms), it["price"]

    def run(self, rebirth_cost, log=False, horizon=30 * 3600):
        c = self.c
        self.grant_free()
        coins, t = 0.0, 0.0
        box_next = c["box_from"]
        ms_ = {}
        trace = []
        while t < horizon:
            inc = self.income(t)
            if coins >= rebirth_cost:
                break
            pv, ms = interp(c["part_value"], t), interp(c["match_share"], t)
            best, best_score, bg, bp = None, -1, 0, 0
            for it in self.visible():
                g, p = self.gain(it, t, pv, ms)
                if g <= 0 or p <= 0:
                    continue
                wait = max(0, (p - coins) / max(inc, 1e-9))
                score = g / p / (1 + wait / c["patience"])
                if score > best_score:
                    best, best_score, bg, bp = it, score, g, p
            save = (rebirth_cost - coins) / max(inc, 1e-9)
            if best is None or bp / bg > save:
                t += save
                break
            price = best["price"]
            if coins < price:
                dt = (price - coins) / max(inc, 1e-9)
                while box_next < t + dt:
                    coins += c["box_coins"] + c["box_income_seconds"] * inc
                    box_next += c["box_every"]
                    dt = max(0, (price - coins) / max(inc, 1e-9))
                coins += inc * dt
                t += dt
            coins -= price
            self.apply(best)
            self.grant_free()
            if best["kind"] == "Room":
                ms_[best["zone"]] = t
                if log:
                    trace.append(f"{t/60:6.1f} min open {best['zone']:<18} {price:>14,.0f}  income {self.income(t):>12,.0f}/s")
            elif log and best["kind"] in ("Line",):
                trace.append(f"{t/60:6.1f} min {best['id']:<24} {price:>14,.0f}  income {self.income(t):>12,.0f}/s")
        return dict(t=t, share=len(self.owned) / len(self.items), rooms=ms_, income=self.income(t), trace=trace)


def main():
    r = Sim(BASE).run(BASE["rebirth_cost"], log=True)
    print("\n".join(r["trace"]))
    print(f"rebirth ({BASE['rebirth_cost']:,.0f} Coins) at {r['t'] / 3600:.2f} h with {r['share'] * 100:.0f}% of the buttons bought; income then {r['income']:,.0f}/s")


if __name__ == "__main__":
    main()
