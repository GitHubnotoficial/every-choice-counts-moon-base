-- GameManager (Script) -> ServerScriptService.GameManager
-- Dueño: Isaac + Claude. Crea GameState y Remotes, y lleva el orden de las fases con su reloj.
-- Regla del contrato: SOLO este script escribe GameState.Phase y GameState.TimeLeft.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

---------------------------------------------------------------------
-- 1. Crear GameState y Remotes (los demás scripts los esperan con WaitForChild)
---------------------------------------------------------------------
local GS = ReplicatedStorage:FindFirstChild("GameState") or Instance.new("Folder")
GS.Name = "GameState"
GS.Parent = ReplicatedStorage

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local REMOTE_NAMES = {
	"RequestRole", "ReadyUp", "PlayPressed", "ShowProsCons", "HideProsCons", "Launch",
	"SiteNav", "SiteChoose", "SiteSuggest", "Toast", "Fact", "EmergencyAnswer", "MoonLight", "DebugSkip",
}
for _, name in REMOTE_NAMES do
	if not Remotes:FindFirstChild(name) then
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = Remotes
	end
end

local ROLES = Config.RoleOrder

-- Pone todos los atributos en su valor inicial (al arrancar y con TRY AGAIN / PLAY AGAIN)
local function resetState()
	for _, r in ROLES do
		GS:SetAttribute("Choice_" .. r, "")
		GS:SetAttribute("Spot_" .. r, "")
		GS:SetAttribute("Damaged_" .. r, false)
		GS:SetAttribute("MissionComplete_" .. r, false)
		GS:SetAttribute("Mission_" .. r .. "_Done", 0)
		GS:SetAttribute("Mission_" .. r .. "_Total", 0)
	end
	for _, s in Config.Sites do
		GS:SetAttribute("Suggest_" .. s.Id, "")
	end
	GS:SetAttribute("ReadyCount", 0)
	GS:SetAttribute("CargoUsed", 0)
	GS:SetAttribute("CargoCapacity", 0)
	GS:SetAttribute("PenaltyPct", 0)
	GS:SetAttribute("StartO2", 100)
	GS:SetAttribute("StartWater", 100)
	GS:SetAttribute("Launched", false)
	GS:SetAttribute("SiteCursor", "nobile")
	GS:SetAttribute("Site", "")
	GS:SetAttribute("Landed", false)
	GS:SetAttribute("AllPlaced", false)
	GS:SetAttribute("EnergyMade", 0)
	GS:SetAttribute("EnergyUsed", 0)
	GS:SetAttribute("Day", 0)
	GS:SetAttribute("DayTimeLeft", 0)
	GS:SetAttribute("CargoArrived", false)
	GS:SetAttribute("Emergency", "")
	GS:SetAttribute("EmergencyStage", "")
	GS:SetAttribute("Result", "")
	for _, p in Players:GetPlayers() do
		p:SetAttribute("Dead", false)
	end
end

---------------------------------------------------------------------
-- 2. Ayudantes de tiempo y READY
---------------------------------------------------------------------
local readySet: { [Player]: boolean } = {}

local function clearReady()
	table.clear(readySet)
	GS:SetAttribute("ReadyCount", 0)
end

Remotes.ReadyUp.OnServerEvent:Connect(function(player)
	readySet[player] = true
	local n = 0
	for p in readySet do
		if p.Parent then n += 1 end
	end
	GS:SetAttribute("ReadyCount", n)
end)

local function allReady(): boolean
	local total = #Players:GetPlayers()
	return total > 0 and GS:GetAttribute("ReadyCount") >= total
end

local playPressed = false
Remotes.PlayPressed.OnServerEvent:Connect(function()
	playPressed = true
end)

local function seconds(t: number): number
	if Config.Debug.FastTimers and t > 10 then
		return 10
	end
	return t
end

-- Pone la fase y corre su reloj. Termina al llegar a 0 o cuando stopWhen() devuelve true.
-- Devuelve true si terminó por stopWhen.
local function runPhase(phase: string, duration: number?, stopWhen: (() -> boolean)?): boolean
	clearReady()
	GS:SetAttribute("Phase", phase)
	if not duration then
		GS:SetAttribute("TimeLeft", 0)
		while not (stopWhen and stopWhen()) do
			task.wait(0.25)
		end
		return true
	end
	local left = seconds(duration)
	GS:SetAttribute("TimeLeft", left)
	local acc = 0
	while left > 0 do
		if stopWhen and stopWhen() then
			return true
		end
		acc += task.wait(0.25)
		if acc >= 1 then
			acc -= 1
			left -= 1
			GS:SetAttribute("TimeLeft", left)
		end
	end
	return stopWhen ~= nil and stopWhen() or false
