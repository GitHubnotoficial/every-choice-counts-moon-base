--!strict
-- Config (ModuleScript) -> ReplicatedStorage.Config
-- Todos los números y textos del juego (fases 0, 1 y 2). Fuente: PDF de especificación de Leticia (14-nov).
-- Los textos que ve el jugador van en INGLÉS. Los comentarios en español.
-- Regla: nadie escribe números o textos sueltos en su script; los lee de aquí. Para cambiar algo, se pide a Isaac.

local Config = {}

---------------------------------------------------------------------
-- GENERAL
---------------------------------------------------------------------
Config.GameTitle = "EVERY CHOICE COUNTS: MOON BASE" -- nombre elegido por el equipo (15-nov)
Config.Tagline = "Build a base on the Moon with your crew"
Config.Label = "MOON BASE SURVIVAL" -- no usar el nombre ni el logo de la NASA
Config.MaxPlayers = 4

-- Paleta (morado, lavanda, rosa, celeste, amarillo + rojo/azul/blanco estilo NASA)
Config.Colors = {
	BgDark = Color3.fromHex("0C0628"),
	Stage = Color3.fromHex("160B45"),
	Panel = Color3.fromHex("22155E"),
	Panel2 = Color3.fromHex("2E1F78"),
	Text = Color3.fromHex("FFFFFF"),
	Muted = Color3.fromHex("C9BEF5"),
	Dim = Color3.fromHex("8F84C2"),
	Red = Color3.fromHex("FC3D21"), -- botones principales (PLAY, READY, CHOOSE)
	Gold = Color3.fromHex("FFD43B"),
	Bad = Color3.fromHex("FF7A66"),
	Good = Color3.fromHex("3DD68C"),
	Pink = Color3.fromHex("FF8FD1"),
	Sky = Color3.fromHex("7FD6FF"),
}

-- [15-nov] Letreros del centro espacial alrededor de la base de la Tierra (decoración, sin marcas reales)
Config.CampusSigns = {
	Center = "SPACE CENTER",
	Assembly = "ROCKET ASSEMBLY",
	Control = "MISSION CONTROL",
	Training = "ASTRONAUT TRAINING",
	Rover = "ROVER LAB",
	Science = "SCIENCE LAB",
	Plants = "SPACE FARM LAB",
	Fuel = "FUEL DEPOT",
	Visitors = "VISITOR CENTER",
}

-- [15-nov] Extras: huellas en la Luna, gestos, celebraciones, opciones (volumen y texto grande) y créditos
Config.Extras = {
	Footprints = {
		Step = 2.2, -- studs entre una huella y la siguiente
		Life = 40, -- segundos que dura cada huella
		Max = 300, -- huellas a la vez en pantalla (las más viejas se borran)
		MoonX = 1500, -- a partir de esta X estamos en la Luna
	},
	EmoteCooldown = 2.5, -- segundos entre gestos
	EmoteShow = 2.5, -- segundos que se ve el globo sobre la cabeza
	BigTextScale = 1.25, -- "texto grande" multiplica el tamaño de letra
	ConfettiCount = 70,
	Text = {
		Wave = "Wave",
		Point = "Point",
		WaveIcon = "👋",
		PointIcon = "👉",
		Settings = "Settings",
		Music = "Music",
		Effects = "Sound effects",
		BigText = "Big text",
		On = "ON",
		Off = "OFF",
		Credits = "Credits",
		Close = "Close",
		MissionDone = "%s mission complete!",
		PhaseDone = "Phase complete! Great teamwork!",
		Win = "You did it! The base survived!",
		CreditsTitle = "Every Choice Counts: Moon Base",
		TeamTitle = "Our team",
		SourcesTitle = "Where the science comes from",
		Thanks = "Made for the NASA Space Apps Challenge 2026. Thanks for playing!",
	},
	-- PENDIENTE: el equipo debe completar estas listas (nombres y fuentes reales que usaron)
	Credits = {
		Team = {
			"Leticia",
			"Isaac",
			"Celeste",
		},
		Sources = {
			"(add the sources of the science facts here)",
		},
	},
}

-- Tiempos (segundos)
Config.Times = {
	RoleSelect = 30, -- elección de rol (2D)
	Briefing = 20, -- instrucciones (2D)
	Phase0Decide = 90, -- 1:30 para elegir en los cuartos
	LaunchWindow = 15, -- el Captain tiene 15 s para lanzar
	Transition = 18, -- pantallas de paso entre fases (15-nov: 10 -> 18 para que quepa la animación del despegue; con READY de todos se salta)
	LaunchCinematic = 9, -- 15-nov: duración de la animación del despegue y viaje a la Luna (al inicio de Transition01)
	SiteSelect = 60, -- elegir sitio en la Luna 3D
	LandingAnim = 7, -- 15-nov: 7 s para la animación 3D de llegada a la Luna (LaunchCinematic)
	Placement = 300, -- 5:00 para colocar
	Phase2Intro = 10,
	Phase2 = 240, -- 4:00 de misiones
	NoWaterGrace = 120, -- con agua en 0, 2 min para recargar o muere
}

---------------------------------------------------------------------
-- ROLES (ids fijos: "cap", "eng", "life", "bot")
---------------------------------------------------------------------
Config.RoleOrder = { "cap", "eng", "life", "bot" }
Config.Roles = {
	cap = {
		Name = "CAPTAIN", Color = Color3.fromHex("E8341C"), Icon = "rocket", Door = "red door",
		Card = "You choose the ship and the landing site",
		Mission = "You are the CAPTAIN. Go to the red door. Choose the ship that will take your crew to the Moon.",
	},
	eng = {
		Name = "ENGINEER", Color = Color3.fromHex("FFC93C"), Icon = "gear", Door = "yellow door",
		Card = "You choose the energy and build the base",
		Mission = "You are the ENGINEER. Go to the yellow door. Choose how your base will get its energy.",
	},
	life = {
		Name = "LIFE SUPPORT", Color = Color3.fromHex("2F7BFF"), Icon = "drop", Door = "blue door",
		Card = "You keep the air and water flowing",
		Mission = "You are LIFE SUPPORT. Go to the blue door. Choose how your crew will get air and water.",
	},
	bot = {
		Name = "BOTANIST", Color = Color3.fromHex("3DD68C"), Icon = "leaf", Door = "green door",
		Card = "You grow the food",
		Mission = "You are the BOTANIST. Go to the green door. Choose how your crew will get food.",
	},
}

