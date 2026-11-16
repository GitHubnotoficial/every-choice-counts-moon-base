-- Phase1UI (LocalScript) -> StarterPlayer.StarterPlayerScripts.Phase1UI
-- Lo que ve cada jugador en la Fase 1 (PDF Fase 1, caps. 3, 4 y 5):
-- 1. SiteSelect: pantalla 2D con la Luna 3D (ViewportFrame), flechas, CHOOSE / SUGGEST, 6 barras y dato real.
-- 2. Landing: la nave baja (altura en km) y luego TOUCHDOWN! o ROUGH LANDING!
-- 3. Placement: arriba "PLACE YOUR ..." y el reloj; abajo la tabla de ventajas y desventajas del punto cercano.
--    Cada jugador solo ve SUS puntos (los de los demás se esconden solo en esta pantalla).
-- Los avisos (Toast) y la etiqueta de gravedad los muestra Phase3HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local C = Config.Colors
local T = P1.Text
local player = Players.LocalPlayer
local INK = Color3.fromHex("1A1240") -- texto oscuro sobre amarillo o verde

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(o: Instance, r: number?)
	new("UICorner", { CornerRadius = UDim.new(0, r or 14) }, o)
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		TextColor3 = C.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base, parent)
end

local function fmt(t: number): string
	t = math.max(0, math.floor(t))
	return string.format("%d:%02d", t // 60, t % 60)
end

local function myRoles(): { string }
	local list = string.split(player:GetAttribute("Roles") or "", ",")
	if list[1] == "" then
		return {}
	end
	return list
end

local function hasRole(role: string): boolean
	return table.find(myRoles(), role) ~= nil
end

local function siteIndex(id: string): number
	for i, s in Config.Sites do
		if s.Id == id then
			return i
		end
	end
	return 1
end

local function findOption(role: string)
	local id = GS:GetAttribute("Choice_" .. role) or ""
	for _, o in Config.Options[role] do
		if o.Id == id then
			return o
		end
	end
	return nil
end

local function itemName(role: string): string
	if role == "cap" then
		return T.Habitat
	end
	local o = findOption(role)
	return o and o.Name or Config.Roles[role].Name
end

local function phase(): string
	return GS:GetAttribute("Phase") or ""
end

---------------------------------------------------------------------
-- ScreenGui y escalado (todo se diseña en 1280 x 720 y se escala a la pantalla)
---------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "SO_Phase1UI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 15,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local scales = {}
local function stage(parent: Instance): Frame
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1280, 720),
		BackgroundTransparency = 1,
	}, parent)
	table.insert(scales, new("UIScale", {}, f))
	return f
end

local function fit()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local v = cam.ViewportSize
	local s = math.min(v.X / 1280, v.Y / 720)
	for _, sc in scales do
		sc.Scale = s
	end
end

---------------------------------------------------------------------
-- 1. PANTALLA DEL SITIO
---------------------------------------------------------------------
local siteScreen = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Stage, BorderSizePixel = 0, Visible = false }, gui)
local S = stage(siteScreen)

label(S, { Text = T.SiteEyebrow, TextColor3 = C.Muted, TextSize = 14, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(40, 28), Size = UDim2.fromOffset(500, 18) })
label(S, { Text = T.SiteTitle, Font = Enum.Font.FredokaOne, TextSize = 40, Position = UDim2.fromOffset(40, 48), Size = UDim2.fromOffset(700, 48) })

local timerPill = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(1240, 28), Size = UDim2.fromOffset(150, 52), BackgroundColor3 = C.Panel }, S)
corner(timerPill, 26)
local timerStroke = new("UIStroke", { Color = C.Panel2, Thickness = 2 }, timerPill)
local timerText = label(timerPill, { Text = "1:00", Font = Enum.Font.FredokaOne, TextSize = 30, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })

-- Fondo: estrellas que titilan y un brillo suave detrás de la Luna (15-nov)
local starRng = Random.new(5)
for i = 1, 70 do
	local sz = starRng:NextInteger(2, 4)
	local st = new("Frame", { Position = UDim2.fromOffset(starRng:NextInteger(10, 830), starRng:NextInteger(100, 700)), Size = UDim2.fromOffset(sz, sz),
		BackgroundColor3 = C.Text, BackgroundTransparency = starRng:NextNumber(0.1, 0.6), BorderSizePixel = 0 }, S)
	corner(st)
	if i % 3 == 0 then
		TweenService:Create(st, TweenInfo.new(starRng:NextNumber(1.2, 2.6), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.95 }):Play()
	end
