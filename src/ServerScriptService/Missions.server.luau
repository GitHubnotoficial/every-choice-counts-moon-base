-- Missions (Script) -> ServerScriptService.Missions
-- Dueño: Isaac + Claude (antes era tarea de Larry). Fase 2 completa (PDF Fase 2): una misión por rol según lo que
-- trajo en la Fase 0 y dónde lo puso en la Fase 1, reparaciones y energía. Todo es "mantener E".
-- Escribe: Phase2Intro_<rol>, Mission_<rol>_Done / _Total, MissionComplete_<rol>, Damaged_<rol> (al reparar),
--          EnergyMade / EnergyUsed. Marca las bandejas sembradas con el tag "SO_Tray" y Planted = true.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Energy = require(ReplicatedStorage:WaitForChild("Energy"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local M = Config.Missions
local ROLES = Config.RoleOrder

local site = workspace:WaitForChild("MoonSite")
local folder: Folder? = nil

local function find(list, id)
	for _, x in list do
		if x.Id == id then return x end
	end
	return nil
end

local function ground(): Vector3
	return site.Lander.PrimaryPart.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
end

-- Dónde está lo que colocó cada rol (o su punto elegido, o un lugar por defecto)
local function placedModel(role: string): Model?
	local placed = site:FindFirstChild("Placed")
	return placed and placed:FindFirstChild(role) :: Model?
end
local function posOf(role: string): Vector3
	local m = placedModel(role)
	if m then return m:GetPivot().Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0) end
	local spot = find(Config.Spots[role], GS:GetAttribute("Spot_" .. role) or "")
	return ground() + (spot and spot.Offset or Vector3.new(20, 0, 20))
end

---------------------------------------------------------------------
-- Objetos de prueba (solo Studio, si se saltó la Fase 1): los mismos de DayCycle
---------------------------------------------------------------------
local function ensureTestObjects()
	if site:FindFirstChild("Placed") or not RunService:IsStudio() then return end
	local templates = ServerStorage:FindFirstChild("SO_Templates")
	if not templates then return end
	local placed = Instance.new("Folder")
	placed.Name = "Placed"
	placed.Parent = site
	local pick = {
		cap = "habitat",
		eng = GS:GetAttribute("Choice_eng") == "reactor" and "reactor" or "panels",
		life = templates:FindFirstChild(GS:GetAttribute("Choice_life") or "") and GS:GetAttribute("Choice_life") or "lifesupport",
		bot = GS:GetAttribute("Choice_bot") ~= "packaged" and "greenhouse" or nil,
	}
	for _, role in ROLES do
		local tpl = pick[role] and templates:FindFirstChild(pick[role])
		local spot = find(Config.Spots[role], GS:GetAttribute("Spot_" .. role) or "")
		if tpl and spot then
			local m = tpl:Clone()
			m.Name = role
			m:PivotTo(CFrame.new(ground() + spot.Offset))
			m.Parent = placed
		end
	end
	local hab = placed:FindFirstChild("cap")
	if hab then site.HabitatZone.CFrame = hab:GetPivot() + Vector3.new(0, 5, 0) end
end

---------------------------------------------------------------------
-- Fábrica de puntos "mantener E" (cualquier jugador vivo puede ayudar)
---------------------------------------------------------------------
-- Ajusta un punto a la altura real del suelo (colinas, bordes de cráter); ignora jugadores y objetos de la base
local function snap(pos: Vector3): Vector3
	local params = RaycastParams.new()
	local ignore: { Instance } = { folder :: Instance }
	for _, n in { "Placed", "Lander", "ChosenLander", "HabitatZone", "CargoZone" } do
		local x = site:FindFirstChild(n)
		if x then table.insert(ignore, x) end
	end
	for _, p in Players:GetPlayers() do
		if p.Character then table.insert(ignore, p.Character) end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 40, pos.Z), Vector3.new(0, -80, 0), params)
	return hit and Vector3.new(pos.X, hit.Position.Y + 0.6, pos.Z) or pos
end

local function holdPoint(pos: Vector3, text: string, hold: number, role: string, onDone: (Player) -> ()): BasePart
	pos = snap(pos)
	local part = Instance.new("Part")
	part.Name = "MissionPoint_" .. role
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.3, 4, 4)
	part.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Config.Roles[role].Color
	part.Transparency = 0.2
	part.Parent = folder
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.ObjectText = Config.Roles[role].Name
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.Parent = part
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Dead") or not prompt.Enabled or GS:GetAttribute("Phase") ~= "Phase2" then return end
		prompt.Enabled = false
		part.Color = Config.Colors.Good
		part.Transparency = 0.6
		onDone(p)
	end)
	return part
