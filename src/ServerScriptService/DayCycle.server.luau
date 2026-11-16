-- DayCycle (Script) -> ServerScriptService.DayCycle
-- Dueño: Isaac + Claude. Fase 3: 7 días de 2 min (PDF Fase 3, caps. 1, 2 y 7.1).
-- Escribe: Day, DayTimeLeft, DayEndCount, CargoArrived, Result ("won" / "lost").
-- Al empezar la fase se asegura de que todos estén en la Luna (por si se saltó directo con Debug).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local P3 = Config.Phase3

local site = workspace:WaitForChild("MoonSite")
local running = false
local skipDay = false

local function find(list, id)
	for _, x in list do
		if x.Id == id then return x end
	end
	return nil
end

local function alivePlayers(): number
	local n = 0
	for _, p in Players:GetPlayers() do
		if not p:GetAttribute("Dead") then n += 1 end
	end
	return n
end

-- Lleva a todos a la Luna si no están (solo pasa al saltar fases en pruebas)
local function ensureOnMoon()
	workspace.Gravity = Config.Gravity.Moon
	local spawnPos = site.LanderSpawn.Position
	for i, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - spawnPos).Magnitude > 400 then
			p.Character:PivotTo(CFrame.new(spawnPos + Vector3.new(i * 3, 3, 0)))
		end
	end
	-- Región del hábitat en el punto que eligió el Captain (si Placement no la movió)
	local spot = find(Config.Spots.cap, GS:GetAttribute("Spot_cap") or "")
	if spot and not site:FindFirstChild("Placed") then
		site.HabitatZone.Position = site.Lander.PrimaryPart.Position * Vector3.new(1, 0, 1)
			+ Vector3.new(0, 6, 0) + spot.Offset
	end
end

-- Objetos de prueba (solo en Studio y solo si Placement no colocó nada): clona las plantillas
-- de ServerStorage.SO_Templates en el punto de cada rol, para poder probar la Fase 3 sola.
local TEMPLATE_BY_ROLE = {
	cap = function() return "habitat" end,
	eng = function() return GS:GetAttribute("Choice_eng") == "reactor" and "reactor" or "panels" end,
	-- La máquina que eligió Life Support (modelos de Ramón en SO_Templates); si no existe, la genérica
	life = function()
		local c = GS:GetAttribute("Choice_life") or ""
		local t = game:GetService("ServerStorage"):FindFirstChild("SO_Templates")
		return (t and t:FindFirstChild(c)) and c or "lifesupport"
	end,
	bot = function() return GS:GetAttribute("Choice_bot") ~= "packaged" and "greenhouse" or nil end,
}
local function ensureTestObjects()
	if site:FindFirstChild("Placed") or not RunService:IsStudio() then return end
	local templates = game:GetService("ServerStorage"):FindFirstChild("SO_Templates")
	if not templates then return end
	local placed = Instance.new("Folder")
	placed.Name = "Placed"
	placed.Parent = site
	local ground = site.Lander.PrimaryPart.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
	for role, pick in TEMPLATE_BY_ROLE do
		local name = pick()
		local spot = find(Config.Spots[role], GS:GetAttribute("Spot_" .. role) or "")
		local tpl = name and templates:FindFirstChild(name)
		if tpl and spot then
			local m = tpl:Clone()
			m.Name = role
			m:PivotTo(CFrame.new(ground + spot.Offset))
			m.Parent = placed
			-- Bandejas del invernadero: plantadas y etiquetadas para las cosechas
			if role == "bot" then
				local n = spot.Trays or 2
				local trays = {}
				for _, d in m:GetDescendants() do
					if d.Name == "Tray" then table.insert(trays, d) end
				end
				for i, t in trays do
					if i <= n then
						t:SetAttribute("Planted", true)
						CollectionService:AddTag(t, "SO_Tray")
					end
				end
			end
		end
	end
	-- La región del hábitat sigue al hábitat
	local hab = placed:FindFirstChild("cap")
	if hab then site.HabitatZone.CFrame = hab:GetPivot() + Vector3.new(0, 5, 0) end
end