end
for k, t in { 0.93, 0.88, 0.84 } do
	local d = 560 - k * 70
	local glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(420, 300), Size = UDim2.fromOffset(d, d), BackgroundColor3 = Color3.fromHex("8E7BFF"), BackgroundTransparency = t, BorderSizePixel = 0 }, S)
	corner(glow)
end

-- Luna 3D
local view = new("ViewportFrame", {
	Position = UDim2.fromOffset(20, 96),
	Size = UDim2.fromOffset(800, 430),
	BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(86, 80, 118),
	LightColor = Color3.fromRGB(255, 246, 230),
	LightDirection = Vector3.new(-1, -0.25, -0.55),
}, S)

-- (15-nov) Luna más bonita: textura de roca, mares oscuros, cráteres con borde claro y brillo en la orilla
local R = 10
local moon = Instance.new("Model")
moon.Name = "Moon"
local sphere = new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(R * 2, R * 2, R * 2), Color = Color3.fromRGB(196, 192, 206), Material = Enum.Material.Slate, Anchored = true, CFrame = CFrame.new() }, moon)
moon.PrimaryPart = sphere

local function onMoon(lat: number, lon: number, lift: number): Vector3
	local r = R + lift
	return Vector3.new(r * math.cos(lat) * math.sin(lon), r * math.sin(lat), r * math.cos(lat) * math.cos(lon))
end

-- Mancha que se pega a la curva de la Luna (elipsoide aplanado): mares y cráteres
local function patch(lat: number, lon: number, w: number, color: Color3, raise: number, mat: Enum.Material?)
	local n = onMoon(lat, lon, 0).Unit
	local sag = w * w / (8 * R)
	local pos = n * (R - sag + raise)
	local p = new("Part", { Size = Vector3.new(w, 2 * sag + 0.16, w), Color = color, Material = mat or Enum.Material.Slate, Anchored = true,
		CFrame = CFrame.lookAt(pos, pos + n) * CFrame.Angles(-math.pi / 2, 0, 0) }, moon)
	new("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, p)
	return p
end

local seed = Random.new(7)
-- Mares oscuros (como los de la Luna de verdad)
for _ = 1, 14 do
	patch(math.asin(seed:NextNumber(-0.95, 0.9)), seed:NextNumber(-math.pi, math.pi), seed:NextNumber(4, 8), Color3.fromRGB(150, 146, 170), 0.0, Enum.Material.SmoothPlastic)
end
-- Cráteres: borde claro, fondo oscuro y, en los grandes, un pico en el centro
for k = 1, 60 do
	local lat = math.asin(seed:NextNumber(-1, 1))
	local lon = seed:NextNumber(-math.pi, math.pi)
	local w = k <= 8 and seed:NextNumber(1.8, 2.8) or seed:NextNumber(0.5, 1.5)
	patch(lat, lon, w * 1.3, Color3.fromRGB(212, 209, 224), 0.03)
	patch(lat, lon, w, Color3.fromRGB(136, 132, 156), 0.06)
	if k <= 8 then
		patch(lat, lon, w * 0.25, Color3.fromRGB(214, 210, 226), 0.12)
	end
end
-- Brillo en el borde de la Luna (como si la luz del Sol la rodeara)
new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(R * 2.06, R * 2.06, R * 2.06), Color = Color3.fromRGB(205, 190, 255), Material = Enum.Material.ForceField, Transparency = 0.2, Anchored = true, CFrame = CFrame.new() }, moon)

-- Sitios: separados alrededor del polo para que se vean (los reales están a menos de 5° del polo)
local siteLat, siteLon, markers, suggestDots = {}, {}, {}, {}
for i, s in Config.Sites do
	siteLat[i] = math.rad(-90 + 6 + (90 + s.Lat) * 4)
	siteLon[i] = math.rad(s.Lon)
	markers[i] = new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), Color = C.Text, Material = Enum.Material.Neon, Anchored = true, CFrame = CFrame.new(onMoon(siteLat[i], siteLon[i], 0.15)) }, moon)
	suggestDots[i] = {}
