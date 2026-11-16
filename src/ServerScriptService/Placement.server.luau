-- Placement (Script) -> ServerScriptService.Placement
-- Fase 1 en el servidor: colocar lo que trajo cada rol (PDF Fase 1, caps. 5, 6 y 7).
-- - 3 puntos por rol (Config.Spots, posiciones relativas a la nave), pulsar E una vez para colocar.
-- - Martillo y aparición pieza por pieza (BuildTime de cada punto); mientras tanto no se puede mover.
-- - Hasta colocar se camina más lento según el peso (Config.WalkSpeed).
-- - Recoger con E (Pick up) y colocar en otro punto: puede dañarse (Config.MoveDamageChance).
-- - Al acabar el tiempo, lo que falte se coloca solo en el punto más cercano, sin castigo.
-- Escribe: Spot_<rol>, Damaged_<rol>. Los objetos quedan en Workspace.MoonSite.Placed.<rol>
-- (así los encuentran DayCycle, Emergencies y las misiones de la Fase 2).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ROLES = Config.RoleOrder
local rng = Random.new()

-- Estado de esta fase
local active = false
local placed: { [string]: Model } = {} -- placed[rol] = modelo en el suelo
local building: { [string]: boolean } = {} -- building[rol] = true mientras martilla
local moves: { [string]: number } = {} -- veces que se recogió para mover
local spotInfo: { [BasePart]: { role: string, data: any, ground: Vector3 } } = {}

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function hasRole(player: Player, role: string): boolean
	local roles = string.split(player:GetAttribute("Roles") or "", ",")
	return table.find(roles, role) ~= nil
end

local function ownerOf(role: string): Player?
	local id = GS:GetAttribute("Role_" .. role)
	return id and id ~= 0 and Players:GetPlayerByUserId(id) or nil
end

local function findOption(role: string)
	local id = GS:GetAttribute("Choice_" .. role) or ""
	for _, o in Config.Options[role] do
		if o.Id == id then
			return o
		end
	end
	return nil
end

-- Nombre en pantalla de lo que coloca el rol
local function itemName(role: string): string
	if role == "cap" then
		return P1.Text.Habitat
	end
	local o = findOption(role)
	return o and o.Name or Config.Roles[role].Name
end

local function site(): Model?
	return workspace:FindFirstChild("MoonSite")
end

local function placedFolder(): Folder
	local s = site() :: Model
	local f = s:FindFirstChild("Placed")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Placed"
		f.Parent = s
	end
	return f :: Folder
end

local function humanoidOf(player: Player?): Humanoid?
	local char = player and player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

---------------------------------------------------------------------
-- Velocidad al caminar (hasta colocar)
---------------------------------------------------------------------
local function speedFor(player: Player): number
	local speed = Config.WalkSpeed[0]
	for _, role in ROLES do
		if hasRole(player, role) then
			if building[role] then
				return 0
			end
			if not placed[role] then
				local v
				if role == "cap" then
					v = Config.WalkSpeed.CaptainHabitat
				else
					local o = findOption(role)
					v = Config.WalkSpeed[o and o.Weight or 0] or Config.WalkSpeed[0]
				end
				speed = math.min(speed, v)
			end
		end
	end
	return speed
end

local function updateSpeeds()
	for _, pl in Players:GetPlayers() do
		local hum = humanoidOf(pl)
		if hum and not pl:GetAttribute("Dead") then
			hum.WalkSpeed = active and speedFor(pl) or Config.WalkSpeed[0]
		end
	end
end

