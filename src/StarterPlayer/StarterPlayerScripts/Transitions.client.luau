-- Transitions (LocalScript) -> StarterPlayer.StarterPlayerScripts.Transitions
-- Pantallas de paso entre fases (PDF Fase 1, caps. 8 y 9):
-- 1. Transition01 "LAUNCH SUCCESSFUL": las 4 elecciones, la carga, el castigo, oxígeno y agua, y un dato real por elección.
-- 2. Transition12 "PHASE 1 COMPLETE": el sitio, dónde quedó cada cosa, qué significa para la Fase 2 y datos reales.
-- El botón CONTINUE manda ReadyUp; GameManager sigue cuando todos lo pulsan o a los 10 s.
-- Solo lee GameState y Config: no cambia nada del juego.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local C = Config.Colors
local T = P1.Text2
local player = Players.LocalPlayer
local INK = Color3.fromHex("1A1240")
local SOFT = Color3.fromHex("DCD2FF")

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(o: Instance, r: number)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base, parent)
end

local function fmt(t: number): string
	t = math.max(0, math.floor(t))
	return string.format("%d:%02d", t // 60, t % 60)
end

local function hex(c: Color3): string
	return "#" .. c:ToHex()
end

local function find(list, id: string)
	for _, x in list do
		if x.Id == id then
			return x
		end
	end
	return nil
end

local function darkText(role: string): Color3
	return (role == "eng" or role == "bot") and INK or C.Text
end

---------------------------------------------------------------------
-- ScreenGui y escalado (diseño en 1280 x 720)
---------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "SO_Transitions", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 18,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local scales = {}
local function fit()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local v = cam.ViewportSize
	local s = math.min(v.X / 1280, v.Y / 720)
	for _, sc in scales do
		sc.Scale = s
	end
end

-- Cada pantalla: fondo, título, botón CONTINUE y texto de "n/4 ready"
local function screen(titleText: string, titleColor: Color3)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Stage, BorderSizePixel = 0, Visible = false }, gui)
	local st = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1280, 720), BackgroundTransparency = 1 }, bg)
	table.insert(scales, new("UIScale", {}, st))
	label(st, { Text = titleText, Font = Enum.Font.FredokaOne, TextSize = 52, TextColor3 = titleColor, Position = UDim2.fromOffset(64, 30), Size = UDim2.fromOffset(900, 60) })
	local sub = label(st, { Text = "", TextColor3 = SOFT, TextSize = 20, Position = UDim2.fromOffset(64, 92), Size = UDim2.fromOffset(1100, 26) })

	local shadow = new("Frame", { Position = UDim2.fromOffset(300, 643), Size = UDim2.fromOffset(300, 64), BackgroundColor3 = Color3.fromHex("A8230F") }, st)
	corner(shadow, 18)
	local btn = new("TextButton", {
		Position = UDim2.fromOffset(300, 636), Size = UDim2.fromOffset(300, 64), BackgroundColor3 = C.Red,
		Text = Config.Text.Continue, Font = Enum.Font.FredokaOne, TextSize = 30, TextColor3 = C.Text, AutoButtonColor = true,
	}, st)
	corner(btn, 18)
	local ready = new("TextLabel", {
		BackgroundTransparency = 1, RichText = true, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = SOFT,
		Position = UDim2.fromOffset(630, 644), Size = UDim2.fromOffset(560, 50), TextXAlignment = Enum.TextXAlignment.Left,
	}, st)

	local s = { bg = bg, stage = st, sub = sub, btn = btn, ready = ready, sent = false }
	btn.MouseButton1Click:Connect(function()
		if s.sent then
			return
		end
		s.sent = true
		btn.Text = "READY ✓"
		btn.BackgroundColor3 = C.Good
		Remotes.ReadyUp:FireServer()
	end)
	return s
end

-- Tarjeta morada con título
local function card(parent: Instance, x: number, y: number, w: number, h: number, title: string): Frame
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = C.Panel }, parent)
	corner(f, 20)
	new("UIStroke", { Color = C.Panel2, Thickness = 2 }, f)
	label(f, { Text = title, Font = Enum.Font.FredokaOne, TextSize = 20, TextColor3 = C.Gold, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 0, 24) })
	local body = new("Frame", { Position = UDim2.fromOffset(20, 48), Size = UDim2.new(1, -40, 1, -60), BackgroundTransparency = 1 }, f)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	return body
end