end
moon.Parent = view
-- Anillo que late y rayo de luz sobre el sitio elegido (15-nov)
local selectedSite = 1
local selRing = new("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 2.6, 2.6), Color = C.Red, Material = Enum.Material.Neon, Transparency = 0.35, Anchored = true }, moon)
local selBeam = new("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 0.18, 0.18), Color = Color3.fromHex("FF8A75"), Material = Enum.Material.Neon, Transparency = 0.3, Anchored = true }, moon)

local cam = Instance.new("Camera")
cam.FieldOfView = 34
cam.CFrame = CFrame.lookAt(Vector3.new(0, -13, 27), Vector3.new(0, -4.5, 0))
cam.Parent = view
view.CurrentCamera = cam

-- (15-nov, 2) Más espacio alrededor de la Luna: la Tierra al fondo, una nave en órbita con estela,
-- un sol brillante, estrellas fugaces y un acercamiento suave al abrir la pantalla.
local space = Instance.new("Model")
space.Name = "Space"
local earthPos = Vector3.new(-30, 9, -46)
new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), Color = Color3.fromRGB(46, 112, 220), Material = Enum.Material.SmoothPlastic, Anchored = true, CFrame = CFrame.new(earthPos) }, space)
local landRng = Random.new(3)
for _ = 1, 7 do
	local dir = Vector3.new(landRng:NextNumber(-1, 1), landRng:NextNumber(-0.7, 0.7), landRng:NextNumber(-1, 1)).Unit
	local w = landRng:NextNumber(1.4, 2.6)
	local p = new("Part", { Size = Vector3.new(w, 0.5, w * 0.8), Color = Color3.fromRGB(86, 170, 90), Material = Enum.Material.SmoothPlastic, Anchored = true,
		CFrame = CFrame.lookAt(earthPos + dir * 2.85, earthPos + dir * 4) * CFrame.Angles(-math.pi / 2, 0, 0) }, space)
	new("SpecialMesh", { MeshType = Enum.MeshType.Sphere }, p)
end
new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(6.25, 6.25, 6.25), Color = Color3.new(1, 1, 1), Material = Enum.Material.ForceField, Transparency = 0.35, Anchored = true, CFrame = CFrame.new(earthPos) }, space)
new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(6.7, 6.7, 6.7), Color = Color3.fromRGB(120, 190, 255), Material = Enum.Material.ForceField, Transparency = 0.1, Anchored = true, CFrame = CFrame.new(earthPos) }, space)

-- Nave en órbita (cuerpo blanco, paneles azules, luz roja) y su estela
local ship = Instance.new("Model")
ship.Name = "Ship"
local shipBody = new("Part", { Size = Vector3.new(0.5, 0.5, 1.3), Color = Color3.fromRGB(240, 240, 245), Material = Enum.Material.SmoothPlastic, Anchored = true }, ship)
ship.PrimaryPart = shipBody
local shipParts = {
	{ new("Part", { Size = Vector3.new(1.6, 0.06, 0.6), Color = Color3.fromRGB(60, 110, 230), Material = Enum.Material.SmoothPlastic, Anchored = true }, ship), CFrame.new(1.05, 0, 0) },
	{ new("Part", { Size = Vector3.new(1.6, 0.06, 0.6), Color = Color3.fromRGB(60, 110, 230), Material = Enum.Material.SmoothPlastic, Anchored = true }, ship), CFrame.new(-1.05, 0, 0) },
	{ new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(0.22, 0.22, 0.22), Color = Color3.fromRGB(255, 70, 60), Material = Enum.Material.Neon, Anchored = true }, ship), CFrame.new(0, 0.3, 0.4) },
	{ new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(140, 220, 255), Material = Enum.Material.Neon, Anchored = true }, ship), CFrame.new(0, 0, 0.7) },
}
ship.Parent = space
local trail = {}
for i = 1, 16 do
	trail[i] = new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(0.22, 0.22, 0.22) * (1 - i / 20), Color = Color3.fromRGB(140, 220, 255), Material = Enum.Material.Neon, Transparency = 0.2 + i * 0.05, Anchored = true }, space)
end
space.Parent = view
local orbitTilt = CFrame.Angles(math.rad(18), 0, math.rad(-22))
local function orbitPos(t: number): Vector3
	return orbitTilt * Vector3.new(math.cos(t) * 14.5, 0, math.sin(t) * 14.5)
