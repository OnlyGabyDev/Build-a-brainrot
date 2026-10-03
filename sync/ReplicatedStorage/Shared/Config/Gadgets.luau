--[[
	Gadgets (GDD §3): a brainrot's gadget unlocks with its first completion (in any
	edition), together with its morph. Every gadget is one of a few reusable
	archetypes plus config. Brainrots without an entry have no gadget yet.
]]

export type Gadget = {
	Name: string,
	Archetype: string, -- "Movement" | "Melee" | "Emote" | "Launch"
	Icon: string?, -- shown in the Index
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
	TralaleroTralala = { Name = "Tralalero Sneakers", Icon = "👟", Description = "Hold it to run super fast!", Archetype = "Movement", WalkSpeed = 30 },
	TungTungTungSahur = { Name = "Sahur Baton", Icon = "🥁", Description = "Bonk players far away!", Archetype = "Melee", Range = 8, Knockback = 90, Cooldown = 1 },
	BallerinaCappuccina = {
		Name = "Ballerina Dance",
		Icon = "🩰",
		Description = "Click to dance!",
		Archetype = "Emote",
		AnimationId = "rbxassetid://507771019", -- Roblox's default R15 dance
	},
	-- simple ones for the rest (the user, 2026-10-03: a gadget for every brainrot)
	BrrBrrPatapim = { Name = "Patapim Leaf Hop", Icon = "🌿", Description = "Hold it to jump really high!", Archetype = "Movement", JumpHeight = 18 },
	LiriliLarila = { Name = "Lirilì Cactus Boots", Icon = "🌵", Description = "Hold it to walk faster.", Archetype = "Movement", WalkSpeed = 24 },
	TrippiTroppi = { Name = "Trippi Shrimp Jump", Icon = "🦐", Description = "Click to leap forward!", Archetype = "Launch", Forward = 70, Up = 45, Cooldown = 2 },
	ChimpanziniBananini = { Name = "Banana Slap", Icon = "🍌", Description = "Slap players away!", Archetype = "Melee", Range = 7, Knockback = 60, Cooldown = 0.8 },
	BonecaAmbalabu = { Name = "Boneca Tire Roll", Icon = "🛞", Description = "Hold it to roll super fast!", Archetype = "Movement", WalkSpeed = 34 },
	CappuccinoAssassino = { Name = "Assassin Katana", Icon = "🗡️", Description = "Slash players far away!", Archetype = "Melee", Range = 9, Knockback = 110, Cooldown = 1.2 },
	BombombiniGusini = { Name = "Goose Flap", Icon = "🪿", Description = "Click to flap up into the sky!", Archetype = "Launch", Forward = 20, Up = 90, Cooldown = 2.5 },
	FrigoCamelo = { Name = "Fridge Slam", Icon = "🧊", Description = "A huge slam: players fly!", Archetype = "Melee", Range = 10, Knockback = 130, Cooldown = 2 },
	GlorboFruttodrillo = { Name = "Watermelon Chomp", Icon = "🍉", Description = "Chomp players away!", Archetype = "Melee", Range = 7, Knockback = 85, Cooldown = 1 },
	BombardiroCrocodilo = { Name = "Bombardiro Jet", Icon = "✈️", Description = "Click to blast forward like a jet!", Archetype = "Launch", Forward = 140, Up = 55, Cooldown = 3 },
	LaVacaSaturnoSaturnita = { Name = "Saturn Moon Jump", Icon = "🪐", Description = "Hold it to jump like on the moon!", Archetype = "Movement", JumpHeight = 30 },
	SupremoBrainrotto = { Name = "Royal Risotto Rush", Icon = "👑", Description = "Hold it: faster AND higher!", Archetype = "Movement", WalkSpeed = 36, JumpHeight = 16 },
}

return Gadgets
