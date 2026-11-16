-- Phase3HUD (LocalScript) -> StarterPlayer.StarterPlayerScripts.Phase3HUD
-- Dueño: Isaac + Claude. Interfaz de la Fase 3 (PDF Fase 3): día y reloj, barras personales, panel de la base,
-- tarjeta de emergencia, luz que cruza la Luna (PlayMoonLight), avisos y pantalla final.
-- Crea su propio ScreenGui "SO_Phase3HUD" (no toca las Gui de Celeste). Si existe el HUD de Celeste ("HUDGui"),
-- deja que ella muestre los avisos y las barras.
-- Teclas de prueba (solo Studio): F6 saltar día · F7 llenar barras · F8 forzar emergencia al azar · F9 saltar fase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local EmergencyData = require(ReplicatedStorage:WaitForChild("EmergencyData"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local T3 = Config.Text3
local C = Config.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local byId = {}
for _, e in EmergencyData do byId[e.Id] = e end

local MOON_PHASES = { Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true }

---------------------------------------------------------------------
-- Ayudantes de interfaz
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SO_Phase3HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(o: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = o
end
local function frame(parent: Instance, name: string, size: UDim2, pos: UDim2, color: Color3?, transp: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color or C.Panel
	f.BackgroundTransparency = transp or 0.1
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end
local function label(parent: Instance, text: string, size: UDim2, pos: UDim2, font: Enum.Font?, color: Color3?): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = size
	t.Position = pos
	t.BackgroundTransparency = 1
	t.Text = text
	t.Font = font or Enum.Font.GothamBold
	t.TextColor3 = color or C.Text
	t.TextScaled = true
	t.TextWrapped = true
	t.Parent = parent
	return t
end
local function fmt(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end
local function celesteHUD(): boolean
	return playerGui:FindFirstChild("HUDGui") ~= nil
end

---------------------------------------------------------------------
-- Día y reloj (arriba al centro)
---------------------------------------------------------------------
local dayBox = frame(gui, "Day", UDim2.fromOffset(260, 56), UDim2.new(0.5, -130, 0, 12), C.Panel, 0.1)
corner(dayBox, 28)
local dayText = label(dayBox, "", UDim2.new(1, -20, 1, -12), UDim2.fromOffset(10, 6), Enum.Font.FredokaOne)
-- 15-nov: el Sol de verdad (NASA DONKI en vivo) debajo del día: qué tan activo está el Sol real hoy
local sunLine = label(gui, "", UDim2.fromOffset(460, 20), UDim2.new(0.5, -230, 0, 72), Enum.Font.GothamBold, Color3.fromHex("FFD27A"))
sunLine.TextStrokeTransparency = 0.4
sunLine.Visible = false

---------------------------------------------------------------------
-- Barras personales (arriba a la izquierda)
---------------------------------------------------------------------
local barsBox = frame(gui, "Bars", UDim2.fromOffset(250, 112), UDim2.fromOffset(16, 80), C.Panel, 0.15)
corner(barsBox)
local function bar(y: number, name: string, color: Color3)
	label(barsBox, name, UDim2.fromOffset(80, 22), UDim2.fromOffset(10, y), Enum.Font.GothamBold).TextXAlignment = Enum.TextXAlignment.Left
	local track = frame(barsBox, name .. "Track", UDim2.fromOffset(140, 14), UDim2.fromOffset(96, y + 4), Color3.fromHex("3B2C8C"), 0)
	corner(track, 7)
	local fill = frame(track, "Fill", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), color, 0)
	corner(fill, 7)
	return fill
end
local o2Fill = bar(10, "OXYGEN", Color3.fromHex("2F7BFF"))
local waterFill = bar(42, "WATER", Config.Colors.Sky)
local radFill = bar(74, "RADIATION", Config.Colors.Gold)
local noWater = label(gui, "", UDim2.fromOffset(320, 40), UDim2.new(0.5, -160, 0, 74), Enum.Font.FredokaOne, C.Bad)
local gravity = label(gui, Config.Text.Gravity, UDim2.fromOffset(200, 20), UDim2.new(1, -216, 0, 16), Enum.Font.GothamBold, C.Muted)

---------------------------------------------------------------------
-- Panel de la base (a la derecha)
---------------------------------------------------------------------
local baseBox = frame(gui, "Base", UDim2.fromOffset(250, 150), UDim2.new(1, -266, 0, 44), C.Panel, 0.15)
corner(baseBox)
local foodT = label(baseBox, "", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 8))
local rO2T = label(baseBox, "", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 36))
local rWT = label(baseBox, "", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 64))
local energyT = label(baseBox, "", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 92))
local blackoutT = label(baseBox, "", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 122), Enum.Font.GothamBold, C.Bad)
for _, t in { foodT, rO2T, rWT, energyT, blackoutT } do t.TextXAlignment = Enum.TextXAlignment.Left end

