"""
Where a brainrot comes from, and its original meme image, before we draw it.

    python tools/brainrot_refs.py out.png "Tim Cheese" "Fluriflura" ...

For each name (its page title on the Steal a Brainrot fandom wiki) it prints the wiki's
`creator` and `rarity` fields, and finds the original meme image the page or its
/Gallery shows ("Origin Images", "the image it is based on"). It saves each one to
<out>_<Name>.png and puts them side by side in out.png (look with the Read tool).

The creator field is what tells a real meme from one Steal a Brainrot made up: a TikTok
handle (@alexey_pigeon, @ofuscabreno, ...) is a meme; "BRAZILIAN SPYDER" or "SpyderSammy"
(the game's developers) is theirs, and we don't use it. Draw from the original image,
never from the game's 3D figure (that's their work). The wiki is fan-made: check a
surprising one somewhere else too.
"""

import io
import json
import re
import subprocess
import sys
import urllib.parse

from PIL import Image, ImageDraw

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
WIKI = "https://stealabrainrot.fandom.com/"  # (Cloudflare wants the browser headers)


def fetch(url):
    return subprocess.run(["curl", "-sL", "-A", UA, "-H", "Referer: " + WIKI, url], capture_output=True).stdout


def api(query):
    try:
        return json.loads(fetch(WIKI + "api.php?" + query))
    except ValueError:
        return {}


def page(title):
    data = api(f"action=parse&page={urllib.parse.quote(title)}&prop=images|wikitext&format=json&redirects=1")
    return data.get("parse")


def field(wikitext, name):
    match = re.search(r"\|\s*" + name + r"\s*=\s*([^|\n}]*(?:\[[^\]]*\][^|\n}]*)?)", wikitext)
    return match.group(1).strip() if match else "?"


def original_image(title):
    for name in (title, title + "/Gallery"):
        parsed = page(name)
        if not parsed:
            continue
        wikitext = parsed["wikitext"]["*"]
        for image in parsed["images"]:
            pattern = re.escape(image.replace("_", " ")).replace(r"\ ", "[ _]")
            caption = re.search(pattern + r"[^\n]*", wikitext)
            text = image + " " + (caption.group(0) if caption else "")
            if re.search(r"(?i)origin|based on|tiktok|\bmeme\b", text):
                return image
    return None


def main():
    out, titles = sys.argv[1], sys.argv[2:]
    cells = []
    for title in titles:
        parsed = page(title)
        wikitext = parsed["wikitext"]["*"] if parsed else ""
        print(f"{title:32} rarity={field(wikitext, 'rarity'):14} creator={field(wikitext, 'creator') if wikitext else 'NO PAGE'}")
        image = original_image(title)
        if not image:
            print("    no original image found")
            continue
        info = api(f"action=query&titles=File:{urllib.parse.quote(image)}&prop=imageinfo&iiprop=url&iiurlwidth=500&format=json")
        found = next(iter(info["query"]["pages"].values()))["imageinfo"][0]
        try:
            picture = Image.open(io.BytesIO(fetch(found.get("thumburl") or found["url"]))).convert("RGB")
        except OSError:
            print("    the image didn't load")
            continue
        picture.save(out.rsplit(".", 1)[0] + "_" + re.sub(r"\W", "", title) + ".png")
        cells.append((title, picture))
    if not cells:
        return
    cell, columns = 330, 4
    rows = (len(cells) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell, rows * cell), (150, 150, 155))
    draw = ImageDraw.Draw(sheet)
    for index, (title, picture) in enumerate(cells):
        picture.thumbnail((cell - 10, cell - 26))
        x, y = (index % columns) * cell, (index // columns) * cell
        sheet.paste(picture, (x + (cell - picture.width) // 2, y + 22))
        draw.text((x + 6, y + 4), title, fill=(0, 0, 0))
    sheet.save(out)


if __name__ == "__main__":
    main()