end

-- Sol con destello (la luz viene de la derecha)
for k, d in { 150, 90, 46 } do
	local sun = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(765, 128), Size = UDim2.fromOffset(d, d), BackgroundColor3 = Color3.fromRGB(255, 236, 190),
		BackgroundTransparency = ({ 0.9, 0.75, 0.05 })[k], BorderSizePixel = 0, ZIndex = 0 }, S)
	corner(sun)
	if k == 1 then
		TweenService:Create(sun, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(180, 180) }):Play()
	end
end

-- Estrellas fugaces de vez en cuando
local shootRng = Random.new()
task.spawn(function()
	while true do
		task.wait(shootRng:NextNumber(2.5, 5))
		if siteScreen.Visible then
			local x, y = shootRng:NextInteger(80, 700), shootRng:NextInteger(110, 300)
			local st = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(90, 2), Rotation = 28,
				BackgroundColor3 = C.Text, BorderSizePixel = 0, ZIndex = 0 }, S)
			new("UIGradient", { Transparency = NumberSequence.new(1, 0) }, st)
			local tw = TweenService:Create(st, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(x + 260, y + 140), BackgroundTransparency = 1 })
			tw:Play()
			tw.Completed:Once(function()
				st:Destroy()
			end)
		end
	end
end)

-- Acercamiento de la cámara al abrir la pantalla
local camPos, camTarget = Vector3.new(0, -13, 27), Vector3.new(0, -4.5, 0)
local zoomStart = os.clock()
siteScreen:GetPropertyChangedSignal("Visible"):Connect(function()
	if siteScreen.Visible then
		zoomStart = os.clock()
	end
end)
RunService.RenderStepped:Connect(function()
	if not siteScreen.Visible then
		return
	end
	local now = os.clock()
	local a = math.clamp((now - zoomStart) / 1.8, 0, 1)
	local e = 1 - (1 - a) ^ 3
	cam.CFrame = CFrame.lookAt(camTarget + (camPos - camTarget) * (1 + 1.3 * (1 - e)), camTarget)
	-- nave: da una vuelta cada 14 s; la estela sigue sus posiciones anteriores
	local t = now * (2 * math.pi / 14)
	local p, ahead = orbitPos(t), orbitPos(t + 0.05)
	local cf = CFrame.lookAt(p, ahead)
	ship:PivotTo(cf)
	for _, sp in shipParts do
		sp[1].CFrame = cf * sp[2]
	end
	for i, d in trail do
		d.CFrame = CFrame.new(orbitPos(t - i * 0.045))
	end
end)

local angleNow, angleGoal = 0, 0
RunService.RenderStepped:Connect(function(dt)
	if not siteScreen.Visible then
		return
	end
	-- Girar por el camino más corto
	local diff = (angleGoal - angleNow + math.pi) % (2 * math.pi) - math.pi
	angleNow += diff * math.min(1, dt * 6)
	moon:PivotTo(CFrame.Angles(0, angleNow, 0))
	-- el anillo y el rayo siguen al sitio elegido (se mueven con la Luna)
	local n = onMoon(siteLat[selectedSite], siteLon[selectedSite], 0).Unit
	local spin = CFrame.Angles(0, angleNow, 0)
	local p = spin:PointToWorldSpace(n * (R + 0.2))
	local nn = spin:VectorToWorldSpace(n)
	local k = 1 + 0.25 * math.sin(os.clock() * 5)
	selRing.Size = Vector3.new(0.12, 2.6 * k, 2.6 * k)
	selRing.CFrame = CFrame.lookAt(p, p + nn) * CFrame.Angles(0, math.rad(90), 0)
	selBeam.CFrame = CFrame.lookAt(p + nn * 2, p + nn * 4) * CFrame.Angles(0, math.rad(90), 0)
end)

-- Flechas, nombre y botón
local function arrow(text: string, x: number): TextButton
	local b = new("TextButton", {
		Text = text, Font = Enum.Font.FredokaOne, TextSize = 34, TextColor3 = INK, BackgroundColor3 = C.Text,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, 566), Size = UDim2.fromOffset(64, 64), AutoButtonColor = true,
	}, S)
	corner(b, 32)
	return b
