--[[
	Gadgets (GDD §3): a brainrot's gadget unlocks with its first completion (in any
	edition), together with its morph. Every gadget is one of a few reusable
	archetypes plus config. Brainrots without an entry have no gadget yet.
]]

export type Gadget = {
	Name: string,
	Archetype: string, -- "Movement" | "Melee" | "Emote" | "Launch"
	Icon: string?, -- one of ours (Config/Icons), shown in the Index: Shoe (Movement), Hammer (Melee), Rocket (Launch)
	Description: string?, -- one short line for the Index
	-- Movement (while held)
	WalkSpeed: number?,
	JumpHeight: number?,
	-- Launch (click: throws you Forward and Up, studs/s; Cooldown)
	Forward: number?,
	Up: number?,
	-- Melee (no effect inside tycoon plots: they're safe zones)
	Range: number?, -- studs in front of you
	Knockback: number?, -- launch speed
	Cooldown: number?,
	-- Emote
	AnimationId: string?,
}

local Gadgets: { [string]: Gadget } = {
	TralaleroTralala = { Name = "Tralalero Sneakers", Icon = "Shoe", Description = "Hold it to run super fast!", Archetype = "Movement", WalkSpeed = 30 },
	TungTungTungSahur = { Name = "Sahur Baton", Icon = "Hammer", Description = "Bonk players far away!", Archetype = "Melee", Range = 8, Knockback = 90, Cooldown = 1 },
	BallerinaCappuccina = {
		Name = "Ballerina Dance",
		Icon = "Music",
		Description = "Click to dance!",
		Archetype = "Emote",
		AnimationId = "rbxassetid://507771019", -- Roblox's default R15 dance
	},
	-- simple ones for the rest (the user, 2026-10-03: a gadget for every brainrot)
	BrrBrrPatapim = { Name = "Patapim Leaf Hop", Icon = "Shoe", Description = "Hold it to jump really high!", Archetype = "Movement", JumpHeight = 18 },
	LiriliLarila = { Name = "Lirilì Cactus Boots", Icon = "Shoe", Description = "Hold it to walk faster.", Archetype = "Movement", WalkSpeed = 24 },
	TrippiTroppi = { Name = "Trippi Shrimp Jump", Icon = "Rocket", Description = "Click to leap forward!", Archetype = "Launch", Forward = 70, Up = 45, Cooldown = 2 },
	ChimpanziniBananini = { Name = "Banana Slap", Icon = "Hammer", Description = "Slap players away!", Archetype = "Melee", Range = 7, Knockback = 60, Cooldown = 0.8 },
	BonecaAmbalabu = { Name = "Boneca Tire Roll", Icon = "Shoe", Description = "Hold it to roll super fast!", Archetype = "Movement", WalkSpeed = 34 },
	CappuccinoAssassino = { Name = "Assassin Katana", Icon = "Hammer", Description = "Slash players far away!", Archetype = "Melee", Range = 9, Knockback = 110, Cooldown = 1.2 },
	BombombiniGusini = { Name = "Goose Flap", Icon = "Rocket", Description = "Click to flap up into the sky!", Archetype = "Launch", Forward = 20, Up = 90, Cooldown = 2.5 },
	FrigoCamelo = { Name = "Fridge Slam", Icon = "Hammer", Description = "A huge slam: players fly!", Archetype = "Melee", Range = 10, Knockback = 130, Cooldown = 2 },
	GlorboFruttodrillo = { Name = "Watermelon Chomp", Icon = "Hammer", Description = "Chomp players away!", Archetype = "Melee", Range = 7, Knockback = 85, Cooldown = 1 },
	BombardiroCrocodilo = { Name = "Bombardiro Jet", Icon = "Rocket", Description = "Click to blast forward like a jet!", Archetype = "Launch", Forward = 140, Up = 55, Cooldown = 3 },
	LaVacaSaturnoSaturnita = { Name = "Saturn Moon Jump", Icon = "Shoe", Description = "Hold it to jump like on the moon!", Archetype = "Movement", JumpHeight = 30 },
	-- the bigger collection's first wave (2026-10-07)
	TimCheese = { Name = "Cheese Dash", Icon = "Shoe", Description = "Hold it to scurry fast!", Archetype = "Movement", WalkSpeed = 26 },
	TaTaTaTaSahur = { Name = "Teapot Bonk", Icon = "Hammer", Description = "Bonk players away!", Archetype = "Melee", Range = 7, Knockback = 70, Cooldown = 1 },
	TricTracBaraboom = { Name = "Baraboom Stomp", Icon = "Rocket", Description = "Click to spring up high!", Archetype = "Launch", Forward = 30, Up = 75, Cooldown = 2.5 },
	Fluriflura = { Name = "Fluri Flap", Icon = "Rocket", Description = "Click to flap forward!", Archetype = "Launch", Forward = 55, Up = 65, Cooldown = 2 },
	BanditoBobritto = { Name = "Beaver Tail Slap", Icon = "Hammer", Description = "Slap players away!", Archetype = "Melee", Range = 8, Knockback = 80, Cooldown = 1 },
	TrulimeroTrulicina = { Name = "Four-Leg Sprint", Icon = "Shoe", Description = "Hold it to run super fast!", Archetype = "Movement", WalkSpeed = 30 },
	BananitaDolphinita = { Name = "Dolphin Dive", Icon = "Rocket", Description = "Click to dive forward!", Archetype = "Launch", Forward = 95, Up = 40, Cooldown = 2 },
	BurbaloniLoliloli = { Name = "Coconut Roll", Icon = "Shoe", Description = "Hold it to roll super fast!", Archetype = "Movement", WalkSpeed = 32 },
	BlueberrinniOctopusini = { Name = "Tentacle Slap", Icon = "Hammer", Description = "Slap players far away!", Archetype = "Melee", Range = 9, Knockback = 95, Cooldown = 1.2 },
	OrangutiniAnanassini = { Name = "Jungle Swing", Icon = "Rocket", Description = "Click to swing far!", Archetype = "Launch", Forward = 85, Up = 80, Cooldown = 2.5 },
	GirafaCelestre = { Name = "Moon Boots", Icon = "Shoe", Description = "Hold it to jump into space!", Archetype = "Movement", JumpHeight = 34 },
	DragonCannelloni = { Name = "Dragon Wings", Icon = "Rocket", Description = "Click to fly like a dragon!", Archetype = "Launch", Forward = 160, Up = 100, Cooldown = 3 },
	-- the second wave (2026-10-07)
	TalpaDiFero = { Name = "Drill Nose", Icon = "Hammer", Description = "Drill players away!", Archetype = "Melee", Range = 7, Knockback = 70, Cooldown = 1 },
	SvininaBombardino = { Name = "Pig Bomb Blast", Icon = "Rocket", Description = "Click to blast up high!", Archetype = "Launch", Forward = 25, Up = 85, Cooldown = 2.5 },
	CactoHipopotamo = { Name = "Sandal Stroll", Icon = "Shoe", Description = "Hold it to walk faster.", Archetype = "Movement", WalkSpeed = 24 },
	PerochelloLemonchello = { Name = "Lemon Wings", Icon = "Rocket", Description = "Click to flap forward!", Archetype = "Launch", Forward = 60, Up = 70, Cooldown = 2 },
	MangoliniParrocini = { Name = "Parrot Hop", Icon = "Shoe", Description = "Hold it to jump really high!", Archetype = "Movement", JumpHeight = 20 },
	PenguinoCocosino = { Name = "Penguin Slide", Icon = "Shoe", Description = "Hold it to slide super fast!", Archetype = "Movement", WalkSpeed = 30 },
	StrawberrelliFlamingelli = { Name = "Flamingo Leap", Icon = "Rocket", Description = "Click to leap up high!", Archetype = "Launch", Forward = 50, Up = 85, Cooldown = 2.5 },
	RhinoToasterino = { Name = "Rhino Charge", Icon = "Hammer", Description = "Charge players far away!", Archetype = "Melee", Range = 9, Knockback = 110, Cooldown = 1.2 },
	ZibraZubraZibralini = { Name = "Zebra Gallop", Icon = "Shoe", Description = "Hold it to run super fast!", Archetype = "Movement", WalkSpeed = 34 },
	GorilloWatermelondrillo = { Name = "Gorilla Smash", Icon = "Hammer", Description = "A huge smash: players fly!", Archetype = "Melee", Range = 10, Knockback = 130, Cooldown = 1.5 },
	OrcaleroOrcala = { Name = "Orca Splash", Icon = "Rocket", Description = "Click to leap like an orca!", Archetype = "Launch", Forward = 130, Up = 75, Cooldown = 3 },
	TrenostruzzoTurbo3000 = { Name = "Turbo 3000", Icon = "Rocket", Description = "Click to zoom off like a train!", Archetype = "Launch", Forward = 190, Up = 40, Cooldown = 3 },
}

return Gadgets