end

---------------------------------------------------------------------
-- 3. Carga y castigo (Fase 0 → 1)
---------------------------------------------------------------------
local function findOption(role: string, id: string)
	for _, o in Config.Options[role] do
		if o.Id == id then return o end
	end
	return nil
end

-- Rellena al azar quien no eligió y calcula carga, castigo y O2/agua iniciales
local function finishPhase0()
	for _, r in ROLES do
		if GS:GetAttribute("Choice_" .. r) == "" then
			local list = Config.Options[r]
			GS:SetAttribute("Choice_" .. r, list[math.random(1, #list)].Id)
		end
	end
	local ship = findOption("cap", GS:GetAttribute("Choice_cap"))
	local used = 0
	for _, r in { "eng", "life", "bot" } do
		local o = findOption(r, GS:GetAttribute("Choice_" .. r))
		used += (o and o.Weight or 0)
	end
	local capacity = ship and ship.Capacity or 100
	local excess = math.max(0, used - capacity)
	local pct = math.ceil(excess / 10) * Config.Overload.PercentPer10 + (ship and ship.LateSolPenalty or 0)
	local start = math.max(Config.Overload.MinStart, 100 - pct)
	GS:SetAttribute("CargoUsed", used)
	GS:SetAttribute("CargoCapacity", capacity)
	GS:SetAttribute("PenaltyPct", pct)
	GS:SetAttribute("StartO2", start)
	GS:SetAttribute("StartWater", start)
end

---------------------------------------------------------------------
-- 4. Depuración: saltar a una fase con datos falsos
---------------------------------------------------------------------
local ORDER = { "Title", "RoleSelect", "Briefing", "Phase0", "SiteSelect", "Placement", "Phase2", "Phase3" }

local function applyFakeState()
	for k, v in Config.Debug.FakeState do
		GS:SetAttribute(k, v)
	end
end

local skipRequested = false
Remotes.DebugSkip.OnServerEvent:Connect(function(_player, what)
	if not RunService:IsStudio() then return end -- solo en Studio
	if what == "phase" then
		skipRequested = true
	end
end)

-- ¿Murieron todos? (en la Luna, antes de la Fase 3; la Fase 3 la maneja DayCycle)
local function allDead(): boolean
	local list = Players:GetPlayers()
	if #list == 0 then return false end
	for _, p in list do
		if not p:GetAttribute("Dead") then return false end
	end
	return true
end

local function orSkip(fn: (() -> boolean)?): () -> boolean
	return function()
		if allDead() then return true end
		if skipRequested then
			skipRequested = false
			return true
		end
		return fn ~= nil and fn() or false
	end
end

---------------------------------------------------------------------
-- 5. Ciclo de la partida
---------------------------------------------------------------------
local function waitForPlayers()
	while #Players:GetPlayers() == 0 do
		task.wait(0.5)
	end
end

local function playRound(startAt: string?)
	resetState()
	local skipTo = startAt and table.find(ORDER, startAt) or 1
	-- Datos falsos solo si saltamos más allá de la Fase 0 (para probar la 1, 2 o 3 solas)
	if skipTo >= 5 then
		applyFakeState()
	end
	local function reached(name: string): boolean
		return (table.find(ORDER, name) :: number) >= skipTo
	end

	-- Título: espera PLAY de cualquiera
	if reached("Title") and skipTo == 1 then
		playPressed = false
		runPhase("Title", nil, orSkip(function() return playPressed end))
	end

	-- Elección de rol (30 s). RolesAndSuits reparte los libres al salir de esta fase.
	if reached("RoleSelect") and skipTo <= 2 then
		runPhase("RoleSelect", Config.Times.RoleSelect, orSkip(allReady)) -- 15-nov: si todos tienen rol y pulsan READY, se pasa antes
	end

	-- Briefing (20 s o todos READY)
	if reached("Briefing") and skipTo <= 3 then
		runPhase("Briefing", Config.Times.Briefing, orSkip(allReady))
	end

	-- Fase 0: elegir (1:30) y lanzar (15 s)
	if skipTo <= 4 then
		-- 15-nov: si los 4 roles ya eligieron y todos pulsan READY, se pasa antes
		runPhase("Phase0", Config.Times.Phase0Decide, orSkip(function()
			for _, r in ROLES do
				if (GS:GetAttribute("Choice_" .. r) or "") == "" then return false end
			end
			return allReady()
		end))
		finishPhase0()
		GS:SetAttribute("Launched", false)
		local launched = runPhase("Launch", Config.Times.LaunchWindow, orSkip(function()
			return GS:GetAttribute("Launched") == true
		end))
		if not launched then
			-- Mal final: la nave se fue sin ellos
			runPhase("Failed", nil, allReady)
			return
		end
		runPhase("Transition01", Config.Times.Transition, orSkip(allReady))
	end

	-- Fase 1: sitio (1:00) → aterrizaje → colocación (5:00)
	if skipTo <= 5 then
		runPhase("SiteSelect", Config.Times.SiteSelect, orSkip(function()
			return GS:GetAttribute("Site") ~= ""
		end))
		-- Si nadie eligió, Phase1Manager pone un sitio al azar; aquí esperamos como máximo 3 s
		local t0 = os.clock()
		while GS:GetAttribute("Site") == "" and os.clock() - t0 < 3 do task.wait(0.2) end
		if GS:GetAttribute("Site") == "" then
			GS:SetAttribute("Site", Config.Sites[math.random(1, #Config.Sites)].Id)
		end
		runPhase("Landing", 8, orSkip(function() return GS:GetAttribute("Landed") == true end))
	end
	-- Si muere toda la tripulación antes de la Fase 3: pantalla final de derrota
	local function crewLost(): boolean
		if allDead() then
			GS:SetAttribute("Result", "lost")
			runPhase("End", nil, allReady)
			return true
		end
		return false
	end

	if skipTo <= 6 then
		-- Termina antes si Placement (Leticia) marca AllPlaced: 10 s después de colocar los 4 objetos
		runPhase("Placement", Config.Times.Placement, orSkip(function() return GS:GetAttribute("AllPlaced") == true end))
		if crewLost() then return end
		runPhase("Transition12", Config.Times.Transition, orSkip(allReady))
	end

	-- Fase 2: inicio (10 s) y misiones (4:00)
	if skipTo <= 7 then
		runPhase("Phase2Intro", Config.Times.Phase2Intro, orSkip(allReady))
		-- Termina 10 s después de que las 4 misiones estén completas (antes se esperaban siempre los 4:00)
		local doneSince: number? = nil
		runPhase("Phase2", Config.Times.Phase2, orSkip(function()
			for _, r in ROLES do
				if not GS:GetAttribute("MissionComplete_" .. r) then
					doneSince = nil
					return false
				end
			end
			if not doneSince then
				doneSince = os.clock()
				Remotes.Toast:FireAllClients(Config.Text.Phase2EndsSoon, 4)
			end
			return os.clock() - doneSince >= 10
		end))
		if crewLost() then return end
		runPhase("Transition23", Config.Times.Transition, orSkip(allReady))
	end

	-- Fase 3: DayCycle lleva los días y escribe Result ("won" / "lost")
	GS:SetAttribute("Result", "")
	-- Aquí NO se usa allDead: el que decide la derrota es DayCycle (escribe Result = "lost").
	-- Si se cortara antes, la pantalla final saldría sin resultado y nadie podría seguir.
	runPhase("Phase3", nil, function()
		if skipRequested then
			skipRequested = false
			return true
		end
		return GS:GetAttribute("Result") ~= ""
	end)
	if GS:GetAttribute("Result") == "" then
		-- Respaldo (salto de prueba o caso raro): nunca llegar a la pantalla final sin resultado
		GS:SetAttribute("Result", allDead() and "lost" or "won")
	end
	if GS:GetAttribute("Result") == "won" then
		runPhase("Rescue", Config.Phase3.RescueTime, nil)
	end
	-- Pantalla final: PLAY AGAIN / TRY AGAIN = ReadyUp de todos
	runPhase("End", nil, allReady)
end

waitForPlayers()
task.wait(1)
local firstStart = RunService:IsStudio() and Config.Debug.StartPhase or nil
playRound(firstStart)
while true do
	-- Después de cada partida se vuelve a elegir rol (no al título)
	playRound("RoleSelect")
end
