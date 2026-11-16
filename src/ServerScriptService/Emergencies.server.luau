-- Emergencies (Script) -> ServerScriptService.Emergencies
-- Dueño: Isaac + Claude. Motor genérico de emergencias de la Fase 3 (PDF Fase 3, caps. 4 a 6).
-- Lee las emergencias de ReplicatedStorage.EmergencyData. Una sola función para todas.
-- Escribe: Emergency, EmergencyStage ("choose" | "execute" | "protected" | "result" | ""), EmergencyChoice,
--          EmergencyChooser, EmergencyLeft, EmergencyDisabled, EmergenciesSeen, EmergenciesSolved, AnswersA,
--          y los modificadores del día Mod_* (los leen Bars y Resources; se borran al empezar cada día).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local LIST = require(ReplicatedStorage:WaitForChild("EmergencyData"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local P3 = Config.Phase3

local site = workspace:WaitForChild("MoonSite")
local MODS = { "Mod_O2Mult", "Mod_RadOutMult", "Mod_HabitatNoDrop", "Mod_GreenhouseOff", "Mod_MachineOff",
	"Mod_ExtraEnergy", "Mod_TraysNoGrow", "Mod_SlowWalk", "Mod_MachineMult", "Mod_WalkMinus" } -- 15-nov: +2 (PDF Fase 3)
-- Efectos que duran más de un día: se borran al empezar una partida nueva (día 1) y al salir de la Fase 3
local LONG_MODS = { "MachineProdMult", "CargoDayOverride", "NextWalkMinus", "HasReadyTray" }

local byId = {}
for _, e in LIST do byId[e.Id] = e end

local lastId = ""
local quietStreak = 0
-- Para el día 7 (PDF 6.2): apagones y respuestas C por rol
local hadBlackout: { [string]: boolean } = {}
local answeredC: { [string]: boolean } = {}
local BLACKOUT_ROLE = { greenhouse = "bot", machine = "life", habitat = "cap" }
local forced: string? = nil
local answer: { letter: string, role: string }? = nil
local pointsFolder = Instance.new("Folder")
pointsFolder.Name = "EmergencyPoints"
pointsFolder.Parent = site

---------------------------------------------------------------------
-- Objetos animados de cada punto (pedido de Isaac 15-nov: "anima las emergencias como las misiones").
-- Mismo estilo que Missions: junto al disco aparece el objeto real y al terminar de mantener E se ve el trabajo.
---------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local METAL = Color3.fromHex("C9CCD8")
local DARK = Color3.fromHex("2B2F4A")
local UP = CFrame.Angles(0, 0, math.rad(90)) -- eje del cilindro vertical
local FWD = CFrame.Angles(0, math.rad(90), 0) -- eje del cilindro hacia el jugador

local function newPart(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = pointsFolder
	return p
end
local function cyl(name: string, length: number, diam: number, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
	local p = newPart(name, Vector3.new(length, diam, diam), cf, color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(name: string, d: number, pos: Vector3, color: Color3, mat: Enum.Material?): BasePart
	local p = newPart(name, Vector3.new(d, d, d), CFrame.new(pos), color, mat)
	p.Shape = Enum.PartType.Ball
	return p
end
local function tw(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?): Tween
	local x = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad), props)
	x:Play()
	return x
end
local function hinge(p: BasePart, pivot: CFrame, rot: CFrame, t: number): Tween
	return tw(p, t, { CFrame = pivot * rot * pivot:Inverse() * p.CFrame })
end
local function spin(p: BasePart, turns: number, t: number)
	task.spawn(function()
		local steps = math.max(1, math.floor(turns * 8))
		for _ = 1, steps do
			if not p.Parent then return end
			tw(p, t / steps, { CFrame = p.CFrame * CFrame.Angles(math.rad(45), 0, 0) }, Enum.EasingStyle.Linear).Completed:Wait()
		end
	end)
end
-- Gira varias piezas juntas alrededor de un eje (aspas de ventilador)
local function spinAround(parts: { BasePart }, pivot: CFrame, turns: number, t: number)
	task.spawn(function()
		local steps = math.max(1, math.floor(turns * 8))
		for _ = 1, steps do
			local last
			for _, p in parts do
				if p.Parent then last = tw(p, t / steps, { CFrame = pivot * CFrame.Angles(0, 0, math.rad(45)) * pivot:Inverse() * p.CFrame }, Enum.EasingStyle.Linear) end
			end
			if not last then return end
			last.Completed:Wait()
		end
	end)
end
local function statusLight(cf: CFrame, color: Color3?): BasePart
	local l = newPart("StatusLight", Vector3.new(0.45, 0.45, 0.45), cf, color or Config.Colors.Red, Enum.Material.Neon)
	l.Shape = Enum.PartType.Ball
	return l
end
local function lightOk(l: BasePart, final: Color3?)
	task.spawn(function()
		for _ = 1, 3 do
			l.Color = Color3.new(1, 1, 1); task.wait(0.15)
			l.Color = Config.Colors.Gold; task.wait(0.15)
		end
		l.Color = final or Config.Colors.Good
	end)
end
local function burst(at: BasePart, color: Color3, t: number, opts: { [string]: any }?)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.22, 0)
	e.Lifetime = NumberRange.new(0.4, 0.9)
	e.Speed = NumberRange.new(4, 8)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Rate = 50
	e.Acceleration = Vector3.new(0, -10, 0)
	if opts then for k, v in opts do (e :: any)[k] = v end end
	e.Parent = at
	task.delay(t, function()
		e.Enabled = false
		task.wait(1.2)
		e:Destroy()
	end)
end

-- Altura real del suelo. Afuera ignora los módulos (rayo desde arriba);
-- adentro del hábitat el rayo sale de poco más arriba para no chocar con el techo.
local function snap(pos: Vector3, indoor: boolean?): Vector3
	local params = RaycastParams.new()
	local ignore: { Instance } = { pointsFolder }
	if not indoor then
		for _, n in { "Placed", "Lander", "ChosenLander", "HabitatZone", "CargoZone", "SO_CommsAntenna" } do
			local x = site:FindFirstChild(n)
			if x then table.insert(ignore, x) end
		end
	end
	for _, p in Players:GetPlayers() do
		if p.Character then table.insert(ignore, p.Character) end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local from = indoor and 2.5 or 40
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + from, pos.Z), Vector3.new(0, -(from + 40), 0), params)
	return hit and Vector3.new(pos.X, hit.Position.Y + 0.6, pos.Z) or pos
end
-- Base del objeto: junto al punto, del lado contrario al centro, mirando al jugador (frente = -Z local)
local function baseAt(pos: Vector3, center: Vector3?, indoor: boolean?, dist: number?): CFrame
	local d = center and (pos - center) * Vector3.new(1, 0, 1) or Vector3.zero
	d = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 0, -1)
	local at = snap(pos + d * (dist or 2.8), indoor) - Vector3.new(0, 0.5, 0)
	return CFrame.lookAt(at, Vector3.new(pos.X, at.Y, pos.Z))
end

-- Antena (llamarada, A): caja de orientación con manivela; las barras de señal se encienden una a una
local function antennaProp(b: CFrame)
	newPart("TunerBox", Vector3.new(1.4, 1.8, 0.8), b * CFrame.new(0, 0.9, 0), DARK)
	local bars = {}
	for i = 1, 4 do
		local h = 0.2 + i * 0.15
		table.insert(bars, newPart("SignalBar", Vector3.new(0.18, h, 0.05), b * CFrame.new(-0.45 + i * 0.2, 1.25 + h / 2, -0.42), Color3.fromHex("3A3F5C"), Enum.Material.Neon))
	end
	local wheel = cyl("TunerCrank", 0.15, 0.7, b * CFrame.new(0, 0.7, -0.45) * FWD, Config.Colors.Gold)
	local light = statusLight(b * CFrame.new(0.5, 1.95, 0))
	return function()
		spin(wheel, 3, 2.4)
		for _, bar in bars do
			task.wait(0.55)
			tw(bar, 0.2, { Color = Config.Colors.Good })
		end
		burst(light, Config.Colors.Sky, 1.2, { LightEmission = 1, Acceleration = Vector3.zero, Speed = NumberRange.new(6, 9) })
		lightOk(light)
	end
end

