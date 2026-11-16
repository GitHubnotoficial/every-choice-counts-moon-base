-- MoonExtras (Script) -> ServerScriptService.MoonExtras
-- Dueño: Isaac + Claude. Mejoras de la Luna pedidas por Isaac (15-nov):
-- 1) Cráter de hielo profundo con la estación de recarga en el borde (el hielo se derrite: agua y oxígeno).
-- 2) Hábitat al que se puede ENTRAR (plantilla SO_Templates.habitat): literas, filtro de CO2 (como el CDRA de la ISS),
--    sensor de radiación (como el HERA de Orion) y refugio de tormenta con bolsas de agua (idea de NASA para Orion).
-- 3) La nave que eligió el Captain aparece en la Luna en vez del cohete genérico.
-- Las piezas 1 y 2 se construyen una sola vez (si ya existen, no se repiten).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local site = workspace:WaitForChild("MoonSite")
local O = Config.Zones.Moon

local C = {
	White = Color3.fromHex("F4F2FA"), Lavender = Color3.fromHex("D9D2F5"), Red = Color3.fromHex("FC3D21"),
	Teal = Color3.fromHex("36C9C6"), Floor = Color3.fromHex("3A3F66"), Metal = Color3.fromHex("8F8AA8"),
	Dark = Color3.fromHex("1A1240"), Blue = Color3.fromHex("2F7BFF"), Green = Color3.fromHex("3DD68C"),
	Water = Color3.fromHex("7FB8FF"), Rock = Color3.fromHex("8E89A8"), RockDark = Color3.fromHex("6E6A8C"),
	Ice = Color3.fromHex("CFEFFF"), Gold = Color3.fromHex("FFD43B"),
}

