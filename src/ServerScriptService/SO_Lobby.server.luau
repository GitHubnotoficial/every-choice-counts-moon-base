-- SO_Lobby (Script) -> ServerScriptService.SO_Lobby
-- Dueño: Isaac + Claude (pedido de Isaac 15-nov: "que no aparezcamos en un pasillo, sino en una habitación grande").
-- Sala de llegada del tamaño de la sala de control (20 × 34), pegada al extremo oeste del pasillo de la Fase 0.
-- Busca dónde termina el pasillo (EarthBase.HallWallW), arma la sala del otro lado, quita esa pared para abrir el paso
-- y mueve EarthSpawn y el SpawnLocation al centro. Si la sala ya existe (construida en Edit), no hace nada.
-- Textos en Config.Lobby. Se puede ejecutar también desde Edit con la misma función (devuelve build).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local H = 12
local W, D = 20, 34 -- largo (x) y ancho (z) de la sala
local C = {
	Wall = Color3.fromHex("E8EAF2"), Floor = Color3.fromHex("2B2F48"), Ceil = Color3.fromHex("141A33"),
	White = Color3.fromHex("F4F2FA"), Sky = Color3.fromHex("7FD6FF"), Yellow = Color3.fromHex("FFD43B"),
	Dark = Color3.fromHex("1B1F38"), Moon = Color3.fromHex("C9C6D8"), Crater = Color3.fromHex("9C98B2"),
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

local function sign(part: BasePart, face: Enum.NormalId, lines: { { string } })
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.LightInfluence = 0
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.Parent = part
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	f.Parent = g
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0.02, 0)
	list.Parent = f
	for _, l in lines do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(0.92, 0, l[2], 0)
		t.Text = l[1]
		t.TextColor3 = l[3]
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Parent = f
	end
end

