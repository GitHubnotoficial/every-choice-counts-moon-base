-- SO_MoonFX (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_MoonFX
-- Hecho por Claude (16-nov) a pedido de Jose. Efectos que hacen el juego más vivo; todo pasa SOLO en este cliente:
--   1. Martillo de la Fase 1: mueve el brazo de quien construye (atributo SO_Hammering que pone Placement),
--      con polvo, chispas y sonido en cada golpe.
--   2. Flecha a la recarga: si tu oxígeno o tu agua bajan del 35 %, una flecha y una columna de luz te
--      llevan a la estación más cercana.
--   3. Polvo: cada astronauta levanta polvo al caminar y al caer (las huellas las hace MoonFootprints).
--   4. Alarma: luz roja en pantalla y en la base, y la cámara tiembla cuando llega una emergencia.
--   5. Celebración: confeti del color del rol al resolver una emergencia (las misiones: Celebrations).
--   6. Rover: si vas sentado en el rover (SO_Rover), lo maneja este cliente (WASD).
--   7. Rocas lunares: esconde las que ya recogiste (SO_MoonRocks).
-- No crea RemoteEvents ni toca otros scripts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local GS = ReplicatedStorage:WaitForChild("GameState")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local MOON_X = Config.Zones.Moon.X

local function onMoon(pos: Vector3): boolean
	return math.abs(pos.X - MOON_X) < 1500
end
local function myRoot(): BasePart?
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Carpeta local para todo lo que se crea aquí (no se replica)
local fxFolder = Instance.new("Folder")
fxFolder.Name = "SO_MoonFX"
fxFolder.Parent = camera

local gui = Instance.new("ScreenGui")
gui.Name = "SO_MoonFX"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

-- Part invisible para emitir partículas en un punto
local function burstAt(pos: Vector3, setup: (ParticleEmitter) -> (), count: number, life: number)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = CFrame.new(pos)
	p.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	setup(e)
	e.Parent = p
	e:Emit(count)
	Debris:AddItem(p, life)
end

-- Polvo lunar: gris, lento y cae despacio (poca gravedad, sin aire)
local function dust(e: ParticleEmitter)
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(168, 166, 180))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.8) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Speed = NumberRange.new(2, 4.5)
	e.SpreadAngle = Vector2.new(70, 70)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -1.6, 0)
	e.Drag = 0.6
	e.RotSpeed = NumberRange.new(-40, 40)
	e.LightInfluence = 0.6
end
local function sparks(e: ParticleEmitter)
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 140, 60))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.25, 0.5)
	e.Speed = NumberRange.new(7, 12)
	e.SpreadAngle = Vector2.new(60, 60)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -8, 0)
	e.LightEmission = 1
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function refreshRayFilter()
	local list = { fxFolder }
	for _, p in Players:GetPlayers() do
		if p.Character then table.insert(list, p.Character) end
	end
	rayParams.FilterDescendantsInstances = list
end

---------------------------------------------------------------------
-- 1. Martillo: brazo derecho arriba y golpe abajo, una vez cada 0,6 s
---------------------------------------------------------------------
local PERIOD = 0.6
local hammerSound = SoundConfig.Hammer
-- En el avatar nuevo de Roblox los hombros pueden ser AnimationConstraint: se mueve su Transform justo antes
-- de la física (PreSimulation), igual que SO_EggsClient con los brazos del martillo y la pluma.
local hammering: { [Model]: { motor: Instance, r6: boolean, t0: number, lastHit: number } } = {}

local function shoulderOf(char: Model): (Instance?, boolean)
	for _, n in { "RightShoulder", "Right Shoulder" } do
		local j = char:FindFirstChild(n, true)
		if j and (j:IsA("AnimationConstraint") or j:IsA("Motor6D")) then
			return j, n == "Right Shoulder"
		end
	end
	return nil, false
end

