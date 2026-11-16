-- ZoneLighting (LocalScript) -> StarterPlayer.StarterPlayerScripts.ZoneLighting
-- Dueño: Isaac + Claude. Cambia la luz SOLO en este cliente y SOLO en la zona de la Luna.
-- No toca la iluminación del place en Edit: guarda la original y la devuelve al salir de la Luna.
-- Cielo lunar: negro con muchas estrellas, sin atmósfera, y un Sol muy brillante pegado al horizonte
-- (en el polo sur de la Luna el Sol siempre está bajo: sombras largas). La Tierra también se ve baja, en el horizonte.
-- En la emergencia "flare" el Sol se ve como en las imágenes del SDO de la NASA (luz ultravioleta extrema, dorada).

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local KEYS = { "ClockTime", "Brightness", "ExposureCompensation", "Ambient", "OutdoorAmbient", "FogEnd", "FogColor",
	"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness", "GeographicLatitude" }

-- Luna: noche (cielo negro con estrellas) pero el suelo bien iluminado, como en la demo
local MOON = {
	-- 15-nov: antes 5.5 y 0.35; la nave blanca y el suelo se veían como un foco (pedido de Isaac)
	ClockTime = 20.05, Brightness = 3.2, ExposureCompensation = 0,
	Ambient = Color3.fromHex("4A4F78"), OutdoorAmbient = Color3.fromHex("7C82A8"),
	FogEnd = 100000, FogColor = Color3.fromHex("000000"),
	EnvironmentDiffuseScale = 0.4, EnvironmentSpecularScale = 0.6,
	ShadowSoftness = 0.05, -- sombras nítidas (no hay aire que las suavice)
	GeographicLatitude = -89.5, -- polo sur: la luz llega muy baja
}
local SUN_DIR = Vector3.new(-0.78, 0.07, -0.62).Unit -- dirección del Sol, casi en el horizonte
local SUN_DIST = 1800
-- Tierra: dirección, distancia y radio en Config.MoonSky (los usa también SO_EggsClient). Tamaño real ~1,9°.
local EARTH_DIR = Config.MoonSky.EarthDir -- desde el polo sur, la Tierra queda pegada al horizonte
local EARTH_DIST = Config.MoonSky.EarthDist
local GS = ReplicatedStorage:WaitForChild("GameState")

local original = {}
for _, k in KEYS do original[k] = (Lighting :: any)[k] end
local atm = Lighting:FindFirstChildOfClass("Atmosphere")
local atmOriginal = atm and { Density = atm.Density, Offset = atm.Offset, Color = atm.Color, Decay = atm.Decay, Haze = atm.Haze, Glare = atm.Glare }

---------------------------------------------------------------------
-- Piezas que solo existen en este cliente mientras está en la Luna
---------------------------------------------------------------------
local moonSky: Sky? = nil
local hiddenSkies: { Sky } = {}
local effects: { Instance } = {}
local sun: Part? = nil
local earth: Model? = nil
-- Modelos 3D de Ramón (Tierra, Sol y Sol en tormenta). Si faltan, se usan los hechos con piezas.
local SKY = ReplicatedStorage:FindFirstChild("SO_SkyModels")
local sunModel: Model? = nil
local stormModel: Model? = nil
local SUN_MODEL_DIAM = 70 * 7 / 2 -- la corona mide 7 y la fotosfera 2: la fotosfera queda del tamaño del Sol (70)
local function skyClone(name: string, diam: number): Model?
	local src = SKY and SKY:FindFirstChild(name)
	if not src then return nil end
	local m = src:Clone() :: Model
	local _, sz = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * diam / math.max(sz.X, 0.01))
	m.Parent = camera
	return m
end

