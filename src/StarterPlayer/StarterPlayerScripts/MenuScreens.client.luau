-- MenuScreens (LocalScript) -> StarterPlayer.StarterPlayerScripts.MenuScreens
-- Pantallas 2D del inicio (PDF Fase 0, caps. 3 y 10.3; lienzo de diseño "1 · Título", "2 · Elección de rol", "3 · Instrucciones"):
-- 1. Título (fase "Title"): etiqueta, nombre del juego, frase, botón PLAY y "1–4 players · PC".
-- 2. Elección de rol (fase "RoleSelect"): 4 tarjetas; doble clic para tomar o soltar un rol.
-- 3. Instrucciones (fase "Briefing"): misión del rol, cómo jugar, cuidado y botón READY.
-- 4. Mission failed (fase "Failed"): botón TRY AGAIN.
-- Todo se crea desde este script. Usa los Remotes de GameManager: PlayPressed, RequestRole y ReadyUp.
-- Quién tiene cada rol lo dice GameState.Role_<rol> (UserId, 0 = libre); lo escribe RolesAndSuits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local C = Config.Colors
local player = Players.LocalPlayer
local INK = Color3.fromHex("1A1240")
local DOUBLE_CLICK = 0.4 -- segundos entre los 2 clics

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

local function corner(o: Instance, r: number?)
	new("UICorner", { CornerRadius = r and UDim.new(0, r) or UDim.new(0.5, 0) }, o)
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local base = { BackgroundTransparency = 1, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 16 }
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base, parent)
end

-- Círculo de color (estrellas, Luna, Tierra, puntos)
local function circle(parent: Instance, x: number, y: number, size: number, color: Color3, transparency: number?): Frame
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size), BackgroundColor3 = color, BackgroundTransparency = transparency or 0, BorderSizePixel = 0 }, parent)
	corner(f)
	return f
end

local function fmt(t: number): string
	t = math.max(0, math.floor(t))
	return string.format("%d:%02d", t // 60, t % 60)
end

---------------------------------------------------------------------
-- ScreenGui y escalado (diseño en 1280 x 720)
---------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "SO_MenuScreens",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

-- Estrellas que titilan (siempre en el mismo lugar)
local starSeed = Random.new(11)
local function stars(parent: Instance, n: number)
	for i = 1, n do
		local s = starSeed:NextInteger(2, 4)
		local st = new("Frame", {
			Position = UDim2.fromOffset(starSeed:NextInteger(6, 1274), starSeed:NextInteger(6, 714)), Size = UDim2.fromOffset(s, s),
			BackgroundColor3 = C.Text, BackgroundTransparency = starSeed:NextNumber(0.15, 0.6), BorderSizePixel = 0,
		}, parent)
		corner(st)
		if i % 3 == 0 then
			TweenService:Create(st, TweenInfo.new(starSeed:NextNumber(1.2, 2.8), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.92 }):Play()
		 end
	end
end

local scales = {}
local function screen(): (Frame, Frame)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Text, BorderSizePixel = 0, Visible = false, ClipsDescendants = true }, gui)
	-- Fondo: morado oscuro arriba, casi negro abajo
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("241163"), C.BgDark) }, bg)
	local st = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1280, 720), BackgroundTransparency = 1 }, bg)
	table.insert(scales, new("UIScale", {}, st))
	stars(st, 45)
	return bg, st
end

-- Botón que crece un poco al pasar el ratón
local function hoverGrow(btn: GuiButton)
	local scale = new("UIScale", {}, btn)
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, info, { Scale = 1.05 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
end

-- Encabezado de color con las esquinas de arriba redondas (para tarjetas blancas)
local function cardHead(parent: Instance, height: number, color: Color3, r: number): Frame
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = color, BorderSizePixel = 0 }, parent)
	corner(head, r)
	new("Frame", { Position = UDim2.new(0, 0, 1, -r), Size = UDim2.new(1, 0, 0, r), BackgroundColor3 = color, BorderSizePixel = 0 }, head)
	return head
end

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

---------------------------------------------------------------------
-- 1. TÍTULO
---------------------------------------------------------------------
local titleBg, T = screen()

