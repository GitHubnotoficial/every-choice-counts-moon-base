-- SO_Rover (Script) -> ServerScriptService.SO_Rover
-- Hecho por Claude (16-nov) a pedido de Jose. Un rover lunar pequeño (2 asientos) junto a la nave, desde la Fase 2
-- hasta el final. Se maneja con WASD sentado en el asiento del piloto ("Hold E to drive" o tocando el asiento).
-- El servidor le da la física al piloto y el cliente (StarterPlayerScripts.SO_MoonFX) mueve el rover con dos
-- restricciones (Drive = LinearVelocity, Turn = AngularVelocity). Si se voltea, se cae o se aleja mucho, vuelve.
-- Inspirado en el Lunar Roving Vehicle de Apolo 15, 16 y 17 (sin logos).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local site = workspace:WaitForChild("MoonSite")
local ACTIVE = { Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true }

local rover: Model? = nil
local home: CFrame = CFrame.new()

local SILVER = Color3.fromRGB(176, 178, 188)
local DARK = Color3.fromRGB(46, 48, 58)
local GOLD = Color3.fromRGB(214, 168, 66)

local function part(m: Model, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.Massless = true
	p.Parent = m
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function buildRover(cf: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "SO_Rover"
	-- Chasis (la parte con física): no choca; ruedan las 4 esferas de abajo
	local chassis = part(m, "Chassis", Vector3.new(5.5, 0.6, 8.5), cf * CFrame.new(0, 1.9, 0), DARK, Enum.Material.DiamondPlate)
	chassis.Massless = false
	chassis.CustomPhysicalProperties = PhysicalProperties.new(3, 0, 0, 100, 1)
	m.PrimaryPart = chassis
	-- Ruedas: esfera invisible que toca el suelo (sin fricción) + rueda visible de malla dorada
	for _, x in { -3.1, 3.1 } do
		for _, z in { -2.9, 2.9 } do
			local skid = part(m, "Skid", Vector3.new(2.6, 2.6, 2.6), cf * CFrame.new(x, 1.3, z), DARK, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			skid.Transparency = 1
			skid.CanCollide = true
			skid.Massless = false
			skid.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0.1, 100, 1)
			weld(chassis, skid)
			local wheel = part(m, "Wheel", Vector3.new(0.9, 2.6, 2.6), cf * CFrame.new(x, 1.3, z), GOLD, Enum.Material.Fabric, Enum.PartType.Cylinder)
			weld(chassis, wheel)
			local hub = part(m, "Hub", Vector3.new(1, 0.9, 0.9), cf * CFrame.new(x, 1.3, z), SILVER, Enum.Material.Metal, Enum.PartType.Cylinder)
			weld(chassis, hub)
			-- guardabarros
			local fender = part(m, "Fender", Vector3.new(1.1, 0.15, 3), cf * CFrame.new(x, 2.75, z), SILVER, Enum.Material.Metal)
			weld(chassis, fender)
		end
	end
	-- Asientos y cosas del rover
	local seat = Instance.new("VehicleSeat")
	seat.Name = "SO_RoverSeat"
	seat.Size = Vector3.new(2, 0.6, 2)
	seat.CFrame = cf * CFrame.new(-1.3, 2.5, 0.6)
	seat.Color = Color3.fromRGB(70, 130, 220)
	seat.Material = Enum.Material.Fabric
	seat.MaxSpeed = 0 -- lo mueve SO_MoonFX, no el asiento
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.HeadsUpDisplay = false
	seat.CanCollide = false
	seat.Massless = true
	seat.Parent = m
	weld(chassis, seat)
	local seat2 = Instance.new("Seat")
	seat2.Name = "PassengerSeat"
	seat2.Size = Vector3.new(2, 0.6, 2)
	seat2.CFrame = cf * CFrame.new(1.3, 2.5, 0.6)
	seat2.Color = Color3.fromRGB(70, 130, 220)
	seat2.Material = Enum.Material.Fabric
	seat2.CanCollide = false
	seat2.Massless = true
	seat2.Parent = m
	weld(chassis, seat2)
	for _, s in { seat, seat2 } do
		local back = part(m, "SeatBack", Vector3.new(2, 1.8, 0.3), s.CFrame * CFrame.new(0, 1, 1), s.Color, Enum.Material.Fabric)
		weld(chassis, back)
	end
	local console = part(m, "Console", Vector3.new(2.2, 1.4, 0.6), cf * CFrame.new(0, 3, -1.4) * CFrame.Angles(math.rad(-25), 0, 0), SILVER, Enum.Material.Metal)
	weld(chassis, console)
	local screen = part(m, "Screen", Vector3.new(1.6, 0.8, 0.05), console.CFrame * CFrame.new(0, 0.1, -0.33), Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
	weld(chassis, screen)
	-- Antena de plato (como el rover de Apolo)
	local mast = part(m, "Mast", Vector3.new(0.2, 3, 0.2), cf * CFrame.new(0, 3.5, -3.4), SILVER, Enum.Material.Metal)
	weld(chassis, mast)
	local dish = part(m, "Dish", Vector3.new(0.2, 2.4, 2.4), cf * CFrame.new(0, 5.2, -3.4) * CFrame.Angles(0, math.rad(90), math.rad(20)), Color3.fromRGB(230, 230, 236), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	weld(chassis, dish)
	local rack = part(m, "ToolRack", Vector3.new(4.6, 1, 1.4), cf * CFrame.new(0, 2.7, 3.6), SILVER, Enum.Material.Metal)
	weld(chassis, rack)
	-- Letrero y prompt para subirse
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 46)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.MaxDistance = 60
	bb.Parent = console
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Config.Colors.Gold
	t.TextStrokeTransparency = 0.3
	t.Text = "MOON ROVER · WASD to drive"
	t.Parent = bb
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hold E to drive"
	prompt.ObjectText = "MOON ROVER"
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = seat
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Dead") or seat.Occupant then return end
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then seat:Sit(hum) end
	end)

	-- Física: velocidad en el plano, giro en Y y siempre derecho
	local a0 = Instance.new("Attachment")
	a0.Name = "Center"
	a0.Parent = chassis
	local up = Instance.new("Attachment")
	up.Name = "Up"
	up.Axis = Vector3.new(0, 1, 0)
	up.SecondaryAxis = Vector3.new(1, 0, 0)
	up.Parent = chassis
	local lv = Instance.new("LinearVelocity")
	lv.Name = "Drive"
	lv.Attachment0 = a0
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.zero
	lv.MaxForce = 9000
	lv.Parent = chassis
	local av = Instance.new("AngularVelocity")
	av.Name = "Turn"
	av.Attachment0 = a0
	av.RelativeTo = Enum.ActuatorRelativeTo.World
	av.AngularVelocity = Vector3.zero
	av.MaxTorque = 40000
	av.Parent = chassis
	local ao = Instance.new("AlignOrientation")
	ao.Name = "Upright"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = up
	ao.AlignType = Enum.AlignType.PrimaryAxisParallel
	ao.PrimaryAxis = Vector3.new(0, 1, 0)
	ao.MaxTorque = 60000
	ao.Responsiveness = 25
	ao.Parent = chassis

	-- Dueño de la física = el piloto (así se maneja sin retraso)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		local p = hum and Players:GetPlayerFromCharacter(hum.Parent)
		pcall(function() chassis:SetNetworkOwner(p) end)
		if not p then
			lv.PlaneVelocity = Vector2.zero
			av.AngularVelocity = Vector3.zero
		else
			Remotes.Toast:FireClient(p, "W/S: go and back · A/D: turn · SPACE: get off", 4)
		end
	end)
	return m
end

-- Busca un lugar libre cerca de la nave para estacionarlo
local function findHome(): CFrame
	local center = site.Lander:GetPivot().Position
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { site:FindFirstChild("Ground"), site:FindFirstChild("Pad"), site:FindFirstChild("PadStripes"), workspace.Terrain }
	-- fuera de la plataforma de aterrizaje (mide 70 x 70): así no tapa la puerta de la nave
	local pad = site:FindFirstChild("Pad")
	for r = 46, 90, 8 do
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			local pos = Vector3.new(center.X + math.cos(a) * r, 0, center.Z + math.sin(a) * r)
			local ray = workspace:Raycast(pos + Vector3.new(0, 80, 0), Vector3.new(0, -160, 0))
			if ray and ray.Instance ~= pad and math.abs(ray.Position.Y - center.Y) < 4 then
				local ground = ray.Position
				local hits = workspace:GetPartBoundsInBox(CFrame.new(ground + Vector3.new(0, 4, 0)), Vector3.new(10, 6, 12), params)
				local free = true
				for _, h in hits do
					if h.Transparency < 1 or h.CanCollide then free = false break end
				end
				if free then
					return CFrame.lookAt(ground, Vector3.new(center.X, ground.Y, center.Z))
				end
			end
		end
	end
	return CFrame.new(center + Vector3.new(-40, 0, 30))
end

local function spawnRover()
	if rover then rover:Destroy() end
	home = findHome()
	rover = buildRover(home)
	rover.Parent = site
end

local function removeRover()
	if rover then rover:Destroy(); rover = nil end
end

local last = ""
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local phase = GS:GetAttribute("Phase") or ""
	if ACTIVE[phase] and not ACTIVE[last] then
		spawnRover()
	elseif not ACTIVE[phase] and phase ~= "Rescue" and phase ~= "End" then
		removeRover()
	end
	last = phase
end)

-- Si se voltea, se cae del mapa o se va muy lejos: vuelve a casa (sin nadie encima)
while true do
	task.wait(2)
	if rover and rover.Parent and rover.PrimaryPart then
		local c = rover.PrimaryPart
		local far = (c.Position - home.Position).Magnitude > 450
		local fell = c.Position.Y < home.Position.Y - 30
		local flipped = c.CFrame.UpVector.Y < 0.3
		if far or fell or flipped then
			local seat = rover:FindFirstChild("SO_RoverSeat") :: VehicleSeat?
			local occ = seat and seat.Occupant
			if occ then occ.Sit = false end
			task.wait(0.3)
			spawnRover()
		end
	end
end
