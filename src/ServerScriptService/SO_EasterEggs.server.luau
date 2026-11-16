-- SO_EasterEggs (Script) -> ServerScriptService.SO_EasterEggs
-- Dueño: Isaac + Claude. Easter eggs del Apolo en el mapa lunar (pedido de Isaac, 15-nov).
-- Sin cartel, sin aviso y sin texto: el ProximityPrompt es invisible (Style = Custom).
-- Quien sabe lo que son se acerca y presiona E, y se recrea el experimento real (lo ven todos):
--   hammer = el astronauta levanta los brazos, el martillo va a su mano derecha y la pluma a la izquierda
--            (como Dave Scott en el Apolo 15, 1971), los suelta y caen JUNTOS. Tiempo de caída real en la
--            Luna para la altura de las manos: t = √(2h/g), g = 1,62 m/s². Sin sonido (no hay aire).
--            Al tocar el suelo saltan granos de polvo en parábola, sin nube (sin aire no hay freno).
--   mirror = reflector como el del Apolo 11 (100 prismas). Con E, SO_EggsClient dibuja en cada jugador
--            un pulso verde que sale de SU Tierra (la del cielo), llega en 1,28 s y vuelve más débil.
-- Sin logos, banderas ni insignias (regla Space Apps).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local E = Config.EasterEggs

local site = workspace:WaitForChild("MoonSite")
local lander = site:WaitForChild("Lander")

local METAL = Color3.fromHex("B4B8C2")
local STEEL = Color3.fromHex("5A5F6B")
local GRIP = Color3.fromHex("2A2C33")
local FEATHER = Color3.fromHex("F1EEE6")
local FEATHER_TIP = Color3.fromHex("CFC7B8")

local laserEvent = Remotes:FindFirstChild("SO_LaserShot") or Instance.new("RemoteEvent")
laserEvent.Name = "SO_LaserShot"
laserEvent.Parent = Remotes

local folder = site:FindFirstChild("SO_EasterEggs") or Instance.new("Folder")
folder.Name = "SO_EasterEggs"
folder:ClearAllChildren()
folder.Parent = site

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new((props and props.Wedge) and "WedgePart" or "Part") :: BasePart
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = true
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props or {} do
		if k ~= "Wedge" then (p :: any)[k] = v end
	end
	p.Parent = parent
	return p
end

-- Altura del suelo en (x, z): rayo hacia abajo que ignora jugadores y los propios easter eggs.
-- "from" = desde cuántos studs arriba empieza (bajo las manos se usa 0.3 para no chocar con la nave)
local function groundAt(pos: Vector3, from: number?): Vector3
	local up = from or 60
	local params = RaycastParams.new()
	local ignore = { folder }
	for _, pl in Players:GetPlayers() do
		if pl.Character then table.insert(ignore, pl.Character) end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(pos + Vector3.new(0, up, 0), Vector3.new(0, -(up + 80), 0), params)
	return hit and hit.Position or pos
end

-- Prompt invisible: sin interfaz, solo funciona la tecla E muy cerca
local function secretPrompt(spot: BasePart, onUse: (Player) -> ())
	local prompt = Instance.new("ProximityPrompt")
	prompt.Style = Enum.ProximityPromptStyle.Custom -- no se dibuja nada
	prompt.ActionText = ""
	prompt.ObjectText = ""
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = E.Distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = spot
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Dead") then return end
		onUse(p)
	end)
end

local o = lander.PrimaryPart.Position

