-- Phase1Config (ModuleScript) -> ReplicatedStorage.Phase1Config
-- Números y textos de la Fase 1 y de las pantallas de Título y Roles que TODAVÍA NO están en Config.
-- Se dejaron aparte para no tocar Config (dueño: Isaac). Isaac puede moverlos a Config cuando quiera:
-- solo hay que cambiar el require en Phase1Manager, Placement, Phase1UI y MenuScreens.
-- Los textos que ve el jugador van en INGLÉS.

local Phase1Config = {}

-- Salto en la Luna: más o menos el doble de lo normal (7,2 studs en la Tierra)
Phase1Config.MoonJumpHeight = 14.4
Phase1Config.EarthJumpHeight = 7.2

-- Aterrizaje
Phase1Config.LandingAltitudeKm = 15 -- altura desde la que "baja" la nave en la pantalla

-- Colocación
Phase1Config.PlaceHold = 0 -- pulsar E una vez
Phase1Config.PickUpHold = 1 -- mantener E 1 s para recoger
Phase1Config.WaitBuildersMax = 10 -- al acabar el tiempo, espera como máximo 10 s a quien esté martillando
Phase1Config.SpotSize = Vector3.new(1, 10, 10) -- cilindro plano (alto, diámetro, diámetro)
Phase1Config.BuildClearance = 4 -- al construir, el astronauta queda 4 studs fuera del borde del objeto
-- Dirección del Sol en la Luna (la misma que usa ZoneLighting): los paneles solares se colocan mirándolo
Phase1Config.SunDirection = Vector3.new(-0.78, 0.07, -0.62)
Phase1Config.AllPlacedDelay = 10 -- con los 4 objetos colocados, 10 s más y se marca AllPlaced (fin de la colocación)

-- Recarga dentro de la nave (debajo del cuerpo, al final de la rampa)
Phase1Config.LanderRefillOffset = Vector3.new(0, 2.1, 1.5) -- desde el pivote de la nave
Phase1Config.LanderRefillHold = 2 -- segundos manteniendo E
-- [15-nov] Nave más grande con cuarto adentro (Fase 1) y base provisional (Fase 2 en adelante)
Phase1Config.ShipScale = 1.7 -- cuánto se agranda la nave elegida en la Luna
Phase1Config.ShipFarOffset = Vector3.new(25, 0, -80) -- a dónde se aleja la nave en la Fase 2 (desde su lugar)
Phase1Config.TempBaseOffset = Vector3.new(0, 0, -2) -- centro de la base provisional (desde el pivote de la nave)

-- Colores oscuros de cada rol (nombres en las tarjetas blancas)
Phase1Config.RoleDark = {
	cap = Color3.fromHex("B3240F"),
	eng = Color3.fromHex("8A5A00"),
	life = Color3.fromHex("1655C9"),
	bot = Color3.fromHex("137A47"),
}

Phase1Config.Text = {
	-- Pantalla de título
	PlayWaiting = "STARTING...",
	-- Pista en cada tarjeta de rol
	JoinHint = "Double-click to join",
	LeaveHint = "Double-click to leave",
	RolesReady = "READY ✓",
	RolesWaiting = "WAITING %d/%d",
	Phase0Ready = "SHIP READY ✓",

	-- Pantalla de roles
	Room = "Room: %s",

	-- Elección del sitio
	SiteEyebrow = "PHASE 1 · LANDING",
	SiteTitle = "CHOOSE WHERE TO LAND",
	Choose = "CHOOSE",
	Suggest = "SUGGEST THIS SITE",
	CaptainNote = "Use the arrows (or ← →) and press CHOOSE. The choice is final.",
	CrewNote = "Only the Captain moves the Moon and chooses. You can suggest the site on screen.",
	ScaleNote = "10 = best for your base (our team's study)",
	RoughWarn = "Rough ground: the ship may land tilted.",
	SuggestedBy = "Suggested by:",
	DidYouKnow = "DID YOU KNOW?",
	Suggests = "%s suggests %s",

	-- Aterrizaje
	LandingAt = "LANDING AT %s",
	Descending = "Descending to the lunar south pole…",
	Touchdown = "TOUCHDOWN!",
	TouchdownText = "You landed at %s. Get ready to build your base.",
	RoughTitle = "ROUGH LANDING!",
	RoughText = "The ship tilted. Repairs cost 5% oxygen.",

	-- Colocación
	PlaceYour = "PLACE YOUR %s",
	AllPlaced = "BASE READY · WAIT FOR YOUR CREW",
	PlaceHere = "Place here",
	PickUp = "Pick up",
	Building = "BUILDING...",
	RealFact = "Real fact:",
	Habitat = "HABITAT",
	FoodCrates = "FOOD CRATES",
	RampTitle = "YOUR BASE",
	NotPlaced = "not placed yet",
	BaseReadySoon = "Base ready! Phase 1 ends in %d seconds.",
	BaseNotReady = "Something was picked up. Place it again!",

	-- Recarga en la nave
	ShipRefill = "Hold E to refill air + water",
	ShipRefillObject = "Ship",
	ShipRefillSign = "AIR + WATER",
	ShipRefillFull = "Air and water are full!",
	TankO2Sign = "OXYGEN",
	TankWaterSign = "WATER",
	FillO2 = "Hold E to fill oxygen",
	FillWater = "Hold E to fill water",
	TankO2Object = "Oxygen tank",
	TankWaterObject = "Water tank",
	TankO2Full = "Oxygen full!",
	TankWaterFull = "Water full!",
	ShipRoomSign = "OXYGEN + WATER INSIDE",
	TempBaseSign = "BASE: OXYGEN + WATER",
	MachineRefillObject = "Life support machine",
	MachineRefillReady = "New refill station next to the life support machine!",
}

-- Textos de las pantallas de paso (Transitions) y del lanzamiento (Phase0HUD)
Phase1Config.Text2 = {
	-- Paso 0 -> 1
	YourCrewBrought = "YOUR CREW IS BRINGING",
	StartWith = "YOU START PHASE 1 WITH",
	Cargo = "CARGO: %d / %d",
	Oxygen = "OXYGEN",
	Water = "WATER",
	NextLanding = "Next: choose where to land on the Moon",

	-- Paso 1 -> 2
	YourBase = "YOUR BASE",
	LandedAt = "You landed at %s",
	DamagedTag = "DAMAGED",
	EnergyLine = "Energy: about %d per day",
	RadLine = "Radiation: x%s",
	ReactorNear = "(reactor next to the lander: x1.5 for everyone)",
	TraysLine = "Growing trays: %d",
	NoTrays = "Growing trays: none (packed food)",
	RepairsLine = "Repairs to do: %s",
	NoRepairs = "Repairs to do: none",
	ReadyContinue = "%d/%d ready · continues in %s",

	-- Lanzamiento (Fase 0)
	Phase0Top = "PREPARE THE SHIP   %s",
	LaunchBtn = "LAUNCH",
	WaitCaptain = "Waiting for the Captain to launch...",
	GoToButton = "Run to the red LAUNCH button in the control room!",
	LaunchSign = "LAUNCH",
	OnlyCaptain = "Only the CAPTAIN can launch.",
}

return Phase1Config