end

local function around(center: Vector3, n: number, radius: number, startAngle: number?): { Vector3 }
	local out = {}
	for i = 1, n do
		local a = (startAngle or 0) + (i - 1) * (2 * math.pi / n)
		table.insert(out, center + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius))
	end
	return out
end

-- Suma un paso a la misión de un rol y la cierra al completar
local function step(role: string, doneText: string, fact: string)
	local done = (GS:GetAttribute("Mission_" .. role .. "_Done") or 0) + 1
	local total = GS:GetAttribute("Mission_" .. role .. "_Total") or 1
	GS:SetAttribute("Mission_" .. role .. "_Done", done)
	if done >= total and not GS:GetAttribute("MissionComplete_" .. role) then
		GS:SetAttribute("MissionComplete_" .. role, true)
		Remotes.Toast:FireAllClients(doneText, 3)
		Remotes.Fact:FireAllClients(fact)
	end
end

---------------------------------------------------------------------
-- Animaciones realistas de cada tarea (pedido de Isaac 15-nov: "que sea realista más que estético").
-- Cada punto tiene al lado el objeto real (filtro, válvula, taladro, pala...) mirando al jugador,
-- y al terminar de mantener E se ve el trabajo hecho.
---------------------------------------------------------------------
local METAL = Color3.fromHex("C9CCD8")
local DARK = Color3.fromHex("2B2F4A")
local function newPart(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end
-- Cilindro: su eje es la X del CFrame
local function cyl(name: string, length: number, diam: number, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
	local p = newPart(name, Vector3.new(length, diam, diam), cf, color, mat)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local UP = CFrame.Angles(0, 0, math.rad(90)) -- eje del cilindro vertical
local FWD = CFrame.Angles(0, math.rad(90), 0) -- eje del cilindro hacia el jugador
local function tw(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?): Tween
	local x = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad), props)
	x:Play()
	return x
end
-- Gira una pieza alrededor de un punto (bisagra)
local function hinge(p: BasePart, pivot: CFrame, rot: CFrame, t: number): Tween
	return tw(p, t, { CFrame = pivot * rot * pivot:Inverse() * p.CFrame })
end
-- Gira una pieza sobre su eje X varias veces (volante, broca, manivela)
local function spin(p: BasePart, turns: number, t: number)
	task.spawn(function()
		local steps = math.max(1, math.floor(turns * 8))
		for _ = 1, steps do
			tw(p, t / steps, { CFrame = p.CFrame * CFrame.Angles(math.rad(45), 0, 0) }, Enum.EasingStyle.Linear).Completed:Wait()
		end
	end)
end
-- Mueve un modelo entero con tween
local function tweenPivot(m: Model, cf: CFrame, t: number)
	local v = Instance.new("CFrameValue")
	v.Value = m:GetPivot()
	v.Changed:Connect(function(x) m:PivotTo(x) end)
	local x = tw(v, t, { Value = cf })
	x.Completed:Connect(function() v:Destroy() end)
end
local function statusLight(cf: CFrame): BasePart
	local l = newPart("StatusLight", Vector3.new(0.45, 0.45, 0.45), cf, Config.Colors.Gold, Enum.Material.Neon)
	l.Shape = Enum.PartType.Ball
	return l
end
local function lightOk(l: BasePart)
	task.spawn(function()
		for _ = 1, 3 do
			l.Color = Color3.new(1, 1, 1); task.wait(0.15)
			l.Color = Config.Colors.Gold; task.wait(0.15)
		end
		l.Color = Config.Colors.Good
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
-- Base de un objeto: junto al punto, del lado contrario al centro, y de frente al jugador (frente = -Z local)
local function baseAt(pos: Vector3, center: Vector3?): CFrame
	local d = center and (pos - center) * Vector3.new(1, 0, 1) or Vector3.zero
	d = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 0, -1)
	local at = snap(pos + d * 2.8) - Vector3.new(0, 0.5, 0)
	return CFrame.lookAt(at, Vector3.new(pos.X, at.Y, pos.Z))
end

