-- LaunchCinematic (LocalScript) -> StarterPlayer.StarterPlayerScripts.LaunchCinematic
-- Animaciones de la Tierra a la Luna. Solo en este cliente (no cambia nada en el servidor).
-- 1. DESPEGUE (al inicio de Transition01, cuando GameState.Launched = true): el cohete elegido despega de la
--    plataforma de la Tierra, viaja por el espacio y llega cerca de la Luna ("3 DAYS LATER...").
-- 2. LLEGADA (fase "Landing"): el mismo cohete baja del cielo sobre la base de la Luna con fuego y polvo.
-- Cada cohete tiene su animación (GameState.Choice_cap):
--   light    = despegue rápido y ligero; en el espacio pequeños chorros; aterrizaje suave con un motor.
--   cargo    = despegue lento y pesado con mucho humo; en el espacio gira despacio; aterriza con 4 motores.
--   starship = llamarada enorme y suelta el propulsor; en el espacio da la vuelta; aterriza con motores a los lados.
-- Mientras dura, el jugador tiene el atributo local SO_Cinematic = true (Transitions y Phase1UI esperan).
-- Usa la nave que Tables pone en la plataforma (EarthBase.LaunchPad.ChosenShip). Texturas de partículas de Roblox.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local LAUNCH_TIME = Config.Times.LaunchCinematic or 9
local LAND_TIME = math.max(4, (Config.Times.LandingAnim or 7) - 0.6)
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"

local TEXT = {
	Count = { "3", "2", "1" },
	Liftoff = "LIFTOFF!",
	OnTheWay = "ON THE WAY TO THE MOON",
	DaysLater = "About 3 days later...", -- las misiones Apollo tardaban unos 3 días en llegar
}

---------------------------------------------------------------------
-- Pantalla: fundido a negro y letrero
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SO_Cinematic"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local black = Instance.new("Frame")
black.Size = UDim2.fromScale(1, 1)
black.BackgroundColor3 = Color3.new(0, 0, 0)
black.BackgroundTransparency = 1
black.BorderSizePixel = 0
black.Parent = gui
local caption = Instance.new("TextLabel")
caption.AnchorPoint = Vector2.new(0.5, 1)
caption.Position = UDim2.new(0.5, 0, 0.88, 0)
caption.Size = UDim2.fromScale(0.8, 0.12)
caption.BackgroundTransparency = 1
caption.Font = Enum.Font.FredokaOne
caption.TextScaled = true
caption.TextColor3 = Color3.new(1, 1, 1)
caption.TextStrokeTransparency = 0.3
caption.Text = ""
caption.Parent = gui

local function fade(to: number, t: number)
	TweenService:Create(black, TweenInfo.new(t), { BackgroundTransparency = to }):Play()
	task.wait(t)
end

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

-- Fuego que sale hacia abajo del punto (relativo a la pieza)
local function flame(p: BasePart, offset: Vector3, size: number, rate: number?): ParticleEmitter
	local a = Instance.new("Attachment")
	a.Position = offset
	a.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = FIRE_TEX
	e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("FFFFFF")), ColorSequenceKeypoint.new(0.3, Color3.fromHex("FFD27A")), ColorSequenceKeypoint.new(1, Color3.fromHex("FF5A1F")) })
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.6), NumberSequenceKeypoint.new(1, size * 1.4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.25, 0.45)
	e.Speed = NumberRange.new(size * 6, size * 9)
	e.SpreadAngle = Vector2.new(8, 8)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Rate = rate or 160
	e.LockedToPart = false
	e.Parent = a
	local l = Instance.new("PointLight")
	l.Color = Color3.fromHex("FFB060")
	l.Range = size * 6
	l.Brightness = 3
	l.Parent = a
	return e
end

local function smoke(p: BasePart, offset: Vector3, size: number, rate: number, color: Color3?): ParticleEmitter
	local a = Instance.new("Attachment")
	a.Position = offset
	a.Parent = p
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE_TEX
	e.Color = ColorSequence.new(color or Color3.fromHex("E6E2EE"))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(1, size * 2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(2.5, 4)
	e.Speed = NumberRange.new(size * 1.5, size * 3)
	e.SpreadAngle = Vector2.new(85, 85)
	e.EmissionDirection = Enum.NormalId.Top
	e.Drag = 1.2
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-30, 30)
	e.Rate = rate
	e.Parent = a
	return e
end

