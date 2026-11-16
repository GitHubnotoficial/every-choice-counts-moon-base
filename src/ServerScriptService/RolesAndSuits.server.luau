-- RolesAndSuits (Script) -> ServerScriptService.RolesAndSuits
-- Dueño: Isaac + Claude. Tomar/soltar rol, repartir roles libres, traje y etiqueta sobre la cabeza.
-- Escribe GameState.Role_<rol> (UserId, 0 = libre) y player:SetAttribute("Role", rol principal).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ROLES = Config.RoleOrder

for _, r in ROLES do
	if GS:GetAttribute("Role_" .. r) == nil then
		GS:SetAttribute("Role_" .. r, 0)
	end
end

-- Roles que tiene un jugador, en orden
local function rolesOf(player: Player): { string }
	local list = {}
	for _, r in ROLES do
		if GS:GetAttribute("Role_" .. r) == player.UserId then
			table.insert(list, r)
		end
	end
	return list
end

-- Actualiza el atributo "Role" (rol principal) y la apariencia
local refreshLook: (Player) -> ()

local function refresh(player: Player)
	local list = rolesOf(player)
	player:SetAttribute("Role", list[1] or "")
	player:SetAttribute("Roles", table.concat(list, ","))
	refreshLook(player)
end

local function canChangeRoles(): boolean
	local phase = GS:GetAttribute("Phase")
	return phase == "RoleSelect" or phase == "Title"
end

-- Tomar o soltar un rol (doble clic en una tarjeta de rol)
local function requestRole(player: Player, roleId: any)
	if not canChangeRoles() or typeof(roleId) ~= "string" or not Config.Roles[roleId] then return end
	local owner = GS:GetAttribute("Role_" .. roleId)
	if owner == player.UserId then
		GS:SetAttribute("Role_" .. roleId, 0) -- soltar el propio
	elseif owner == 0 then
		-- Con 4 jugadores, cada uno solo puede tener 1 rol; con menos, puede tomar más
		if #rolesOf(player) >= 1 and #Players:GetPlayers() >= 4 then
			Remotes.Toast:FireClient(player, "You already have a role.", 2.5)
			return
		end
		GS:SetAttribute("Role_" .. roleId, player.UserId)
	else
		Remotes.Toast:FireClient(player, "That role is taken.", 2.5)
		return
	end
	refresh(player)
end
Remotes.RequestRole.OnServerEvent:Connect(requestRole)

-- Puente para la pantalla de roles de Celeste: su script dispara ReplicatedStorage.ElegirRolEvent con un nombre
-- ("Captain", "Engineer", "LifeSupport", "Botanist" o parecidos). Lo traducimos al id del contrato.
local elegir = ReplicatedStorage:FindFirstChild("ElegirRolEvent") or Instance.new("RemoteEvent")
elegir.Name = "ElegirRolEvent"
elegir.Parent = ReplicatedStorage
elegir.OnServerEvent:Connect(function(player, name)
	if typeof(name) ~= "string" then return end
	local n = string.lower(name)
	local id = (n:find("cap") and "cap") or ((n:find("eng") or n:find("ing")) and "eng")
		or (n:find("life") and "life") or (n:find("bot") and "bot") or nil
	if id then requestRole(player, id) end
end)

-- Roles libres, en orden al azar
local function freeRolesShuffled(): { string }
	local free = {}
	for _, r in ROLES do
		if GS:GetAttribute("Role_" .. r) == 0 then table.insert(free, r) end
	end
	for i = #free, 2, -1 do
		local j = math.random(i)
		free[i], free[j] = free[j], free[i]
	end
	return free
end

-- A cada jugador que aún no tiene rol le toca uno libre al azar
local function assignRolelessPlayers()
	local free = freeRolesShuffled()
	for _, p in Players:GetPlayers() do
		if #free == 0 then break end
		if #rolesOf(p) == 0 then
			GS:SetAttribute("Role_" .. table.remove(free), p.UserId)
			refresh(p)
			Remotes.Toast:FireClient(p, Config.Text.RoleAssigned, 3)
		end
	end
