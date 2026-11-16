-- Bars (Script) -> ServerScriptService.Bars
-- Dueño: Isaac + Claude. Barras por jugador: O2, Water, Radiation (atributos del jugador, 0–100), Dead.
-- Corre desde Placement hasta el final. Recarga en la nave (en Fase 3 gasta la reserva de la base).
-- Muerte: espectador + deja su cinturón (otro lo recoge con E y puede elegir en emergencias de ese rol).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local R = Config.BarRates

local ACTIVE_PHASES = {
	Landing = true, Placement = true, Transition12 = true, Phase2Intro = true,
	Phase2 = true, Transition23 = true, Phase3 = true,
}

local site = workspace:WaitForChild("MoonSite")
local landerZone = site:WaitForChild("LanderZone") :: BasePart
local habitatZone = site:WaitForChild("HabitatZone") :: BasePart
local refill = site:WaitForChild("RefillStation") :: BasePart

local noWaterSince: { [Player]: number } = {}
local warned: { [Player]: { o2: boolean, water: boolean } } = {}
local lastRefill: { [Player]: number } = {} -- os.clock() de la última recarga (para explicar la muerte)

-- ¿Está el punto dentro de la caja de la parte?
local function inside(zone: BasePart, pos: Vector3): boolean
	local rel = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	return math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z
end

local function find(list, id)
	for _, x in list do
		if x.Id == id then return x end
	end
	return nil
end

-- Multiplicador de radiación (PDF Fase 3, 3.1)
local function radMult(): number
	local m = 1.5 -- sin hábitat colocado
	local spot = find(Config.Spots.cap, GS:GetAttribute("Spot_cap") or "")
	if spot then m = spot.RadMult end
	-- 16-nov: tormenta de radiación (B) y muro de provisiones: el multiplicador del hábitat pasa a ×0,5 ese día
	local shield = GS:GetAttribute("Mod_HabitatRadMult")
	if shield then m = math.min(m, shield) end
	if GS:GetAttribute("Choice_eng") == "reactor" and GS:GetAttribute("Spot_eng") == "next_lander" then
		m *= R.NoReactorNearMult
	end
	if GS:GetAttribute("Damaged_cap") then m *= 2 end
	if GS:GetAttribute("Blackout") == "habitat" then m *= R.BlackoutHabitatMult end
	return m
end

local function startBars(p: Player)
	p:SetAttribute("O2", GS:GetAttribute("StartO2") or 100)
	p:SetAttribute("Water", GS:GetAttribute("StartWater") or 100)
	p:SetAttribute("Radiation", 0)
	p:SetAttribute("Dead", false)
	p:SetAttribute("DeathWhy", nil)
	noWaterSince[p] = nil
	lastRefill[p] = nil
end

---------------------------------------------------------------------
-- Muerte y cinturón
---------------------------------------------------------------------
local belts = Instance.new("Folder")
belts.Name = "Belts"
belts.Parent = site

local function dropBelt(p: Player, pos: Vector3)
	local roles = string.split(p:GetAttribute("Roles") or "", ",")
	local belt = Instance.new("Part")
	belt.Name = "Belt_" .. p.Name
	belt.Shape = Enum.PartType.Cylinder
	belt.Orientation = Vector3.new(0, 0, 90)
	belt.Size = Vector3.new(0.4, 2.4, 2.4)
	belt.Anchored = true
	belt.CanCollide = false
	belt.Material = Enum.Material.Neon
	local main = Config.Roles[roles[1]]
	belt.Color = main and main.Color or Color3.new(1, 1, 1)
	belt.Position = Vector3.new(pos.X, site.Ground.Position.Y + 2.3, pos.Z)
	belt:SetAttribute("Roles", p:GetAttribute("Roles") or "")
	belt.Parent = belts

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = string.format(Config.Text3.PickBelt, p.DisplayName)
	prompt.HoldDuration = 1
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.Parent = belt
	prompt.Triggered:Connect(function(taker)
		if taker:GetAttribute("Dead") then return end
		-- El que lo recoge puede responder emergencias de esos roles (no revive al dueño)
		local have = taker:GetAttribute("Belts") or ""
		taker:SetAttribute("Belts", have == "" and belt:GetAttribute("Roles") or (have .. "," .. belt:GetAttribute("Roles")))
		belt:Destroy()
		Remotes.Toast:FireClient(taker, "You picked up a belt. You can answer that role's emergencies.", 3)
	end)
