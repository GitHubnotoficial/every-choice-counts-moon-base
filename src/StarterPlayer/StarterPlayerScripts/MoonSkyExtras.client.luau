-- MoonSkyExtras (LocalScript) -> StarterPlayer.StarterPlayerScripts.MoonSkyExtras
-- Cielo visto desde la Luna, mezcla de las dos imágenes de referencia:
--   - imagen 1: cielo muy oscuro lleno de estrellas y un resplandor turquesa a lo largo del horizonte
--     (los reflectores de la base están en Workspace.MoonSite.MoonDetail.Searchlights);
--   - imagen 2: la Tierra grande saliendo por el horizonte con el Sol brillando en su borde, nubes de galaxia
--     moradas y azules (suaves), planetas, satélites y cohetes con fuego.
-- NO cambia ZoneLighting (Isaac). Solo trabaja en este cliente, sobre lo que ZoneLighting pone en la cámara:
--   - "SO_SkyDome" (domo de estrellas que sigue a la cámara): aquí se agregan las piezas nuevas.
--   - "Earth" (modelo de Ramón) o "SO_MoonEarth": se agranda EARTH_SCALE veces.
-- Cuando ZoneLighting borra el domo y la Tierra (al salir de la Luna), todo esto se borra con ellos.
-- [Copia en src/ hecha por Claude el 15-nov: el script original solo existía en Studio.]

local RunService = game:GetService("RunService")

-- [arreglo Claude 15-nov, pedido de Isaac] Tierra a tamaño real visto desde la Luna (~1,9°, Config.MoonSky). Antes 12.
local EARTH_SCALE = 1
local EARTH_AZ = 69 -- rumbo de la Tierra en el cielo (el mismo que usa ZoneLighting); todo se arma alrededor
local DIST = 860 -- distancia de las piezas del cielo (las estrellas de ZoneLighting están a 900)

local camera = workspace.CurrentCamera
local dome: Model? = nil
local earth: Model? = nil
local glare: BasePart? = nil
local rockets: { { part: Model, a: Vector3, b: Vector3, speed: number, phase: number } } = {}

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, transparency: number?, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0
	p.Size = size
	if shape then
		p.Shape = shape
	end
	p.CFrame = cf
	p.Parent = parent
	return p
end

-- Nube suave (Vía Láctea o Nubes de Magallanes): elipse con degradado en un BillboardGui (en studs).
-- [arreglo Claude 15-nov] Antes eran piezas de neón con malla de esfera: con la luz lunar actual, a más de
-- ~0,5 de transparencia no se veían y a 0,5 quedaban blancas y duras. El BillboardGui (LightInfluence = 0)
-- da un brillo exacto y bordes difuminados. "transparency" = transparencia en el centro de la mancha.
local function cloud(parent: Instance, size: Vector3, cf: CFrame, color: Color3, transparency: number)
	local anchor = part(parent, Vector3.new(1, 1, 1), cf, color, 1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(size.X * 1.2, size.Y * 1.2)
	bb.LightInfluence = 0
	bb.Parent = anchor
	local function blob(rot: number): Frame
		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = f
		local g = Instance.new("UIGradient")
		g.Rotation = rot
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, transparency), NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = f
		return f
	end
	local outer = blob(0)
	blob(90).Parent = outer -- dos degradados cruzados: borde suave por todos lados
	outer.Parent = bb
end

-- Dirección desde altura (grados sobre el horizonte) y rumbo (grados)
local function dirOf(alt: number, az: number): Vector3
	local a, b = math.rad(alt), math.rad(az)
	return Vector3.new(math.cos(a) * math.cos(b), math.sin(a), math.cos(a) * math.sin(b))
end

local function earthInfo(): (Vector3?, number)
	if not (earth and earth.Parent and dome) then
		return nil, 0
	end
	local _, size = earth:GetBoundingBox()
	return (earth:GetPivot().Position - dome:GetPivot().Position).Unit, size.X / 2
end