-- Nave de carga y de rescate (PDF 7.1): el mismo modelo baja del cielo en 6 s con una luz de motor
-- que se apaga al aterrizar. Con balizas aterriza en la zona de carga; sin balizas, junto a la nave.
local function spawnShip(name: string, seconds: number?): Model
	local templates = game:GetService("ServerStorage"):FindFirstChild("SO_Templates")
	local tpl = templates and templates:FindFirstChild("cargoship")
	local m: Model
	if tpl then
		m = tpl:Clone()
	else
		m = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(10, 8, 10)
		body.Anchored = true
		body.Color = Color3.fromHex("DADAE6")
		body.Parent = m
		m.PrimaryPart = body
		body.PivotOffset = CFrame.new(0, -4, 0)
	end
	m.Name = name
	local ground = site.Lander.PrimaryPart.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
	local land = GS:GetAttribute("MissionComplete_cap") and (site.CargoZone.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 0.4, 0))
		or (ground + Vector3.new(-30, 0, -20))
	-- Luz de motor
	local flame = Instance.new("Part")
	flame.Name = "EngineFlame"
	flame.Shape = Enum.PartType.Ball
	flame.Size = Vector3.new(4, 4, 4)
	flame.Anchored = true
	flame.CanCollide = false
	flame.Material = Enum.Material.Neon
	flame.Color = Color3.fromHex("FF9A3C")
	flame.Parent = m
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 4
	light.Color = flame.Color
	light.Parent = flame
	local t = seconds or 6
	local startY = 160
	m:PivotTo(CFrame.new(land + Vector3.new(0, startY, 0)))
	flame.Position = land + Vector3.new(0, startY - 1, 0)
	m.Parent = site
	-- Descenso con frenado al final (cuadrático)
	local t0 = os.clock()
	while true do
		local k = math.clamp((os.clock() - t0) / t, 0, 1)
		local y = startY * (1 - k) ^ 2
		m:PivotTo(CFrame.new(land + Vector3.new(0, y, 0)))
		flame.Position = land + Vector3.new(0, y - 1, 0)
		if k >= 1 then break end
		task.wait()
	end
	light:Destroy()
	flame:Destroy()
	return m
end

Remotes.DebugSkip.OnServerEvent:Connect(function(_p, what)
	if not RunService:IsStudio() then return end
	if what == "day" then
		skipDay = true
	elseif what == "fill" then
		for _, p in Players:GetPlayers() do
			p:SetAttribute("O2", 100); p:SetAttribute("Water", 100); p:SetAttribute("Radiation", 0)
		end
	end
end)

local function runDays()
	running = true
	ensureOnMoon()
	ensureTestObjects()
	GS:SetAttribute("DayEndCount", 0)
	GS:SetAttribute("CargoArrived", false)
	GS:SetAttribute("CargoDayOverride", nil) -- 15-nov: sin contacto el día 3 -> la nave llega el día 5
	GS:SetAttribute("Result", "")

	for day = 1, P3.Days do
		if GS:GetAttribute("Phase") ~= "Phase3" then running = false return end
		GS:SetAttribute("Day", day)
		GS:SetAttribute("DayTimeLeft", P3.DayLength)

		-- Aviso de inicio del día y nave de carga
		if day == (GS:GetAttribute("CargoDayOverride") or P3.CargoDay) then
			Remotes.Toast:FireAllClients(string.format(Config.Text3.CargoLanding, day), P3.DayIntro)
			if GS:GetAttribute("MissionComplete_cap") then
				task.spawn(spawnShip, "CargoShip", 6)
				GS:SetAttribute("CargoArrived", true)
				Remotes.Toast:FireAllClients(Config.Text3.CargoLanded, 4)
			else
				Remotes.Toast:FireAllClients(Config.Text3.CargoFailed, 4)
			end
		else
			Remotes.Toast:FireAllClients(string.format(Config.Text3.DayStart, day), P3.DayIntro)
		end

		-- Reloj del día
		local left = P3.DayLength
		while left > 0 do
			task.wait(1)
			if skipDay then skipDay = false; left = 0 else left -= 1 end
			GS:SetAttribute("DayTimeLeft", left)
			if alivePlayers() == 0 then
				GS:SetAttribute("Day", day)
				GS:SetAttribute("Result", "lost")
				running = false
				return
			end
			if GS:GetAttribute("Phase") ~= "Phase3" then running = false return end
		end
		-- Fin del día: Resources baja comida y suma producción
		GS:SetAttribute("DayEndCount", day)
	end

	-- Sobrevivieron: GameManager pasa a "Rescue" (12 s) y ahí baja la nave de rescate (PDF 7.1)
	GS:SetAttribute("Result", "won")
	running = false
end

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local phase = GS:GetAttribute("Phase")
	if phase == "Phase3" and not running then
		task.spawn(runDays)
	elseif phase == "RoleSelect" or phase == "Title" then
		-- Partida nueva: quitar naves, cinturones y revivir a los muertos (quedaban invisibles y anclados)
		for _, n in { "CargoShip", "RescueShip" } do
			local s = site:FindFirstChild(n)
			if s then s:Destroy() end
		end
		local belts = site:FindFirstChild("Belts")
		if belts then belts:ClearAllChildren() end
		for _, p in Players:GetPlayers() do
			p:SetAttribute("Belts", nil)
			p:SetAttribute("NoWaterLeft", nil)
			-- (solo los que murieron: PhaseMovement también ancla a todos en las pantallas 2D)
			if p:GetAttribute("DeathCause") then
				p:SetAttribute("DeathCause", nil)
				p:SetAttribute("DeathWhy", nil)
				p:LoadCharacter()
			end
		end
		GS:SetAttribute("NextChooseTime", nil)
	elseif phase == "Rescue" then
		-- 4 s de texto, 6 s de descenso, 2 s de cierre
		Remotes.Toast:FireAllClients(Config.Text3.Day7Complete .. " — " .. Config.Text3.ShipComing, 4)
		task.delay(4, function()
			if GS:GetAttribute("Phase") == "Rescue" then spawnShip("RescueShip", 6) end
		end)
	end
end)