-- Filtro (reciclador): el cartucho viejo sale y cae; entra uno nuevo
local function filterProp(b: CFrame)
	newPart("FilterHousing", Vector3.new(2.4, 3.2, 1.6), b * CFrame.new(0, 1.6, 0), Color3.fromHex("F4F2FA"))
	newPart("FilterLabel", Vector3.new(1.6, 0.3, 0.05), b * CFrame.new(0, 2.6, -0.82), DARK)
	local old = cyl("OldFilter", 1.6, 0.9, b * CFrame.new(-0.4, 1.2, -0.8) * FWD, Color3.fromHex("7A5C3E"), Enum.Material.Fabric)
	cyl("GoodFilter", 1.6, 0.9, b * CFrame.new(0.6, 1.2, -0.5) * FWD, Color3.fromHex("ECE6CF"), Enum.Material.Fabric)
	local light = statusLight(b * CFrame.new(0.8, 2.6, -0.82))
	return function()
		tw(old, 0.8, { CFrame = b * CFrame.new(-0.4, 1.2, -2.2) * FWD })
		task.wait(0.85)
		tw(old, 0.45, { CFrame = b * CFrame.new(-0.4, 0.45, -2.8) * FWD * CFrame.Angles(0, 0.5, 0) }, Enum.EasingStyle.Bounce)
		local new = cyl("NewFilter", 1.6, 0.9, b * CFrame.new(-0.4, 1.2, -2.6) * FWD, Color3.fromHex("FFFFFF"), Enum.Material.Fabric)
		task.wait(0.4)
		tw(new, 0.9, { CFrame = b * CFrame.new(-0.4, 1.2, -0.8) * FWD })
		task.wait(0.9)
		lightOk(light)
		task.delay(3, function()
			tw(old, 1, { Transparency = 1 }).Completed:Wait()
			old:Destroy()
		end)
	end
end

-- Válvula (tanques): el volante gira dos vueltas y la aguja pasa de rojo a verde
local function valveProp(b: CFrame)
	cyl("Tank", 3.2, 1.8, b * CFrame.new(0, 1.6, 0) * UP, Color3.fromHex("F4F2FA"))
	newPart("Stem", Vector3.new(0.3, 0.6, 0.3), b * CFrame.new(0, 3.4, 0), METAL, Enum.Material.Metal)
	local wheel = cyl("ValveWheel", 0.2, 1.3, b * CFrame.new(0, 3.75, 0) * UP, Config.Colors.Red)
	local P0 = b * CFrame.new(0, 1.9, -0.96)
	cyl("Gauge", 0.08, 1, P0 * FWD, Color3.new(1, 1, 1))
	newPart("RedMark", Vector3.new(0.18, 0.18, 0.04), P0 * CFrame.Angles(0, 0, math.rad(55)) * CFrame.new(0, 0.36, -0.05), Config.Colors.Red, Enum.Material.Neon)
	newPart("GreenMark", Vector3.new(0.18, 0.18, 0.04), P0 * CFrame.Angles(0, 0, math.rad(-55)) * CFrame.new(0, 0.36, -0.05), Config.Colors.Good, Enum.Material.Neon)
	local needle = newPart("Needle", Vector3.new(0.06, 0.42, 0.03), P0 * CFrame.Angles(0, 0, math.rad(55)) * CFrame.new(0, 0.2, -0.07), DARK)
	return function()
		spin(wheel, 2, 2)
		task.wait(0.5)
		hinge(needle, P0, CFrame.Angles(0, 0, math.rad(-110)), 1.5)
	end
end