local function P(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in props do (p :: any)[k] = v end end
	p.Parent = parent
	return p
end
local function cylY(parent, name, h, d, pos: Vector3, color, props)
	local p = P(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function sign(part: BasePart, face: Enum.NormalId, text: string, color: Color3?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = C.Dark
	t.TextColor3 = color or C.Gold
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	t.Parent = sg
	sg.Parent = part
	return t
end

---------------------------------------------------------------------
-- 1) Cráter de hielo profundo con estación de recarga
---------------------------------------------------------------------
local function buildIceCrater()
	if site:FindFirstChild("SO_IceCraterDeep") then return end
	local m = Instance.new("Model")
	m.Name = "SO_IceCraterDeep"
	m.Parent = site
	local c = O + Vector3.new(-90, 0, 80)
	-- Borde levantado: anillo de rampas que suben hacia afuera y bajan hacia adentro (parece hundido)
	local n = 28
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local outer = P(m, "RimOuter", Vector3.new(10, 3, 13), CFrame.lookAt(c + dir * 31 + Vector3.new(0, 1.2, 0), c + dir * 40 + Vector3.new(0, -2, 0)), C.Rock, { Material = Enum.Material.Slate })
		local inner = P(m, "RimInner", Vector3.new(10, 3, 11), CFrame.lookAt(c + dir * 23 + Vector3.new(0, 1.2, 0), c + dir * 15 + Vector3.new(0, -3, 0)), C.RockDark, { Material = Enum.Material.Slate })
		outer.CanCollide = true; inner.CanCollide = true
	end
	-- Fondo oscuro (sombra permanente) y hielo brillante
	cylY(m, "CraterFloor", 0.4, 36, c + Vector3.new(0, 0.25, 0), Color3.fromHex("2E2A48"), { Material = Enum.Material.Slate })
	for i, off in { Vector3.new(0, 0, 0), Vector3.new(5, 0, 3), Vector3.new(-4, 0, 4), Vector3.new(2, 0, -5), Vector3.new(-5, 0, -3) } do
		local s = (i == 1) and 6 or 3.2
		P(m, "IceBlock", Vector3.new(s, s * 0.6, s), CFrame.new(c + off + Vector3.new(0, s * 0.3 + 0.4, 0)) * CFrame.Angles(0, i, 0.15), C.Ice, { Material = Enum.Material.Ice, Transparency = 0.1 })
	end
	local glow = cylY(m, "IceGlow", 0.2, 14, c + Vector3.new(0, 0.5, 0), C.Ice, { Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false })
	local pl = Instance.new("PointLight"); pl.Color = C.Ice; pl.Range = 26; pl.Brightness = 1.5; pl.Parent = glow
	-- La estación de recarga se muda al hielo: derretir hielo = agua; electrólisis = oxígeno
	local refill = site:FindFirstChild("RefillStation") :: BasePart?
	if refill then
		refill.Size = Vector3.new(3, 2.4, 2.4)
		refill.CFrame = CFrame.new(c + Vector3.new(8, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		local tank = P(m, "MeltTank", Vector3.new(3, 4, 3), CFrame.new(c + Vector3.new(11, 2, 0)), C.White)
		sign(P(m, "MeltSign", Vector3.new(6, 1.6, 0.2), CFrame.new(c + Vector3.new(11, 5.4, 0)) * CFrame.Angles(0, math.rad(-90), 0), C.Dark), Enum.NormalId.Front, "ICE → WATER + OXYGEN")
		tank:SetAttribute("Info", "Melting ice gives water. Splitting water (electrolysis) gives oxygen.")
	end
	-- Rampa para bajar al fondo (por el lado de la base)
	P(m, "RampDown", Vector3.new(8, 1, 22), CFrame.lookAt(c + Vector3.new(14, 1.2, -14), c + Vector3.new(6, 0, -6)) * CFrame.Angles(math.rad(-6), 0, 0), C.RockDark, { Material = Enum.Material.Slate })
end

---------------------------------------------------------------------
-- 2) Hábitat con interior (reemplaza la plantilla cerrada)
---------------------------------------------------------------------
local function buildHabitatTemplate()
	local templates = ServerStorage:FindFirstChild("SO_Templates")
	if not templates then return end
	local old = templates:FindFirstChild("habitat")
	if old and old:GetAttribute("SO_Hollow") then return end
	if old then old.Name = "habitat_closed" end
	local m = Instance.new("Model")
	m.Name = "habitat"
	m:SetAttribute("SO_Hollow", true)
	local L, W, H = 22, 12, 9 -- largo (X), ancho (Z), alto
	local floor = P(m, "Floor", Vector3.new(L, 0.6, W), CFrame.new(0, 0.3, 0), C.Floor)
	-- Paredes largas con ventanas
	for _, z in { -W / 2, W / 2 } do
		P(m, "WallLow", Vector3.new(L, 4, 0.6), CFrame.new(0, 2.6, z), C.White)
		P(m, "WallHigh", Vector3.new(L, 2, 0.6), CFrame.new(0, H - 0.4, z), C.White)
		for _, x in { -7, 0, 7 } do
			P(m, "Window", Vector3.new(4, 2.6, 0.3), CFrame.new(x, 5.9, z), Color3.fromHex("9ED8FF"), { Material = Enum.Material.Glass, Transparency = 0.4 })
		end
		for _, x in { -10.5, -3.5, 3.5, 10.5 } do
			P(m, "Post", Vector3.new(1, 2.6, 0.6), CFrame.new(x, 5.9, z), C.White)
		end
		P(m, "RedStripe", Vector3.new(L, 0.5, 0.7), CFrame.new(0, 4.4, z), C.Red)
	end
	-- Extremos con puerta (5 de ancho, 7 de alto) a los dos lados
	for _, x in { -L / 2, L / 2 } do
		P(m, "EndL", Vector3.new(0.6, H, (W - 5) / 2), CFrame.new(x, H / 2 + 0.3, -(W + 5) / 4), C.White)
		P(m, "EndR", Vector3.new(0.6, H, (W - 5) / 2), CFrame.new(x, H / 2 + 0.3, (W + 5) / 4), C.White)
		P(m, "EndTop", Vector3.new(0.6, H - 7, 5), CFrame.new(x, 7.3 + (H - 7) / 2, 0), C.White)
		P(m, "DoorFrame", Vector3.new(0.8, 0.5, 5.6), CFrame.new(x, 7.5, 0), C.Teal, { Material = Enum.Material.Neon })
	end
	-- Techo curvo (3 placas)
	P(m, "Roof", Vector3.new(L + 1, 0.6, W - 4), CFrame.new(0, H + 1.4, 0), C.Lavender)
	P(m, "RoofL", Vector3.new(L + 1, 0.6, 3.4), CFrame.new(0, H + 0.6, -W / 2 + 1.3) * CFrame.Angles(math.rad(35), 0, 0), C.Lavender)
	P(m, "RoofR", Vector3.new(L + 1, 0.6, 3.4), CFrame.new(0, H + 0.6, W / 2 - 1.3) * CFrame.Angles(math.rad(-35), 0, 0), C.Lavender)
	local lamp = P(m, "Lamp", Vector3.new(8, 0.2, 1), CFrame.new(0, H + 0.9, 0), C.White, { Material = Enum.Material.Neon })
	local sl = Instance.new("SurfaceLight"); sl.Face = Enum.NormalId.Bottom; sl.Range = 14; sl.Brightness = 1.4; sl.Angle = 140; sl.Parent = lamp

	-- Literas (2) con bolsas de dormir
	for i, x in { -8, -4 } do
		P(m, "Bunk" .. i, Vector3.new(3, 0.5, 5.5), CFrame.new(x, 1.6, -3), C.Metal)
		P(m, "SleepingBag" .. i, Vector3.new(2.6, 0.5, 4.6), CFrame.new(x, 2.1, -3), C.Blue)
	end
	-- Filtro de CO2 (rack como el CDRA de la ISS): caja con rejillas y cartuchos
	local scrub = P(m, "AirScrubber", Vector3.new(3, 5.5, 2), CFrame.new(-9.5, 3.35, 4.5), C.White)
	for k = 0, 2 do
		cylY(m, "FilterCartridge", 1.4, 0.9, Vector3.new(-9.5 + (k - 1) * 0.95, 1.6, 3.3), Color3.fromHex("E9E3C8"))
		P(m, "Grille", Vector3.new(2.4, 0.3, 0.1), CFrame.new(-9.5, 4 + k * 0.6, 3.45), C.Dark)
	end
	sign(P(m, "ScrubberSign", Vector3.new(3, 0.9, 0.1), CFrame.new(-9.5, 6.6, 3.45), C.Dark), Enum.NormalId.Front, "CO₂ FILTER")
	-- Sensor de radiación (como el HERA de Orion): caja en la pared con pantalla de dosis
	local sensor = P(m, "RadSensor", Vector3.new(2.4, 1.6, 0.8), CFrame.new(2, 5.6, -W / 2 + 0.75), Color3.fromHex("C9CCD8"))
	local screen = P(m, "RadScreen", Vector3.new(1.8, 1, 0.1), CFrame.new(2, 5.7, -W / 2 + 1.2), C.Dark)
	local label = sign(screen, Enum.NormalId.Back, "DOSE: NORMAL", C.Green)
	label.Name = "DoseText"
	P(m, "RadLight", Vector3.new(0.4, 0.4, 0.2), CFrame.new(3, 6.2, -W / 2 + 1.2), C.Green, { Material = Enum.Material.Neon })
	sign(P(m, "SensorSign", Vector3.new(3.4, 0.7, 0.1), CFrame.new(2, 6.9, -W / 2 + 1.2), C.Dark), Enum.NormalId.Back, "RADIATION SENSOR")
	-- Refugio de tormenta: rincón rodeado de bolsas de agua y provisiones (NASA, Orion)
	local sx = 7.5
	for k = 0, 3 do
		P(m, "WaterBag", Vector3.new(1.2, 1.4, 4.4), CFrame.new(sx - 2.6, 1.3 + k * 1.45, 3), C.Water, { Material = Enum.Material.Plastic, Transparency = 0.15 })
		P(m, "WaterBagTop", Vector3.new(5, 1.4, 1.2), CFrame.new(sx, 1.3 + k * 1.45, 0.7), C.Water, { Material = Enum.Material.Plastic, Transparency = 0.15 })
	end
	P(m, "Shelter", Vector3.new(4.5, 0.2, 4.5), CFrame.new(sx, 0.7, 3.2), C.Gold, { Material = Enum.Material.Neon, Transparency = 0.5 })
	sign(P(m, "ShelterSign", Vector3.new(4.6, 0.9, 0.1), CFrame.new(sx, 7.4, 0.62), C.Dark), Enum.NormalId.Front, "STORM SHELTER")
	-- Mesa y estante de comida
	P(m, "Table", Vector3.new(3, 0.3, 2), CFrame.new(-1, 2.4, 3.5), C.Metal)
	P(m, "TableLeg", Vector3.new(0.4, 2, 0.4), CFrame.new(-1, 1.3, 3.5), C.Metal)

	m.PrimaryPart = floor
	floor.PivotOffset = CFrame.new(0, -0.3, 0)
	m.Parent = templates
	-- La región del hábitat cubre el interior
	local zone = site:FindFirstChild("HabitatZone") :: BasePart?
	if zone then zone.Size = Vector3.new(L, H, W) end
end

---------------------------------------------------------------------
-- 3) La nave elegida aterriza en la Luna
---------------------------------------------------------------------
local GS = ReplicatedStorage:WaitForChild("GameState", 10)
local SHIP_PHASES = { Landing = true, Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true, Rescue = true }
local shownFor = ""

local function setLanderVisible(on: boolean)
	local lander = site:FindFirstChild("Lander")
	if not lander then return end
	for _, d in lander:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Ramp" then
			if d:GetAttribute("SO_T") == nil then d:SetAttribute("SO_T", d.Transparency) end
			d.Transparency = on and d:GetAttribute("SO_T") or 1
			d.CanCollide = on
		end
	end
end

local function showChosenShip()
	local choice = GS and GS:GetAttribute("Choice_cap") or ""
	if choice == shownFor then return end
	local old = site:FindFirstChild("ChosenLander")
	if old then old:Destroy() end
	shownFor = choice
	local maq = ServerStorage:FindFirstChild("SO_Maquetas")
	local tpl = maq and maq:FindFirstChild(choice)
	if not tpl then setLanderVisible(true); return end
	local m = tpl:Clone()
	m.Name = "ChosenLander"
	local _, size = m:GetBoundingBox()
	local target = ({ light = 13, cargo = 22, starship = 40 })[choice] or 22 -- alto en studs (la ligera es ancha y baja)
	m:ScaleTo(m:GetScale() * target / math.max(size.Y, 0.1))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true end
	end
	local lp = site.Lander.PrimaryPart.Position
	m:PivotTo(CFrame.new(Vector3.new(lp.X, O.Y + 0.6, lp.Z)))
	m.Parent = site
	setLanderVisible(false)
end

local function resetShip()
	local old = site:FindFirstChild("ChosenLander")
	if old then old:Destroy() end
	shownFor = ""
	setLanderVisible(true)
end

---------------------------------------------------------------------
-- 4) Antena de comunicaciones (una sola, funcional): torre de celosía con plato que apunta a la Tierra.
--    En la llamarada solar el plato se desalinea; al completar "realign" vuelve a apuntar a la Tierra.
---------------------------------------------------------------------
local EARTH_DIR = Vector3.new(0.36, 0.1, 0.93).Unit -- la misma dirección que la Tierra del cielo (ZoneLighting)
local dishPivot: BasePart? = nil
local function buildAntenna()
	-- Las dos antenas viejas de la cresta se quitan
	for _, d in site:GetChildren() do
		if d.Name == "Antenna" or d.Name == "AntennaBase" then d:Destroy() end
	end
	if site:FindFirstChild("SO_CommsAntenna") then
		dishPivot = site.SO_CommsAntenna:FindFirstChild("DishPivot") :: BasePart?
		return
	end
	local m = Instance.new("Model")
	m.Name = "SO_CommsAntenna"
	local spot = O + Vector3.new(88, 0, 70)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { m }
	local hit = workspace:Raycast(spot + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), params)
	local g = hit and hit.Position or spot
	local Hh = 16
	-- Base de concreto y patas de celosía (se estrechan hacia arriba)
	P(m, "Footing", Vector3.new(5, 1, 5), CFrame.new(g + Vector3.new(0, 0.3, 0)), C.Metal, { Material = Enum.Material.Concrete })
	local function strut(a: Vector3, b: Vector3, w: number)
		P(m, "Strut", Vector3.new(w, w, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), C.White, { Material = Enum.Material.Metal })
	end
	local corners = { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1) }
	local function at(c: Vector3, y: number): Vector3
		local half = 1.4 - 0.8 * (y / Hh)
		return g + Vector3.new(c.X * half, y + 0.8, c.Z * half)
	end
	for i, c in corners do
		strut(at(c, 0), at(c, Hh), 0.3)
		local n = corners[i % 4 + 1]
		for y = 0, Hh - 4, 4 do
			strut(at(c, y), at(n, y + 4), 0.15) -- diagonales
			strut(at(c, y + 4), at(n, y + 4), 0.15) -- horizontales
		end
	end
	-- Plataforma, motor de orientación y luz de aviso
	local top = g + Vector3.new(0, Hh + 0.8, 0)
	P(m, "Platform", Vector3.new(2.4, 0.4, 2.4), CFrame.new(top), C.Metal, { Material = Enum.Material.DiamondPlate })
	P(m, "Motor", Vector3.new(1, 1.2, 1), CFrame.new(top + Vector3.new(0, 0.8, 0)), C.Dark)
	local beacon = P(m, "Beacon", Vector3.new(0.6, 0.6, 0.6), CFrame.new(top + Vector3.new(0, 4.6, 0)), C.Red, { Material = Enum.Material.Neon })
	beacon.Shape = Enum.PartType.Ball
	-- Plato parabólico: pivote invisible + plato + borde + brazos + alimentador; todo soldado al pivote
	local center = top + Vector3.new(0, 2.2, 0)
	local pivot = P(m, "DishPivot", Vector3.new(0.5, 0.5, 0.5), CFrame.lookAt(center, center + EARTH_DIR), C.Dark, { Transparency = 1, CanCollide = false })
	local function onDish(name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?)
		local p = P(m, name, size, pivot.CFrame * offset, color, { Anchored = false, CanCollide = false, Material = Enum.Material.SmoothPlastic })
		if shape then p.Shape = shape end
		local w = Instance.new("WeldConstraint"); w.Part0 = pivot; w.Part1 = p; w.Parent = p
		return p
	end
	local FACE = CFrame.Angles(0, math.rad(90), 0) -- eje del cilindro mirando hacia adelante
	onDish("Dish", Vector3.new(0.4, 6, 6), CFrame.new(0, 0, 0.3) * FACE, C.White, Enum.PartType.Cylinder)
	onDish("DishRim", Vector3.new(0.6, 6.4, 6.4), CFrame.new(0, 0, 0.5) * FACE, C.Metal, Enum.PartType.Cylinder)
	onDish("DishBack", Vector3.new(1, 2, 2), CFrame.new(0, 0, 1.1) * FACE, C.Metal, Enum.PartType.Cylinder)
	for k = 0, 2 do
		local a = k * math.pi * 2 / 3
		local base = Vector3.new(math.cos(a) * 2.6, math.sin(a) * 2.6, 0)
		local tip = Vector3.new(0, 0, -2.8)
		onDish("FeedArm", Vector3.new(0.12, 0.12, (tip - base).Magnitude), CFrame.lookAt((base + tip) / 2, tip), C.White)
	end
	onDish("FeedHorn", Vector3.new(0.6, 0.6, 0.8), CFrame.new(0, 0, -2.9), C.Gold)
	-- Cartel
	sign(P(m, "AntennaSign", Vector3.new(5, 1.2, 0.2), CFrame.new(g + Vector3.new(0, 2.2, 2.7)), C.Dark), Enum.NormalId.Front, "COMMS ANTENNA → EARTH")
	m.PrimaryPart = pivot
	m.Parent = site
	dishPivot = pivot