-- Copia local de la nave elegida, con la altura pedida y apoyada en su base (pivote abajo al centro)
local function shipCopy(height: number): (Model, number, number)
	local pad = workspace:FindFirstChild("EarthBase") and workspace.EarthBase:FindFirstChild("LaunchPad")
	local src = pad and pad:FindFirstChild("ChosenShip") :: Model?
	local m: Model
	if src then
		m = src:Clone()
	else
		-- Respaldo: cohete simple
		m = Instance.new("Model")
		local body = part(m, "Body", Vector3.new(8, 2, 2), CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("F2F2F7"), nil, Enum.PartType.Cylinder)
		part(m, "Nose", Vector3.new(2, 2, 2), CFrame.new(0, 8.4, 0), Color3.fromHex("E8341C"), nil, Enum.PartType.Ball)
		m.PrimaryPart = body
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		end
	end
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * height / math.max(size.Y, 0.1))
	local cf, size2 = m:GetBoundingBox()
	-- Pieza invisible en la base de la nave: es el punto que se mueve (y de donde sale el fuego)
	local root = part(m, "SO_Root", Vector3.new(1, 1, 1), CFrame.new(cf.Position - Vector3.new(0, size2.Y / 2, 0)), Color3.new(1, 1, 1))
	root.Transparency = 1
	m.PrimaryPart = root
	return m, size2.Y, math.max(size2.X, size2.Z)
end

-- Esconder (solo en este cliente) un modelo real mientras se ve su copia
local function setHidden(m: Instance?, hidden: boolean)
	if not m then return end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = hidden and 1 or 0
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			d.Enabled = not hidden
		end
	end
end

local function easeOut(k: number): number
	return 1 - (1 - k) ^ 3
end

local busy = false
local function begin(): CFrame
	busy = true
	player:SetAttribute("SO_Cinematic", true)
	camera = workspace.CurrentCamera
	local old = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	return old
end
local function finish()
	camera.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then camera.CameraSubject = hum end
	caption.Text = ""
	player:SetAttribute("SO_Cinematic", false)
	busy = false
end

---------------------------------------------------------------------
-- 1. DESPEGUE Y VIAJE
---------------------------------------------------------------------
local STYLE = {
	light = { height = 9, rise = 900, liftDur = 3.4, flameSize = 2.2, smokeRate = 25, smokeSize = 6 },
	cargo = { height = 15, rise = 650, liftDur = 3.8, flameSize = 3.4, smokeRate = 70, smokeSize = 12 },
	starship = { height = 22, rise = 800, liftDur = 3.8, flameSize = 5, smokeRate = 90, smokeSize = 16 },
}