---------------------------------------------------------------------
-- TEXTOS DE PANTALLAS 2D
---------------------------------------------------------------------
Config.Text = {
	RoleAssigned = "You did not pick a role, so you got one at random!", -- READY en la elección de rol
	PlayersLine = "1–4 players · PC",
	ChooseRole = "CHOOSE YOUR ROLE",
	ChooseRoleHint = "Double-click a card to take a role",
	TakenBy = "TAKEN BY",
	You = "YOU",
	RolesTaken = "%d/4 roles taken",
	AutoAssign = "Free roles are auto-assigned in %s",
	BriefingTitle = "MISSION BRIEFING",
	BriefingTag = "PHASE 0 · 1:30 TO PREPARE THE SHIP",
	HowToPlay = "WASD: Move · Click: See pros and cons · Double-click: Choose · Hallway: The big screen shows what your team chose",
	WatchOut = "Talk to your crew. If the ship is too heavy, everyone arrives later with less oxygen and water. When time runs out, the Captain has 15 seconds to launch, or the ship leaves without you.",
	ReadyCount = "%d/4 ready · starts automatically in %s",
	LaunchNow = "CAPTAIN: LAUNCH NOW! %d",
	TooHeavy = "TOO HEAVY: −%d%% oxygen and water",
	LaunchOk = "LAUNCH SUCCESSFUL",
	Failed = "MISSION FAILED",
	FailedText = "The ship left without you. The Captain did not launch in time.",
	TryAgain = "TRY AGAIN",
	Continue = "CONTINUE",
	DidYouKnow = "Did you know?",
	Gravity = "Gravity: 1/6 of Earth",
	RoughLanding = "ROUGH LANDING! The ship tilted. Repairs cost 5% oxygen.",
	Damaged = "Your %s got damaged! Repair it in Phase 2.",
	Phase1Done = "PHASE 1 COMPLETE",
	WhatPhase2 = "What this means for Phase 2",
	Phase2Title = "PHASE 2: BUILD YOUR BASE",
	Phase2Footer = "Anyone can repair damaged items: hold E for 10 seconds.",
	Phase2Done = "PHASE 2 COMPLETE",
	BaseBuiltAt = "BASE BUILT AT %s",
	EnoughPower = "ENOUGH POWER: no blackouts",
	NotEnoughPower = "NOT ENOUGH POWER: BLACKOUTS AHEAD",
	NextSurvive = "Next: survive on the Moon",
	NoPlayer = "(no player — anyone can do it)",
	NoWater = "NO WATER: %s",
	DamagedSign = "DAMAGED — Hold E to repair",
	Repaired = "REPAIRED!",
	Energy = "ENERGY: %d used / %d made",
	-- Paso Fase 2 → 3 y fin anticipado de la Fase 2
	Phase2EndsSoon = "All missions done! Phase 2 ends in 10 seconds.",
	MissionNotDone = "%s — not finished: it will work at half power",
	StillDamaged = "Still damaged: %s",
	NothingDamaged = "Nothing is damaged. Great job!",
	-- Mission failed: qué hacer la próxima vez y un dato real
	FailedTip = "Next time: when the 1:30 runs out, the Captain has 15 seconds to press LAUNCH.",
	FailedFactTitle = "DID YOU KNOW?",
	FailedFact = "Real rockets have launch windows: they must lift off at the right moment to reach their target. If they miss it, they wait for the next one.",
}

---------------------------------------------------------------------
-- FASE 0: OPCIONES (una tabla por rol). Weight = peso; Capacity solo naves.
---------------------------------------------------------------------
Config.Options = {
	cap = {
		{ Id = "light", Name = "LIGHT LANDER", Capacity = 100, LateSolPenalty = 0,
			UsedIn = "Used in: Apollo Lunar Module, 1969–1972",
			Fact = "The Apollo Lunar Module carried 2 astronauts and landed on the Moon 6 times.",
			Pro = "Fast and simple. Your crew starts first.",
			Con = "Very little cargo space. Easy to make the ship too heavy." },
		{ Id = "cargo", Name = "CARGO LANDER", Capacity = 160, LateSolPenalty = 0,
			UsedIn = "Used in: Blue Ghost Mission 1 (Firefly Aerospace), 2025",
			Fact = "Blue Ghost landed on the Moon on March 2, 2025, carrying 10 NASA instruments, and worked for about 14 days.",
			Pro = "Good balance between cargo and speed.",
			Con = "Not the biggest and not the fastest." },
		{ Id = "starship", Name = "STARSHIP HLS", Capacity = 240, LateSolPenalty = 10,
			UsedIn = "Used in: Chosen by NASA in 2021 for the Moon landings (planned)",
			Fact = "Starship must fill its tanks in Earth orbit from tanker flights before it goes to the Moon. It has not landed on the Moon yet.",
			Pro = "Huge cargo space. Everything fits.",
			Con = "It needs extra fuel stops, so your crew arrives one day late." },
	},
	eng = {
		{ Id = "panels", Name = "SOLAR PANELS", Weight = 20,
			UsedIn = "Used in: International Space Station, since 2000",
			Fact = "The ISS unfurled its first permanent solar arrays in December 2000, and it still runs on solar power.",
			Pro = "Very light. Free energy from the Sun.",
			Con = "No Sun, no energy. Weak in dark places." },
		{ Id = "panels_bat", Name = "SOLAR PANELS + BATTERIES", Weight = 40,
			UsedIn = "Used in: International Space Station",
			Fact = "Every time the ISS passes through Earth's shadow, its batteries keep the power on.",
			Pro = "Keeps the power on during short shadows.",
			Con = "Twice as heavy. Still needs the Sun." },
		{ Id = "reactor", Name = "FISSION REACTOR", Weight = 60,
			UsedIn = "Used in: NASA KRUSTY test, 2018 (on Earth)",
			Fact = "In 2018 NASA's KRUSTY test reactor ran at full power for 28 hours. NASA says this kind of power can keep going through the two-week lunar night.",
			Pro = "Power day and night, anywhere.",
			Con = "The heaviest option. It can shut down in an emergency." },
	},
	life = {
		{ Id = "electrolyzer", Name = "ELECTROLYZER ONLY", Weight = 20, StartTanks = 70,
			UsedIn = "Used in: ISS Oxygen Generation System",
			Fact = "On the ISS it splits water, and the oxygen goes into the cabin air for the crew.",
			Pro = "Very light. Makes oxygen from water.",
			Con = "Recycles nothing. You need ice nearby." },
		{ Id = "recycler", Name = "RECYCLER + ELECTROLYZER", Weight = 40, StartTanks = 50,
			UsedIn = "Used in: ISS Water Recovery System",
			Fact = "In 2023 NASA announced that the ISS recovers 98% of its water, even from urine and from the crew's breath and sweat.",
			Pro = "Reuses almost all your water and makes oxygen.",
			Con = "Tanks start half full. Needs energy." },
		{ Id = "tanks", Name = "FULL TANKS", Weight = 60, StartTanks = 100,
			UsedIn = "Used in: Apollo missions, 1969–1972",
			Fact = "The longest Apollo visit to the Moon, Apollo 17 in 1972, lasted only 75 hours.",
			Pro = "Full air and water from day one. No energy needed.",
			Con = "Heavy, and they run out." },
		{ Id = "o2plant", Name = "REGOLITH OXYGEN PLANT", Weight = 60, StartTanks = 30,
			UsedIn = "Used in: NASA CaRD test, 2023 (on Earth)",
			Fact = "In 2023 NASA heated fake Moon soil with a powerful laser and pulled oxygen out of it.",
			Pro = "Makes oxygen from Moon soil forever.",
			Con = "Heavy, slow to start, uses a lot of energy, makes no water." },
	},
	bot = {
		{ Id = "regolith_kit", Name = "REGOLITH KIT", Weight = 20, FoodSols = 2,
			UsedIn = "Used in: University of Florida experiment reported by NASA, 2022 (on Earth)",
			Fact = "In 2022 scientists grew plants in real Moon soil from Apollo 11, 12 and 17. They grew more slowly and had stunted roots.",
			Pro = "Almost no weight. Grow food in Moon soil.",
			Con = "Only 2 days of packed food. Plants grow slowly." },
		{ Id = "hydroponics", Name = "HYDROPONIC RACKS", Weight = 40, FoodSols = 4,
			UsedIn = "Used in: Veggie on the International Space Station, since 2014",
			Fact = "On August 10, 2015, astronauts on the ISS ate red romaine lettuce grown in space.",
			Pro = "Fresh food and a little extra oxygen.",
			Con = "Uses water and energy. Only 4 days of packed food." },
		{ Id = "packaged", Name = "PACKAGED FOOD", Weight = 60, FoodSols = 999,
			UsedIn = "Used in: NASA Space Food Systems",
			Fact = "NASA wants food for long missions to stay safe and tasty for up to five years.",
			Pro = "Food for the whole mission. No energy needed.",
			Con = "Heavy. No fresh food and no extra oxygen." },
	},
}