---------------------------------------------------------------------
-- Modelos detallados. Cada uno se arma alrededor de su CFrame "c" (en el suelo) y devuelve sus piezas.
---------------------------------------------------------------------
-- Martillo de geólogo: mango con empuñadura de goma, cabeza con cara plana redonda y punta de cincel
local function buildHammer(parent: Instance, c: CFrame, s: number): { BasePart }
	local out = {}
	local function add(p) table.insert(out, p) end
	-- el mango va a lo largo de X; la cabeza en x = +0.72
	add(part(parent, "Handle", Vector3.new(1.45 * s, 0.1 * s, 0.1 * s), c, METAL,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal }))
	add(part(parent, "Grip", Vector3.new(0.55 * s, 0.14 * s, 0.14 * s), c * CFrame.new(-0.42 * s, 0, 0), GRIP,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Rubber }))
	add(part(parent, "Cap", Vector3.new(0.05 * s, 0.16 * s, 0.16 * s), c * CFrame.new(-0.72 * s, 0, 0), GRIP,
		{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Rubber }))
	local head = c * CFrame.new(0.72 * s, 0, 0)
	add(part(parent, "HeadBody", Vector3.new(0.2 * s, 0.2 * s, 0.34 * s), head, STEEL, { Material = Enum.Material.Metal }))
	-- cara de golpe: cilindro corto apuntando a +Z
	add(part(parent, "Face", Vector3.new(0.1 * s, 0.22 * s, 0.22 * s), head * CFrame.new(0, 0, 0.21 * s) * CFrame.Angles(0, math.rad(90), 0),
		STEEL, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal }))
	-- punta de cincel hacia -Z: cuña que se afina
	add(part(parent, "Pick", Vector3.new(0.2 * s, 0.2 * s, 0.34 * s), head * CFrame.new(0, 0, -0.34 * s) * CFrame.Angles(0, math.rad(180), 0),
		STEEL, { Wedge = true, Material = Enum.Material.Metal }))
	return out
end

-- Pluma de halcón blanca: raquis que se afina y barbas a los dos lados con forma de hoja, algo curvada
local function buildFeather(parent: Instance, c: CFrame, s: number): { BasePart }
	local out = {}
	local L = 1.3 * s -- largo total (a lo largo de X)
	local N = 8
	-- ancho de cada lado de la barba a lo largo de la pluma (0 = base, 1 = punta)
	local function width(t: number): number
		if t < 0.18 then return 0 end -- cálamo desnudo en la base
		return 0.17 * s * math.sin(math.pi * math.min(1, (t - 0.18) / 0.82) ^ 0.8)
	end
	local seg = L / N
	for i = 0, N - 1 do
		local t = (i + 0.5) / N
		local bend = math.rad(-14) * t * t -- curva suave hacia la punta
		local cf = c * CFrame.new(-L / 2 + (i + 0.5) * seg, 0.004 * i, 0) * CFrame.Angles(0, bend, 0)
		local quillW = (0.05 - 0.035 * t) * s
		table.insert(out, part(parent, "Quill", Vector3.new(seg * 1.02, quillW, quillW), cf,
			t < 0.18 and Color3.fromHex("E6DCC8") or FEATHER, { Shape = Enum.PartType.Cylinder }))
		local w = width(t)
		if w > 0.005 then
			local color = t > 0.8 and FEATHER_TIP or FEATHER
			-- barba izquierda (más ancha) y derecha (más angosta), casi planas
			table.insert(out, part(parent, "VaneL", Vector3.new(seg * 1.05, 0.012 * s, w * 1.25), cf * CFrame.new(0, 0, w * 0.62), color))
			table.insert(out, part(parent, "VaneR", Vector3.new(seg * 1.05, 0.012 * s, w * 0.8), cf * CFrame.new(0, 0, -w * 0.4), color))
		end
	end
	return out
end

---------------------------------------------------------------------
-- Brazos del astronauta: el servidor solo marca al jugador con SO_ArmsUp = true/false.
-- SO_EggsClient (en cada cliente) gira los hombros hacia adelante justo antes de la física.
-- (En el avatar nuevo de Roblox los hombros son AnimationConstraint y desde el servidor no obedecen.)
---------------------------------------------------------------------
local function setArms(p: Player, up: boolean)
	p:SetAttribute("SO_ArmsUp", up or nil)
end

-- Granos de regolito que saltan en parábola y vuelven a caer (sin aire: sin nube ni flotación)
local function dust(at: Vector3, count: number)
	local a = part(folder, "SO_Dust", Vector3.new(0.2, 0.2, 0.2), CFrame.new(at), Color3.new(1, 1, 1), { Transparency = 1 })
	local pe = Instance.new("ParticleEmitter")
	pe.Enabled = false
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromHex("BDB8CC"))
	pe.LightEmission = 0
	pe.Size = NumberSequence.new(0.12, 0.06)
	pe.Transparency = NumberSequence.new(0.1, 0.4)
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(2.5, 5)
	pe.SpreadAngle = Vector2.new(60, 60)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.Acceleration = Vector3.new(0, -E.MoonG / E.StudMeters, 0) -- gravedad lunar en studs/s²
	pe.Drag = 0
	pe.Parent = a
	pe:Emit(count)
	task.delay(1.5, function() a:Destroy() end)
end

