-- Tables (Script) -> ServerScriptService.Tables
-- Dueño: Isaac + Claude (antes era tarea de Yamir). Fase 0 en el edificio (PDF Fase 0, caps. 6 y 10):
-- - Clic en un pedestal o su maqueta → panel de pros y contras (cualquiera puede mirar).
-- - Doble clic → elige (solo el dueño del rol y solo en "Phase0"). Cambiar es libre mientras dure la fase.
-- - El pedestal elegido se ilumina y una copia pequeña de la maqueta "sube a la nave".
-- - Pantalla grande: elecciones, carga contra capacidad, castigo y reloj; "CAPTAIN: LAUNCH NOW!" en Launch.
-- - Consola: mantener E en "Launch" (solo el Captain) → GameState.Launched = true.
-- - Ventana: la nave elegida por el Captain aparece en la plataforma de lanzamiento.
-- - Al empezar "Phase0" lleva a todos al inicio del pasillo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ROLES = Config.RoleOrder

local base = workspace:WaitForChild("EarthBase")
local maquetas = ServerStorage:WaitForChild("SO_Maquetas")
local DOUBLE = 0.4

local function findOption(role: string, id: string)
	for _, o in Config.Options[role] do
		if o.Id == id then return o end
	end
	return nil
end

local function owns(player: Player, role: string): boolean
	return GS:GetAttribute("Role_" .. role) == player.UserId
end

---------------------------------------------------------------------
-- Pedestales: clic y doble clic
---------------------------------------------------------------------
local pedestals: { [string]: BasePart } = {} -- "rol_opcion" → pedestal
local lastClick: { [Player]: { t: number, key: string } } = {}

local function lift(role: string, option: string, from: Vector3)
	-- Copia pequeña de la maqueta que sube y se desvanece (como si subiera a la nave)
	local tpl = maquetas:FindFirstChild(option)
	if not tpl then return end
	local m = tpl:Clone()
	m:ScaleTo(0.6)
	m:PivotTo(CFrame.new(from + Vector3.new(0, 1, 0)))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
	end
	m.Parent = workspace
	local t0 = os.clock()
	task.spawn(function()
		while os.clock() - t0 < 1.2 do
			local k = (os.clock() - t0) / 1.2
			m:PivotTo(CFrame.new(from + Vector3.new(0, 1 + k * 8, 0)) * CFrame.Angles(0, k * math.pi * 2, 0))
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then d.Transparency = k end
			end
			task.wait()
		end
		m:Destroy()
	end)
end

local function highlight(role: string)
	local chosen = GS:GetAttribute("Choice_" .. role) or ""
	local color = Config.Roles[role].Color
	for key, ped in pedestals do
		if ped:GetAttribute("Role") == role then
			local on = ped:GetAttribute("Option") == chosen
			ped.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			ped.Color = on and color or Color3.fromHex("2B2F48")
		end
	end
end

local function onClick(player: Player, ped: BasePart)
	local role, option = ped:GetAttribute("Role"), ped:GetAttribute("Option")
	local key = role .. "_" .. option
	local now = os.clock()
	local last = lastClick[player]
	lastClick[player] = { t = now, key = key }
	if last and last.key == key and now - last.t < DOUBLE then
		-- Doble clic: elegir
		if GS:GetAttribute("Phase") ~= "Phase0" then
			Remotes.Toast:FireClient(player, "You can choose when the countdown starts.", 2.5)
			return
		end
		if not owns(player, role) then
			Remotes.Toast:FireClient(player, "Only the " .. Config.Roles[role].Name .. " can choose here.", 2.5)
			return
		end
		if GS:GetAttribute("Choice_" .. role) ~= option then
			GS:SetAttribute("Choice_" .. role, option)
			lift(role, option, ped.Position)
			local o = findOption(role, option)
			Remotes.Toast:FireAllClients(Config.Roles[role].Name .. " chose " .. (o and o.Name or option), 2.5)
		end
		lastClick[player] = nil
	else
		-- Un clic: pros y contras
		Remotes.ShowProsCons:FireClient(player, role, option)
	end
end

local function wire(ped: BasePart, target: Instance)
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 16
	cd.Parent = target
	cd.MouseClick:Connect(function(player) onClick(player, ped) end)
end

for _, room in base:GetChildren() do
	if room.Name:match("^Room_") then
		for _, d in room:GetChildren() do
			if d:IsA("BasePart") and d.Name:match("^Pedestal_") then
				pedestals[d:GetAttribute("Role") .. "_" .. d:GetAttribute("Option")] = d
				wire(d, d)
				local m = room:FindFirstChild("Model_" .. d:GetAttribute("Option"))
				if m then
					local primary = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
					if primary then wire(d, primary) end
					for _, part in m:GetDescendants() do
						if part:IsA("BasePart") and part ~= primary then wire(d, part) end
					end
				end
			end
		end
	end
end
for _, r in ROLES do
	GS:GetAttributeChangedSignal("Choice_" .. r):Connect(function() highlight(r) end)
end
Players.PlayerRemoving:Connect(function(p) lastClick[p] = nil end)