-- Taladro de hielo (electrolizador): la broca gira y baja, salta hielo y sale un núcleo de hielo
local function drillProp(b: CFrame)
	local apex = (b * CFrame.new(0, 4.4, 0)).Position
	for i = 0, 2 do
		local a = i * 2 * math.pi / 3
		local foot = (b * CFrame.new(math.cos(a) * 1.4, 0, math.sin(a) * 1.4)).Position
		newPart("DrillLeg", Vector3.new(0.18, 0.18, (apex - foot).Magnitude), CFrame.lookAt((apex + foot) / 2, apex), METAL, Enum.Material.Metal)
	end
	newPart("DrillMotor", Vector3.new(0.9, 0.9, 0.9), CFrame.new(apex), Config.Colors.Gold)
	local ice = cyl("IceSurface", 0.1, 2.4, b * CFrame.new(0, 0.05, 0) * UP, Color3.fromHex("CFEFFF"), Enum.Material.Ice)
	local start = b * CFrame.new(0, 2.7, 0) * UP
	local bit = cyl("DrillBit", 2.6, 0.35, start, METAL, Enum.Material.DiamondPlate)
	return function()
		burst(ice, Color3.fromHex("E8F8FF"), 2, { Acceleration = Vector3.new(0, -6, 0), Speed = NumberRange.new(3, 6) })
		for _ = 1, 18 do
			-- tras UP, la X local apunta hacia arriba: -X baja la broca
			tw(bit, 0.11, { CFrame = bit.CFrame * CFrame.new(-0.07, 0, 0) * CFrame.Angles(math.rad(45), 0, 0) }, Enum.EasingStyle.Linear).Completed:Wait()
		end
		local core = newPart("IceCore", Vector3.new(0.6, 0.1, 0.6), b * CFrame.new(1.1, 0.1, -0.7), Color3.fromHex("CFEFFF"), Enum.Material.Ice)
		tw(core, 0.8, { Size = Vector3.new(0.6, 1.4, 0.6), CFrame = b * CFrame.new(1.1, 0.75, -0.7) })
		tw(bit, 0.9, { CFrame = start })
	end
end

-- Pala de regolito (planta de oxígeno): cava dos veces, el montón baja y el balde se llena
local function digProp(b: CFrame)
	local pile = newPart("Regolith", Vector3.new(3, 1.4, 3), b * CFrame.new(0, 0.3, 0.3), Color3.fromHex("8E89A8"), Enum.Material.Sand)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = pile
	cyl("Bucket", 1.2, 1.3, b * CFrame.new(1.9, 0.6, -0.5) * UP, Color3.fromHex("F4F2FA"))
	local fill = cyl("BucketFill", 0.1, 1.1, b * CFrame.new(1.9, 0.2, -0.5) * UP, Color3.fromHex("8E89A8"), Enum.Material.Sand)
	local handle = newPart("ShovelHandle", Vector3.new(0.15, 2.6, 0.15), b * CFrame.new(-1.3, 1.6, -0.4) * CFrame.Angles(0, 0, math.rad(-15)), Color3.fromHex("8A6E4B"), Enum.Material.Wood)
	local blade = newPart("ShovelBlade", Vector3.new(0.8, 0.9, 0.08), handle.CFrame * CFrame.new(0, -1.6, 0), METAL, Enum.Material.Metal)
	return function()
		local pv = handle.CFrame * CFrame.new(0, 1.2, 0)
		for _ = 1, 2 do
			hinge(handle, pv, CFrame.Angles(0, 0, math.rad(-35)), 0.4)
			hinge(blade, pv, CFrame.Angles(0, 0, math.rad(-35)), 0.4).Completed:Wait()
			burst(pile, Color3.fromHex("A9A4C2"), 0.3, { Speed = NumberRange.new(2, 4) })
			hinge(handle, pv, CFrame.Angles(0, 0, math.rad(35)), 0.4)
			hinge(blade, pv, CFrame.Angles(0, 0, math.rad(35)), 0.4).Completed:Wait()
		end
		tw(mesh, 1, { Scale = Vector3.new(0.65, 0.5, 0.65) })
		tw(fill, 1, { CFrame = b * CFrame.new(1.9, 1.1, -0.5) * UP })
	end
end

-- Manguera: el extremo se conecta al puerto de la máquina y la palanca se cierra
local function hoseProp(b: CFrame)
	newPart("PortPlate", Vector3.new(1.4, 1.6, 0.3), b * CFrame.new(0, 1, 0.2), METAL, Enum.Material.Metal)
	cyl("Port", 0.6, 0.6, b * CFrame.new(0, 1, -0.2) * FWD, Color3.fromHex("8F8AA8"), Enum.Material.Metal)
	local hoseEnd = cyl("HoseEnd", 1, 0.45, b * CFrame.new(1.4, 0.25, -1.8) * CFrame.Angles(0, math.rad(40), 0), Config.Colors.Sky)
	local lever = newPart("Lever", Vector3.new(0.15, 0.8, 0.15), b * CFrame.new(0.55, 1.6, -0.2), Config.Colors.Red)
	local light = statusLight(b * CFrame.new(-0.5, 1.6, -0.1))
	return function()
		tw(hoseEnd, 0.9, { CFrame = b * CFrame.new(0, 1, -0.9) * FWD })
		task.wait(1)
		hinge(lever, b * CFrame.new(0.55, 1.2, -0.2), CFrame.Angles(0, 0, math.rad(-90)), 0.4)
		task.wait(0.4)
		lightOk(light)
	end
