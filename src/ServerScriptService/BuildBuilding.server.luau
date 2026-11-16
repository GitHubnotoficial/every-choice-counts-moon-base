-- BuildBuilding (Script) -> ServerScriptService.BuildBuilding
-- Dueño: Isaac + Claude (antes era tarea de Yamir). Edificio de la Fase 0 en la Tierra (PDF Fase 0, cap. 4),
-- con el estilo de los cuartos del prototipo "99 Dias": paredes blancas, piso azul oscuro, techo oscuro con tira de
-- neón del color del rol, banda translúcida en el piso, cartel oscuro al fondo y pedestales bajos con maqueta.
-- Construido desde cero con este script (no se copian piezas del prototipo).
-- Crea Workspace.EarthBase en Config.Zones.Earth: pasillo 86×14, 4 cuartos 26×24, sala de control 20×34,
-- pedestales Pedestal_<rol>_<opción> (atributos Role y Option), pantalla grande, consola y plataforma de lanzamiento.
-- Si EarthBase ya existe (construido en Edit), no hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local O = Config.Zones.Earth
local H = 12 -- alto de paredes

local C = {
	Wall = Color3.fromHex("E8EAF2"),
	Floor = Color3.fromHex("2B2F48"),
	Ceil = Color3.fromHex("141A33"),
	Hall = Color3.fromHex("3A3F66"),
	Ped = Color3.fromHex("2B2F48"),
	PedBase = Color3.fromHex("1B1F38"),
	White = Color3.fromHex("F4F2FA"),
	Lavender = Color3.fromHex("D9D2F5"),
	Pink = Color3.fromHex("FF4F9A"),
	Orange = Color3.fromHex("FF9A3C"),
	Metal = Color3.fromHex("8F8AA8"),
	Silver = Color3.fromHex("C9CCD8"),
	Blue = Color3.fromHex("2F7BFF"),
	Sky = Color3.fromHex("7FD6FF"),
	Green = Color3.fromHex("3DD68C"),
	Brown = Color3.fromHex("8A5A3C"),
	Yellow = Color3.fromHex("FFD43B"),
	Red = Color3.fromHex("FC3D21"),
	Purple = Color3.fromHex("7B4DFF"),
	Crate = Color3.fromHex("E0B26A"),
}

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
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
	if props then
		for k, v in props do (p :: any)[k] = v end
	end
	p.Parent = parent
	return p
end
local function cylY(parent, name, h, d, pos: Vector3, color, props)
	local p = P(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(parent, name, d, pos: Vector3, color, props)
	local p = P(parent, name, Vector3.new(d, d, d), CFrame.new(pos), color, props)
	p.Shape = Enum.PartType.Ball
	return p
end
local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local function finish(m: Model, primary: BasePart)
	m.PrimaryPart = primary
	primary.PivotOffset = primary.CFrame:Inverse()
end
local function textGui(part: BasePart, face: Enum.NormalId, lines: { any }, bg: Color3?)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = part
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = bg or C.Ceil
	frame.Parent = sg
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0); pad.PaddingRight = UDim.new(0.05, 0); pad.PaddingTop = UDim.new(0.06, 0)
	pad.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.02, 0)
	layout.Parent = frame
	for i, l in lines do
		local t = Instance.new("TextLabel")
		t.LayoutOrder = i
		t.Size = UDim2.new(1, 0, l[2], 0)
		t.BackgroundTransparency = 1
		t.Text = l[1]
		t.TextColor3 = l[3]
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextWrapped = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = frame
	end
	return sg
end

---------------------------------------------------------------------
-- Maquetas de las 13 opciones (~3 studs de alto, base en 0,0,0)
---------------------------------------------------------------------
local Maq = {}

local function lander(m: Model, s: number, bodyColor: Color3)
	local body = cylY(m, "Body", 1.6 * s, 1.8 * s, Vector3.new(0, 1.6 * s, 0), bodyColor)
	ball(m, "Nose", 1.8 * s, Vector3.new(0, 2.4 * s, 0), bodyColor)
	cylY(m, "Ring", 0.25 * s, 1.9 * s, Vector3.new(0, 0.9 * s, 0), C.Orange)
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local foot = Vector3.new(math.cos(a) * 1.5 * s, 0.15 * s, math.sin(a) * 1.5 * s)
		local hip = Vector3.new(math.cos(a) * 0.7 * s, 1 * s, math.sin(a) * 0.7 * s)
		local len = (hip - foot).Magnitude
		P(m, "Leg", Vector3.new(0.2 * s, len, 0.2 * s), CFrame.lookAt((foot + hip) / 2, hip) * CFrame.Angles(math.rad(90), 0, 0), C.Pink)
		ball(m, "Foot", 0.4 * s, foot, C.Pink)
	end
	return body