---------------------------------------------------------------------
-- Tarjeta de emergencia (centro)
---------------------------------------------------------------------
local card = frame(gui, "Emergency", UDim2.fromOffset(560, 360), UDim2.new(0.5, -280, 0.5, -170), C.Panel, 0.02)
corner(card, 20)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = C.Red
stroke.Parent = card
local cTitle = label(card, "", UDim2.new(1, -130, 0, 40), UDim2.fromOffset(20, 14), Enum.Font.FredokaOne, C.Bad) -- deja espacio al reloj
local cData = label(card, "", UDim2.new(1, -40, 0, 18), UDim2.fromOffset(20, 56), Enum.Font.GothamBold, C.Muted)
local cText = label(card, "", UDim2.new(1, -40, 0, 40), UDim2.fromOffset(20, 78), Enum.Font.GothamBold)
local cTimer = label(card, "", UDim2.fromOffset(80, 30), UDim2.new(1, -96, 0, 14), Enum.Font.FredokaOne, C.Gold)
local buttons = {}
for i, letter in { "A", "B", "C" } do
	local b = Instance.new("TextButton")
	b.Name = letter
	b.Size = UDim2.new(1, -40, 0, 44)
	b.Position = UDim2.fromOffset(20, 124 + (i - 1) * 52)
	b.BackgroundColor3 = C.Panel2
	b.TextColor3 = C.Text
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.AutoButtonColor = true
	b.Parent = card
	corner(b, 10)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = b
	b.MouseButton1Click:Connect(function() Remotes.EmergencyAnswer:FireServer(letter) end)
	buttons[letter] = b
end
local cFact = label(card, "", UDim2.new(1, -40, 0, 46), UDim2.fromOffset(20, 288), Enum.Font.Gotham, C.Muted)
-- Franja pequeña mientras se ejecuta la respuesta (la tarjeta se oculta para ver el camino)
local execBar = label(gui, "", UDim2.fromOffset(620, 40), UDim2.new(0.5, -310, 0, 74), Enum.Font.FredokaOne, Color3.fromHex("1A1240"))
execBar.BackgroundColor3 = C.Gold
execBar.BackgroundTransparency = 0.05
execBar.Visible = false
corner(execBar)

local function canIChoose(role: string): boolean
	if player:GetAttribute("Dead") then return false end
	local mine = "," .. (player:GetAttribute("Roles") or "") .. "," .. (player:GetAttribute("Belts") or "") .. ","
	if string.find(mine, "," .. role .. ",", 1, true) then return true end
	for _, p in Players:GetPlayers() do
		-- 16-nov: también cuenta quien lleva el cinturón de ese rol (igual que el servidor)
		local theirs = "," .. (p:GetAttribute("Roles") or "") .. "," .. (p:GetAttribute("Belts") or "") .. ","
		if not p:GetAttribute("Dead") and string.find(theirs, "," .. role .. ",", 1, true) then
			return false
		end
	end
	return true
end

local function refreshCard()
	local e = byId[GS:GetAttribute("Emergency") or ""]
	local stage = GS:GetAttribute("EmergencyStage") or ""
	card.Visible = e ~= nil and (stage == "choose" or stage == "protected")
	execBar.Visible = e ~= nil and stage == "execute"
	if e and stage == "execute" then
		local r = e[GS:GetAttribute("EmergencyChoice") or "A"]
		execBar.Text = "► " .. (r and r.Label or "") .. "   " .. (GS:GetAttribute("EmergencyProgress") or "") .. "   " .. fmt(GS:GetAttribute("EmergencyLeft") or 0)
	end
	if not card.Visible or not e then return end
	cTitle.Text = e.Title .. "  ·  " .. Config.Roles[e.Role].Name
	-- 15-nov: en las de clima espacial, el último evento real del Sol (o "SAVED NASA DATA" si no hay conexión)
	cData.Text = GS:GetAttribute("SW_" .. e.Id) or e.DataLine
	cText.Text = e.Text
	cFact.Text = e.Fact
	cTimer.Text = fmt(GS:GetAttribute("EmergencyLeft") or 0)
	local disabled = GS:GetAttribute("EmergencyDisabled") or ""
	local mine = canIChoose(e.Role)
	for _, letter in { "A", "B", "C" } do
		local b = buttons[letter]
		local r = e[letter]
		local off = string.find(disabled, letter, 1, true) ~= nil
		if stage == "protected" then
			b.Visible = letter == "A"
			b.Text = T3.Protected .. ": " .. (e.ProtectedNote or "your base was ready") -- texto de cada emergencia (PDF Fase 3)
			b.Active = false
		elseif stage == "execute" then
			local chosen = GS:GetAttribute("EmergencyChoice")
			b.Visible = true
			b.Text = letter .. ". " .. r.Label .. (letter == chosen and "  ← go to the glowing points!" or "")
			b.Active = false
			b.BackgroundColor3 = C.Panel2
		else
			b.Visible = true
			b.Text = letter .. ". " .. r.Label .. (off and ("   (" .. string.format(T3.Needs, "Phase 2 mission done") .. ")") or "")
			b.Active = mine and not off
			b.AutoButtonColor = b.Active
			b.BackgroundColor3 = b.Active and C.Panel2 or Color3.fromHex("2A2450")
			b.TextTransparency = b.Active and 0 or 0.45
		end
	end