local function makeSun(): Part
	local p = Instance.new("Part")
	p.Name = "SO_MoonSun"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(70, 70, 70)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromHex("FFF4DC")
	-- Halo: círculos cada vez más grandes y transparentes (sin imágenes externas)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Halo"
	bb.Size = UDim2.fromScale(2.6, 2.6) -- halo moderado (antes tapaba la pantalla al mirar al Sol)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Parent = p
	for i, t in { 0.55, 0.7, 0.8, 0.88, 0.93, 0.96 } do
		local f = Instance.new("Frame")
		local s = 0.12 + i * 0.145
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(s, s)
		f.BackgroundColor3 = i <= 2 and Color3.fromHex("FFFFFF") or Color3.fromHex("FFE2A8")
		f.BackgroundTransparency = t
		f.BorderSizePixel = 0
		f.ZIndex = 10 - i
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = f
		f.Parent = bb
	end
	-- Franja de luz horizontal (destello), como el disco brillante de la referencia pero real: un reflejo
	local flare = Instance.new("Frame")
	flare.AnchorPoint = Vector2.new(0.5, 0.5)
	flare.Position = UDim2.fromScale(0.5, 0.5)
	flare.Size = UDim2.fromScale(1, 0.035)
	flare.BackgroundColor3 = Color3.fromHex("FFF0D0")
	flare.BackgroundTransparency = 0.55
	flare.BorderSizePixel = 0
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = flare
	flare.Parent = bb
	p.Parent = camera -- vive en la cámara: solo este cliente lo ve
	return p
end