end

function Maq.light(m) finish(m, lander(m, 1, C.Lavender)) end
function Maq.cargo(m)
	local b = lander(m, 1.25, C.White)
	P(m, "CargoBox", Vector3.new(1.2, 0.8, 1.2), CFrame.new(0, 3.6, 0), C.Yellow)
	finish(m, b)
end
function Maq.starship(m)
	local b = cylY(m, "Body", 4.2, 1.4, Vector3.new(0, 2.5, 0), C.Silver, { Material = Enum.Material.Metal })
	ball(m, "Nose", 1.4, Vector3.new(0, 4.6, 0), C.Silver, { Material = Enum.Material.Metal })
	for i = 0, 3 do
		local a = math.rad(i * 90)
		P(m, "Fin", Vector3.new(0.15, 1.2, 0.8), CFrame.new(math.cos(a) * 0.8, 0.8, math.sin(a) * 0.8) * CFrame.Angles(0, -a, 0), C.Metal)
	end
	cylY(m, "Window", 0.2, 0.5, Vector3.new(0.7, 3.8, 0), C.Sky, { Material = Enum.Material.Glass })
	finish(m, b)
end
local function panel(m, x)
	local mast = cylY(m, "Mast", 1.6, 0.18, Vector3.new(x, 0.8, 0), C.Metal)
	P(m, "Panel", Vector3.new(2, 0.1, 1.4), CFrame.new(x, 1.7, 0) * CFrame.Angles(math.rad(-30), 0, 0), C.Blue, { Material = Enum.Material.Glass })
	return mast
end
function Maq.panels(m)
	finish(m, panel(m, -1.1))
	panel(m, 1.1)
end
function Maq.panels_bat(m)
	finish(m, panel(m, -1.1))
	panel(m, 1.1)
	P(m, "Battery", Vector3.new(1, 0.7, 0.7), CFrame.new(0, 0.35, 0.9), C.Yellow, { Material = Enum.Material.Neon })
end
function Maq.reactor(m)
	local core = cylY(m, "Core", 2.4, 1.3, Vector3.new(0, 1.2, 0), C.Metal, { Material = Enum.Material.Metal })
	cylY(m, "Band", 0.25, 1.4, Vector3.new(0, 1.9, 0), C.Yellow)
	for i = 0, 3 do
		local a = math.rad(i * 90)
		P(m, "Fin", Vector3.new(0.1, 1.8, 1), CFrame.new(math.cos(a) * 1.1, 1.2, math.sin(a) * 1.1) * CFrame.Angles(0, -a, 0), C.Lavender)
	end
	finish(m, core)
end
function Maq.electrolyzer(m)
	local b = P(m, "Box", Vector3.new(1.6, 1.4, 1.2), CFrame.new(0, 0.7, 0), C.White)
	cylY(m, "TubeA", 1.6, 0.4, Vector3.new(-0.4, 2.1, 0), C.Sky, { Material = Enum.Material.Glass })
	cylY(m, "TubeB", 1.6, 0.4, Vector3.new(0.4, 2.1, 0), C.Sky, { Material = Enum.Material.Glass })
	finish(m, b)
end
function Maq.recycler(m)
	local b = P(m, "Box", Vector3.new(1.8, 1.2, 1.2), CFrame.new(0, 0.6, 0), C.White)
	cylY(m, "Filter", 1.4, 1, Vector3.new(0, 1.9, 0), C.Silver, { Material = Enum.Material.Metal })
	cylY(m, "FilterRingT", 0.15, 1.05, Vector3.new(0, 2.55, 0), C.Blue)
	cylY(m, "FilterRingB", 0.15, 1.05, Vector3.new(0, 1.25, 0), C.Blue)
	finish(m, b)