-- Castigo por exceso de carga ("todos pagan"). PENDIENTE de confirmar con Isaac: escalado o fijo.
Config.Overload = {
	PercentPer10 = 5, -- −5 % de oxígeno y agua por cada 10 de exceso
	MinStart = 40, -- nadie empieza por debajo del 40 %
}

-- Velocidad al caminar en la Fase 1 hasta colocar (según peso de la Fase 0)
Config.WalkSpeed = { [0] = 16, [20] = 14, [40] = 12, [60] = 10, CaptainHabitat = 12 }

---------------------------------------------------------------------
-- FASE 1: SITIOS (puntajes del estudio del equipo, 0–10)
---------------------------------------------------------------------
Config.SiteBars = { "Sun", "Ice", "Comms", "Terrain", "Distances", "Science" }
Config.Sites = {
	{ Id = "ridge", Name = "CONNECTING RIDGE", Lat = -89.45, Lon = 222, Light = 88,
		Scores = { 9.5, 7, 9.5, 7.5, 8, 7 },
		Phrase = "The sunniest spot in our team's study.",
		Fact = "In 2022 NASA listed Connecting Ridge as a possible Artemis III landing region. All 13 regions have spots with sunlight for 6.5 days in a row." },
	{ Id = "shackleton", Name = "SHACKLETON RIM", Lat = -89.67, Lon = 129.8, Light = 85,
		Scores = { 9, 8.5, 9, 5, 9, 8 },
		Phrase = "A classic Artemis site next to a shadowed crater.",
		Fact = "Peaks on Shackleton's rim get sunlight more than 90% of the year, but the crater floor is always in shadow and may hold water ice." },
	{ Id = "nobile", Name = "NOBILE", Lat = -85.2, Lon = 53.5, Light = 70,
		Scores = { 7.5, 8.5, 8, 3.5, 8, 9 },
		Phrase = "Lots of ice and science, but frequent shadows.",
		Fact = "In 2021 NASA picked Nobile crater as the landing area for its VIPER ice rover." },
	{ Id = "faustini", Name = "FAUSTINI", Lat = -87.3, Lon = 77, Light = 18,
		Scores = { 1.5, 10, 3, 9, 10, 9.5 },
		Phrase = "The most ice in our team's study, but very little sunlight.",
		Fact = "NASA listed Faustini Rim A as a possible Artemis III landing region. Craters near the south pole that never see the Sun can reach −203 °C." },
	{ Id = "malapert", Name = "MALAPERT", Lat = -85.9, Lon = 0, Light = 85,
		Scores = { 9, 4, 10, 4, 3.5, 6 },
		Phrase = "The best radio contact with Earth in our team's study.",
		Fact = "Malapert Massif is a mountain more than 5,000 m tall. NASA lists it as a possible Artemis III landing region." },
}
Config.RoughTerrainBelow = 5 -- Terreno < 5 → aterrizaje inclinado
Config.RoughLandingO2 = 5 -- −5 % de oxígeno

Config.Gravity = { Earth = 196.2, Moon = 32.4 }