end

-- Razones de la muerte, de la que más explica a la que menos (la primera sale en el aviso y en la pantalla final)
local function deathReasons(p: Player, why: string, inLander: boolean, inHabitat: boolean, rad: number): { string }
	local T = Config.Text3
	local out = {}
	if not inLander and not inHabitat then
		table.insert(out, T.WhyOutside)
	elseif inLander then
		table.insert(out, T.WhyLander)
	end
	if why == "oxygen" and rad >= 100 then table.insert(out, T.WhyRad) end
	if why == "oxygen" and (GS:GetAttribute("Mod_O2Mult") or 1) > 1 then table.insert(out, T.WhyCO2) end
	if GS:GetAttribute("Phase") == "Phase3" then
		local key = why == "water" and "ReserveWater" or "ReserveO2"
		if (GS:GetAttribute(key) or 0) < 1 then
			table.insert(out, why == "water" and T.WhyReserveWater or T.WhyReserveO2)
		end
	end
	if why == "water" then table.insert(out, string.format(T.WhyNoWater, Config.Times.NoWaterGrace)) end
	if lastRefill[p] then
		table.insert(out, string.format(T.WhyLastRefill, math.floor(os.clock() - lastRefill[p])))
	else
		table.insert(out, T.WhyNeverRefill)
	end
	return out
end

local function kill(p: Player, why: string, reasons: { string }?)
	if p:GetAttribute("Dead") then return end
	p:SetAttribute("Dead", true)
	p:SetAttribute("DeathCause", why)
	p:SetAttribute("DeathWhy", table.concat(reasons or {}, "\n"))
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		dropBelt(p, root.Position)
		-- Espectador: invisible, sin colisión y quieto. La cámara la maneja el cliente (pendiente: seguir a un vivo).
		for _, d in char:GetDescendants() do
			if d:IsA("BasePart") then
				d.Transparency = 1
				d.CanCollide = false
			elseif d:IsA("Decal") then
				d.Transparency = 1
			end
		end
		root.Anchored = true
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
	end
	local first = reasons and reasons[1]
	Remotes.Toast:FireAllClients(p.DisplayName .. (why == "water" and " ran out of water." or " ran out of oxygen.")
		.. (first and (" " .. first) or ""), 5)
end

---------------------------------------------------------------------
-- Recarga en la nave
---------------------------------------------------------------------
local refillPrompt = Instance.new("ProximityPrompt")
refillPrompt.ActionText = Config.Text3.Refill
refillPrompt.HoldDuration = 2
refillPrompt.RequiresLineOfSight = false
refillPrompt.MaxActivationDistance = Config.PromptDistance
refillPrompt.Parent = refill

