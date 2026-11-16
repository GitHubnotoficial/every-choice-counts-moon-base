-- MoonAmbient (LocalScript) -> StarterPlayer.StarterPlayerScripts.MoonAmbient
-- [15-nov] Movimiento de adorno en la Luna, solo en este cliente (no cambia nada del juego):
-- 1. Piezas con atributo AnimSpin (grados/s) giran; AnimSway (grados) se mecen; AnimBlink (segundos) parpadean;
--    AnimSun = true giran despacio para mirar al Sol (paneles solares).
--    Las usan Decor_MoonLife (rover, postes) y LanderRefill (lucecitas del cuarto y de la base).
-- 2. La nave elegida recibe luces de posición que parpadean arriba.
-- 3. Las pantallas (piezas ScreenGlow / ConsoleGlow) muestran gráficos que cambian.
-- 4. El letrero de bienvenida toma su texto de Config.Extras.Text.MoonSign.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local MOON_X = X.Footprints.MoonX

local spin, sway, blink, sun = {}, {}, {}, {}
local base: { [BasePart]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
local baseT: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any
local phase: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any
local rng = Random.new()

---------------------------------------------------------------------
-- Pantallas con gráficos
---------------------------------------------------------------------
local screens = {}
local function addScreen(p: BasePart)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Name = "SO_ScreenGraph"
		g.Face = face
		g.LightInfluence = 0
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 50
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(8, 30, 52)
		bg.BorderSizePixel = 0
		bg.Parent = g
		local bars = {}
		for i = 1, 8 do
			local b = Instance.new("Frame")
			b.AnchorPoint = Vector2.new(0, 1)
			b.Position = UDim2.fromScale(0.05 + (i - 1) * 0.06, 0.92)
			b.Size = UDim2.fromScale(0.04, 0.5)
			b.BackgroundColor3 = i % 3 == 0 and Color3.fromRGB(255, 190, 60) or Color3.fromRGB(80, 230, 160)
			b.BorderSizePixel = 0
			b.Parent = bg
			bars[i] = b
		end
		local dots = {}
		for i = 1, 14 do
			local d = Instance.new("Frame")
			d.AnchorPoint = Vector2.new(0.5, 0.5)
			d.Size = UDim2.fromScale(0.025, 0.06)
			d.BackgroundColor3 = Color3.fromRGB(110, 200, 255)
			d.BorderSizePixel = 0
			d.Parent = bg
			dots[i] = d
		end
		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromScale(0.04, 0.1)
		dot.Position = UDim2.fromScale(0.92, 0.08)
		dot.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		dot.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = dot
		dot.Parent = bg
		g.Parent = p
		table.insert(screens, { part = p, bars = bars, dots = dots, dot = dot, seed = rng:NextNumber(0, 100) })
	end
end

---------------------------------------------------------------------
-- Registrar piezas animadas
---------------------------------------------------------------------
local function register(d: Instance)
	if not d:IsA("BasePart") then
		return
	end
	local p = d :: BasePart
	if p:GetAttribute("AnimSpin") then
		base[p] = p.CFrame
		table.insert(spin, p)
	end
	if p:GetAttribute("AnimSway") then
		base[p] = p.CFrame
		table.insert(sway, p)
	end
	if p:GetAttribute("AnimBlink") then
		baseT[p] = p.Transparency
		phase[p] = rng:NextNumber(0, 10)
		table.insert(blink, p)
	end
	if p:GetAttribute("AnimSun") then
		base[p] = p.CFrame
		table.insert(sun, p)
	end
	if (p.Name == "ScreenGlow" or p.Name == "ConsoleGlow") and not p:FindFirstChild("SO_ScreenGraph") then
		addScreen(p)
	end
end
for _, d in workspace:GetDescendants() do
	register(d)
end
workspace.DescendantAdded:Connect(function(d)
	task.defer(register, d)
end)

-- Letrero de bienvenida
local decor = workspace:FindFirstChild("Decor_MoonLife")
local sign = decor and decor:FindFirstChild("WelcomeSign")
local board = sign and sign:FindFirstChild("Board")
local label = board and board:FindFirstChildWhichIsA("SurfaceGui") and board:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel")
if label then
	label.Text = X.Text.MoonSign
end

---------------------------------------------------------------------
-- Luces de posición en la nave elegida
---------------------------------------------------------------------
local function decorateShip(ship: Instance)
	if ship.Name ~= "ChosenLander" or not ship:IsA("Model") then
		return
	end
	task.wait(0.5) -- LanderRefill la agranda primero
	if not ship.Parent or ship:FindFirstChild("SO_ShipLights") then
		return
	end
	local cf, size = ship:GetBoundingBox()
	local f = Instance.new("Folder")
	f.Name = "SO_ShipLights"
	local top = cf.Position + Vector3.new(0, size.Y / 2 + 0.3, 0)
	local colors = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(80, 230, 120), Color3.fromRGB(255, 255, 255) }
	for i, off in { Vector3.new(0, 0, 0), Vector3.new(size.X * 0.42, -size.Y * 0.45, 0), Vector3.new(-size.X * 0.42, -size.Y * 0.45, 0) } do
		local p = Instance.new("Part")
		p.Name = "ShipBeacon"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.9, 0.9, 0.9)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = colors[i]
		p.Position = top + off
		p:SetAttribute("AnimBlink", i == 1 and 1.4 or 0.9)
		local l = Instance.new("PointLight")
		l.Color = colors[i]
		l.Range = 10
		l.Brightness = 1.2
		l.Parent = p
		p.Parent = f
	end
	f.Parent = ship