---------------------------------------------------------------------
-- Pantalla grande
---------------------------------------------------------------------
local screen = base.ControlRoom.BigScreen
local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Back -- mira hacia el interior de la sala (sur)
sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
sg.PixelsPerStud = 50
sg.LightInfluence = 0
sg.Parent = screen
local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Config.Colors.BgDark
bg.Parent = sg
local function lbl(y: number, h: number, size: number?): TextLabel
	local t = Instance.new("TextLabel")
	t.Position = UDim2.fromScale(0.04, y)
	t.Size = UDim2.fromScale(0.92, h)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = bg
	return t
end
local title = lbl(0.03, 0.12)
local rows = {}
for i, r in ROLES do
	rows[r] = lbl(0.18 + (i - 1) * 0.11, 0.09)
end
local track = Instance.new("Frame")
track.Position = UDim2.fromScale(0.04, 0.66)
track.Size = UDim2.fromScale(0.92, 0.07)
track.BackgroundColor3 = Color3.fromHex("3B2C8C")
track.Parent = bg
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Config.Colors.Gold
fill.Parent = track
local cargoText = lbl(0.75, 0.09)
local warnText = lbl(0.86, 0.1)

local function cargo(): (number, number, number)
	local ship = findOption("cap", GS:GetAttribute("Choice_cap") or "")
	local used = 0
	for _, r in { "eng", "life", "bot" } do
		local o = findOption(r, GS:GetAttribute("Choice_" .. r) or "")
		used += o and o.Weight or 0
	end
	local cap = ship and ship.Capacity or 100
	local excess = math.max(0, used - cap)
	local pct = math.ceil(excess / 10) * Config.Overload.PercentPer10 + (ship and ship.LateSolPenalty or 0)
	return used, cap, pct
end

local function fmt(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function refreshScreen()
	local phase = GS:GetAttribute("Phase") or ""
	local left = GS:GetAttribute("TimeLeft") or 0
	if phase == "Launch" then
		title.Text = string.format(Config.Text.LaunchNow, left)
		title.TextColor3 = (left % 2 == 0) and Config.Colors.Red or Color3.new(1, 1, 1)
	else
		title.Text = "MISSION CONTROL   " .. (phase == "Phase0" and fmt(left) or "")
		title.TextColor3 = Config.Colors.Gold
	end
	for _, r in ROLES do
		local o = findOption(r, GS:GetAttribute("Choice_" .. r) or "")
		rows[r].Text = Config.Roles[r].Name .. ":  " .. (o and o.Name or "—")
		rows[r].TextColor3 = Config.Roles[r].Color
	end
	local used, cap, pct = cargo()
	fill.Size = UDim2.fromScale(math.clamp(used / cap, 0, 1), 1)
	fill.BackgroundColor3 = used > cap and Config.Colors.Bad or Config.Colors.Gold
	cargoText.Text = string.format("CARGO: %d / %d", used, cap)
	if used > cap then
		warnText.Text = string.format(Config.Text.TooHeavy, pct)
	elseif pct > 0 then
		warnText.Text = string.format("ARRIVES 1 DAY LATE: −%d%% oxygen and water", pct) -- Starship
	else
		warnText.Text = ""
	end
	warnText.TextColor3 = Config.Colors.Bad
end

---------------------------------------------------------------------
-- Ventana: la nave elegida en la plataforma
---------------------------------------------------------------------
local anchor = base.LaunchPad.ShipAnchor
local shipModel: Model? = nil
local function refreshShip()
	if shipModel then shipModel:Destroy(); shipModel = nil end
	local id = GS:GetAttribute("Choice_cap") or ""
	local tpl = maquetas:FindFirstChild(id)
	if not tpl then return end
	local m = tpl:Clone()
	m.Name = "ChosenShip"
	m:ScaleTo(4)
	m:PivotTo(CFrame.new(anchor.Position))
	m.Parent = base.LaunchPad
	shipModel = m
end
GS:GetAttributeChangedSignal("Choice_cap"):Connect(refreshShip)

---------------------------------------------------------------------
-- Consola de lanzamiento
---------------------------------------------------------------------
local console = base.ControlRoom.LaunchConsole
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Hold E to LAUNCH"
prompt.ObjectText = "CAPTAIN"
prompt.HoldDuration = 1
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Enabled = false
prompt.Parent = console
prompt.Triggered:Connect(function(player)
	if GS:GetAttribute("Phase") ~= "Launch" then return end
	local roles = string.split(player:GetAttribute("Roles") or "", ",")
	if table.find(roles, "cap") then
		GS:SetAttribute("Launched", true)
	else
		Remotes.Toast:FireClient(player, "Only the CAPTAIN can launch.", 2.5)
	end
end)

---------------------------------------------------------------------
-- Fases
---------------------------------------------------------------------
local function toStart()
	local spawn = base:FindFirstChild("EarthSpawn")
	if not spawn then return end
	for i, p in Players:GetPlayers() do
		if p.Character then
			p.Character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 3, (i - 2.5) * 3)) * CFrame.Angles(0, -math.pi / 2, 0))
		end
	end
end

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local phase = GS:GetAttribute("Phase")
	prompt.Enabled = phase == "Launch"
	if phase == "Phase0" then
		workspace.Gravity = Config.Gravity.Earth
		toStart()
		for _, r in ROLES do highlight(r) end
		refreshShip()
	end
	refreshScreen()
end)
GS:GetAttributeChangedSignal("TimeLeft"):Connect(refreshScreen)
for _, r in ROLES do
	GS:GetAttributeChangedSignal("Choice_" .. r):Connect(refreshScreen)
end
refreshScreen()