end

-- Reparte TODOS los roles libres al azar, primero a quien tenga menos (al salir de RoleSelect o si alguien se va)
local function assignFreeRoles()
	if #Players:GetPlayers() == 0 then return end
	assignRolelessPlayers()
	for _, r in freeRolesShuffled() do
		local players = Players:GetPlayers()
		for i = #players, 2, -1 do -- desempate al azar
			local j = math.random(i)
			players[i], players[j] = players[j], players[i]
		end
		table.sort(players, function(a, b) return #rolesOf(a) < #rolesOf(b) end)
		GS:SetAttribute("Role_" .. r, players[1].UserId)
		refresh(players[1])
	end
end

-- READY en la elección de rol: a quien no eligió le toca un rol libre al azar,
-- y si ya están todos listos, se reparten también los roles que sobran (nadie queda sin puesto).
Remotes.ReadyUp.OnServerEvent:Connect(function()
	if GS:GetAttribute("Phase") ~= "RoleSelect" then return end
	assignRolelessPlayers()
	task.defer(function()
		local total = #Players:GetPlayers()
		if total > 0 and (GS:GetAttribute("ReadyCount") or 0) >= total then
			assignFreeRoles()
		end
	end)
end)

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if not canChangeRoles() then
		assignFreeRoles()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for _, r in ROLES do
		if GS:GetAttribute("Role_" .. r) == player.UserId then
			GS:SetAttribute("Role_" .. r, 0)
		end
	end
	if not canChangeRoles() then
		task.defer(assignFreeRoles)
	end
end)

---------------------------------------------------------------------
-- Traje: cuerpo blanco, sin accesorios, mochila del color del rol y etiqueta "ENGINEER · Juan"
---------------------------------------------------------------------
local WHITE = Color3.fromHex("F2F2F5")

-- Equipo del traje (modelos de Ramón): se pega a la cabeza, las manos y los pies; sirve para R15 y R6.
-- Cada pieza se escala al ancho de la parte del cuerpo y se apoya en su borde de abajo.
local SUIT = game:GetService("ServerStorage"):FindFirstChild("SO_Suit")
local GEAR = {
	-- modelo, partes del cuerpo (R15, R6), ancho = ancho del cuerpo × mult, dónde va ("center" o "bottom")
	{ "Helmet", { "Head" }, 1.35, "center" },
	{ "GloveL", { "LeftHand", "Left Arm" }, 1.45, "bottom" },
	{ "GloveR", { "RightHand", "Right Arm" }, 1.45, "bottom" },
	{ "BootL", { "LeftFoot", "Left Leg" }, 1.35, "bottom" },
	{ "BootR", { "RightFoot", "Right Leg" }, 1.35, "bottom" },
}
local function dressGear(char: Model)
	if not SUIT then return end
	for _, g in GEAR do
		local name, parts, mult, where = g[1], g[2], g[3], g[4]
		local src = SUIT:FindFirstChild(name)
		local body: BasePart? = nil
		for _, n in parts do
			body = char:FindFirstChild(n) :: BasePart?
			if body then break end
		end
		if src and body and not char:FindFirstChild("SO_" .. name) then
			local m = src:Clone() :: Model
			m.Name = "SO_" .. name
			m:SetAttribute("SO_Gear", true)
			local _, sz = m:GetBoundingBox()
			-- La cabeza R6 mide 2 de ancho pero se ve de ~1.2: para la cabeza se usa el alto
			local ref = (name == "Helmet") and body.Size.Y or math.min(body.Size.X, body.Size.Z)
			m:ScaleTo(m:GetScale() * ref * mult / math.max(sz.X, 0.01))
			local _, sz2 = m:GetBoundingBox()
			local y = (where == "bottom") and (-body.Size.Y / 2 + sz2.Y / 2 - 0.05) or 0.08
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
				end
			end
			m:PivotTo(body.CFrame * CFrame.new(0, y, 0))
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					local w = Instance.new("WeldConstraint")
					w.Part0 = body
					w.Part1 = p
					w.Parent = p
				end
			end
			m.Parent = char
		end
	end
	-- La cara queda dentro del casco
	local head = char:FindFirstChild("Head")
	local face = head and head:FindFirstChildOfClass("Decal")
	if face and char:FindFirstChild("SO_Helmet") then face.Transparency = 1 end