end

---------------------------------------------------------------------
-- Luz que cruza la Luna (PDF 4.2): una sola animación, color del rol que decidió
---------------------------------------------------------------------
-- 16-nov: versión 3D (la del "si sobra tiempo"). La Luna es una esfera con mares y cráteres dentro de un
-- ViewportFrame. Los ViewportFrame no muestran PointLight, así que la "luz que cruza" es la luz del propio
-- ViewportFrame: su dirección va de izquierda a derecha en 3 s y su color es el del rol que decidió.
local moonView = Instance.new("ViewportFrame")
moonView.Name = "MoonLight"
moonView.Size = UDim2.fromOffset(260, 260)
moonView.Position = UDim2.new(0.5, -130, 0.5, -170)
moonView.BackgroundTransparency = 1
moonView.Ambient = Color3.fromRGB(70, 66, 96) -- el lado oscuro se ve un poco (sigue pareciendo la Luna)
moonView.Visible = false
moonView.Parent = gui
local moonCam = Instance.new("Camera")
moonCam.FieldOfView = 40
moonCam.CFrame = CFrame.lookAt(Vector3.new(0, 0, 31), Vector3.zero)
moonCam.Parent = moonView
moonView.CurrentCamera = moonCam

local moonModel = Instance.new("Model")
moonModel.Name = "Moon"
do
	local R = 10
	local function part(size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material): BasePart
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.Parent = moonModel
		return p
	end
	local sphere = part(Vector3.new(R * 2, R * 2, R * 2), CFrame.new(), Color3.fromRGB(196, 192, 206), Enum.Material.Slate)
	sphere.Shape = Enum.PartType.Ball
	moonModel.PrimaryPart = sphere
	-- Mancha pegada a la curva de la Luna (elipsoide aplanado): mares y cráteres
	local function patch(lat: number, lon: number, w: number, color: Color3, raise: number)
		local n = Vector3.new(math.cos(lat) * math.sin(lon), math.sin(lat), math.cos(lat) * math.cos(lon))
		local sag = w * w / (8 * R)
		local pos = n * (R - sag + raise)
		local p = part(Vector3.new(w, 2 * sag + 0.16, w), CFrame.lookAt(pos, pos + n) * CFrame.Angles(-math.pi / 2, 0, 0), color, Enum.Material.SmoothPlastic)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	local seed = Random.new(7)
	for _ = 1, 12 do
		patch(math.asin(seed:NextNumber(-0.95, 0.9)), seed:NextNumber(-math.pi, math.pi), seed:NextNumber(4, 8), Color3.fromRGB(150, 146, 170), 0)
	end
	for _ = 1, 40 do
		local lat, lon = math.asin(seed:NextNumber(-1, 1)), seed:NextNumber(-math.pi, math.pi)
		local w = seed:NextNumber(0.6, 2.4)
		patch(lat, lon, w * 1.3, Color3.fromRGB(212, 209, 224), 0.03)
		patch(lat, lon, w, Color3.fromRGB(136, 132, 156), 0.06)
	end
end
moonModel.Parent = moonView

local function PlayMoonLight(color: Color3)
	moonView.LightColor = color:Lerp(Color3.new(1, 1, 1), 0.35) -- color del rol, aclarado para que se vean los cráteres
	moonView.LightDirection = Vector3.new(1, -0.1, -0.15) -- la luz entra por la izquierda (apunta a la derecha)
	moonModel:PivotTo(CFrame.Angles(0.25, 0, 0))
	moonView.Visible = true
	local t = Config.Phase3.LightTime
	-- La luz barre la Luna de izquierda a derecha y la Luna gira un poco
	local tw = TweenService:Create(moonView, TweenInfo.new(t, Enum.EasingStyle.Sine), { LightDirection = Vector3.new(-1, -0.1, -0.15) })
	tw:Play()
	local t0 = os.clock()
	while os.clock() - t0 < t do
		moonModel:PivotTo(CFrame.Angles(0.25, (os.clock() - t0) / t * 0.8, 0))
		RunService.RenderStepped:Wait()
	end
	moonView.Visible = false
end

Remotes.MoonLight.OnClientEvent:Connect(function(role)
	local info = Config.Roles[role]
	task.spawn(PlayMoonLight, info and info.Color or Color3.fromHex("B7A8F0"))
end)

---------------------------------------------------------------------
-- Avisos (si Celeste todavía no tiene su HUD)
---------------------------------------------------------------------
local toast = label(gui, "", UDim2.fromOffset(560, 44), UDim2.new(0.5, -280, 0, 130), Enum.Font.FredokaOne, Color3.fromHex("1A1240"))
toast.BackgroundColor3 = C.Gold
toast.BackgroundTransparency = 0
toast.Visible = false
corner(toast)
local toastId = 0
Remotes.Toast.OnClientEvent:Connect(function(text, seconds)
	if celesteHUD() then return end
	toastId += 1
	local my = toastId
	toast.Text = text
	toast.Visible = true
	task.delay(seconds or 2.5, function()
		if toastId == my then toast.Visible = false end
	end)
end)