local function launchCinematic()
	if busy then return end
	local choice = GS:GetAttribute("Choice_cap") or "cargo"
	local st = STYLE[choice] or STYLE.cargo
	local pad = workspace:FindFirstChild("EarthBase") and workspace.EarthBase:FindFirstChild("LaunchPad")
	local anchor = pad and pad:FindFirstChild("ShipAnchor") :: BasePart?
	if not anchor then return end
	begin()
	-- [arreglo Claude 15-nov] primero la toma dentro de la cápsula (SO_Cockpit): cuenta regresiva adentro
	local cockpit = ReplicatedStorage:FindFirstChild("SO_CockpitShot")
	local fromCockpit = cockpit ~= nil and pcall(function() cockpit:Invoke("launch") end)
	local folder = Instance.new("Folder")
	folder.Name = "SO_CinematicLaunch"
	folder.Parent = workspace
	local real = pad:FindFirstChild("ChosenShip")
	setHidden(real, true)

	local ship, h, w = shipCopy(st.height)
	local base = anchor.Position
	ship:PivotTo(CFrame.new(base))
	ship.Parent = folder
	local root = ship.PrimaryPart :: BasePart

	-- Starship: propulsor gigante debajo (se suelta en el aire)
	local booster: Model? = nil
	local boosterRoot: BasePart? = nil
	if choice == "starship" then
		booster = Instance.new("Model")
		booster.Name = "Booster"
		local bh = h * 1.1
		local br = part(booster, "BoosterBody", Vector3.new(bh, w * 0.9, w * 0.9), CFrame.new(base + Vector3.new(0, bh / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromHex("C9CCD8"), Enum.Material.Metal, Enum.PartType.Cylinder)
		for k = 0, 3 do
			part(booster, "Fin", Vector3.new(0.4, 3, 2), CFrame.new(base + Vector3.new(0, bh - 2, 0)) * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(w * 0.5, 0, 0), Color3.fromHex("8F95A8"), Enum.Material.Metal)
		end
		local broot = part(booster, "SO_Root", Vector3.new(1, 1, 1), CFrame.new(base), Color3.new(1, 1, 1))
		broot.Transparency = 1
		booster.PrimaryPart = broot
		booster.Parent = folder
		boosterRoot = broot
		ship:PivotTo(CFrame.new(base + Vector3.new(0, bh, 0)))
	end

	-- Humo en la plataforma
	local padPart = part(folder, "PadFx", Vector3.new(1, 1, 1), CFrame.new(base + Vector3.new(0, 0.5, 0)), Color3.new(1, 1, 1))
	padPart.Transparency = 1
	local padSmoke = smoke(padPart, Vector3.zero, st.smokeSize, 0)

	-- Cámara: de lado y desde abajo, mirando a la nave
	local dist = (h + (booster and h * 1.1 or 0)) * 1.6 + 25
	local camBase = base + Vector3.new(-dist * 0.75, 6, dist * 0.75)
	camera.CFrame = CFrame.lookAt(camBase, base + Vector3.new(0, h * 0.6, 0))
	fade(0, 0.01)
	fade(1, 0.4)

	-- Cuenta regresiva
	for i, n in (fromCockpit and {} or TEXT.Count) do -- la cuenta ya se vio adentro
		caption.Text = n
		if i == 3 then padSmoke.Rate = st.smokeRate * 0.5 end
		task.wait(0.45)
	end
	caption.Text = TEXT.Liftoff
	local fireRoot = boosterRoot or root
	local f1 = flame(fireRoot, Vector3.zero, st.flameSize, choice == "cargo" and 120 or 180)
	local extra: { ParticleEmitter } = {}
	if choice == "cargo" then -- 4 motores
		for _, o in { Vector3.new(w * 0.3, 0, 0), Vector3.new(-w * 0.3, 0, 0), Vector3.new(0, 0, w * 0.3), Vector3.new(0, 0, -w * 0.3) } do
			table.insert(extra, flame(root, o, st.flameSize * 0.7, 90))
		end
	elseif choice == "starship" then -- llamarada más ancha
		for _, o in { Vector3.new(w * 0.25, 0, 0), Vector3.new(-w * 0.25, 0, 0) } do
			table.insert(extra, flame(fireRoot, o, st.flameSize * 0.8, 140))
		end
	end
	padSmoke.Rate = st.smokeRate

	-- Subida (acelera); el Starship suelta el propulsor a mitad
	local t0 = os.clock()
	local separated = false
	local boosterAt = Vector3.zero
	local boosterVel = 0
	local shipFlame: ParticleEmitter? = nil
	while true do
		local t = os.clock() - t0
		local k = math.clamp(t / st.liftDur, 0, 1)
		local y = st.rise * k * k * (choice == "cargo" and k or 1) -- el de carga arranca más lento
		local shake = (1 - k) * 0.15
		local pos = base + Vector3.new(math.random() * shake, y, math.random() * shake)
		if booster and boosterRoot then
			if not separated and k > 0.55 then
				separated = true
				boosterAt = boosterRoot.Position
				f1.Enabled = false
				for _, e in extra do e.Enabled = false end
				shipFlame = flame(root, Vector3.zero, st.flameSize * 0.8, 160)
				caption.Text = "STAGE SEPARATION!"
			end
			if separated then
				boosterVel -= 40 * (1 / 60)
				boosterAt += Vector3.new(0.6, boosterVel, 0.3)
				booster:PivotTo(CFrame.new(boosterAt) * CFrame.Angles(0, 0, math.rad(math.min(25, (t - st.liftDur * 0.55) * 20))))
				ship:PivotTo(CFrame.new(pos + Vector3.new(0, h * 1.1, 0)))
			else
				booster:PivotTo(CFrame.new(pos))
				ship:PivotTo(CFrame.new(pos + Vector3.new(0, h * 1.1, 0)))
			end
		else
			ship:PivotTo(CFrame.new(pos))
		end
		-- la cámara sube un poco detrás de la nave
		local target = root.Position + Vector3.new(0, h * 0.5, 0)
		local camPos = camBase + Vector3.new(0, math.max(0, target.Y - base.Y - 40) * 0.55, 0)
		camera.CFrame = CFrame.lookAt(camPos, target)
		if t > 1.2 and caption.Text == TEXT.Liftoff then caption.Text = "" end
		if t >= st.liftDur then break end
		RunService.RenderStepped:Wait()
	end
	padSmoke.Rate = 0
	fade(0, 0.4)
	setHidden(real, false)
	folder:Destroy()

	-- VIAJE POR EL ESPACIO (lejos de todo, de noche)
	local saved = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	local atmDensity = atm and atm.Density
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromHex("6A6F90")
	Lighting.OutdoorAmbient = Color3.fromHex("8A90B0")
	if atm then atm.Density = 0 end
	-- en el espacio no hay nubes ni luz de atardecer
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	local warm = Lighting:FindFirstChild("SO_EarthWarm") :: ColorCorrectionEffect?
	local cloudsOn, warmOn = clouds and clouds.Enabled, warm and warm.Enabled
	if clouds then clouds.Enabled = false end
	if warm then warm.Enabled = false end

	local S = Vector3.new(0, 30000, 0)
	local space = Instance.new("Folder")
	space.Name = "SO_CinematicSpace"
	space.Parent = workspace
	local rng = Random.new(3)
	for _ = 1, 260 do
		local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
		if v.Magnitude > 0.1 then
			local s = rng:NextNumber(2, 5)
			part(space, "Star", Vector3.new(s, s, s), CFrame.new(S + v.Unit * 1400), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
	-- La Tierra (modelo de Ramón si está) atrás y la Luna adelante
	local earthPos = S + Vector3.new(-330, -40, -170)
	local skySrc = ReplicatedStorage:FindFirstChild("SO_SkyModels")
	local earthTpl = skySrc and skySrc:FindFirstChild("Earth")
	if earthTpl then
		local e = earthTpl:Clone()
		local _, es = e:GetBoundingBox()
		e:ScaleTo(e:GetScale() * 230 / es.X)
		e:PivotTo(CFrame.new(earthPos))
		e.Parent = space
	else
		part(space, "Earth", Vector3.new(230, 230, 230), CFrame.new(earthPos), Color3.fromHex("2F7BFF"), nil, Enum.PartType.Ball)
	end
	local moonPos = S + Vector3.new(430, 40, -150)
	part(space, "Moon", Vector3.new(190, 190, 190), CFrame.new(moonPos), Color3.fromHex("C9C6D8"), Enum.Material.Slate, Enum.PartType.Ball)
	for _ = 1, 14 do
		local v = Vector3.new(rng:NextNumber(-1, 0.2), rng:NextNumber(-0.7, 0.7), rng:NextNumber(0.2, 1)).Unit
		local d = rng:NextNumber(14, 40)
		part(space, "Crater", Vector3.new(4, d, d), CFrame.lookAt(moonPos + v * 94, moonPos + v * 200) * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("9C98B2"), Enum.Material.Slate, Enum.PartType.Cylinder)
	end

	local sp, sh = shipCopy(st.height * 0.6)
	sp.Parent = space
	local spRoot = sp.PrimaryPart :: BasePart
	local trail = flame(spRoot, Vector3.zero, st.flameSize * 0.5, 120)
	local from, to = S + Vector3.new(-120, 0, 0), S + Vector3.new(210, 25, -40)
	caption.Text = TEXT.OnTheWay
	fade(1, 0.35)
	local travel = math.max(2.2, LAUNCH_TIME - st.liftDur - 2.2)
	local t1 = os.clock()
	local puffAt = 0
	while true do
		local t = os.clock() - t1
		local k = math.clamp(t / travel, 0, 1)
		local pos = from:Lerp(to, k)
		local dir = (to - from).Unit
		-- la nave apunta hacia la Luna (de pie = +Y; se acuesta mirando a dir)
		local look = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(-math.rad(90), 0, 0)
		if choice == "starship" and k > 0.45 then
			-- da la vuelta (como los Starship al prepararse para frenar)
			look = look * CFrame.Angles(0, 0, math.rad(math.clamp((k - 0.45) / 0.3, 0, 1) * 180))
		elseif choice == "cargo" then
			look = look * CFrame.Angles(0, t * 0.8, 0) -- gira despacio
		end
		sp:PivotTo(look * CFrame.new(0, -sh / 2, 0))
		if choice == "light" and t - puffAt > 0.5 then -- pequeños chorros de los propulsores
			puffAt = t
			local puff = part(space, "Puff", Vector3.new(1.2, 1.2, 1.2), look * CFrame.new(sh * 0.3, 0, 0), Color3.new(1, 1, 1), Enum.Material.Neon, Enum.PartType.Ball)
			TweenService:Create(puff, TweenInfo.new(0.4), { Transparency = 1, Size = Vector3.new(3, 3, 3) }):Play()
		end
		if k > 0.6 then caption.Text = TEXT.DaysLater end
		camera.CFrame = CFrame.lookAt(pos + Vector3.new(-30, 14, 85), pos + Vector3.new(60, 0, -40))
		if k >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	trail.Enabled = false
	fade(0, 0.4)
	space:Destroy()
	for k, v in saved do (Lighting :: any)[k] = v end
	if atm and atmDensity then atm.Density = atmDensity end
	if clouds then clouds.Enabled = cloudsOn end
	if warm then warm.Enabled = warmOn end
	finish()
	fade(1, 0.4)
end

---------------------------------------------------------------------
-- 2. LLEGADA A LA LUNA
---------------------------------------------------------------------
local function landingCinematic()
	if busy then return end
	local site = workspace:FindFirstChild("MoonSite")
	local lander = site and site:FindFirstChild("Lander") :: Model?
	if not lander then return end
	local choice = GS:GetAttribute("Choice_cap") or "cargo"
	begin()
	-- [arreglo Claude 15-nov] toma dentro de la cápsula: la Luna se acerca por la ventana
	local cockpit = ReplicatedStorage:FindFirstChild("SO_CockpitShot")
	if cockpit then pcall(function() cockpit:Invoke("landing") end) end
	fade(0, 0.2)
	task.wait(0.4) -- deja que todos lleguen a la Luna y cambie la luz
	setHidden(lander, true)
	local folder = Instance.new("Folder")
	folder.Name = "SO_CinematicLanding"
	folder.Parent = workspace
	local ground = lander:GetPivot().Position
	local ship, h, w = shipCopy(choice == "starship" and 26 or (choice == "light" and 12 or 16))
	ship.Parent = folder
	local root = ship.PrimaryPart :: BasePart

	-- Motores: light = 1 abajo; cargo = 4 abajo; starship = 4 a los lados, arriba (motores de aterrizaje)
	local flames: { ParticleEmitter } = {}
	if choice == "light" then
		table.insert(flames, flame(root, Vector3.zero, 2.2, 160))
	elseif choice == "cargo" then
		for _, o in { Vector3.new(w * 0.32, 0, 0), Vector3.new(-w * 0.32, 0, 0), Vector3.new(0, 0, w * 0.32), Vector3.new(0, 0, -w * 0.32) } do
			table.insert(flames, flame(root, o, 2, 120))
		end
	else
		for _, o in { Vector3.new(w * 0.55, h * 0.72, 0), Vector3.new(-w * 0.55, h * 0.72, 0), Vector3.new(0, h * 0.72, w * 0.55), Vector3.new(0, h * 0.72, -w * 0.55) } do
			table.insert(flames, flame(root, o, 2.4, 140))
		end
	end
	-- Polvo lunar que sale volando cuando la nave está cerca del suelo
	local dustPart = part(folder, "Dust", Vector3.new(1, 1, 1), CFrame.new(ground + Vector3.new(0, 0.5, 0)), Color3.new(1, 1, 1))
	dustPart.Transparency = 1
	local dust = smoke(dustPart, Vector3.zero, choice == "light" and 5 or 9, 0, Color3.fromHex("CFCBE0"))
	dust.SpreadAngle = Vector2.new(88, 88)
	dust.Speed = NumberRange.new(18, 34)
	dust.Acceleration = Vector3.new(0, -3, 0)

	local startY = 160
	local camPos = ground + Vector3.new(58, 16, 58)
	fade(1, 0.4)
	local descend = LAND_TIME - 1.6
	local t0 = os.clock()
	while true do
		local t = os.clock() - t0
		local k = math.clamp(t / descend, 0, 1)
		local e = easeOut(k)
		local y = startY * (1 - e)
		local sway = (1 - k) * 2
		local pos = ground + Vector3.new(math.sin(t * 2) * sway, y, math.cos(t * 1.6) * sway)
		local tilt = choice == "light" and CFrame.Angles(0, t * 0.2, 0) or CFrame.new()
		ship:PivotTo(CFrame.new(pos) * tilt)
		dust.Rate = (y < 35 and k < 1) and (1 - y / 35) * 160 or 0
		camera.CFrame = CFrame.lookAt(camPos + Vector3.new(0, y * 0.15, 0), pos + Vector3.new(0, h * 0.5, 0))
		if k >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	-- Aterrizó: motores apagados y una nube de polvo
	for _, f in flames do f.Enabled = false end
	dust.Rate = 0
	dust:Emit(choice == "light" and 30 or 60)
	task.wait(0.9)
	fade(0, 0.3)
	folder:Destroy()
	setHidden(lander, false)
	finish()
	fade(1, 0.3)
end

---------------------------------------------------------------------
-- Cuándo se ve cada una
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("Launched"):Connect(function()
	if GS:GetAttribute("Launched") == true then
		task.spawn(launchCinematic)
	end
end)
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if GS:GetAttribute("Phase") == "Landing" then
		task.spawn(landingCinematic)
	end
end)
player:SetAttribute("SO_Cinematic", false)
