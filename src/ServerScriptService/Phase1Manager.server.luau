-- Phase1Manager (Script) -> ServerScriptService.Phase1Manager
-- Fase 1 en el servidor: elegir el sitio (SiteSelect) y aterrizar (Landing). PDF Fase 1, caps. 3 y 4.
-- Lee:     GameState.Phase (lo escribe GameManager), Role_<rol>, Choice_<rol>.
-- Escribe: SiteCursor, Site, Suggest_<sitio> ("eng,bot"), RoughLanding, Landed.
-- La colocación (Placement) está en el script Placement.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Fases que pasan en la Luna (gravedad lunar y salto más alto)
local MOON_PHASES = {
	Landing = true, Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true,
	Transition23 = true, Phase3 = true, Rescue = true,
}
-- Fases en la Tierra (se vuelve a la gravedad normal)
local EARTH_PHASES = { Title = true, RoleSelect = true, Briefing = true, Phase0 = true, Launch = true }

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
-- ¿El jugador tiene este rol? (puede tener varios si son menos de 4)
local function hasRole(player: Player, role: string): boolean
	local roles = string.split(player:GetAttribute("Roles") or "", ",")
	return table.find(roles, role) ~= nil
end

local function siteIndex(id: string): number?
	for i, s in Config.Sites do
		if s.Id == id then
			return i
		end
	end
	return nil
end

local function siteById(id: string)
	local i = siteIndex(id)
	return i and Config.Sites[i] or nil
end

local function phase(): string
	return GS:GetAttribute("Phase") or ""
end

local function canPickSite(): boolean
	return phase() == "SiteSelect" and (GS:GetAttribute("Site") or "") == ""
end

---------------------------------------------------------------------
-- 1. ELEGIR EL SITIO
---------------------------------------------------------------------
-- El Captain mueve la Luna: +1 / -1 (flechas) o el id de un sitio
Remotes.SiteNav.OnServerEvent:Connect(function(player, step)
	if not canPickSite() or not hasRole(player, "cap") then
		return
	end
	local i = siteIndex(GS:GetAttribute("SiteCursor") or "") or 1
	if typeof(step) == "number" then
		local n = #Config.Sites
		i = ((i - 1 + (step > 0 and 1 or -1)) % n) + 1
	elseif typeof(step) == "string" and siteIndex(step) then
		i = siteIndex(step) :: number
	else
		return
	end
	GS:SetAttribute("SiteCursor", Config.Sites[i].Id)
end)

-- CHOOSE: solo el Captain. La elección es final.
Remotes.SiteChoose.OnServerEvent:Connect(function(player, id)
	if not canPickSite() or not hasRole(player, "cap") then
		return
	end
	if typeof(id) ~= "string" or not siteById(id) then
		id = GS:GetAttribute("SiteCursor")
	end
	if siteById(id) then
		GS:SetAttribute("Site", id)
	end
end)

-- SUGGEST: cada rol que no es Captain marca un sitio (uno por rol)
Remotes.SiteSuggest.OnServerEvent:Connect(function(player, id)
	if not canPickSite() or typeof(id) ~= "string" or not siteById(id) then
		return
	end
	local site = siteById(id)
	for _, role in Config.RoleOrder do
		if role ~= "cap" and hasRole(player, role) then
			-- Quitar la sugerencia anterior de este rol
			for _, s in Config.Sites do
				local list = string.split(GS:GetAttribute("Suggest_" .. s.Id) or "", ",")
				local at = table.find(list, role)
				if at then
					table.remove(list, at)
					GS:SetAttribute("Suggest_" .. s.Id, table.concat(list, ","))
				end
			end
			-- Poner la nueva
			local list = string.split(GS:GetAttribute("Suggest_" .. id) or "", ",")
			if list[1] == "" then
				table.remove(list, 1)
			end
			table.insert(list, role)
			GS:SetAttribute("Suggest_" .. id, table.concat(list, ","))
			Remotes.Toast:FireAllClients(string.format(P1.Text.Suggests, Config.Roles[role].Name, site.Name), 2.5)
		end
	end
end)