-- Radio de la nave (llamarada, B): la pantalla pasa de rojo a amarillo (señal débil) y la antenita parpadea
local function radioProp(b: CFrame)
	newPart("RadioDesk", Vector3.new(2.2, 1.6, 1.1), b * CFrame.new(0, 0.8, 0), METAL, Enum.Material.Metal)
	newPart("RadioBody", Vector3.new(1.8, 0.9, 0.9), b * CFrame.new(0, 2.05, 0.05), DARK)
	local screen = newPart("RadioScreen", Vector3.new(0.9, 0.5, 0.05), b * CFrame.new(-0.3, 2.1, -0.42), Config.Colors.Red, Enum.Material.Neon)
	local knob = cyl("RadioKnob", 0.12, 0.35, b * CFrame.new(0.55, 2.05, -0.45) * FWD, METAL)
	newPart("RadioWhip", Vector3.new(0.06, 1.8, 0.06), b * CFrame.new(0.7, 3.4, 0.2), METAL, Enum.Material.Metal)
	local tip = newPart("RadioTip", Vector3.new(0.2, 0.2, 0.2), b * CFrame.new(0.7, 4.3, 0.2), Config.Colors.Red, Enum.Material.Neon)
	tip.Shape = Enum.PartType.Ball
	return function()
		spin(knob, 1.5, 1.2)
		task.wait(1.2)
		tw(screen, 0.4, { Color = Config.Colors.Gold })
		burst(tip, Config.Colors.Gold, 1, { LightEmission = 1, Acceleration = Vector3.zero, Speed = NumberRange.new(3, 5) })
		lightOk(tip, Config.Colors.Gold)
	end
end

-- Tablero eléctrico (eyección de masa coronal): se abre la puerta, saltan chispas y se baja la palanca
local function breakerProp(b: CFrame, letter: string)
	newPart("BreakerCabinet", Vector3.new(2, 2.8, 0.7), b * CFrame.new(0, 1.4, 0), DARK)
	newPart("BreakerBack", Vector3.new(1.7, 2.4, 0.05), b * CFrame.new(0, 1.4, -0.37), Color3.fromHex("111326"))
	local levers = {}
	for i, c in { Config.Colors.Good, Config.Colors.Sky } do
		local x = i == 1 and -0.4 or 0.4
		newPart("LeverTag", Vector3.new(0.5, 0.25, 0.04), b * CFrame.new(x, 2.15, -0.4), c, Enum.Material.Neon)
		levers[i] = newPart("Lever", Vector3.new(0.15, 0.8, 0.15), b * CFrame.new(x, 1.55, -0.45), METAL, Enum.Material.Metal)
	end
	local door = newPart("BreakerDoor", Vector3.new(1.9, 2.6, 0.08), b * CFrame.new(0, 1.4, -0.42), Color3.fromHex("4A4F6E"), Enum.Material.Metal)
	local light = statusLight(b * CFrame.new(0.7, 2.95, 0))
	return function()
		hinge(door, b * CFrame.new(-0.95, 1.4, -0.42), CFrame.Angles(0, math.rad(105), 0), 0.6)
		task.wait(0.6)
		burst(light, Config.Colors.Gold, 0.8, { LightEmission = 1, Speed = NumberRange.new(6, 10) })
		local lv = levers[letter == "B" and 2 or 1]
		local x = letter == "B" and 0.4 or -0.4
		hinge(lv, b * CFrame.new(x, 1.2, -0.45), CFrame.Angles(math.rad(-120), 0, 0), 0.5)
		task.wait(0.6)
		lightOk(light)
	end
end

-- Caja de repuestos (CO2, A paso 1): se abre la tapa y salen piezas para armar el filtro
local function partsProp(b: CFrame)
	newPart("PartsCrate", Vector3.new(2.2, 1.2, 1.4), b * CFrame.new(0, 0.6, 0), Color3.fromHex("E8A53B"))
	local lid = newPart("CrateLid", Vector3.new(2.3, 0.15, 1.5), b * CFrame.new(0, 1.28, 0), Color3.fromHex("C9832A"))
	local bits = {
		cyl("SparePipe", 1.2, 0.3, b * CFrame.new(-0.5, 0.9, 0), METAL, Enum.Material.Metal),
		newPart("SpareMesh", Vector3.new(0.7, 0.1, 0.7), b * CFrame.new(0.3, 0.9, 0), Color3.fromHex("ECE6CF"), Enum.Material.Fabric),
		newPart("DuctTape", Vector3.new(0.35, 0.35, 0.35), b * CFrame.new(0.7, 0.9, 0.2), Color3.fromHex("9EA3B5")),
	}
	return function()
		hinge(lid, b * CFrame.new(0, 1.28, 0.75), CFrame.Angles(math.rad(-100), 0, 0), 0.5)
		task.wait(0.5)
		for i, p in bits do
			tw(p, 0.5, { CFrame = p.CFrame + Vector3.new(0, 1.6 + i * 0.3, 0) }, Enum.EasingStyle.Back)
		end
		task.wait(1.5)
		for _, p in bits do tw(p, 0.6, { Transparency = 1 }) end
	end
end

-- Filtro (CO2): sale el cartucho saturado y entra uno nuevo (o uno hecho a mano con cinta)
local function filterProp(b: CFrame, homemade: boolean)
	newPart("FilterHousing", Vector3.new(2.4, 3.2, 1.6), b * CFrame.new(0, 1.6, 0), Color3.fromHex("F4F2FA"))
	newPart("FilterLabel", Vector3.new(1.6, 0.3, 0.05), b * CFrame.new(0, 2.6, -0.82), DARK)
	local old = cyl("OldFilter", 1.6, 0.9, b * CFrame.new(-0.4, 1.2, -0.8) * FWD, Color3.fromHex("5E4A36"), Enum.Material.Fabric)
	local light = statusLight(b * CFrame.new(0.8, 2.6, -0.82))
	return function()
		tw(old, 0.8, { CFrame = b * CFrame.new(-0.4, 1.2, -2.2) * FWD })
		task.wait(0.85)
		tw(old, 0.45, { CFrame = b * CFrame.new(-0.4, 0.45, -2.8) * FWD * CFrame.Angles(0, 0.5, 0) }, Enum.EasingStyle.Bounce)
		local new = cyl("NewFilter", 1.6, 0.9, b * CFrame.new(-0.4, 1.2, -2.6) * FWD,
			homemade and Color3.fromHex("9EA3B5") or Color3.fromHex("FFFFFF"), Enum.Material.Fabric)
		task.wait(0.4)
		tw(new, 0.9, { CFrame = b * CFrame.new(-0.4, 1.2, -0.8) * FWD })
		task.wait(0.9)
		lightOk(light)
	end
end

-- Medidor de radiación (dosis, A): la aguja salta a rojo, tiembla y baja a amarillo al ponerse a cubierto
local function meterProp(b: CFrame)
	newPart("MeterPost", Vector3.new(0.25, 1.6, 0.25), b * CFrame.new(0, 0.8, 0), METAL, Enum.Material.Metal)
	newPart("MeterBox", Vector3.new(1.3, 1, 0.6), b * CFrame.new(0, 2.1, 0), Color3.fromHex("E8C33B"))
	local P0 = b * CFrame.new(0, 2.05, -0.32)
	cyl("MeterDial", 0.06, 0.8, P0 * FWD, Color3.new(1, 1, 1))
	newPart("RedZone", Vector3.new(0.16, 0.16, 0.04), P0 * CFrame.Angles(0, 0, math.rad(-55)) * CFrame.new(0, 0.28, -0.04), Config.Colors.Red, Enum.Material.Neon)
	local needle = newPart("Needle", Vector3.new(0.05, 0.34, 0.03), P0 * CFrame.Angles(0, 0, math.rad(60)) * CFrame.new(0, 0.16, -0.06), DARK)
	local light = statusLight(b * CFrame.new(0.5, 2.75, 0), Config.Colors.Gold)
	return function()
		hinge(needle, P0, CFrame.Angles(0, 0, math.rad(-110)), 0.5).Completed:Wait()
		for _ = 1, 3 do
			hinge(needle, P0, CFrame.Angles(0, 0, math.rad(10)), 0.08).Completed:Wait()
			hinge(needle, P0, CFrame.Angles(0, 0, math.rad(-10)), 0.08).Completed:Wait()
		end
		task.wait(0.4)
		hinge(needle, P0, CFrame.Angles(0, 0, math.rad(60)), 0.9)
		lightOk(light, Config.Colors.Gold)
	end
end

-- Muro de provisiones (dosis, B): cada caja (agua o comida) se desliza y se apila en el refugio
local function crateProp(from: CFrame, to: CFrame, water: boolean)
	local c = newPart(water and "WaterBag" or "FoodCrate", Vector3.new(2.6, 1.4, 1.4), from * CFrame.new(0, 0.7, 0),
		water and Color3.fromHex("5AA9E6") or Color3.fromHex("E8A53B"), water and Enum.Material.Plastic or Enum.Material.WoodPlanks)
	c.Transparency = 0.15
	return function()
		tw(c, 1.2, { CFrame = to }, Enum.EasingStyle.Back)
	end
end