-- Fila de un rol: etiqueta de color con el nombre del rol y, al lado, un texto
local function roleRow(parent: Instance, order: number, role: string): TextLabel
	local row = new("Frame", { LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) }, parent)
	local chip = label(row, {
		Text = Config.Roles[role].Name, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = darkText(role),
		BackgroundTransparency = 0, BackgroundColor3 = Config.Roles[role].Color, Size = UDim2.fromOffset(140, 32),
		Position = UDim2.fromOffset(0, 4), TextXAlignment = Enum.TextXAlignment.Center,
	})
	corner(chip, 10)
	return new("TextLabel", {
		BackgroundTransparency = 1, RichText = true, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.Text,
		Position = UDim2.fromOffset(154, 0), Size = UDim2.new(1, -154, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
end

-- Barra con texto encima
local function bar(parent: Instance, order: number)
	local box = new("Frame", { LayoutOrder = order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46) }, parent)
	local text = label(box, { Text = "", TextSize = 16, Font = Enum.Font.GothamBlack, Size = UDim2.new(1, 0, 0, 20) })
	local track = new("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = Color3.fromHex("3B2C8C") }, box)
	corner(track, 8)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Gold }, track)
	corner(fill, 8)
	return { text = text, fill = fill }
end

-- Dato real con un punto del color del rol
local function factRow(parent: Instance, order: number): (Frame, TextLabel)
	local row = new("Frame", { LayoutOrder = order, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) }, parent)
	local dot = new("Frame", { Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = C.Gold }, row)
	corner(dot, 6)
	local text = label(row, {
		Text = "", Font = Enum.Font.Gotham, TextSize = 15, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -22, 0, 0), TextYAlignment = Enum.TextYAlignment.Top,
	})
	return dot, text
end

---------------------------------------------------------------------
-- 1. PASO 0 -> 1: LAUNCH SUCCESSFUL
---------------------------------------------------------------------
local s01 = screen(Config.Text.LaunchOk, C.Good)
local choices01 = card(s01.stage, 64, 134, 560, 236, T.YourCrewBrought)
local rows01 = {}
for i, role in Config.RoleOrder do
	rows01[role] = roleRow(choices01, i, role)
end
local load01 = card(s01.stage, 64, 386, 560, 232, T.StartWith)
local cargoBar = bar(load01, 1)
local o2Bar = bar(load01, 2)
local waterBar = bar(load01, 3)
local facts01 = card(s01.stage, 656, 134, 560, 484, P1.Text.DidYouKnow)
local factRows01 = {}
for i, role in Config.RoleOrder do
	local dot, text = factRow(facts01, i)
	dot.BackgroundColor3 = Config.Roles[role].Color
	factRows01[role] = text
end

local function draw01()
	for _, role in Config.RoleOrder do
		local o = find(Config.Options[role], GS:GetAttribute("Choice_" .. role) or "")
		rows01[role].Text = o and o.Name or "—"
		factRows01[role].Text = o and o.Fact or ""
	end
	local used = GS:GetAttribute("CargoUsed") or 0
	local cap = GS:GetAttribute("CargoCapacity") or 0
	local over = cap > 0 and used > cap
	cargoBar.text.Text = string.format(T.Cargo, used, cap)
	cargoBar.fill.Size = UDim2.fromScale(cap > 0 and math.clamp(used / cap, 0, 1) or 0, 1)
	cargoBar.fill.BackgroundColor3 = over and C.Red or C.Good
	cargoBar.text.TextColor3 = over and C.Bad or C.Text
	if over then
		-- −5 % por cada 10 de exceso (el mismo cálculo que GameManager)
		local pct = math.ceil((used - cap) / 10) * Config.Overload.PercentPer10
		cargoBar.text.Text ..= "   " .. string.format(Config.Text.TooHeavy, pct)
	end
	local o2 = GS:GetAttribute("StartO2") or 100
	local water = GS:GetAttribute("StartWater") or 100
	o2Bar.text.Text = string.format("%s  %d%%", T.Oxygen, o2)
	o2Bar.fill.Size = UDim2.fromScale(o2 / 100, 1)
	o2Bar.fill.BackgroundColor3 = C.Sky
	waterBar.text.Text = string.format("%s  %d%%", T.Water, water)
	waterBar.fill.Size = UDim2.fromScale(water / 100, 1)
	waterBar.fill.BackgroundColor3 = Config.Roles.life.Color
	s01.sub.Text = T.NextLanding
end

---------------------------------------------------------------------
-- 2. PASO 1 -> 2: PHASE 1 COMPLETE
---------------------------------------------------------------------
local s12 = screen(Config.Text.Phase1Done, C.Good)
local placed12 = card(s12.stage, 64, 134, 560, 236, T.YourBase)
local rows12 = {}
for i, role in Config.RoleOrder do
	rows12[role] = roleRow(placed12, i, role)
end
local means12 = card(s12.stage, 64, 386, 560, 232, Config.Text.WhatPhase2)
local meanLines = {}
for i = 1, 4 do
	meanLines[i] = label(means12, { LayoutOrder = i, Text = "", TextSize = 17, RichText = true, TextWrapped = true, Size = UDim2.new(1, 0, 0, 34) })
end
local facts12 = card(s12.stage, 656, 134, 560, 484, P1.Text.DidYouKnow)
local factRows12 = {}
for i = 1, 3 do
	local dot, text = factRow(facts12, i)
	factRows12[i] = { dot = dot, text = text, row = dot.Parent }
end