---------------------------------------------------------------------
-- Planetas, satélites y cohetes (piezas simples)
---------------------------------------------------------------------
local function planet(parent: Instance, pos: Vector3, d: number, base: Color3, bands: { Color3 }?, ring: Color3?)
	local m = Instance.new("Model")
	m.Name = "Planet"
	part(m, Vector3.new(d, d, d), CFrame.new(pos), base, 0, Enum.PartType.Ball, Enum.Material.SmoothPlastic)
	if bands then -- franjas (como Júpiter): discos finos un poco más anchos que la esfera
		for i, c in bands do
			local y = (i - (#bands + 1) / 2) * d * 0.16
			local w = math.sqrt(math.max(0, (d / 2) ^ 2 - y ^ 2)) * 2 + 0.3
			part(m, Vector3.new(d * 0.07, w, w), CFrame.new(pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)), c, 0, Enum.PartType.Cylinder, Enum.Material.SmoothPlastic)
		end
	end
	if ring then -- anillo (como Saturno)
		part(m, Vector3.new(0.4, d * 2.1, d * 2.1), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(25), 0, 0), ring, 0.35, Enum.PartType.Cylinder, Enum.Material.SmoothPlastic)
	end
	m.Parent = parent
end

local function satellite(parent: Instance, pos: Vector3, s: number, yaw: number)
	local m = Instance.new("Model")
	m.Name = "Satellite"
	local cf = CFrame.new(pos) * CFrame.Angles(0.4, yaw, 0.3)
	part(m, Vector3.new(s, s * 0.7, s * 0.7), cf, Color3.fromHex("D9A93A"), 0, nil, Enum.Material.Foil) -- cuerpo dorado
	for _, side in { -1, 1 } do
		part(m, Vector3.new(s * 0.15, s * 0.15, s * 0.6), cf * CFrame.new(side * s * 0.75, 0, 0), Color3.fromHex("9AA0B8"), 0, nil, Enum.Material.Metal)
		part(m, Vector3.new(s * 1.8, s * 0.06, s * 0.9), cf * CFrame.new(side * s * 1.9, 0, 0), Color3.fromHex("24357A"), 0, nil, Enum.Material.Glass) -- panel solar
	end
	part(m, Vector3.new(s * 0.1, s * 0.9, s * 0.9), cf * CFrame.new(0, s * 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("EDEDF5"), 0, Enum.PartType.Cylinder, Enum.Material.SmoothPlastic) -- antena
	m.Parent = parent
end

local function rocket(parent: Instance, s: number): Model
	local m = Instance.new("Model")
	m.Name = "Rocket"
	local body = part(m, Vector3.new(s * 3, s * 0.7, s * 0.7), CFrame.new(), Color3.fromHex("F2F2F7"), 0, Enum.PartType.Cylinder, Enum.Material.SmoothPlastic)
	m.PrimaryPart = body
	part(m, Vector3.new(s * 0.7, s * 0.7, s * 0.7), CFrame.new(s * 1.5, 0, 0), Color3.fromHex("E8341C"), 0, Enum.PartType.Ball, Enum.Material.SmoothPlastic) -- punta
	part(m, Vector3.new(s * 0.4, s * 0.72, s * 0.72), CFrame.new(s * 0.6, 0, 0), Color3.fromHex("E8341C"), 0, Enum.PartType.Cylinder, Enum.Material.SmoothPlastic) -- franja
	part(m, Vector3.new(s * 0.9, s * 1.1, s * 1.1), CFrame.new(-s * 1.9, 0, 0), Color3.fromHex("FFB347"), 0.1, Enum.PartType.Ball) -- fuego
	part(m, Vector3.new(s * 1.6, s * 0.7, s * 0.7), CFrame.new(-s * 2.6, 0, 0), Color3.fromHex("FF7A2E"), 0.35, Enum.PartType.Ball)
	for k = 1, 7 do -- estela de humo
		local d = s * (0.9 + k * 0.35)
		part(m, Vector3.new(d, d, d), CFrame.new(-s * (3 + k * 1.6), 0, 0), Color3.fromHex("D9D4E8"), 0.55 + k * 0.055, Enum.PartType.Ball, Enum.Material.SmoothPlastic)
	end
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- Decorar el domo
---------------------------------------------------------------------
-- [arreglo Claude 15-nov, pedido de Isaac] Cielo REALISTA visto desde el polo sur de la Luna, en condiciones
-- óptimas (sin aire, a la sombra, ojos adaptados a la oscuridad):
--   - Sin aire no hay resplandor en el horizonte ni nubes de colores: se quitaron el turquesa y las nubes moradas.
--   - Vía Láctea: franja pálida y tenue que cruza el cielo en arco (el plano de la galaxia está ~60° inclinado
--     respecto a la eclíptica), más brillante y algo cálida hacia el centro galáctico (Sagitario).
--   - El polo sur de la eclíptica queda casi en el cénit (el eje de la Luna está inclinado solo 1,5°), y la Gran
--     Nube de Magallanes está a ~5° de ese polo: se ve casi encima. La Pequeña, unos 20° más abajo.
--   - Planetas: se ven como estrellas brillantes (puntos, no discos), cerca del horizonte porque la eclíptica
--     corre casi por el horizonte en el polo. Venus cerca del Sol (nunca a más de ~47° de él).
--   - Sin satélites ni cohetes en el cielo.
local function decorate(d: Model)
	if d:FindFirstChild("SO_SkyExtras") then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "SO_SkyExtras"
	local center = d:GetPivot().Position
	local rng = Random.new(7)
	table.clear(rockets)

	-- Dirección de un punto del arco de la Vía Láctea: gran círculo inclinado 60° (sube hasta ~60° de altura)
	local MW_AZ = EARTH_AZ + 135 -- rumbo donde el arco está más alto (cruza el horizonte a 45° de la Tierra, no por delante)
	local up = dirOf(60, MW_AZ) -- punto más alto del arco
	local side = dirOf(0, MW_AZ + 90) -- cruza el horizonte a 90° de ahí
	local function mwDir(t: number): Vector3 -- t en radianes a lo largo del arco
		return (up * math.cos(t) + side * math.sin(t)).Unit
	end

	-- 1) Vía Láctea: muchas manchas pálidas a lo largo del arco (más densas y cálidas cerca del centro galáctico)
	local mwColors = { Color3.fromHex("DCE3F5"), Color3.fromHex("ECE6DA"), Color3.fromHex("CFD8EE") }
	for i = 1, 70 do
		local t = (i / 70) * math.pi * 1.1 - math.pi * 0.55 -- de horizonte a horizonte
		local dir = mwDir(t + rng:NextNumber(-0.03, 0.03))
		if dir.Y < 0.14 then continue end -- pegadas al horizonte se veían como discos gigantes (y las colinas las tapan)
		local core = math.exp(-((t - 0.35) / 0.35) ^ 2) -- zona del centro galáctico
		local pos = center + dir * DIST
		local cf = CFrame.lookAt(pos, center) * CFrame.Angles(0, 0, math.atan2(math.cos(t), math.sin(t)) + rng:NextNumber(-0.15, 0.15))
		local color = core > 0.5 and Color3.fromHex("F2E6D2") or mwColors[rng:NextInteger(1, #mwColors)]
		cloud(folder, Vector3.new(rng:NextNumber(150, 240), rng:NextNumber(70, 120) * (1 + core * 0.6), 12), cf, color,
			0.89 - core * 0.05) -- tenue; más brillante hacia el centro galáctico
		-- polvo de estrellas dentro de la franja
		for _ = 1, 14 + math.floor(core * 20) do
			local s = rng:NextNumber(0.6, 1.3)
			part(folder, Vector3.new(s, s, s), cf * CFrame.new(rng:NextNumber(-110, 110), rng:NextNumber(-50, 50) * (1 + core * 0.5), -10),
				Color3.fromHex("F4F1FF"), rng:NextNumber(0.25, 0.6), Enum.PartType.Ball)
		end
	end

	-- 2) Nubes de Magallanes (galaxias satélite): manchas pálidas, la Grande casi en el cénit
	for _, mc in { { alt = 85, az = EARTH_AZ + 160, w = 70, h = 46 }, { alt = 65, az = EARTH_AZ + 205, w = 34, h = 22 } } do
		local pos = center + dirOf(mc.alt, mc.az) * DIST
		local cf = CFrame.lookAt(pos, center) * CFrame.Angles(0, 0, 0.5)
		cloud(folder, Vector3.new(mc.w, mc.h, 10), cf, Color3.fromHex("E4E8F6"), 0.86)
		for _ = 1, 30 do
			local s = rng:NextNumber(0.5, 1.1)
			part(folder, Vector3.new(s, s, s), cf * CFrame.new(rng:NextNumber(-mc.w / 2.4, mc.w / 2.4), rng:NextNumber(-mc.h / 2.4, mc.h / 2.4), -8),
				Color3.fromHex("F4F1FF"), rng:NextNumber(0.3, 0.6), Enum.PartType.Ball)
		end
	end

	-- 3) Muchísimas estrellas (sin aire no titilan y se ven muchas más que desde la Tierra)
	local starColors = { Color3.fromHex("FFFFFF"), Color3.fromHex("CFE0FF"), Color3.fromHex("FFE9C9"), Color3.fromHex("E6D4FF") }
	for i = 1, 1300 do
		local u, t = rng:NextNumber(0.02, 1), rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(1 - u * u)
		local s = i <= 1100 and rng:NextNumber(0.8, 1.8) or rng:NextNumber(1.8, 2.8)
		part(folder, Vector3.new(s, s, s), CFrame.new(center + Vector3.new(r * math.cos(t), u, r * math.sin(t)) * DIST), starColors[rng:NextInteger(1, 4)], rng:NextNumber(0, 0.4), Enum.PartType.Ball)
	end

	-- 4) Planetas como puntos brillantes, pegados al horizonte (eclíptica). Venus cerca del Sol.
	local SUN_AZ = math.deg(math.atan2(-0.62, -0.78)) -- mismo rumbo del Sol que ZoneLighting
	for _, pl in {
		{ name = "Venus", az = SUN_AZ + 38, alt = 3.5, s = 4.2, c = "FFF8EA" },
		{ name = "Jupiter", az = SUN_AZ + 150, alt = 2.5, s = 3.4, c = "FFF1D6" },
		{ name = "Saturn", az = SUN_AZ - 120, alt = 3, s = 2.6, c = "F2DFA8" },
		{ name = "Mars", az = SUN_AZ + 95, alt = 2, s = 2.4, c = "FF9466" },
	} do
		local p = part(folder, Vector3.new(pl.s, pl.s, pl.s), CFrame.new(center + dirOf(pl.alt, pl.az) * DIST), Color3.fromHex(pl.c), 0, Enum.PartType.Ball)
		p.Name = pl.name
	end

	folder.Parent = d