end

-- El plato se desalinea en la llamarada y vuelve a apuntar a la Tierra al completar la tarea
local TweenService = game:GetService("TweenService")
local misaligned = false
local function aimDish(ok: boolean)
	local pv = dishPivot
	if not pv or misaligned == not ok then return end
	misaligned = not ok
	local c = pv.Position
	local target = CFrame.lookAt(c, c + EARTH_DIR)
	if not ok then target = target * CFrame.Angles(math.rad(-40), math.rad(55), 0) end
	TweenService:Create(pv, TweenInfo.new(ok and 3 or 1.2, Enum.EasingStyle.Quad), { CFrame = target }):Play()
end
task.spawn(function()
	while true do
		local b = site:FindFirstChild("SO_CommsAntenna") and site.SO_CommsAntenna:FindFirstChild("Beacon") :: BasePart?
		if b then
			b.Color = misaligned and C.Gold or C.Red
			b.Transparency = 0
			task.wait(misaligned and 0.2 or 0.8)
			b.Transparency = 0.8
		end
		task.wait(misaligned and 0.2 or 1.2)
	end
end)

---------------------------------------------------------------------
-- 5) Modelos de Ramón para la Luna (ServerStorage.SO_MoonProps): cráter grande y medidor de radiación
---------------------------------------------------------------------
local PROPS = ServerStorage:FindFirstChild("SO_MoonProps")
local function buildMoonProps()
	if not PROPS then return end
	local crater = PROPS:FindFirstChild("CraterBig")
	if crater then
		-- Uno junto al punto "crater wall" de la Fase 1 (el hábitat queda contra su borde) y otro de paisaje
		for name, offset in { SO_CraterWall = Vector3.new(-60, -6, 10), SO_CraterDeco = Vector3.new(-140, -6, -95) } do
			if not site:FindFirstChild(name) then
				local c = crater:Clone()
				c.Name = name
				for _, p in c:GetDescendants() do
					if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true end
				end
				c:PivotTo(CFrame.new(O + offset))
				c.Parent = site
			end
		end
	end
	-- Medidor de radiación de Ramón en la pared del hábitat (reemplaza la caja gris)
	local meter = PROPS:FindFirstChild("RadMeter")
	local hab = ServerStorage:FindFirstChild("SO_Templates") and ServerStorage.SO_Templates:FindFirstChild("habitat")
	local box = hab and hab:FindFirstChild("RadSensor") :: BasePart?
	if meter and hab and box and not hab:FindFirstChild("RadMeterModel") then
		local m = meter:Clone()
		m.Name = "RadMeterModel"
		local _, sz = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * 2.6 / math.max(sz.Y, 0.01))
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false end
		end
		-- de frente al interior: la pared está en -Z, el medidor mira hacia +Z
		m:PivotTo(CFrame.new(box.Position + Vector3.new(0, -0.4, 0.3)) * CFrame.Angles(0, math.pi, 0))
		m.Parent = hab
		box.Transparency = 1
		local screen = hab:FindFirstChild("RadScreen") :: BasePart?
		if screen then
			screen.Transparency = 1
			for _, g in screen:GetChildren() do
				if g:IsA("SurfaceGui") then g.Enabled = false end
			end
		end
	end