---------------------------------------------------------------------
-- 1. Martillo y pluma (Apolo 15)
---------------------------------------------------------------------
do
	local H = E.Hammer
	local m = Instance.new("Model")
	m.Name = "Egg_hammer"
	m.Parent = folder
	local g = groundAt(o + H.Offset)
	local s = H.Scale

	-- Tumbados en el suelo, uno al lado del otro
	local yaw = CFrame.Angles(0, math.rad(20), 0)
	local hammerHome = CFrame.new(g + Vector3.new(0, 0.08 * s, 0)) * yaw
	local featherHome = CFrame.new(g + Vector3.new(0, 0.03 * s, 0)) * yaw * CFrame.new(0.1, 0, 1.0 * s) * CFrame.Angles(0, math.rad(-10), 0)
	local hammer = buildHammer(m, hammerHome, s)
	local feather = buildFeather(m, featherHome, s)

	-- Cada grupo se mueve como un bloque: guardo cada pieza respecto a su "centro"
	local function group(list: { BasePart }, center: CFrame)
		local rel = {}
		for _, p in list do rel[p] = center:ToObjectSpace(p.CFrame) end
		return { parts = list, rel = rel, home = center, now = center }
	end
	local gH, gF = group(hammer, hammerHome), group(feather, featherHome)
	local function place(gr, cf: CFrame)
		gr.now = cf
		for p, r in gr.rel do p.CFrame = cf * r end
	end

	local spot = part(m, "Spot", Vector3.new(1, 1, 1), CFrame.new(g + Vector3.new(0, 0.6, 0.5)), Color3.new(1, 1, 1), { Transparency = 1 })

	local busy = false
	local function run(p: Player, root: BasePart)
		-- Quieto mientras hace el experimento
		local wasAnchored = root.Anchored
		root.Anchored = true
		local body = root.CFrame

		-- 1) Levanta los brazos hacia adelante
		setArms(p, true)
		task.wait(H.ArmTime * 0.6)

		-- 2) Martillo a la mano derecha y pluma a la izquierda (horizontales, apuntando hacia adelante)
		local hand = H.Hands
		local hold = CFrame.Angles(0, math.rad(90), 0) -- el largo de cada objeto mirando hacia adelante
		local rightHand = body * CFrame.new(hand.X, hand.Y, hand.Z) * hold
		local leftHand = body * CFrame.new(-hand.X, hand.Y, hand.Z) * hold
		local fromH, fromF = gH.now, gF.now
		local t0 = os.clock()
		while true do
			local k = math.clamp((os.clock() - t0) / H.PickTime, 0, 1)
			local e = k * k * (3 - 2 * k)
			-- arco suave hacia arriba mientras viajan
			local lift = Vector3.new(0, math.sin(e * math.pi) * 0.8, 0)
			place(gH, fromH:Lerp(rightHand, e) + lift)
			place(gF, fromF:Lerp(leftHand, e) + lift)
			if k >= 1 then break end
			RunService.Heartbeat:Wait()
		end
		task.wait(H.HoldTime)

		-- 3) Los suelta: misma aceleración para los dos (sin aire la pluma no frena)
		local groundH = groundAt(rightHand.Position, 0.3)
		local groundF = groundAt(leftHand.Position, 0.3)
		local h = math.max(0.1, rightHand.Position.Y - groundH.Y - 0.08 * s) -- studs que caen
		local fall = math.sqrt(2 * h * E.StudMeters / E.MoonG) -- segundos reales en la Luna
		-- donde quedan: tumbados en el suelo, mirando igual que en la mano
		local restH = CFrame.new(groundH + Vector3.new(0, 0.08 * s, 0)) * (rightHand - rightHand.Position)
		local restF = CFrame.new(groundF + Vector3.new(0, 0.03 * s, 0)) * (leftHand - leftHand.Position)
		local dropH = rightHand.Position.Y - restH.Position.Y
		local dropF = leftHand.Position.Y - restF.Position.Y
		t0 = os.clock()
		while true do
			local k = math.clamp((os.clock() - t0) / fall, 0, 1)
			local d = k * k -- caída libre: recorrido ∝ t²
			place(gH, rightHand - Vector3.new(0, dropH * d, 0))
			place(gF, leftHand - Vector3.new(0, dropF * d, 0))
			if k >= 1 then break end
			RunService.Heartbeat:Wait()
		end
		place(gH, restH)
		place(gF, restF)
		dust(restH.Position, H.DustCount)
		dust(restF.Position, math.floor(H.DustCount / 2))

		-- 4) Baja los brazos y lo suelta
		task.wait(0.5)
		setArms(p, false)
		task.wait(H.ArmTime)
		if root.Parent then root.Anchored = wasAnchored end

		-- 5) Un rato en el suelo y vuelven a su sitio (para el siguiente que sepa)
		task.wait(H.RestTime)
	end

	secretPrompt(spot, function(p)
		if busy then return end
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end
		busy = true
		local ok, err = pcall(run, p, root)
		if not ok then
			warn("[SO_EasterEggs] martillo y pluma:", err)
			-- dejar al jugador como estaba
			setArms(p, false)
			if root.Parent then root.Anchored = false end
		end
		place(gH, gH.home)
		place(gF, gF.home)
		busy = false
	end)