end
function Maq.tanks(m)
	local a = cylY(m, "TankA", 2.6, 1, Vector3.new(-0.6, 1.3, 0), C.White)
	cylY(m, "TankB", 2.6, 1, Vector3.new(0.6, 1.3, 0), C.White)
	cylY(m, "StripeA", 0.25, 1.05, Vector3.new(-0.6, 1.6, 0), C.Blue)
	cylY(m, "StripeB", 0.25, 1.05, Vector3.new(0.6, 1.6, 0), C.Blue)
	finish(m, a)
end
function Maq.o2plant(m)
	local b = P(m, "Box", Vector3.new(1.8, 1.2, 1.4), CFrame.new(0, 0.6, 0), C.Purple)
	local funnel = cylY(m, "Funnel", 0.8, 1.2, Vector3.new(-0.3, 1.6, 0), C.Metal)
	funnel.Size = Vector3.new(0.8, 1.2, 1.2)
	cylY(m, "Chimney", 1.4, 0.35, Vector3.new(0.6, 1.9, 0), C.Silver)
	finish(m, b)
end
function Maq.regolith_kit(m)
	local b = P(m, "Box", Vector3.new(1.8, 0.9, 1.4), CFrame.new(0, 0.45, 0), C.Brown)
	P(m, "Soil", Vector3.new(1.6, 0.1, 1.2), CFrame.new(0, 0.92, 0), Color3.fromHex("6E6A8C"))
	cylY(m, "Stem", 0.7, 0.12, Vector3.new(0, 1.3, 0), C.Green)
	ball(m, "Leaf", 0.5, Vector3.new(0, 1.7, 0), C.Green, { Material = Enum.Material.Neon })
	finish(m, b)
end
function Maq.hydroponics(m)
	local frameL = P(m, "PostL", Vector3.new(0.15, 2.8, 0.15), CFrame.new(-1, 1.4, 0), C.Metal)
	P(m, "PostR", Vector3.new(0.15, 2.8, 0.15), CFrame.new(1, 1.4, 0), C.Metal)
	for i = 0, 2 do
		P(m, "Shelf", Vector3.new(2.1, 0.1, 1), CFrame.new(0, 0.5 + i * 0.9, 0), C.White)
		P(m, "Plants", Vector3.new(1.8, 0.3, 0.8), CFrame.new(0, 0.7 + i * 0.9, 0), C.Green, { Material = Enum.Material.Grass })
	end
	finish(m, frameL)
end
function Maq.packaged(m)
	local first
	for i, v in { Vector3.new(-0.6, 0.45, 0), Vector3.new(0.6, 0.45, 0), Vector3.new(0, 1.35, 0) } do
		local c = P(m, "Crate" .. i, Vector3.new(1.1, 0.9, 1.1), CFrame.new(v), C.Crate)
		first = first or c
	end
	finish(m, first)
end

---------------------------------------------------------------------
-- Edificio
---------------------------------------------------------------------
local ROOM_W, ROOM_D = 26, 24
local ROOMS = {
	{ role = "eng", x = -20, side = -1 }, -- norte
	{ role = "cap", x = 15, side = -1 },
	{ role = "bot", x = -20, side = 1 }, -- sur
	{ role = "life", x = 15, side = 1 },
}