-- Luna grande: halo, sombra y cráteres con borde; flota despacio
local moonHolder = new("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, T)
circle(moonHolder, 1130 - 380, 640 - 380, 760, Color3.fromHex("B9A4FF"), 0.93)
circle(moonHolder, 1130 - 345, 640 - 345, 690, Color3.fromHex("B9A4FF"), 0.86)
local moonBody = circle(moonHolder, 820, 330, 620, Color3.fromHex("FFFFFF"))
new("UIGradient", { Rotation = 40, Color = ColorSequence.new(Color3.fromHex("EEE8FF"), Color3.fromHex("9682DB")) }, moonBody)
for _, cr in { { 110, 90, 110 }, { 290, 190, 70 }, { 200, 270, 46 }, { 360, 70, 34 }, { 60, 230, 28 }, { 420, 300, 54 }, { 250, 30, 22 } } do
	local c = circle(moonBody, cr[1], cr[2], cr[3], Color3.fromHex("8F7AD6"), 0.55)
	new("UIStroke", { Color = Color3.fromHex("F2EDFF"), Thickness = 3, Transparency = 0.35 }, c)
end
TweenService:Create(moonHolder, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.fromOffset(0, -14) }):Play()

-- La Tierra, pequeña y lejos, con atmósfera
local earth = circle(T, 1010, 70, 96, Config.Roles.life.Color)
new("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromHex("7FD6FF"), Color3.fromHex("1E4FBF")) }, earth)
new("UIStroke", { Color = C.Sky, Thickness = 4, Transparency = 0.4 }, earth)
for _, l in { { 18, 22, 34, 22 }, { 52, 52, 28, 18 }, { 30, 62, 16, 12 } } do
	local land = circle(earth, l[1], l[2], l[3], Config.Roles.bot.Color)
	land.Size = UDim2.fromOffset(l[3], l[4])
end

local col = new("Frame", { Position = UDim2.fromOffset(120, 210), Size = UDim2.fromOffset(760, 420), BackgroundTransparency = 1 }, T)
new("UIListLayout", { Padding = UDim.new(0, 22), SortOrder = Enum.SortOrder.LayoutOrder }, col)

-- Etiqueta azul "MOON BASE SURVIVAL" con punto rojo
local tag = new("Frame", { LayoutOrder = 1, BackgroundColor3 = Color3.fromHex("0B3D91"), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36) }, col)
corner(tag, 18)
new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, tag)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, tag)
local dot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(10, 10), BackgroundColor3 = C.Red }, tag)
corner(dot)
label(tag, { LayoutOrder = 2, Text = Config.Label, Font = Enum.Font.GothamBlack, TextSize = 14, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36) })

-- Nombre del juego: si tiene ":" va en dos líneas ("EVERY CHOICE COUNTS:" pequeño y dorado, "MOON BASE" grande)
local titleTop, titleMain = string.match(Config.GameTitle, "^(.-):%s*(.+)$")
local titleBox = new("Frame", { LayoutOrder = 2, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromOffset(760, 0) }, col)
new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, titleBox)
if titleTop then
	label(titleBox, { LayoutOrder = 1, Text = titleTop, Font = Enum.Font.FredokaOne, TextSize = 44, TextColor3 = C.Gold, Size = UDim2.fromOffset(760, 50), TextXAlignment = Enum.TextXAlignment.Left })