end

-- Agrandar la Tierra de ZoneLighting (solo una vez) y ponerle el destello del Sol en el borde
local function growEarth(m: Model)
	if m:GetAttribute("SO_Grown") then
		return
	end
	m:SetAttribute("SO_Grown", true)
	m:ScaleTo(m:GetScale() * EARTH_SCALE)
	-- Los halos (BillboardGui en studs) también crecen
	for _, g in m:GetDescendants() do
		if g:IsA("BillboardGui") then
			g.Size = UDim2.fromScale(g.Size.X.Scale * EARTH_SCALE, g.Size.Y.Scale * EARTH_SCALE)
		end
	end
	-- Destello del Sol detrás del borde de arriba (como en la imagen)
	local _, size = m:GetBoundingBox()
	local g = part(camera, Vector3.new(size.X * 0.04, size.X * 0.04, size.X * 0.04), CFrame.new(), Color3.fromHex("FFF6E0"), 0, Enum.PartType.Ball)
	g.Name = "SO_EarthGlare"
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(size.X * 0.9, size.X * 0.6)
	bb.LightInfluence = 0
	bb.Parent = g
	for i, t in { 0.3, 0.75, 0.9 } do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(0.05 * i * i, 0.075 * i * i)
		f.BackgroundColor3 = i <= 2 and Color3.new(1, 1, 1) or Color3.fromHex("FFE2A8")
		f.BackgroundTransparency = t
		f.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = f
		f.Parent = bb
	end
	for _, rot in { 0, 90, 30, -30, 60, -60 } do -- rayos
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.fromScale(rot == 0 and 1 or 0.45, 0.012)
		ray.Rotation = rot
		ray.BackgroundColor3 = Color3.fromHex("FFF0D0")
		ray.BackgroundTransparency = 0.35
		ray.BorderSizePixel = 0
		local grad = Instance.new("UIGradient")
		grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
		grad.Parent = ray
		ray.Parent = bb
	end
	glare = g
	m.Destroying:Connect(function()
		g:Destroy()
		if glare == g then
			glare = nil
		end
	end)