-- Puntos de colocación por rol. Offset = posición relativa a la nave (studs). AJUSTAR al construir el mapa.
Config.Spots = {
	cap = {
		{ Id = "open_field", Name = "OPEN FIELD", Dist = "Near", Offset = Vector3.new(120, 0, -10), RadMult = 1.5, BuildTime = 5,
			Fact = "The longest Apollo visit to the Moon, Apollo 17, lasted only 75 hours.",
			Pro = "Quick to build, close to the lander.", Con = "Radiation goes up faster." },
		{ Id = "crater_wall", Name = "CRATER WALL", Dist = "Medium", Offset = Vector3.new(-60, 0, 40), RadMult = 1.0, BuildTime = 5,
			Fact = "A NASA study found that the walls of a crater like Shackleton can cut radiation by up to 40% inside it.",
			Pro = "The wall blocks part of the radiation.", Con = "Farther from the lander." },
		{ Id = "half_buried", Name = "HALF-BURIED", Dist = "Near", Offset = Vector3.new(95, 0, -125), RadMult = 0.5, BuildTime = 10,
			Fact = "NASA studies say long Moon missions may need habitats covered with Moon soil to protect the crew from radiation.",
			Pro = "Best protection from radiation.", Con = "Takes twice as long to build." },
	},
	eng = {
		{ Id = "sunny_ridge", Name = "SUNNY RIDGE", Dist = "Far", Offset = Vector3.new(90, 0, 60), PanelMult = 1.0, ReactorRadMult = 1.0, BuildTime = 5,
			Fact = "NASA's design for a reactor on the Moon places it at least 1 km away from the crew.",
			Pro = "Panels: full sunlight. Reactor: far from the crew, safe.", Con = "Far away, so repairs take a long walk." },
		{ Id = "next_lander", Name = "NEXT TO THE LANDER", Dist = "Near", Offset = Vector3.new(-32, 0, -26), PanelMult = 0.7, ReactorRadMult = 1.5, BuildTime = 5,
			Fact = "At the Moon's south pole the Sun stays just above or below the horizon, so even small objects cast long shadows.",
			Pro = "Close and easy to check.", Con = "Panels lose 30% to shade. A reactor here gives everyone more radiation." },
		{ Id = "rock_wall", Name = "BEHIND A ROCK WALL", Dist = "Medium", Offset = Vector3.new(-50, 0, -50), PanelMult = 0.85, ReactorRadMult = 1.0, BuildTime = 5,
			Fact = "A NASA study found that the Moon's own hills and crater walls block part of the radiation.",
			Pro = "Best place for a reactor: the rock blocks radiation.", Con = "Panels lose 15% to shade." },
	},
	life = {
		{ Id = "inside_lander", Name = "INSIDE THE LANDER", Dist = "Near", Offset = Vector3.new(0, 0, 8), BuildTime = 5,
			Fact = "On the ISS, water is even collected from the crew's breath and sweat in the cabin air.",
			Pro = "Protected, no walking. Best spot for tanks.", Con = "Machines that use ice or soil must be fed by hand." },
		{ Id = "next_habitat", Name = "NEXT TO THE HABITAT", Dist = "Medium", Offset = Vector3.new(165, 0, 20), BuildTime = 5,
			Fact = "On the ISS, oxygen making and water recycling sit in the same module, Tranquility, added in 2010.",
			Pro = "Refill station right next to the base.", Con = "Nothing special." },
		{ Id = "ice_edge", Name = "ICE CRATER EDGE", Dist = "Far", Offset = Vector3.new(-90, 0, 36), TankWaterPenalty = 10, BuildTime = 5,
			Fact = "In 2009 NASA's LCROSS hit Cabeus, a shadowed crater near the south pole, and found water.",
			Pro = "Machines get ice and soil directly.", Con = "Long walks for repairs. Bad spot for tanks." },
	},
	bot = {
		{ Id = "inside_habitat", Name = "INSIDE THE HABITAT", Dist = "Near", Offset = Vector3.new(130, 0, 40), Trays = 2, ExtraEnergy = 0, BuildTime = 5,
			Fact = "NASA's Veggie garden has grown plants inside the ISS since 2014.",
			Pro = "Safe and warm.", Con = "Only 2 growing trays." },
		{ Id = "attached_module", Name = "ATTACHED MODULE", Dist = "Near", Offset = Vector3.new(45, 0, 130), Trays = 4, ExtraEnergy = 10, BuildTime = 5,
			Fact = "Since 2017 the ISS has the Advanced Plant Habitat, a closed, automated growth chamber for plants.",
			Pro = "4 growing trays.", Con = "Uses more energy." },
		{ Id = "inflatable", Name = "INFLATABLE OUTSIDE", Dist = "Medium", Offset = Vector3.new(180, 0, -70), Trays = 6, ExtraEnergy = 15, FreezeRisk = true, BuildTime = 5,
			Fact = "An expandable module called BEAM was attached to the ISS in April 2016.",
			Pro = "6 growing trays. Moon soil right outside.", Con = "It can freeze at night." },
	},
}
Config.SpotRadius = 8 -- radio del círculo que abre la tabla al llegar
Config.MoveDamageChance = { 0.20, 0.40, 0.60 } -- 1.ª, 2.ª, 3.ª o más veces que se mueve

Config.PhaseFacts = {
	Damaged = "On Apollo 17 in 1972, the astronauts had to repair a fender of their Moon rover. They made a new one from spare maps, clamps and duct tape.",
	Tilted = "In March 2025 the Athena lander came down on its side in a crater near the Moon's south pole. Its mission ended in less than a day.",
}

---------------------------------------------------------------------
-- FASE 2: MISIONES (todo es mantener E; ProximityPrompt.HoldDuration)
---------------------------------------------------------------------
Config.PromptDistance = 8
Config.RepairHold = 10

Config.Missions = {
	cap = {
		Intro = "Place 3 landing beacons so the cargo ship can land.",
		List = "CAPTAIN — Place landing beacons (%d/%d)",
		Prompt = "Hold E to place beacon", Hold = 4, Count = 3,
		BeaconRadius = 24, -- las 3 balizas quedan a 24 studs de la zona de carga (antes 11, fijo en Missions)
		BaseDistance = { open_field = 25, half_buried = 35, crater_wall = 45 },
		ShipAdjust = { light = -10, cargo = 0, starship = 10 },
		Done = "LANDING ZONE READY",
		Fact = "In March 2025 the Athena lander came down on its side in a crater near the Moon's south pole. Its mission ended in less than a day.",
	},
	eng = {
		-- Puntos según el sol del sitio; tarea según la fuente traída
		CountBySite = { ridge = 1, shackleton = 1, malapert = 1, nobile = 2, faustini = 3 },
		DistanceBySpot = { next_lander = 15, rock_wall = 45, sunny_ridge = 80 },
		Hold = 5,
		List = "ENGINEER — Get ready for the shadow (%d/%d)",
		Done = "READY FOR THE SHADOW",
		ByOption = {
			panels = { Intro = "Tilt your solar panels toward the Sun.", Prompt = "Hold E to tilt the panel",
				Fact = "At the Moon's south pole the Sun stays just above or below the horizon, so even small objects cast long shadows." },
			panels_bat = { Intro = "Check your batteries.", Prompt = "Hold E to check the battery",
				Fact = "Every time the ISS passes through Earth's shadow, its batteries keep the power on." },
			reactor = { Intro = "Check the reactor radiators.", Prompt = "Hold E to check the radiator",
				Fact = "NASA says fission power can keep a Moon base running through the lunar night, which lasts about two Earth weeks." },
		},
	},
	life = {
		List = "LIFE SUPPORT — Service your machine (%d/%d)",
		Done = "MACHINE AT 100%",
		IceDistance = { inside_lander = 70, next_habitat = 45, ice_edge = 8 },
		MalapertExtra = 30,
		ByOption = {
			recycler = { Intro = "Change the recycler filters.", Count = 3, Hold = 4, Prompt = "Hold E to change the filter",
				Fact = "On the ISS, water is even collected from the crew's breath and sweat in the cabin air." },
			electrolyzer = { Intro = "Connect the ice hose.", Count = 2, Hold = 5, Prompt = "Hold E to drill the ice", Prompt2 = "Hold E to connect the hose",
				Fact = "On the ISS it splits water, and the oxygen goes into the cabin air for the crew." },
			o2plant = { Intro = "Connect the regolith hose.", Count = 2, Hold = 5, Prompt = "Hold E to dig regolith", Prompt2 = "Hold E to connect the hose",
				Fact = "In 2023 NASA heated fake Moon soil with a powerful laser and pulled oxygen out of it." },
			tanks = { Intro = "Check the tank valves.", Count = 3, Hold = 3, Prompt = "Hold E to check the valve",
				Fact = "The longest Apollo visit to the Moon, Apollo 17 in 1972, lasted only 75 hours." },
		},
	},
	bot = {
		Done = "ALL TRAYS PLANTED",
		DoneFood = "FOOD COUNTED",
		ByOption = {
			hydroponics = { Intro = "Plant seeds in each glowing tray.", Hold = 3, Prompt = "Hold E to plant seeds", List = "BOTANIST — Plant the trays (%d/%d)",
				Fact = "On August 10, 2015, astronauts on the ISS ate red romaine lettuce grown in space." },
			regolith_kit = { Intro = "Plant seeds in each glowing tray.", Hold = 5, Prompt = "Hold E to plant seeds", List = "BOTANIST — Plant the trays (%d/%d)",
				Fact = "In 2022 scientists grew plants in real Moon soil from Apollo 11, 12 and 17. They grew more slowly and had stunted roots." },
			packaged = { Intro = "Count your food crates.", Hold = 3, Count = 3, Prompt = "Hold E to count", List = "BOTANIST — Count the food crates (%d/%d)",
				Fact = "NASA wants food for long missions to stay safe and tasty for up to five years." },
		},
	},
}