end
local prevBtn = arrow("<", 160)
local nextBtn = arrow(">", 680)

local nameBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(420, 566), Size = UDim2.fromOffset(380, 60), BackgroundColor3 = C.Panel }, S)
corner(nameBox, 18)
new("UIStroke", { Color = C.Panel2, Thickness = 2 }, nameBox)
local nameText = label(nameBox, { Text = "", Font = Enum.Font.FredokaOne, TextSize = 32, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })

local mainBtn = new("TextButton", {
	Text = T.Choose, Font = Enum.Font.FredokaOne, TextSize = 28, TextColor3 = C.Text, BackgroundColor3 = C.Red,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(420, 608), Size = UDim2.fromOffset(340, 58), AutoButtonColor = true,
}, S)
corner(mainBtn, 18)
local note = label(S, { Text = "", TextColor3 = C.Muted, TextSize = 14, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(420, 676), Size = UDim2.fromOffset(760, 20), TextXAlignment = Enum.TextXAlignment.Center })

-- Tarjeta de la derecha
local card = new("Frame", { Position = UDim2.fromOffset(860, 110), Size = UDim2.fromOffset(384, 576), BackgroundColor3 = C.Panel }, S)
corner(card, 22)
new("UIStroke", { Color = C.Panel2, Thickness = 2 }, card)
new("UIPadding", { PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }, card)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, card)

local cardName = label(card, { LayoutOrder = 1, Font = Enum.Font.FredokaOne, TextSize = 26, Size = UDim2.new(1, 0, 0, 30) })
local cardPhrase = label(card, { LayoutOrder = 2, TextColor3 = C.Muted, TextSize = 16, TextWrapped = true, Size = UDim2.new(1, 0, 0, 42), TextYAlignment = Enum.TextYAlignment.Top })

local bars = {}
for i, name in Config.SiteBars do
	local row = new("Frame", { LayoutOrder = 2 + i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22) }, card)
	label(row, { Text = name, TextSize = 15, Font = Enum.Font.GothamBlack, Size = UDim2.new(0, 96, 1, 0) })
	local track = new("Frame", { Position = UDim2.new(0, 104, 0.5, -7), Size = UDim2.new(1, -150, 0, 14), BackgroundColor3 = Color3.fromHex("3B2C8C") }, row)
	corner(track, 7)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Gold }, track)
	corner(fill, 7)
	local value = label(row, { Text = "", TextSize = 15, Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 38, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
	bars[i] = { fill = fill, value = value }
end
label(card, { LayoutOrder = 10, Text = T.ScaleNote, TextColor3 = C.Dim, TextSize = 12, Size = UDim2.new(1, 0, 0, 14) })
local warnText = label(card, { LayoutOrder = 11, Text = T.RoughWarn, TextColor3 = C.Bad, TextSize = 14, Font = Enum.Font.GothamBlack, Size = UDim2.new(1, 0, 0, 18), Visible = false })

local suggRow = new("Frame", { LayoutOrder = 12, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26) }, card)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, suggRow)

local factBox = new("Frame", { LayoutOrder = 13, Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.Panel2 }, card)
corner(factBox, 14)
new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, factBox)
label(factBox, { Text = T.DidYouKnow, TextColor3 = C.Gold, Font = Enum.Font.FredokaOne, TextSize = 15, Size = UDim2.new(1, 0, 0, 18) })
local factText = label(factBox, { Text = "", TextSize = 15, TextWrapped = true, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 1, -30), TextYAlignment = Enum.TextYAlignment.Top })