---------------------------------------------------------------------
-- Pantalla junto a la rampa con las elecciones de todos
---------------------------------------------------------------------
local function updateRampScreen()
	local s = site()
	local screen = s and s:FindFirstChild("RampScreen")
	local sg = screen and screen:FindFirstChildOfClass("SurfaceGui")
	if not sg then
		return
	end
	local list = sg:FindFirstChild("SO_List")
	if not list then
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 60
		list = Instance.new("Frame")
		list.Name = "SO_List"
		list.Size = UDim2.fromScale(1, 1)
		list.BackgroundColor3 = Config.Colors.Stage
		list.Parent = sg
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 14)
		pad.PaddingLeft = UDim.new(0, 18)
		pad.PaddingRight = UDim.new(0, 18)
		pad.Parent = list
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.LayoutOrder = 0
		title.Size = UDim2.new(1, 0, 0, 44)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.TextColor3 = Config.Colors.Gold
		title.Text = P1.Text.RampTitle
		title.Parent = list
		for i, role in ROLES do
			local row = Instance.new("TextLabel")
			row.Name = role
			row.LayoutOrder = i
			row.Size = UDim2.new(1, 0, 0, 46)
			row.BackgroundTransparency = 1
			row.Font = Enum.Font.GothamBold
			row.TextScaled = true
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.TextColor3 = Config.Roles[role].Color
			row.Parent = list
		end
	end
	for _, role in ROLES do
		local row = list:FindFirstChild(role) :: TextLabel
		local spotId = GS:GetAttribute("Spot_" .. role) or ""
		local where = P1.Text.NotPlaced
		for _, d in Config.Spots[role] do
			if d.Id == spotId then
				where = d.Name
			end
		end
		row.Text = Config.Roles[role].Name .. " · " .. itemName(role) .. " → " .. where
	end
end

---------------------------------------------------------------------
-- Modelos: plantillas de ServerStorage.SO_Templates (las hace BuildMoonSite)
---------------------------------------------------------------------
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- Bloque simple si falta la plantilla (así se puede probar igual)
local function fallbackModel(role: string): Model
	local m = Instance.new("Model")
	local block = part(m, "Block", Vector3.new(8, 6, 8), CFrame.new(0, 3, 0), Config.Roles[role].Color)
	m.PrimaryPart = block
	block.PivotOffset = block.CFrame:Inverse()
	return m
end

-- Cajas de comida (comida empacada no tiene invernadero)
local function cratesModel(): Model
	local m = Instance.new("Model")
	local first
	for i = 0, 2 do
		local c = part(m, "Crate", Vector3.new(3, 3, 3), CFrame.new(i * 3.6 - 3.6, 1.5, 0), Color3.fromHex("E0B26A"))
		first = first or c
	end
	m.PrimaryPart = first
	first.PivotOffset = first.CFrame:Inverse()
	return m
end

local function makeModel(role: string, spot): Model
	local templates = ServerStorage:FindFirstChild("SO_Templates")
	local choice = GS:GetAttribute("Choice_" .. role) or ""
	local name
	if role == "cap" then
		name = "habitat"
	elseif role == "eng" or role == "life" then
		-- Modelos de Ramón (SO_Maquetas) a escala real [arreglo Claude 15-nov]: 3 paneles en fila, reactor o máquina de soporte vital
		local maq = ServerStorage:FindFirstChild("SO_Maquetas")
		local key = (role == "eng" and choice ~= "reactor") and "panels" or choice
		local src = maq and maq:FindFirstChild(key)
		if src then
			local mm = Instance.new("Model")
			local copies = (role == "eng" and choice ~= "reactor") and { -7, 0, 7 } or { 0 }
			for _, x in copies do
				local c = src:Clone()
				c:ScaleTo(c:GetScale() * ((role == "eng" and choice ~= "reactor") and 3.4 or 3))
				c:PivotTo(CFrame.new(x, 0, 0))
				for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
				c.Parent = mm
			end
			if role == "eng" and choice == "panels_bat" then
				part(mm, "Battery", Vector3.new(3, 2, 2), CFrame.new(0, 1, 4), Config.Colors.Gold)
			end
			local first = mm:FindFirstChildWhichIsA("BasePart", true) :: BasePart
			mm.PrimaryPart = first
			first.PivotOffset = first.CFrame:Inverse()
			return mm
		end
		name = (role == "eng") and ((choice == "reactor") and "reactor" or "panels") or "lifesupport"
	elseif role == "bot" then
		if choice == "packaged" then
			return cratesModel()
		end
		name = "greenhouse"
	end
	local tpl = templates and templates:FindFirstChild(name)
	local m = tpl and tpl:Clone() or fallbackModel(role)

	local pivot = m:GetPivot()
	if role == "eng" and choice == "panels_bat" then
		-- Paneles + baterías: una caja amarilla de baterías
		part(m, "Battery", Vector3.new(2, 2, 3), pivot * CFrame.new(0, 1, 3), Config.Colors.Gold)
	end
	if role == "bot" and spot.Trays and spot.Trays > 2 then
		-- El invernadero trae 2 bandejas; las demás van al lado (anexo 4, inflable 6)
		for k = 3, spot.Trays do
			local idx = k - 3
			local x = 9 + math.floor(idx / 2) * 5
			local z = (idx % 2 == 0) and -1.8 or 1.8
			part(m, "Tray", Vector3.new(4, 0.8, 2), pivot * CFrame.new(x, 0.6, z), Config.Roles.bot.Color)
		end
	end
	return m