end

-- Las estrellas que quedan delante de la Tierra se esconden (solo en este cliente)
local function hideStarsOnEarth()
	local dir, r = earthInfo()
	if not (dir and dome) then
		return
	end
	local c = dome:GetPivot().Position
	local dist = ((earth :: Model):GetPivot().Position - c).Magnitude
	local limit = math.cos(math.atan((r * 1.08) / dist))
	for _, p in dome:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Center" then
			local v = p.Position - c
			if v.Magnitude > 1 and v.Unit:Dot(dir) > limit then
				p.LocalTransparencyModifier = 1
			end
		end
	end
end

---------------------------------------------------------------------
-- Vigilar la cámara
---------------------------------------------------------------------
local function onChild(c: Instance)
	if not c:IsA("Model") then
		return
	end
	if c.Name == "SO_SkyDome" then
		dome = c
		task.defer(function()
			decorate(c)
			task.wait(0.2)
			hideStarsOnEarth()
		end)
	elseif c.Name == "Earth" or c.Name == "SO_MoonEarth" then
		earth = c
		task.defer(function()
			growEarth(c)
			task.wait(0.2)
			hideStarsOnEarth()
		end)
	end
end

-- En la Luna no hay aire: se apagan las nubes y el tono cálido del cielo de la Tierra (solo en este cliente)
local function earthSky(on: boolean)
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then clouds.Enabled = on end
	local warm = game:GetService("Lighting"):FindFirstChild("SO_EarthWarm")
	if warm then (warm :: ColorCorrectionEffect).Enabled = on end