-- Calentador (helada, A): las resistencias se ponen naranjas y sube aire caliente
local function heaterProp(b: CFrame)
	newPart("HeaterBox", Vector3.new(2, 1.8, 0.9), b * CFrame.new(0, 0.9, 0), METAL, Enum.Material.Metal)
	local coils = {}
	for i = 0, 2 do
		table.insert(coils, cyl("Coil", 1.6, 0.18, b * CFrame.new(0, 0.5 + i * 0.4, -0.47), Color3.fromHex("5A5F7A"), Enum.Material.Metal))
	end
	local light = statusLight(b * CFrame.new(0.75, 2, 0))
	return function()
		for _, c in coils do
			task.wait(0.3)
			c.Material = Enum.Material.Neon
			tw(c, 0.8, { Color = Color3.fromHex("FF7A2E") })
		end
		burst(coils[3], Color3.fromHex("FFB27A"), 3, { Acceleration = Vector3.new(0, 4, 0), Speed = NumberRange.new(1, 2), Transparency = NumberSequence.new(0.5, 1), Rate = 25 })
		lightOk(light)
	end
end

-- Ventilador (moho, A): se cortan las hojas con moho (caen) y las aspas giran rápido
local function fanProp(b: CFrame)
	newPart("FanPost", Vector3.new(0.25, 1.6, 0.25), b * CFrame.new(0, 0.8, 0), METAL, Enum.Material.Metal)
	local hub = b * CFrame.new(0, 2.2, -0.1)
	cyl("FanRing", 0.2, 2, hub * FWD, DARK).Transparency = 0.6
	local blades = {
		newPart("Blade", Vector3.new(1.7, 0.3, 0.05), hub, Color3.fromHex("F4F2FA")),
		newPart("Blade", Vector3.new(0.3, 1.7, 0.05), hub, Color3.fromHex("F4F2FA")),
	}
	local leaves = newPart("MoldyLeaves", Vector3.new(1.2, 0.5, 1.2), b * CFrame.new(1.4, 0.3, -0.6), Color3.fromHex("6E7B3A"), Enum.Material.Grass)
	return function()
		burst(leaves, Color3.fromHex("7C6A3A"), 1, { Speed = NumberRange.new(2, 4) })
		tw(leaves, 1, { Size = Vector3.new(0.4, 0.1, 0.4), Transparency = 1 })
		spinAround(blades, hub, 6, 3)
	end
end

-- Basurero (moho, B): se abre la tapa, cae la bandeja con moho y se cierra
local function binProp(b: CFrame)
	cyl("Bin", 1.8, 1.4, b * CFrame.new(0, 0.9, 0) * UP, Color3.fromHex("5A5F7A"))
	local lid = cyl("BinLid", 0.15, 1.5, b * CFrame.new(0, 1.88, 0) * UP, DARK)
	local tray = newPart("MoldyTray", Vector3.new(1.2, 0.3, 0.8), b * CFrame.new(0, 2.6, -1.4), Color3.fromHex("6B5B4B"), Enum.Material.Slate)
	return function()
		hinge(lid, b * CFrame.new(0, 1.88, 0.75), CFrame.Angles(math.rad(-100), 0, 0), 0.4)
		task.wait(0.4)
		tw(tray, 0.7, { CFrame = b * CFrame.new(0, 1.2, 0) * CFrame.Angles(0.6, 0, 0) })
		task.wait(0.7)
		burst(lid, Color3.fromHex("7C6A3A"), 0.4, { Speed = NumberRange.new(1, 3) })
		tray:Destroy()
		hinge(lid, b * CFrame.new(0, 1.88, 0.75), CFrame.Angles(math.rad(100), 0, 0), 0.4)
	end
end

-- [15-nov] Objetos de las otras 10 emergencias ---------------------------------------------------

-- Escotilla del hábitat (tormenta de radiación, A): la puerta se cierra y la luz pasa a verde
local function hatchProp(b: CFrame)
	newPart("HatchFrame", Vector3.new(3, 4, 0.5), b * CFrame.new(0, 2, 0), METAL, Enum.Material.Metal)
	local door = newPart("HatchDoor", Vector3.new(2.4, 3.4, 0.2), b * CFrame.new(-2.3, 2, -0.3), Color3.fromHex("F4F2FA"))
	newPart("RadSign", Vector3.new(0.8, 0.8, 0.05), b * CFrame.new(0, 3.5, -0.27), Color3.fromHex("F2C230"), Enum.Material.Neon)
	local light = statusLight(b * CFrame.new(1.7, 3.6, -0.3))
	return function()
		tw(door, 1.2, { CFrame = b * CFrame.new(0, 2, -0.3) }, Enum.EasingStyle.Sine)
		task.wait(1.2)
		burst(door, Color3.fromHex("C9CCD8"), 0.3, { Speed = NumberRange.new(2, 4) })
		lightOk(light)
	end
end

-- Montón de regolito (tormenta de radiación, B): la pala echa tierra y el montón crece
local function regolithProp(b: CFrame)
	local pile = newPart("RegolithPile", Vector3.new(1.2, 0.3, 1.2), b * CFrame.new(0, 0.15, 0), Color3.fromHex("8E89A8"), Enum.Material.Sand)
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = pile
	local handle = newPart("ShovelHandle", Vector3.new(0.15, 2.6, 0.15), b * CFrame.new(-1.4, 1.4, -0.4) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromHex("8A6E4B"), Enum.Material.Wood)
	local blade = newPart("ShovelBlade", Vector3.new(0.8, 0.9, 0.08), handle.CFrame * CFrame.new(0, -1.6, 0), METAL, Enum.Material.Metal)
	return function()
		local pv = handle.CFrame * CFrame.new(0, 1.2, 0)
		for _ = 1, 2 do
			hinge(handle, pv, CFrame.Angles(0, 0, math.rad(-40)), 0.35)
			hinge(blade, pv, CFrame.Angles(0, 0, math.rad(-40)), 0.35).Completed:Wait()
			burst(pile, Color3.fromHex("A9A4C2"), 0.3, { Speed = NumberRange.new(2, 5) })
			hinge(handle, pv, CFrame.Angles(0, 0, math.rad(40)), 0.35)
			hinge(blade, pv, CFrame.Angles(0, 0, math.rad(40)), 0.35).Completed:Wait()
		end
		tw(pile, 1, { Size = Vector3.new(3.2, 1.6, 3.2), CFrame = b * CFrame.new(0, 0.8, 0) })
	end
end