end
local bigTitle = label(titleBox, { LayoutOrder = 2, Text = titleMain or Config.GameTitle, Font = Enum.Font.FredokaOne, TextScaled = true, Size = UDim2.fromOffset(760, 104), TextXAlignment = Enum.TextXAlignment.Left })
new("UITextSizeConstraint", { MaxTextSize = 104 }, bigTitle)
new("UIStroke", { Color = Color3.fromHex("3B1E9C"), Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, bigTitle)
label(col, { LayoutOrder = 3, Text = Config.Tagline, TextColor3 = Color3.fromHex("DCD2FF"), TextSize = 26, Size = UDim2.fromOffset(760, 32), TextXAlignment = Enum.TextXAlignment.Left })

-- Botón PLAY rojo con sombra
local playHolder = new("Frame", { LayoutOrder = 4, BackgroundTransparency = 1, Size = UDim2.fromOffset(320, 104) }, col)
local playShadow = new("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.fromOffset(300, 84), BackgroundColor3 = Color3.fromHex("A8230F") }, playHolder)
corner(playShadow, 18)
local playBtn = new("TextButton", {
	Position = UDim2.fromOffset(0, 18), Size = UDim2.fromOffset(300, 84), BackgroundColor3 = C.Red,
	Text = "PLAY", Font = Enum.Font.FredokaOne, TextSize = 40, TextColor3 = C.Text, AutoButtonColor = true,
}, playHolder)
corner(playBtn, 18)
hoverGrow(playBtn)
label(col, { LayoutOrder = 5, Text = Config.Text.PlayersLine, TextColor3 = Color3.fromHex("B7A8F0"), TextSize = 16, Size = UDim2.fromOffset(400, 20), TextXAlignment = Enum.TextXAlignment.Left })

local pressed = false
playBtn.MouseButton1Click:Connect(function()
	if pressed then
		return
	end
	pressed = true
	playBtn.Text = P1.Text.PlayWaiting
	playBtn.TextSize = 30
	Remotes.PlayPressed:FireServer()
end)

---------------------------------------------------------------------
-- 2. ELECCIÓN DE ROL
---------------------------------------------------------------------
local rolesBg, Rs = screen()

label(Rs, { Text = Config.Text.ChooseRole, Font = Enum.Font.FredokaOne, TextSize = 56, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 62) })
label(Rs, { Text = Config.Text.ChooseRoleHint, TextColor3 = Color3.fromHex("DCD2FF"), TextSize = 22, Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 0, 28) })

-- Íconos hechos con formas simples (cohete, engranaje, gota, hoja)
local function icon(parent: Instance, kind: string, color: Color3)
	local box = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(80, 80), BackgroundTransparency = 1 }, parent)
	if kind == "rocket" then
		local body = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(40, 4), Size = UDim2.fromOffset(28, 58), BackgroundTransparency = 1 }, box)
		corner(body, 14)
		new("UIStroke", { Color = color, Thickness = 3 }, body)
		local win = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(14, 22), Size = UDim2.fromOffset(9, 9), BackgroundTransparency = 1 }, body)
		corner(win)
		new("UIStroke", { Color = color, Thickness = 3 }, win)
		for _, x in { 18, 62 } do
			local fin = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, 44), Size = UDim2.fromOffset(4, 22), BackgroundColor3 = color, Rotation = x < 40 and 35 or -35 }, box)
			corner(fin, 2)
		end
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(40, 66), Size = UDim2.fromOffset(4, 10), BackgroundColor3 = color }, box)
	elseif kind == "gear" then
		for i = 0, 3 do
			new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(40, 40), Size = UDim2.fromOffset(6, 70), BackgroundColor3 = color, Rotation = i * 45, BorderSizePixel = 0 }, box)
		end
		local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(40, 40), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Config.Roles.eng.Color }, box)
		corner(ring)
		new("UIStroke", { Color = color, Thickness = 4 }, ring)
		local hole = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(40, 40), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 }, box)
		corner(hole)
		new("UIStroke", { Color = color, Thickness = 3 }, hole)
	elseif kind == "drop" then
		local drop = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(40, 46), Size = UDim2.fromOffset(42, 42), BackgroundTransparency = 1, Rotation = 45 }, box)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, drop)
		new("UIStroke", { Color = color, Thickness = 3 }, drop)
		local tip = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(40, 24), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Config.Roles.life.Color, Rotation = 45, BorderSizePixel = 0 }, box)
		new("UIStroke", { Color = color, Thickness = 3 }, tip)
	elseif kind == "leaf" then
		local leaf = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(42, 38), Size = UDim2.fromOffset(32, 60), BackgroundTransparency = 1, Rotation = 40 }, box)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, leaf)
		new("UIStroke", { Color = color, Thickness = 3 }, leaf)
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(36, 46), Size = UDim2.fromOffset(3, 56), BackgroundColor3 = color, Rotation = 40, BorderSizePixel = 0 }, box)
	end
end