local function buildRoom(base: Model, r)
	local info = Config.Roles[r.role]
	local room = model(base, "Room_" .. r.role)
	local zc = r.side * (7 + ROOM_D / 2) -- centro del cuarto
	local center = O + Vector3.new(r.x, 0, zc)
	local zDoor = r.side * 7 -- pared que da al pasillo
	local zBack = r.side * (7 + ROOM_D)

	P(room, "Floor", Vector3.new(ROOM_W, 0.6, ROOM_D), CFrame.new(center + Vector3.new(0, -0.3, 0)), C.Floor)
	P(room, "Ceiling", Vector3.new(ROOM_W, 0.6, ROOM_D), CFrame.new(center + Vector3.new(0, H + 0.3, 0)), C.Ceil)
	P(room, "WallL", Vector3.new(1, H, ROOM_D), CFrame.new(center + Vector3.new(-ROOM_W / 2, H / 2, 0)), C.Wall)
	P(room, "WallR", Vector3.new(1, H, ROOM_D), CFrame.new(center + Vector3.new(ROOM_W / 2, H / 2, 0)), C.Wall)
	P(room, "WallBack", Vector3.new(ROOM_W, H, 1), CFrame.new(O + Vector3.new(r.x, H / 2, zBack)), C.Wall)
	-- Pared del pasillo con puerta de 8 de ancho
	local seg = (ROOM_W - 8) / 2
	P(room, "WallDoorL", Vector3.new(seg, H, 1), CFrame.new(O + Vector3.new(r.x - 4 - seg / 2, H / 2, zDoor)), C.Wall)
	P(room, "WallDoorR", Vector3.new(seg, H, 1), CFrame.new(O + Vector3.new(r.x + 4 + seg / 2, H / 2, zDoor)), C.Wall)
	P(room, "WallDoorTop", Vector3.new(8, H - 9, 1), CFrame.new(O + Vector3.new(r.x, 9 + (H - 9) / 2, zDoor)), C.Wall)
	-- Marco de puerta del color del rol y letrero
	P(room, "DoorFrameL", Vector3.new(0.6, 9, 1.4), CFrame.new(O + Vector3.new(r.x - 4.3, 4.5, zDoor)), info.Color, { Material = Enum.Material.Neon })
	P(room, "DoorFrameR", Vector3.new(0.6, 9, 1.4), CFrame.new(O + Vector3.new(r.x + 4.3, 4.5, zDoor)), info.Color, { Material = Enum.Material.Neon })
	P(room, "DoorFrameT", Vector3.new(9.2, 0.6, 1.4), CFrame.new(O + Vector3.new(r.x, 9.3, zDoor)), info.Color, { Material = Enum.Material.Neon })
	local sign = P(room, "DoorSign", Vector3.new(8, 1.6, 0.2), CFrame.new(O + Vector3.new(r.x, 10.6, zDoor - r.side * 0.62)), C.Ceil)
	textGui(sign, r.side < 0 and Enum.NormalId.Back or Enum.NormalId.Front, { { info.Name, 0.85, info.Color } })

	-- Banda translúcida y tira de neón (estilo del prototipo)
	P(room, "Band", Vector3.new(ROOM_W, 1.5, ROOM_D), CFrame.new(center + Vector3.new(0, 0.75, 0)), info.Color, { Transparency = 0.92, CanCollide = false, CanQuery = false })
	P(room, "Strip", Vector3.new(18, 0.3, 1.4), CFrame.new(O + Vector3.new(r.x, H - 0.4, zDoor + r.side * 2)), info.Color, { Material = Enum.Material.Neon })
	-- Luz del color del rol + luz blanca de techo (mejora sobre el prototipo)
	local lamp = P(room, "Lamp", Vector3.new(1, 0.2, 1), CFrame.new(center + Vector3.new(0, H - 0.1, 0)), C.White, { Material = Enum.Material.Neon, Transparency = 0.3 })
	local pl = Instance.new("PointLight"); pl.Color = info.Color; pl.Range = 22; pl.Brightness = 1.6; pl.Parent = lamp
	local sl = Instance.new("SurfaceLight"); sl.Face = Enum.NormalId.Bottom; sl.Range = 16; sl.Brightness = 1.2; sl.Angle = 120; sl.Parent = lamp

	-- Cartel del rol en la pared del fondo
	local poster = P(room, "Poster", Vector3.new(16, 5, 0.4), CFrame.new(O + Vector3.new(r.x, 9.45, zBack - r.side * 0.7)), C.Ceil)
	textGui(poster, r.side < 0 and Enum.NormalId.Back or Enum.NormalId.Front, {
		{ info.Name, 0.28, info.Color },
		{ info.Card, 0.2, Color3.new(1, 1, 1) },
		{ "Click a model: see pros and cons", 0.15, Color3.fromHex("C9BEF5") },
		{ "Double-click: choose it", 0.15, Color3.fromHex("FFD43B") },
	})

	-- Pedestales con maqueta y cartel al lado, en fila frente a la pared del fondo
	local opts = Config.Options[r.role]
	local n = #opts
	local spacing = 6
	local zPed = zBack - r.side * 4.5
	-- 15-nov: pedestales 1,2 más altos y carteles más grandes (pedido de Isaac: se leían mal)
	local RAISE = 1.2
	for i, o in opts do
		local x = r.x + (i - (n + 1) / 2) * spacing
		local base = P(room, "Step_" .. o.Id, Vector3.new(4.4, 1 + RAISE, 5.4), CFrame.new(O + Vector3.new(x, (1 + RAISE) / 2, zPed)), C.PedBase)
		local ped = P(room, "Pedestal_" .. r.role .. "_" .. o.Id, Vector3.new(3.6, 0.6, 4.6), CFrame.new(O + Vector3.new(x, 1.3 + RAISE, zPed)), C.Ped)
		ped:SetAttribute("Role", r.role)
		ped:SetAttribute("Option", o.Id)
		local glow = P(room, "Glow_" .. o.Id, Vector3.new(3.8, 0.1, 4.8), CFrame.new(O + Vector3.new(x, 1.0 + RAISE, zPed)), info.Color, { Material = Enum.Material.Neon, Transparency = 0.6 })
		glow:SetAttribute("Option", o.Id)
		-- Maqueta encima, mirando al pasillo
		local m = model(room, "Model_" .. o.Id)
		Maq[o.Id](m)
		m:PivotTo(CFrame.new(O + Vector3.new(x, 1.6 + RAISE, zPed)) * CFrame.Angles(0, r.side < 0 and math.pi or 0, 0))
		m:SetAttribute("Role", r.role)
		m:SetAttribute("Option", o.Id)
		-- Nombre flotando sobre la maqueta (como el prototipo)
		local bb = Instance.new("BillboardGui")
		bb.Name = "NameTag"
		bb.Size = UDim2.fromOffset(120, 22)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
		bb.MaxDistance = 18
		bb.LightInfluence = 0
		bb.Enabled = false -- 15-nov: tapaba el póster; el nombre ya está en la placa de adelante
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = o.Name
		t.TextColor3 = info.Color
		t.TextStrokeTransparency = 0.3
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Parent = bb
		bb.Parent = ped
		-- Cartel al lado (nombre, cuándo se usó, dato real)
		local card = P(room, "Card_" .. o.Id, Vector3.new(4.2, 2.6, 0.2), CFrame.new(O + Vector3.new(x, 2.45, zPed - r.side * 3.4)) * CFrame.Angles(0, r.side < 0 and math.pi or 0, 0) * CFrame.Angles(math.rad(50), 0, 0), C.Ceil)
		textGui(card, Enum.NormalId.Front, {
			{ o.Name, 0.18, info.Color },
			{ o.UsedIn, 0.2, Color3.fromHex("C9BEF5") },
			{ "Real fact: " .. o.Fact, 0.5, Color3.new(1, 1, 1) },
		})
	end
	return room
