-- CommsDelay (Script) -> ServerScriptService.CommsDelay
-- Dueño: Isaac + Claude (15-nov). El reto pide el retraso de comunicación: la luz tarda ~1,3 s de la Luna a la Tierra.
-- 1. Cada día de la Fase 3 llega un mensaje de Control de Misión: primero "viene en camino" y 1,3 s después el texto.
-- 2. En la antena (SO_CommsAntenna) cualquiera puede mantener E para llamar: la respuesta llega 2,6 s después
--    (ida y vuelta). Durante la llamarada solar sin arreglar, no hay señal.
-- Usa el Remote Toast que ya muestra Phase3HUD. Textos y números en Config.Comms.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local C = Config.Comms
local site = workspace:WaitForChild("MoonSite")

local msgIndex = 0
local function nextMessage(): string
	msgIndex = msgIndex % #C.Messages + 1
	return C.Messages[msgIndex]
end

-- ¿La llamarada solar está cortando la radio? (emergencia "flare" sin terminar)
local function radioDown(): boolean
	return GS:GetAttribute("Emergency") == "flare" and GS:GetAttribute("EmergencyStage") ~= "result"
end

local function inPhase3(): boolean
	return GS:GetAttribute("Phase") == "Phase3"
end

-- Mensaje diario
GS:GetAttributeChangedSignal("Day"):Connect(function()
	local day = GS:GetAttribute("Day") or 0
	if not inPhase3() or day < 1 then return end
	task.spawn(function()
		while inPhase3() and GS:GetAttribute("Day") == day
			and (Config.Phase3.DayLength - (GS:GetAttribute("DayTimeLeft") or 0)) < C.DailyAt do
			task.wait(0.5)
		end
		if not inPhase3() or GS:GetAttribute("Day") ~= day or radioDown() then return end
		-- no tapar una emergencia en curso: esperar a que termine (máx. 40 s)
		local t0 = os.clock()
		while (GS:GetAttribute("Emergency") or "") ~= "" and os.clock() - t0 < 40 do task.wait(0.5) end
		if not inPhase3() or GS:GetAttribute("Day") ~= day or radioDown() then return end
		Remotes.Toast:FireAllClients(string.format(C.Incoming, C.OneWay), C.OneWay + 0.6)
		task.wait(C.OneWay)
		Remotes.Toast:FireAllClients(string.format(C.Reply, C.OneWay * 2, nextMessage()), 6)
	end)
end)

-- Llamar desde la antena
local lastCall: { [Player]: number } = {}
local function setupPrompt()
	local ant = site:WaitForChild("SO_CommsAntenna", 60)
	local footing = ant and ant:WaitForChild("Footing", 10)
	if not footing or footing:FindFirstChild("SO_CallEarth") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SO_CallEarth"
	prompt.ActionText = C.Prompt
	prompt.ObjectText = C.Object
	prompt.HoldDuration = 1
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.Enabled = inPhase3()
	prompt.Parent = footing
	GS:GetAttributeChangedSignal("Phase"):Connect(function()
		prompt.Enabled = inPhase3()
	end)
	prompt.Triggered:Connect(function(p)
		if not inPhase3() or p:GetAttribute("Dead") then return end
		if os.clock() - (lastCall[p] or -999) < C.Cooldown then return end
		lastCall[p] = os.clock()
		if radioDown() then
			Remotes.Toast:FireClient(p, C.NoSignal, 4)
			return
		end
		Remotes.Toast:FireClient(p, string.format(C.Calling, C.OneWay), C.OneWay * 2 + 0.5)
		task.wait(C.OneWay * 2)
		if p.Parent then
			Remotes.Toast:FireClient(p, string.format(C.Reply, C.OneWay * 2, nextMessage()), 6)
		end
	end)
end
task.spawn(setupPrompt)
-- Si la antena se reconstruye (otra partida), volver a poner el prompt
site.ChildAdded:Connect(function(c)
	if c.Name == "SO_CommsAntenna" then task.delay(1, setupPrompt) end
end)
Players.PlayerRemoving:Connect(function(p) lastCall[p] = nil end)
