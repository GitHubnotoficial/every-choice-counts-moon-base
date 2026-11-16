-- SO_Cockpit (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_Cockpit
-- Dueño: Isaac + Claude (pedido de Isaac 15-nov). Escena dentro de la cápsula: la tripulación acostada boca arriba
-- (así se despega de verdad: la aceleración empuja contra la espalda), mirando el panel que cuelga encima.
-- Forma de cápsula de tripulación moderna (paredes blancas, luz azul, panel curvo de 3 pantallas, columna de mandos,
-- asientos crema y negro, ventanas redondas) con toques de cabina de película (relojes de aguja, luces ámbar, cables).
-- Sin logos ni marcas. Todo vive solo en este cliente (lejos del mapa, en y = 15000).
-- Tomas (cada una empieza en primera persona desde el asiento del jugador, con el borde del visor):
--   "launch"  → cuenta regresiva y temblor (antes del despegue que se ve desde afuera, LaunchCinematic)
--   "landing" → la Luna se acerca por la ventana y baja la altitud (antes de la llegada desde afuera)
--   "return"  → de regreso a casa con la Tierra en la ventana (al final de la fase "Rescue")
-- API: ReplicatedStorage.SO_CockpitShot (BindableFunction, solo local): Invoke(toma) espera a que termine.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local T = Config.Cockpit or {
	LaunchTime = 5, LandingTime = 3.5, ReturnTime = 5, ReturnAt = 6.5, PovShare = 0.55,
	Text = { Liftoff = "LIFTOFF!", Landing = "LANDING BURN", Return = "HEADING HOME" },
}

local O = CFrame.new(0, 15000, 6000) -- centro del piso de la cápsula
local WALL = Color3.fromHex("ECEDF2")
local DARK = Color3.fromHex("17181F")
local BEZEL = Color3.fromHex("23252E")
local METAL = Color3.fromHex("9AA0B2")
local SUIT = Color3.fromHex("F4F4F7")
local SUITDARK = Color3.fromHex("3A3D48")
local CREAM = Color3.fromHex("E3D3AE")
local AMBER = Color3.fromHex("FFB347")
local LED = Color3.fromHex("5D7BFF")
local SCREEN = Color3.fromHex("0A1838")
local BLUE = Color3.fromHex("6FC3FF")

local folder: Model? = nil
local live: { [string]: any } = { windows = {} }
local seatHeads: { CFrame } = {}

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = folder
	return p
end
local function ball(name: string, d: number, pos: Vector3, color: Color3, mat: Enum.Material?): Part
	return part(name, Vector3.new(d, d, d), CFrame.new(pos), color, mat, Enum.PartType.Ball)
end
-- Cilindro redondeado entre dos puntos (brazo, pierna, tubo), con bolas en las puntas
local function limb(name: string, a: Vector3, b: Vector3, d: number, color: Color3, mat: Enum.Material?, ends: boolean?)
	local len = (b - a).Magnitude
	part(name, Vector3.new(len, d, d), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, mat, Enum.PartType.Cylinder)
	if ends ~= false then
		ball(name .. "J", d, a, color, mat)
		ball(name .. "J", d, b, color, mat)
	end
end
local function label(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3, bold: boolean?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = size
	t.Position = pos
	t.Text = text
	t.TextColor3 = color
	t.Font = bold and Enum.Font.GothamBold or Enum.Font.Code
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
	return t
end
local function screenGui(p: BasePart): Frame
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.LightInfluence = 0
	g.Brightness = 1.8
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 60
	g.Parent = p
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = SCREEN
	f.BorderSizePixel = 0
	f.Parent = g
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromHex("FFFFFF"), Color3.fromHex("8C9BFF"))
	grad.Rotation = 90
	grad.Parent = f
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0); pad.PaddingTop = UDim.new(0.06, 0)
	pad.Parent = f
	return f
end

