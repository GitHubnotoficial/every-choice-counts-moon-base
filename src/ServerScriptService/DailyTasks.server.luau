-- DailyTasks (Script) -> ServerScriptService.DailyTasks
-- Dueño: Isaac + Claude. Fase 3: tareas diarias de mantenimiento (pedido de Isaac 15-nov: "los días quedan vacíos").
-- Cada día sale una tarea por rol; cualquiera vivo puede hacerla. Recompensas:
--   cap  → revisar los sellos de la escotilla: −10 de radiación para todos.
--   eng  → limpiar el polvo de los paneles (o radiadores del reactor): +10 de energía el resto del día.
--   life → cortar 2 bloques en el cráter de hielo, llevarlos en la mano y cargarlos en la máquina: +5 % de reserva cada uno.
--   bot  → regar las bandejas (−30 s de crecimiento) o, con comida empacada, revisar las cajas (+0,25 días de comida).
-- Escribe: Task_<rol>_Done (bool) y Task_life_Progress ("0/2"). Textos y números en Config.DailyTasks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DT = Config.DailyTasks
local O = Config.Zones.Moon

local site = workspace:WaitForChild("MoonSite")
local folder: Folder? = nil

local function inPhase3(): boolean
	return GS:GetAttribute("Phase") == "Phase3"
end

local function clear()
	if folder then folder:Destroy(); folder = nil end
	for _, p in Players:GetPlayers() do
		local ice = p.Character and p.Character:FindFirstChild("SO_CarriedIce")
		if ice then ice:Destroy() end
		p:SetAttribute("CarryingIce", nil)
	end
end

-- Altura real del suelo en un punto (ignora jugadores, base colocada y tareas)
local function snap(pos: Vector3): Vector3
	local params = RaycastParams.new()
	local ignore: { Instance } = {}
	for _, n in { "Placed", "Lander", "ChosenLander", "HabitatZone", "LanderZone", "DailyTasks", "Missions" } do
		local x = site:FindFirstChild(n)
		if x then table.insert(ignore, x) end
	end
	for _, p in Players:GetPlayers() do
		if p.Character then table.insert(ignore, p.Character) end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 40, pos.Z), Vector3.new(0, -80, 0), params)
	return hit and Vector3.new(pos.X, hit.Position.Y + 0.4, pos.Z) or pos
end

local function placedPos(role: string): Vector3?
	local placed = site:FindFirstChild("Placed")
	local m = placed and placed:FindFirstChild(role)
	return m and (m:GetPivot().Position * Vector3.new(1, 0, 1)) or nil
end

-- Punto "mantener E" con anillo del color del rol y una luz que sube y baja (para encontrarlo)
local function taskPoint(pos: Vector3, role: string, text: string, hold: number, onDone: (Player) -> ()): BasePart
	pos = snap(pos)
	local color = Config.Roles[role].Color
	local p = Instance.new("Part")
	p.Name = "Task_" .. role
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.3, 4.5, 4.5)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.35
	p.Parent = folder
	local beam = Instance.new("Part")
	beam.Name = "Marker"
	beam.Size = Vector3.new(0.4, 8, 0.4)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.5
	beam.Parent = p
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.ObjectText = DT.Title
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = p
	prompt.Triggered:Connect(function(plr)
		if plr:GetAttribute("Dead") or not inPhase3() or not prompt.Enabled then return end
		onDone(plr)
	end)
	return p
end

local function burstAt(part: BasePart, color: Color3)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.3, 0)
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Speed = NumberRange.new(4, 8)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Rate = 60
	e.Parent = part
	task.delay(1, function() e.Enabled = false end)
end

local function finish(role: string, point: BasePart?, doneText: string, fact: string)
	GS:SetAttribute("Task_" .. role .. "_Done", true)
	if point then
		local pr = point:FindFirstChildOfClass("ProximityPrompt")
		if pr then pr.Enabled = false end
		point.Color = Config.Colors.Good
		burstAt(point, Config.Colors.Good)
		task.delay(1.5, function() if point.Parent then point:Destroy() end end)
	end
	Remotes.Toast:FireAllClients(doneText, 4)
	Remotes.Fact:FireAllClients(fact)