end

-- Paneles: la manivela gira y las placas de los paneles se inclinan hacia el Sol
local PANEL_PARTS = { cells = true, backsheet = true, frame = true, caps = true, bracket = true, Panel = true }
local function panelProp(b: CFrame, m: Model?)
	newPart("CrankBox", Vector3.new(0.9, 1.6, 0.7), b * CFrame.new(0, 0.8, 0), DARK)
	local wheel = cyl("CrankWheel", 0.15, 0.8, b * CFrame.new(0, 1.2, -0.43) * FWD, Config.Colors.Gold)
	return function()
		spin(wheel, 2, 1.6)
		if not m then return end
		for _, unit in m:GetChildren() do
			local parts = {}
			local pivot: CFrame? = nil
			for _, d in (unit:IsA("Model") and unit:GetDescendants() or { unit }) do
				if d:IsA("BasePart") and PANEL_PARTS[d.Name] then
					table.insert(parts, d)
					if d.Name == "bracket" or not pivot then pivot = unit:GetPivot().Rotation + d.Position end
				end
			end
			for _, p in parts do
				hinge(p, pivot :: CFrame, CFrame.Angles(math.rad(10), 0, 0), 1.6)
			end
		end
	end
end

-- Batería: se abre la puerta y la barra de carga sube hasta verde
local function batteryProp(b: CFrame)
	newPart("BatteryCabinet", Vector3.new(2, 2.6, 1.2), b * CFrame.new(0, 1.3, 0), DARK)
	newPart("ChargeFrame", Vector3.new(0.5, 1.9, 0.05), b * CFrame.new(0, 1.3, -0.62), Color3.fromHex("111326"))
	local bar = newPart("ChargeBar", Vector3.new(0.38, 0.35, 0.06), b * CFrame.new(0, 0.53, -0.64), Config.Colors.Gold, Enum.Material.Neon)
	local door = newPart("BatteryDoor", Vector3.new(1.9, 2.4, 0.08), b * CFrame.new(0, 1.3, -0.68), METAL, Enum.Material.Metal)
	local light = statusLight(b * CFrame.new(0.7, 2.75, -0.4))
	return function()
		hinge(door, b * CFrame.new(-0.95, 1.3, -0.68), CFrame.Angles(0, math.rad(100), 0), 0.7)
		task.wait(0.8)
		tw(bar, 1.6, { Size = Vector3.new(0.38, 1.8, 0.06), CFrame = b * CFrame.new(0, 1.3, -0.64), Color = Config.Colors.Good })
		task.wait(1.6)
		lightOk(light)
	end
end

-- Radiador (reactor): se quita el polvo lunar y las aletas se enfrían (de naranja a metal)
local function radiatorProp(b: CFrame)
	newPart("RadiatorPost", Vector3.new(0.3, 0.6, 0.3), b * CFrame.new(0, 0.3, 0), METAL, Enum.Material.Metal)
	local fins = {}
	for i = -2, 2 do
		table.insert(fins, newPart("Fin", Vector3.new(0.12, 2.6, 1.8), b * CFrame.new(i * 0.32, 1.9, 0), Color3.fromHex("E8743B"), Enum.Material.Neon))
	end
	local dust = newPart("LunarDust", Vector3.new(1.7, 2.7, 1.95), b * CFrame.new(0, 1.9, 0), Color3.fromHex("9A8F7A"), Enum.Material.Sand)
	dust.Transparency = 0.3
	local light = statusLight(b * CFrame.new(1.1, 3.3, 0))
	light.Color = Config.Colors.Red
	return function()
		burst(dust, Color3.fromHex("B5AA94"), 1, { Acceleration = Vector3.new(0, -4, 0) })
		tw(dust, 1.2, { Transparency = 1, CFrame = b * CFrame.new(0, 1.2, 0) })
		task.wait(0.8)
		for _, f in fins do
			tw(f, 1.5, { Color = METAL })
		end
		task.wait(1.5)
		for _, f in fins do f.Material = Enum.Material.Metal end
		dust:Destroy()
		lightOk(light)
	end
end

