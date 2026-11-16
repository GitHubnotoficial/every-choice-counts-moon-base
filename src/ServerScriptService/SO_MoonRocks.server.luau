-- SO_MoonRocks (Script) -> ServerScriptService.SO_MoonRocks
-- Hecho por Claude (16-nov) a pedido de Jose. 6 rocas lunares escondidas alrededor de la base, desde la Fase 1
-- (Placement) hasta el final. Cada jugador recoge cada roca UNA vez (mantener E 1 s) y recibe un dato real de las
-- muestras de las misiones Apolo. Las que ya recogió se esconden solo para él (StarterPlayerScripts.SO_MoonFX).
-- Escribe en cada jugador: RocksFound (número) y RocksList ("1,4,..."). Los usa el diploma (SO_Diploma).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local site = workspace:WaitForChild("MoonSite")

local TOTAL = 6
-- Datos reales (NASA). Los textos del jugador van en inglés.
local FACTS = {
	"The six Apollo Moon landings brought back 382 kilograms of Moon rocks, pebbles, sand and dust.",
	"Apollo 15 astronauts found the 'Genesis Rock', a piece of the Moon's ancient crust.",
	"On Apollo 17, geologist-astronaut Harrison Schmitt found orange soil made of tiny glass beads from old volcanoes.",
	"'Big Muley', brought back by Apollo 16, is the largest Moon rock ever collected: about 11.7 kilograms.",
	"Apollo astronauts said Moon dust smelled like spent gunpowder.",
	"Most Apollo Moon samples are kept in a special clean lab at NASA's Johnson Space Center in Houston.",
}
local ACTIVE = { Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true }

local folder: Folder? = nil

local function makeRock(id: number, pos: Vector3): Model
	local m = Instance.new("Model")
	m.Name = "MoonRock_" .. id
	m:SetAttribute("RockId", id)
	local rnd = Random.new(id * 97)
	local main: BasePart
	for i = 1, 3 do
		local p = Instance.new("Part")
		local s = i == 1 and 1.3 or rnd:NextNumber(0.5, 0.85)
		p.Size = Vector3.new(s * rnd:NextNumber(0.9, 1.3), s * 0.8, s)
		p.Material = Enum.Material.Basalt
		p.Color = i == 1 and Color3.fromRGB(122, 118, 132) or Color3.fromRGB(96, 92, 106)
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = CFrame.new(pos + Vector3.new(i == 1 and 0 or rnd:NextNumber(-0.8, 0.8), p.Size.Y / 2 - 0.1, i == 1 and 0 or rnd:NextNumber(-0.8, 0.8)))
			* CFrame.Angles(rnd:NextNumber(-0.4, 0.4), rnd:NextNumber(0, 6.28), rnd:NextNumber(-0.4, 0.4))
		p.Parent = m
		if i == 1 then main = p end
	end
	m.PrimaryPart = main
	-- Brillito para que se encuentre (sin imágenes externas)
	local glint = Instance.new("ParticleEmitter")
	glint.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	glint.Color = ColorSequence.new(Color3.fromRGB(255, 236, 170))
	glint.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0) })
	glint.Lifetime = NumberRange.new(0.8, 1.2)
	glint.Rate = 3
	glint.Speed = NumberRange.new(0.5, 1)
	glint.LightEmission = 1
	glint.Parent = main
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 226, 150)
	light.Range = 7
	light.Brightness = 0.8
	light.Parent = main
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hold E to collect a Moon rock"
	prompt.ObjectText = "MOON ROCK"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.PromptDistance
	prompt.Parent = main
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Dead") then return end
		local list = p:GetAttribute("RocksList") or ""
		if string.find("," .. list .. ",", "," .. id .. ",", 1, true) then return end
		p:SetAttribute("RocksList", list == "" and tostring(id) or (list .. "," .. id))
		local n = (p:GetAttribute("RocksFound") or 0) + 1
		p:SetAttribute("RocksFound", n)
		Remotes.Toast:FireClient(p, string.format("MOON ROCK FOUND! (%d/%d)", n, TOTAL), 3)
		Remotes.Fact:FireClient(p, FACTS[id] or FACTS[1])
	end)
	return m
end

-- ¿Está libre este punto? (lejos de la nave, de los objetos colocados y de las otras rocas)
local function freeSpot(pos: Vector3, taken: { Vector3 }): boolean
	for _, t in taken do
		if (t - pos).Magnitude < 25 then return false end
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ground = site:FindFirstChild("Ground")
	params.FilterDescendantsInstances = { ground, workspace.Terrain }
	local hits = workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 3, 0)), Vector3.new(8, 5, 8), params)
	for _, h in hits do
		if h.Transparency < 1 then return false end
	end
	return true
end

local function spawnRocks()
	if folder then folder:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "SO_MoonRocks"
	folder = f
	local center = site.Lander:GetPivot().Position
	local rnd = Random.new()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	local ground = { site:FindFirstChild("Ground"), site:FindFirstChild("Hills"), workspace.Terrain }
	ray.FilterDescendantsInstances = ground
	local taken = {}
	local id = 0
	local tries = 0
	while id < TOTAL and tries < 400 do
		tries += 1
		local a = (id / TOTAL) * math.pi * 2 + rnd:NextNumber(-0.4, 0.4)
		local r = rnd:NextNumber(35, 105)
		local x, z = center.X + math.cos(a) * r, center.Z + math.sin(a) * r
		local hit = workspace:Raycast(Vector3.new(x, center.Y + 120, z), Vector3.new(0, -260, 0), ray)
		if hit and hit.Position.Y < center.Y + 12 and freeSpot(hit.Position, taken) then
			id += 1
			table.insert(taken, hit.Position)
			makeRock(id, hit.Position).Parent = f
		end
	end
	f.Parent = site
end

local last = ""
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local phase = GS:GetAttribute("Phase") or ""
	if ACTIVE[phase] and not ACTIVE[last] then
		spawnRocks()
	elseif phase == "RoleSelect" or phase == "Title" then
		if folder then folder:Destroy(); folder = nil end
		for _, p in Players:GetPlayers() do
			p:SetAttribute("RocksFound", 0)
			p:SetAttribute("RocksList", "")
		end
	end
	last = phase
end)