local function build(): Model?
	local base = workspace:FindFirstChild("EarthBase")
	if not base or base:FindFirstChild("SO_Lobby") then return nil end
	local wallW = base:FindFirstChild("HallWallW") :: BasePart?
	-- Extremo oeste del pasillo (si la pared ya no está, el borde del piso del pasillo)
	local hallEnd = wallW and wallW.Position.X or -67
	local y0 = 0
	local L = Config.Lobby
	local cx = hallEnd - W / 2
	local room = Instance.new("Model")
	room.Name = "SO_Lobby"

	P(room, "Floor", Vector3.new(W, 0.6, D), CFrame.new(cx, y0 - 0.3, 0), C.Floor)
	P(room, "Ceiling", Vector3.new(W, 0.6, D), CFrame.new(cx, y0 + H + 0.3, 0), C.Ceil)
	P(room, "WallW", Vector3.new(1, H, D), CFrame.new(hallEnd - W, y0 + H / 2, 0), C.Wall)
	P(room, "WallN", Vector3.new(W + 1, H, 1), CFrame.new(cx, y0 + H / 2, -D / 2), C.Wall)
	P(room, "WallS", Vector3.new(W + 1, H, 1), CFrame.new(cx, y0 + H / 2, D / 2), C.Wall)
	-- pared del lado del pasillo, con la abertura de 14 del pasillo
	local side = (D - 14) / 2
	P(room, "WallEN", Vector3.new(1, H, side), CFrame.new(hallEnd, y0 + H / 2, -(7 + side / 2)), C.Wall)
	P(room, "WallES", Vector3.new(1, H, side), CFrame.new(hallEnd, y0 + H / 2, 7 + side / 2), C.Wall)
	-- tiras de luz y lámparas como en el resto del edificio
	for _, z in { -1, 1 } do
		P(room, "Strip", Vector3.new(W - 2, 0.25, 0.6), CFrame.new(cx, y0 + H - 0.3, z * (D / 2 - 2)), C.Sky, { Material = Enum.Material.Neon })
	end
	for _, z in { -8, 8 } do
		local lamp = P(room, "Lamp", Vector3.new(4, 0.2, 4), CFrame.new(cx, y0 + H - 0.1, z), C.White, { Material = Enum.Material.Neon, Transparency = 0.2 })
		local sl = Instance.new("SurfaceLight"); sl.Face = Enum.NormalId.Bottom; sl.Range = 20; sl.Brightness = 1.6; sl.Angle = 120; sl.Parent = lamp
	end
	-- Cartel grande de bienvenida en la pared oeste (mirando a la sala)
	local board = P(room, "WelcomeSign", Vector3.new(0.3, 6.5, 18), CFrame.new(hallEnd - W + 0.7, y0 + 7.2, 0), C.Dark)
	sign(board, Enum.NormalId.Right, {
		{ L.Eyebrow, 0.1, Color3.fromHex("C9BEF5") },
		{ L.Title, 0.28, C.Yellow },
		{ L.Line1, 0.14, C.White },
		{ L.Line2, 0.14, C.Sky },
	})
	-- Luna en un pedestal (centro de la sala, hacia el oeste)
	P(room, "MoonPedestal", Vector3.new(3, 2, 3), CFrame.new(cx - 4.5, y0 + 1, 0), C.Dark)
	local moon = P(room, "Moon", Vector3.new(4, 4, 4), CFrame.new(cx - 4.5, y0 + 4.1, 0), C.Moon, { Material = Enum.Material.Slate, Shape = Enum.PartType.Ball })
	local rng = Random.new(4)
	for _ = 1, 9 do
		local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.6, 0.9), rng:NextNumber(-1, 1)).Unit
		local d = rng:NextNumber(0.5, 1.1)
		P(room, "MoonCrater", Vector3.new(0.12, d, d), CFrame.lookAt(moon.Position + v * 1.97, moon.Position + v * 3) * CFrame.Angles(0, math.rad(90), 0),
			C.Crater, { Material = Enum.Material.Slate, Shape = Enum.PartType.Cylinder, CanCollide = false })
	end
	-- 4 círculos de color en el piso, uno por rol, con su nombre
	for i, r in Config.RoleOrder do
		local info = Config.Roles[r]
		local z = (i - 2.5) * 6
		P(room, "RolePad_" .. r, Vector3.new(0.12, 4, 4), CFrame.new(cx + 3, y0 + 0.06, z) * CFrame.Angles(0, 0, math.rad(90)),
			info.Color, { Material = Enum.Material.Neon, Transparency = 0.45, Shape = Enum.PartType.Cylinder, CanCollide = false })
		local tag = P(room, "RoleTag_" .. r, Vector3.new(3.6, 0.05, 1), CFrame.new(cx + 6.5, y0 + 0.04, z), C.Dark, { CanCollide = false })
		sign(tag, Enum.NormalId.Top, { { info.Name, 0.8, info.Color } })
	end
	-- Flechas en el piso hacia el pasillo
	for i = 0, 2 do
		P(room, "FloorArrow", Vector3.new(2.6, 0.1, 0.8), CFrame.new(hallEnd - 6 + i * 2.2, y0 + 0.05, 0), C.Yellow, { Material = Enum.Material.Neon, Transparency = 0.3 })
	end
	-- Bancos a los lados
	for _, z in { -1, 1 } do
		P(room, "Bench", Vector3.new(6, 1.2, 1.6), CFrame.new(cx - 2, y0 + 0.6, z * (D / 2 - 1.8)), Color3.fromHex("3A3F66"))
	end
	room.Parent = base

	-- Abrir el paso: quitar la pared del extremo del pasillo
	if wallW then wallW:Destroy() end
	-- Aparecer en el centro de la sala, mirando hacia el pasillo
	local spawnPos = Vector3.new(cx + 3, y0, 0)
	local es = base:FindFirstChild("EarthSpawn") :: BasePart?
	if es then es.CFrame = CFrame.new(spawnPos + Vector3.new(0, 0.5, 0)) end
	local sp = workspace:FindFirstChildOfClass("SpawnLocation")
	if sp then sp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 0.1, 0)) end
	return room
end

build()
return nil