refillPrompt.Triggered:Connect(function(p)
	if p:GetAttribute("Dead") then return end
	local o2, water = p:GetAttribute("O2") or 0, p:GetAttribute("Water") or 0
	local needO2, needWater = 100 - o2, 100 - water
	-- Arreglo 15-nov: con las barras llenas antes salía "reserva vacía" aunque la reserva estuviera llena
	if needO2 + needWater < 1 then return end
	if GS:GetAttribute("Phase") == "Phase3" then
		-- En la Fase 3 la recarga sale de la reserva compartida (1 % de barra = 0,35 % de reserva)
		local byN = Config.Reserve.RefillCostByPlayers -- 16-nov: costo según cuántos jugadores hay
		local cost = byN and byN[math.clamp(#Players:GetPlayers(), 1, #byN)] or Config.Reserve.RefillCost
		local rO2, rW = GS:GetAttribute("ReserveO2") or 0, GS:GetAttribute("ReserveWater") or 0
		needO2 = math.min(needO2, rO2 / cost)
		needWater = math.min(needWater, rW / cost)
		if needO2 + needWater < 1 then
			Remotes.Toast:FireClient(p, Config.Text3.ReserveEmpty, 3)
			return
		end
		GS:SetAttribute("ReserveO2", rO2 - needO2 * cost)
		GS:SetAttribute("ReserveWater", rW - needWater * cost)
	end
	p:SetAttribute("O2", o2 + needO2)
	p:SetAttribute("Water", water + needWater)
	noWaterSince[p] = nil
	lastRefill[p] = os.clock()
end)

---------------------------------------------------------------------
-- Ciclo de 1 segundo
---------------------------------------------------------------------
local lastPhase = ""
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local phase = GS:GetAttribute("Phase")
	-- Al llegar a la Luna (o al saltar directo a una fase lunar) se inician las barras
	if ACTIVE_PHASES[phase] and not ACTIVE_PHASES[lastPhase] then
		for _, p in Players:GetPlayers() do startBars(p) end
	end
	lastPhase = phase
end)

Players.PlayerRemoving:Connect(function(p) noWaterSince[p] = nil; warned[p] = nil; lastRefill[p] = nil end)

while true do
	task.wait(1)
	local phase = GS:GetAttribute("Phase")
	if ACTIVE_PHASES[phase] and phase ~= "Landing" then
		local mult = radMult()
		local habitatBlackout = GS:GetAttribute("Blackout") == "habitat"
		for _, p in Players:GetPlayers() do
			if p:GetAttribute("Dead") or p:GetAttribute("O2") == nil then continue end
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then continue end
			local pos = root.Position
			local inLander = inside(landerZone, pos)
			local inHabitat = inside(habitatZone, pos)
			local indoors = inLander or inHabitat

			local rad = p:GetAttribute("Radiation")
			local radDelta
			if inHabitat then
				radDelta = (habitatBlackout or GS:GetAttribute("Mod_HabitatNoDrop")) and 0 or R.RadHabitatPerMin / 60
			elseif inLander then
				radDelta = R.RadLanderPerMin * mult / 60
			else
				radDelta = R.RadOutsidePerMin * mult * (GS:GetAttribute("Mod_RadOutMult") or 1) / 60
			end
			rad = math.clamp(rad + radDelta, 0, 100)

			local o2Rate = indoors and R.O2Inside or R.O2Outside
			o2Rate *= (GS:GetAttribute("Mod_O2Mult") or 1) -- emergencia CO2
			if rad >= 100 then o2Rate *= R.Rad100O2Mult end
			local waterRate = indoors and R.WaterInside or R.WaterOutside
			if phase ~= "Phase3" then -- fases 1 y 2: más lento
				o2Rate *= R.EarlyMult
				waterRate *= R.EarlyMult
			end

			local o2 = math.max(0, p:GetAttribute("O2") - o2Rate)
			local water = math.max(0, p:GetAttribute("Water") - waterRate)
			p:SetAttribute("Radiation", rad)
			p:SetAttribute("O2", o2)
			p:SetAttribute("Water", water)

			-- Aviso de barra baja (una vez hasta que se recargue)
			local w = warned[p] or { o2 = false, water = false }
			warned[p] = w
			if o2 < R.LowWarn and not w.o2 then w.o2 = true; Remotes.Toast:FireClient(p, Config.Text3.LowO2, 4) end
			if water < R.LowWarn and not w.water then w.water = true; Remotes.Toast:FireClient(p, Config.Text3.LowWater, 4) end
			if o2 > R.LowWarn + 10 then w.o2 = false end
			if water > R.LowWarn + 10 then w.water = false end

			if o2 <= 0 then
				kill(p, "oxygen", deathReasons(p, "oxygen", inLander, inHabitat, rad))
			elseif water <= 0 then
				noWaterSince[p] = noWaterSince[p] or os.clock()
				p:SetAttribute("NoWaterLeft", math.max(0, Config.Times.NoWaterGrace - (os.clock() - noWaterSince[p])))
				if os.clock() - noWaterSince[p] >= Config.Times.NoWaterGrace then
					kill(p, "water", deathReasons(p, "water", inLander, inHabitat, rad))
				end
			else
				noWaterSince[p] = nil
				p:SetAttribute("NoWaterLeft", nil)
			end
		end
	end
end