-- Efecto si un objeto dañado no se repara (toda la Fase 3)
Config.DamageEffects = {
	cap = { RadMult = 2 },
	eng = { EnergyMult = 0.8 },
	life = { MachineMult = 0.5, TankWaterPenalty = 10 },
	bot = { TraysLost = 1 },
}

---------------------------------------------------------------------
-- ENERGÍA (por día)
---------------------------------------------------------------------
Config.Energy = {
	ReactorOutput = 80,
	DamagedMult = 0.8,
	Demand = {
		habitat = 20, recycler = 25, electrolyzer = 15, o2plant = 40, tanks = 0,
		hydroponics = 15, regolith_kit = 5, packaged = 0,
	},
}

---------------------------------------------------------------------
-- FASE 3: SOBREVIVIR (PDF Fase 3). Números iniciales: se ajustan con las pruebas.
---------------------------------------------------------------------
Config.Phase3 = {
	Days = 7,
	DayLength = 120, -- 2 min por día
	DayIntro = 3, -- aviso al empezar el día
	CargoDay = 4, -- llega la nave de carga si hay 3 balizas
	CargoBonus = 15, -- +15 % a la reserva de O2 y agua
	EmergencyWindow = { 20, 80 }, -- segundo del día en que aparece
	ChooseTime = 20,
	ExecuteTime = 40,
	ResultToast = 4,
	LightTime = 3,
	RescueTime = 12,
}

-- Barras personales (vale para fases 1, 2 y 3)
Config.BarRates = {
	O2Inside = 100 / 360, -- % por segundo dentro de la nave o del hábitat (6 min)
	O2Outside = 100 / 180, -- afuera (3 min)
	WaterInside = 100 / 360,
	WaterOutside = 100 / 180,
	RadOutsidePerMin = 4, -- × multiplicador
	RadLanderPerMin = 1, -- × multiplicador
	RadHabitatPerMin = -2, -- baja dentro del hábitat (salvo apagón del hábitat)
	Rad100O2Mult = 2.5, -- con radiación al 100 % el O2 baja 2,5 veces más rápido
	RefillPerSec = 10, -- % por segundo en la estación de recarga
	NoReactorNearMult = 1.5, -- reactor junto a la nave
	BlackoutHabitatMult = 2,
	EarlyMult = 0.5, -- en las fases 1 y 2 el oxígeno y el agua bajan a la mitad (hay más que hacer afuera)
	LowWarn = 25, -- aviso de barra baja
}

-- Reserva de la base (compartida). Recargar 1 % de la barra gasta RefillCost % de la reserva.
Config.Reserve = {
	RefillCost = 0.35,
	-- 16-nov (ajuste tras simular las combinaciones extremas del PDF Fase 3, cap. 10): la reserva es una sola
	-- para todo el equipo, así que con más jugadores se vaciaba mucho antes. Con 0,35 fijo, "tanques + balizas"
	-- perdía siempre con 2 a 4 jugadores (el PDF dice que la nave del día 4 debe salvarlos). Costo según
	-- cuántos jugadores hay en el servidor (1, 2, 3, 4):
	RefillCostByPlayers = { 0.35, 0.30, 0.25, 0.20 },
	Machines = {
		recycler = { Start = 50, O2 = 45, Water = 55 },
		electrolyzer = { Start = 70, O2 = 50, Water = 20 },
		o2plant = { Start = 30, O2 = 60, Water = 0 },
		tanks = { Start = 100, O2 = 0, Water = 0 },
	},
	NoMissionMult = 0.5, -- sin la misión de la Fase 2: produce la mitad
	DamagedMult = 0.5, -- máquina dañada: otra mitad
	HarvestO2 = 2, -- cada cosecha suma +2 % de O2 a la reserva
}

Config.Food = {
	Start = { regolith_kit = 2, hydroponics = 4, packaged = 7 },
	CountedBonus = 1, -- +1 día si se contaron las cajas en la Fase 2
	PerDay = 1,
	Harvest = 0.5,
	HungrySpeed = 10, -- con comida en 0 todos caminan a 10
}

Config.Harvest = {
	GrowTime = 150, -- 2,5 min
	Hold = 3,
	RegolithFirstMult = 2, -- primera cosecha con kit de regolito tarda el doble
}

-- Apagones por turnos si EnergyUsed > EnergyMade. (El PDF deja vacío el 2.º turno: PREGUNTAR A LETICIA)
Config.BlackoutOrder = { "greenhouse", "machine", "habitat" }
Config.BlackoutNames = { greenhouse = "greenhouse", machine = "life support machine", habitat = "habitat" }