---------------------------------------------------------------------
-- 2. GRAVEDAD Y SALTO
---------------------------------------------------------------------
local function setJump(char: Model?, height: number)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = false
		hum.JumpHeight = height
	end
end

local function applyGravity()
	local p = phase()
	if MOON_PHASES[p] then
		workspace.Gravity = Config.Gravity.Moon
		for _, pl in Players:GetPlayers() do
			setJump(pl.Character, P1.MoonJumpHeight)
		end
	elseif EARTH_PHASES[p] then
		workspace.Gravity = Config.Gravity.Earth
		for _, pl in Players:GetPlayers() do
			setJump(pl.Character, P1.EarthJumpHeight)
		end
	end
end

Players.PlayerAdded:Connect(function(pl)
	pl.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 5)
		setJump(char, MOON_PHASES[phase()] and P1.MoonJumpHeight or P1.EarthJumpHeight)
	end)
end)

---------------------------------------------------------------------
-- 3. ATERRIZAR
---------------------------------------------------------------------
-- Lleva a todos los vivos junto a la rampa de la nave
local function bringEveryoneToLander()
	local site = workspace:FindFirstChild("MoonSite")
	local spawn = site and site:FindFirstChild("LanderSpawn")
	if not spawn then
		warn("Phase1Manager: no encuentro MoonSite.LanderSpawn")
		return
	end
	for i, pl in Players:GetPlayers() do
		local char = pl.Character
		if char and not pl:GetAttribute("Dead") then
			char:PivotTo(CFrame.new(spawn.Position + Vector3.new((i - 2.5) * 4, 3, 0)))
		end
	end
end

local landingToken = 0
local function startLanding()
	landingToken += 1
	local my = landingToken
	GS:SetAttribute("Landed", false)

	local site = siteById(GS:GetAttribute("Site") or "")
	-- Terreno (barra 4) menor que 5: la nave queda inclinada
	local rough = site ~= nil and site.Scores[4] < Config.RoughTerrainBelow
	GS:SetAttribute("RoughLanding", rough)

	bringEveryoneToLander()

	-- Tiempo de la animación de bajada (la pantalla la muestra Phase1UI)
	task.wait(Config.Times.LandingAnim)
	if my ~= landingToken or phase() ~= "Landing" then
		return
	end

	if rough then
		-- Bars ya puso O2 = StartO2 al empezar Landing; aquí se resta el 5 %
		for _, pl in Players:GetPlayers() do
			local o2 = pl:GetAttribute("O2")
			if o2 then
				pl:SetAttribute("O2", math.max(0, o2 - Config.RoughLandingO2))
			end
		end
		Remotes.Toast:FireAllClients(Config.Text.RoughLanding, 4)
	end
	GS:SetAttribute("Landed", true)
end

-- Si se salta directo a la colocación (Debug), igual hay que estar en la Luna
local function ensureOnMoon()
	local site = workspace:FindFirstChild("MoonSite")
	local spawn = site and site:FindFirstChild("LanderSpawn")
	if not spawn then
		return
	end
	for _, pl in Players:GetPlayers() do
		local root = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - spawn.Position).Magnitude > 600 then
			pl.Character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 3, 0)))
		end
	end
end

---------------------------------------------------------------------
-- 4. Reaccionar a los cambios de fase
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local p = phase()
	applyGravity()
	if p == "SiteSelect" then
		-- Empieza en NOBILE, sin sugerencias
		if (GS:GetAttribute("SiteCursor") or "") == "" then
			GS:SetAttribute("SiteCursor", "nobile")
		end
		for _, s in Config.Sites do
			GS:SetAttribute("Suggest_" .. s.Id, "")
		end
		GS:SetAttribute("RoughLanding", false)
	elseif p == "Landing" then
		task.spawn(startLanding)
	elseif p == "Placement" then
		ensureOnMoon()
	end
end)

applyGravity()