end

---------------------------------------------------------------------
-- 6) Paneles solares mirando al Sol. En el polo sur el Sol va casi por el horizonte, así que las celdas
--    tienen que mirar hacia él (antes le daban la espalda). Misma dirección que el Sol del cielo (ZoneLighting).
---------------------------------------------------------------------
local SUN_FLAT = Vector3.new(-0.78, 0, -0.62).Unit
local function alignPanels(m: Instance)
	for _, unit in m:GetChildren() do
		if unit:IsA("Model") and not unit:GetAttribute("SunAligned") then
			local cells = unit:FindFirstChild("cells", true) :: BasePart?
			local back = (unit:FindFirstChild("backsheet", true) or unit:FindFirstChild("frame", true)) :: BasePart?
			if cells and back then
				-- Hacia dónde miran las celdas: de la lámina de atrás hacia las celdas (la malla viene inclinada
				-- dentro de su caja, así que el tamaño de la pieza no sirve para esto)
				local flat = (cells.Position - back.Position) * Vector3.new(1, 0, 1)
				if flat.Magnitude > 0.05 then
					local rot = CFrame.lookAt(Vector3.zero, SUN_FLAT) * CFrame.lookAt(Vector3.zero, flat.Unit):Inverse()
					local pv = unit:GetPivot()
					unit:PivotTo(CFrame.new(pv.Position) * rot * pv.Rotation)
				end
				unit:SetAttribute("SunAligned", true)
			end
		end
	end
