-- SettingsMenu (LocalScript) -> StarterPlayer.StarterPlayerScripts.SettingsMenu
-- [15-nov] Botón de engranaje (a la izquierda, en el medio) que abre las opciones:
-- 1. Volumen de la música y de los efectos (de 0 a 100 %, de a 10). SoundManager lo aplica con Opt_Music / Opt_SFX.
-- 2. Texto grande: multiplica el tamaño de letra de todas las pantallas (Config.Extras.BigTextScale).
-- 3. Créditos: equipo y fuentes de la ciencia (Config.Extras.Credits).
-- Todo es solo para este jugador. Textos y números en ReplicatedStorage.Config.Extras.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local T = X.Text
local C = Config.Colors
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local INK = Color3.fromHex("1A1240")
local PANEL = Color3.fromHex("2A1C6E")

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end
local function corner(o: Instance, r: number?)
	new("UICorner", { CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0) }, o)
end

local gui = new("ScreenGui", { Name = "SO_SettingsMenu", ResetOnSpawn = false, DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, pg)
gui:SetAttribute("NoBigText", true) -- este menú no se agranda (ya es grande)

-- Botón de engranaje
local gear = new("TextButton", {
	Text = "⚙", Font = Enum.Font.GothamBold, TextSize = 30, TextColor3 = C.Text, BackgroundColor3 = PANEL, BackgroundTransparency = 0.1,
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, -60), Size = UDim2.fromOffset(52, 52),
}, gui)
corner(gear)
new("UIStroke", { Color = C.Text, Thickness = 2, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, gear)

-- Fondo oscuro + panel
local shade = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false }, gui)
local panel = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 400), BackgroundColor3 = PANEL, Active = true }, shade)
corner(panel, 24)
new("UIStroke", { Color = C.Text, Thickness = 3, Transparency = 0.5 }, panel)
new("UIScale", {}, panel)

local function label(parent: Instance, text: string, size: number, pos: UDim2, w: number, h: number, align: Enum.TextXAlignment?): TextLabel
	return new("TextLabel", { Text = text, Font = Enum.Font.FredokaOne, TextSize = size, TextColor3 = C.Text, BackgroundTransparency = 1,
		Position = pos, Size = UDim2.fromOffset(w, h), TextXAlignment = align or Enum.TextXAlignment.Left, TextWrapped = true }, parent)
end
local function button(parent: Instance, text: string, pos: UDim2, w: number, h: number, color: Color3): TextButton
	local b = new("TextButton", { Text = text, Font = Enum.Font.FredokaOne, TextSize = 24, TextColor3 = INK, BackgroundColor3 = color, Position = pos, Size = UDim2.fromOffset(w, h) }, parent)
	corner(b, 14)
	return b
end

label(panel, T.Settings, 34, UDim2.fromOffset(28, 18), 400, 44)

-- Fila de volumen: [-] barra [+]
local function volumeRow(y: number, title: string, attr: string)
	label(panel, title, 24, UDim2.fromOffset(28, y), 200, 30)
	local minus = button(panel, "−", UDim2.fromOffset(28, y + 36), 48, 44, C.Text)
	local plus = button(panel, "+", UDim2.fromOffset(384, y + 36), 48, 44, C.Text)
	local bar = new("Frame", { Position = UDim2.fromOffset(88, y + 50), Size = UDim2.fromOffset(284, 16), BackgroundColor3 = Color3.fromHex("140C3A") }, panel)
	corner(bar, 8)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Gold }, bar)
	corner(fill, 8)
	local pct = label(panel, "", 20, UDim2.fromOffset(300, y), 132, 30, Enum.TextXAlignment.Right)
	local function draw()
		local v = player:GetAttribute(attr) or 1
		fill.Size = UDim2.fromScale(v, 1)
		pct.Text = math.floor(v * 100 + 0.5) .. "%"
	end
	local function step(d: number)
		local v = player:GetAttribute(attr) or 1
		player:SetAttribute(attr, math.clamp(math.floor((v + d) * 10 + 0.5) / 10, 0, 1))
	end
	minus.MouseButton1Click:Connect(function() step(-0.1) end)
	plus.MouseButton1Click:Connect(function() step(0.1) end)
	player:GetAttributeChangedSignal(attr):Connect(draw)
	draw()