end

local function buildSite(): Model
	local base = model(workspace, "EarthBase")

	-- Pasillo 86×14
	P(base, "HallFloor", Vector3.new(86, 0.6, 14), CFrame.new(O + Vector3.new(0, -0.3, 0)), C.Hall)
	P(base, "HallCeiling", Vector3.new(86, 0.6, 14), CFrame.new(O + Vector3.new(0, H + 0.3, 0)), C.Ceil)
	P(base, "HallWallW", Vector3.new(1, H, 14), CFrame.new(O + Vector3.new(-43, H / 2, 0)), C.Wall)
	for _, z in { -1, 1 } do
		-- Tramos de pared del pasillo que no tienen cuarto detrás
		P(base, "HallWallA", Vector3.new(10, H, 1), CFrame.new(O + Vector3.new(-38, H / 2, z * 7)), C.Wall)
		P(base, "HallWallB", Vector3.new(9, H, 1), CFrame.new(O + Vector3.new(-2.5, H / 2, z * 7)), C.Wall)
		P(base, "HallWallC", Vector3.new(15, H, 1), CFrame.new(O + Vector3.new(35.5, H / 2, z * 7)), C.Wall)
		P(base, "HallStrip", Vector3.new(80, 0.25, 0.6), CFrame.new(O + Vector3.new(0, H - 0.3, z * 5.5)), Color3.fromHex("7FD6FF"), { Material = Enum.Material.Neon })
	end
	-- Línea guía en el piso hacia la sala de control
	for i = 0, 7 do
		P(base, "FloorArrow", Vector3.new(4, 0.1, 0.8), CFrame.new(O + Vector3.new(-30 + i * 9, 0.05, 0)), Color3.fromHex("FFD43B"), { Material = Enum.Material.Neon, Transparency = 0.3 })
	end
	for x = -36, 36, 18 do
		local lamp = P(base, "HallLamp", Vector3.new(2, 0.2, 2), CFrame.new(O + Vector3.new(x, H - 0.1, 0)), C.White, { Material = Enum.Material.Neon, Transparency = 0.2 })
		local sl = Instance.new("SurfaceLight"); sl.Face = Enum.NormalId.Bottom; sl.Range = 18; sl.Brightness = 1.5; sl.Angle = 120; sl.Parent = lamp
	end
	-- Inicio de los jugadores (extremo oeste)
	P(base, "EarthSpawn", Vector3.new(4, 1, 4), CFrame.new(O + Vector3.new(-38, 0.5, 0)), Color3.fromHex("FFD43B"), { Transparency = 1, CanCollide = false })

	for _, r in ROOMS do buildRoom(base, r) end

	-- Sala de control ~20×34 al este
	local cx = 53
	local ctrl = model(base, "ControlRoom")
	P(ctrl, "Floor", Vector3.new(20, 0.6, 34), CFrame.new(O + Vector3.new(cx, -0.3, 0)), C.Floor)
	P(ctrl, "Ceiling", Vector3.new(20, 0.6, 34), CFrame.new(O + Vector3.new(cx, H + 0.3, 0)), C.Ceil)
	P(ctrl, "WallN", Vector3.new(20, H, 1), CFrame.new(O + Vector3.new(cx, H / 2, -17)), C.Wall)
	P(ctrl, "WallS", Vector3.new(20, H, 1), CFrame.new(O + Vector3.new(cx, H / 2, 17)), C.Wall)
	P(ctrl, "WallWN", Vector3.new(1, H, 10), CFrame.new(O + Vector3.new(43, H / 2, -12)), C.Wall)
	P(ctrl, "WallWS", Vector3.new(1, H, 10), CFrame.new(O + Vector3.new(43, H / 2, 12)), C.Wall)
	-- Ventana grande al este (se ve la nave elegida)
	P(ctrl, "WindowFrameB", Vector3.new(1, 3, 34), CFrame.new(O + Vector3.new(63, 1.5, 0)), C.Wall)
	P(ctrl, "WindowFrameT", Vector3.new(1, 2, 34), CFrame.new(O + Vector3.new(63, H - 1, 0)), C.Wall)
	P(ctrl, "Window", Vector3.new(0.4, H - 5, 34), CFrame.new(O + Vector3.new(63, 3 + (H - 5) / 2, 0)), Color3.fromHex("BFE6FF"), { Material = Enum.Material.Glass, Transparency = 0.6 })
	local lamp = P(ctrl, "Lamp", Vector3.new(4, 0.2, 4), CFrame.new(O + Vector3.new(cx, H - 0.1, 0)), C.White, { Material = Enum.Material.Neon, Transparency = 0.2 })
	local sl = Instance.new("SurfaceLight"); sl.Face = Enum.NormalId.Bottom; sl.Range = 20; sl.Brightness = 1.6; sl.Angle = 120; sl.Parent = lamp
	-- Pantalla grande en la pared norte (la llena el script Tables)
	local screen = P(ctrl, "BigScreen", Vector3.new(16, 9, 0.4), CFrame.new(O + Vector3.new(cx, 6.5, -16.3)), Color3.fromHex("0C0628"), { Material = Enum.Material.Neon })
	screen:SetAttribute("Face", "Front")
	-- Consola de lanzamiento (solo el Captain)
	local console = P(ctrl, "LaunchConsole", Vector3.new(4, 3, 2.5), CFrame.new(O + Vector3.new(cx, 1.5, 4)), C.Red)
	P(ctrl, "ConsoleButton", Vector3.new(1.4, 0.4, 1.4), CFrame.new(O + Vector3.new(cx, 3.2, 4)), Color3.fromHex("FFD43B"), { Material = Enum.Material.Neon })
	console:SetAttribute("Console", true)

	-- Plataforma de lanzamiento afuera de la ventana
	local pad = model(base, "LaunchPad")
	P(pad, "Ground", Vector3.new(80, 1, 80), CFrame.new(O + Vector3.new(105, -0.5, 0)), Color3.fromHex("9AA0B8"), { Material = Enum.Material.Concrete })
	local plate = P(pad, "Plate", Vector3.new(24, 1, 24), CFrame.new(O + Vector3.new(95, 0.5, 0)), Color3.fromHex("5A5F7A"), { Material = Enum.Material.Metal })
	for i = 0, 7 do
		local a = math.rad(i * 45)
		P(pad, "Stripe", Vector3.new(4, 0.1, 1), CFrame.new(O + Vector3.new(95 + math.cos(a) * 10, 1.05, math.sin(a) * 10)) * CFrame.Angles(0, -a, 0), (i % 2 == 0) and Color3.fromHex("FFD43B") or Color3.fromHex("1A1240"))
	end
	P(pad, "ShipAnchor", Vector3.new(1, 1, 1), CFrame.new(plate.Position + Vector3.new(0, 0.5, 0)), C.White, { Transparency = 1, CanCollide = false })
	return base
