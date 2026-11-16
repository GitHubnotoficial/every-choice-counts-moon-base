-- BuildMoonSite (Script) -> ServerScriptService.BuildMoonSite
-- Dueño: Isaac + Claude (base). Leticia puede agregar detalles.
-- Construye Workspace.MoonSite en Config.Zones.Moon (3000, 0, 0) y las plantillas de objetos en ServerStorage.SO_Templates.
-- Estilo parecido a la demo "99 Dias": suelo lavanda claro, plataforma con franjas amarillas, nave con patas rosadas,
-- cúpula de invernadero celeste, cápsula blanca con aro rojo, esferas de soporte vital y la Tierra en el cielo.
-- Si MoonSite ya existe (se construyó en Edit), no hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local ORIGIN = Config.Zones.Moon

-- Paleta (morado, lavanda, rosa, celeste, amarillo + rojo/azul/blanco)
local C = {
	Ground = Color3.fromHex("C9C6DC"),
	GroundDark = Color3.fromHex("A9A5C2"),
	Rock = Color3.fromHex("8E89A8"),
	Pad = Color3.fromHex("B9BEDB"),
	Yellow = Color3.fromHex("FFD43B"),
	Navy = Color3.fromHex("1A1240"),
	White = Color3.fromHex("F4F2FA"),
	Lavender = Color3.fromHex("D9D2F5"),
	Pink = Color3.fromHex("FF4F9A"),
	Orange = Color3.fromHex("FF9A3C"),
	Red = Color3.fromHex("FC3D21"),
	Teal = Color3.fromHex("36C9C6"),
	Sky = Color3.fromHex("7FD6FF"),
	Blue = Color3.fromHex("2F7BFF"),
	Green = Color3.fromHex("3DD68C"),
	Purple = Color3.fromHex("7B4DFF"),
	Metal = Color3.fromHex("8F8AA8"),
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

-- Cilindro vertical (el eje del cilindro de Roblox es X; lo giramos para que quede de pie)
local function cylY(parent, name, height, diameter, pos: Vector3, color, props)
	local p = P(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
-- Cilindro acostado a lo largo de X
local function cylX(parent, name, length, diameter, pos: Vector3, color, props)
	local p = P(parent, name, Vector3.new(length, diameter, diameter), CFrame.new(pos), color, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(parent, name, d, pos: Vector3, color, props)
	local p = P(parent, name, Vector3.new(d, d, d), CFrame.new(pos), color, props)
	p.Shape = Enum.PartType.Ball
	return p
end
local function zone(parent, name, size: Vector3, pos: Vector3)
	return P(parent, name, size, CFrame.new(pos), Color3.new(1, 1, 1), {
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false,
	})
end
-- Fija el punto de giro del modelo en (0,0,0) sin rotación (los modelos se arman en el origen)
local function finish(m: Model, primary: BasePart)
	m.PrimaryPart = primary
	primary.PivotOffset = primary.CFrame:Inverse()
end
local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- Plantillas de objetos (centradas en 0,0,0 sobre el suelo). Se clonan con :Clone() y :PivotTo().
---------------------------------------------------------------------
local Templates = {}

-- Hábitat: cápsula blanca acostada con aro rojo y ojo de buey celeste (como la demo)
function Templates.habitat(parent: Instance): Model
	local m = model(parent, "habitat")
	local body = cylX(m, "Body", 16, 9, Vector3.new(0, 5, 0), C.White)
	ball(m, "CapL", 9, Vector3.new(-8, 5, 0), C.White)
	cylX(m, "RingRed", 1.4, 9.6, Vector3.new(8.2, 5, 0), C.Red)
	cylX(m, "Window", 0.6, 5.5, Vector3.new(8.9, 5, 0), C.Teal, { Material = Enum.Material.Glass, Transparency = 0.15 })
	cylX(m, "StripeA", 0.6, 9.3, Vector3.new(-2, 5, 0), C.Teal)
	cylX(m, "StripeB", 0.6, 9.3, Vector3.new(3, 5, 0), C.Red)
	P(m, "Base", Vector3.new(14, 1, 7), CFrame.new(0, 0.5, 0), C.Metal)
	cylY(m, "Antenna", 3, 0.3, Vector3.new(2, 11, 0), C.Metal)
	ball(m, "AntennaTip", 0.8, Vector3.new(2, 12.6, 0), C.Red, { Material = Enum.Material.Neon })
	finish(m, body)
	return m
end

-- Invernadero: cúpula celeste translúcida con base blanca (2 bandejas dentro)
function Templates.greenhouse(parent: Instance): Model
	local m = model(parent, "greenhouse")
	local base = cylY(m, "Base", 1.4, 13, Vector3.new(0, 0.7, 0), C.White)
	cylY(m, "Ring", 0.6, 13.6, Vector3.new(0, 1.6, 0), C.Teal)
	cylY(m, "Wall", 4, 12, Vector3.new(0, 3.4, 0), C.Sky, { Material = Enum.Material.Glass, Transparency = 0.35 })
	ball(m, "Dome", 12, Vector3.new(0, 5.4, 0), C.Sky, { Material = Enum.Material.Glass, Transparency = 0.35 })
	ball(m, "Top", 1.6, Vector3.new(0, 11.4, 0), C.White)
	for i = -1, 1, 2 do
		P(m, "Tray", Vector3.new(4, 0.8, 2), CFrame.new(i * 2.6, 2.2, 0), C.Green)
	end
	finish(m, base)
	return m
end

-- Soporte vital: esferas blancas con aros azules sobre base morada (como la demo)
function Templates.lifesupport(parent: Instance): Model
	local m = model(parent, "lifesupport")
	local base = P(m, "Base", Vector3.new(10, 1, 8), CFrame.new(0, 0.5, 0), C.Purple)
	ball(m, "TankBig", 6, Vector3.new(0, 5, 0), C.White)
	cylY(m, "RingBig", 0.8, 6.4, Vector3.new(0, 5, 0), C.Blue)
	ball(m, "TankSmall", 3.4, Vector3.new(3.4, 2.8, 1.5), C.White)
	cylY(m, "RingSmall", 0.5, 3.7, Vector3.new(3.4, 2.8, 1.5), C.Orange)
	cylY(m, "Pipe", 3, 0.6, Vector3.new(-3, 2.5, -2), C.Metal)
	cylY(m, "Chimney", 2, 1, Vector3.new(0, 8.6, 0), C.Metal)
	finish(m, base)
	return m
end

-- Paneles solares: 2 paneles azules inclinados sobre mástiles
function Templates.panels(parent: Instance): Model
	local m = model(parent, "panels")
	local root
	for i = -1, 1, 2 do
		local mast = cylY(m, "Mast", 5, 0.5, Vector3.new(i * 4, 2.5, 0), C.Metal)
		root = root or mast
		P(m, "Panel", Vector3.new(6, 0.3, 4), CFrame.new(i * 4, 5.2, 0) * CFrame.Angles(math.rad(-30), 0, 0), C.Blue, { Material = Enum.Material.Glass, Transparency = 0.05 })
	end
	finish(m, root)
	return m
end

-- Reactor: cilindro gris con aletas (radiadores)
function Templates.reactor(parent: Instance): Model
	local m = model(parent, "reactor")
	local core = cylY(m, "Core", 7, 4, Vector3.new(0, 3.5, 0), C.Metal, { Material = Enum.Material.Metal })
	cylY(m, "Band", 0.6, 4.4, Vector3.new(0, 5.6, 0), C.Yellow)
	for i = 0, 3 do
		local a = math.rad(i * 90)
		P(m, "Fin", Vector3.new(0.3, 5, 3), CFrame.new(math.cos(a) * 3.2, 3.5, math.sin(a) * 3.2) * CFrame.Angles(0, -a, 0), C.Lavender)
	end
	finish(m, core)
	return m
end

-- Baliza: poste con luz (Light se pinta rojo → verde)
function Templates.beacon(parent: Instance): Model
	local m = model(parent, "beacon")
	local pole = cylY(m, "Pole", 4, 0.5, Vector3.new(0, 2, 0), C.Metal)
	ball(m, "Light", 1.2, Vector3.new(0, 4.4, 0), C.Red, { Material = Enum.Material.Neon })
	finish(m, pole)
	return m
end

-- Nave (la de la misión y la de carga/rescate): cuerpo lavanda, aro naranja y patas rosadas
function Templates.lander(parent: Instance, scale: number?): Model
	local s = scale or 1
	local m = model(parent, "lander")
	local body = cylY(m, "Body", 10 * s, 11 * s, Vector3.new(0, 10 * s, 0), C.Lavender)
	ball(m, "Nose", 11 * s, Vector3.new(0, 15 * s, 0), C.Lavender)
	cylY(m, "RingOrange", 1.2 * s, 11.6 * s, Vector3.new(0, 5.6 * s, 0), C.Orange)
	cylX(m, "Window", 0.6 * s, 3 * s, Vector3.new(5.6 * s, 12 * s, 0), C.Teal, { Material = Enum.Material.Glass })
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local foot = Vector3.new(math.cos(a) * 9 * s, 1 * s, math.sin(a) * 9 * s)
		local hip = Vector3.new(math.cos(a) * 4.5 * s, 6 * s, math.sin(a) * 4.5 * s)
		local mid = (foot + hip) / 2
		local len = (hip - foot).Magnitude
		P(m, "Leg", Vector3.new(1.2 * s, len, 1.2 * s), CFrame.lookAt(mid, hip) * CFrame.Angles(math.rad(90), 0, 0), C.Pink)
		ball(m, "Foot", 2.2 * s, foot, C.Pink)
	end
	finish(m, body)
	return m
end

---------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------
local function buildSite(): Model
	local site = model(workspace, "MoonSite")
	local o = ORIGIN

	-- Suelo y lomas
	P(site, "Ground", Vector3.new(500, 4, 500), CFrame.new(o + Vector3.new(0, -2, 0)), C.Ground, { Material = Enum.Material.Sand })
	local hills = model(site, "Hills")
	local rng = Random.new(7)
	for _, h in {
		{ Vector3.new(-150, 0, -120), 90, 28 }, { Vector3.new(160, 0, -150), 110, 34 },
		{ Vector3.new(-170, 0, 140), 80, 22 }, { Vector3.new(190, 0, 170), 70, 20 },
	} do
		local hill = ball(hills, "Hill", h[2], o + h[1] + Vector3.new(0, h[3] - h[2] / 2, 0), C.GroundDark, { Material = Enum.Material.Slate })
		hill.CanCollide = true
	end
	local rocks = model(site, "Rocks")
	for _ = 1, 55 do
		local x, z = rng:NextNumber(-220, 220), rng:NextNumber(-220, 220)
		if math.abs(x) > 40 or math.abs(z) > 40 then
			local s = rng:NextNumber(1.5, 6)
			local r = ball(rocks, "Rock", s, o + Vector3.new(x, s * 0.25, z), C.Rock, { Material = Enum.Material.Slate })
			r.Size = Vector3.new(s * 1.3, s * 0.7, s)
		end
	end

	-- Plataforma de la base con franjas amarillas y azul oscuro (como la demo)
	P(site, "Pad", Vector3.new(70, 0.6, 70), CFrame.new(o + Vector3.new(0, 0.3, 0)), C.Pad, { Material = Enum.Material.Concrete })
	local stripes = model(site, "PadStripes")
	for side = 0, 3 do
		for i = -7, 7 do
			local color = (i % 2 == 0) and C.Yellow or C.Navy
			local along = i * 4.6
			local pos = (side == 0 and Vector3.new(along, 0.7, 35)) or (side == 1 and Vector3.new(along, 0.7, -35))
				or (side == 2 and Vector3.new(35, 0.7, along)) or Vector3.new(-35, 0.7, along)
			local size = (side < 2) and Vector3.new(4.6, 0.3, 1.6) or Vector3.new(1.6, 0.3, 4.6)
			P(stripes, "Stripe", size, CFrame.new(o + pos), color)
		end
	end

	-- Nave de la misión con rampa y zonas
	local lander = Templates.lander(site)
	lander.Name = "Lander"
	lander:PivotTo(CFrame.new(o + Vector3.new(0, 0.6, 0)))
	local ramp = P(lander, "Ramp", Vector3.new(5, 0.6, 11), CFrame.new(o + Vector3.new(0, 2.4, 10)) * CFrame.Angles(math.rad(-18), 0, 0), C.White)
	ramp.CanCollide = true
	zone(site, "LanderZone", Vector3.new(14, 18, 14), o + Vector3.new(0, 9, 0))
	zone(site, "LanderSpawn", Vector3.new(2, 1, 2), o + Vector3.new(0, 3, 22))

	-- Estación de recarga junto a la rampa (el prompt lo pone Bars)
	local refill = cylY(site, "RefillStation", 3, 2, o + Vector3.new(6, 2.1, 17), C.Sky, { Material = Enum.Material.Neon })
	refill.CanCollide = true

	-- Pantalla junto a la rampa (la llena Placement)
	local screen = P(site, "RampScreen", Vector3.new(8, 5, 0.5), CFrame.new(o + Vector3.new(-8, 4, 18)), C.Navy)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.Parent = screen

	-- Cráter de hielo (punto ice_edge de Life Support)
	local crater = o + Vector3.new(-90, 0, 80)
	cylY(site, "IceCrater", 1, 54, crater + Vector3.new(0, -0.1, 0), Color3.fromHex("6E6A8C"), { Material = Enum.Material.Slate })
	cylY(site, "CraterRim", 2, 58, crater + Vector3.new(0, -0.6, 0), C.GroundDark, { Material = Enum.Material.Slate })
	cylY(site, "Ice", 1, 16, crater + Vector3.new(0, 0.5, 0), Color3.fromHex("CFEFFF"), { Material = Enum.Material.Ice })

	-- Pared de roca (rock_wall del Engineer) y cresta soleada (sunny_ridge)
	P(site, "RockWall", Vector3.new(30, 14, 5), CFrame.new(o + Vector3.new(-50, 7, -42)), C.Rock, { Material = Enum.Material.Slate })
	local ridge = ball(site, "SunnyRidge", 50, o + Vector3.new(95, -14, 75), C.GroundDark, { Material = Enum.Material.Slate })
	ridge.Size = Vector3.new(60, 40, 45)
	-- La antena de comunicaciones (una sola, funcional) la construye MoonExtras

	-- Zona de carga (balizas, nave de carga y de rescate)
	P(site, "CargoZone", Vector3.new(26, 0.4, 26), CFrame.new(o + Vector3.new(0, 0.2, -70)), C.Pad, { Material = Enum.Material.Concrete })

	-- Región del hábitat (por defecto en crater_wall; la mueven Placement o DayCycle)
	zone(site, "HabitatZone", Vector3.new(18, 12, 12), o + Vector3.new(-60, 6, 40))

	-- La Tierra en el cielo (solo se ve desde la Luna)
	local earth = ball(site, "Earth", 60, o + Vector3.new(-200, 380, -500), C.Blue, { CanCollide = false, CastShadow = false })
	ball(site, "EarthLand1", 22, earth.Position + Vector3.new(14, 12, 22), C.Green, { CanCollide = false, CastShadow = false })
	ball(site, "EarthLand2", 16, earth.Position + Vector3.new(-18, -10, 24), C.Green, { CanCollide = false, CastShadow = false })

	return site
end

local function buildTemplates()
	if ServerStorage:FindFirstChild("SO_Templates") then return end
	local folder = Instance.new("Folder")
	folder.Name = "SO_Templates"
	for _, name in { "habitat", "greenhouse", "lifesupport", "panels", "reactor", "beacon" } do
		local m = Templates[name](folder)
		m:PivotTo(CFrame.new(0, 0, 0))
	end
	local cargo = Templates.lander(folder, 0.7)
	cargo.Name = "cargoship"
	folder.Parent = ServerStorage
end

if not workspace:FindFirstChild("MoonSite") then
	buildSite()
end
buildTemplates()
