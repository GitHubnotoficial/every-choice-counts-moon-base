-- SO_EggsClient (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_EggsClient
-- Dueño: Isaac + Claude. Parte de cliente de los easter eggs del Apolo (SO_EasterEggs):
-- 1) Brazos: a todo jugador con el atributo SO_ArmsUp le gira los hombros hacia adelante (martillo y pluma).
--    Se hace aquí, justo antes de la física, porque en el avatar nuevo de Roblox (AnimationConstraint)
--    los hombros no obedecen cambios hechos desde el servidor.
-- 2) Láser del reflector (lo pide el servidor con SO_LaserShot). La Tierra del cielo la dibuja ZoneLighting
--    siguiendo a la cámara de cada jugador, así que el pulso sale de la Tierra que ESE jugador ve (Config.MoonSky).
--    Ida: pulso verde brillante (532 nm), 1,28 s. Al llegar deja una mancha en el suelo (de verdad el haz mide
--    varios km al llegar a la Luna). Vuelta: mucho más débil, porque regresan poquísimos fotones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------------------------------------------------------------------
-- 1) Brazos al frente
---------------------------------------------------------------------
local ARM_TIME = require(ReplicatedStorage:WaitForChild("Config")).EasterEggs.Hammer.ArmTime
local armAmount: { [Player]: number } = {}

RunService.PreSimulation:Connect(function(dt)
	for _, p in Players:GetPlayers() do
		local target = p:GetAttribute("SO_ArmsUp") and 1 or 0
		local a = armAmount[p] or 0
		if a == 0 and target == 0 then continue end
		a = math.clamp(a + (target == 1 and 1 or -1) * dt / ARM_TIME, 0, 1)
		armAmount[p] = a
		local char = p.Character
		if not char then continue end
		local e = a * a * (3 - 2 * a)
		for _, n in { "RightShoulder", "LeftShoulder", "Right Shoulder", "Left Shoulder" } do
			local j = char:FindFirstChild(n, true)
			if j and (j:IsA("AnimationConstraint") or j:IsA("Motor6D")) then
				-- R6 tiene los hombros girados 90°: el eje que sube el brazo hacia adelante es Z
				local r6 = n:find(" ") ~= nil
				local rot = r6 and CFrame.Angles(0, 0, math.rad(90) * e * (n:find("Right") and 1 or -1))
					or CFrame.Angles(math.rad(90) * e, 0, 0);
				(j :: any).Transform = rot
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(p) armAmount[p] = nil end)

---------------------------------------------------------------------
-- 2) Láser del reflector
---------------------------------------------------------------------

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local SKY = Config.MoonSky
local M = Config.EasterEggs.Mirror
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SO_LaserShot")
local camera = workspace.CurrentCamera

local folder = Instance.new("Folder")
folder.Name = "SO_LaserFx"
folder.Parent = workspace

local function neon(name: string, size: Vector3, transp: number, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = M.Color
	p.Transparency = transp
	if shape then p.Shape = shape end
	p.Parent = folder
	return p
end

-- Punto de la superficie de la Tierra que da hacia "target". Usa la Tierra que de verdad se ve en el cielo
-- (modelo "Earth"/"SO_MoonEarth" en la cámara, aunque otro script la haya agrandado); si no está, Config.MoonSky.
local function earthPoint(target: Vector3): Vector3
	camera = workspace.CurrentCamera
	local m = camera:FindFirstChild("Earth") or camera:FindFirstChild("SO_MoonEarth")
	local center, radius
	if m and m:IsA("Model") then
		local cf, size = m:GetBoundingBox()
		center, radius = cf.Position, size.X / 2
	else
		center, radius = camera.CFrame.Position + SKY.EarthDir * SKY.EarthDist, SKY.EarthRadius
	end
	return center + (target - center).Unit * radius * 0.98
end

local function stretch(p: Part, a: Vector3, b: Vector3, width: number)
	local len = math.max(0.05, (b - a).Magnitude)
	p.Size = Vector3.new(width, width, len)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
end

-- Un tramo del viaje. down = de la Tierra al reflector; si no, de vuelta.
local function leg(target: Vector3, seconds: number, down: boolean)
	local strong = down
	local core = neon("Core", Vector3.one, strong and 0.1 or 0.55)
	local glow = neon("Glow", Vector3.one, strong and 0.8 or 0.93)
	local pulse = neon("Pulse", Vector3.one * (strong and 2.6 or 1), strong and 0 or 0.4, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color = M.Color
	light.Range = strong and 18 or 8
	light.Brightness = strong and 4 or 1.5
	light.Parent = pulse
	local t0 = os.clock()
	while true do
		local k = math.clamp((os.clock() - t0) / seconds, 0, 1)
		local earth = earthPoint(target)
		local from, to = down and earth or target, down and target or earth
		local head = from:Lerp(to, k)
		pulse.CFrame = CFrame.new(head)
		stretch(core, from, head, strong and 0.35 or 0.12)
		stretch(glow, from, head, strong and 1.4 or 0.5)
		if k >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	pulse:Destroy()
	-- La estela se apaga despacio
	task.spawn(function()
		for i = 1, 10 do
			core.Transparency += (1 - core.Transparency) * 0.3
			glow.Transparency += (1 - glow.Transparency) * 0.3
			task.wait(0.04)
		end
		core:Destroy()
		glow:Destroy()
	end)
end

-- Mancha verde del haz sobre el suelo, alrededor del reflector
local function footprint(ground: Vector3)
	local d = M.SpotRadius * 2
	local disk = neon("Spot", Vector3.new(0.05, d, d), 0.75, Enum.PartType.Cylinder)
	disk.CFrame = CFrame.new(ground + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	task.spawn(function()
		task.wait(0.3)
		for i = 1, 16 do
			disk.Transparency += (1 - disk.Transparency) * 0.2
			task.wait(0.04)
		end
		disk:Destroy()
	end)
end

event.OnClientEvent:Connect(function(target: Vector3, ground: Vector3, seconds: number)
	leg(target, seconds, true)
	footprint(ground)
	task.wait(0.25)
	leg(target, seconds, false)
end)
