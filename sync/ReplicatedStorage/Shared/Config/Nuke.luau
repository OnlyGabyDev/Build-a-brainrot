--[[
	The NUKE (GDD §12, a developer product): someone buys it, the whole server gets a
	warning, a giant Bombardiro Crocodilo slowly flies in over the hub and drops a nuke,
	and when it hits the ground every screen goes white and everyone dies (every Humanoid
	in the game: players, and later bosses and other NPCs; things tagged NukeProof, like
	the podium's avatars, are spared). The server times the kills, every client plays
	the show by the same clock (seconds after the launch's server time).
]]

return {
	Warning = 0, -- the banner and the siren
	Arrive = 2.5, -- the bomber starts fading in, far out
	Over = 11, -- it's over the hub: the nuke drops
	Impact = 14.5, -- the nuke hits the ground: white screens, everyone dies
	Leave = 18, -- the bomber's gone (it flies on and fades out)
	Cooldown = 25, -- the next nuke in the queue waits this long after an impact

	BomberId = "BombardiroCrocodilo",
	BomberScale = 11,
	Altitude = 190, -- the bomber's height over the hub
	ApproachFrom = 900, -- how far out it appears
	WhiteHold = 1.6, -- seconds the screen stays white
	WhiteFade = 2.2,
}