-- Aspiradora (polvo en la esclusa, A): la mancha de polvo se encoge mientras aspira
local function vacuumProp(b: CFrame)
	cyl("VacuumTank", 1.2, 0.9, b * CFrame.new(1.3, 0.6, 0) * UP, Color3.fromHex("E8A53B"))
	local hose = newPart("VacuumHose", Vector3.new(0.18, 0.18, 1.8), b * CFrame.new(0.4, 0.3, -0.6) * CFrame.Angles(0, math.rad(50), 0), DARK)
	local dust = newPart("DustPatch", Vector3.new(0.1, 2.4, 2.4), b * CFrame.new(-0.6, 0.06, -1.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("9A8F7A"), Enum.Material.Sand)
	dust.Shape = Enum.PartType.Cylinder
	return function()
		burst(dust, Color3.fromHex("B5AA94"), 1.5, { Acceleration = Vector3.new(0, 3, 0), Speed = NumberRange.new(1, 3) })
		tw(hose, 0.6, { CFrame = b * CFrame.new(-0.4, 0.3, -1) * CFrame.Angles(0, math.rad(80), 0) })
		tw(dust, 1.8, { Size = Vector3.new(0.1, 0.2, 0.2), Transparency = 1 })
	end
end

-- Cepillo de trajes (polvo, B): sale polvo del traje y queda blanco
local function suitBrushProp(b: CFrame)
	newPart("SuitRack", Vector3.new(0.2, 3, 0.2), b * CFrame.new(0, 1.5, 0.3), METAL, Enum.Material.Metal)
	local suit = newPart("SuitTorso", Vector3.new(1.4, 1.8, 0.8), b * CFrame.new(0, 1.9, 0), Color3.fromHex("B9AE96"), Enum.Material.Fabric)
	ball("SuitHelmet", 1, (b * CFrame.new(0, 3.2, 0)).Position, Color3.fromHex("C9C0AA"))
	return function()
		burst(suit, Color3.fromHex("B5AA94"), 1.5, { Speed = NumberRange.new(2, 4) })
		tw(suit, 1.5, { Color = Color3.fromHex("F4F2FA") })
	end
end

-- Computadora de respaldo (tormenta geomagnética, B): la pantalla arranca de negro a verde
local function consoleProp(b: CFrame)
	newPart("ConsoleDesk", Vector3.new(2, 1.2, 1), b * CFrame.new(0, 0.6, 0), DARK)
	local screen = newPart("ConsoleScreen", Vector3.new(1.6, 1.1, 0.08), b * CFrame.new(0, 1.85, 0.1) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromHex("0A0C14"), Enum.Material.Neon)
	local bars = {}
	for i = 1, 4 do
		local bar = newPart("BootBar", Vector3.new(0.05, 0.1, 0.03), screen.CFrame * CFrame.new(-0.6, 0.35 - i * 0.18, -0.06), Config.Colors.Good, Enum.Material.Neon)
		bar.Transparency = 1
		bars[i] = bar
	end
	return function()
		tw(screen, 0.4, { Color = Color3.fromHex("0F2A1C") })
		for i, bar in bars do
			task.wait(0.3)
			bar.Transparency = 0
			local w = 0.4 + i * 0.2
			tw(bar, 0.4, { Size = Vector3.new(w, 0.1, 0.03), CFrame = screen.CFrame * CFrame.new(-0.62 + w / 2, 0.35 - i * 0.18, -0.06) })
		end
	end
end

-- Reinicio del reactor (A): se baja la palanca y la barra de potencia sube hasta verde
local function reactorRestartProp(b: CFrame)
	newPart("ReactorPanel", Vector3.new(1.4, 2.2, 0.6), b * CFrame.new(0, 1.1, 0), Color3.fromHex("3A3D48"))
	newPart("PowerFrame", Vector3.new(0.4, 1.4, 0.05), b * CFrame.new(-0.35, 1.2, -0.32), Color3.fromHex("111326"))
	local bar = newPart("PowerBar", Vector3.new(0.3, 0.2, 0.06), b * CFrame.new(-0.35, 0.6, -0.34), Config.Colors.Red, Enum.Material.Neon)
	local lever = newPart("Lever", Vector3.new(0.15, 0.8, 0.15), b * CFrame.new(0.35, 1.6, -0.4), Config.Colors.Gold)
	return function()
		hinge(lever, b * CFrame.new(0.35, 1.2, -0.4), CFrame.Angles(math.rad(-110), 0, 0), 0.5)
		task.wait(0.5)
		tw(bar, 1.6, { Size = Vector3.new(0.3, 1.3, 0.06), CFrame = b * CFrame.new(-0.35, 1.15, -0.34), Color = Config.Colors.Good })
	end
end

-- Bicicleta de ejercicio (músculos y huesos): la rueda gira más rápido
local function bikeProp(b: CFrame)
	newPart("BikeBase", Vector3.new(0.5, 0.2, 2.2), b * CFrame.new(0, 0.1, 0), DARK)
	newPart("BikePost", Vector3.new(0.2, 1.4, 0.2), b * CFrame.new(0, 0.8, 0.5), METAL, Enum.Material.Metal)
	newPart("BikeSeat", Vector3.new(0.5, 0.15, 0.7), b * CFrame.new(0, 1.55, 0.5), Color3.fromHex("2B2B2B"))
	newPart("BikeBars", Vector3.new(0.9, 0.12, 0.12), b * CFrame.new(0, 1.5, -0.6), METAL, Enum.Material.Metal)
	local wheel = cyl("Flywheel", 0.2, 1.1, b * CFrame.new(0, 0.7, -0.6), Config.Colors.Red)
	return function()
		spin(wheel, 6, 2.2)
	end
end

-- Caja de comida (comida dañada): A se revisa (tapa y luz verde) / B se tira (cae y se va)
local function foodCrateProp(b: CFrame, toss: boolean)
	local crate = newPart("FoodCrate", Vector3.new(1.6, 1, 1.2), b * CFrame.new(0, 0.5, 0), Color3.fromHex("E8A53B"), Enum.Material.WoodPlanks)
	local lid = newPart("CrateLid", Vector3.new(1.7, 0.12, 1.3), b * CFrame.new(0, 1.06, 0), Color3.fromHex("C9832A"))
	local light = statusLight(b * CFrame.new(0.6, 1.35, -0.5), Config.Colors.Gold)
	return function()
		hinge(lid, b * CFrame.new(0, 1.06, 0.65), CFrame.Angles(math.rad(-100), 0, 0), 0.5)
		task.wait(0.6)
		if toss then
			burst(crate, Color3.fromHex("7C6A3A"), 0.5, { Speed = NumberRange.new(1, 3) })
			for _, p in { crate, lid, light } do
				tw(p, 0.8, { CFrame = p.CFrame + Vector3.new(0, -1.2, 0), Transparency = 1 })
			end
		else
			lightOk(light)
		end
	end
end

-- Desinfectante (tripulación enferma, A): spray con niebla y brillo de limpio
local function sprayProp(b: CFrame)
	local bottle = cyl("SprayBottle", 0.9, 0.4, b * CFrame.new(0, 0.95, 0) * UP, Color3.fromHex("5AA9E6"))
	newPart("SprayHead", Vector3.new(0.25, 0.3, 0.35), b * CFrame.new(0, 1.55, -0.1), Color3.new(1, 1, 1))
	local nozzle = newPart("Nozzle", Vector3.new(0.1, 0.1, 0.1), b * CFrame.new(0, 1.55, -0.3), DARK)
	newPart("Table", Vector3.new(1.6, 0.5, 1.2), b * CFrame.new(0, 0.25, 0), METAL, Enum.Material.Metal)
	return function()
		burst(nozzle, Color3.fromHex("DDF2FF"), 1.2, { Acceleration = Vector3.zero, Speed = NumberRange.new(4, 7), SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Front, Transparency = NumberSequence.new(0.4, 1) })
		task.wait(1.2)
		burst(bottle, Color3.new(1, 1, 1), 0.6, { LightEmission = 1, Acceleration = Vector3.zero, Speed = NumberRange.new(1, 2) })
	end
end

-- Canasta de verduras frescas (tripulación enferma, B): las verduras saltan a la canasta
local function basketProp(b: CFrame)
	cyl("Basket", 0.7, 1.2, b * CFrame.new(0, 0.35, 0) * UP, Color3.fromHex("C9A56B"), Enum.Material.WoodPlanks)
	local veg = {}
	for i, c in { "4FB36A", "E8533F", "F2C230" } do
		local v = ball("Veg", 0.35, (b * CFrame.new(-1.6, 0.3, -0.4 + i * 0.3)).Position, Color3.fromHex(c))
		veg[i] = v
	end
	return function()
		for i, v in veg do
			tw(v, 0.5, { CFrame = b * CFrame.new(-0.2 + i * 0.15, 0.85, 0) }, Enum.EasingStyle.Back)
			task.wait(0.25)
		end
	end
end

-- Fuga en el tanque (A parchar / B cerrar): sale un chorro de agua que se detiene
local function leakProp(b: CFrame, letter: string)
	cyl("Tank", 3, 1.8, b * CFrame.new(0, 1.5, 0) * UP, Color3.fromHex("F4F2FA"))
	local wheel = cyl("ValveWheel", 0.2, 1.1, b * CFrame.new(0, 3.2, 0) * UP, Config.Colors.Red)
	local hole = newPart("Hole", Vector3.new(0.15, 0.15, 0.05), b * CFrame.new(0.3, 1.2, -0.92), DARK)
	local jet = Instance.new("ParticleEmitter")
	jet.Color = ColorSequence.new(Color3.fromHex("8FD3FF"))
	jet.Size = NumberSequence.new(0.15, 0.05)
	jet.Lifetime = NumberRange.new(0.4, 0.6)
	jet.Speed = NumberRange.new(5, 7)
	jet.SpreadAngle = Vector2.new(6, 6)
	jet.Acceleration = Vector3.new(0, -12, 0)
	jet.EmissionDirection = Enum.NormalId.Front
	jet.Rate = 60
	jet.Parent = hole
	return function()
		if letter == "A" then
			local tape = newPart("Tape", Vector3.new(0.05, 0.6, 0.6), b * CFrame.new(0.3, 1.2, -1.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("9EA3B5"))
			tw(tape, 0.6, { CFrame = b * CFrame.new(0.3, 1.2, -0.95) * CFrame.Angles(0, math.rad(90), 0) })
			task.wait(0.6)
		else
			spin(wheel, 2, 1.4)
			task.wait(1.4)
		end
		jet.Enabled = false
	end
end

-- Carrito (helada, B): las plantas suben al carrito y ruedan hacia el hábitat
local function cartProp(b: CFrame, toward: Vector3)
	local parts = {
		newPart("CartBed", Vector3.new(2, 0.2, 1.3), b * CFrame.new(0, 0.6, 0), METAL, Enum.Material.Metal),
		newPart("CartHandle", Vector3.new(0.12, 1, 1.3), b * CFrame.new(1, 1.1, 0), DARK),
		newPart("PlantBox", Vector3.new(1.4, 0.6, 0.9), b * CFrame.new(-0.1, 1, 0), Color3.fromHex("6FBF5A"), Enum.Material.Grass),
	}
	for _, x in { -0.7, 0.7 } do
		for _, z in { -0.55, 0.55 } do
			table.insert(parts, cyl("Wheel", 0.15, 0.4, b * CFrame.new(x, 0.25, z) * FWD, DARK))
		end
	end
	return function()
		local d = (toward - b.Position) * Vector3.new(1, 0, 1)
		local move = (d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 0, 1)) * math.min(8, d.Magnitude)
		for _, p in parts do
			tw(p, 2, { CFrame = p.CFrame + move }, Enum.EasingStyle.Sine)
		end
		task.wait(2)
		for _, p in parts do tw(p, 0.8, { Transparency = 1 }) end
	end
end

---------------------------------------------------------------------
-- Condiciones y ayudantes
---------------------------------------------------------------------
local function trays(): { BasePart }
	local t = {}
	for _, tray in CollectionService:GetTagged("SO_Tray") do
		if tray:GetAttribute("Planted") then table.insert(t, tray) end
	end
	return t
end

local CONDITIONS = {
	always = function() return true end,
	has_machine = function() return GS:GetAttribute("Choice_life") ~= "tanks" end,
	has_trays = function() return #trays() > 0 end,
	-- [15-nov, PDF Fase 3] condiciones de las otras 10 emergencias
	has_panels = function() local c = GS:GetAttribute("Choice_eng") return c == "panels" or c == "panels_bat" end,
	has_reactor = function() return GS:GetAttribute("Choice_eng") == "reactor" end,
	has_tanks = function() return GS:GetAttribute("Choice_life") == "tanks" end,
	packaged_outside = function() return GS:GetAttribute("Choice_bot") == "packaged" and GS:GetAttribute("Spot_bot") ~= "inflatable" end,
	contact_ok = function() return GS:GetAttribute("NextChooseTime") == nil end, -- si ya no hay contacto, no sale "sin contacto"
}

local function roleHasAlivePlayer(role: string): boolean
	for _, p in Players:GetPlayers() do
		if not p:GetAttribute("Dead") and string.find("," .. (p:GetAttribute("Roles") or "") .. ",", "," .. role .. ",", 1, true) then
			return true
		end
	end
	return false
end

-- ¿Puede este jugador elegir? (rol afectado, su cinturón, o cualquiera si nadie vivo tiene el rol)
local function canChoose(p: Player, role: string): boolean
	if p:GetAttribute("Dead") then return false end
	local mine = "," .. (p:GetAttribute("Roles") or "") .. "," .. (p:GetAttribute("Belts") or "") .. ","
	if string.find(mine, "," .. role .. ",", 1, true) then return true end
	return not roleHasAlivePlayer(role)
end

local function landerPos(): Vector3
	return site.Lander.PrimaryPart.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
end
local function placedPos(role: string, fallback: Vector3): Vector3
	local placed = site:FindFirstChild("Placed")
	local m = placed and placed:FindFirstChild(role)
	return m and (m:GetPivot().Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)) or (landerPos() + fallback)
