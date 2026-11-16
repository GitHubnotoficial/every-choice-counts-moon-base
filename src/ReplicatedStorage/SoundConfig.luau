-- SoundConfig (ModuleScript) -> ReplicatedStorage.SoundConfig
-- Sonidos del juego (todos gratis de la tienda de Roblox; se comprobó que cargan en este place el 15-nov).
-- Para cambiar un sonido, cambiar el número del Id. Volume: 0 a 1. Lo usa StarterPlayerScripts.SoundManager.

return {
	-- Música (en bucle)
	EarthMusic = { Id = 134433077845062, Volume = 0.22 }, -- "Return Signal Hopeful Future Ambient Music" (DistroKid): menús, edificio, despegue
	MoonMusic = { Id = 140533822783920, Volume = 0.22 }, -- "Space Ambient" (DistroKid): en la Luna

	-- Efectos
	Click = { Id = 15675059323, Volume = 0.5 }, -- "Roblox_UI_Bright_Click" (Roblox): botones de pantalla
	Beep = { Id = 9117060349, Volume = 0.6 }, -- "Nasa Transmission Beep 2" (Pro Sound Effects): al terminar un "mantener E" y al empezar el día
	Alarm = { Id = 611141322, Volume = 0.45, Seconds = 4 }, -- "Spaceship Alarm (Loop)": emergencia (PDF Fase 3: "con una alarma y una luz roja")
	Launch = { Id = 12222065, Volume = 0.8 }, -- "Launching rocket.wav" (Roblox): despegue
	Rumble = { Id = 9113224519, Volume = 0.35 }, -- "Avalanche Very Deep Crumbling 2" (Pro Sound Effects): motores del despegue y del aterrizaje
	Victory = { Id = 1836473422, Volume = 0.7 }, -- "Victory Fanfare Sting" (APM Music): MISSION COMPLETE
	Fail = { Id = 125909120236588, Volume = 0.6 }, -- "Mounting Consequences StingA" (APM Music): MISSION FAILED / muerte
}