local factBox = frame(gui, "Fact", UDim2.fromOffset(400, 160), UDim2.new(1, -416, 1, -180), C.Panel2, 0.05) -- abajo a la derecha (a la izquierda están las tareas)
corner(factBox)
factBox.Visible = false
label(factBox, "DID YOU KNOW?", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 6), Enum.Font.FredokaOne, C.Gold)
local factText = label(factBox, "", UDim2.new(1, -20, 1, -36), UDim2.fromOffset(10, 30), Enum.Font.Gotham)
-- [arreglo Claude 15-nov] Los datos duran más (≈ 1,5 palabras por segundo, entre 15 y 35 s), no se tapan
-- uno al otro (esperan en fila) y se pueden cerrar con la X.
local factQueue: { string } = {}
local factShowing = false
local factId = 0
local closeFact = Instance.new("TextButton")
closeFact.Size = UDim2.fromOffset(28, 28)
closeFact.Position = UDim2.new(1, -34, 0, 4)
closeFact.BackgroundColor3 = C.Panel
closeFact.TextColor3 = C.Text
closeFact.Font = Enum.Font.FredokaOne
closeFact.TextSize = 18
closeFact.Text = "X"
closeFact.Parent = factBox
corner(closeFact, 8)
local showNextFact
local function hideFact()
	factId += 1
	factBox.Visible = false
	factShowing = false
	task.delay(0.3, showNextFact)
end
showNextFact = function()
	if factShowing or #factQueue == 0 then return end
	local text = table.remove(factQueue, 1)
	factShowing = true
	factId += 1
	local my = factId
	factText.Text = text
	factBox.Visible = true
	local words = select(2, string.gsub(text, "%S+", ""))
	task.delay(math.clamp(words / 1.5 + 6, 15, 35), function() if factId == my then hideFact() end end)
end
closeFact.MouseButton1Click:Connect(hideFact)
Remotes.Fact.OnClientEvent:Connect(function(text)
	if celesteHUD() then return end
	if typeof(text) ~= "string" or text == "" then return end
	table.insert(factQueue, text)
	if #factQueue > 3 then table.remove(factQueue, 1) end -- no acumular demasiados
	showNextFact()
end)

---------------------------------------------------------------------
-- Pantalla final (PDF 7.2 y 7.3)
---------------------------------------------------------------------
local endBox = frame(gui, "End", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.BgDark, 0.05)
endBox.Visible = false
local eTitle = label(endBox, "", UDim2.new(0.8, 0, 0, 70), UDim2.new(0.1, 0, 0.08, 0), Enum.Font.FredokaOne)
local eSub = label(endBox, "", UDim2.new(0.8, 0, 0, 32), UDim2.new(0.1, 0, 0.08, 76), Enum.Font.GothamBold, C.Muted)
local eBody = label(endBox, "", UDim2.new(0.7, 0, 0.5, 0), UDim2.new(0.15, 0, 0.26, 0), Enum.Font.GothamBold)
eBody.TextYAlignment = Enum.TextYAlignment.Top
local again = Instance.new("TextButton")
again.Size = UDim2.fromOffset(280, 64)
again.Position = UDim2.new(0.5, -140, 0.85, 0)
again.BackgroundColor3 = C.Red
again.TextColor3 = C.Text
again.Font = Enum.Font.FredokaOne
again.TextScaled = true
again.Parent = endBox
corner(again, 16)
again.MouseButton1Click:Connect(function()
	Remotes.ReadyUp:FireServer()
	again.Text = "WAITING…"
end)

local function helpedLines(): { string }
	local out = {}
	local ok = {
		half_buried = GS:GetAttribute("Spot_cap") == "half_buried",
		cargo = GS:GetAttribute("CargoArrived") == true,
		power = (GS:GetAttribute("EnergyUsed") or 0) <= (GS:GetAttribute("EnergyMade") or 0),
		recycler = GS:GetAttribute("Choice_life") == "recycler" and GS:GetAttribute("MissionComplete_life") == true, -- PDF: "reciclador al 100 %"
		trays = (GS:GetAttribute("Choice_bot") ~= "packaged") and GS:GetAttribute("Spot_bot") ~= "inside_habitat",
		protected = GS:GetAttribute("MissionComplete_eng") == true,
		repaired = not (GS:GetAttribute("Damaged_cap") or GS:GetAttribute("Damaged_eng") or GS:GetAttribute("Damaged_life") or GS:GetAttribute("Damaged_bot")),
		smart = (GS:GetAttribute("AnswersA") or 0) >= 3,
	}
	for _, h in Config.Helped do
		if ok[h.Id] and #out < 4 then table.insert(out, "✓ " .. h.Text) end
	end
	return out
end