end
local function siteScore(index: number): number
	for _, s in Config.Sites do
		if s.Id == GS:GetAttribute("Site") then return s.Scores[index] end
	end
	return 8
end

-- Dónde van los puntos de cada respuesta
local function positions(where: string, count: number): { Vector3 }
	local L = landerPos()
	if where == "antenna" and site:FindFirstChild("SO_CommsAntenna") and site.SO_CommsAntenna:FindFirstChild("Footing") then
		-- Al pie de la antena real (MoonExtras), del lado de la base
		local f = site.SO_CommsAntenna.Footing.Position
		local toBase = (L - f) * Vector3.new(1, 0, 1)
		return { Vector3.new(f.X, L.Y, f.Z) + (toBase.Magnitude > 0.1 and toBase.Unit or Vector3.zero) * 5 }
	elseif where == "antenna" then
		local comms = siteScore(3)
		local dist = comms >= 9 and 20 or (comms >= 7 and 40 or 70)
		local dir = Vector3.new(95, 0, 75).Unit
		return { L + dir * dist }
	elseif where == "lander" then
		return { L + Vector3.new(-9, 0, 20) } -- lejos del prompt de recarga de la nave (también usa E)
	elseif where == "board" then
		return { placedPos("eng", Vector3.new(-12, 0, -8)) + Vector3.new(6, 0, 0) }
	elseif where == "machine" then
		return { placedPos("life", Vector3.new(40, 0, 20)) + Vector3.new(6, 0, 0) }
	elseif where == "parts_then_machine" then
		return { L + Vector3.new(10, 0, 10), placedPos("life", Vector3.new(40, 0, 20)) + Vector3.new(6, 0, 0) }
	elseif where == "meters" and site:FindFirstChild("Placed") and site.Placed:FindFirstChild("cap") and site.Placed.cap:FindFirstChild("RadSensor") then
		-- Un medidor dentro del hábitat (el sensor de radiación), uno en la nave y uno afuera
		local sensor = site.Placed.cap.RadSensor.Position
		return { Vector3.new(sensor.X, L.Y, sensor.Z), L + Vector3.new(-6, 0, 14), L + Vector3.new(0, 0, -40) }
	elseif where == "supplies" and site:FindFirstChild("Placed") and site.Placed:FindFirstChild("cap") and site.Placed.cap:FindFirstChild("Shelter") then
		-- El muro de provisiones se arma en el refugio de tormenta del hábitat
		local s = site.Placed.cap.Shelter.Position
		local g = Vector3.new(s.X, L.Y, s.Z)
		return { g + Vector3.new(-1.5, 0, -1), g + Vector3.new(1.5, 0, -1), g + Vector3.new(0, 0, 1.5) }
	elseif where == "meters" then
		return { L + Vector3.new(-6, 0, 14), L + Vector3.new(0, 0, -40), site.HabitatZone.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 8) }
	elseif where == "supplies" then
		local h = site.HabitatZone.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
		return { h + Vector3.new(-6, 0, 9), h + Vector3.new(0, 0, 10), h + Vector3.new(6, 0, 9) }
	elseif where == "heater" then
		return { placedPos("bot", Vector3.new(20, 0, 25)) + Vector3.new(0, 0, 9) }
	elseif where == "trays" then
		local out = {}
		for i, t in trays() do
			if i > count then break end
			table.insert(out, t.Position + Vector3.new(0, 1, 2))
		end
		if #out == 0 then out = { placedPos("bot", Vector3.new(20, 0, 25)) + Vector3.new(0, 0, 9) } end
		return out
	end
	-- [15-nov, PDF Fase 3] lugares de las otras 10 emergencias
	local hab = placedPos("cap", Vector3.new(-60, 0, 40))
	if where == "habitat" then
		return { hab + Vector3.new(-15, 0, 0) } -- al costado del hábitat (frente a la puerta el aviso no aparecía)
	elseif where == "habitat3" then -- montones de regolito alrededor del hábitat
		return { hab + Vector3.new(-14, 0, 6), hab + Vector3.new(14, 0, 6), hab + Vector3.new(0, 0, -12) }
	elseif where == "airlock3" then -- manchas de polvo en la entrada
		return { L + Vector3.new(-6, 0, 14), L + Vector3.new(0, 0, 18), L + Vector3.new(6, 0, 14) }
	elseif where == "consoles2" then
		local b = placedPos("eng", Vector3.new(-12, 0, -8))
		return { b + Vector3.new(6, 0, -4), b + Vector3.new(6, 0, 4) }
	elseif where == "reactor3" then
		local r = placedPos("eng", Vector3.new(-12, 0, -8))
		return { r + Vector3.new(8, 0, 0), r + Vector3.new(-4, 0, 7), r + Vector3.new(-4, 0, -7) }
	elseif where == "exercise" then
		return { hab + Vector3.new(0, 0, -10) }
	elseif where == "crates3" or where == "crate1" then
		local c = placedPos("bot", Vector3.new(20, 0, 25))
		local list = { c + Vector3.new(-4, 0, 6), c + Vector3.new(0, 0, 7), c + Vector3.new(4, 0, 6) }
		return where == "crate1" and { list[2] } or list
	elseif where == "clean3" then -- hábitat, cultivo y esclusa
		return { hab + Vector3.new(-15, 0, 0), placedPos("bot", Vector3.new(20, 0, 25)) + Vector3.new(0, 0, 9), L + Vector3.new(0, 0, 18) }
	elseif where == "ready_tray" then
		for _, t in trays() do
			if (t:GetAttribute("GrowLeft") or 1) <= 0 then return { t.Position + Vector3.new(0, 1, 2) } end
		end
		local list = trays()
		if #list > 0 then return { list[1].Position + Vector3.new(0, 1, 2) } end
	end
	return { L + Vector3.new(0, 0, 18) }
end