local cards = {}
for i, role in Config.RoleOrder do
	local info = Config.Roles[role]
	local x = 80 + (i - 1) * (262 + 24)
	local cardBtn = new("TextButton", {
		Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(x, 172), Size = UDim2.fromOffset(262, 400),
		BackgroundColor3 = C.Text,
	}, Rs)
	corner(cardBtn, 22)
	local ring = new("UIStroke", { Color = C.Gold, Thickness = 6, Enabled = false, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, cardBtn)
	local head = cardHead(cardBtn, 150, info.Color, 22)
	local dark = (role == "eng" or role == "bot")
	icon(head, info.Icon, dark and INK or C.Text)
	-- Al pasar el ratón, la tarjeta sube un poco
	local liftInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
	cardBtn.MouseEnter:Connect(function()
		TweenService:Create(cardBtn, liftInfo, { Position = UDim2.fromOffset(x, 162) }):Play()
	end)
	cardBtn.MouseLeave:Connect(function()
		TweenService:Create(cardBtn, liftInfo, { Position = UDim2.fromOffset(x, 172) }):Play()
	end)

	label(cardBtn, { Text = info.Name, Font = Enum.Font.FredokaOne, TextSize = 30, TextColor3 = P1.RoleDark[role], Position = UDim2.fromOffset(22, 168), Size = UDim2.new(1, -44, 0, 36), TextXAlignment = Enum.TextXAlignment.Left })
	label(cardBtn, { Text = info.Card, TextColor3 = INK, TextSize = 18, TextWrapped = true, Position = UDim2.fromOffset(22, 210), Size = UDim2.new(1, -44, 0, 80), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
	label(cardBtn, { Text = string.format(P1.Text.Room, info.Door), TextColor3 = Color3.fromHex("5A4F80"), Font = Enum.Font.GothamBlack, TextSize = 15, Position = UDim2.fromOffset(22, 300), Size = UDim2.new(1, -44, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
	-- Pista abajo: cómo tomar o soltar el rol
	local hint = label(cardBtn, {
		Text = P1.Text.JoinHint, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = P1.RoleDark[role],
		BackgroundTransparency = 0, BackgroundColor3 = Color3.fromHex("F1EDFF"),
		Position = UDim2.fromOffset(18, 340), Size = UDim2.new(1, -36, 0, 40),
	})
	corner(hint, 12)

	-- "YOU" arriba a la derecha
	local you = label(cardBtn, {
		Text = Config.Text.You, Font = Enum.Font.GothamBlack, TextSize = 14, BackgroundTransparency = 0, BackgroundColor3 = INK,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(56, 28), Visible = false, ZIndex = 3,
	})
	corner(you, 14)

	-- Capa oscura de "TAKEN BY"
	local taken = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Panel, BackgroundTransparency = 0, Visible = false, ZIndex = 5 }, cardBtn)
	corner(taken, 22)
	new("UIStroke", { Color = info.Color, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, taken)
	local headIcon = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, ZIndex = 6 }, taken)
	corner(headIcon)
	new("UIStroke", { Color = C.Text, Thickness = 3 }, headIcon)
	local shoulders = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 156), Size = UDim2.fromOffset(52, 26), BackgroundTransparency = 1, ZIndex = 6 }, taken)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, shoulders)
	new("UIStroke", { Color = C.Text, Thickness = 3 }, shoulders)
	label(taken, { Text = Config.Text.TakenBy, TextColor3 = Color3.fromHex("DCD2FF"), Font = Enum.Font.GothamBlack, TextSize = 16, Position = UDim2.fromOffset(0, 198), Size = UDim2.new(1, 0, 0, 20), ZIndex = 6 })
	local takenName = label(taken, { Text = "", Font = Enum.Font.FredokaOne, TextSize = 30, Position = UDim2.fromOffset(10, 224), Size = UDim2.new(1, -20, 0, 36), TextScaled = false, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6 })

	-- Doble clic: tomar o soltar el rol (RolesAndSuits decide si se puede)
	local lastClick = 0
	cardBtn.MouseButton1Click:Connect(function()
		local now = os.clock()
		if now - lastClick <= DOUBLE_CLICK then
			lastClick = 0
			Remotes.RequestRole:FireServer(role)
		else
			lastClick = now
		end
	end)

	cards[role] = { ring = ring, you = you, taken = taken, takenName = takenName, hint = hint }
end

-- Abajo: cuántos roles hay tomados y el reloj
local countPill = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(80, 628), Size = UDim2.fromOffset(300, 48), BackgroundColor3 = Color3.fromHex("2A1C6E") }, Rs)
corner(countPill, 24)
local dots = {}
for i, role in Config.RoleOrder do
	dots[role] = circle(countPill, 18 + (i - 1) * 20, 17, 14, Color3.fromHex("5A4F80"))