---------------------------------------------------------------------
-- La Tierra vista desde la Luna: océano, continentes, nubes y borde de atmósfera. Gira despacio.
---------------------------------------------------------------------
local EARTH_R = Config.MoonSky.EarthRadius
local function makeEarth(): Model
	local ramon = skyClone("Earth", EARTH_R * 2)
	if ramon then
		-- halo de atmósfera detrás del modelo de Ramón
		local mesh = ramon:FindFirstChildWhichIsA("BasePart", true)
		if mesh then
			local halo = Instance.new("BillboardGui")
			halo.Name = "Atmosphere"
			halo.Size = UDim2.fromScale(EARTH_R * 2.2, EARTH_R * 2.2)
			halo.LightInfluence = 0
			halo.Parent = mesh
			local glow = Instance.new("Frame")
			glow.Size = UDim2.fromScale(1, 1)
			glow.BackgroundColor3 = Color3.fromHex("8CC4FF")
			glow.BackgroundTransparency = 0.55
			glow.BorderSizePixel = 0
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = glow
			glow.Parent = halo
		end
		return ramon
	end
	local m = Instance.new("Model")
	m.Name = "SO_MoonEarth"
	local function ball(name: string, d: number, pos: Vector3, color: Color3, mat: Enum.Material, transp: number?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(d, d, d)
		p.CFrame = CFrame.new(pos)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = mat
		p.Color = color
		p.Transparency = transp or 0
		p.Parent = m
		return p
	end
	local core = ball("Ocean", EARTH_R * 2, Vector3.zero, Color3.fromHex("1F5FC9"), Enum.Material.SmoothPlastic)
	m.PrimaryPart = core
	-- Parche plano pegado a la superficie (elipsoide aplanado que sigue la curva)
	local function patch(name: string, dir: Vector3, w: number, l: number, lift: number, color: Color3, mat: Enum.Material, transp: number?, spinAng: number?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(1, 1, 1)
		local right = dir:Cross(math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis).Unit
		local fwd = right:Cross(dir).Unit
		p.CFrame = CFrame.fromMatrix(dir * (EARTH_R + lift - 1.6), right, dir, fwd) * CFrame.Angles(0, spinAng or 0, 0)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = mat
		p.Color = color
		p.Transparency = transp or 0
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(w, 6, l) -- grueso y hundido: cubre la curva sin dejar huecos
		mesh.Parent = p
		p.Parent = m
	end
	local function sph(lat: number, lon: number): Vector3
		local a, b = math.rad(lat), math.rad(lon)
		return Vector3.new(math.cos(a) * math.cos(b), math.sin(a), math.cos(a) * math.sin(b))
	end
	-- Continentes: grupos de manchas verdes con zonas secas (café), como América, África-Europa, Asia y Australia
	local rng = Random.new(7)
	local CONT = { { 40, 0, 7 }, { 0, 20, 8 }, { 45, 80, 9 }, { -25, 135, 4 }, { 40, 260, 7 }, { -15, 300, 6 } }
	for _, c in CONT do
		for k = 1, c[3] do
			local dir = sph(c[1] + rng:NextNumber(-16, 16), c[2] + rng:NextNumber(-18, 18))
			local dry = rng:NextNumber() < 0.15
			patch("Land", dir, rng:NextNumber(14, 24), rng:NextNumber(16, 30), 0, dry and Color3.fromHex("CDB283") or Color3.fromHex("3F8F3B"), Enum.Material.Grass, 0, rng:NextNumber(0, 3))
		end
	end
	-- Hielo polar
	patch("IceN", Vector3.yAxis, 30, 30, 0.2, Color3.fromHex("F4F8FF"), Enum.Material.Snow)
	patch("IceS", -Vector3.yAxis, 36, 36, 0.2, Color3.fromHex("F4F8FF"), Enum.Material.Snow)
	-- Nubes: franjas blancas alargadas, un poco por encima
	for _ = 1, 16 do
		local dir = sph(rng:NextNumber(-60, 60), rng:NextNumber(0, 360))
		patch("Cloud", dir, rng:NextNumber(5, 9), rng:NextNumber(20, 34), 0.6, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0.12, rng:NextNumber(-0.4, 0.4) + math.pi / 2)
	end
	-- Atmósfera: halo azul detrás de la Tierra (la esfera tapa el centro, solo se ve el borde)
	local halo = Instance.new("BillboardGui")
	halo.Name = "Atmosphere"
	halo.Size = UDim2.fromScale(EARTH_R * 2.25, EARTH_R * 2.25)
	halo.LightInfluence = 0
	halo.Parent = core
	local glow = Instance.new("Frame")
	glow.Size = UDim2.fromScale(1, 1)
	glow.BackgroundColor3 = Color3.fromHex("8CC4FF")
	glow.BackgroundTransparency = 0.45
	glow.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = glow
	glow.Parent = halo
	m.Parent = camera
	return m
end

---------------------------------------------------------------------
-- Llamarada solar: el Sol se ve dorado como en las imágenes del SDO (171 Å), con regiones activas que
-- destellan y arcos de plasma en el borde. Se activa con la emergencia "flare".
---------------------------------------------------------------------
local flareParts: { Instance } = {}
local flareOn = false
local function setFlare(on: boolean)
	if on == flareOn or not sun then return end
	flareOn = on
	for _, x in flareParts do x:Destroy() end
	table.clear(flareParts)
	if stormModel and sunModel then
		stormModel.Parent = on and camera or nil
		if on then sunModel.Parent = nil else sunModel.Parent = camera end
	end
	local halo = sun:FindFirstChild("Halo") :: BillboardGui?
	if not on then
		sun.Color = Color3.fromHex("FFF4DC")
		sun.Size = Vector3.new(70, 70, 70)
		if halo then
			halo.Size = UDim2.fromScale(2.6, 2.6)
			for _, fr in halo:GetChildren() do
				if fr:IsA("Frame") then fr.BackgroundColor3 = (fr.ZIndex >= 8) and Color3.fromHex("FFFFFF") or Color3.fromHex("FFE2A8") end
			end
		end
		return
	end
	sun.Color = Color3.fromHex("D99A00")
	sun.Size = Vector3.new(84, 84, 84)
	if halo then
		halo.Size = UDim2.fromScale(3.6, 3.6)
		for _, fr in halo:GetChildren() do
			if fr:IsA("Frame") then fr.BackgroundColor3 = Color3.fromHex("FFC21A") end
		end
	end
	local rng = Random.new()
	-- Con el modelo de Ramón (Sol en tormenta, estilo SDO) no hacen falta las manchas ni los arcos hechos con piezas
	local regions = stormModel and 0 or 40
	local loops = stormModel and 0 or 16
	-- Regiones activas: manchas brillantes en una franja a cada lado del ecuador (como en el SDO)
	for _ = 1, regions do
		local lat = (rng:NextNumber() < 0.5 and 1 or -1) * rng:NextNumber(0.12, 0.45)
		local lon = rng:NextNumber(0, math.pi * 2)
		local dir = Vector3.new(math.cos(lat) * math.cos(lon), math.sin(lat), math.cos(lat) * math.sin(lon))
		local p = Instance.new("Part")
		p.Name = "ActiveRegion"
		p.Shape = Enum.PartType.Ball
		local d = rng:NextNumber(3, 8)
		p.Size = Vector3.new(d, d, d)
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromHex("FFF6C8")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
		p:SetAttribute("Dir", dir)
		p.Parent = camera
		table.insert(flareParts, p)
	end
	-- Arcos de plasma en el borde
	for _ = 1, loops do
		local p = Instance.new("Part")
		p.Name = "Loop"
		p.Size = Vector3.new(1, 1, rng:NextNumber(8, 18))
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromHex("FFD95A")
		p.Transparency = 0.35
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
		p:SetAttribute("Ang", rng:NextNumber(0, math.pi * 2))
		p.Parent = camera
		table.insert(flareParts, p)
	end
	-- Destello en toda la pantalla al empezar
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "SO_FlareFlash"
	cc.TintColor = Color3.fromHex("FFE7A0")
	cc.Brightness = 0.35
	cc.Parent = Lighting
	table.insert(flareParts, cc)
	task.spawn(function()
		for k = 1, 20 do
			if not cc.Parent then return end
			cc.Brightness = 0.35 * (1 - k / 20)
			task.wait(0.08)
		end
	end)
end

---------------------------------------------------------------------
-- Cielo como en una app de astronomía: estrellas reales vistas desde el polo sur de la Luna.
-- El eje de la Luna apunta casi al polo de la eclíptica, así que el cenit del polo sur lunar es el polo sur de la
-- eclíptica (cerca de Canopus). Altura = −latitud eclíptica; dirección = longitud eclíptica.
---------------------------------------------------------------------
local SKY_DIST = 900
local STARS = { -- nombre, AR (horas), Dec (grados), brillo 1–3
	Canopus = { 6.399, -52.70, 3 }, Achernar = { 1.629, -57.24, 3 }, Acrux = { 12.443, -63.10, 3 }, Mimosa = { 12.795, -59.69, 2 },
	Gacrux = { 12.519, -57.11, 2 }, DeltaCru = { 12.252, -58.75, 1 }, AlphaCen = { 14.660, -60.84, 3 }, Hadar = { 14.064, -60.37, 2 },
	Sirius = { 6.752, -16.72, 3 }, Rigel = { 5.242, -8.20, 3 }, Betelgeuse = { 5.919, 7.41, 3 }, Bellatrix = { 5.419, 6.35, 2 },
	Saiph = { 5.796, -9.67, 1 }, Alnitak = { 5.679, -1.94, 2 }, Alnilam = { 5.604, -1.20, 2 }, Mintaka = { 5.533, -0.30, 2 },
	Antares = { 16.490, -26.43, 3 }, Shaula = { 17.560, -37.10, 2 }, Dschubba = { 16.006, -22.62, 1 }, Sargas = { 17.622, -43.00, 2 },
	Fomalhaut = { 22.961, -29.62, 2 }, Peacock = { 20.427, -56.73, 2 },
}
local LINES = {
	{ "Acrux", "Gacrux" }, { "Mimosa", "DeltaCru" }, { "AlphaCen", "Hadar" },
	{ "Betelgeuse", "Bellatrix" }, { "Betelgeuse", "Alnitak" }, { "Bellatrix", "Mintaka" }, { "Alnitak", "Alnilam" },
	{ "Alnilam", "Mintaka" }, { "Alnitak", "Saiph" }, { "Mintaka", "Rigel" },
	{ "Dschubba", "Antares" }, { "Antares", "Sargas" }, { "Sargas", "Shaula" },
}
local SHOW_LABELS = false -- Isaac pidió el cielo sin nombres (15-nov)
local LABELS = { Acrux = "Southern Cross", AlphaCen = "Alpha Centauri", Canopus = "Canopus", Achernar = "Achernar",
	Alnilam = "Orion", Antares = "Scorpius", Sirius = "Sirius", Fomalhaut = "Fomalhaut" }

local function skyDir(raH: number, decD: number): (Vector3, number)
	local eps = math.rad(23.44)
	local a, d = math.rad(raH * 15), math.rad(decD)
	local sinB = math.sin(d) * math.cos(eps) - math.cos(d) * math.sin(eps) * math.sin(a)
	local lam = math.atan2(math.sin(a) * math.cos(eps) + math.tan(d) * math.sin(eps), math.cos(a))
	local alt = -math.asin(sinB)
	return Vector3.new(math.cos(alt) * math.cos(lam), math.sin(alt), math.cos(alt) * math.sin(lam)), alt
end

local skyModel: Model? = nil
local function makeSkyDome(): Model
	local m = Instance.new("Model")
	m.Name = "SO_SkyDome"
	local center = Instance.new("Part")
	center.Name = "Center"; center.Anchored = true; center.CanCollide = false; center.CanQuery = false; center.Transparency = 1
	center.Size = Vector3.new(1, 1, 1); center.CFrame = CFrame.new(); center.Parent = m
	m.PrimaryPart = center
	local function star(pos: Vector3, size: number, color: Color3)
		local s = Instance.new("Part")
		s.Shape = Enum.PartType.Ball; s.Anchored = true; s.CanCollide = false; s.CanQuery = false; s.CastShadow = false
		s.Material = Enum.Material.Neon; s.Color = color; s.Size = Vector3.new(size, size, size); s.CFrame = CFrame.new(pos)
		s.Parent = m
	end
	-- Estrellas de fondo (más grandes que las de Roblox para que se noten)
	local rng = Random.new(42)
	for _ = 1, 260 do
		local u, t = rng:NextNumber(0.03, 1), rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(1 - u * u)
		local c = ({ Color3.fromHex("FFFFFF"), Color3.fromHex("CFE0FF"), Color3.fromHex("FFF1D6") })[rng:NextInteger(1, 3)]
		star(Vector3.new(r * math.cos(t), u, r * math.sin(t)) * SKY_DIST, rng:NextNumber(2.4, 5), c)
	end
	-- Estrellas reales, líneas de constelación y nombres (estilo app de astronomía)
	local pos: { [string]: Vector3 } = {}
	for name, s in STARS do
		local dir, alt = skyDir(s[1], s[2])
		if alt > 0.02 then
			pos[name] = dir * SKY_DIST
			star(pos[name], 5 + s[3] * 3, Color3.fromHex("FFFFFF"))
			if SHOW_LABELS and LABELS[name] then
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.fromOffset(150, 20); bb.StudsOffsetWorldSpace = Vector3.new(0, -14, 0); bb.LightInfluence = 0
				local l = Instance.new("TextLabel")
				l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Text = LABELS[name]
				l.TextColor3 = Color3.fromHex("B8C4FF"); l.TextTransparency = 0.25; l.Font = Enum.Font.GothamMedium; l.TextScaled = true
				l.Parent = bb
				local anchor = Instance.new("Part")
				anchor.Anchored = true; anchor.CanCollide = false; anchor.CanQuery = false; anchor.Transparency = 1; anchor.Size = Vector3.new(1, 1, 1)
				anchor.CFrame = CFrame.new(pos[name]); anchor.Parent = m
				bb.Parent = anchor
			end
		end
	end
	for _, ln in LINES do
		local a, b = pos[ln[1]], pos[ln[2]]
		if a and b then
			local l = Instance.new("Part")
			l.Anchored = true; l.CanCollide = false; l.CanQuery = false; l.CastShadow = false
			l.Material = Enum.Material.Neon; l.Color = Color3.fromHex("6F86D9"); l.Transparency = 0.55
			l.Size = Vector3.new(1.3, 1.3, (a - b).Magnitude); l.CFrame = CFrame.lookAt((a + b) / 2, b)
			l.Parent = m
		end
	end
	m.Parent = camera
	return m
end

local function addEffect(class: string, props: { [string]: any })
	local e = Instance.new(class)
	e.Name = "SO_Moon" .. class
	for k, v in props do (e :: any)[k] = v end
	e.Parent = Lighting
	table.insert(effects, e)
end

local function enterMoon()
	for _, k in KEYS do (Lighting :: any)[k] = MOON[k] end
	if atm then
		-- Sin aire: sin bruma ni color en el cielo
		atm.Density = 0; atm.Haze = 0; atm.Glare = 0; atm.Offset = 0
	end
	-- Cielo propio: estrellas a montones, sin el Sol ni la Luna de Roblox (ponemos los nuestros)
	for _, s in Lighting:GetChildren() do
		if s:IsA("Sky") then table.insert(hiddenSkies, s); s.Parent = nil end
	end
	local sky = Instance.new("Sky")
	sky.Name = "SO_MoonSky"
	sky.StarCount = 5000
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting
	moonSky = sky
	-- Brillo del Sol y del neón, y más contraste (paleta fría)
	-- 15-nov: umbral alto para que solo brillen el neón y el Sol, no las superficies blancas (antes 1.6 / 40 / 0.9)
	addEffect("BloomEffect", { Intensity = 0.5, Size = 24, Threshold = 1.6 })
	addEffect("ColorCorrectionEffect", { Contrast = 0.18, Saturation = -0.05, TintColor = Color3.fromHex("EEF0FF") })
	addEffect("SunRaysEffect", { Intensity = 0.12, Spread = 0.6 })
	sun = makeSun()
	sunModel = skyClone("Sun", SUN_MODEL_DIAM)
	stormModel = skyClone("SunStorm", SUN_MODEL_DIAM)
	if stormModel then stormModel.Parent = nil end
	if sunModel then sun.Transparency = 1 end -- el halo sigue; la bola neón queda escondida detrás del modelo
	skyModel = makeSkyDome()
	earth = makeEarth()
	-- La Tierra vieja del mapa estaba muy alta: se esconde solo en este cliente
	local site = workspace:FindFirstChild("MoonSite")
	for _, n in { "Earth", "EarthLand1", "EarthLand2" } do
		local p = site and site:FindFirstChild(n) :: BasePart?
		if p then p.LocalTransparencyModifier = 1 end
	end
	setFlare(GS:GetAttribute("Emergency") == "flare")
end

local function leaveMoon()
	for _, k in KEYS do (Lighting :: any)[k] = original[k] end
	if atm and atmOriginal then
		for k, v in atmOriginal do (atm :: any)[k] = v end
	end
	if moonSky then moonSky:Destroy(); moonSky = nil end
	for _, s in hiddenSkies do s.Parent = Lighting end
	table.clear(hiddenSkies)
	for _, e in effects do e:Destroy() end
	table.clear(effects)
	if sun then sun:Destroy(); sun = nil end
	if skyModel then skyModel:Destroy(); skyModel = nil end
	if earth then earth:Destroy(); earth = nil end
	setFlare(false)
	if sunModel then sunModel:Destroy(); sunModel = nil end
	if stormModel then stormModel:Destroy(); stormModel = nil end
	for _, x in flareParts do x:Destroy() end
	table.clear(flareParts)
	flareOn = false
end

local current = "earth"
local function zoneOf(x: number): string
	return math.abs(x - Config.Zones.Moon.X) < 1500 and "moon" or "earth"
end

-- El Sol sigue a la cámara para estar siempre en el horizonte, muy lejos
RunService.RenderStepped:Connect(function()
	if sun then
		sun.CFrame = CFrame.new(camera.CFrame.Position + SUN_DIR * SUN_DIST)
		-- el modelo del Sol (normal o en tormenta) acompaña a la bola y gira despacio
		local active = (flareOn and stormModel) or (not flareOn and sunModel) or nil
		if active then
			active:PivotTo(CFrame.new(sun.Position) * CFrame.Angles(0, os.clock() * 0.05, 0))
		end
	end
	if skyModel then
		skyModel:PivotTo(CFrame.new(camera.CFrame.Position))
	end
	if earth then
		-- gira una vuelta cada 2 minutos (un "día" del juego), con el eje inclinado
		earth:PivotTo(CFrame.new(camera.CFrame.Position + EARTH_DIR * EARTH_DIST) * CFrame.Angles(math.rad(-23), os.clock() * math.pi / 60, 0))
	end
	if sun and flareOn then
		local c, r0, t = sun.Position, sun.Size.X / 2, os.clock()
		local toCam = (camera.CFrame.Position - c).Unit
		local right = toCam:Cross(Vector3.yAxis).Unit
		local up = right:Cross(toCam).Unit
		for i, x in flareParts do
			if x:IsA("BasePart") then
				if x.Name == "ActiveRegion" then
					local d = x:GetAttribute("Dir") :: Vector3
					-- las manchas quedan en la cara visible y destellan
					local v = right * d.X + up * d.Y + toCam * math.abs(d.Z)
					x.CFrame = CFrame.new(c + v.Unit * (r0 - 1))
					x.Transparency = 0.15 + 0.5 * (0.5 + 0.5 * math.sin(t * 6 + i))
				else
					local a = (x:GetAttribute("Ang") :: number) + math.sin(t + i) * 0.05
					local out = right * math.cos(a) + up * math.sin(a)
					local edge = c + out * (r0 + 3) + toCam * 2
					x.CFrame = CFrame.lookAt(edge, edge + out) * CFrame.Angles(0, 0, t * 2 + i)
				end
			end
		end
	end
end)

GS:GetAttributeChangedSignal("Emergency"):Connect(function()
	if sun then setFlare(GS:GetAttribute("Emergency") == "flare") end
end)

while true do
	task.wait(0.5)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local z = zoneOf(root.Position.X)
		if z ~= current then
			current = z
			if z == "moon" then enterMoon() else leaveMoon() end
		end
	end
end