-- ¿El punto está dentro del hábitat? (medidor junto al sensor, muro del refugio)
local function isIndoor(where: string, i: number): boolean
	local cap = site:FindFirstChild("Placed") and site.Placed:FindFirstChild("cap")
	if where == "meters" then return i == 1 and cap ~= nil and cap:FindFirstChild("RadSensor") ~= nil end
	if where == "supplies" then return cap ~= nil and cap:FindFirstChild("Shelter") ~= nil end
	return false
end

-- Elige y arma el objeto animado de un punto; devuelve la animación de "trabajo hecho"
local function makeProp(id: string, letter: string, where: string, i: number, pos: Vector3, spots: { Vector3 }, indoor: boolean): (() -> ())?
	local L = landerPos()
	local function centerOf(role: string): Vector3
		local m = site:FindFirstChild("Placed") and site.Placed:FindFirstChild(role)
		return m and m:GetPivot().Position or L
	end
	-- [15-nov] objetos de las otras 10 emergencias (algunas reusan lugares de las primeras 6)
	if id == "leak" and where == "machine" then
		return leakProp(baseAt(pos, centerOf("life")), letter)
	elseif id == "dust" and where == "lander" then
		return suitBrushProp(baseAt(pos, L))
	elseif where == "habitat" then
		return hatchProp(baseAt(pos, centerOf("cap"), false, 2.2))
	elseif where == "habitat3" then
		return regolithProp(baseAt(pos, centerOf("cap")))
	elseif where == "airlock3" then
		return vacuumProp(baseAt(pos, L))
	elseif where == "consoles2" then
		return consoleProp(baseAt(pos, centerOf("eng")))
	elseif where == "reactor3" then
		return reactorRestartProp(baseAt(pos, centerOf("eng")))
	elseif where == "exercise" then
		return bikeProp(baseAt(pos, centerOf("cap")))
	elseif where == "crates3" or where == "crate1" then
		return foodCrateProp(baseAt(pos, centerOf("bot")), where == "crate1")
	elseif where == "clean3" then
		return sprayProp(baseAt(pos, L))
	elseif where == "ready_tray" then
		return basketProp(baseAt(pos, pos - Vector3.new(0, 1, 2)))
	end
	if where == "antenna" then
		return antennaProp(baseAt(pos, L))
	elseif where == "lander" then
		return radioProp(baseAt(pos, L))
	elseif where == "board" then
		return breakerProp(baseAt(pos, centerOf("eng")), letter)
	elseif where == "parts_then_machine" then
		if i == 1 then return partsProp(baseAt(pos, L)) end
		return filterProp(baseAt(pos, centerOf("life")), true)
	elseif where == "machine" then
		return filterProp(baseAt(pos, centerOf("life")), false)
	elseif where == "meters" then
		if indoor then
			-- adentro: el medidor va hacia el centro del hábitat (no contra la pared)
			local h = centerOf("cap")
			return meterProp(baseAt(pos, pos * 2 - h, true, 2))
		end
		return meterProp(baseAt(pos, L))
	elseif where == "supplies" then
		local g = Vector3.zero
		for _, s in spots do g += s end
		g /= #spots
		local floorY = pos.Y - 0.6
		local fromDir = (pos - g) * Vector3.new(1, 0, 1)
		fromDir = fromDir.Magnitude > 0.1 and fromDir.Unit or Vector3.new(0, 0, 1)
		local from = CFrame.new(Vector3.new(pos.X, floorY, pos.Z) + fromDir * 2.5)
		-- muro: dos cajas abajo y una arriba
		local slot = ({ Vector3.new(-1.35, 0.7, -2.2), Vector3.new(1.35, 0.7, -2.2), Vector3.new(0, 2.1, -2.2) })[i] or Vector3.new(0, 0.7, -2.2)
		local to = CFrame.new(Vector3.new(g.X, floorY, g.Z) + slot)
		return crateProp(from, to, i ~= 2)
	elseif where == "heater" then
		return heaterProp(baseAt(pos, centerOf("bot")))
	elseif where == "trays" then
		local tray = pos - Vector3.new(0, 1, 2)
		local b = baseAt(pos, tray)
		if id == "mold" and letter == "A" then return fanProp(b) end
		if id == "mold" then return binProp(b) end
		return cartProp(b, centerOf("cap"))
	end
	return nil
end

-- Crea un punto de "mantener E" (cualquier vivo puede ayudar)
local function holdPoint(pos: Vector3, text: string, hold: number, color: Color3, onDone: () -> ())
	local part = Instance.new("Part")
	part.Name = "EmergencyPoint"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.4, 5, 5)
	part.CFrame = CFrame.new(pos - Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Parent = pointsFolder
	local beam = Instance.new("Part") -- columna de luz para encontrarlo de lejos
	beam.Name = "Beam"
	beam.Size = Vector3.new(0.6, 40, 0.6)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 20, 0))
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.5
	beam.Color = color
	beam.Parent = part
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.HoldDuration = hold
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.Parent = part
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Dead") or not prompt.Enabled then return end
		prompt.Enabled = false
		part.Color = Config.Colors.Good
		beam:Destroy()
		onDone()
	end)
	return part, prompt, beam
end