-- Ángulo del brazo (0 = colgando, 90 = hacia adelante, 150 = arriba) en el momento k (0 a 1) de cada golpe
local function armAngle(k: number): number
	if k < 0.62 then
		local a = k / 0.62
		return 40 + 112 * (1 - (1 - a) ^ 3) -- sube rápido y frena arriba
	elseif k < 0.82 then
		local a = (k - 0.62) / 0.2
		return 152 - 130 * a * a -- baja acelerando: ¡pum!
	else
		return 22
	end
end

local function hammerHit(char: Model)
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local tip = hand and hand:FindFirstChild("SO_HammerTip") :: Attachment?
	if not tip then return end
	local pos = tip.WorldPosition
	refreshRayFilter()
	local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -8, 0), rayParams)
	local ground = hit and hit.Position or pos
	burstAt(ground + Vector3.new(0, 0.2, 0), dust, 10, 2.5)
	burstAt(pos, sparks, 8, 1)
	if hammerSound then
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. hammerSound.Id
		s.Volume = hammerSound.Volume
		s.PlaybackSpeed = 0.9 + math.random() * 0.25
		s.RollOffMaxDistance = 80
		s.Parent = hand
		s:Play()
		Debris:AddItem(s, 2)
	end
end

local function startHammer(char: Model)
	if hammering[char] then return end
	local motor, r6 = shoulderOf(char)
	if not motor then return end
	hammering[char] = { motor = motor, r6 = r6, t0 = os.clock(), lastHit = -1 }
end
local function stopHammer(char: Model)
	hammering[char] = nil -- la animación normal vuelve a mover el brazo sola
end

local function watchCharacter(char: Model)
	local function check()
		if char:GetAttribute("SO_Hammering") then startHammer(char) else stopHammer(char) end
	end
	char:GetAttributeChangedSignal("SO_Hammering"):Connect(check)
	check()
	char.AncestryChanged:Connect(function(_, parent)
		if not parent then hammering[char] = nil end
	end)
end

---------------------------------------------------------------------
-- 2. Flecha a la recarga
---------------------------------------------------------------------
local LOW = 35
local MOON_PHASES = { Landing = true, Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true }
local REFILL_PROMPTS = { SO_ShipRefill = "both", SO_MachineRefill = "both", SO_Tank_O2 = "o2", SO_Tank_Water = "water" }

local arrowBox = Instance.new("Frame")
arrowBox.Name = "RefillArrow"
arrowBox.AnchorPoint = Vector2.new(0.5, 0.5)
arrowBox.Position = UDim2.new(0.5, 0, 1, -150)
arrowBox.Size = UDim2.fromOffset(90, 90)
arrowBox.BackgroundTransparency = 1
arrowBox.Visible = false
arrowBox.Parent = gui
-- Flecha hecha con dos barras (">" girada hacia arriba), sin imágenes externas
local arrow = Instance.new("Frame")
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.Position = UDim2.fromScale(0.5, 0.5)
arrow.Size = UDim2.fromScale(1, 1)
arrow.BackgroundTransparency = 1
arrow.Parent = arrowBox
for _, side in { -1, 1 } do
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = UDim2.fromOffset(46, 14)
	bar.Position = UDim2.new(0.5, side * 14, 0.5, 2)
	bar.Rotation = side * 42
	bar.BackgroundColor3 = Config.Colors.Sky
	bar.BorderSizePixel = 0
	bar.Parent = arrow
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = bar
	local st = Instance.new("UIStroke")
	st.Thickness = 2
	st.Color = Color3.fromRGB(20, 16, 60)
	st.Parent = bar
end
local arrowText = Instance.new("TextLabel")
arrowText.AnchorPoint = Vector2.new(0.5, 0)
arrowText.Position = UDim2.new(0.5, 0, 1, 2)
arrowText.Size = UDim2.fromOffset(360, 30)
arrowText.BackgroundTransparency = 1
arrowText.Font = Enum.Font.FredokaOne
arrowText.TextScaled = true
arrowText.TextColor3 = Config.Colors.Sky
arrowText.TextStrokeTransparency = 0.3
arrowText.Parent = arrowBox

