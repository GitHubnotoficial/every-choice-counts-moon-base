-- Resources (Script) -> ServerScriptService.Resources
-- Dueño: Isaac + Claude. Fase 3: reserva de la base (O2 y agua), comida, cosechas y apagones (PDF Fase 3, cap. 3).
-- Escucha a DayCycle por atributos: Day (empieza un día) y DayEndCount (termina un día).
-- Escribe: ReserveO2, ReserveWater, Food, Blackout, Harvests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Energy = require(ReplicatedStorage:WaitForChild("Energy"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local TRAY_TAG = "SO_Tray" -- Larry (Fase 2) etiqueta cada bandeja sembrada con este tag y Planted = true
local blackoutTurn = 0

local function inPhase3(): boolean
	return GS:GetAttribute("Phase") == "Phase3"
end

-- Energía generada y pedida (+ calefacción de la emergencia, si está activa). Arreglo 15-nov:
-- antes, al dañarse o repararse algo se perdía la energía extra de la calefacción.
local function recalcEnergy(): (number, number)
	local made, used = Energy.calc(GS)
	used += GS:GetAttribute("Mod_ExtraEnergy") or 0
	GS:SetAttribute("EnergyMade", made)
	GS:SetAttribute("EnergyUsed", used)
	return made, used
end

local onDayStart: () -> () -- se define más abajo

---------------------------------------------------------------------
-- Inicio de la Fase 3
---------------------------------------------------------------------
local function startResources()
	local life = GS:GetAttribute("Choice_life")
	local m = Config.Reserve.Machines[life] or Config.Reserve.Machines.recycler
	GS:SetAttribute("ReserveO2", m.Start)
	GS:SetAttribute("ReserveWater", m.Start)

	local bot = GS:GetAttribute("Choice_bot")
	local food = Config.Food.Start[bot] or 2
	if bot == "packaged" and GS:GetAttribute("MissionComplete_bot") then
		food += Config.Food.CountedBonus
	end
	GS:SetAttribute("Food", food)
	GS:SetAttribute("Blackout", "")
	GS:SetAttribute("Harvests", 0)
	GS:SetAttribute("MachineProdMult", 1) -- 15-nov: el polvo la baja el resto del juego (PDF Fase 3)
	GS:SetAttribute("NextWalkMinus", nil)
	blackoutTurn = 0

	recalcEnergy()

	-- Respaldo: si la Fase 2 no marcó las bandejas como sembradas, se marcan las del invernadero colocado
	-- (una menos si el cultivo quedó dañado). Placement pone 2, 4 o 6 bandejas según el lugar.
	if #CollectionService:GetTagged(TRAY_TAG) == 0 and bot ~= "packaged" then
		local site = workspace:FindFirstChild("MoonSite")
		local placed = site and site:FindFirstChild("Placed")
		local gh = placed and placed:FindFirstChild("bot")
		if gh then
			local n = 0
			for _, d in gh:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Tray" then
					n += 1
					if not (GS:GetAttribute("Damaged_bot") and n == 1) then
						d:SetAttribute("Planted", true)
						CollectionService:AddTag(d, TRAY_TAG)
					end
				end
			end
		end
	end

	-- Bandejas: empiezan a crecer
	for _, tray in CollectionService:GetTagged(TRAY_TAG) do
		if tray:GetAttribute("Planted") then
			local first = bot == "regolith_kit" and Config.Harvest.RegolithFirstMult or 1
			tray:SetAttribute("GrowLeft", Config.Harvest.GrowTime * first)
		end
	end

	-- Arreglo 15-nov: si DayCycle ya puso Day = 1 antes que este script, el apagón del día 1
	-- se borraba arriba (Blackout = ""). Se vuelve a revisar aquí.
	if (GS:GetAttribute("Day") or 0) >= 1 then
		onDayStart()
	end
end

---------------------------------------------------------------------
-- Empieza un día: ¿apagón?
---------------------------------------------------------------------
onDayStart = function()
	if not inPhase3() then return end
	local made, used = recalcEnergy()
	if used > made then
		blackoutTurn += 1
		local order = Config.BlackoutOrder
		local system = order[((blackoutTurn - 1) % #order) + 1]
		GS:SetAttribute("Blackout", system)
		Remotes.Toast:FireAllClients(string.format(Config.Text3.Blackout, Config.BlackoutNames[system]), 4)
	else
		GS:SetAttribute("Blackout", "")
	end
end

---------------------------------------------------------------------
-- Termina un día: comida y producción de la máquina
---------------------------------------------------------------------
local function onDayEnd()
	-- DayEndCount = 0 es el reinicio al empezar la fase, no el fin de un día
	if not inPhase3() or (GS:GetAttribute("DayEndCount") or 0) < 1 then return end
	-- Comida
	GS:SetAttribute("Food", math.max(0, (GS:GetAttribute("Food") or 0) - Config.Food.PerDay))

	-- Producción de la máquina de Life Support
	if GS:GetAttribute("Blackout") ~= "machine" and not GS:GetAttribute("Mod_MachineOff") then
		local m = Config.Reserve.Machines[GS:GetAttribute("Choice_life")]
		if m then
			local mult = 1
			if not GS:GetAttribute("MissionComplete_life") then mult *= Config.Reserve.NoMissionMult end
			if GS:GetAttribute("Damaged_life") then mult *= Config.Reserve.DamagedMult end
			-- 15-nov: polvo (resto del juego) y tormentas (ese día) bajan la producción
			mult *= (GS:GetAttribute("MachineProdMult") or 1) * (GS:GetAttribute("Mod_MachineMult") or 1)
			GS:SetAttribute("ReserveO2", math.min(100, GS:GetAttribute("ReserveO2") + m.O2 * mult))
			GS:SetAttribute("ReserveWater", math.min(100, GS:GetAttribute("ReserveWater") + m.Water * mult))
		end
	end
end

---------------------------------------------------------------------
-- Nave de carga (día 4): +15 % a las reservas
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("CargoArrived"):Connect(function()
	if GS:GetAttribute("CargoArrived") and inPhase3() then
		local b = Config.Phase3.CargoBonus
		GS:SetAttribute("ReserveO2", math.min(100, GS:GetAttribute("ReserveO2") + b))
		GS:SetAttribute("ReserveWater", math.min(100, GS:GetAttribute("ReserveWater") + b))
	end
end)

---------------------------------------------------------------------
-- Cosechas: cada bandeja crece en 2,5 min, brilla y se cosecha con E 3 s
---------------------------------------------------------------------
local function setupTray(tray: BasePart)
	if tray:FindFirstChild("HarvestPrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HarvestPrompt"
	prompt.ActionText = Config.Text3.Harvest
	prompt.HoldDuration = Config.Harvest.Hold
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.Enabled = false
	prompt.Parent = tray
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Dead") or (tray:GetAttribute("GrowLeft") or 1) > 0 then return end
		GS:SetAttribute("Food", (GS:GetAttribute("Food") or 0) + Config.Food.Harvest)
		GS:SetAttribute("ReserveO2", math.min(100, (GS:GetAttribute("ReserveO2") or 0) + Config.Reserve.HarvestO2))
		GS:SetAttribute("Harvests", (GS:GetAttribute("Harvests") or 0) + 1)
		tray:SetAttribute("GrowLeft", Config.Harvest.GrowTime)
		tray.Material = Enum.Material.SmoothPlastic
		prompt.Enabled = false
	end)
end

-- 15-nov: cada bandeja sembrada muestra un cultivo real (lechuga, fresas, camote o tomates enanos, modelos de
-- ServerStorage.SO_MoonProps.Crops) que crece de chico a grande mientras baja GrowLeft. Si se pierde, desaparece.
local CROP_NAMES = { "Lettuce", "Strawberry", "SweetPotato", "DwarfTomato" }
local cropCount = 0
local function cropFolder(): Instance?
	local props = game:GetService("ServerStorage"):FindFirstChild("SO_MoonProps")
	return props and props:FindFirstChild("Crops")
end
local function setCropSize(tray: BasePart)
	local crop = tray:FindFirstChild("SO_Crop") :: Model?
	if not crop then return end
	local full = crop:GetAttribute("FullScale") or 1
	local left = tray:GetAttribute("GrowLeft") or 0
	local k = 1 - math.clamp(left / Config.Harvest.GrowTime, 0, 1)
	crop:ScaleTo(full * (0.35 + 0.65 * k))
	local rot = crop:GetAttribute("Rot90") and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()
	crop:PivotTo(tray.CFrame * CFrame.new(0, tray.Size.Y / 2, 0) * rot)
end
local function addCrop(tray: BasePart)
	local folder = cropFolder()
	if not folder or tray:FindFirstChild("SO_Crop") or not tray:GetAttribute("Planted") then return end
	cropCount += 1
	local tpl = folder:FindFirstChild(CROP_NAMES[(cropCount - 1) % #CROP_NAMES + 1]) :: Model?
	if not tpl then return end
	local crop = tpl:Clone()
	crop.Name = "SO_Crop"
	local _, size = crop:GetBoundingBox()
	-- que ocupe la bandeja a lo largo (eje más largo de la bandeja)
	local full = math.max(tray.Size.X, tray.Size.Z) * 0.9 / math.max(size.X, 0.1)
	crop:ScaleTo(crop:GetScale() * full)
	crop:SetAttribute("FullScale", crop:GetScale())
	crop:SetAttribute("Rot90", tray.Size.Z > tray.Size.X)
	crop.Parent = tray
	setCropSize(tray)
end
local function removeCrop(tray: Instance)
	local c = tray:FindFirstChild("SO_Crop")
	if c then c:Destroy() end
end

for _, t in CollectionService:GetTagged(TRAY_TAG) do setupTray(t); addCrop(t) end
CollectionService:GetInstanceAddedSignal(TRAY_TAG):Connect(function(t)
	setupTray(t)
	addCrop(t)
end)
CollectionService:GetInstanceRemovedSignal(TRAY_TAG):Connect(removeCrop)

---------------------------------------------------------------------
-- Escuchar a DayCycle y a GameManager
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if inPhase3() then startResources() end
end)
GS:GetAttributeChangedSignal("Day"):Connect(onDayStart)
GS:GetAttributeChangedSignal("DayEndCount"):Connect(onDayEnd)

-- Recalcular energía si se repara/daña algo durante la fase
for _, r in Config.RoleOrder do
	GS:GetAttributeChangedSignal("Damaged_" .. r):Connect(function()
		if inPhase3() then
			recalcEnergy()
		end
	end)
end

-- Calefacción (noche helada): pide energía extra el resto del día
GS:GetAttributeChangedSignal("Mod_ExtraEnergy"):Connect(function()
	if inPhase3() then
		recalcEnergy()
	end
end)

-- Ciclo de 1 s: crecimiento de bandejas y hambre
while true do
	task.wait(1)
	if inPhase3() then
		local grows = GS:GetAttribute("Blackout") ~= "greenhouse" and not GS:GetAttribute("Mod_GreenhouseOff") and not GS:GetAttribute("Mod_TraysNoGrow")
		for _, tray in CollectionService:GetTagged(TRAY_TAG) do
			local left = tray:GetAttribute("GrowLeft")
			if left == nil and tray:GetAttribute("Planted") then -- marcada después de empezar la fase
				left = Config.Harvest.GrowTime * (GS:GetAttribute("Choice_bot") == "regolith_kit" and Config.Harvest.RegolithFirstMult or 1)
				tray:SetAttribute("GrowLeft", left)
			end
			if tray:GetAttribute("Planted") and not tray:FindFirstChild("SO_Crop") then addCrop(tray) end
			if left and left > 0 and grows then
				left -= 1
				tray:SetAttribute("GrowLeft", left)
				if left % 5 == 0 then setCropSize(tray) end -- la planta crece de a poco
				if left <= 0 then
					tray.Material = Enum.Material.Neon -- lista: brilla
					local pr = tray:FindFirstChild("HarvestPrompt")
					if pr then pr.Enabled = true end
				end
			end
		end
		-- Sin comida: todos caminan a 10
		local hungry = (GS:GetAttribute("Food") or 0) <= 0 or GS:GetAttribute("Mod_SlowWalk") == true
		for _, p in Players:GetPlayers() do
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum and not p:GetAttribute("Dead") then
				-- 15-nov: músculos débiles = 2 o 4 puntos más lento (mínimo 8); sin comida, 10
				local speed = math.max(8, 16 - (GS:GetAttribute("Mod_WalkMinus") or 0))
				if hungry then speed = math.min(speed, Config.Food.HungrySpeed) end
				hum.WalkSpeed = speed
			end
		end
	end
end