end

local function primaryOf(m: Model): BasePart?
	return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

-- Chispas y humo para que se vea que está dañado
local function addDamageFx(m: Model)
	local p = primaryOf(m)
	if p and not p:FindFirstChild("SO_Sparks") then
		local sparks = Instance.new("Sparkles")
		sparks.Name = "SO_Sparks"
		sparks.Parent = p
		local smoke = Instance.new("Smoke")
		smoke.Name = "SO_Smoke"
		smoke.Opacity = 0.2
		smoke.Parent = p
	end
end

---------------------------------------------------------------------
-- Martillo y aparición
---------------------------------------------------------------------
-- 16-nov (Claude): antes era una barra gris que flotaba delante del astronauta. Ahora el martillo lunar de Ramón
-- (ServerStorage.SO_MoonProps.Hammer) va soldado a la mano derecha. El servidor solo pone el martillo y el
-- atributo SO_Hammering en el personaje; el movimiento del brazo, el polvo, las chispas y el sonido los hace
-- cada cliente (StarterPlayerScripts.SO_MoonFX) para que se vean suaves.
local HAMMER_LENGTH = 1.9 -- studs (el modelo real mide 0,35)
local function makeHammer(): Model
	local props = game:GetService("ServerStorage"):FindFirstChild("SO_MoonProps")
	local tpl = props and props:FindFirstChild("Hammer")
	local m: Model
	if tpl then
		m = tpl:Clone()
		local _, size = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * HAMMER_LENGTH / math.max(size.X, 0.01))
	else
		-- Respaldo con piezas: mango y cabeza
		m = Instance.new("Model")
		local handle = Instance.new("Part")
		handle.Size = Vector3.new(HAMMER_LENGTH, 0.22, 0.22)
		handle.Color = Color3.fromRGB(120, 124, 132)
		handle.Material = Enum.Material.Metal
		handle.Parent = m
		local head = Instance.new("Part")
		head.Size = Vector3.new(0.35, 0.35, 0.9)
		head.Color = Color3.fromRGB(70, 74, 82)
		head.Material = Enum.Material.Metal
		head.CFrame = handle.CFrame * CFrame.new(-HAMMER_LENGTH / 2 + 0.17, 0, 0)
		head.Parent = m
	end
	m.Name = "SO_Hammer"
	return m
end

local function hammer(player: Player, seconds: number)
	local char = player.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) :: BasePart?
	if not hand then
		return
	end
	local old = char:FindFirstChild("SO_Hammer")
	if old then old:Destroy() end
	local m = makeHammer()
	-- El modelo tiene el mango en X y la cabeza en el extremo -X: el mango sigue al brazo (-Y de la mano),
	-- con la cabeza abajo y la cara hacia adelante.
	local cf, size = m:GetBoundingBox()
	local handDown = hand.Size.Y / 2
	local target = hand.CFrame * CFrame.new(0, -handDown - size.X / 2 + 0.35, 0) * CFrame.Angles(0, 0, math.rad(90))
	m:PivotTo(target * cf:ToObjectSpace(m:GetPivot())) -- el centro de la caja va a 'target'
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = hand
			w.Part1 = d
			w.Parent = d
		end
	end
	-- Punto de la cabeza (para el polvo y las chispas del cliente)
	local tip = Instance.new("Attachment")
	tip.Name = "SO_HammerTip"
	tip.Parent = hand
	tip.Position = Vector3.new(0, -handDown - size.X + 0.45, 0)
	m.Parent = char
	char:SetAttribute("SO_Hammering", true)
	task.delay(seconds, function()
		if char.Parent then char:SetAttribute("SO_Hammering", nil) end
		if m.Parent then m:Destroy() end
		if tip.Parent then tip:Destroy() end
	end)
end