end
local site = workspace:WaitForChild("MoonSite", 30)
if site then
	site.ChildAdded:Connect(decorateShip)
	local s = site:FindFirstChild("ChosenLander")
	if s then
		task.spawn(decorateShip, s)
	end
end

---------------------------------------------------------------------
-- Cada cuadro (solo si la cámara está en la Luna)
---------------------------------------------------------------------
local function clean(list)
	for i = #list, 1, -1 do
		if not list[i].Parent then
			table.remove(list, i)
		end
	end
end
local lastClean = 0
local lastScreen = 0
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	-- (15-nov) también en la Tierra: el exterior de la base de la Fase 0 tiene ventiladores, antena y luces
	local t = os.clock()
	if t - lastClean > 3 then
		lastClean = t
		clean(spin)
		clean(sway)
		clean(blink)
		clean(sun)
		for i = #screens, 1, -1 do
			if not screens[i].part.Parent then
				table.remove(screens, i)
			end
		end
	end
	for _, p in spin do
		local b = base[p]
		if b then
			p.CFrame = CFrame.new(b.Position) * CFrame.Angles(0, math.rad(t * p:GetAttribute("AnimSpin")), 0) * (CFrame.new(b.Position):Inverse() * b)
		end
	end
	for _, p in sway do
		local b = base[p]
		if b then
			p.CFrame = b * CFrame.Angles(0, math.rad(math.sin(t * 0.6) * p:GetAttribute("AnimSway")), 0)
		end
	end
	for _, p in blink do
		local per = p:GetAttribute("AnimBlink")
		local on = ((t + phase[p]) % per) < per * 0.55
		p.Transparency = on and (baseT[p] or 0) or 0.8
	end
	-- paneles: giran despacio hacia el Sol (solo de lado, sin voltearse)
	local sd = Lighting:GetSunDirection()
	local flat = Vector3.new(sd.X, 0, sd.Z)
	if flat.Magnitude > 0.05 then
		local yaw = math.atan2(-flat.X, -flat.Z)
		local tilt = math.clamp(math.asin(math.clamp(sd.Y, -1, 1)), 0.1, 1.2)
		for _, p in sun do
			local b = base[p]
			if b then
				local goal = CFrame.new(b.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.pi / 2 - tilt, 0, 0)
				p.CFrame = p.CFrame:Lerp(goal, math.min(1, dt * 0.4))
			end
		end
	end
	-- pantallas: 6 veces por segundo
	if t - lastScreen > 0.16 then
		lastScreen = t
		for _, s in screens do
			for i, b in s.bars do
				local h = 0.25 + 0.6 * (0.5 + 0.5 * math.sin(t * (1 + i * 0.3) + s.seed + i))
				b.Size = UDim2.fromScale(0.04, h * 0.8)
			end
			for i, d in s.dots do
				local x = 0.55 + (i - 1) * 0.03
				local y = 0.5 - 0.3 * math.sin(t * 2 + i * 0.5 + s.seed)
				d.Position = UDim2.fromScale(x, y)
			end
			s.dot.Visible = (t % 1) < 0.5
		end
	end
end)