local function showEnd()
	local won = GS:GetAttribute("Result") == "won"
	eTitle.Text = won and T3.MissionComplete or Config.Text.Failed
	eTitle.TextColor3 = won and C.Good or C.Bad
	local day = GS:GetAttribute("Day") or 0
	eSub.Text = won and T3.Survived7 or (day == 0 and T3.CrewLost or string.format(T3.SurvivedN, math.max(0, day - 1)))
	local lines = {}
	for _, r in Config.RoleOrder do
		local uid = GS:GetAttribute("Role_" .. r) or 0
		local p = Players:GetPlayerByUserId(uid)
		local alive = p and not p:GetAttribute("Dead")
		table.insert(lines, Config.Roles[r].Name .. ": " .. (alive and T3.Alive or T3.Lost))
	end
	local alive = 0
	for _, p in Players:GetPlayers() do if not p:GetAttribute("Dead") then alive += 1 end end
	table.insert(lines, "")
	table.insert(lines, string.format("Days: %d/7 · Survivors: %d/%d · Harvests: %d · Emergencies solved: %d/%d",
		won and 7 or math.max(0, (GS:GetAttribute("Day") or 1) - 1), alive, #Players:GetPlayers(),
		GS:GetAttribute("Harvests") or 0, GS:GetAttribute("EmergenciesSolved") or 0, GS:GetAttribute("EmergenciesSeen") or 0))
	-- Derrota: explicar por qué (quién se quedó sin qué y la causa principal; recursos de la base agotados)
	if not won then
		table.insert(lines, "")
		table.insert(lines, T3.WhyLostTitle)
		for _, p in Players:GetPlayers() do
			if p:GetAttribute("Dead") then
				local what = p:GetAttribute("DeathCause") == "water" and "water" or "oxygen"
				local first = string.split(p:GetAttribute("DeathWhy") or "", "\n")[1] or ""
				table.insert(lines, string.format(T3.WhyPlayer, p.DisplayName, what, first))
			end
		end
		if (GS:GetAttribute("ReserveO2") or 1) < 1 then table.insert(lines, string.format(T3.WhyTeamReserve, "oxygen")) end
		if (GS:GetAttribute("ReserveWater") or 1) < 1 then table.insert(lines, string.format(T3.WhyTeamReserve, "water")) end
		if (GS:GetAttribute("Food") or 1) <= 0 then table.insert(lines, T3.WhyTeamFood) end
		table.insert(lines, T3.DeathTip)
	end
	table.insert(lines, "")
	table.insert(lines, T3.WhatHelped)
	for _, l in helpedLines() do table.insert(lines, l) end
	eBody.Text = table.concat(lines, "\n")
	again.Text = won and T3.PlayAgain or Config.Text.TryAgain
	endBox.Visible = true
end

---------------------------------------------------------------------
-- Fase 2: tarjeta de inicio y lista de misiones (PDF Fase 2, caps. 3 y 4)
---------------------------------------------------------------------
local introBox = frame(gui, "Phase2Intro", UDim2.fromOffset(620, 330), UDim2.new(0.5, -310, 0.5, -165), C.Panel, 0.05)
corner(introBox, 20)
introBox.Visible = false
label(introBox, Config.Text.Phase2Title, UDim2.new(1, -40, 0, 44), UDim2.fromOffset(20, 14), Enum.Font.FredokaOne, C.Gold)
local introLines = {}
for i, role in Config.RoleOrder do
	local l = label(introBox, "", UDim2.new(1, -40, 0, 38), UDim2.fromOffset(20, 64 + (i - 1) * 44), Enum.Font.GothamBold, Config.Roles[role].Color)
	l.TextXAlignment = Enum.TextXAlignment.Left
	introLines[role] = l
end
label(introBox, Config.Text.Phase2Footer, UDim2.new(1, -40, 0, 22), UDim2.fromOffset(20, 246), Enum.Font.Gotham, C.Muted)
local readyBtn = Instance.new("TextButton")
readyBtn.Size = UDim2.fromOffset(200, 44)
readyBtn.Position = UDim2.new(0.5, -100, 1, -58)
readyBtn.BackgroundColor3 = C.Red
readyBtn.TextColor3 = C.Text
readyBtn.Font = Enum.Font.FredokaOne
readyBtn.TextScaled = true
readyBtn.Text = "READY"
readyBtn.Parent = introBox
corner(readyBtn, 12)
readyBtn.MouseButton1Click:Connect(function()
	Remotes.ReadyUp:FireServer()
	readyBtn.Text = "WAITING…"
end)

local missionBox = frame(gui, "Missions", UDim2.fromOffset(330, 236), UDim2.new(1, -346, 0, 80), C.Panel, 0.2)
corner(missionBox)
missionBox.Visible = false
local mLayout = Instance.new("UIListLayout")
mLayout.Padding = UDim.new(0, 2)
mLayout.Parent = missionBox
local mPad = Instance.new("UIPadding")
mPad.PaddingLeft = UDim.new(0, 10); mPad.PaddingTop = UDim.new(0, 8); mPad.PaddingRight = UDim.new(0, 10)
mPad.Parent = missionBox
local mLines = {}
for i = 1, 9 do
	local l = label(missionBox, "", UDim2.new(1, 0, 0, 22), UDim2.fromScale(0, 0), Enum.Font.GothamBold)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = i
	mLines[i] = l