---------------------------------------------------------------------
-- Efectos (los números son del juego, PDF Fase 3 cap. 6)
---------------------------------------------------------------------
local function loseTrays(n: number)
	local list = trays()
	for i = 1, math.min(n, #list) do
		local t = list[i]
		t:SetAttribute("Planted", false)
		CollectionService:RemoveTag(t, "SO_Tray")
		t.Color = Color3.fromHex("6B5B4B")
		t.Material = Enum.Material.Slate
		local pr = t:FindFirstChild("HarvestPrompt")
		if pr then pr.Enabled = false end
	end
end

local function addFood(d: number)
	GS:SetAttribute("Food", math.max(0, (GS:GetAttribute("Food") or 0) + d))
end

local EFFECTS = {
	next_choose_20 = function() GS:SetAttribute("NextChooseTime", 20) end,
	next_choose_15 = function() GS:SetAttribute("NextChooseTime", 15) end,
	next_choose_10 = function() GS:SetAttribute("NextChooseTime", 10) end,
	greenhouse_off = function() GS:SetAttribute("Mod_GreenhouseOff", true) end,
	machine_off = function() GS:SetAttribute("Mod_MachineOff", true) end,
	surge = function()
		GS:SetAttribute("Damaged_eng", true)
		GS:SetAttribute("Mod_GreenhouseOff", true)
	end,
	fixed = function() GS:SetAttribute("Mod_O2Mult", nil) end,
	rest = function()
		GS:SetAttribute("Mod_O2Mult", nil)
		GS:SetAttribute("Mod_SlowWalk", true)
	end,
	o2_fast_day = function() GS:SetAttribute("Mod_O2Mult", 1.5) end,
	rad_out_15 = function() GS:SetAttribute("Mod_RadOutMult", 1.5) end,
	supply_wall = function()
		GS:SetAttribute("ReserveWater", math.max(0, (GS:GetAttribute("ReserveWater") or 0) - 10))
		addFood(-0.5)
	end,
	rad_out_2_nodrop = function()
		GS:SetAttribute("Mod_RadOutMult", 2)
		GS:SetAttribute("Mod_HabitatNoDrop", true)
	end,
	lose_tray_1 = function() loseTrays(1) end,
	mold_spread = function()
		local day = GS:GetAttribute("Day")
		task.spawn(function()
			while GS:GetAttribute("Day") == day and GS:GetAttribute("Phase") == "Phase3" and #trays() > 0 do
				loseTrays(1)
				task.wait(30)
			end
		end)
	end,
	heaters = function() GS:SetAttribute("Mod_ExtraEnergy", 20) end,
	trays_no_grow = function() GS:SetAttribute("Mod_TraysNoGrow", true) end,
	-- [15-nov, PDF Fase 3] efectos de las otras 10 emergencias
	-- Tormenta de radiación solar: con hábitat semienterrado, todo a la mitad
	rad_storm_a = function()
		local h = GS:GetAttribute("Spot_cap") == "half_buried" and 0.5 or 1
		GS:SetAttribute("Mod_RadOutMult", 4 * h)
		GS:SetAttribute("Mod_MachineMult", 0.5) -- nadie atiende la máquina
	end,
	rad_storm_b = function()
		local h = GS:GetAttribute("Spot_cap") == "half_buried" and 0.5 or 1
		GS:SetAttribute("Mod_RadOutMult", 2 * h)
	end,
	rad_storm_c = function()
		local h = GS:GetAttribute("Spot_cap") == "half_buried" and 0.5 or 1
		GS:SetAttribute("Mod_RadOutMult", 4 * h)
	end,
	-- Polvo: la máquina produce menos el resto del juego
	dust_b = function() GS:SetAttribute("MachineProdMult", (GS:GetAttribute("MachineProdMult") or 1) * 0.9) end,
	dust_c = function() GS:SetAttribute("MachineProdMult", (GS:GetAttribute("MachineProdMult") or 1) * 0.8) end,
	-- Sin contacto (C de la llamarada y de "sin contacto"): 10 s y, si es el día 3, la nave de carga llega el día 5
	no_contact = function()
		GS:SetAttribute("NextChooseTime", 10)
		if GS:GetAttribute("Day") == 3 then GS:SetAttribute("CargoDayOverride", 5) end
	end,
	-- Tormenta geomagnética
	geo_a = function() -- todo se pausa 20 s (sin crecimiento ni producción: 20 de los 120 s del día)
		local day = GS:GetAttribute("Day")
		GS:SetAttribute("Mod_TraysNoGrow", true)
		GS:SetAttribute("Mod_MachineMult", 1 - 20 / P3.DayLength)
		task.delay(20, function()
			if GS:GetAttribute("Day") == day then GS:SetAttribute("Mod_TraysNoGrow", nil) end
		end)
	end,
	geo_b = function() GS:SetAttribute("Mod_MachineMult", 0.75) end,
	system_down = function() -- se apaga el siguiente sistema de la lista de apagones
		local order = Config.BlackoutOrder
		local i = table.find(order, GS:GetAttribute("Blackout") or "") or 0
		GS:SetAttribute("Blackout", order[(i % #order) + 1])
	end,
	-- Sombra larga y reactor apagado: se apaga todo el resto del día
	all_off = function()
		GS:SetAttribute("Mod_GreenhouseOff", true)
		GS:SetAttribute("Mod_MachineOff", true)
		GS:SetAttribute("Blackout", "habitat")
	end,
	-- Fuga (tanques)
	water_minus10 = function() GS:SetAttribute("ReserveWater", math.max(0, (GS:GetAttribute("ReserveWater") or 0) - 10)) end,
	leak_spread = function() -- −5 % de agua cada 20 s hasta que termina el día
		local day = GS:GetAttribute("Day")
		task.spawn(function()
			while true do
				task.wait(20)
				if GS:GetAttribute("Day") ~= day or GS:GetAttribute("Phase") ~= "Phase3" then break end
				GS:SetAttribute("ReserveWater", math.max(0, (GS:GetAttribute("ReserveWater") or 0) - 5))
			end
		end)
	end,
	-- Músculos y huesos
	extra_energy_5 = function() GS:SetAttribute("Mod_ExtraEnergy", (GS:GetAttribute("Mod_ExtraEnergy") or 0) + 5) end,
	slow_2 = function() GS:SetAttribute("Mod_WalkMinus", 2) end,
	slow_4_2days = function()
		GS:SetAttribute("Mod_WalkMinus", 4)
		GS:SetAttribute("NextWalkMinus", 4) -- también todo el día siguiente
	end,
	-- Comida dañada y tripulación enferma
	food_half = function() addFood(-0.5) end,
	food_one = function() addFood(-1) end,
	stomach = function()
		for _, p in Players:GetPlayers() do
			if not p:GetAttribute("Dead") and p:GetAttribute("Water") then p:SetAttribute("Water", math.max(0, p:GetAttribute("Water") - 20)) end
		end
	end,
	fresh_veg = function()
		for _, p in Players:GetPlayers() do
			if not p:GetAttribute("Dead") and p:GetAttribute("Water") then p:SetAttribute("Water", math.max(0, p:GetAttribute("Water") - 10)) end
		end
		for _, t in trays() do -- la bandeja lista se usa y vuelve a crecer
			if (t:GetAttribute("GrowLeft") or 1) <= 0 then
				t:SetAttribute("GrowLeft", Config.Harvest.GrowTime)
				t.Material = Enum.Material.SmoothPlastic
				local pr = t:FindFirstChild("HarvestPrompt")
				if pr then pr.Enabled = false end
				break
			end
		end
	end,
	sick = function()
		for _, p in Players:GetPlayers() do
			if not p:GetAttribute("Dead") and p:GetAttribute("Water") then p:SetAttribute("Water", math.max(0, p:GetAttribute("Water") - 20)) end
		end
		addFood(-0.5)
	end,
	cold_kill = function()
		local inflatable = GS:GetAttribute("Spot_bot") == "inflatable"
		if GS:GetAttribute("Choice_bot") == "packaged" then
			addFood(inflatable and -2 or -1)
		else
			loseTrays(inflatable and 3 or 1)
		end
	end,
}

---------------------------------------------------------------------
-- Tirada del día (PDF 4.1)
---------------------------------------------------------------------
local function probOf(e): number
	local p = e.Prob
	if GS:GetAttribute("Damaged_" .. e.Role) then p += 0.05 end -- +5 puntos si su objeto sigue dañado
	-- 15-nov: el Sol de verdad (SO_LiveSpaceWeather): si el Sol real está activo, más clima espacial
	if e.Id == "flare" or e.Id == "cme" or e.Id == "geostorm" or e.Id == "sep" then
		p *= GS:GetAttribute("SW_Mult") or 1
	end
	return p
end

local function candidates()
	local list = {}
	for _, e in LIST do
		if e.Id ~= lastId and CONDITIONS[e.Condition] and CONDITIONS[e.Condition]() then
			table.insert(list, e)
		end
	end
	return list
end

local function weightedPick(list)
	local total = 0
	for _, e in list do total += probOf(e) end
	local r = math.random() * total
	for _, e in list do
		r -= probOf(e)
		if r <= 0 then return e end
	end
	return list[#list]
end

local function rollDay(day: number)
	if forced then
		local e = byId[forced]; forced = nil
		return e
	end
	local list = candidates()
	if #list == 0 then return nil end
	if day == P3.Days then
		-- Día 7 (PDF 6.2): puntaje de problemas por rol. Dañado 2, sin misión 1, apagón 1, respondió C 1.
		-- Empate: orden Captain, Engineer, Life Support, Botanist. Nadie con problemas: Captain.
		local best, bestScore = "cap", -1
		for _, role in Config.RoleOrder do
			local s = 0
			if GS:GetAttribute("Damaged_" .. role) then s += 2 end
			if not GS:GetAttribute("MissionComplete_" .. role) then s += 1 end
			if hadBlackout[role] then s += 1 end
			if answeredC[role] then s += 1 end
			if s > bestScore then best, bestScore = role, s end
		end
		local ofRole = {}
		for _, e in list do
			if e.Role == best then table.insert(ofRole, e) end
		end
		return weightedPick(#ofRole > 0 and ofRole or list)
	end
	if quietStreak >= 2 then
		return weightedPick(list) -- 2 días tranquilos seguidos: sale una sí o sí
	end
	-- Orden al azar; cada una sale con su probabilidad; la primera que sale es la del día
	for i = #list, 2, -1 do
		local j = math.random(1, i)
		list[i], list[j] = list[j], list[i]
	end
	for _, e in list do
		if math.random() < probOf(e) then return e end
	end
	return nil
end

---------------------------------------------------------------------
-- Correr una emergencia
---------------------------------------------------------------------
local function countdown(stage: string, seconds: number, doneWhen: () -> boolean): boolean
	GS:SetAttribute("EmergencyStage", stage)
	local left = seconds
	GS:SetAttribute("EmergencyLeft", left)
	while left > 0 do
		if doneWhen() then return true end
		task.wait(0.25)
		left -= 0.25
		GS:SetAttribute("EmergencyLeft", math.ceil(left))
		if GS:GetAttribute("Phase") ~= "Phase3" then return false end
	end
	return doneWhen()
end

local function clearEmergency()
	GS:SetAttribute("Emergency", "")
	GS:SetAttribute("EmergencyStage", "")
	pointsFolder:ClearAllChildren()
end

local function finish(e, letter: string, chooserRole: string, toast: string)
	-- Arreglo 15-nov: si la Fase 3 ya terminó (murió la tripulación o se ganó), no mostrar avisos ni datos
	-- encima de la pantalla final.
	if GS:GetAttribute("Phase") ~= "Phase3" then
		clearEmergency()
		return
	end
	if letter == "C" then answeredC[e.Role] = true end
	GS:SetAttribute("EmergencyChoice", letter)
	GS:SetAttribute("EmergencyChooser", chooserRole)
	GS:SetAttribute("EmergencyStage", "result")
	Remotes.MoonLight:FireAllClients(chooserRole ~= "" and chooserRole or "none")
	task.wait(P3.LightTime)
	Remotes.Toast:FireAllClients(toast, P3.ResultToast)
	Remotes.Fact:FireAllClients(e.Fact)
	task.wait(P3.ResultToast)
	GS:SetAttribute("Emergency", "")
	GS:SetAttribute("EmergencyStage", "")
	pointsFolder:ClearAllChildren()
end

local function runEmergency(e)
	lastId = e.Id
	GS:SetAttribute("EmergenciesSeen", (GS:GetAttribute("EmergenciesSeen") or 0) + 1)
	GS:SetAttribute("EmergencyChoice", "")
	GS:SetAttribute("EmergencyChooser", "")
	GS:SetAttribute("Emergency", e.Id)

	-- Protección de la Fase 2 (PDF 4.3): la tarjeta sale igual, dice PROTECTED y no pasa nada
	if e.ProtectedBy and GS:GetAttribute(e.ProtectedBy) then
		GS:SetAttribute("EmergencyStage", "protected")
		task.wait(6)
		GS:SetAttribute("EmergenciesSolved", (GS:GetAttribute("EmergenciesSolved") or 0) + 1)
		finish(e, "", e.Role, Config.Text3.Protected)
		return
	end

	-- ¿Hay una bandeja lista? (verduras frescas de "tripulación enferma")
	local ready = false
	for _, t in trays() do
		if (t:GetAttribute("GrowLeft") or 1) <= 0 then ready = true end
	end
	GS:SetAttribute("HasReadyTray", ready)

	-- Opciones no disponibles (ej. filtro de repuesto sin la misión de la Fase 2)
	local disabled = {}
	for _, letter in { "A", "B", "C" } do
		local r = e[letter]
		if r and r.Requires and not GS:GetAttribute(r.Requires) then table.insert(disabled, letter) end
	end
	GS:SetAttribute("EmergencyDisabled", table.concat(disabled, ","))

	if e.Ongoing == "o2_fast" then GS:SetAttribute("Mod_O2Mult", 1.5) end

	-- 1) Elegir (20 s, o lo que dejó la llamarada solar)
	answer = nil
	local chooseTime = GS:GetAttribute("NextChooseTime") or P3.ChooseTime
	GS:SetAttribute("NextChooseTime", nil)
	countdown("choose", chooseTime, function() return answer ~= nil end)
	local picked = answer
	if GS:GetAttribute("Phase") ~= "Phase3" then
		clearEmergency() -- la fase terminó mientras se elegía: no aplicar efectos
		return
	end
	if not picked then
		-- Nadie eligió: pasa la C (o el efecto de "sin respuesta" si la ficha lo define)
		local eff = EFFECTS[e.Timeout or e.C.Effect]
		if eff then eff() end
		finish(e, "C", "", e.C.Toast)
		return
	end

	GS:SetAttribute("EmergencyChoice", picked.letter)
	local r = e[picked.letter]
	-- 2) Ejecutar: puntos de mantener E (40 s). La C no tiene puntos.
	if r.Points then
		local spots = positions(r.Points.Where, r.Points.Count)
		local done, need = 0, #spots
		GS:SetAttribute("EmergencyProgress", "0/" .. need)
		local color = Config.Roles[picked.role] and Config.Roles[picked.role].Color or Config.Colors.Gold
		-- Ordered (PDF: reactor "en orden"): solo el punto que toca está encendido; al terminarlo se enciende el siguiente
		local ordered = r.Points.Ordered == true
		local steps: { { prompt: ProximityPrompt, beam: BasePart, part: BasePart } } = {}
		for i, pos in spots do
			local indoor = isIndoor(r.Points.Where, i)
			pos = snap(pos, indoor)
			local okProp, anim = pcall(makeProp, e.Id, picked.letter, r.Points.Where, i, pos, spots, indoor)
			if not okProp then warn("[Emergencies] prop:", anim); anim = nil end
			local part, prompt, beam = holdPoint(pos, r.Label .. (need > 1 and (" (" .. i .. "/" .. need .. ")") or ""), r.Points.Hold, color, function()
				done += 1
				GS:SetAttribute("EmergencyProgress", done .. "/" .. need)
				if anim then task.spawn(anim) end
				local nxt = ordered and steps[i + 1]
				if nxt then
					nxt.prompt.Enabled = true
					nxt.beam.Transparency = 0.5
					nxt.part.Transparency = 0
				end
			end)
			steps[i] = { prompt = prompt, beam = beam, part = part }
			if ordered and i > 1 then
				prompt.Enabled = false
				beam.Transparency = 1
				part.Transparency = 0.7
			end
		end
		local ok = countdown("execute", P3.ExecuteTime, function() return done >= need end)
		if GS:GetAttribute("Phase") ~= "Phase3" then
			clearEmergency()
			return
		end
		if not ok then
			pointsFolder:ClearAllChildren()
			local eff = EFFECTS[e.C.Effect]
			if eff then eff() end
			finish(e, "C", "", e.C.Toast)
			return
		end
	end
	local eff = EFFECTS[r.Effect]
	if eff then eff() end
	if picked.letter ~= "C" then
		GS:SetAttribute("EmergenciesSolved", (GS:GetAttribute("EmergenciesSolved") or 0) + 1)
	end
	if picked.letter == "A" then
		GS:SetAttribute("AnswersA", (GS:GetAttribute("AnswersA") or 0) + 1)
	end
	finish(e, picked.letter, picked.role, r.Toast)
end

Remotes.EmergencyAnswer.OnServerEvent:Connect(function(p, letter)
	local e = byId[GS:GetAttribute("Emergency") or ""]
	if not e or GS:GetAttribute("EmergencyStage") ~= "choose" or answer then return end
	if letter ~= "A" and letter ~= "B" and letter ~= "C" then return end
	if string.find(GS:GetAttribute("EmergencyDisabled") or "", letter, 1, true) then return end
	if not canChoose(p, e.Role) then
		Remotes.Toast:FireClient(p, "Only the " .. Config.Roles[e.Role].Name .. " (or their belt) can choose.", 2.5)
		return
	end
	-- Quién decidió = el rol principal de quien pulsó (color de la luz)
	answer = { letter = letter, role = p:GetAttribute("Role") or e.Role }
end)

-- Botón de prueba (solo Studio): forzar una emergencia para el próximo día o ahora mismo
Remotes.DebugSkip.OnServerEvent:Connect(function(_p, what, id)
	if not RunService:IsStudio() then return end
	if what == "emergency" and byId[id] and GS:GetAttribute("Phase") == "Phase3" and (GS:GetAttribute("Day") or 0) >= 1 and GS:GetAttribute("Emergency") == "" then
		task.spawn(runEmergency, byId[id])
	end
end)

---------------------------------------------------------------------
-- Cada día: borrar modificadores, tirar dados y programar la emergencia
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("Day"):Connect(function()
	local day = GS:GetAttribute("Day") or 0
	if GS:GetAttribute("Phase") ~= "Phase3" then return end
	for _, m in MODS do GS:SetAttribute(m, nil) end
	if day == 1 then
		-- [arreglo 15-nov] partida nueva: no arrastrar efectos largos de la partida anterior
		for _, m in LONG_MODS do GS:SetAttribute(m, nil) end
	end
	-- "Saltarse el ejercicio": la tripulación sigue lenta todo el día siguiente
	if GS:GetAttribute("NextWalkMinus") then
		GS:SetAttribute("Mod_WalkMinus", GS:GetAttribute("NextWalkMinus"))
		GS:SetAttribute("NextWalkMinus", nil)
	end
	if day == 1 then
		lastId, quietStreak = "", 0
		table.clear(hadBlackout)
		table.clear(answeredC)
		GS:SetAttribute("EmergenciesSeen", 0)
		GS:SetAttribute("EmergenciesSolved", 0)
		GS:SetAttribute("AnswersA", 0)
		return -- el día 1 es tranquilo
	end
	local e = rollDay(day)
	if not e then
		quietStreak += 1
		return
	end
	quietStreak = 0
	local at = math.random(P3.EmergencyWindow[1], P3.EmergencyWindow[2])
	task.spawn(function()
		while GS:GetAttribute("Day") == day and GS:GetAttribute("Phase") == "Phase3"
			and (P3.DayLength - (GS:GetAttribute("DayTimeLeft") or 0)) < at do
			task.wait(0.5)
		end
		if GS:GetAttribute("Day") == day and GS:GetAttribute("Phase") == "Phase3" and GS:GetAttribute("Emergency") == "" then
			runEmergency(e)
		end
	end)
end)

-- Registrar qué rol tuvo apagón (para el día 7)
GS:GetAttributeChangedSignal("Blackout"):Connect(function()
	local role = BLACKOUT_ROLE[GS:GetAttribute("Blackout") or ""]
	if role then hadBlackout[role] = true end
end)

-- Al salir de la Fase 3 se limpia todo
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if GS:GetAttribute("Phase") ~= "Phase3" then
		pointsFolder:ClearAllChildren()
		for _, m in MODS do GS:SetAttribute(m, nil) end
		for _, m in LONG_MODS do GS:SetAttribute(m, nil) end
	end
end)