Config.Text3 = {
	Day = "DAY %d / 7",
	DayStart = "DAY %d",
	CargoLanding = "DAY %d — Cargo ship landing!",
	CargoLanded = "CARGO SHIP LANDED! +15% oxygen and water",
	CargoFailed = "CARGO SHIP COULD NOT LAND",
	Blackout = "BLACKOUT: %s is off today",
	Food = "FOOD: %.1f days",
	ReserveO2 = "BASE OXYGEN: %d%%",
	ReserveWater = "BASE WATER: %d%%",
	Hungry = "NO FOOD! Everyone moves slower.",
	ReserveEmpty = "The base reserve is empty!",
	Refill = "Hold E to melt ice: refill air + water",
	Harvest = "Hold E to harvest",
	PickBelt = "Hold E to pick up %s's belt",
	Day7Complete = "DAY 7 COMPLETE",
	ShipComing = "A ship is coming to take you home.",
	MissionComplete = "MISSION COMPLETE",
	Survived7 = "Your base survived 7 days on the Moon",
	SurvivedN = "Your crew survived %d of 7 days",
	Alive = "ALIVE",
	Lost = "LOST",
	WhatHelped = "WHAT HELPED YOUR CREW",
	PlayAgain = "PLAY AGAIN",
	Protected = "PROTECTED",
	Needs = "Needs: %s",
	LowO2 = "LOW OXYGEN! Go back to the lander to refill.",
	LowWater = "LOW WATER! Go back to the lander to refill.",
	DeadTitle = "YOU RAN OUT OF %s",
	DeadSub = "You are now watching your crew. Click to switch.",
	CrewLost = "Your whole crew was lost.",
	-- Por qué moriste / por qué perdieron (se arma en Bars al morir y en la pantalla final)
	WhyOutside = "You were outside the base: air and water drop 2× faster out there.",
	WhyLander = "You were in the lander: radiation still climbs slowly in there.",
	WhyRad = "Your radiation reached 100%: oxygen drops 2.5× faster.",
	WhyCO2 = "High CO₂ in the base made everyone's oxygen drop faster.",
	WhyReserveO2 = "The base oxygen reserve was empty, so the lander could not refill you.",
	WhyReserveWater = "The base water reserve was empty, so the lander could not refill you.",
	WhyLastRefill = "Your last refill at the lander was %d s ago.",
	WhyNeverRefill = "You never refilled at the lander.",
	WhyNoWater = "You went %d s without water.",
	DeathTip = "TIP: when a bar gets low, go back to the lander and hold E to refill.",
	WhyLostTitle = "WHY YOU LOST",
	WhyPlayer = "• %s ran out of %s. %s",
	WhyTeamReserve = "✗ The base reserve ran out of %s.",
	WhyTeamFood = "✗ The food ran out, so everyone moved slower.",
}

---------------------------------------------------------------------
-- FASE 3: TAREAS DIARIAS (mantenimiento real; una por rol y por día; cualquiera puede ayudar)
---------------------------------------------------------------------
Config.DailyTasks = {
	Title = "TODAY'S TASKS",
	cap = {
		Name = "Check the hatch seals", Prompt = "Hold E to check the seals", Hold = 4,
		RadDrop = 10, -- −10 de radiación para todos los vivos
		Done = "SEALS CHECKED! Less dust and radiation inside.",
		Fact = "On the Apollo missions, Moon dust stuck to everything and wore down the astronauts' suits and seals.",
	},
	eng = {
		Name = "Clean the dust off the panels", Prompt = "Hold E to clean the panels", Hold = 5,
		NameReactor = "Clean the reactor radiators", PromptReactor = "Hold E to clean the radiators",
		Bonus = 10, -- +10 de energía producida el resto del día
		Done = "CLEAN! Your base makes more power today.",
		Fact = "Dust on solar panels blocks sunlight, so they make less power. On Mars, gusts of wind sometimes cleaned the panels of NASA's rovers.",
	},
	life = {
		Name = "Bring 2 ice blocks to the machine", PromptIce = "Hold E to cut an ice block", PromptLoad = "Hold E to load the ice",
		Hold = 2, Count = 2,
		Reserve = 5, -- +5 % de oxígeno y agua de la base por bloque
		Carrying = "You are carrying ice. Take it to the machine!",
		Done = "ICE LOADED! More air and water for the base.",
		Fact = "Water ice in the dark craters of the Moon's south pole could give astronauts drinking water and oxygen.",
	},
	bot = {
		Name = "Water the plants", Prompt = "Hold E to water the trays", Hold = 4,
		NamePackaged = "Check the food crates", PromptPackaged = "Hold E to check the crates",
		GrowBoost = 30, -- −30 s de crecimiento a cada bandeja
		FoodBonus = 0.25, -- con comida empacada: +0,25 días
		Done = "DONE! Your plants grow faster today.",
		DonePackaged = "CHECKED! You found some extra food.",
		Fact = "NASA's Veggie garden grows plants in small pillows with soil and fertilizer. Astronauts water them by hand.",
	},
}

-- Aplastón (SO_Stomp, idea de Leticia + Isaac): caer de un salto lunar encima de otro lo deja
-- tumbado y aturdido unos segundos. No quita oxígeno, agua ni vida: es solo comedia.
Config.Stomp = {
	Enabled = true, -- false = apagado del todo
	MinFallSpeed = 12, -- studs/s cayendo para que cuente como aplastón (no al caminar)
	Radius = 2.6, -- distancia horizontal máxima entre los dos (studs)
	MinAbove = 2, -- el que cae tiene que estar por encima de la cabeza: entre MinAbove
	MaxAbove = 6.5, -- y MaxAbove studs sobre la cintura del otro
	StunTime = 2, -- segundos tumbado
	ImmuneTime = 5, -- segundos sin poder ser aplastado otra vez después de levantarse
	Bounce = 45, -- velocidad hacia arriba del que cae encima (rebote)
	Sound = "rbxasset://sounds/uuhhh.mp3",
	SoundPitch = 1.6,
	Text = "%s flattened %s!", -- jugador que cae, jugador aplastado
	-- Dato real (solo en el primer aplastón de la partida). Fuente: NASA, Apollo Lunar Surface Journal,
	-- "Working on the Moon: Grab, Kneel, Fall, Rise" (ver docs/06-fuentes.md)
	Fact = "Real fact: Apollo 16 astronauts fell 12 times on the Moon. No one got hurt: their soft suits were forgiving.",
}

-- Easter eggs del Apolo (SO_EasterEggs): objetos pequeños en el mapa lunar SIN cartel, SIN aviso y SIN texto.
-- Quien sabe lo que son se acerca y presiona E (prompt invisible) y se recrea el experimento real:
--   hammer = martillo y pluma suben y caen juntos (Apolo 15, 1971; Galileo).
--   mirror = un pulso de láser verde viaja de la Tierra al reflector y vuelve (Apolo 11, 14 y 15).
-- Sin logos, banderas ni insignias (regla Space Apps). Offset = posición relativa a la nave (studs).
-- Fuentes en docs/06-fuentes.md.
Config.EasterEggs = {
	Distance = 4, -- a cuántos studs funciona la E (hay que estar encima)
	StudMeters = 0.28, -- metros por stud (para que las caídas y el láser tengan los tiempos reales)
	MoonG = 1.62, -- gravedad lunar real en m/s² (NASA)
	Hammer = {
		Offset = Vector3.new(-11, 0, 9),
		ArmTime = 0.6, -- segundos para levantar los brazos
		PickTime = 0.7, -- segundos para que martillo y pluma lleguen a las manos
		HoldTime = 0.9, -- segundos quietos en las manos antes de soltarlos
		RestTime = 6, -- segundos en el suelo antes de volver a su sitio
		Hands = Vector3.new(1.05, 1.0, -1.75), -- manos con los brazos al frente, respecto al torso (medido en Play)
		Scale = 1.4, -- tamaño respecto al real (martillo ~40 cm, pluma ~30 cm) para que se vean
		DustCount = 14, -- granos de polvo al caer (vuelan en parábola: sin aire no hay nube)
	},
	Mirror = {
		Offset = Vector3.new(18, 0, -12),
		LightTrip = 1.28, -- segundos que tarda la luz de la Tierra a la Luna (384.400 km / 300.000 km/s)
		Color = Color3.fromHex("3CFF6A"), -- verde: el observatorio APOLLO usa láser verde de 532 nm
		Grid = 10, -- 10 × 10 = 100 prismas, como el reflector del Apolo 11
		SpotRadius = 7, -- mancha del láser en el suelo (de verdad mide varios km al llegar a la Luna)
	},
}