end

local function watch(cam: Camera)
	for _, c in cam:GetChildren() do
		onChild(c)
		if c.Name == "SO_SkyDome" then earthSky(false) end
	end
	cam.ChildAdded:Connect(function(c)
		onChild(c)
		if c.Name == "SO_SkyDome" then earthSky(false) end
	end)
	cam.ChildRemoved:Connect(function(c)
		if c.Name == "SO_SkyDome" then earthSky(true) end
	end)
end
watch(camera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	if camera then
		watch(camera)
	end
end)

-- Cada cuadro: el destello sigue el borde de la Tierra y los cohetes avanzan
RunService.RenderStepped:Connect(function()
	if glare and earth and earth.Parent then
		local ep = earth:GetPivot().Position
		local _, size = earth:GetBoundingBox()
		local r = size.X / 2
		local toCam = (camera.CFrame.Position - ep).Unit
		local up = (Vector3.yAxis - toCam * toCam:Dot(Vector3.yAxis)).Unit
		glare.CFrame = CFrame.new(ep + up * r * 0.97 + toCam * r * 0.25)
	end
	if dome and dome.Parent then
		local c = dome:GetPivot().Position
		local t = os.clock()
		for _, rk in rockets do
			if rk.part.Parent then
				-- van del punto a al punto b y vuelven a empezar
				local k = (rk.phase + t * rk.speed) % 1
				local p = rk.a:Lerp(rk.b, k).Unit
				local ahead = rk.a:Lerp(rk.b, k + 0.01).Unit
				local pos, nxt = c + p * (DIST - 40), c + ahead * (DIST - 40)
				rk.part:PivotTo(CFrame.lookAt(pos, nxt) * CFrame.Angles(0, math.rad(90), 0))
			end
		end
	end
end)