end

---------------------------------------------------------------------
-- Las 4 tareas
---------------------------------------------------------------------
local function setupCap()
	local hab = site:FindFirstChild("Placed") and site.Placed:FindFirstChild("cap")
	local pos = hab and (hab:GetPivot() * CFrame.new(13.5, 0, 0)).Position or (site.LanderZone.Position + Vector3.new(20, 0, 10))
	local point
	point = taskPoint(pos, "cap", DT.cap.Prompt, DT.cap.Hold, function()
		for _, p in Players:GetPlayers() do
			if not p:GetAttribute("Dead") and p:GetAttribute("Radiation") then
				p:SetAttribute("Radiation", math.max(0, p:GetAttribute("Radiation") - DT.cap.RadDrop))
			end
		end
		finish("cap", point, DT.cap.Done, DT.cap.Fact)
	end)
end

local function setupEng()
	local reactor = GS:GetAttribute("Choice_eng") == "reactor"
	local base = placedPos("eng") or (site.LanderZone.Position * Vector3.new(1, 0, 1) + Vector3.new(-15, 0, -10))
	local point
	point = taskPoint(base + Vector3.new(0, 0, 7), "eng", reactor and DT.eng.PromptReactor or DT.eng.Prompt, DT.eng.Hold, function()
		-- Polvo que sale volando de los paneles
		local placed = site:FindFirstChild("Placed")
		local m = placed and placed:FindFirstChild("eng")
		local first = m and m:FindFirstChildWhichIsA("BasePart", true)
		if first then burstAt(first, Color3.fromHex("B5AA94")) end
		GS:SetAttribute("EnergyMade", (GS:GetAttribute("EnergyMade") or 0) + DT.eng.Bonus)
		finish("eng", point, DT.eng.Done, DT.eng.Fact)
	end)
end

local function setupLife()
	local n = 0
	GS:SetAttribute("Task_life_Progress", "0/" .. DT.life.Count)
	local crater = site:FindFirstChild("SO_IceCraterDeep")
	local icePos = (crater and crater:GetBoundingBox().Position or (O + Vector3.new(-90, 0, 80))) * Vector3.new(1, 0, 1) + Vector3.new(4, 0, -4)
	local machine = placedPos("life") or (site.LanderZone.Position * Vector3.new(1, 0, 1) + Vector3.new(6, 0, 0))
	local loadPoint: BasePart
	local icePoint: BasePart
	icePoint = taskPoint(icePos, "life", DT.life.PromptIce, DT.life.Hold, function(plr)
		if plr:GetAttribute("CarryingIce") then return end
		-- El bloque va en la mano del jugador
		plr:SetAttribute("CarryingIce", true)
		local char = plr.Character
		local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
		if hand then
			local props = ServerStorage:FindFirstChild("SO_MoonProps")
			local src = props and props:FindFirstChild("IceBlock1")
			local block: Instance
			if src then
				local m = src:Clone() :: Model
				local _, sz = m:GetBoundingBox()
				m:ScaleTo(m:GetScale() * 1.3 / math.max(sz.X, 0.01))
				m:PivotTo(hand.CFrame * CFrame.new(0, -0.6, -0.4))
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = false; d.CanCollide = false; d.Massless = true
						local w = Instance.new("WeldConstraint"); w.Part0 = hand; w.Part1 = d; w.Parent = d
					end
				end
				block = m
			else
				local b = Instance.new("Part")
				b.Size = Vector3.new(1.2, 1, 1.2)
				b.Material = Enum.Material.Ice
				b.Color = Color3.fromHex("CFEFFF")
				b.CanCollide = false; b.Massless = true
				b.CFrame = hand.CFrame * CFrame.new(0, -0.6, -0.4)
				local w = Instance.new("WeldConstraint"); w.Part0 = hand; w.Part1 = b; w.Parent = b
				block = b
			end
			block.Name = "SO_CarriedIce"
			block.Parent = char
		end
		burstAt(icePoint, Color3.fromHex("E8F8FF"))
		Remotes.Toast:FireClient(plr, DT.life.Carrying, 3)
	end)
	loadPoint = taskPoint(machine + Vector3.new(-6, 0, 0), "life", DT.life.PromptLoad, DT.life.Hold, function(plr)
		if not plr:GetAttribute("CarryingIce") then return end
		plr:SetAttribute("CarryingIce", nil)
		local ice = plr.Character and plr.Character:FindFirstChild("SO_CarriedIce")
		if ice then ice:Destroy() end
		GS:SetAttribute("ReserveO2", math.min(100, (GS:GetAttribute("ReserveO2") or 0) + DT.life.Reserve))
		GS:SetAttribute("ReserveWater", math.min(100, (GS:GetAttribute("ReserveWater") or 0) + DT.life.Reserve))
		n += 1
		GS:SetAttribute("Task_life_Progress", n .. "/" .. DT.life.Count)
		burstAt(loadPoint, Color3.fromHex("7FB8FF"))
		if n >= DT.life.Count then
			if icePoint.Parent then icePoint:Destroy() end
			finish("life", loadPoint, DT.life.Done, DT.life.Fact)
		end
	end)