end

local function missionText(role: string): (string, boolean)
	local choice = GS:GetAttribute("Choice_" .. role) or ""
	local f
	if role == "bot" then
		local o = Config.Missions.bot.ByOption[choice]
		f = o and o.List or "BOTANIST — Plant the trays (%d/%d)"
	else
		f = Config.Missions[role].List
	end
	local ok = GS:GetAttribute("MissionComplete_" .. role) == true
	return (ok and "✓ " or "• ") .. string.format(f, GS:GetAttribute("Mission_" .. role .. "_Done") or 0, GS:GetAttribute("Mission_" .. role .. "_Total") or 0), ok
end

local function updatePhase2(phase: string)
	introBox.Visible = phase == "Phase2Intro"
	missionBox.Visible = phase == "Phase2"
	if phase ~= "Phase2Intro" then readyBtn.Text = "READY" end
	if introBox.Visible then
		for _, role in Config.RoleOrder do
			introLines[role].Text = Config.Roles[role].Name .. ": " .. (GS:GetAttribute("Phase2Intro_" .. role) or "")
		end
	end
	if missionBox.Visible then
		local i = 0
		for _, role in Config.RoleOrder do
			i += 1
			local text, ok = missionText(role)
			mLines[i].Text = text
			mLines[i].TextColor3 = ok and C.Good or Config.Roles[role].Color
		end
		for _, role in Config.RoleOrder do
			if GS:GetAttribute("Damaged_" .. role) and i < 8 then
				i += 1
				mLines[i].Text = "• REPAIR — " .. Config.Roles[role].Name
				mLines[i].TextColor3 = C.Bad
			end
		end
		i += 1
		local used, made = GS:GetAttribute("EnergyUsed") or 0, GS:GetAttribute("EnergyMade") or 0
		mLines[i].Text = string.format(Config.Text.Energy, used, made)
		mLines[i].TextColor3 = used <= made and C.Good or C.Bad
		for k = i + 1, 9 do mLines[k].Text = "" end
		dayBox.Visible = true
		dayText.Text = "BUILD YOUR BASE   " .. fmt(GS:GetAttribute("TimeLeft") or 0)
	end
end

---------------------------------------------------------------------
-- Tareas del día (Fase 3, debajo de las barras): una por rol, ✓ al completarla. Las crea DailyTasks.
---------------------------------------------------------------------
local tasksBox = frame(gui, "Tasks", UDim2.fromOffset(330, 150), UDim2.fromOffset(16, 204), C.Panel, 0.15)
corner(tasksBox, 14)
tasksBox.Visible = false
label(tasksBox, Config.DailyTasks.Title, UDim2.new(1, -20, 0, 24), UDim2.fromOffset(12, 6), Enum.Font.FredokaOne, C.Gold).TextXAlignment = Enum.TextXAlignment.Left
local taskLines = {}
for i, role in Config.RoleOrder do
	local l = label(tasksBox, "", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 34 + (i - 1) * 28), Enum.Font.GothamBold)
	l.TextXAlignment = Enum.TextXAlignment.Left
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 17 -- todas las líneas del mismo tamaño
	cap.Parent = l
	taskLines[role] = l
end
local function updateTasks(show: boolean)
	tasksBox.Visible = show and GS:GetAttribute("Task_cap_Done") ~= nil
	if not tasksBox.Visible then return end
	local DT = Config.DailyTasks
	for _, role in Config.RoleOrder do
		local name = DT[role].Name
		if role == "eng" and GS:GetAttribute("Choice_eng") == "reactor" then name = DT.eng.NameReactor end
		if role == "bot" and GS:GetAttribute("Choice_bot") == "packaged" then name = DT.bot.NamePackaged end
		if role == "life" then name ..= " (" .. (GS:GetAttribute("Task_life_Progress") or "0/2") .. ")" end
		local done = GS:GetAttribute("Task_" .. role .. "_Done") == true
		taskLines[role].Text = (done and "✓ " or "• ") .. name
		taskLines[role].TextColor3 = done and C.Good or Config.Roles[role].Color
	end
end

---------------------------------------------------------------------
-- Paso Fase 2 → Fase 3 (antes eran 10 s sin nada en pantalla): qué quedó listo, qué sigue dañado,
-- la energía y CONTINUE (ReadyUp; GameManager sigue cuando todos lo pulsan o a los 10 s)
---------------------------------------------------------------------
local t23 = frame(gui, "Transition23", UDim2.fromOffset(700, 430), UDim2.new(0.5, -350, 0.5, -215), C.Panel, 0.05)
corner(t23, 18)
t23.Visible = false
local t23Title = label(t23, Config.Text.Phase2Done, UDim2.new(1, -40, 0, 50), UDim2.fromOffset(20, 16), Enum.Font.FredokaOne, C.Good)
local t23Site = label(t23, "", UDim2.new(1, -40, 0, 26), UDim2.fromOffset(20, 66), Enum.Font.GothamBold, C.Muted)
local t23Lines = {}
for i, role in Config.RoleOrder do
	local l = label(t23, "", UDim2.new(1, -60, 0, 26), UDim2.fromOffset(30, 100 + (i - 1) * 30), Enum.Font.GothamBold)
	l.TextXAlignment = Enum.TextXAlignment.Left
	t23Lines[role] = l