-- Dibuja el sitio que tiene el Captain en pantalla
local function drawSite()
	local id = GS:GetAttribute("SiteCursor") or "nobile"
	local chosen = GS:GetAttribute("Site") or ""
	if chosen ~= "" then
		id = chosen
	end
	local i = siteIndex(id)
	local s = Config.Sites[i]
	angleGoal = -siteLon[i]

	nameText.Text = s.Name
	cardName.Text = s.Name
	cardPhrase.Text = s.Phrase
	factText.Text = s.Fact
	for b, v in s.Scores do
		TweenService:Create(bars[b].fill, TweenInfo.new(0.35), { Size = UDim2.fromScale(v / 10, 1) }):Play()
		bars[b].fill.BackgroundColor3 = v < 5 and C.Bad or C.Gold
		bars[b].value.Text = tostring(v)
	end
	warnText.Visible = s.Scores[4] < Config.RoughTerrainBelow

	-- Marcador rojo en el sitio elegido, con anillo que late y rayo de luz
	for k, m in markers do
		m.Color = (k == i) and C.Red or C.Text
		m.Size = (k == i) and Vector3.new(1.5, 1.5, 1.5) or Vector3.new(0.8, 0.8, 0.8)
	end
	selectedSite = i

	-- Sugerencias: chips en la tarjeta y puntos de color sobre cada sitio
	for _, c in suggRow:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for k, site in Config.Sites do
		for _, d in suggestDots[k] do
			d:Destroy()
		end
		suggestDots[k] = {}
		local list = string.split(GS:GetAttribute("Suggest_" .. site.Id) or "", ",")
		local n = 0
		for _, role in list do
			local info = Config.Roles[role]
			if info then
				n += 1
				local off = Vector3.new((n - 2) * 0.9, -0.9, 0)
				local base = onMoon(siteLat[k], siteLon[k], 0.2)
				table.insert(suggestDots[k], new("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Color = info.Color, Material = Enum.Material.Neon, Anchored = true, CFrame = CFrame.new(base + CFrame.Angles(0, siteLon[k], 0):VectorToWorldSpace(off)) }, moon))
				if k == i then
					if #suggRow:GetChildren() == 1 then
						label(suggRow, { Text = T.SuggestedBy, TextColor3 = C.Dim, TextSize = 13, Font = Enum.Font.GothamBlack, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), LayoutOrder = 0 })
					end
					local chip = label(suggRow, { Text = "  " .. info.Name .. "  ", TextSize = 12, Font = Enum.Font.GothamBlack, BackgroundTransparency = 0, BackgroundColor3 = info.Color, TextColor3 = (role == "eng" or role == "bot") and INK or C.Text, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), LayoutOrder = n })
					corner(chip, 11)
				end
			end
		end
	end

	-- Botones según el rol
	local captain = hasRole("cap")
	local done = chosen ~= ""
	prevBtn.Visible = captain
	nextBtn.Visible = captain
	prevBtn.Active = captain and not done
	nextBtn.Active = captain and not done
	prevBtn.BackgroundTransparency = done and 0.6 or 0
	nextBtn.BackgroundTransparency = done and 0.6 or 0
	if captain then
		mainBtn.Text = T.Choose
		mainBtn.BackgroundColor3 = C.Red
		note.Text = T.CaptainNote
	else
		mainBtn.Text = T.Suggest
		mainBtn.BackgroundColor3 = Config.Roles.life.Color
		note.Text = T.CrewNote
	end
	mainBtn.AutoButtonColor = not done
	mainBtn.BackgroundTransparency = done and 0.5 or 0
end

local function canAct(): boolean
	return phase() == "SiteSelect" and (GS:GetAttribute("Site") or "") == ""
end

prevBtn.MouseButton1Click:Connect(function()
	if canAct() and hasRole("cap") then
		Remotes.SiteNav:FireServer(-1)
	end
end)
nextBtn.MouseButton1Click:Connect(function()
	if canAct() and hasRole("cap") then
		Remotes.SiteNav:FireServer(1)
	end
end)
mainBtn.MouseButton1Click:Connect(function()
	if not canAct() then
		return
	end
	local id = GS:GetAttribute("SiteCursor") or "nobile"
	if hasRole("cap") then
		Remotes.SiteChoose:FireServer(id)
	else
		Remotes.SiteSuggest:FireServer(id)
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not siteScreen.Visible or not canAct() or not hasRole("cap") then
		return
	end
	if input.KeyCode == Enum.KeyCode.Left then
		Remotes.SiteNav:FireServer(-1)
	elseif input.KeyCode == Enum.KeyCode.Right then
		Remotes.SiteNav:FireServer(1)
	end
end)