-- Cielo lunar (ZoneLighting dibuja la Tierra; SO_EggsClient la usa como origen del láser).
-- Desde el polo sur la Tierra queda casi pegada al horizonte. Tamaño real visto desde la Luna: ~1,9°
-- (radio / distancia = tan(0,95°) → 20 / 1200).
Config.MoonSky = {
	EarthDir = Vector3.new(0.36, 0.1, 0.93).Unit, -- ~6° sobre el horizonte
	EarthDist = 1200, -- studs desde la cámara (la Tierra sigue a la cámara: siempre "infinitamente" lejos)
	EarthRadius = 20,
}

-- Carteles flotantes de la Luna (SO_WorldLabels): menos intrusivos, como en los juegos buenos de Roblox
Config.WorldLabels = {
	PixelsPerStud = 32, -- rótulos de información: 120 px de ancho → 3,75 studs (letrero real en el mundo)
	Near = 22, -- hasta aquí se ven normal (studs)
	Far = 40, -- desde Near se desvanecen; más lejos no se ven
	NavNear = 25, -- marcadores de navegación (AlwaysOnTop): tamaño completo hasta aquí
	NavFar = 90, -- a esta distancia ya están en su tamaño mínimo
	NavMinScale = 0.5, -- tamaño mínimo de lejos (50 %)
	NavFarFade = 0.35, -- de lejos se aclaran un poco (0 = igual, 1 = invisibles)
	NavMaxDistance = 260, -- más lejos ni se dibujan
	MinBackground = 0.3, -- fondo al menos 30 % transparente
}

-- "Did you know?" en la pantalla entre la Fase 2 y la 3 y en la pantalla final (SO_DidYouKnow). Solo datos con fuente NASA.
Config.DidYouKnow = {
	Title = "DID YOU KNOW?",
	Facts = {
		"Apollo 17 astronauts fixed their broken Moon buggy fender with four maps and tape.",
		"Apollo astronauts brought back 382 kg of Moon rocks and soil.",
		"The Moon always shows Earth the same face: it spins once for every trip around us.",
		"You could fit about 30 Earths between Earth and the Moon.",
		"In sunlight the Moon reaches about 127 °C. In darkness it drops to about -173 °C.",
		"Inside Shackleton crater, at the Moon's south pole, the Sun never shines.",
		"In 2026, the Artemis II crew flew farther from Earth than any humans before them.",
		"In 2020, scientists confirmed water molecules on the sunlit Moon, in Clavius crater.",
	},
}

-- "What helped your crew" (tabla 9 del PDF, en este orden)
Config.Helped = {
	{ Id = "half_buried", Text = "Your half-buried habitat blocked radiation." },
	{ Id = "cargo", Text = "Your beacons brought a cargo ship full of supplies." },
	{ Id = "power", Text = "Your base always had enough power." },
	{ Id = "recycler", Text = "Your recycler saved almost all of your water." },
	{ Id = "trays", Text = "Your greenhouse fed the crew." },
	{ Id = "protected", Text = "Your Engineer was ready for the emergency." },
	{ Id = "repaired", Text = "You repaired everything that broke." },
	{ Id = "smart", Text = "You made smart choices in emergencies." },
}

---------------------------------------------------------------------
-- DECORACIÓN DE LOS CUARTOS (Fase 0): 2 pósters por rol { título, línea 1, línea 2 } con datos reales
---------------------------------------------------------------------
Config.Decor = {
	Posters = {
		cap = {
			{ "MOON LANDINGS", "Apollo 11 landed on July 20, 1969.", "Only 12 people have walked on the Moon." },
			{ "WEIGHT MATTERS", "A heavier ship needs more fuel.", "Pack only what your crew needs." },
		},
		eng = {
			{ "SOLAR POWER", "Solar panels need sunlight to work.", "At the south pole the Sun stays low." },
			{ "FISSION POWER", "NASA tested the KRUSTY reactor in 2018.", "It can keep a base on through the lunar night." },
		},
		life = {
			{ "AIR", "The ISS splits water to make oxygen.", "Filters remove the CO₂ we breathe out." },
			{ "WATER", "The ISS recovers 98% of its water.", "Even breath and sweat are recycled." },
		},
		bot = {
			{ "SPACE FARMING", "ISS astronauts ate space lettuce in 2015.", "Plants also make a little oxygen." },
			{ "MOON SOIL", "In 2022 plants grew in real Moon soil.", "They grew slower than on Earth." },
		},
	},
}

---------------------------------------------------------------------
-- ZONAS (un place, zonas lejos entre sí)
---------------------------------------------------------------------
Config.Zones = {
	Lobby = Vector3.new(-3000, 0, 0),
	Earth = Vector3.new(0, 0, 0),
	Moon = Vector3.new(3000, 0, 0),
	Interior = Vector3.new(6000, 0, 0),
}

---------------------------------------------------------------------
-- DEPURACIÓN (solo pruebas)
---------------------------------------------------------------------
Config.Debug = {
	StartPhase = nil :: string?, -- "Phase0", "SiteSelect", "Placement", "Phase2", "Phase3" para saltar directo
	FastTimers = false, -- true = relojes de espera a 10 s
	-- Elecciones falsas para saltar directo a una fase sin jugar las anteriores
	FakeState = {
		Choice_cap = "cargo", Choice_eng = "panels_bat", Choice_life = "recycler", Choice_bot = "hydroponics",
		Site = "shackleton",
		Spot_cap = "crater_wall", Spot_eng = "sunny_ridge", Spot_life = "next_habitat", Spot_bot = "attached_module",
		MissionComplete_cap = true, MissionComplete_eng = true, MissionComplete_life = true, MissionComplete_bot = true,
		StartO2 = 100, StartWater = 100,
	},
}