end
local function watchPlaced(placed: Instance)
	local function check(child: Instance)
		if child.Name == "eng" then
			-- Placement arma el modelo pieza por pieza: se gira cuando termina de aparecer
			task.delay(12, function() if child.Parent then alignPanels(child) end end)
		end
	end
	for _, c in placed:GetChildren() do check(c) end
	placed.ChildAdded:Connect(check)
end
local function onSiteChild(c: Instance)
	if c.Name == "Placed" and c:IsA("Folder") then watchPlaced(c) end
end
for _, c in site:GetChildren() do onSiteChild(c) end
site.ChildAdded:Connect(onSiteChild)
-- Respaldo: al empezar la Fase 2 y la 3, por si algo se escapó
if GS then
	GS:GetAttributeChangedSignal("Phase"):Connect(function()
		local ph = GS:GetAttribute("Phase")
		if ph == "Phase2Intro" or ph == "Phase2" or ph == "Phase3" then
			local placed = site:FindFirstChild("Placed")
			local eng = placed and placed:FindFirstChild("eng")
			if eng then alignPanels(eng) end
		end
	end)
end

---------------------------------------------------------------------
-- 7) Terreno de Ramón (SO_MoonProps): pared de roca, cresta soleada, bloques de hielo y un cráter con hielo.
--    Las piezas viejas quedan invisibles y sin choque (otros scripts usan su posición).
---------------------------------------------------------------------
local function placeProp(name: string, newName: string, scale: number, cf: CFrame): Model?
	if site:FindFirstChild(newName) or not PROPS or not PROPS:FindFirstChild(name) then return nil end
	local m = PROPS[name]:Clone() :: Model
	m.Name = newName
	m:ScaleTo(m:GetScale() * scale)
	m:PivotTo(cf)
	m.Parent = site
	return m