---------------------------------------------------------------------
-- 2. ATERRIZAJE
---------------------------------------------------------------------
local landScreen = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.BgDark, BackgroundTransparency = 0.25, BorderSizePixel = 0, Visible = false }, gui)
local L = stage(landScreen)
local landBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(640, 360), Size = UDim2.fromOffset(660, 250), BackgroundColor3 = C.Panel }, L)
corner(landBox, 24)
new("UIStroke", { Color = C.Panel2, Thickness = 2 }, landBox)
local landTitle = label(landBox, { Text = "", Font = Enum.Font.FredokaOne, TextSize = 40, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 46), TextXAlignment = Enum.TextXAlignment.Center })
local landBig = label(landBox, { Text = "", Font = Enum.Font.FredokaOne, TextSize = 56, Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 64), TextXAlignment = Enum.TextXAlignment.Center })
local landText = label(landBox, { Text = "", TextColor3 = C.Muted, TextSize = 18, TextWrapped = true, Position = UDim2.fromOffset(30, 160), Size = UDim2.new(1, -60, 0, 60), TextXAlignment = Enum.TextXAlignment.Center })

local landStart = 0
local function showLandingResult()
	local s = Config.Sites[siteIndex(GS:GetAttribute("Site") or "")]
	landBig.Visible = false
	if GS:GetAttribute("RoughLanding") then
		landTitle.Text = T.RoughTitle
		landTitle.TextColor3 = C.Bad
		landText.Text = T.RoughText
	else
		landTitle.Text = T.Touchdown
		landTitle.TextColor3 = C.Good
		landText.Text = string.format(T.TouchdownText, s.Name)
	end
end

local function startLanding()
	local s = Config.Sites[siteIndex(GS:GetAttribute("Site") or "")]
	landTitle.Text = string.format(T.LandingAt, s.Name)
	landTitle.TextColor3 = C.Text
	landText.Text = T.Descending
	landBig.Visible = true
	landStart = os.clock()
end

RunService.RenderStepped:Connect(function()
	if landScreen.Visible and landBig.Visible then
		local t = math.clamp((os.clock() - landStart) / Config.Times.LandingAnim, 0, 1)
		local e = t < 0.5 and 2 * t * t or 1 - ((-2 * t + 2) ^ 2) / 2
		landBig.Text = string.format("%.1f km", P1.LandingAltitudeKm * (1 - e))
	end
end)

GS:GetAttributeChangedSignal("Landed"):Connect(function()
	if GS:GetAttribute("Landed") and landScreen.Visible then
		showLandingResult()
	end
end)

-- Mientras se ve la animación 3D de llegada (LaunchCinematic): sin fondo oscuro y la caja arriba y más chica
local landScale = new("UIScale", { Scale = 1 }, landBox)
local function cinemaLook()
	local on = Players.LocalPlayer:GetAttribute("SO_Cinematic") == true
	landScreen.BackgroundTransparency = on and 1 or 0.25
	landBox.Position = on and UDim2.fromOffset(640, 110) or UDim2.fromOffset(640, 360)
	landScale.Scale = on and 0.7 or 1
end
Players.LocalPlayer:GetAttributeChangedSignal("SO_Cinematic"):Connect(cinemaLook)
cinemaLook()

---------------------------------------------------------------------
-- 3. COLOCACIÓN
---------------------------------------------------------------------
local placeHud = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, gui)
local topPill = label(placeHud, {
	Text = "", Font = Enum.Font.FredokaOne, TextSize = 24, BackgroundTransparency = 0.1, BackgroundColor3 = C.Stage,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.fromOffset(560, 44),
	TextXAlignment = Enum.TextXAlignment.Center,
})
corner(topPill, 22)

local panel = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 40), Size = UDim2.fromOffset(340, 210), -- a un costado para no tapar la E [arreglo Claude 15-nov]
	BackgroundColor3 = C.Stage, BackgroundTransparency = 0.25, Visible = false,
}, placeHud)
corner(panel, 18)
new("UIStroke", { Color = C.Panel2, Thickness = 2 }, panel)
new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20) }, panel)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
local pTitle = label(panel, { LayoutOrder = 1, Font = Enum.Font.FredokaOne, TextSize = 20, Size = UDim2.new(1, 0, 0, 26) })
local pPro = label(panel, { LayoutOrder = 2, TextColor3 = C.Good, TextSize = 14, TextWrapped = true, Size = UDim2.new(1, 0, 0, 36) })
local pCon = label(panel, { LayoutOrder = 3, TextColor3 = C.Bad, TextSize = 14, TextWrapped = true, Size = UDim2.new(1, 0, 0, 36) })
local pFact = label(panel, { LayoutOrder = 4, TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 14, TextWrapped = true, Size = UDim2.new(1, 0, 0, 52), TextYAlignment = Enum.TextYAlignment.Top })