-- Las piezas pasan de invisibles a visibles una por una, de abajo hacia arriba
local function appear(m: Model, seconds: number)
	local parts = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, { p = d, t = d.Transparency })
			d.Transparency = 1
		end
	end
	table.sort(parts, function(a, b)
		return a.p.Position.Y < b.p.Position.Y
	end)
	local step = seconds / math.max(1, #parts)
	for _, it in parts do
		TweenService:Create(it.p, TweenInfo.new(math.min(step, 0.4)), { Transparency = it.t }):Play()
		task.wait(step)
	end
end

---------------------------------------------------------------------
-- Colocar y recoger
---------------------------------------------------------------------
local pickUp: (Player, string) -> ()

-- ¿Están los 4 objetos en el suelo? Entonces, tras P1.AllPlacedDelay s, GameState.AllPlaced = true.
-- GameManager (Isaac) puede usar AllPlaced para terminar la colocación antes de los 5:00.
local allPlacedToken = 0
local function checkAllPlaced()
	local all = active
	for _, role in ROLES do
		if not placed[role] or building[role] then
			all = false
		end
	end
	allPlacedToken += 1
	if not all then
		if GS:GetAttribute("AllPlaced") then
			GS:SetAttribute("AllPlaced", false)
			Remotes.Toast:FireAllClients(P1.Text.BaseNotReady, 3)
		end
		return
	end
	if GS:GetAttribute("AllPlaced") then
		return
	end
	local my = allPlacedToken
	Remotes.Toast:FireAllClients(string.format(P1.Text.BaseReadySoon, P1.AllPlacedDelay), 4)
	task.delay(P1.AllPlacedDelay, function()
		if my == allPlacedToken and active then
			GS:SetAttribute("AllPlaced", true)
		end
	end)
end

-- Apaga/enciende los puntos "Place here" de un rol (no deben quedar con el objeto ya colocado) [arreglo Claude 15-nov]
local function setPlacePrompts(role: string, on: boolean)
	local s = site()
	local f = s and s:FindFirstChild("SO_Spots")
	if not f then return end
	for _, m in f:GetChildren() do
		if m:GetAttribute("Role") == role then
			m:SetAttribute("Taken", not on) -- Phase1UI lo respeta en el cliente
			local pr = m:FindFirstChild("SO_Place")
			if pr then pr.Enabled = on end
		end
	end
end

-- Saca a un jugador de la huella del objeto: lo deja al borde, mirando al objeto [arreglo 15-nov: antes el
-- objeto aparecía encima del astronauta y la física lo lanzaba o lo dejaba atascado]
local function pushOut(pl: Player, center: Vector3, radius: number, groundY: number): BasePart?
	local root = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
	if flat.Magnitude >= radius + P1.BuildClearance - 0.5 then
		return root -- ya está fuera
	end
	local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
	local target = Vector3.new(center.X, groundY + 3, center.Z) + dir * (radius + P1.BuildClearance)
	pl.Character:PivotTo(CFrame.lookAt(target, Vector3.new(center.X, target.Y, center.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
	return root
end

-- Huella del modelo: centro y radio en el suelo
local function footprint(m: Model): (Vector3, number)
	local cf, size = m:GetBoundingBox()
	return cf.Position, math.max(size.X, size.Z) / 2
end

local function placeAt(player: Player?, role: string, spotPart: BasePart, animate: boolean)
	if placed[role] or building[role] then
		return
	end
	local info = spotInfo[spotPart]
	if not info then
		return
	end
	local spot = info.data
	building[role] = true
	setPlacePrompts(role, false)

	local m = makeModel(role, spot)
	m.Name = role
	local choice = GS:GetAttribute("Choice_" .. role) or ""
	if role == "eng" and choice ~= "reactor" then
		-- Paneles solares: el frente del modelo (+Z) queda mirando al Sol, que está casi en el horizonte
		local sun = P1.SunDirection * Vector3.new(1, 0, 1)
		m:PivotTo(CFrame.lookAt(info.ground, info.ground - sun.Unit))
	else
		m:PivotTo(CFrame.new(info.ground))
	end
	-- Mientras aparece no choca con nadie; al terminar recupera sus colisiones
	local collide = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			collide[d] = d.CanCollide
			d.CanCollide = false
		end
	end
	local center, radius = footprint(m)

	-- Nadie se queda dentro: el que construye (y cualquier otro) sale al borde antes de que aparezca
	local builderRoot = nil
	for _, pl in Players:GetPlayers() do
		local r = pushOut(pl, center, radius, info.ground.Y)
		if pl == player then
			builderRoot = r
		end
	end
	m.Parent = placedFolder()

	if animate and player then
		local hum = humanoidOf(player)
		updateSpeeds() -- velocidad 0 mientras martilla
		if hum then
			hum.JumpHeight = 0
		end
		-- Quieto de verdad mientras martilla: sin resbalar ni caerse
		if builderRoot then
			builderRoot.Anchored = true
		end
		hammer(player, spot.BuildTime)
		appear(m, spot.BuildTime)
		if hum then
			hum.JumpHeight = P1.MoonJumpHeight
		end
		-- Solo se suelta si seguimos en la colocación (en las pantallas de paso PhaseMovement lo deja quieto)
		if builderRoot and builderRoot.Parent and GS:GetAttribute("Phase") == "Placement" and not player:GetAttribute("Dead") then
			builderRoot.Anchored = false
		end
	end

	for d, c in collide do
		if d.Parent then
			d.CanCollide = c
		end
	end
	-- Por si alguien entró mientras aparecía
	for _, pl in Players:GetPlayers() do
		pushOut(pl, center, radius, info.ground.Y)
	end

	placed[role] = m
	building[role] = false
	GS:SetAttribute("Spot_" .. role, spot.Id)

	-- ¿Se dañó? Solo si ya se había movido antes (y nunca al colocarse solo al final)
	local n = moves[role] or 0
	if animate and n > 0 then
		local chance = Config.MoveDamageChance[math.min(n, #Config.MoveDamageChance)]
		if rng:NextNumber() < chance then
			GS:SetAttribute("Damaged_" .. role, true)
			if player then
				Remotes.Toast:FireClient(player, string.format(Config.Text.Damaged, itemName(role)), 5)
			end
		end
	end
	if GS:GetAttribute("Damaged_" .. role) then
		addDamageFx(m)
	end

	-- La región del hábitat sigue al hábitat (la usan Bars y DayCycle)
	local s = site()
	local habZone = s and s:FindFirstChild("HabitatZone") :: BasePart?
	if role == "cap" and habZone then
		habZone.CFrame = m:GetPivot() + Vector3.new(0, 5, 0)
	end

	-- Aviso para recogerlo y moverlo (solo mientras dure la colocación)
	local p = primaryOf(m)
	if active and p then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SO_PickUp"
		prompt.ActionText = P1.Text.PickUp
		prompt.ObjectText = itemName(role)
		prompt.HoldDuration = P1.PickUpHold
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = Config.PromptDistance + 6
		prompt:SetAttribute("Role", role)
		prompt.Parent = p
		prompt.Triggered:Connect(function(pl)
			pickUp(pl, role)
		end)
	end

	updateSpeeds()
	updateRampScreen()
	checkAllPlaced()
end

pickUp = function(player: Player, role: string)
	if not active or building[role] or not placed[role] or not hasRole(player, role) or player:GetAttribute("Dead") then
		return
	end
	placed[role]:Destroy()
	placed[role] = nil
	setPlacePrompts(role, true)
	GS:SetAttribute("Spot_" .. role, "")
	moves[role] = (moves[role] or 0) + 1
	updateSpeeds()
	updateRampScreen()
	checkAllPlaced()
end

---------------------------------------------------------------------
-- Los 12 puntos
---------------------------------------------------------------------
local function groundUnder(pos: Vector3, ignore: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), params)
	return hit and hit.Position or pos
end

local function createSpots(): Folder?
	local s = site()
	local lander = s and s:FindFirstChild("Lander") :: Model?
	if not (s and lander) then
		warn("Placement: falta Workspace.MoonSite.Lander")
		return nil
	end
	local old = s:FindFirstChild("SO_Spots")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "SO_Spots"
	folder.Parent = s

	local lp = lander:GetPivot().Position
	local base = Vector3.new(lp.X, 0, lp.Z)
	local ignore: { Instance } = { lander, folder, placedFolder() }
	for _, pl in Players:GetPlayers() do
		if pl.Character then
			table.insert(ignore, pl.Character)
		end
	end

	table.clear(spotInfo)
	for _, role in ROLES do
		local color = Config.Roles[role].Color
		for _, d in Config.Spots[role] do
			local ground = groundUnder(base + d.Offset, ignore)
			local marker = Instance.new("Part")
			marker.Name = role .. "_" .. d.Id
			marker.Shape = Enum.PartType.Cylinder
			marker.Size = P1.SpotSize
			marker.CFrame = CFrame.new(ground + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
			marker.Anchored = true
			marker.CanCollide = false
			marker.CanQuery = false
			marker.Material = Enum.Material.Neon
			marker.Color = color
			marker.Transparency = 0.35
			marker:SetAttribute("Role", role)
			marker:SetAttribute("SpotId", d.Id)
			marker.Parent = folder

			-- Cartel flotante (cada cliente ve solo los de su rol: Phase1UI)
			local bb = Instance.new("BillboardGui")
			bb.Name = "SO_Sign"
			bb.Size = UDim2.fromOffset(220, 40)
			bb.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
			bb.AlwaysOnTop = true
			bb.MaxDistance = 250
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundColor3 = color
			label.TextColor3 = (role == "eng" or role == "bot") and Color3.fromHex("1A1240") or Config.Colors.Text
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.Text = d.Name
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = label
			label.Parent = bb
			bb.Parent = marker

			-- Pulsar E una vez para colocar
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SO_Place"
			prompt.ActionText = P1.Text.PlaceHere
			prompt.ObjectText = d.Name
			prompt.HoldDuration = P1.PlaceHold
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = Config.SpotRadius
			prompt:SetAttribute("Role", role)
			prompt.Parent = marker
			prompt.Triggered:Connect(function(pl)
				if active and hasRole(pl, role) and not pl:GetAttribute("Dead") then
					placeAt(pl, role, marker, true)
				end
			end)

			spotInfo[marker] = { role = role, data = d, ground = ground }
		end
	end
	return folder
end

---------------------------------------------------------------------
-- Empezar y terminar la colocación
---------------------------------------------------------------------
local function startPlacement()
	if not site() then
		warn("Placement: falta Workspace.MoonSite")
		return
	end
	active = true
	allPlacedToken += 1
	GS:SetAttribute("AllPlaced", false)
	table.clear(placed)
	table.clear(building)
	for _, role in ROLES do
		moves[role] = 0
		GS:SetAttribute("Spot_" .. role, "")
	end
	-- Objetos de una partida anterior
	local old = (site() :: Model):FindFirstChild("Placed")
	if old then
		old:Destroy()
	end
	createSpots()
	updateSpeeds()
	updateRampScreen()
end

local function endPlacement()
	active = false
	allPlacedToken += 1
	-- Esperar a quien esté martillando
	local waited = 0
	while waited < P1.WaitBuildersMax do
		local any = false
		for _, v in building do
			if v then
				any = true
			end
		end
		if not any then
			break
		end
		waited += task.wait(0.25)
	end

	-- Lo que falte se coloca solo en el punto más cercano a su jugador, sin castigo
	for _, role in ROLES do
		if not placed[role] then
			local pl = ownerOf(role)
			local root = pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local best, bestDist = nil, math.huge
			for marker, info in spotInfo do
				if info.role == role then
					local dist = root and (info.ground - root.Position).Magnitude or 0
					if dist < bestDist then
						best, bestDist = marker, dist
					end
				end
			end
			if best then
				placeAt(nil, role, best, false)
			end
		end
	end

	-- Quitar los puntos y los avisos de "Pick up"
	local s = site()
	local spots = s and s:FindFirstChild("SO_Spots")
	if spots then
		spots:Destroy()
	end
	table.clear(spotInfo)
	if s and s:FindFirstChild("Placed") then
		for _, d in s.Placed:GetDescendants() do
			if d:IsA("ProximityPrompt") and d.Name == "SO_PickUp" then
				d:Destroy()
			end
		end
	end
	updateSpeeds()
	updateRampScreen()
end

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local p = GS:GetAttribute("Phase")
	if p == "Placement" and not active then
		startPlacement()
	elseif p ~= "Placement" and active then
		endPlacement()
	end
end)

-- Quien reaparece durante la colocación recupera su velocidad
local function onPlayer(pl: Player)
	pl.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 5)
		if active then
			updateSpeeds()
		end
	end)
	pl:GetAttributeChangedSignal("Roles"):Connect(function()
		if active then
			updateSpeeds()
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, pl in Players:GetPlayers() do
	onPlayer(pl)
end

if GS:GetAttribute("Phase") == "Placement" then
	startPlacement()
end