-- Herramienta de reparación: una llave gira junto al objeto con chispas
local function repairAnim(pos: Vector3)
	local w = newPart("Wrench", Vector3.new(1.8, 0.25, 0.4), CFrame.new(pos + Vector3.new(0, 2.5, -1.5)), METAL, Enum.Material.Metal)
	burst(w, Config.Colors.Gold, 1.5, { LightEmission = 1, Speed = NumberRange.new(6, 10) })
	spin(w, 2, 1.5)
	task.delay(1.8, function() w:Destroy() end)
end

---------------------------------------------------------------------
-- Las 4 misiones (PDF Fase 2, cap. 5)
---------------------------------------------------------------------
local function introFor(role: string): string
	local choice = GS:GetAttribute("Choice_" .. role) or ""
	if role == "cap" then return M.cap.Intro end
	local opt = M[role].ByOption and M[role].ByOption[choice]
	return opt and opt.Intro or ""
end

local function setupCaptain()
	local zone = site.CargoZone.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.5, 0)
	GS:SetAttribute("Mission_cap_Total", M.cap.Count)
	local templates = ServerStorage:FindFirstChild("SO_Templates")
	for _, pos in around(zone, M.cap.Count, M.cap.BeaconRadius or 11, math.rad(90)) do -- 15-nov: radio en Config
		local kit = newPart("BeaconKit", Vector3.new(1.6, 0.8, 1), baseAt(pos, zone) * CFrame.new(0, 0.4, 0), METAL)
		holdPoint(pos, M.cap.Prompt, M.cap.Hold, "cap", function()
			-- Baliza: se clava en el suelo (sube desde abajo), parpadea en rojo y queda verde
			kit:Destroy()
			local tpl = templates and templates:FindFirstChild("beacon")
			if tpl then
				local b = tpl:Clone()
				b:PivotTo(CFrame.new(pos - Vector3.new(0, 3, 0)))
				b.Parent = folder
				tweenPivot(b, CFrame.new(pos), 1.2)
				local light = b:FindFirstChild("Light")
				if light then
					task.spawn(function()
						for _ = 1, 3 do
							light.Color = Config.Colors.Red; task.wait(0.2)
							light.Color = Color3.new(1, 1, 1); task.wait(0.2)
						end
						light.Color = Config.Colors.Good
					end)
				end
			end
			step("cap", M.cap.Done, M.cap.Fact)
		end)
	end
end

local function setupEngineer()
	local choice = GS:GetAttribute("Choice_eng") or "panels"
	local opt = M.eng.ByOption[choice] or M.eng.ByOption.panels
	local n = M.eng.CountBySite[GS:GetAttribute("Site") or ""] or 1
	GS:SetAttribute("Mission_eng_Total", n)
	local m = placedModel("eng")
	local center = posOf("eng")
	for _, pos in around(center, n, 7, math.rad(30)) do
		local b = baseAt(pos, center)
		local play = (choice == "reactor") and radiatorProp(b) or (choice == "panels_bat") and batteryProp(b) or panelProp(b, m)
		holdPoint(pos, opt.Prompt, M.eng.Hold, "eng", function()
			task.spawn(play)
			step("eng", M.eng.Done, opt.Fact)
		end)
	end
end

local function setupLifeSupport()
	local choice = GS:GetAttribute("Choice_life") or "recycler"
	local opt = M.life.ByOption[choice] or M.life.ByOption.recycler
	local machine = posOf("life")
	GS:SetAttribute("Mission_life_Total", opt.Count)
	if choice == "electrolyzer" or choice == "o2plant" then
		-- 1) perforar el hielo / cavar regolito, 2) conectar la manguera en la máquina
		local dist = M.life.IceDistance[GS:GetAttribute("Spot_life") or ""] or 45
		if GS:GetAttribute("Site") == "malapert" then dist += M.life.MalapertExtra end
		local source
		if choice == "electrolyzer" and site:FindFirstChild("Ice") then
			local ice = site.Ice.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
			source = ((ice - machine).Magnitude > dist) and (machine + (ice - machine).Unit * dist) or ice
		else
			source = machine + Vector3.new(-dist, 0, 0)
		end
		local sourceDone, hoseDone = false, false
		local function hose()
			if not (sourceDone and hoseDone) then return end
			local mid, len = (source + machine) / 2, (source - machine).Magnitude
			local h = Instance.new("Part")
			h.Name = "Hose"
			h.Size = Vector3.new(0.4, 0.4, len)
			h.CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.4, 0), machine + Vector3.new(0, 0.4, 0))
			h.Anchored = true
			h.CanCollide = false
			h.Color = Config.Colors.Sky
			h.Material = Enum.Material.Neon
			h.Parent = folder
		end
		local playSource = (choice == "electrolyzer") and drillProp(baseAt(source, machine)) or digProp(baseAt(source, machine))
		local hosePos = machine + Vector3.new(6, 0, 0)
		local playHose = hoseProp(baseAt(hosePos, hosePos + Vector3.new(6, 0, 0)))
		holdPoint(source, opt.Prompt, opt.Hold, "life", function()
			sourceDone = true; task.spawn(playSource); hose(); step("life", M.life.Done, opt.Fact)
		end)
		holdPoint(hosePos, opt.Prompt2, opt.Hold, "life", function()
			hoseDone = true; task.spawn(playHose); hose(); step("life", M.life.Done, opt.Fact)
		end)
	else
		for _, pos in around(machine, opt.Count, 7) do
			local b = baseAt(pos, machine)
			local play = (choice == "tanks") and valveProp(b) or filterProp(b)
			holdPoint(pos, opt.Prompt, opt.Hold, "life", function()
				task.spawn(play)
				step("life", M.life.Done, opt.Fact)
			end)
		end
	end