---------------------------------------------------------------------
-- Construcción (una vez)
---------------------------------------------------------------------
local function build()
	if folder then return end
	folder = Instance.new("Model")
	folder.Name = "SO_Cockpit"

	-- Casco: cono truncado blanco liso (radio 7 abajo, 4,6 arriba, 9 de alto) con costillas metálicas finas.
	-- Los segmentos 5 y 18 tienen un hueco con ventana redonda (a los lados, un poco hacia el panel).
	local N = 24
	local r0, r1, H = 7, 4.6, 9
	local WINDOWS = { [5] = true, [18] = true }
	for i = 0, N - 1 do
		local a = (i + 0.5) / N * math.pi * 2
		local mid = (r0 + r1) / 2
		local tilt = math.atan2(r0 - r1, H)
		local cf = O * CFrame.Angles(0, a, 0) * CFrame.new(0, H / 2, -mid) * CFrame.Angles(-tilt, 0, 0)
		local L = H / math.cos(tilt)
		local wWidth = 2 * math.pi * mid / N + 0.12
		local w: BasePart
		if WINDOWS[i] then
			-- pared con hueco: pieza de abajo y pieza de arriba; en medio, la ventana (frente local -Z = hacia afuera)
			local wy = (4.2 - H / 2) / math.cos(tilt)
			local lo, hi = -L / 2, wy - 1.15
			w = part("Wall", Vector3.new(wWidth, hi - lo, 0.3), cf * CFrame.new(0, (lo + hi) / 2, 0), WALL)
			local lo2, hi2 = wy + 1.15, L / 2
			part("Wall", Vector3.new(wWidth, hi2 - lo2, 0.3), cf * CFrame.new(0, (lo2 + hi2) / 2, 0), WALL)
			local wcf = cf * CFrame.new(0, wy, 0)
			for k = 0, 15 do -- marco: anillo metálico y aro de luz azul
				local ang = k / 16 * math.pi * 2
				part("WindowFrame", Vector3.new(0.5, 0.42, 0.45), wcf * CFrame.Angles(0, 0, ang) * CFrame.new(0, 1.28, -0.05), METAL, Enum.Material.Metal)
				part("WindowLed", Vector3.new(0.48, 0.1, 0.1), wcf * CFrame.Angles(0, 0, ang) * CFrame.new(0, 1.05, 0.2), LED, Enum.Material.Neon)
			end
			local glass = part("WindowGlass", Vector3.new(0.06, 2.2, 2.2), wcf * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("CFE4FF"), Enum.Material.Glass, Enum.PartType.Cylinder)
			glass.Transparency = 0.82
			table.insert(live.windows, glass)
			-- agarradera junto a la ventana
			for _, gx in { -1.05, 1.05 } do
				limb("Grab", (wcf * CFrame.new(gx, 0.9, 0.35)).Position, (wcf * CFrame.new(gx, -0.9, 0.35)).Position, 0.12, METAL, Enum.Material.Metal, false)
			end
		else
			w = part("Wall", Vector3.new(wWidth, L, 0.3), cf, WALL)
		end
		if i % 2 == 0 then
			part("Rib", Vector3.new(0.1, L - 0.4, 0.12), cf * CFrame.new(wWidth / 2, 0, 0.18), METAL, Enum.Material.Metal)
		end
		-- paneles de pared con tornillos (detalle) en algunos segmentos
		if not WINDOWS[i] and i % 4 == 1 then
			part("WallPanel", Vector3.new(wWidth - 0.4, 1.6, 0.06), cf * CFrame.new(0, 1.2, 0.18), Color3.fromHex("DADCE4"))
			for _, b in { Vector2.new(-0.5, 0.65), Vector2.new(0.5, 0.65), Vector2.new(-0.5, -0.65), Vector2.new(0.5, -0.65) } do
				ball("Bolt", 0.1, (cf * CFrame.new(b.X, 1.2 + b.Y, 0.22)).Position, METAL, Enum.Material.Metal)
			end
		end
		-- franja oscura abajo (consolas) y luz azul al pie de la pared
		part("LowBand", Vector3.new(w.Size.X, 1.4, 0.32), O * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.7, -(r0 - 0.2)), Color3.fromHex("2C2F3A"))
		part("LedStrip", Vector3.new(w.Size.X, 0.08, 0.1), O * CFrame.Angles(0, a, 0) * CFrame.new(0, 1.45, -(r0 - 0.45)), LED, Enum.Material.Neon)
		-- luces ámbar arriba, entre costillas (toque de cabina de película)
		if i % 3 == 0 then
			part("AmberLamp", Vector3.new(0.5, 0.12, 0.08), O * CFrame.Angles(0, a, 0) * CFrame.new(0, 7.9, -(r1 + 0.45)), AMBER, Enum.Material.Neon)
		end
	end
	part("Floor", Vector3.new(0.3, 14.4, 14.4), O * CFrame.new(0, -0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.DiamondPlate, Enum.PartType.Cylinder)
	-- Techo con escotilla de ventana (se ve el cielo de arriba)
	local cy = 9.1
	for _, r in { { -3.05, 0, 3.5, 9.8 }, { 3.05, 0, 3.5, 9.8 }, { 0, -3.05, 2.6, 3.5 }, { 0, 3.05, 2.6, 3.5 } } do
		part("Ceiling", Vector3.new(r[3], 0.3, r[4]), O * CFrame.new(r[1], cy, r[2]), WALL)
	end
	-- marco redondo de la escotilla (anillo metálico continuo) con aro de luz azul
	for k = 0, 23 do
		local ang = k / 24 * math.pi * 2
		local ring = O * CFrame.new(0, cy - 0.2, 0) * CFrame.Angles(0, -ang, 0)
		part("HatchFrame", Vector3.new(0.5, 0.45, 0.42), ring * CFrame.new(1.5, 0, 0), METAL, Enum.Material.Metal)
		part("HatchLed", Vector3.new(0.08, 0.08, 0.4), ring * CFrame.new(1.22, -0.2, 0), LED, Enum.Material.Neon)
	end
	local hatchGlass = part("HatchGlass", Vector3.new(0.06, 2.6, 2.6), O * CFrame.new(0, cy, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("CFE4FF"), Enum.Material.Glass, Enum.PartType.Cylinder)
	hatchGlass.Transparency = 0.85
	for _, hx in { -1.9, 1.9 } do -- asas de la escotilla, al lado (no tapan la vista)
		limb("HatchHandle", (O * CFrame.new(hx, cy - 0.45, -0.5)).Position, (O * CFrame.new(hx, cy - 0.45, 0.5)).Position, 0.14, AMBER, nil, true)
	end

	-- AFUERA (se ve por las ventanas y la escotilla): cielo que cambia, estrellas, suelo y la Tierra
	local sky = {}
	local P0 = O.Position
	for _, f in { { Vector3.new(400, 0, 0), Vector3.new(4, 800, 800) }, { Vector3.new(-400, 0, 0), Vector3.new(4, 800, 800) },
		{ Vector3.new(0, 0, 400), Vector3.new(800, 800, 4) }, { Vector3.new(0, 0, -400), Vector3.new(800, 800, 4) },
		{ Vector3.new(0, 400, 0), Vector3.new(800, 4, 800) } } do
		local p = part("Sky", f[2], CFrame.new(P0 + f[1]), Color3.fromHex("6FB6FF"), Enum.Material.Neon)
		table.insert(sky, p)
	end
	local stars = {}
	local rng = Random.new(11)
	for _ = 1, 160 do
		local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.25, 1), rng:NextNumber(-1, 1))
		if v.Magnitude > 0.2 then
			local s = rng:NextNumber(1.2, 2.6)
			local st = ball("Star", s, P0 + v.Unit * 330, Color3.new(1, 1, 1), Enum.Material.Neon)
			st.Transparency = 1
			table.insert(stars, st)
		end
	end
	local ground = part("Ground", Vector3.new(1600, 4, 1600), CFrame.new(P0 - Vector3.new(0, 6, 0)), Color3.fromHex("5E7A4C"), Enum.Material.Grass)
	local craters = {}
	for _ = 1, 30 do -- cráteres (solo en la Luna)
		local d = rng:NextNumber(8, 40)
		local c = part("Crater", Vector3.new(0.6, d, d), CFrame.new(P0 + Vector3.new(rng:NextNumber(-500, 500), -3.8, rng:NextNumber(-500, 500))) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("8F8BA3"), Enum.Material.Slate, Enum.PartType.Cylinder)
		c.Transparency = 1
		table.insert(craters, c)
	end
	local earth = ball("Earth", 120, P0 + Vector3.new(330, 60, -60), Color3.fromHex("2F7BFF"), Enum.Material.SmoothPlastic)
	local earthLand = {}
	for _, o in { Vector3.new(-50, 18, 10), Vector3.new(-48, -10, 25), Vector3.new(-45, 25, -20) } do
		local l = ball("EarthLand", 34, earth.Position + o, Color3.fromHex("4FB36A"), Enum.Material.SmoothPlastic)
		table.insert(earthLand, l)
	end
	earth.Transparency = 1
	for _, l in earthLand do l.Transparency = 1 end
	live.sky, live.stars, live.ground, live.craters, live.earth, live.earthLand = sky, stars, ground, craters, earth, earthLand

	-- 4 asientos en fila (crema con laterales negros) y la tripulación boca arriba
	local roleColors = {}
	for _, r in Config.RoleOrder do table.insert(roleColors, Config.Roles[r].Color) end
	table.clear(seatHeads)
	for i = 1, 4 do
		local x = (i - 2.5) * 2.7
		local s = O * CFrame.new(x, 1.3, 1) * CFrame.Angles(math.rad(-10), 0, 0)
		local function at(v: Vector3): Vector3 return (s * CFrame.new(v)).Position end
		-- asiento
		part("SeatShell", Vector3.new(2.2, 0.3, 3.4), s, DARK)
		part("SeatPad", Vector3.new(1.5, 0.22, 3.2), s * CFrame.new(0, 0.22, 0), CREAM, Enum.Material.Fabric)
		for _, sx in { -0.95, 0.95 } do
			part("Bolster", Vector3.new(0.3, 0.6, 3.2), s * CFrame.new(sx, 0.3, 0), DARK)
		end
		part("HeadRest", Vector3.new(1.5, 0.3, 1), s * CFrame.new(0, 0.2, 2.1), CREAM, Enum.Material.Fabric)
		part("LegRest", Vector3.new(1.9, 0.3, 1.8), s * CFrame.new(0, 0.9, -2.5) * CFrame.Angles(math.rad(40), 0, 0), DARK)
		part("SeatStrut", Vector3.new(0.3, 1.4, 0.3), s * CFrame.new(0, -0.8, -0.3), METAL, Enum.Material.Metal)
		-- astronauta (redondeado): pelvis, cuello y cabeza a lo largo del asiento; mira hacia arriba (+Y)
		local P, Nk, Hd = at(Vector3.new(0, 0.85, -0.7)), at(Vector3.new(0, 0.9, 1.0)), at(Vector3.new(0, 1.05, 1.75))
		limb("Torso", P, Nk, 1.35, SUIT, Enum.Material.Fabric)
		ball("Chest", 1.45, at(Vector3.new(0, 0.95, 0.5)), SUIT, Enum.Material.Fabric)
		limb("Belt", at(Vector3.new(-0.62, 0.85, -0.55)), at(Vector3.new(0.62, 0.85, -0.55)), 0.3, SUITDARK, nil, false)
		for _, sx in { -0.38, 0.38 } do -- correas del arnés
			limb("Strap", at(Vector3.new(sx, 1.55, 0.95)), at(Vector3.new(sx * 0.5, 1.5, -0.4)), 0.12, SUITDARK, nil, false)
		end
		ball("Patch", 0.4, at(Vector3.new(0.72, 1.2, 0.75)), roleColors[i] or AMBER, Enum.Material.Neon)
		-- casco con visor oscuro
		ball("Helmet", 1.45, Hd, SUIT)
		local visor = ball("Visor", 1.1, at(Vector3.new(0, 1.42, 1.8)), Color3.fromHex("14151C"), Enum.Material.Glass)
		visor.Reflectance = 0.35
		limb("HelmetRing", at(Vector3.new(0, 0.95, 1.05)), at(Vector3.new(0, 0.95, 1.25)), 1.25, SUITDARK, nil, false)
		-- brazos: del hombro al codo y la mano sobre el pecho
		for _, sx in { -1, 1 } do
			local sh = at(Vector3.new(sx * 0.75, 1.0, 0.8))
			local el = at(Vector3.new(sx * 0.95, 1.35, -0.1))
			local hd = at(Vector3.new(sx * 0.45, 1.65, -0.4))
			limb("UpperArm", sh, el, 0.5, SUIT, Enum.Material.Fabric)
			limb("Forearm", el, hd, 0.45, SUIT, Enum.Material.Fabric)
			ball("Glove", 0.5, hd, SUITDARK)
			-- piernas: muslo hacia arriba, rodilla, pantorrilla hacia el apoyo y bota
			local hip = at(Vector3.new(sx * 0.33, 0.85, -0.8))
			local knee = at(Vector3.new(sx * 0.33, 1.85, -1.85))
			local ankle = at(Vector3.new(sx * 0.33, 1.55, -3.05))
			limb("Thigh", hip, knee, 0.62, SUIT, Enum.Material.Fabric)
			limb("Shin", knee, ankle, 0.55, SUIT, Enum.Material.Fabric)
			part("Boot", Vector3.new(0.55, 0.8, 0.75), CFrame.lookAt(ankle, ankle + (s.UpVector * 0.4 - s.LookVector)) * CFrame.new(0, 0, -0.15), SUITDARK)
		end
		seatHeads[i] = CFrame.new(at(Vector3.new(0, 1.25, 1.95)))
	end

	-- Panel curvo que cuelga encima de la tripulación: 3 pantallas en arco (frente = hacia ellos)
	local panelCF = O * CFrame.new(0, 5.7, -0.7) * CFrame.Angles(math.rad(45), 0, 0)
	part("PanelArm", Vector3.new(0.5, 3.3, 0.5), O * CFrame.new(-3, 7.6, -1.8), METAL, Enum.Material.Metal)
	part("PanelArm", Vector3.new(0.5, 3.3, 0.5), O * CFrame.new(3, 7.6, -1.8), METAL, Enum.Material.Metal)
	local screens = {}
	for k, ang in { 16, 0, -16 } do
		local seg = panelCF * CFrame.new((k - 2) * 3.5, 0, (k == 2) and -0.25 or 0) * CFrame.Angles(0, math.rad(ang), 0)
		part("Bezel", Vector3.new(3.55, 2.75, 0.3), seg * CFrame.new(0, 0, -0.18), BEZEL)
		local s = part("Screen" .. k, Vector3.new(3.25, 2.4, 0.05), seg * CFrame.Angles(0, math.pi, 0), SCREEN, Enum.Material.Glass)
		screens[k] = screenGui(s)
	end
	part("BezelLed", Vector3.new(10.6, 0.06, 0.1), panelCF * CFrame.new(0, 1.42, -0.1), LED, Enum.Material.Neon)
	-- Pantalla izquierda: lista de pasos
	label(screens[1], "SEQUENCE", UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0, 0), BLUE, true)
	local steps = {}
	for i, txt in { "CABIN PRESSURE", "SUITS SEALED", "O2 FLOW", "COMMS", "ENGINES" } do
		steps[i] = label(screens[1], "[ ] " .. txt, UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0, 0.06 + i * 0.15), Color3.fromHex("A9BCE0"))
	end
	-- Pantalla del centro: trayectoria, altitud, velocidad y reloj
	label(screens[2], "TRAJECTORY", UDim2.fromScale(0.6, 0.12), UDim2.fromScale(0, 0), BLUE, true)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.36, 0.56)
	ring.Size = UDim2.fromScale(0.5, 0.66)
	ring.BackgroundTransparency = 1
	ring.Parent = screens[2]
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0.5, 0); corner.Parent = ring
	local stroke = Instance.new("UIStroke"); stroke.Color = BLUE; stroke.Thickness = 3; stroke.Parent = ring
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromScale(0.06, 0.08)
	dot.BackgroundColor3 = AMBER
	dot.Parent = screens[2]
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0.5, 0); dc.Parent = dot
	local alt = label(screens[2], "ALT 0.0 km", UDim2.fromScale(0.36, 0.13), UDim2.fromScale(0.62, 0.3), Color3.new(1, 1, 1))
	local vel = label(screens[2], "VEL 0 m/s", UDim2.fromScale(0.36, 0.13), UDim2.fromScale(0.62, 0.48), Color3.new(1, 1, 1))
	local clock = label(screens[2], "T- 00:10", UDim2.fromScale(0.36, 0.15), UDim2.fromScale(0.62, 0.66), AMBER, true)
	-- Pantalla derecha: sistemas en barras
	label(screens[3], "SYSTEMS", UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0, 0), BLUE, true)
	local bars = {}
	for i, txt in { "O2", "PWR", "H2O", "FUEL" } do
		label(screens[3], txt, UDim2.fromScale(0.2, 0.12), UDim2.fromScale(0, 0.08 + i * 0.18), Color3.fromHex("A9BCE0"))
		local back = Instance.new("Frame")
		back.Size = UDim2.fromScale(0.65, 0.09)
		back.Position = UDim2.fromScale(0.25, 0.1 + i * 0.18)
		back.BackgroundColor3 = Color3.fromHex("14254F")
		back.BorderSizePixel = 0
		back.Parent = screens[3]
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0.9, 1)
		fill.BackgroundColor3 = Color3.fromHex("4CD08A")
		fill.BorderSizePixel = 0
		fill.Parent = back
		bars[txt] = fill
	end

	-- Fila analógica bajo las pantallas: relojes con aguja, interruptores y luces ámbar
	local strip = panelCF * CFrame.new(0, -1.75, 0.05)
	part("Strip", Vector3.new(10.4, 0.9, 0.3), strip * CFrame.new(0, 0, -0.15), BEZEL, Enum.Material.Metal)
	local needles = {}
	for k, x in { -4.4, -3.5, 3.5, 4.4 } do
		local g = strip * CFrame.new(x, 0, 0.1)
		part("Gauge", Vector3.new(0.08, 0.72, 0.72), g * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("F4EAD0"), nil, Enum.PartType.Cylinder)
		part("GaugeRim", Vector3.new(0.06, 0.82, 0.82), g * CFrame.new(0, 0, -0.03) * CFrame.Angles(0, math.rad(90), 0), METAL, Enum.Material.Metal, Enum.PartType.Cylinder)
		needles[k] = { p = part("Needle", Vector3.new(0.04, 0.28, 0.03), g * CFrame.new(0, 0.12, 0.06), Color3.fromHex("D7261E")), c = g * CFrame.new(0, 0, 0.06) }
	end
	local lamps = {}
	for k = 0, 9 do
		local x = -2.5 + k * 0.55
		part("Switch", Vector3.new(0.12, 0.35, 0.12), strip * CFrame.new(x, -0.12, 0.18) * CFrame.Angles(math.rad(25), 0, 0), METAL, Enum.Material.Metal)
		lamps[k] = part("Lamp", Vector3.new(0.22, 0.14, 0.08), strip * CFrame.new(x, 0.25, 0.06), Color3.fromHex("5A4020"), Enum.Material.Neon)
	end
	part("RedGuard", Vector3.new(0.5, 0.5, 0.3), strip * CFrame.new(2.9, 0, 0.2), Color3.fromHex("D7261E")).Transparency = 0.25

	-- Columna central de mandos (entre los asientos 2 y 3): botones y mando de mano
	local col = O * CFrame.new(0, 3.3, -1.6)
	part("Column", Vector3.new(0.5, 3.6, 0.5), O * CFrame.new(0, 1.8, -1.9), METAL, Enum.Material.Metal)
	part("ColumnHead", Vector3.new(1.4, 1.1, 0.4), col * CFrame.Angles(math.rad(40), 0, 0), BEZEL)
	for bx = -1, 1 do
		for by = 0, 1 do
			part("Button", Vector3.new(0.3, 0.22, 0.08), col * CFrame.Angles(math.rad(40), 0, 0) * CFrame.new(bx * 0.4, 0.15 - by * 0.35, 0.22), by == 0 and BLUE or Color3.fromHex("DDE6FF"), Enum.Material.Neon)
		end
	end

	-- Cables y tubos del techo (naranja y negro) y paneles laterales con perillas
	for k = 1, 5 do
		local a = k * 1.1
		local from = (O * CFrame.new(math.cos(a) * 3.8, 8.6, math.sin(a) * 3.8)).Position
		local to = (O * CFrame.new(math.cos(a + 0.9) * 4.3, 7.4, math.sin(a + 0.9) * 4.3)).Position
		local mid = from:Lerp(to, 0.5) - Vector3.new(0, 0.6, 0)
		limb("Cable", from, mid, 0.14, k % 2 == 0 and Color3.fromHex("2B2B2B") or Color3.fromHex("C4572A"), nil, false)
		limb("Cable", mid, to, 0.14, k % 2 == 0 and Color3.fromHex("2B2B2B") or Color3.fromHex("C4572A"), nil, false)
	end
	for _, side in { -1, 1 } do
		local sp = O * CFrame.new(side * 5.3, 2.6, -3.3) * CFrame.Angles(0, side * math.rad(-50), 0)
		part("SidePanel", Vector3.new(2.4, 1.6, 0.25), sp, BEZEL, Enum.Material.Metal)
		for k = 0, 5 do
			part("Knob", Vector3.new(0.2, 0.22, 0.22), sp * CFrame.new(-0.8 + (k % 3) * 0.8, k < 3 and 0.35 or -0.35, -0.18) * CFrame.Angles(0, math.rad(90), 0), k % 2 == 0 and AMBER or METAL, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
	end

	-- Detallitos: extintor, bolsas de carga, rejillas de aire, etiquetas y agarraderas
	local function onWall(angDeg: number, y: number, inward: number): CFrame
		local a = math.rad(angDeg)
		local r = r0 - (r0 - r1) * (y / H) - inward
		return O * CFrame.Angles(0, a, 0) * CFrame.new(0, y, -r)
	end
	local function placard(cf: CFrame, text: string, color: Color3?)
		local p = part("Placard", Vector3.new(1.1, 0.32, 0.05), cf, DARK)
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Back -- mira hacia adentro (+Z local)
		g.LightInfluence = 0
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 80
		g.Parent = p
		local t = label(g, text, UDim2.fromScale(0.94, 0.9), UDim2.fromScale(0.03, 0.05), color or Color3.fromHex("F2C230"), true)
		t.TextXAlignment = Enum.TextXAlignment.Center
	end
	-- extintor rojo con su soporte
	local ext = onWall(150, 2.4, 0.55)
	part("Extinguisher", Vector3.new(1.3, 0.5, 0.5), ext * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("D7261E"), nil, Enum.PartType.Cylinder)
	part("ExtTop", Vector3.new(0.25, 0.3, 0.25), ext * CFrame.new(0, 0.75, 0), DARK)
	part("ExtStrap", Vector3.new(0.56, 0.1, 0.56), ext * CFrame.new(0, 0.2, 0), METAL, Enum.Material.Metal)
	placard(onWall(150, 3.45, 0.32), "FIRE", Color3.fromHex("FF6B5E"))
	-- bolsas de carga blancas con correas detrás de los asientos
	for k, ang in { 165, 180, 195 } do
		local b = onWall(ang, 0.75 + (k == 2 and 0.2 or 0), 1.1)
		part("CargoBag", Vector3.new(1.4, 1.3 + (k == 2 and 0.4 or 0), 0.9), b, Color3.fromHex("E8E6DD"), Enum.Material.Fabric)
		part("BagStrap", Vector3.new(1.44, 0.12, 0.94), b * CFrame.new(0, 0.25, 0), SUITDARK)
		part("BagTag", Vector3.new(0.4, 0.25, 0.02), b * CFrame.new(0.3, -0.1, 0.46), AMBER)
	end
	-- rejillas de ventilación
	for _, ang in { 120, 240 } do
		local v = onWall(ang, 6.6, 0.25)
		part("Vent", Vector3.new(1.2, 0.7, 0.1), v, Color3.fromHex("C4C7D2"))
		for k = -2, 2 do
			part("VentBar", Vector3.new(1.05, 0.06, 0.06), v * CFrame.new(0, k * 0.12, 0.06), DARK)
		end
	end
	-- etiquetas cerca de los paneles
	placard(onWall(55, 3.8, 0.3), "CABIN PRESS")
	placard(onWall(305, 3.8, 0.3), "O2 / N2")
	placard(onWall(15, 6.9, 0.25), "HATCH")
	placard(onWall(345, 6.9, 0.25), "COMMS", Color3.fromHex("6FC3FF"))
	-- agarraderas en U junto al techo
	for _, ang in { 30, 150, 210, 330 } do
		local g0 = onWall(ang, 7.4, 0.45)
		limb("Grab", (g0 * CFrame.new(-0.5, 0, 0)).Position, (g0 * CFrame.new(0.5, 0, 0)).Position, 0.12, AMBER, nil, true)
	end
	-- Indicador de gravedad cero: lucecita LED minimalista colgando del panel (esfera blanca con un ojo de luz cian).
	-- Cuelga hacia el piso con gravedad y flota cuando ya no hay (las tripulaciones reales usan un objeto así).
	local hang = (panelCF * CFrame.new(1.8, -2.4, 0.4)).Position
	local toy = {}
	toy.body = ball("OrbShell", 0.5, hang - Vector3.new(0, 0.85, 0), Color3.fromHex("F2F3F7"))
	toy.band = part("OrbBand", Vector3.new(0.1, 0.53, 0.53), CFrame.new(hang - Vector3.new(0, 0.85, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("3A3D48"), nil, Enum.PartType.Cylinder)
	toy.eye = ball("OrbEye", 0.2, hang - Vector3.new(0, 0.85, -0.2), Color3.fromHex("5FE8FF"), Enum.Material.Neon)
	toy.cap = part("OrbCap", Vector3.new(0.14, 0.12, 0.14), CFrame.new(hang - Vector3.new(0, 0.58, 0)), Color3.fromHex("3A3D48"), Enum.Material.Metal)
	toy.string = part("OrbCable", Vector3.new(0.03, 0.3, 0.03), CFrame.new(hang - Vector3.new(0, 0.15, 0)), Color3.fromHex("2B2B2B"))
	toy.light = Instance.new("PointLight")
	toy.light.Color = Color3.fromHex("5FE8FF")
	toy.light.Range = 5
	toy.light.Brightness = 1.5
	toy.light.Parent = toy.eye
	live.toy, live.toyHang = toy, hang

	-- Luces: blanca general, azul de las pantallas y ámbar de los instrumentos
	local lp = part("CabinLight", Vector3.new(0.2, 0.2, 0.2), O * CFrame.new(0, 6.5, 1), Color3.new(1, 1, 1))
	lp.Transparency = 1
	local l0 = Instance.new("PointLight"); l0.Color = Color3.fromHex("FFF4E6"); l0.Range = 20; l0.Brightness = 2.2; l0.Parent = lp
	local l1 = Instance.new("SurfaceLight"); l1.Face = Enum.NormalId.Bottom; l1.Color = Color3.fromHex("8FB0FF"); l1.Range = 10; l1.Angle = 120; l1.Brightness = 2; l1.Parent = folder.BezelLed
	local l2 = Instance.new("PointLight"); l2.Color = AMBER; l2.Range = 9; l2.Brightness = 1; l2.Parent = folder.Strip

	live.steps, live.alt, live.vel, live.clock, live.dot, live.bars, live.needles, live.lamps, live.panel =
		steps, alt, vel, clock, dot, bars, needles, lamps, panelCF
	folder.Parent = workspace
end

---------------------------------------------------------------------
-- Pantalla negra, borde del visor y letrero
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SO_CockpitGui"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 61
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local visorFrame = Instance.new("Frame") -- borde oscuro del casco en primera persona
visorFrame.Size = UDim2.fromScale(1, 1)
visorFrame.BackgroundTransparency = 1
visorFrame.Visible = false
visorFrame.Parent = gui
for _, e in { { 0, 0, 1, 0.16, 90 }, { 0, 0.84, 1, 0.16, -90 }, { 0, 0, 0.12, 1, 0 }, { 0.88, 0, 0.12, 1, 180 } } do
	local f = Instance.new("Frame")
	f.Position = UDim2.fromScale(e[1], e[2])
	f.Size = UDim2.fromScale(e[3], e[4])
	f.BackgroundColor3 = Color3.fromHex("05060A")
	f.BorderSizePixel = 0
	f.Parent = visorFrame
	local g = Instance.new("UIGradient")
	g.Rotation = e[5]
	g.Transparency = NumberSequence.new(0, 1)
	g.Parent = f
end
local black = Instance.new("Frame")
black.Size = UDim2.fromScale(1, 1)
black.BackgroundColor3 = Color3.new(0, 0, 0)
black.BackgroundTransparency = 1
black.BorderSizePixel = 0
black.Parent = gui
local caption = Instance.new("TextLabel")
caption.AnchorPoint = Vector2.new(0.5, 1)
caption.Position = UDim2.new(0.5, 0, 0.9, 0)
caption.Size = UDim2.fromScale(0.7, 0.1)
caption.BackgroundTransparency = 1
caption.Font = Enum.Font.FredokaOne
caption.TextScaled = true
caption.TextColor3 = Color3.new(1, 1, 1)
caption.TextStrokeTransparency = 0.3
caption.Text = ""
caption.Parent = gui
local function fade(to: number, t: number)
	TweenService:Create(black, TweenInfo.new(t), { BackgroundTransparency = to }):Play()
	task.wait(t)
end

---------------------------------------------------------------------
-- Tomas
---------------------------------------------------------------------
local SHOTS = {
	launch = { time = T.LaunchTime, window = Color3.fromHex("6FB6FF"), windowEnd = Color3.fromHex("05060C") },
	landing = { time = T.LandingTime, window = Color3.fromHex("05060C"), windowEnd = Color3.fromHex("BDB9CC") },
	["return"] = { time = T.ReturnTime, window = Color3.fromHex("2F7BFF"), windowEnd = Color3.fromHex("3E8CFF") },
}

-- Asiento del jugador = orden de su rol (Captain, Engineer, Life Support, Botanist)
local function mySeat(): number
	local role = player:GetAttribute("Role")
	for i, r in Config.RoleOrder do
		if r == role then return i end
	end
	return 2
end

-- Durante la toma: luz neutra (la de la Luna o la Tierra no debe teñir la cabina)
local function setCabinLighting(on: boolean, saved: { [string]: any })
	if on then
		saved.Ambient, saved.OutdoorAmbient, saved.Exposure = Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ExposureCompensation
		saved.effects = {}
		for _, e in Lighting:GetChildren() do
			if e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") then
				saved.effects[e] = e.Enabled
				e.Enabled = false
			end
		end
		Lighting.Ambient = Color3.fromHex("8A8C96")
		Lighting.OutdoorAmbient = Color3.fromHex("8A8C96")
		Lighting.ExposureCompensation = 0
	else
		Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.ExposureCompensation = saved.Ambient, saved.OutdoorAmbient, saved.Exposure
		for e, en in saved.effects or {} do
			if e.Parent then e.Enabled = en end
		end
	end
end

local running = false
local function play(kind: string)
	local shot = SHOTS[kind]
	if not shot or running then return end
	running = true
	build()
	local camera = workspace.CurrentCamera
	local prevType = camera.CameraType
	local prevFov = camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable
	local saved = {}
	-- Tomas: 1) primera persona desde el casco del jugador; 2) detrás de los cascos (la del regreso empieza aquí)
	local head = seatHeads[mySeat()] or seatHeads[2]
	local panelPos = (live.panel :: CFrame).Position
	local povPos, povLook = head.Position, panelPos + Vector3.new(0, -0.4, 0)
	local widePos, wideLook = (O * CFrame.new(0.6, 3.3, 5.6)).Position, (O * CFrame.new(0, 5.6, -1.2)).Position
	local povShare = kind == "return" and 0.45 or (T.PovShare or 0.55)
	-- Afuera según la toma: cielo, suelo (Tierra o Luna), estrellas y la Tierra lejos
	local P0 = O.Position
	local moonGround = kind == "landing"
	live.ground.Color = moonGround and Color3.fromHex("BDB9CC") or Color3.fromHex("5E7A4C")
	live.ground.Material = moonGround and Enum.Material.Slate or Enum.Material.Grass
	live.ground.Transparency = kind == "return" and 1 or 0
	for _, c in live.craters do c.Transparency = moonGround and 0 or 1 end
	local showEarth = kind == "return" or kind == "landing"
	live.earth.Transparency = showEarth and 0 or 1
	for _, l in live.earthLand do l.Transparency = showEarth and 0 or 1 end
	local earthScale = kind == "landing" and 0.25 or 1 -- desde la Luna la Tierra se ve chica
	live.earth.Size = Vector3.one * 120 * earthScale
	live.earth.Position = P0 + Vector3.new(330, kind == "landing" and 150 or 60, -60)
	for idx, l in live.earthLand do
		local o = ({ Vector3.new(-50, 18, 10), Vector3.new(-48, -10, 25), Vector3.new(-45, 25, -20) })[idx]
		l.Size = Vector3.one * 34 * earthScale
		l.Position = live.earth.Position + o * earthScale
	end
	local function outside(k: number, t: number)
		local skyCol = kind == "launch" and Color3.fromHex("6FB6FF"):Lerp(Color3.fromHex("04050B"), math.clamp((k - 0.45) / 0.45, 0, 1)) or Color3.fromHex("04050B")
		for _, s in live.sky do s.Color = skyCol end
		local starsOn = kind ~= "launch" or k > 0.8
		for _, s in live.stars do s.Transparency = starsOn and 0 or 1 end
		-- el suelo se aleja al despegar y se acerca al aterrizar
		local gy = kind == "launch" and (-6 - math.max(0, k - 0.6) ^ 2 * 900) or (kind == "landing" and (-160 + k * 154) or -6)
		live.ground.Position = P0 + Vector3.new(0, gy, 0)
		for _, c in live.craters do c.Position = Vector3.new(c.Position.X, P0.Y + gy + 2.2, c.Position.Z) end
		-- la Tierra gira despacio de regreso
		if kind == "return" then
			live.earth.CFrame = CFrame.new(live.earth.Position) * CFrame.Angles(0, t * 0.05, 0)
		end
	end
	outside(0, 0)
	-- La lucecita: cuelga hacia el piso (gravedad) y flota en el espacio; su ojo pulsa
	local function toyPose(k: number, t: number)
		local toy, hang = live.toy, live.toyHang
		local floating = (kind == "return") or (kind == "launch" and k > 0.85)
		local off: Vector3
		if floating then
			off = Vector3.new(math.sin(t * 0.9) * 0.35, -0.35 + math.sin(t * 0.6) * 0.25, math.cos(t * 0.7) * 0.3)
		else
			local swing = kind == "landing" and math.sin(t * 3) * 0.12 or math.sin(t * 2) * 0.04
			off = Vector3.new(swing, -0.85, 0)
		end
		local body = hang + off
		-- el ojo mira hacia la tripulación (+Z) y, flotando, gira despacio
		local spinCF = CFrame.new(body) * CFrame.Angles(floating and math.sin(t * 0.5) * 0.6 or 0, floating and t * 0.5 or 0, 0)
		toy.body.CFrame = spinCF
		toy.band.CFrame = spinCF * CFrame.Angles(0, 0, math.rad(90))
		toy.eye.CFrame = spinCF * CFrame.new(0, 0, 0.19)
		toy.cap.CFrame = spinCF * CFrame.new(0, 0.27, 0)
		local pulse = 0.5 + 0.5 * math.sin(t * 3)
		toy.light.Brightness = 0.8 + pulse * 1.4
		toy.eye.Color = Color3.fromHex("2FB8D8"):Lerp(Color3.fromHex("A8F6FF"), pulse)
		local top = (spinCF * CFrame.new(0, 0.33, 0)).Position
		local len = math.max(0.05, (hang - top).Magnitude)
		toy.string.Size = Vector3.new(0.03, len, 0.03)
		toy.string.CFrame = CFrame.lookAt((hang + top) / 2, hang) * CFrame.Angles(math.rad(90), 0, 0)
	end
	toyPose(0, 0)
	for _, s in live.steps do
		s.Text = (kind == "launch" and "[ ] " or "[x] ") .. s.Text:sub(5)
		s.TextColor3 = kind == "launch" and Color3.fromHex("A9BCE0") or Color3.fromHex("4CD08A")
	end
	fade(0, 0.25)
	setCabinLighting(true, saved)
	local firstPov = kind ~= "return"
	camera.FieldOfView = firstPov and 85 or 72
	visorFrame.Visible = firstPov
	fade(1, 0.35)
	local t0 = os.clock()
	local stepShown = 0
	local lampAt = 0
	local cut = false
	while true do
		local t = os.clock() - t0
		local k = math.clamp(t / shot.time, 0, 1)
		-- corte de cámara a mitad de la toma
		local pov = (k < povShare) == firstPov
		if not cut and (k >= povShare) then
			cut = true
			camera.FieldOfView = pov and 85 or 72
			visorFrame.Visible = pov
		end
		-- Temblor: fuerte al despegar, suave al frenar en la Luna, casi nada de regreso
		local shake = 0.01
		if kind == "launch" then
			shake = k > 0.5 and (k - 0.5) * 0.4 or 0.01
		elseif kind == "landing" then
			shake = 0.05 + k * 0.07
		end
		local jitter = Vector3.new(math.noise(t * 20, 1) * shake, math.noise(t * 20, 2) * shake, math.noise(t * 20, 3) * shake)
		if pov then
			camera.CFrame = CFrame.lookAt(povPos + jitter * 0.6, povLook + jitter)
		else
			local bob = kind == "return" and Vector3.new(0, math.sin(t * 0.8) * 0.15, 0) or Vector3.zero
			camera.CFrame = CFrame.lookAt(widePos + jitter + bob, wideLook + jitter * 0.5)
		end
		-- Ventanas: el cielo se oscurece al subir; la Luna se acerca al bajar
		outside(k, t)
		toyPose(k, t)
		-- Lista de pasos que se marca al despegar
		if kind == "launch" then
			local want = math.min(#live.steps, math.floor(k * 1.6 * #live.steps))
			while stepShown < want do
				stepShown += 1
				local s = live.steps[stepShown]
				s.Text = "[x]" .. s.Text:sub(4)
				s.TextColor3 = Color3.fromHex("4CD08A")
			end
		end
		-- Números de la pantalla del centro
		local a = (kind == "launch") and k * k * 12 or ((kind == "landing") and (1 - k) * 2.5 or 380000 * (0.1 + k * 0.02))
		live.alt.Text = string.format("ALT %s km", a >= 1000 and string.format("%d", a) or string.format("%.1f", a))
		live.vel.Text = string.format("VEL %d m/s", (kind == "launch") and math.floor(k * k * 1900) or ((kind == "landing") and math.floor((1 - k) * 60) or 1450))
		if kind == "launch" then
			local left = math.max(0, math.ceil((0.7 - k) / 0.7 * 3 - 0.01))
			live.clock.Text = left > 0 and string.format("T- 00:0%d", left) or "T+ 00:01"
			caption.Text = left > 0 and tostring(left) or T.Text.Liftoff
		else
			live.clock.Text = string.format("T+ %02d:%02d", math.floor(t / 60), math.floor(t % 60))
			caption.Text = kind == "landing" and T.Text.Landing or T.Text.Return
		end
		local ang = (kind == "return" and 0.3 or 0) + k * math.pi * 2 * (kind == "launch" and 0.15 or 0.25)
		live.dot.Position = UDim2.fromScale(0.36 + math.cos(ang) * 0.25, 0.56 - math.sin(ang) * 0.33)
		live.bars.FUEL.Size = UDim2.fromScale(kind == "launch" and (0.95 - k * 0.25) or (kind == "landing" and (0.45 - k * 0.15) or 0.6), 1)
		-- Agujas que tiemblan y luces ámbar que parpadean
		for i, n in live.needles do
			local target = (kind == "launch" and k * 1.8 or 1.1) + math.noise(t * 6, i) * (shake * 4 + 0.08)
			n.p.CFrame = n.c * CFrame.Angles(0, 0, -target) * CFrame.new(0, 0.12, 0)
		end
		if t - lampAt > 0.18 then
			lampAt = t
			for _, l in live.lamps do
				l.Color = (math.random() < (kind == "launch" and 0.6 or 0.35)) and AMBER or Color3.fromHex("5A4020")
			end
		end
		if k >= 1 or (kind == "return" and GS:GetAttribute("Phase") ~= "Rescue") then break end
		RunService.RenderStepped:Wait()
	end
	fade(0, 0.3)
	caption.Text = ""
	visorFrame.Visible = false
	setCabinLighting(false, saved)
	camera.FieldOfView = prevFov
	camera.CameraType = prevType
	if prevType ~= Enum.CameraType.Scriptable then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then camera.CameraSubject = hum end
	end
	running = false
	-- quien llama (LaunchCinematic) hace su propio fundido; si no, quitamos el negro aquí
	task.delay(0.05, function() if not running then fade(1, 0.3) end end)
end

-- API local para LaunchCinematic: espera a que termine la toma
local api = ReplicatedStorage:FindFirstChild("SO_CockpitShot") or Instance.new("BindableFunction")
api.Name = "SO_CockpitShot"
api.OnInvoke = function(kind: string)
	play(kind)
	return true
end
api.Parent = ReplicatedStorage

-- Regreso: al final de "Rescue", antes de la pantalla final
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if GS:GetAttribute("Phase") ~= "Rescue" then return end
	task.delay(T.ReturnAt, function()
		if GS:GetAttribute("Phase") == "Rescue" then
			player:SetAttribute("SO_Cinematic", true)
			play("return")
			player:SetAttribute("SO_Cinematic", false)
		end
	end)
end)