end
local countText = label(countPill, { Text = "", TextSize = 20, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(104, 0), Size = UDim2.new(1, -112, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
local autoText = new("TextLabel", {
	BackgroundTransparency = 1, RichText = true, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.fromHex("DCD2FF"),
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(400, 628), Size = UDim2.fromOffset(500, 30), TextXAlignment = Enum.TextXAlignment.Left,
}, Rs)

-- [15-nov] Botón READY: aparece cuando TODOS los jugadores ya tienen un rol. Si todos lo pulsan, se pasa
-- a la siguiente pantalla sin esperar el reloj (GameManager termina RoleSelect con READY de todos).
local rolesReady = new("TextButton", {
	Text = P1.Text.RolesReady, Font = Enum.Font.FredokaOne, TextSize = 26, TextColor3 = C.Text, BackgroundColor3 = C.Red,
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(1200, 628), Size = UDim2.fromOffset(240, 54), Visible = false, AutoButtonColor = true,
}, Rs)
corner(rolesReady, 18)
hoverGrow(rolesReady)
local rolesReadySent = false
rolesReady.MouseButton1Click:Connect(function()
	if rolesReadySent or GS:GetAttribute("Phase") ~= "RoleSelect" then
		return
	end
	rolesReadySent = true
	Remotes.ReadyUp:FireServer()
end)

-- ¿Todos los jugadores tienen al menos un rol?
local function everyoneHasRole(): boolean
	local list = Players:GetPlayers()
	if #list == 0 then
		return false
	end
	for _, p in list do
		local has = false
		for _, role in Config.RoleOrder do
			if (GS:GetAttribute("Role_" .. role) or 0) == p.UserId then
				has = true
			end
		end
		if not has then
			return false
		end
	end
	return true
end

-- [Claude 15-nov] READY aparece cuando YO ya tengo un rol (no hace falta que todos tengan);
-- al pulsarlo, a quien no eligió le toca uno al azar y los que sobran se reparten (RolesAndSuits).
local function iHaveRole(): boolean
	for _, role in Config.RoleOrder do
		if (GS:GetAttribute("Role_" .. role) or 0) == Players.LocalPlayer.UserId then return true end
	end
	return false
end

local function drawRolesReady()
	local ok = iHaveRole()
	rolesReady.Visible = ok
	if rolesReadySent then
		rolesReady.Text = string.format(P1.Text.RolesWaiting, GS:GetAttribute("ReadyCount") or 0, #Players:GetPlayers())
		rolesReady.BackgroundColor3 = C.Good
	else
		rolesReady.Text = P1.Text.RolesReady
		rolesReady.BackgroundColor3 = C.Red
	end
end
GS:GetAttributeChangedSignal("ReadyCount"):Connect(drawRolesReady)
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if GS:GetAttribute("Phase") == "RoleSelect" then
		rolesReadySent = false
	end
	drawRolesReady()
end)

local function drawRoles()
	local takenCount = 0
	for _, role in Config.RoleOrder do
		local owner = GS:GetAttribute("Role_" .. role) or 0
		local c = cards[role]
		local mine = owner == player.UserId
		local other = owner ~= 0 and not mine
		if owner ~= 0 then
			takenCount += 1
		end
		c.you.Visible = mine
		c.ring.Enabled = mine
		c.taken.Visible = other
		c.hint.Text = mine and P1.Text.LeaveHint or P1.Text.JoinHint
		c.hint.BackgroundColor3 = mine and C.Gold or Color3.fromHex("F1EDFF")
		c.hint.TextColor3 = mine and INK or P1.RoleDark[role]
		if other then
			local p = Players:GetPlayerByUserId(owner)
			c.takenName.Text = p and p.DisplayName or "?"
		end
		dots[role].BackgroundColor3 = owner ~= 0 and Config.Roles[role].Color or Color3.fromHex("5A4F80")
	end
	countText.Text = string.format(Config.Text.RolesTaken, takenCount)
	local gold = "#" .. C.Gold:ToHex()
	autoText.Text = string.format(Config.Text.AutoAssign, '<font color="' .. gold .. '"><b>' .. fmt(GS:GetAttribute("TimeLeft") or 0) .. "</b></font>")
	drawRolesReady()
end

for _, role in Config.RoleOrder do
	GS:GetAttributeChangedSignal("Role_" .. role):Connect(drawRoles)
end
Players.PlayerAdded:Connect(drawRoles)
Players.PlayerRemoving:Connect(function()
	task.defer(drawRoles)
end)

---------------------------------------------------------------------
-- 3. INSTRUCCIONES (fase "Briefing"): misión, cómo jugar, cuidado y botón READY
---------------------------------------------------------------------
local briefBg, B = screen()

local function hex(c: Color3): string
	return "#" .. c:ToHex()
end

-- Botón rojo con sombra (PLAY, READY, TRY AGAIN)
local function redButton(parent: Instance, text: string, x: number, y: number, w: number, h: number): TextButton
	local shadow = new("Frame", { Position = UDim2.fromOffset(x, y + 7), Size = UDim2.fromOffset(w, h), BackgroundColor3 = Color3.fromHex("A8230F") }, parent)
	corner(shadow, 18)
	local b = new("TextButton", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = C.Red,
		Text = text, Font = Enum.Font.FredokaOne, TextSize = 32, TextColor3 = C.Text, AutoButtonColor = true,
	}, parent)
	corner(b, 18)
	hoverGrow(b)
	return b
end

label(B, { Text = Config.Text.BriefingTitle, Font = Enum.Font.FredokaOne, TextSize = 48, Position = UDim2.fromOffset(64, 44), Size = UDim2.fromOffset(600, 56), TextXAlignment = Enum.TextXAlignment.Left })
local tagPill = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(1216, 50), Size = UDim2.fromOffset(460, 44), BackgroundColor3 = Color3.fromHex("0B3D91") }, B)
corner(tagPill, 22)
local clock = new("Frame", { Position = UDim2.fromOffset(20, 12), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 }, tagPill)
corner(clock)
new("UIStroke", { Color = C.Text, Thickness = 2 }, clock)
new("Frame", { Position = UDim2.fromOffset(9, 4), Size = UDim2.fromOffset(2, 7), BackgroundColor3 = C.Text, BorderSizePixel = 0 }, clock)
label(tagPill, { Text = Config.Text.BriefingTag, Font = Enum.Font.GothamBlack, TextSize = 17, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })

-- Tarjeta blanca con encabezado de color
local function briefCard(i: number, title: string, color: Color3, dark: boolean): Frame
	local x = 64 + (i - 1) * (368 + 24)
	local card = new("Frame", { Position = UDim2.fromOffset(x, 126), Size = UDim2.fromOffset(368, 432), BackgroundColor3 = C.Text }, B)
	corner(card, 22)
	local head = cardHead(card, 70, color, 22)
	label(head, { Text = title, Font = Enum.Font.FredokaOne, TextSize = 26, TextColor3 = dark and INK or C.Text, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -48, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
	local body = new("Frame", { Position = UDim2.fromOffset(24, 92), Size = UDim2.new(1, -48, 1, -110), BackgroundTransparency = 1 }, card)
	new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	return body
end

local function para(parent: Instance, order: number, text: string, size: number?): TextLabel
	return label(parent, {
		LayoutOrder = order, Text = text, RichText = true, TextColor3 = INK, TextSize = size or 20, TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
	})
end

-- YOUR MISSION (cambia según el rol del jugador)
local missionBody = briefCard(1, "YOUR MISSION", Config.Roles.eng.Color, true)
local mission1 = para(missionBody, 1, "")
local mission2 = para(missionBody, 2, "")
local mission3 = para(missionBody, 3, "")
local missionExtra = para(missionBody, 4, "", 16)

-- HOW TO PLAY (sale de Config.Text.HowToPlay: "WASD: Move · Click: ...")
local howBody = briefCard(2, "HOW TO PLAY", Config.Roles.life.Color, false)
local function keyChip(parent: Instance, text: string, red: boolean)
	local chip = label(parent, {
		Text = text, Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = INK, BackgroundTransparency = 0,
		BackgroundColor3 = red and Color3.fromHex("FFE9E5") or Color3.fromHex("E9E3FF"),
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30),
	})
	corner(chip, 7)
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, chip)
	new("UIStroke", { Color = red and C.Red or Color3.fromHex("B7A8F0"), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, chip)
end
for i, item in string.split(Config.Text.HowToPlay, " · ") do
	local key, what = string.match(item, "^(.-):%s*(.+)$")
	if key then
		local row = new("Frame", { LayoutOrder = i, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 30) }, howBody)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, row)
		local keys = new("Frame", { LayoutOrder = 1, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30) }, row)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, keys)
		if key == "WASD" then
			for _, k in { "W", "A", "S", "D" } do
				keyChip(keys, k, false)
			end
		else
			keyChip(keys, key, key == "Double-click")
		end
		label(row, { LayoutOrder = 2, Text = "  " .. what, TextColor3 = INK, TextSize = 18, TextWrapped = true, Size = UDim2.new(1, -150, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left })
	end
end

-- WATCH OUT (Config.Text.WatchOut en 2 párrafos, con las partes importantes en rojo)
local watchBody = briefCard(3, "WATCH OUT", C.Red, false)
local redText = '<font color="#C2290F">%1</font>'
local watch = Config.Text.WatchOut
local cut = string.find(watch, " When ", 1, true)
local w1 = cut and string.sub(watch, 1, cut - 1) or watch
local w2 = cut and string.sub(watch, cut + 1) or ""
para(watchBody, 1, (string.gsub(w1, "(too heavy)", redText)), 18)
para(watchBody, 2, (string.gsub(w2, "(%d+ seconds)", redText)), 18)

local readyBtn = redButton(B, "READY", 300, 596, 300, 70)
local readyText = new("TextLabel", {
	BackgroundTransparency = 1, RichText = true, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.fromHex("DCD2FF"),
	Position = UDim2.fromOffset(630, 606), Size = UDim2.fromOffset(560, 50), TextXAlignment = Enum.TextXAlignment.Left,
}, B)
local readySent = false
readyBtn.MouseButton1Click:Connect(function()
	if readySent then
		return
	end
	readySent = true
	readyBtn.Text = "READY ✓"
	readyBtn.BackgroundColor3 = C.Good
	Remotes.ReadyUp:FireServer()
end)

local function drawBriefing()
	local role = player:GetAttribute("Role") or ""
	local info = Config.Roles[role]
	if info then
		-- "You are the ENGINEER. Go to the yellow door. Choose how ..." → 3 líneas con colores
		local parts = string.split(info.Mission, ". ")
		local name = '<font color="' .. hex(P1.RoleDark[role]) .. '"><b>' .. info.Name .. "</b></font>"
		mission1.Text = (string.gsub(parts[1] or "", info.Name, name)) .. "."
		mission2.Text = (string.gsub(parts[2] or "", info.Door, '<mark color="' .. hex(info.Color) .. '">' .. info.Door .. "</mark>")) .. "."
		mission3.Text = table.concat(parts, ". ", 3)
	else
		mission1.Text, mission2.Text, mission3.Text = "", "", ""
	end
	-- Con menos de 4 jugadores alguien tiene más de un rol
	local others = {}
	for _, r in string.split(player:GetAttribute("Roles") or "", ",") do
		if r ~= role and Config.Roles[r] then
			table.insert(others, Config.Roles[r].Name .. " (" .. Config.Roles[r].Door .. ")")
		end
	end
	missionExtra.Text = #others > 0 and ("Also: " .. table.concat(others, ", ")) or ""
	readyText.Text = string.format(Config.Text.ReadyCount, GS:GetAttribute("ReadyCount") or 0,
		'<font color="' .. hex(C.Gold) .. '"><b>' .. fmt(GS:GetAttribute("TimeLeft") or 0) .. "</b></font>")
end

---------------------------------------------------------------------
-- 4. MISSION FAILED (fase "Failed"): la nave se fue sin ellos. TRY AGAIN = ReadyUp
---------------------------------------------------------------------
local failBg, F = screen()
-- Luna gris al fondo: la nave se fue sin ellos
local sadMoon = circle(F, 1000, 470, 360, Color3.fromHex("6E6492"))
for _, cr in { { 70, 60, 70 }, { 200, 140, 44 }, { 110, 200, 30 } } do
	circle(sadMoon, cr[1], cr[2], cr[3], Color3.fromHex("5A5080"))
end
label(F, { Text = Config.Text.Failed, Font = Enum.Font.FredokaOne, TextSize = 80, TextColor3 = C.Bad, Position = UDim2.fromOffset(0, 210), Size = UDim2.new(1, 0, 0, 90) })
label(F, { Text = Config.Text.FailedText, TextColor3 = Color3.fromHex("DCD2FF"), TextSize = 24, Position = UDim2.fromOffset(0, 320), Size = UDim2.new(1, 0, 0, 34) })
-- [arreglo Claude 15-nov] Qué hacer la próxima vez y un dato real (Config.Text.FailedTip / FailedFact)
label(F, { Text = Config.Text.FailedTip, TextColor3 = C.Gold, TextSize = 24, TextWrapped = true, Position = UDim2.fromOffset(140, 380), Size = UDim2.new(0, 760, 0, 64) })
label(F, { Text = Config.Text.FailedFactTitle, Font = Enum.Font.FredokaOne, TextColor3 = C.Gold, TextSize = 22, Position = UDim2.fromOffset(140, 470), Size = UDim2.new(0, 760, 0, 28) })
label(F, { Text = Config.Text.FailedFact, TextColor3 = Color3.fromHex("DCD2FF"), TextSize = 20, TextWrapped = true, Position = UDim2.fromOffset(140, 500), Size = UDim2.new(0, 760, 0, 60) })
local tryBtn = redButton(F, Config.Text.TryAgain, 490, 590, 300, 76)
local trySent = false
tryBtn.MouseButton1Click:Connect(function()
	if trySent then
		return
	end
	trySent = true
	tryBtn.Text = "READY ✓"
	tryBtn.BackgroundColor3 = C.Good
	Remotes.ReadyUp:FireServer()
end)

---------------------------------------------------------------------
-- Aviso simple ("That role is taken.") solo mientras se ven estas pantallas
---------------------------------------------------------------------
local toast = label(gui, {
	Text = "", Font = Enum.Font.FredokaOne, TextSize = 22, TextColor3 = INK, BackgroundTransparency = 0, BackgroundColor3 = C.Gold,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 24), Size = UDim2.fromOffset(420, 44), Visible = false, ZIndex = 10,
})
corner(toast, 14)
local toastId = 0
Remotes.Toast.OnClientEvent:Connect(function(text, seconds)
	if not (titleBg.Visible or rolesBg.Visible or briefBg.Visible or failBg.Visible) then
		return -- en las demás fases los avisos los muestra Phase3HUD
	end
	toastId += 1
	local my = toastId
	toast.Text = text
	toast.Visible = true
	task.delay(seconds or 2.5, function()
		if toastId == my then
			toast.Visible = false
		end
	end)
end)