-- El Sol de verdad (SO_LiveSpaceWeather): datos en vivo de NASA DONKI (CCMC, sin clave)
Config.LiveSpaceWeather = {
	Enabled = true,
	BaseUrl = "https://ccmc.gsfc.nasa.gov/DONKI/WS/get",
	Days = 30, -- días hacia atrás que se miran (DONKI acepta hasta 60)
	MediumScore = 2, HighScore = 6, -- puntaje semanal: llamarada M/X = 2, CME = 1, tormenta geomagnética = 3, SEP = 3
	Mult = { LOW = 0.8, MEDIUM = 1, HIGH = 1.5 }, -- multiplica la probabilidad de flare, cme, geostorm y sep
	Text = {
		Summary = "REAL SUN (NASA DONKI, live): %s · %d flares in the last %d days",
		Level = { LOW = "calm", MEDIUM = "active", HIGH = "VERY ACTIVE" },
		Saved = "REAL SUN: saved NASA DONKI data (no live connection)",
		SavedPrefix = "SAVED NASA DATA · ",
		Flare = "LIVE NASA DONKI · Latest real flare: %s on %s (%d flares in %d days, strongest %s)",
		Cme = "LIVE NASA DONKI · Latest real CME: %s (%d in the last %d days)",
		Gst = "LIVE NASA DONKI · Latest real geomagnetic storm: %s, Kp %g",
		Sep = "LIVE NASA DONKI · Latest real solar particle event: %s",
	},
	-- Eventos reales guardados (consultados el 15-nov-2026) por si no hay conexión
	SavedEvents = {
		flare = "M1.7 flare on Nov 11, 2026",
		cme = "CME on Nov 1, 2026",
		geostorm = "Kp 6 storm on Oct 31, 2026",
		sep = "solar particle events in Aug 1972, between Apollo 16 and 17",
	},
}

-- Sala de llegada de la Fase 0 (SO_Lobby)
Config.Lobby = {
	Eyebrow = "SPACE CENTER · CREW READY ROOM",
	Title = "EVERY CHOICE COUNTS: MOON BASE",
	Line1 = "Welcome, junior astronauts!",
	Line2 = "Walk down the hall and visit your role's room.",
}

-- Retraso de comunicación (CommsDelay): la luz tarda unos 1,3 s de la Luna a la Tierra (384.400 km).
-- Cada día llega un mensaje de Control de Misión y cualquiera puede llamar desde la antena.
Config.Comms = {
	OneWay = 1.3, -- segundos de ida (ida y vuelta = 2,6 s)
	DailyAt = 30, -- segundo del día en que llega el mensaje diario
	Cooldown = 15, -- segundos entre llamadas de un mismo jugador
	Prompt = "Hold F to call Mission Control", -- tecla F: al lado puede haber otro prompt con E
	Object = "Antenna",
	Calling = "Calling Earth... the signal needs %.1f s to get there (384,400 km).",
	Incoming = "Message from Earth incoming... it left Earth %.1f s ago.",
	Reply = "MISSION CONTROL (%.1f s round trip): %s",
	NoSignal = "NO SIGNAL: the solar flare is blocking the radio. Fix the antenna first!",
	Messages = {
		"Good morning, crew! We can see your base on our screens.",
		"Keep the solar panels clean. Moon dust sticks to everything!",
		"Ice in the dark craters can become air, water and even rocket fuel.",
		"Space weather update: we are watching the Sun for you. We will warn you about flares.",
		"Your words took 1.3 seconds to reach us. From Mars they could take up to 22 minutes!",
		"Remember: on the Moon one full day and night lasts about 29.5 Earth days.",
		"Great teamwork! Every choice you make keeps the crew alive.",
	},
}

-- Escena dentro de la cápsula (SO_Cockpit): segundos de cada toma y textos
Config.Cockpit = {
	LaunchTime = 5, -- cuenta regresiva y temblor antes del despegue visto desde afuera
	PovShare = 0.55, -- parte de cada toma en primera persona (desde el casco del jugador)
	LandingTime = 3, -- la Luna se acerca por la ventana antes de la llegada vista desde afuera
	ReturnTime = 4.5, -- regreso a casa al final de "Rescue"
	ReturnAt = 6.5, -- segundo de "Rescue" en que empieza (dura 12 s en total)
	Text = { Liftoff = "LIFTOFF!", Landing = "LANDING BURN", Return = "HEADING HOME" },
}

-- Monitor de ritmo cardíaco del cuarto de Soporte Vital (Fase 0): una línea por rol
Config.HeartMonitor = {
	Title = "CREW HEART RATE",
	BaseBPM = { cap = 72, eng = 68, life = 76, bot = 70 }, -- reposo normal: 60-100 lpm
	Drift = 4, -- variación lenta ± lpm
	SweepSeconds = 3, -- lo que tarda el barrido en cruzar la pantalla
	Points = 90, -- puntos por línea
	-- Un solo bip suave (el latido del propio jugador, o el primero), y solo dentro del cuarto
	Beep = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.06, RoomPadding = 1,
		Pitch = { cap = 1.0, eng = 1.12, life = 1.25, bot = 1.4 } },
}

-- Taquillas de traje de la Fase 0 (SO_Lockers): una por cuarto, con un maniquí vestido como los jugadores
Config.Lockers = {
	Heights = { 7, 6.3, 5.7 }, -- alto de la taquilla: se usa el más alto que no tape nada del cuarto
	Width = 5.2, -- ancho (un avatar con los brazos mide ~4)
	Depth = 3.4, -- fondo (cabe la mochila)
	InnerWidth = 0.8, -- fracción del ancho libre por dentro
	InnerDepth = 0.75, -- fracción del fondo libre por dentro
	InnerHeight = 0.76, -- fracción del alto libre por dentro (del piso a la barra)
	MannequinHeight = 5.4, -- alto máximo del maniquí
	InnerFloor = 0.065, -- altura del piso interior (fracción del alto)
	WallThick = 0.5, -- media pared (las paredes van centradas en el borde del piso)
	WallGap = 0.15, -- separación de la cara de la pared
	DoorGap = 1.5, -- separación de la pared de la puerta (en las paredes laterales)
	FrontClear = 0.5, -- espacio libre delante para no estorbar el paso
	TopClear = 0.6, -- espacio libre encima (pantallas y luces de la pared)
	SkinThick = 0.3, SkinLength = 8, -- papel tapiz: láminas más finas que esto y más largas que esto no cuentan
	TinySize = 0.8, -- piezas más chicas que esto (estrellitas pintadas) no cuentan
	BackOffset = 0.25, -- maniquí corrido hacia el fondo
	SearchStep = 0.5, -- paso al buscar un hueco libre junto a la pared
	Movable = { "O2Tank", "TankStripe" }, -- adornos nuestros que se pueden quitar si el cuarto está lleno
	SuitColor = Color3.fromHex("F2F2F5"),
	-- Colores de la taquilla (el importador de Roblox los pierde): pieza = { color, material, transparencia }
	Look = {
		Casillero = { "3F2173" }, Puerta = { "B8A8F2" }, Bisagra = { "B8A8F2" }, Suelo = { "B8A8F2" },
		Barra = { "B8A8F2" }, Nervio = { "B8A8F2" }, Tirador = { "FFD838" }, Rejilla = { "272745" },
		Cristal = { "DAEDFF", "Glass", 0.75 },
		Luz = { "59FF95", "Neon" }, Luz2 = { "FFE159", "Neon" }, Luz3 = { "00E7FF", "Neon" }, Luz4 = { "FF59E7", "Neon" },
	},
}

return Config