local function draw12()
	local site = find(Config.Sites, GS:GetAttribute("Site") or "")
	s12.sub.Text = site and string.format(T.LandedAt, site.Name) or ""
	local bad = hex(C.Bad)

	local anyDamaged = false
	local repairs = {}
	local spots = {}
	for _, role in Config.RoleOrder do
		local spot = find(Config.Spots[role], GS:GetAttribute("Spot_" .. role) or "")
		spots[role] = spot
		local damaged = GS:GetAttribute("Damaged_" .. role) == true
		local text = spot and spot.Name or "—"
		if damaged then
			anyDamaged = true
			table.insert(repairs, Config.Roles[role].Name)
			text ..= '  <font color="' .. bad .. '"><b>' .. T.DamagedTag .. "</b></font>"
		end
		rows12[role].Text = text
	end

	-- Energía esperada: reactor = fija; paneles = luz del sitio x el punto. Dañado: -20 %
	local engChoice = GS:GetAttribute("Choice_eng") or ""
	local energy = 0
	if engChoice == "reactor" then
		energy = Config.Energy.ReactorOutput
	elseif site then
		energy = site.Light * (spots.eng and spots.eng.PanelMult or 1)
	end
	if GS:GetAttribute("Damaged_eng") then
		energy *= Config.Energy.DamagedMult
	end
	meanLines[1].Text = string.format(T.EnergyLine, math.floor(energy + 0.5))

	-- Radiación: según dónde quedó el hábitat (dañado: el doble)
	local rad = spots.cap and spots.cap.RadMult or 1
	if GS:GetAttribute("Damaged_cap") then
		rad *= Config.DamageEffects.cap.RadMult
	end
	local radText = string.format(T.RadLine, string.format("%g", rad))
	if engChoice == "reactor" and spots.eng and (spots.eng.ReactorRadMult or 1) > 1 then
		radText ..= "  " .. T.ReactorNear
	end
	meanLines[2].Text = radText

	-- Bandejas de cultivo
	if (GS:GetAttribute("Choice_bot") or "") == "packaged" then
		meanLines[3].Text = T.NoTrays
	else
		local trays = spots.bot and spots.bot.Trays or 0
		if GS:GetAttribute("Damaged_bot") then
			trays -= Config.DamageEffects.bot.TraysLost
		end
		meanLines[3].Text = string.format(T.TraysLine, math.max(0, trays))
	end

	-- Reparaciones pendientes
	if anyDamaged then
		meanLines[4].Text = '<font color="' .. bad .. '">' .. string.format(T.RepairsLine, table.concat(repairs, ", ")) .. "</font>"
	else
		meanLines[4].Text = T.NoRepairs
	end

	-- Datos reales: siempre el del sitio; además, si algo se dañó o si la nave se inclinó
	local facts = {}
	if site then
		table.insert(facts, { C.Gold, site.Fact })
	end
	if anyDamaged then
		table.insert(facts, { C.Bad, Config.PhaseFacts.Damaged })
	end
	if GS:GetAttribute("RoughLanding") then
		table.insert(facts, { C.Pink, Config.PhaseFacts.Tilted })
	end
	for i, fr in factRows12 do
		local f = facts[i]
		fr.row.Visible = f ~= nil
		if f then
			fr.dot.BackgroundColor3 = f[1]
			fr.text.Text = f[2]
		end
	end
end

---------------------------------------------------------------------
-- Mostrar la pantalla que toca según la fase
---------------------------------------------------------------------
local function drawReady(s)
	s.ready.Text = string.format(T.ReadyContinue, GS:GetAttribute("ReadyCount") or 0, #Players:GetPlayers(),
		'<font color="' .. hex(C.Gold) .. '"><b>' .. fmt(GS:GetAttribute("TimeLeft") or 0) .. "</b></font>")
end

local function open(s, draw)
	if not s.bg.Visible then
		s.sent = false
		s.btn.Text = Config.Text.Continue
		s.btn.BackgroundColor3 = C.Red
		s.bg.Visible = true
	end
	draw()
	drawReady(s)
end

local function applyPhase()
	local p = GS:GetAttribute("Phase") or ""
	if p == "Transition01" then
		-- Mientras se ve la animación del despegue (LaunchCinematic), la pantalla espera
		if player:GetAttribute("SO_Cinematic") then
			s01.bg.Visible = false
		elseif not s01.bg.Visible then
			open(s01, draw01)
		end
	else
		s01.bg.Visible = false
	end
	if p == "Transition12" then
		open(s12, draw12)
	else
		s12.bg.Visible = false
	end
end

GS:GetAttributeChangedSignal("Phase"):Connect(applyPhase)
player:GetAttributeChangedSignal("SO_Cinematic"):Connect(applyPhase)
for _, name in { "TimeLeft", "ReadyCount" } do
	GS:GetAttributeChangedSignal(name):Connect(function()
		if s01.bg.Visible then
			drawReady(s01)
		elseif s12.bg.Visible then
			drawReady(s12)
		end
	end)
end
-- Placement coloca lo que falta justo al terminar el tiempo: volver a dibujar si cambia algo
for _, role in Config.RoleOrder do
	for _, prefix in { "Spot_", "Damaged_" } do
		GS:GetAttributeChangedSignal(prefix .. role):Connect(function()
			if s12.bg.Visible then
				draw12()
			end
		end)
	end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	fit()
end)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end
fit()
applyPhase()