end
local function hideOld(p: Instance?)
	if p and p:IsA("BasePart") then p.Transparency = 1; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false end
end
local function buildRamonTerrain()
	if not PROPS then return end
	-- Pared de roca (punto "behind a rock wall" del Engineer): del tamaño del bloque viejo (30 de largo)
	local wall = site:FindFirstChild("RockWall") :: BasePart?
	if wall and PROPS:FindFirstChild("RockWall") then
		local _, sz = PROPS.RockWall:GetBoundingBox()
		if placeProp("RockWall", "SO_RockWall", wall.Size.X / sz.X, CFrame.new(wall.Position.X, O.Y, wall.Position.Z)) then hideOld(wall) end
	end
	-- Cresta soleada: 60 de ancho, entera y apoyada en el suelo, detrás del punto "sunny ridge" (si quedara
	-- encima del punto, los paneles se meterían dentro de la montaña)
	local ridge = site:FindFirstChild("SunnyRidge") :: BasePart?
	if ridge and PROPS:FindFirstChild("Ridge") then
		local _, sz = PROPS.Ridge:GetBoundingBox()
		if placeProp("Ridge", "SO_Ridge", 60 / sz.X, CFrame.new(ridge.Position.X + 10, O.Y, ridge.Position.Z + 32)) then
			hideOld(ridge)
			-- la antena se vuelve a apoyar sobre la cresta nueva
			local ant = site:FindFirstChild("SO_CommsAntenna")
			if ant then ant:Destroy() end
			buildAntenna()
		end
	end
	-- Bloques de hielo de Ramón en el fondo del cráter de hielo (reemplazan los cubos)
	local crater = site:FindFirstChild("SO_IceCraterDeep")
	if crater and not crater:FindFirstChild("RamonIce") then
		local n = 0
		for _, d in crater:GetChildren() do
			if d:IsA("BasePart") and d.Name == "IceBlock" then
				n += 1
				local src = PROPS:FindFirstChild("IceBlock" .. (((n - 1) % 3) + 1))
				if src then
					local b = src:Clone()
					b.Name = "RamonIce"
					local _, sz = b:GetBoundingBox()
					b:ScaleTo(b:GetScale() * (d.Size.X * 1.2) / sz.X)
					b:PivotTo(CFrame.new(d.Position.X, d.Position.Y - d.Size.Y / 2, d.Position.Z) * CFrame.Angles(0, n * 1.3, 0))
					b.Parent = crater
					hideOld(d)
				end
			end
		end
	end
	-- Un cráter con hielo de paisaje, lejos de la base
	placeProp("IceCrater", "SO_IceCraterDeco", 10, CFrame.new(O + Vector3.new(135, -5, -95)))
end

buildIceCrater()
buildHabitatTemplate()
buildAntenna()
buildMoonProps()
buildRamonTerrain()
if GS then
	GS:GetAttributeChangedSignal("Emergency"):Connect(function()
		local e = GS:GetAttribute("Emergency") or ""
		if e == "flare" then aimDish(false) elseif e == "" then aimDish(true) end
	end)
	GS:GetAttributeChangedSignal("EmergencyProgress"):Connect(function()
		if GS:GetAttribute("Emergency") == "flare" and GS:GetAttribute("EmergencyChoice") == "A" and GS:GetAttribute("EmergencyProgress") == "1/1" then
			aimDish(true)
		end
	end)
	GS:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = GS:GetAttribute("Phase") or ""
		if SHIP_PHASES[phase] then
			showChosenShip()
		elseif phase == "RoleSelect" or phase == "Title" then
			resetShip()
		end
	end)
end