end
local t23Repair = label(t23, "", UDim2.new(1, -60, 0, 26), UDim2.fromOffset(30, 228), Enum.Font.GothamBold)
t23Repair.TextXAlignment = Enum.TextXAlignment.Left
local t23Energy = label(t23, "", UDim2.new(1, -60, 0, 26), UDim2.fromOffset(30, 260), Enum.Font.FredokaOne)
t23Energy.TextXAlignment = Enum.TextXAlignment.Left
label(t23, Config.Text.NextSurvive, UDim2.new(1, -40, 0, 28), UDim2.fromOffset(20, 300), Enum.Font.FredokaOne, C.Gold)
local t23Btn = Instance.new("TextButton")
t23Btn.Size = UDim2.fromOffset(240, 54)
t23Btn.Position = UDim2.new(0.5, -120, 1, -96)
t23Btn.BackgroundColor3 = C.Red
t23Btn.TextColor3 = C.Text
t23Btn.Font = Enum.Font.FredokaOne
t23Btn.TextScaled = true
t23Btn.Text = Config.Text.Continue
t23Btn.Parent = t23
corner(t23Btn, 14)
local t23Count = label(t23, "", UDim2.new(1, -40, 0, 22), UDim2.new(0, 20, 1, -36), Enum.Font.Gotham, C.Muted)
t23Btn.MouseButton1Click:Connect(function()
	Remotes.ReadyUp:FireServer()
	t23Btn.Text = "READY ✓"
	t23Btn.BackgroundColor3 = C.Good
end)
local function updateT23(phase: string)
	t23.Visible = phase == "Transition23"
	if phase ~= "Transition23" then
		t23Btn.Text = Config.Text.Continue
		t23Btn.BackgroundColor3 = C.Red
		return
	end
	local siteName = GS:GetAttribute("Site") or ""
	for _, s in Config.Sites do
		if s.Id == siteName then siteName = s.Name end
	end
	t23Site.Text = string.format(Config.Text.BaseBuiltAt, siteName)
	local damaged = {}
	for _, role in Config.RoleOrder do
		local info = Config.Roles[role]
		local ok = GS:GetAttribute("MissionComplete_" .. role) == true
		local M = Config.Missions
		local done = M[role] and ((role == "bot" and GS:GetAttribute("Choice_bot") == "packaged") and M.bot.DoneFood or M[role].Done) or ""
		t23Lines[role].Text = ok and ("✓ " .. info.Name .. " — " .. done) or ("✗ " .. string.format(Config.Text.MissionNotDone, info.Name))
		t23Lines[role].TextColor3 = ok and C.Text or C.Bad
		if GS:GetAttribute("Damaged_" .. role) then table.insert(damaged, info.Name) end
	end
	t23Repair.Text = #damaged > 0 and string.format(Config.Text.StillDamaged, table.concat(damaged, ", ")) or Config.Text.NothingDamaged
	t23Repair.TextColor3 = #damaged > 0 and C.Bad or C.Good
	local used, made = GS:GetAttribute("EnergyUsed") or 0, GS:GetAttribute("EnergyMade") or 0
	t23Energy.Text = (used <= made and Config.Text.EnoughPower or Config.Text.NotEnoughPower) .. "  (" .. string.format(Config.Text.Energy, used, made) .. ")"
	t23Energy.TextColor3 = used <= made and C.Good or C.Bad
	t23Count.Text = string.format(Config.Text.ReadyCount, GS:GetAttribute("ReadyCount") or 0, fmt(GS:GetAttribute("TimeLeft") or 0))
end

---------------------------------------------------------------------
-- Muerte: aviso arriba (pequeño) y cámara de espectador que sigue a un compañero vivo
---------------------------------------------------------------------
local deadBox = frame(gui, "Dead", UDim2.fromOffset(560, 190), UDim2.new(0.5, -280, 1, -210), C.BgDark, 0.2)
corner(deadBox, 16)
deadBox.Visible = false
local deadTitle = label(deadBox, "", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 6), Enum.Font.FredokaOne, C.Bad)
-- Por qué moriste (lo escribe Bars en DeathWhy) + consejo
local deadWhy = label(deadBox, "", UDim2.new(1, -24, 0, 100), UDim2.fromOffset(12, 40), Enum.Font.GothamBold, C.Text)
deadWhy.TextXAlignment = Enum.TextXAlignment.Left
deadWhy.TextYAlignment = Enum.TextYAlignment.Top
local whySize = Instance.new("UITextSizeConstraint")
whySize.MaxTextSize = 18
whySize.Parent = deadWhy
label(deadBox, T3.DeadSub, UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 1, -30), Enum.Font.GothamBold, C.Muted)

local watchIndex = 0
local function aliveOthers(): { Player }
	local list = {}
	for _, p in Players:GetPlayers() do
		if p ~= player and not p:GetAttribute("Dead") and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
			table.insert(list, p)
		end
	end
	return list
