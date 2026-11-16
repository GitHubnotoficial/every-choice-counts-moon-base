-- EmergencyData (ModuleScript) -> ReplicatedStorage.EmergencyData
-- Dueño: Isaac + Claude (Ramón puede completar las otras 10 con esta misma forma).
-- Las 6 emergencias de la primera versión (PDF Fase 3, cap. 6). Textos de la tarjeta EXACTOS del PDF.
-- Prob = probabilidad por día (días 2 a 6). Condition = clave que revisa Emergencies.
-- Cada respuesta: Label (botón), Points = { Where, Count, Hold, Ordered (uno tras otro) }, Requires (clave opcional), Toast, Effect.
-- ProtectedNote = lo que dice la tarjeta PROTECTED si el Engineer hizo su misión (PDF Fase 3, cap. 6).
-- Los efectos y probabilidades son del juego; los hechos (Fact/Source) son reales y con fuente en docs/06-fuentes.md.
-- 15-nov (Claude): se agregaron las otras 10 emergencias del PDF de la Fase 3 (cap. 6), con los textos exactos de la tarjeta.

return {
	{
		Id = "flare", Role = "cap", Prob = 0.10, Condition = "always",
		Title = "SOLAR FLARE!",
		Text = "A burst from the Sun cut your radio link with Earth.",
		DataLine = "NASA DONKI · Solar Flare (FLR)",
		Fact = "On October 3, 2024, the Sun released an X9.0 flare, the category NASA uses for the most intense flares. NASA says flares can impact radio communications, power grids and navigation signals.",
		A = { Label = "Climb to the antenna and realign it", Points = { Where = "antenna", Count = 1, Hold = 6 }, Toast = "CONTACT RESTORED!", Effect = "next_choose_20" },
		B = { Label = "Use the lander radio", Points = { Where = "lander", Count = 1, Hold = 4 }, Toast = "WEAK SIGNAL", Effect = "next_choose_15" },
		C = { Label = "Wait", Toast = "STILL NO CONTACT", Effect = "no_contact" },
	},
	{
		Id = "cme", Role = "eng", Prob = 0.08, Condition = "always", ProtectedBy = "MissionComplete_eng", ProtectedNote = "your base was ready",
		Title = "CORONAL MASS EJECTION!",
		Text = "A cloud of solar material is hitting the base. A power surge is coming.",
		DataLine = "NASA DONKI · Coronal Mass Ejection (CME)",
		Fact = "NASA describes a coronal mass ejection as a cloud of magnetized solar material that erupts from the Sun's corona into interplanetary space. It can contain about a billion tons of solar material.",
		A = { Label = "Switch to safe mode", Points = { Where = "board", Count = 1, Hold = 5 }, Toast = "SAFE MODE ON", Effect = "greenhouse_off" },
		B = { Label = "Isolate the life support machine", Points = { Where = "board", Count = 1, Hold = 5 }, Toast = "MACHINE ISOLATED", Effect = "machine_off" },
		C = { Label = "Do nothing", Toast = "POWER SURGE!", Effect = "surge" },
	},
	{
		Id = "co2", Role = "life", Prob = 0.08, Condition = "has_machine",
		Title = "HIGH CO₂!",
		Text = "There is too much carbon dioxide in the habitat air.",
		DataLine = "NASA OSDR · Environmental data: carbon dioxide (CO₂)",
		Fact = "On Apollo 13 in 1970, the crew built a filter adapter from plastic bags, a flight plan card and duct tape. The CO₂ levels dropped.",
		Ongoing = "o2_fast", -- mientras no se arregle, el O2 de todos baja ×1,5
		A = { Label = "Build a filter from spare parts", Points = { Where = "parts_then_machine", Count = 2, Hold = 6 }, Toast = "AIR IS CLEAN", Effect = "fixed" },
		B = { Label = "Put in a spare filter", Points = { Where = "machine", Count = 1, Hold = 3 }, Requires = "MissionComplete_life", Toast = "NEW FILTER!", Effect = "fixed" },
		C = { Label = "Everyone rests", Toast = "THE AIR FEELS HEAVY", Effect = "rest" },
		Timeout = "o2_fast_day", -- si nadie responde: O2 ×1,5 el resto del día
	},
	{
		Id = "dose", Role = "life", Prob = 0.07, Condition = "always",
		Title = "RADIATION ALARM!",
		Text = "The dose meters are showing a jump in radiation.",
		DataLine = "NASA RadLab · Absorbed dose rate (Gy/hour)",
		Fact = "NASA says that for Orion the crew would use stowage bags, food and water to build a temporary shelter from radiation. NASA also says shielding that blocks solar particles does not stop galactic cosmic rays.",
		A = { Label = "Check the meters and take shelter", Points = { Where = "meters", Count = 3, Hold = 4 }, Toast = "DOSE UNDER CONTROL", Effect = "rad_out_15" },
		B = { Label = "Build a wall of supplies", Points = { Where = "supplies", Count = 3, Hold = 4 }, Toast = "SUPPLY WALL BUILT", Effect = "supply_wall" },
		C = { Label = "Wait", Toast = "DOSE RATE HIGH!", Effect = "rad_out_2_nodrop" },
	},
	{
		Id = "mold", Role = "bot", Prob = 0.07, Condition = "has_trays",
		Title = "MOLD!",
		Text = "The air is too humid. White spots are growing on the leaves of two trays.",
		DataLine = "NASA OSDR · Environmental data: relative humidity",
		Fact = "In 2015 zinnias growing on the ISS got mold. Astronaut Scott Kelly cared for them, and they bloomed on January 16, 2016.",
		A = { Label = "Cut the leaves and turn up the fans", Points = { Where = "trays", Count = 2, Hold = 4 }, Toast = "TRAYS SAVED!", Effect = "fixed" },
		B = { Label = "Throw away one tray", Points = { Where = "trays", Count = 1, Hold = 2 }, Toast = "TRAY REMOVED", Effect = "lose_tray_1" },
		C = { Label = "Leave it", Toast = "THE MOLD IS SPREADING", Effect = "mold_spread" },
	},
	{
		Id = "freeze", Role = "bot", Prob = 0.07, Condition = "always",
		Title = "FREEZING NIGHT!",
		Text = "The temperature is dropping fast. Your crops are in danger.",
		DataLine = "NASA OSDR · Environmental data: temperature",
		Fact = "Near the Moon's equator, night temperatures drop to -133 °C.",
		A = { Label = "Turn on the heaters", Points = { Where = "heater", Count = 1, Hold = 4 }, Toast = "HEATERS ON", Effect = "heaters" },
		B = { Label = "Move everything into the habitat", Points = { Where = "trays", Count = 2, Hold = 3 }, Toast = "TRAYS MOVED INSIDE", Effect = "trays_no_grow" },
		C = { Label = "Leave it", Toast = "THE COLD KILLED THE CROPS", Effect = "cold_kill" },
	},

	-------------------------------------------------------------------
	-- Las otras 10 emergencias (PDF Fase 3, cap. 6). Textos de la tarjeta EXACTOS del PDF.
	-------------------------------------------------------------------
	-- CAPTAIN
	{
		Id = "sep", Role = "cap", Prob = 0.06, Condition = "always",
		Title = "SOLAR RADIATION STORM!",
		Text = "The Sun is sending out very fast particles. Radiation outside is rising.",
		DataLine = "NASA DONKI · Solar Energetic Particle (SEP)",
		Fact = "NASA says solar energetic particles are almost all protons, and that on the Moon astronauts could pile lunar soil (regolith) over shelters. Strong events like this happened in August 1972, between Apollo 16 and Apollo 17.",
		A = { Label = "Everyone into the habitat", Points = { Where = "habitat", Count = 1, Hold = 3 }, Toast = "EVERYONE IS SAFE", Effect = "rad_storm_a" },
		B = { Label = "Cover the habitat with regolith", Points = { Where = "habitat3", Count = 3, Hold = 4 }, Toast = "SHELTER COVERED", Effect = "rad_storm_b" },
		C = { Label = "Keep working", Toast = "RADIATION RISING!", Effect = "rad_storm_c" },
	},
	{
		Id = "dust", Role = "cap", Prob = 0.08, Condition = "always",
		Title = "DUST IN THE AIRLOCK!",
		Text = "Moon dust got inside and is sticking to the machines.",
		DataLine = "Based on NASA: Electrodynamic Dust Shield",
		Fact = "In 2025 NASA's Electrodynamic Dust Shield removed Moon dust from glass and a radiator on the Blue Ghost lander.",
		A = { Label = "Vacuum the whole airlock", Points = { Where = "airlock3", Count = 3, Hold = 4 }, Toast = "AIRLOCK CLEAN", Effect = "fixed" },
		B = { Label = "Only clean the suits", Points = { Where = "lander", Count = 1, Hold = 4 }, Toast = "SUITS CLEANED", Effect = "dust_b" },
		C = { Label = "Ignore it", Toast = "DUST ON THE MACHINE", Effect = "dust_c" },
	},
	{
		Id = "nocontact", Role = "cap", Prob = 0.06, Condition = "contact_ok",
		Title = "NO CONTACT WITH EARTH!",
		Text = "The base lost contact with Earth. Mission Control can't help you.",
		DataLine = "Based on NASA: Lunar Communications Relay and Navigation Systems",
		Fact = "At the Moon's south pole, Earth can be out of view. NASA plans relay satellites to keep astronauts in contact.",
		A = { Label = "Climb to the antenna and fix it", Points = { Where = "antenna", Count = 1, Hold = 6 }, Toast = "EARTH IS BACK!", Effect = "next_choose_20" },
		B = { Label = "Use the lander radio", Points = { Where = "lander", Count = 1, Hold = 4 }, Toast = "WEAK SIGNAL", Effect = "next_choose_15" },
		C = { Label = "Wait", Toast = "STILL NO CONTACT", Effect = "no_contact" },
	},
	-- ENGINEER
	{
		Id = "geostorm", Role = "eng", Prob = 0.06, Condition = "always", ProtectedBy = "MissionComplete_eng", ProtectedNote = "your base was ready",
		Title = "GEOMAGNETIC STORM!",
		Text = "A geomagnetic storm is disturbing your electronics.",
		DataLine = "NASA DONKI · Geomagnetic Storm (GST)",
		Fact = "In May 2024 the Sun produced the biggest geomagnetic storm in 20 years, rated G5, the top level. NASA says some spacecraft powered down certain instruments or systems in advance.",
		A = { Label = "Power down early", Points = { Where = "board", Count = 1, Hold = 4 }, Toast = "SYSTEMS PROTECTED", Effect = "geo_a" },
		B = { Label = "Use the backup computer", Points = { Where = "consoles2", Count = 2, Hold = 3 }, Toast = "BACKUP ONLINE", Effect = "geo_b" },
		C = { Label = "Leave everything on", Toast = "SYSTEM DOWN!", Effect = "system_down" },
	},
	{
		Id = "shadow", Role = "eng", Prob = 0.08, Condition = "has_panels", ProtectedBy = "MissionComplete_eng", ProtectedNote = "your panels were ready",
		Title = "LONG SHADOW!",
		Text = "A long shadow is covering the solar panels. There is no power from the Sun.",
		DataLine = "Based on NASA: Weather on the Moon",
		Fact = "A lunar night lasts about 14 Earth days, so a Moon base cannot rely only on the Sun.",
		A = { Label = "Turn off the greenhouse", Points = { Where = "board", Count = 1, Hold = 5 }, Toast = "GREENHOUSE OFF", Effect = "greenhouse_off" },
		B = { Label = "Turn off the life support machine", Points = { Where = "board", Count = 1, Hold = 5 }, Toast = "MACHINE OFF", Effect = "machine_off" },
		C = { Label = "Do nothing", Toast = "EVERYTHING IS OFF", Effect = "all_off" },
	},
	{
		Id = "reactor", Role = "eng", Prob = 0.08, Condition = "has_reactor", ProtectedBy = "MissionComplete_eng", ProtectedNote = "the radiators were checked",
		Title = "REACTOR SHUTDOWN!",
		Text = "The reactor turned itself off for safety. The base has no power.",
		DataLine = "Based on NASA: KRUSTY fission power test",
		Fact = "In 2018 NASA's KRUSTY test simulated power cuts, failed engines and failed heat pipes, and the reactor kept running.",
		A = { Label = "Restart the reactor", Points = { Where = "reactor3", Count = 3, Hold = 5, Ordered = true }, Toast = "REACTOR ONLINE", Effect = "fixed" },
		B = { Label = "Use the emergency batteries", Points = { Where = "board", Count = 1, Hold = 3 }, Toast = "BATTERIES ONLINE", Effect = "greenhouse_off" },
		C = { Label = "Wait", Toast = "NO POWER", Effect = "all_off" },
	},
	-- LIFE SUPPORT
	{
		Id = "leak", Role = "life", Prob = 0.08, Condition = "has_tanks",
		Title = "LEAK!",
		Text = "A tank has a small hole and is losing water.",
		DataLine = "Based on NASA: ISS Status, August 2018",
		Fact = "In August 2018 the ISS crew found a 2 mm hole in a Soyuz spacecraft and slowed the leak with tape. The crew was never in danger.",
		A = { Label = "Patch the leak", Points = { Where = "machine", Count = 1, Hold = 6 }, Toast = "LEAK PATCHED!", Effect = "fixed" },
		B = { Label = "Close that tank", Points = { Where = "machine", Count = 1, Hold = 2 }, Toast = "TANK CLOSED", Effect = "water_minus10" },
		C = { Label = "Ignore it", Toast = "THE LEAK KEEPS GOING", Effect = "leak_spread" },
	},
	{
		Id = "muscles", Role = "life", Prob = 0.06, Condition = "always",
		Title = "WEAK MUSCLES AND BONES!",
		Text = "Your crew is losing strength after days in low gravity.",
		DataLine = "NASA OSDR · Space biology: muscle and bone",
		Fact = "NASA's Open Science Data Repository has data that helps understand muscle atrophy and bone loss, which matter for long missions to the Moon and Mars.",
		A = { Label = "Whole-crew workout", Points = { Where = "exercise", Count = 1, Hold = 6 }, Toast = "STRONG AGAIN!", Effect = "extra_energy_5" },
		B = { Label = "Short workout", Points = { Where = "exercise", Count = 1, Hold = 3 }, Toast = "A LITTLE STRONGER", Effect = "slow_2" },
		C = { Label = "Skip it", Toast = "THE CREW IS WEAK", Effect = "slow_4_2days" },
	},
	-- BOTANIST
	{
		Id = "spoiled", Role = "bot", Prob = 0.07, Condition = "packaged_outside",
		Title = "SPOILED FOOD!",
		Text = "A food crate opened and some food may be bad.",
		DataLine = "Based on NASA: Space Food Systems",
		Fact = "NASA wants food for long missions to stay safe and tasty for up to five years.",
		A = { Label = "Check every crate", Points = { Where = "crates3", Count = 3, Hold = 3 }, Toast = "CRATES CHECKED", Effect = "food_half" },
		B = { Label = "Throw away the open crate", Points = { Where = "crate1", Count = 1, Hold = 2 }, Toast = "CRATE REMOVED", Effect = "food_one" },
		C = { Label = "Eat it anyway", Toast = "STOMACH ACHE", Effect = "stomach" },
	},
	{
		Id = "sick", Role = "bot", Prob = 0.06, Condition = "always",
		Title = "SICK CREW!",
		Text = "Your crew's immune systems are weak. Germs are spreading.",
		DataLine = "NASA OSDR · Space biology: immune system and microbes",
		Fact = "NASA's space biology research looks at bone loss, immune dysregulation and microbial evolution. Its data comes from humans, animals, plants and microbes.",
		A = { Label = "Clean and disinfect", Points = { Where = "clean3", Count = 3, Hold = 3 }, Toast = "EVERYTHING IS CLEAN", Effect = "fixed" },
		B = { Label = "Give fresh vegetables", Points = { Where = "ready_tray", Count = 1, Hold = 3 }, Requires = "HasReadyTray", Toast = "FRESH FOOD HELPS", Effect = "fresh_veg" },
		C = { Label = "Keep working", Toast = "THE CREW IS SICK", Effect = "sick" },
	},
}