---------------------------------------------------------------------
-- Mostrar la pantalla que toca según la fase
---------------------------------------------------------------------
local function applyPhase()
	local p = GS:GetAttribute("Phase") or ""
	-- Antes de que GameManager arranque (Phase vacía) también se ve el título
	titleBg.Visible = (p == "Title" or p == "")
	rolesBg.Visible = (p == "RoleSelect")
	briefBg.Visible = (p == "Briefing")
	failBg.Visible = (p == "Failed")
	if p == "Title" or p == "" then
		pressed = false
		playBtn.Text = "PLAY"
		playBtn.TextSize = 40
	end
	-- Cada vez que se abre la pantalla, el botón vuelve a estar sin pulsar
	if p == "Briefing" then
		readySent = false
		readyBtn.Text = "READY"
		readyBtn.BackgroundColor3 = C.Red
	elseif p == "Failed" then
		trySent = false
		tryBtn.Text = Config.Text.TryAgain
		tryBtn.BackgroundColor3 = C.Red
	end
	if not (titleBg.Visible or rolesBg.Visible or briefBg.Visible or failBg.Visible) then
		toast.Visible = false
	end
	drawRoles()
	drawBriefing()
end

GS:GetAttributeChangedSignal("Phase"):Connect(applyPhase)
GS:GetAttributeChangedSignal("TimeLeft"):Connect(function()
	if rolesBg.Visible then
		drawRoles()
	elseif briefBg.Visible then
		drawBriefing()
	end
end)
GS:GetAttributeChangedSignal("ReadyCount"):Connect(function()
	if briefBg.Visible then
		drawBriefing()
	end
end)
player:GetAttributeChangedSignal("Roles"):Connect(function()
	if briefBg.Visible then
		drawBriefing()
	end
end)

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