end
local function updateSpectate()
	local dead = player:GetAttribute("Dead") == true
	deadBox.Visible = dead and (GS:GetAttribute("Phase") or "") ~= "End"
	if not dead then return end
	deadTitle.Text = string.format(T3.DeadTitle, player:GetAttribute("DeathCause") == "water" and "WATER" or "OXYGEN")
	local why = player:GetAttribute("DeathWhy") or ""
	deadWhy.Text = (why ~= "" and ("• " .. string.gsub(why, "\n", "\n• ") .. "\n") or "") .. T3.DeathTip
	local list = aliveOthers()
	if #list > 0 then
		local target = list[(watchIndex % #list) + 1]
		local hum = target.Character:FindFirstChildOfClass("Humanoid")
		if hum and workspace.CurrentCamera.CameraSubject ~= hum then
			workspace.CurrentCamera.CameraSubject = hum
		end
	end
end
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and player:GetAttribute("Dead") and input.UserInputType == Enum.UserInputType.MouseButton1 then
		watchIndex += 1
	end
end)
player:GetAttributeChangedSignal("Dead"):Connect(function()
	if not player:GetAttribute("Dead") then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then workspace.CurrentCamera.CameraSubject = hum end
	end
end)

---------------------------------------------------------------------
-- Actualización
---------------------------------------------------------------------
local function refresh()
	local phase = GS:GetAttribute("Phase") or ""
	local inP3 = phase == "Phase3" or phase == "Rescue"
	dayBox.Visible = inP3
	baseBox.Visible = inP3
	sunLine.Visible = inP3 and GS:GetAttribute("SW_Summary") ~= nil
	sunLine.Text = GS:GetAttribute("SW_Summary") or ""
	local showBars = MOON_PHASES[phase] and not celesteHUD() and player:GetAttribute("O2") ~= nil
	barsBox.Visible = showBars == true
	gravity.Visible = MOON_PHASES[phase] == true and not celesteHUD()
	endBox.Visible = phase == "End" and GS:GetAttribute("Result") ~= ""
	if phase ~= "End" then again.Text = "" end

	if inP3 then
		dayText.Text = string.format(T3.Day, GS:GetAttribute("Day") or 1) .. "   " .. fmt(GS:GetAttribute("DayTimeLeft") or 0)
		foodT.Text = string.format(T3.Food, GS:GetAttribute("Food") or 0)
		foodT.TextColor3 = (GS:GetAttribute("Food") or 0) <= 0 and C.Bad or C.Text
		rO2T.Text = string.format(T3.ReserveO2, math.floor(GS:GetAttribute("ReserveO2") or 0))
		rWT.Text = string.format(T3.ReserveWater, math.floor(GS:GetAttribute("ReserveWater") or 0))
		local used, made = GS:GetAttribute("EnergyUsed") or 0, GS:GetAttribute("EnergyMade") or 0
		energyT.Text = string.format(Config.Text.Energy, used, made)
		energyT.TextColor3 = used <= made and C.Good or C.Bad
		local b = GS:GetAttribute("Blackout") or ""
		blackoutT.Text = b ~= "" and string.format(T3.Blackout, Config.BlackoutNames[b] or b) or ""
	end
	if showBars then
		o2Fill.Size = UDim2.fromScale(math.clamp((player:GetAttribute("O2") or 0) / 100, 0, 1), 1)
		waterFill.Size = UDim2.fromScale(math.clamp((player:GetAttribute("Water") or 0) / 100, 0, 1), 1)
		radFill.Size = UDim2.fromScale(math.clamp((player:GetAttribute("Radiation") or 0) / 100, 0, 1), 1)
		local nw = player:GetAttribute("NoWaterLeft")
		noWater.Text = nw and string.format(Config.Text.NoWater, fmt(nw)) or ""
	else
		noWater.Text = ""
	end
	refreshCard()
	updateSpectate()
	updatePhase2(phase)
	updateT23(phase)
	updateTasks(inP3 and phase == "Phase3")
end

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	refresh()
	if GS:GetAttribute("Phase") == "End" then showEnd() end
end)
GS:GetAttributeChangedSignal("Result"):Connect(function()
	if GS:GetAttribute("Phase") == "End" then showEnd() end
end)
task.spawn(function()
	while true do
		refresh()
		task.wait(0.25)
	end
end)

---------------------------------------------------------------------
-- Teclas de prueba (solo en Studio)
---------------------------------------------------------------------
if RunService:IsStudio() then
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.F6 then
			Remotes.DebugSkip:FireServer("day")
		elseif input.KeyCode == Enum.KeyCode.F7 then
			Remotes.DebugSkip:FireServer("fill")
		elseif input.KeyCode == Enum.KeyCode.F8 then
			local e = EmergencyData[math.random(1, #EmergencyData)]
			Remotes.DebugSkip:FireServer("emergency", e.Id)
		elseif input.KeyCode == Enum.KeyCode.F9 then
			Remotes.DebugSkip:FireServer("phase")
		end
	end)
end