end

-- Plantillas de maquetas para la ventana y para el script Tables (en ServerStorage.SO_Maquetas)
local function buildMaquetas()
	local ServerStorage = game:GetService("ServerStorage")
	if ServerStorage:FindFirstChild("SO_Maquetas") then return end
	local f = Instance.new("Folder")
	f.Name = "SO_Maquetas"
	for id, fn in Maq do
		local m = model(f, id)
		fn(m)
	end
	f.Parent = ServerStorage
end

---------------------------------------------------------------------
-- Decoración de los cuartos (Leticia: "se ven muy vacíos"). Cosas del rol en el piso y 2 pósters con datos
-- reales en las paredes laterales. Usa modelos de Ramón si están; si no, piezas simples. Se arma una sola vez.
---------------------------------------------------------------------
local function decorateRooms(base: Model)
	local ServerStorage = game:GetService("ServerStorage")
	local RAMON = ServerStorage:FindFirstChild("SO_RamonModels")
	local TPL = ServerStorage:FindFirstChild("SO_Templates")
	local POSTERS = Config.Decor and Config.Decor.Posters or {}
	-- Copia un modelo de Ramón (o plantilla) con un alto dado, apoyado en el piso
	local function prop(parent: Instance, src: Instance?, height: number, pos: Vector3, yaw: number?)
		if not src or not src:IsA("Model") then return nil end
		local m = src:Clone() :: Model
		local _, sz = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * height / math.max(sz.Y, 0.01))
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
		end
		local cf, sz2 = m:GetBoundingBox()
		local offset = m:GetPivot().Position - cf.Position
		m:PivotTo(CFrame.new(pos + Vector3.new(0, sz2.Y / 2, 0) + offset) * CFrame.Angles(0, yaw or 0, 0))
		m.Parent = parent
		return m
	end
	local function cylFlat(parent, name, len, d, pos: Vector3, color, axisZ: boolean?)
		local p = P(parent, name, Vector3.new(len, d, d), CFrame.new(pos) * (axisZ and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()), color)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	for _, r in ROOMS do
		local room = base:FindFirstChild("Room_" .. r.role)
		if room and not room:FindFirstChild("SO_Decor") then
			local info = Config.Roles[r.role]
			local d = model(room, "SO_Decor")
			local s = r.side
			local cx = O.X + r.x
			local fz = O.Z + s * 11 -- cerca de la puerta
			local mz = O.Z + s * 16 -- mitad del cuarto
			local y0 = O.Y
			-- Pósters en las dos paredes laterales, mirando hacia adentro
			local list = POSTERS[r.role] or {}
			for k, side in { -1, 1 } do
				local text = list[k]
				if text then
					local pos = Vector3.new(cx + side * 12.35, y0 + 6.5, mz)
					local poster = P(d, "Poster", Vector3.new(0.2, 4.6, 7), CFrame.lookAt(pos, pos + Vector3.new(-side, 0, 0)), info.Color, { Material = Enum.Material.Neon })
					local inner = P(d, "PosterBoard", Vector3.new(0.2, 4.2, 6.6), CFrame.lookAt(pos - Vector3.new(side * 0.12, 0, 0), pos + Vector3.new(-side, 0, 0)), C.Ceil)
					textGui(inner, Enum.NormalId.Front, {
						{ text[1], 0.24, info.Color },
						{ text[2], 0.3, Color3.new(1, 1, 1) },
						{ text[3], 0.3, Color3.fromHex("C9BEF5") },
					})
					poster.CanCollide = false
				end
			end
			-- Cosas del rol en el piso, en las esquinas de adelante
			local L = Vector3.new(cx - 8.5, y0, fz)
			local R = Vector3.new(cx + 8.5, y0, fz)
			if r.role == "cap" then
				prop(d, TPL and TPL:FindFirstChild("cargoship_parts"), 5, L, 0.6) -- piezas de nave
				cylFlat(d, "FuelTank", 4, 1.6, R + Vector3.new(0, 0.8, 0), C.Orange, true)
				cylFlat(d, "FuelTank", 4, 1.6, R + Vector3.new(1.7, 0.8, 0), C.Orange, true)
				cylFlat(d, "FuelTank", 4, 1.6, R + Vector3.new(0.85, 2.2, 0), C.Orange, true)
				P(d, "CargoCrate", Vector3.new(2.4, 2, 2.4), CFrame.new(R + Vector3.new(-2.5, 1, s * 3)) * CFrame.Angles(0, 0.3, 0), C.Silver, { Material = Enum.Material.DiamondPlate })
			elseif r.role == "eng" then
				prop(d, RAMON and RAMON:FindFirstChild("panel_solar"), 5, L, 0.4) -- panel de repuesto
				local spool = cylFlat(d, "CableSpool", 1.4, 2.4, R + Vector3.new(0, 1.2, 0), C.Orange)
				cylFlat(d, "SpoolCore", 1.5, 1, spool.Position, C.PedBase)
				P(d, "Toolbox", Vector3.new(2, 1, 1), CFrame.new(R + Vector3.new(-2.6, 0.5, s * 2)), Color3.fromHex("E8341C"))
				P(d, "Battery", Vector3.new(1.6, 1.4, 1.2), CFrame.new(R + Vector3.new(2.2, 0.7, s * 2.5)), info.Color)
				P(d, "Battery", Vector3.new(1.6, 1.4, 1.2), CFrame.new(R + Vector3.new(2.2, 2.1, s * 2.5)), info.Color)
			elseif r.role == "life" then
				prop(d, RAMON and RAMON:FindFirstChild("generador_oxigeno_elektron"), 5, L, 0.5)
				for k = 0, 2 do
					local t = cylFlat(d, "O2Tank", 3.4, 1.2, R + Vector3.new(k * 1.4 - 1.4, 1.7, 0), C.White)
					t.CFrame = CFrame.new(t.Position) * CFrame.Angles(0, 0, math.rad(90))
					P(d, "TankStripe", Vector3.new(1.25, 0.3, 1.25), CFrame.new(t.Position + Vector3.new(0, 0.6, 0)), info.Color)
				end
				cylFlat(d, "Pipe", 8, 0.5, Vector3.new(cx + s * 0 + 12, y0 + 9, mz), C.Silver, true)
				cylFlat(d, "Pipe", 8, 0.5, Vector3.new(cx - 12, y0 + 9, mz), C.Silver, true)
			elseif r.role == "bot" then
				P(d, "Table", Vector3.new(5, 0.3, 2.4), CFrame.new(L + Vector3.new(0, 2.6, 0)), C.Silver)
				P(d, "TableLeg", Vector3.new(0.4, 2.5, 0.4), CFrame.new(L + Vector3.new(-2, 1.25, 0)), C.Metal)
				P(d, "TableLeg", Vector3.new(0.4, 2.5, 0.4), CFrame.new(L + Vector3.new(2, 1.25, 0)), C.Metal)
				prop(d, RAMON and RAMON:FindFirstChild("NASA_Veggie_Chamber_Growing"), 2.2, L + Vector3.new(-1, 2.75, 0))
				local foods = { "01_Space_galletas (1)", "02_Space_Pan (1)", "04_Colorful_Space_Candies (1)" }
				for k, n in foods do
					prop(d, RAMON and RAMON:FindFirstChild(n), 0.6, L + Vector3.new(0.8 + (k - 1) * 0.6, 2.75, 0.3))
				end
				for k = 0, 2 do
					local pot = R + Vector3.new(k * 1.6 - 1.6, 0, 0)
					cylY(d, "Pot", 1, 1.2, pot + Vector3.new(0, 0.5, 0), Color3.fromHex("A0643C"))
					local leaf = P(d, "Plant", Vector3.new(1.4, 1.4, 1.4), CFrame.new(pot + Vector3.new(0, 1.6, 0)), info.Color, { Material = Enum.Material.Grass })
					leaf.Shape = Enum.PartType.Ball
				end
			end
		end
	end
end

if not workspace:FindFirstChild("EarthBase") then
	buildSite()
end
buildMaquetas()
if workspace:FindFirstChild("EarthBase") then
	decorateRooms(workspace.EarthBase)
end