-- Columna de luz sobre la estación
local beacon = Instance.new("Part")
beacon.Name = "RefillBeacon"
beacon.Shape = Enum.PartType.Cylinder
beacon.Size = Vector3.new(60, 1.4, 1.4)
beacon.Material = Enum.Material.Neon
beacon.Color = Config.Colors.Sky
beacon.Anchored = true
beacon.CanCollide = false
beacon.CanQuery = false
beacon.CanTouch = false
beacon.CastShadow = false
beacon.Transparency = 1
beacon.Parent = fxFolder
local beaconSign = Instance.new("BillboardGui")
beaconSign.Size = UDim2.fromOffset(200, 50)
beaconSign.StudsOffsetWorldSpace = Vector3.new(0, 34, 0)
beaconSign.AlwaysOnTop = true
beaconSign.LightInfluence = 0
beaconSign.Enabled = false
beaconSign.Parent = beacon
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Font = Enum.Font.FredokaOne
signText.TextScaled = true
signText.TextColor3 = Config.Colors.Sky
signText.TextStrokeTransparency = 0.2
signText.Text = "REFILL HERE"
signText.Parent = beaconSign

local function nearestRefill(kind: string, from: Vector3): BasePart?
	local site = workspace:FindFirstChild("MoonSite")
	if not site then return nil end
	local best, bestD = nil, math.huge
	for _, d in site:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local k = REFILL_PROMPTS[d.Name] or (d.Parent and d.Parent.Name == "RefillStation" and "both")
			local part = d.Parent
			if k and (k == "both" or k == kind) and part:IsA("BasePart") then
				local dist = (part.Position - from).Magnitude
				if dist < bestD then best, bestD = part, dist end
			end
		end
	end
	return best
end

local refillTarget: BasePart? = nil
local refillKind = ""
task.spawn(function()
	while true do
		task.wait(0.5)
		local root = myRoot()
		local phase = GS:GetAttribute("Phase") or ""
		local o2, water = player:GetAttribute("O2"), player:GetAttribute("Water")
		refillTarget = nil
		if root and MOON_PHASES[phase] and not player:GetAttribute("Dead") and o2 and water then
			if o2 < LOW then refillKind = "o2" elseif water < LOW then refillKind = "water" else refillKind = "" end
			if refillKind ~= "" then refillTarget = nearestRefill(refillKind, root.Position) end
		end
	end
end)

---------------------------------------------------------------------
-- 3. Huellas y polvo
---------------------------------------------------------------------
local PRINT_MATS = { [Enum.Material.Sand] = true, [Enum.Material.Basalt] = true, [Enum.Material.Slate] = true,
	[Enum.Material.Ground] = true, [Enum.Material.Rock] = true, [Enum.Material.Pebble] = true, [Enum.Material.Concrete] = true }
local STEP = 2.1
local MAX_PRINTS = 160
local prints: { BasePart } = {}
local walkers: { [Model]: { last: Vector3?, left: boolean } } = {}

