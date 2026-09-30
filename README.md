# Build a Brainrot

A Roblox brainrot factory tycoon. Build assembly lines that put brainrots together part by part, hunt loot boxes for new parts, complete brainrots in every zone's edition, and rebirth into crazier zones.

- **Design:** [GDD.md](GDD.md) is the source of truth for mechanics, the sprint plan and the polish backlog.
- **Code:** `sync/` mirrors the Roblox place through [Azul](https://azul.ransomwave.games) (Studio-first sync). `Name.server.luau` is a Script, `Name.client.luau` a LocalScript, and `Name.luau` a ModuleScript.
- **Workflow:** keep Azul running while editing files, or Studio's copy wins on the next sync. Don't edit code during a playtest.
