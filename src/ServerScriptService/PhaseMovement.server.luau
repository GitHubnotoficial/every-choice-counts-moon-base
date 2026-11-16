-- PhaseMovement (Script) -> ServerScriptService.PhaseMovement
-- Dueño: Isaac + Claude. Quién se puede mover y dónde aparece cada jugador según la fase.
-- - En pantallas 2D (título, roles, briefing, transiciones, final) el personaje queda quieto (no se cae del spawn).
-- - En la Fase 0, si todavía no existe Workspace.EarthBase (de Yamir), crea un piso temporal SOLO en Play.
-- - En las fases lunares, quien reaparece sale junto a la nave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")

local FROZEN = {
	[""] = true, Title = true, RoleSelect = true, Briefing = true, Failed = true,
	Transition01 = true, SiteSelect = true, Landing = true, Transition12 = true,
	Phase2Intro = true, Transition23 = true, End = true,
}
local MOON = { Landing = true, Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true, Rescue = true, End = true }

local function setFrozen(char: Model?, frozen: boolean)
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then root.Anchored = frozen end
end

-- Piso temporal de la Tierra (se borra solo cuando Yamir agregue EarthBase)
local function ensureEarthFloor()
	if workspace:FindFirstChild("EarthBase") or workspace:FindFirstChild("SO_TempEarthFloor") then return end
	local floor = Instance.new("Part")
	floor.Name = "SO_TempEarthFloor"
	floor.Size = Vector3.new(200, 2, 200)
	floor.Position = Config.Zones.Earth + Vector3.new(0, -1, 0)
	floor.Anchored = true
	floor.Color = Color3.fromHex("D9D2F5")
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
end

local function applyPhase()
	local phase = GS:GetAttribute("Phase") or ""
	if phase == "Phase0" or phase == "Launch" then ensureEarthFloor() end
	-- Los muertos siguen anclados (espectadores); no los soltamos
	for _, p in Players:GetPlayers() do
		if not p:GetAttribute("Dead") then
			setFrozen(p.Character, FROZEN[phase] == true)
		end
	end
end

GS:GetAttributeChangedSignal("Phase"):Connect(applyPhase)

local function onPlayer(p: Player)
	p.CharacterAdded:Connect(function(char)
		local phase = GS:GetAttribute("Phase") or ""
		char:WaitForChild("HumanoidRootPart", 5)
		if MOON[phase] then
			local site = workspace:FindFirstChild("MoonSite")
			local spawn = site and site:FindFirstChild("LanderSpawn")
			if spawn then char:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 3, 0))) end
		end
		task.defer(function()
			if not p:GetAttribute("Dead") then setFrozen(char, FROZEN[phase] == true) end
		end)
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end

applyPhase()