local function addPrint(pos: Vector3, normal: Vector3, look: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Name = "Footprint"
	p.Size = Vector3.new(0.75, 0.05, 1.15)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color:Lerp(Color3.new(0, 0, 0), 0.32)
	p.Transparency = 0.15
	local flatLook = (look - normal * look:Dot(normal))
	if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
	p.CFrame = CFrame.lookAt(pos + normal * 0.03, pos + normal * 0.03 + flatLook.Unit, normal)
	p.Parent = fxFolder
	table.insert(prints, p)
	if #prints > MAX_PRINTS then
		local old = table.remove(prints, 1)
		if old then old:Destroy() end
	end
	-- se borra despacio (en la Luna de verdad duran millones de años: no hay viento)
	task.delay(25, function()
		if p.Parent then
			TweenService:Create(p, TweenInfo.new(5), { Transparency = 1 }):Play()
			Debris:AddItem(p, 5.5)
		end
	end)
end

local function stepCharacter(char: Model)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or not onMoon(root.Position) or root.Anchored then return end
	local w = walkers[char]
	if not w then
		w = { last = nil, left = false }
		walkers[char] = w
	end
	if hum.FloorMaterial == Enum.Material.Air or hum.SeatPart then
		w.last = nil
		return
	end
	local pos = root.Position
	if w.last and (pos - w.last).Magnitude < STEP then return end
	local moved = w.last and (pos - w.last) or root.CFrame.LookVector
	w.last = pos
	w.left = not w.left
	local side = root.CFrame.RightVector * (w.left and -0.45 or 0.45)
	local hit = workspace:Raycast(pos + side, Vector3.new(0, -6, 0), rayParams)
	-- 16-nov: las huellas ya las dibuja MoonFootprints (del equipo, con suela y tacón); aquí solo el polvo
	if hit and PRINT_MATS[hit.Material] and math.random() < 0.5 then
		burstAt(hit.Position + Vector3.new(0, 0.2, 0), dust, 2, 2.5)
	end
end

local function watchLanding(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then return end
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and onMoon(root.Position) then
				refreshRayFilter()
				local hit = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), rayParams)
				if hit then burstAt(hit.Position + Vector3.new(0, 0.2, 0), dust, 16, 2.5) end
			end
		end
	end)
end

local function setupPlayer(p: Player)
	local function onChar(char: Model)
		watchCharacter(char)
		task.spawn(watchLanding, char)
	end
	if p.Character then onChar(p.Character) end
	p.CharacterAdded:Connect(onChar)
end
for _, p in Players:GetPlayers() do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

---------------------------------------------------------------------
-- 4. Alarma de emergencia
---------------------------------------------------------------------
local redFlash = Instance.new("Frame")
redFlash.Name = "AlarmFlash"
redFlash.Size = UDim2.fromScale(1, 1)
redFlash.BackgroundColor3 = Color3.fromRGB(255, 30, 40)
redFlash.BackgroundTransparency = 1
redFlash.BorderSizePixel = 0
redFlash.ZIndex = 0
redFlash.Parent = gui
local vignette = Instance.new("UIGradient")
vignette.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.85),
	NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 0) })
vignette.Parent = redFlash

local alarmLights: { PointLight } = {}
local function setAlarmLights(on: boolean)
	for _, l in alarmLights do l:Destroy() end
	table.clear(alarmLights)
	if not on then return end
	local site = workspace:FindFirstChild("MoonSite")
	if not site then return end
	local spots = {}
	local cl = site:FindFirstChild("ChosenLander")
	local lamp = cl and cl:FindFirstChild("Lamp", true)
	if lamp and lamp:IsA("BasePart") then table.insert(spots, lamp) end
	local hz = site:FindFirstChild("HabitatZone")
	if hz then table.insert(spots, hz) end
	local placed = site:FindFirstChild("Placed")
	local hab = placed and placed:FindFirstChild("cap")
	if hab and hab.PrimaryPart then table.insert(spots, hab.PrimaryPart) end
	for _, part in spots do
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 40, 40)
		l.Range = 28
		l.Brightness = 0
		l.Shadows = false
		l.Parent = part
		table.insert(alarmLights, l)
	end
end

local shakeUntil = 0
local lastEmergency = ""
local function alarmStage(): string
	local stage = GS:GetAttribute("EmergencyStage") or ""
	if (GS:GetAttribute("Emergency") or "") == "" or GS:GetAttribute("Phase") ~= "Phase3" then return "" end
	return stage
end
GS:GetAttributeChangedSignal("Emergency"):Connect(function()
	local e = GS:GetAttribute("Emergency") or ""
	if e ~= "" and e ~= lastEmergency and GS:GetAttribute("Phase") == "Phase3" then
		shakeUntil = os.clock() + 0.9
		setAlarmLights(true)
	elseif e == "" then
		setAlarmLights(false)
	end
	lastEmergency = e
end)