end
volumeRow(76, T.Music, "Opt_Music")
volumeRow(166, T.Effects, "Opt_SFX")

-- Texto grande
label(panel, T.BigText, 24, UDim2.fromOffset(28, 268), 220, 40)
local bigBtn = button(panel, T.Off, UDim2.fromOffset(312, 264), 120, 44, C.Bad)

-- Créditos y cerrar
local creditsBtn = button(panel, T.Credits, UDim2.fromOffset(28, 330), 196, 50, C.Sky)
local closeBtn = button(panel, T.Close, UDim2.fromOffset(236, 330), 196, 50, C.Gold)

---------------------------------------------------------------------
-- Texto grande: guarda el tamaño original y lo multiplica
---------------------------------------------------------------------
local big = false
local function isMine(o: Instance): boolean
	local sg = o:FindFirstAncestorOfClass("ScreenGui")
	return sg ~= nil and sg:GetAttribute("NoBigText") == true
end
local function applyText(o: Instance)
	if not (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) or isMine(o) then
		return
	end
	local t = o :: TextLabel
	if t.TextScaled then
		return
	end
	local orig = t:GetAttribute("OrigTextSize")
	if orig == nil then
		orig = t.TextSize
		t:SetAttribute("OrigTextSize", orig)
	end
	t.TextSize = big and math.min(100, math.floor(orig * X.BigTextScale)) or orig
end
local function applyAll()
	for _, d in pg:GetDescendants() do
		applyText(d)
	end
end
pg.DescendantAdded:Connect(function(d)
	if big then
		task.defer(applyText, d)
	end
end)
bigBtn.MouseButton1Click:Connect(function()
	big = not big
	bigBtn.Text = big and T.On or T.Off
	bigBtn.BackgroundColor3 = big and C.Good or C.Bad
	applyAll()
end)

---------------------------------------------------------------------
-- Créditos
---------------------------------------------------------------------
local creds = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(620, 520), BackgroundColor3 = PANEL, Visible = false, Active = true }, shade)
corner(creds, 24)
new("UIStroke", { Color = C.Text, Thickness = 3, Transparency = 0.5 }, creds)
label(creds, T.CreditsTitle, 32, UDim2.fromOffset(28, 18), 564, 44, Enum.TextXAlignment.Center)
local list = new("ScrollingFrame", { Position = UDim2.fromOffset(28, 74), Size = UDim2.fromOffset(564, 360), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, creds)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local order = 0
local function line(text: string, size: number, color: Color3)
	order += 1
	new("TextLabel", { Text = text, Font = size >= 24 and Enum.Font.FredokaOne or Enum.Font.GothamMedium, TextSize = size, TextColor3 = color, BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order }, list)
end
line(T.TeamTitle, 26, C.Gold)
for _, n in X.Credits.Team do line("• " .. n, 20, C.Text) end
line(" ", 10, C.Text)
line(T.SourcesTitle, 26, C.Gold)
for _, s in X.Credits.Sources do line("• " .. s, 18, C.Text) end
line(" ", 10, C.Text)
line(T.Thanks, 20, C.Sky)
local credClose = button(creds, T.Close, UDim2.fromOffset(210, 450), 200, 50, C.Gold)

---------------------------------------------------------------------
-- Abrir / cerrar
---------------------------------------------------------------------
local function open(which: Frame?)
	shade.Visible = which ~= nil
	panel.Visible = which == panel
	creds.Visible = which == creds
	if which then
		local s = which:FindFirstChildOfClass("UIScale") or new("UIScale", {}, which)
		-- que quepa en pantallas chicas
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local fit = math.min(1, (vp.Y - 60) / which.Size.Y.Offset, (vp.X - 40) / which.Size.X.Offset)
		s.Scale = fit * 0.85
		TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = fit }):Play()
	end
end
gear.MouseButton1Click:Connect(function() open(shade.Visible and nil or panel) end)
closeBtn.MouseButton1Click:Connect(function() open(nil) end)
creditsBtn.MouseButton1Click:Connect(function() open(creds) end)
credClose.MouseButton1Click:Connect(function() open(panel) end)
shade.MouseButton1Click:Connect(function() open(nil) end)