local function updateTop()
	local text = T.AllPlaced
	for _, role in Config.RoleOrder do
		if hasRole(role) and (GS:GetAttribute("Spot_" .. role) or "") == "" then
			text = string.format(T.PlaceYour, itemName(role))
			break
		end
	end
	topPill.Text = text .. "   " .. fmt(GS:GetAttribute("TimeLeft") or 0)
end

-- Cada 0,2 s: esconder los puntos de otros roles y mostrar la tabla del punto cercano
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 or not placeHud.Visible then
		return
	end
	acc = 0
	local site = workspace:FindFirstChild("MoonSite")
	local spots = site and site:FindFirstChild("SO_Spots")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local near, nearDist = nil, math.huge
	if spots then
		for _, marker in spots:GetChildren() do
			if marker:IsA("BasePart") then
				local mine = hasRole(marker:GetAttribute("Role") or "")
				-- Estos cambios solo pasan en esta pantalla (no se envían al servidor)
				marker.Transparency = mine and 0.35 or 1
				for _, d in marker:GetDescendants() do
					if d:IsA("ProximityPrompt") then
						d.Enabled = mine and not marker:GetAttribute("Taken") -- ya colocado: sin "Place here" [arreglo Claude 15-nov]
					elseif d:IsA("BillboardGui") then
						d.Enabled = mine
					end
				end
				if mine and root then
					local dist = (marker.Position - root.Position).Magnitude
					if dist < nearDist then
						near, nearDist = marker, dist
					end
				end
			end
		end
	end
	-- "Pick up" solo para los objetos de mis roles
	local placed = site and site:FindFirstChild("Placed")
	if placed then
		for _, d in placed:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Name == "SO_PickUp" then
				d.Enabled = hasRole(d:GetAttribute("Role") or "")
			end
		end
	end

	if near and nearDist <= Config.SpotRadius + 2 then
		local role = near:GetAttribute("Role")
		local id = near:GetAttribute("SpotId")
		for _, d in Config.Spots[role] do
			if d.Id == id then
				pTitle.Text = d.Name .. "  ·  " .. d.Dist
				pPro.Text = "+ " .. d.Pro
				pCon.Text = "− " .. d.Con
				pFact.Text = T.RealFact .. " " .. d.Fact
			end
		end
		panel.Visible = true
	else
		panel.Visible = false
	end
	updateTop()
end)

---------------------------------------------------------------------
-- Mostrar la pantalla que toca según la fase
---------------------------------------------------------------------
local function applyPhase()
	local p = phase()
	siteScreen.Visible = p == "SiteSelect"
	if p == "Landing" and not landScreen.Visible then
		landScreen.Visible = true
		startLanding()
		if GS:GetAttribute("Landed") then
			showLandingResult()
		end
	elseif p ~= "Landing" then
		landScreen.Visible = false
	end
	placeHud.Visible = p == "Placement"
	if p == "SiteSelect" then
		drawSite()
	elseif p == "Placement" then
		updateTop()
	end
end

GS:GetAttributeChangedSignal("Phase"):Connect(applyPhase)
GS:GetAttributeChangedSignal("SiteCursor"):Connect(function()
	if siteScreen.Visible then
		drawSite()
	end
end)
GS:GetAttributeChangedSignal("Site"):Connect(function()
	if siteScreen.Visible then
		drawSite()
	end
end)
for _, s in Config.Sites do
	GS:GetAttributeChangedSignal("Suggest_" .. s.Id):Connect(function()
		if siteScreen.Visible then
			drawSite()
		end
	end)
end
GS:GetAttributeChangedSignal("TimeLeft"):Connect(function()
	local t = GS:GetAttribute("TimeLeft") or 0
	timerText.Text = fmt(t)
	local low = t <= 10
	timerStroke.Color = low and C.Red or C.Panel2
	timerText.TextColor3 = low and C.Bad or C.Text
	if placeHud.Visible then
		updateTop()
	end
end)
player:GetAttributeChangedSignal("Roles"):Connect(function()
	if siteScreen.Visible then
		drawSite()
	end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	fit()
end)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end
fit()
applyPhase()