---------------------------------------------------------------------
-- 5. Celebración (confeti)
---------------------------------------------------------------------
local function confetti(color: Color3)
	local colors = { color, Config.Colors.Gold, Color3.new(1, 1, 1), color:Lerp(Color3.new(1, 1, 1), 0.4) }
	local vs = camera.ViewportSize
	for i = 1, 70 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = colors[(i % #colors) + 1]
		f.Size = UDim2.fromOffset(math.random(8, 14), math.random(14, 22))
		f.Rotation = math.random(0, 360)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = math.random() * vs.X
		f.Position = UDim2.fromOffset(x, -30 - math.random() * 200)
		f.ZIndex = 20
		f.Parent = gui
		local t = 2.2 + math.random() * 1.3
		TweenService:Create(f, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(x + math.random(-160, 160), vs.Y + 40),
			Rotation = f.Rotation + math.random(-540, 540),
		}):Play()
		Debris:AddItem(f, t + 0.1)
	end
end

GS:GetAttributeChangedSignal("EmergencyStage"):Connect(function()
	if GS:GetAttribute("EmergencyStage") ~= "result" then return end
	local choice = GS:GetAttribute("EmergencyChoice") or ""
	local role = GS:GetAttribute("EmergencyChooser") or ""
	if (choice == "A" or choice == "B") and role ~= "" then
		local info = Config.Roles[role]
		task.delay(Config.Phase3.LightTime, confetti, info and info.Color or Config.Colors.Gold)
	end
end)
-- 16-nov: el confeti de las misiones terminadas ya lo hace Celebrations (del equipo); aquí solo las emergencias

---------------------------------------------------------------------
-- 6. Rover: si voy sentado, lo manejo yo (el servidor me da la física del rover)
---------------------------------------------------------------------
local ROVER_SPEED = 22
local ROVER_TURN = 1.6
local function driveRover()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not (seat and seat:IsA("VehicleSeat") and seat.Name == "SO_RoverSeat") then return end
	local rover = seat.Parent
	local chassis = rover and rover:FindFirstChild("Chassis") :: BasePart?
	local lv = chassis and chassis:FindFirstChild("Drive") :: LinearVelocity?
	local av = chassis and chassis:FindFirstChild("Turn") :: AngularVelocity?
	if not (lv and av) then return end
	-- Teclas: las del asiento (Throttle/Steer) y, por si acaso, WASD y flechas leídas directamente
	local UIS = game:GetService("UserInputService")
	local function key(a: Enum.KeyCode, b: Enum.KeyCode): boolean
		return UIS:IsKeyDown(a) or UIS:IsKeyDown(b)
	end
	local throttle, steer = seat.Throttle, seat.Steer
	if throttle == 0 and not UIS:GetFocusedTextBox() then
		throttle = (key(Enum.KeyCode.W, Enum.KeyCode.Up) and 1 or 0) - (key(Enum.KeyCode.S, Enum.KeyCode.Down) and 1 or 0)
	end
	if steer == 0 and not UIS:GetFocusedTextBox() then
		steer = (key(Enum.KeyCode.D, Enum.KeyCode.Right) and 1 or 0) - (key(Enum.KeyCode.A, Enum.KeyCode.Left) and 1 or 0)
	end
	local look = chassis.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude > 0.01 then look = look.Unit end
	local v = look * throttle * ROVER_SPEED
	lv.PlaneVelocity = Vector2.new(v.X, v.Z)
	av.AngularVelocity = Vector3.new(0, -steer * ROVER_TURN * (throttle < 0 and -1 or 1), 0)
end

---------------------------------------------------------------------
-- 7. Rocas lunares: las que ya recogí se esconden solo para mí
---------------------------------------------------------------------
local function refreshRocks()
	local site = workspace:FindFirstChild("MoonSite")
	local folder = site and site:FindFirstChild("SO_MoonRocks")
	if not folder then return end
	local mine = "," .. (player:GetAttribute("RocksList") or "") .. ","
	for _, rock in folder:GetChildren() do
		local got = string.find(mine, "," .. tostring(rock:GetAttribute("RockId")) .. ",", 1, true) ~= nil
		for _, d in rock:GetDescendants() do
			if d:IsA("BasePart") then d.LocalTransparencyModifier = got and 1 or 0
			elseif d:IsA("ProximityPrompt") or d:IsA("ParticleEmitter") or d:IsA("Light") then d.Enabled = not got end
		end
	end
end
player:GetAttributeChangedSignal("RocksList"):Connect(refreshRocks)
task.spawn(function()
	while true do
		task.wait(2)
		refreshRocks()
	end
end)

---------------------------------------------------------------------
-- 1. Martillo: brazo (antes de la física, para ganarle a la animación normal)
---------------------------------------------------------------------
RunService.PreSimulation:Connect(function()
	local now = os.clock()
	for char, h in hammering do
		if not h.motor.Parent then
			hammering[char] = nil
		else
			local t = now - h.t0
			local k = (t % PERIOD) / PERIOD
			local ang = math.rad(armAngle(k))
			-- R6 tiene el hombro girado 90°: ahí el eje que sube el brazo hacia adelante es Z
			local joint: any = h.motor
			joint.Transform = h.r6 and CFrame.Angles(0, 0, ang) or CFrame.Angles(ang, 0, 0)
			local n = math.floor(t / PERIOD)
			if k >= 0.82 and n ~= h.lastHit then
				h.lastHit = n
				hammerHit(char)
			end
		end
	end
end)

---------------------------------------------------------------------
-- Ciclo por cuadro
---------------------------------------------------------------------
local filterTimer = 0
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	-- 2. Flecha
	local root = myRoot()
	if refillTarget and refillTarget.Parent and root then
		local tpos = refillTarget.Position
		local rel = camera.CFrame:PointToObjectSpace(tpos)
		arrow.Rotation = math.deg(math.atan2(rel.X, -rel.Z))
		local dist = math.floor((tpos - root.Position).Magnitude)
		arrowText.Text = (refillKind == "o2" and "LOW OXYGEN!" or "LOW WATER!") .. "  REFILL: " .. dist
		arrowBox.Visible = dist > 6
		local pulse = 0.5 + 0.5 * math.sin(now * 5)
		arrowBox.Position = UDim2.new(0.5, 0, 1, -150 - pulse * 8)
		beacon.CFrame = CFrame.new(tpos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
		-- de cerca la columna se esconde (tapaba la vista); el letrero sigue
		beacon.Transparency = dist < 20 and 1 or (0.45 + 0.25 * pulse)
		beaconSign.Enabled = dist > 6
	else
		arrowBox.Visible = false
		beacon.Transparency = 1
		beaconSign.Enabled = false
	end

	-- 3. Huellas (cada 0,1 s alcanza)
	filterTimer += dt
	if filterTimer > 0.1 then
		filterTimer = 0
		refreshRayFilter()
		for _, p in Players:GetPlayers() do
			if p.Character and not p:GetAttribute("Dead") then stepCharacter(p.Character) end
		end
	end

	-- 4. Alarma
	local stage = alarmStage()
	if stage == "choose" or stage == "execute" then
		local s = 0.5 + 0.5 * math.sin(now * (stage == "choose" and 7 or 3.5))
		redFlash.BackgroundTransparency = 1 - (stage == "choose" and 0.35 or 0.15) * s
		for _, l in alarmLights do l.Brightness = 4 * s end
	else
		redFlash.BackgroundTransparency = 1
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		if now < shakeUntil then
			local a = (shakeUntil - now) * 0.5
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)
		elseif hum.CameraOffset ~= Vector3.zero then
			hum.CameraOffset = Vector3.zero
		end
	end

	-- 6. Rover
	driveRover()
end)