end

---------------------------------------------------------------------
-- 2. Reflector láser (como el del Apolo 11: panel de aluminio con 10 × 10 prismas en huecos redondos)
---------------------------------------------------------------------
do
	local M = E.Mirror
	local m = Instance.new("Model")
	m.Name = "Egg_mirror"
	m.Parent = folder
	local g = groundAt(o + M.Offset)
	local dir = Config.MoonSky.EarthDir

	-- Mira hacia la Tierra del cielo (casi en el horizonte, así que el panel queda casi de pie)
	local flatDir = (dir * Vector3.new(1, 0, 1)).Unit
	local base = CFrame.lookAt(g, g + flatDir)
	-- Bandeja y 4 patas cortas
	part(m, "Pallet", Vector3.new(2.6, 0.12, 1.6), base * CFrame.new(0, 0.25, 0.4), METAL, { Material = Enum.Material.Metal })
	for _, x in { -1.15, 1.15 } do
		for _, z in { -0.25, 1.05 } do
			part(m, "Leg", Vector3.new(0.1, 0.25, 0.1), base * CFrame.new(x, 0.12, z), METAL, { Material = Enum.Material.Metal })
		end
	end
	-- Panel inclinado: su cara frontal (-Z local tras girar) apunta a la Tierra
	local elev = math.asin(dir.Y)
	local panel = base * CFrame.new(0, 1.35, 0) * CFrame.Angles(-(math.rad(90) - elev), 0, 0) -- normal (+Y) hacia la Tierra
	part(m, "Frame", Vector3.new(2.3, 0.16, 2.3), panel, Color3.fromHex("CDD0D8"), { Material = Enum.Material.DiamondPlate })
	-- Brazo de apoyo trasero
	part(m, "Strut", Vector3.new(0.1, 1.3, 0.1), base * CFrame.new(0, 0.85, 0.75) * CFrame.Angles(math.rad(-25), 0, 0), METAL, { Material = Enum.Material.Metal })
	local prisms = {}
	local n = M.Grid
	local step = 2.0 / n
	for i = 0, n - 1 do
		for j = 0, n - 1 do
			local cf = panel * CFrame.new(-1.0 + step * (i + 0.5), 0.085, -1.0 + step * (j + 0.5)) * CFrame.Angles(0, 0, math.rad(90))
			table.insert(prisms, part(m, "Prism", Vector3.new(0.02, step * 0.78, step * 0.78), cf, Color3.fromHex("20283A"),
				{ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Glass, Reflectance = 0.5, Transparency = 0.05 }))
		end
	end
	local target = panel * CFrame.new(0, 0.12, 0)

	local spot = part(m, "Spot", Vector3.new(1, 1, 1), CFrame.new(g + Vector3.new(0, 0.6, 0)), Color3.new(1, 1, 1), { Transparency = 1 })
	local PRISM = Color3.fromHex("20283A")
	local busy = false
	secretPrompt(spot, function()
		if busy then return end
		busy = true
		-- Cada jugador dibuja el pulso desde la Tierra de SU cielo (sigue a su cámara)
		laserEvent:FireAllClients(target.Position, g, M.LightTrip)
		task.wait(M.LightTrip)
		-- Llega: los prismas destellan en onda desde el centro
		for _, p in prisms do
			local d = (p.Position - target.Position).Magnitude
			task.delay(d * 0.12, function()
				p.Material = Enum.Material.Neon
				p.Color = M.Color
				task.delay(0.35, function()
					p.Material = Enum.Material.Glass
					p.Color = PRISM
				end)
			end)
		end
		task.wait(M.LightTrip + 1)
		busy = false
	end)
end
