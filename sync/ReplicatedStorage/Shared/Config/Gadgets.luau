--[[
	Gadgets (GDD §3): a brainrot's gadget unlocks with its first completion (in any
	edition), together with its morph. Every gadget is one of a few reusable
	archetypes plus config. Brainrots without an entry have no gadget yet.
]]

export type Gadget = {
	Name: string,
	Archetype: string, -- "Movement" | "Melee" | "Emote"
	-- Movement
	WalkSpeed: number?,
	-- Melee (no effect inside tycoon plots: they're safe zones)
	Range: number?, -- studs in front of you
	Knockback: number?, -- launch speed
	Cooldown: number?,
	-- Emote
	AnimationId: string?,
}

local Gadgets: { [string]: Gadget } = {
	TralaleroTralala = {
		Name = "Tralalero Sneakers",
		Archetype = "Movement",
		WalkSpeed = 30,
	},
	TungTungTungSahur = {
		Name = "Sahur Baton",
		Archetype = "Melee",
		Range = 8,
		Knockback = 90,
		Cooldown = 1,
	},
	BallerinaCappuccina = {
		Name = "Ballerina Dance",
		Archetype = "Emote",
		AnimationId = "rbxassetid://507771019", -- Roblox's default R15 dance
	},
}

return Gadgets