end

local function setupBot()
	local packaged = GS:GetAttribute("Choice_bot") == "packaged"
	local base = placedPos("bot") or (site.LanderZone.Position * Vector3.new(1, 0, 1) + Vector3.new(20, 0, 25))
	local point
	point = taskPoint(base + Vector3.new(0, 0, -8), "bot", packaged and DT.bot.PromptPackaged or DT.bot.Prompt, DT.bot.Hold, function()
		if packaged then
			GS:SetAttribute("Food", (GS:GetAttribute("Food") or 0) + DT.bot.FoodBonus)
			finish("bot", point, DT.bot.DonePackaged, DT.bot.Fact)
		else
			for _, tray in CollectionService:GetTagged("SO_Tray") do
				local left = tray:GetAttribute("GrowLeft")
				if left and left > 0 then
					tray:SetAttribute("GrowLeft", math.max(1, left - DT.bot.GrowBoost))
				end
				if tray:IsA("BasePart") then burstAt(tray, Color3.fromHex("7FB8FF")) end
			end
			finish("bot", point, DT.bot.Done, DT.bot.Fact)
		end
	end)
end

---------------------------------------------------------------------
-- Cada día, tareas nuevas
---------------------------------------------------------------------
local function newDay()
	clear()
	if not inPhase3() then return end
	folder = Instance.new("Folder")
	folder.Name = "DailyTasks"
	folder.Parent = site
	for _, r in Config.RoleOrder do
		GS:SetAttribute("Task_" .. r .. "_Done", false)
	end
	setupCap()
	setupEng()
	setupLife()
	setupBot()
end

GS:GetAttributeChangedSignal("Day"):Connect(function()
	if inPhase3() and (GS:GetAttribute("Day") or 0) >= 1 then
		task.wait(0.5) -- después de que Resources recalcula la energía del día
		newDay()
	end
end)
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if not inPhase3() then
		clear()
		for _, r in Config.RoleOrder do GS:SetAttribute("Task_" .. r .. "_Done", nil) end
		GS:SetAttribute("Task_life_Progress", nil)
	end
end)
-- Si alguien muere cargando hielo, el bloque se quita
Players.PlayerAdded:Connect(function(p)
	p:GetAttributeChangedSignal("Dead"):Connect(function()
		if p:GetAttribute("Dead") then
			p:SetAttribute("CarryingIce", nil)
			local ice = p.Character and p.Character:FindFirstChild("SO_CarriedIce")
			if ice then ice:Destroy() end
		end
	end)
end)