end

local function setupBotanist()
	local choice = GS:GetAttribute("Choice_bot") or "hydroponics"
	local opt = M.bot.ByOption[choice] or M.bot.ByOption.hydroponics
	local m = placedModel("bot")
	if choice == "packaged" then
		GS:SetAttribute("Mission_bot_Total", opt.Count)
		local crates = {}
		if m then
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Crate" then table.insert(crates, d.Position) end
			end
		end
		if #crates == 0 then crates = around(posOf("bot"), opt.Count, 4) end
		for i = 1, opt.Count do
			local at = crates[i] or crates[1]
			holdPoint(at, opt.Prompt, opt.Hold, "bot", function()
				-- La caja se abre y salen los paquetes de comida contados
				for k = -1, 1 do
					local pack = newPart("FoodPack", Vector3.new(0.5, 0.7, 0.2), CFrame.new(at + Vector3.new(k * 0.6, 0.5, 0)), ({ Config.Colors.Red, Config.Colors.Gold, Config.Colors.Good })[k + 2])
					tw(pack, 0.6 + (k + 1) * 0.2, { CFrame = CFrame.new(at + Vector3.new(k * 0.6, 2.4, 0)) }, Enum.EasingStyle.Back)
				end
				step("bot", M.bot.DoneFood, opt.Fact)
			end)
		end
		return
	end
	-- Bandejas: las del invernadero colocado (una rota si se dañó al moverlo)
	local trays = {}
	if m then
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Tray" then table.insert(trays, d) end
		end
	end
	if GS:GetAttribute("Damaged_bot") and #trays > 1 then
		trays[1].Color = Color3.fromHex("6B5B4B")
		table.remove(trays, 1)
	end
	GS:SetAttribute("Mission_bot_Total", math.max(1, #trays))
	for _, tray in trays do
		holdPoint(tray.Position + Vector3.new(0, 0.3, 2.4), opt.Prompt, opt.Hold, "bot", function()
			tray:SetAttribute("Planted", true)
			CollectionService:AddTag(tray, "SO_Tray")
			-- Sobre de semillas que se vuelca sobre la bandeja; las semillas caen y luego sale el brote
			local packet = newPart("SeedPacket", Vector3.new(0.7, 1, 0.08), CFrame.new(tray.Position + Vector3.new(0, 2.2, 0)), Color3.fromHex("F4F2FA"))
			newPart("SeedLabel", Vector3.new(0.5, 0.4, 0.1), packet.CFrame, Config.Colors.Good).Parent = packet
			tw(packet, 0.4, { CFrame = packet.CFrame * CFrame.Angles(0, 0, math.rad(150)) })
			burst(packet, Color3.fromHex("6B4E2E"), 1, { Speed = NumberRange.new(0.5, 1.5), Acceleration = Vector3.new(0, -25, 0), Size = NumberSequence.new(0.15) })
			task.wait(1.2)
			packet:Destroy()
			-- Brote verde que crece (más pequeño con el kit de regolito)
			local s = Instance.new("Part")
			s.Name = "Sprout"
			s.Size = Vector3.new(0.2, 0.2, 0.2)
			s.Position = tray.Position + Vector3.new(0, 0.5, 0)
			s.Anchored = true
			s.CanCollide = false
			s.Color = Config.Colors.Good
			s.Material = Enum.Material.Neon
			s.Parent = tray
			local size = choice == "regolith_kit" and Vector3.new(0.6, 0.8, 0.6) or Vector3.new(1, 1.4, 1)
			TweenService:Create(s, TweenInfo.new(1.5), { Size = size, Position = tray.Position + Vector3.new(0, 0.4 + size.Y / 2, 0) }):Play()
			step("bot", M.bot.Done, opt.Fact)
		end)
	end
	if #trays == 0 then
		GS:SetAttribute("Mission_bot_Total", 1)
		holdPoint(posOf("bot") + Vector3.new(0, 0, 8), opt.Prompt, opt.Hold, "bot", function()
			step("bot", M.bot.Done, opt.Fact)
		end)
	end
end

---------------------------------------------------------------------
-- Reparaciones (PDF Fase 2, cap. 6): cualquiera, mantener E 10 s
---------------------------------------------------------------------
local function setupRepairs()
	for _, role in ROLES do
		if GS:GetAttribute("Damaged_" .. role) then
			local m = placedModel(role)
			local pos = posOf(role) + Vector3.new(0, 0, 7)
			local sign: BillboardGui? = nil
			if m and m.PrimaryPart then
				sign = Instance.new("BillboardGui")
				sign.Name = "SO_DamagedSign"
				sign.Size = UDim2.fromOffset(240, 34)
				sign.StudsOffset = Vector3.new(0, 9, 0)
				sign.AlwaysOnTop = true
				sign.MaxDistance = 120
				local l = Instance.new("TextLabel")
				l.Size = UDim2.fromScale(1, 1)
				l.BackgroundColor3 = Config.Colors.Bad
				l.TextColor3 = Color3.new(1, 1, 1)
				l.Font = Enum.Font.FredokaOne
				l.TextScaled = true
				l.Text = Config.Text.DamagedSign
				l.Parent = sign
				local c = Instance.new("UICorner"); c.Parent = l
				sign.Parent = m.PrimaryPart
			end
			holdPoint(pos, "Hold E to repair", Config.RepairHold, role, function()
				repairAnim(pos)
				GS:SetAttribute("Damaged_" .. role, false)
				if sign then sign:Destroy() end
				if m then
					for _, d in m:GetDescendants() do
						if d:IsA("Sparkles") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("ParticleEmitter") then d:Destroy() end
					end
				end
				Remotes.Toast:FireAllClients(Config.Text.Repaired, 3)
				Remotes.Fact:FireAllClients(Config.PhaseFacts.Damaged)
			end)
		end
	end
end

---------------------------------------------------------------------
-- Ciclo de la fase
---------------------------------------------------------------------
local function updateEnergy()
	local made, used = Energy.calc(GS)
	GS:SetAttribute("EnergyMade", made)
	GS:SetAttribute("EnergyUsed", used)
end

local function startPhase2()
	ensureTestObjects()
	if folder then folder:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "Missions"
	f.Parent = site
	folder = f
	for _, role in ROLES do
		GS:SetAttribute("Mission_" .. role .. "_Done", 0)
		GS:SetAttribute("Mission_" .. role .. "_Total", 0)
		GS:SetAttribute("MissionComplete_" .. role, false)
	end
	setupCaptain()
	setupEngineer()
	setupLifeSupport()
	setupBotanist()
	setupRepairs()
	updateEnergy()
end

local function endPhase2()
	if not folder then return end
	-- Se quitan los puntos que falten; las balizas y la manguera se quedan
	for _, d in folder:GetChildren() do
		if d.Name:match("^MissionPoint_") then d:Destroy() end
	end
end

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local phase = GS:GetAttribute("Phase")
	if phase == "Phase2Intro" then
		for _, role in ROLES do
			GS:SetAttribute("Phase2Intro_" .. role, introFor(role))
		end
		updateEnergy()
	elseif phase == "Phase2" then
		startPhase2()
	elseif phase == "Transition23" or phase == "Phase3" then
		endPhase2()
	elseif phase == "RoleSelect" and folder then
		folder:Destroy() -- nueva partida: fuera balizas y mangueras
		folder = nil
	end
end)

for _, role in ROLES do
	GS:GetAttributeChangedSignal("Damaged_" .. role):Connect(function()
		if GS:GetAttribute("Phase") == "Phase2" then updateEnergy() end
	end)
end