end

refreshLook = function(player: Player)
	local char = player.Character
	if not char then return end
	local role = player:GetAttribute("Role")
	local info = role and Config.Roles[role]
	-- Sin rol no se toca al personaje (así no afecta a quien esté probando otra cosa en el place)
	if not info and not char:FindFirstChild("SO_Backpack") then return end

	-- Cuerpo blanco y sin accesorios ni ropa
	for _, d in char:GetChildren() do
		if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		elseif d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Color = WHITE
		end
	end

	-- Mochila
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	local pack = char:FindFirstChild("SO_Backpack")
	-- Mochila de Ramón del color del rol (SO_Suit.Backpack_<rol>); si cambia el rol, se cambia la mochila
	local packModel = SUIT and role and SUIT:FindFirstChild("Backpack_" .. role)
	if pack and (pack:GetAttribute("Role") ~= role) then
		pack:Destroy()
		pack = nil
	end
	if torso and info and packModel and not pack then
		local m = packModel:Clone() :: Model
		m.Name = "SO_Backpack"
		m:SetAttribute("Role", role)
		local _, sz = m:GetBoundingBox()
		m:ScaleTo(m:GetScale() * torso.Size.X * 0.9 / math.max(sz.X, 0.01))
		local _, sz2 = m:GetBoundingBox()
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
			end
		end
		-- en la espalda (detrás del torso = +Z del torso)
		m:PivotTo(torso.CFrame * CFrame.new(0, 0.05, torso.Size.Z / 2 + sz2.Z / 2 - 0.05))
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				local w = Instance.new("WeldConstraint"); w.Part0 = torso; w.Part1 = p; w.Parent = p
			end
		end
		m.Parent = char
		pack = m
	end
	if torso and info and not packModel then
		if not pack then
			pack = Instance.new("Part")
			pack.Name = "SO_Backpack"
			pack:SetAttribute("Role", role)
			pack.Size = Vector3.new(1.6, 2, 0.8)
			pack.CanCollide = false
			pack.Massless = true
			pack.Material = Enum.Material.SmoothPlastic
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = pack
			weld.C0 = CFrame.new(0, 0, (torso.Size.Z / 2) + 0.4)
			weld.Parent = pack
			pack.Parent = char
		end
		if pack:IsA("BasePart") then pack.Color = info.Color end
	elseif not info and pack then
		pack:Destroy()
	end

	-- Casco, guantes y botas (modelos de Ramón en ServerStorage.SO_Suit)
	if info then
		dressGear(char)
	else
		for _, d in char:GetChildren() do
			if d:IsA("Model") and d:GetAttribute("SO_Gear") then d:Destroy() end
		end
	end

	-- Etiqueta sobre la cabeza
	local head = char:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("SO_Tag")
	if head and info then
		if not tag then
			tag = Instance.new("BillboardGui")
			tag.Name = "SO_Tag"
			tag.Size = UDim2.fromOffset(220, 32)
			tag.StudsOffset = Vector3.new(0, 2.6, 0)
			tag.AlwaysOnTop = true
			tag.MaxDistance = 80
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextStrokeTransparency = 0.4
			label.Parent = tag
			tag.Parent = head
		end
		local label = tag:FindFirstChild("Label") :: TextLabel
		label.Text = info.Name .. " · " .. player.DisplayName
		label.TextColor3 = info.Color
	elseif tag then
		tag:Destroy()
	end
	-- Ocultar el nombre por defecto de Roblox (ya está en la etiqueta)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = info and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(function()
		refreshLook(player)
	end)
end)
for _, p in Players:GetPlayers() do
	if p.Character then refreshLook(p) end
end
