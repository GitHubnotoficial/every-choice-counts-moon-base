-- SO_Diploma (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_Diploma
-- Hecho por Claude (16-nov) a pedido de Jose. Al terminar la partida (fase End) sale primero un diploma de
-- "JUNIOR ASTRONAUT" con tu nombre, tu rol y de 1 a 3 estrellas. Debajo queda la pantalla final de Phase3HUD;
-- el botón SEE RESULTS cierra el diploma. Las estrellas:
--   1. Mission: el equipo sobrevivió los 7 días.
--   2. Teamwork: hiciste tu misión de la Fase 2 (la de alguno de tus roles).
--   3. Explorer: encontraste 3 o más rocas lunares (SO_MoonRocks).
-- Siempre hay al menos 1 estrella por haber participado (para niños: nadie se va con cero).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local C = Config.Colors

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SO_Diploma"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(10, 6, 30)
shade.BackgroundTransparency = 0.25
shade.BorderSizePixel = 0
shade.Parent = gui

-- Diseño en 1280x720 con UIScale (como el resto de las pantallas)
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.Size = UDim2.fromOffset(1280, 720)
holder.BackgroundTransparency = 1
holder.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = holder
local function fit()
	local v = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.min(v.X / 1280, v.Y / 720)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
fit()

local function corner(o: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
end
local function label(parent: Instance, text: string, y: number, h: number, font: Enum.Font, color: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -120, 0, h)
	t.Position = UDim2.fromOffset(60, y)
	t.BackgroundTransparency = 1
	t.Text = text
	t.Font = font
	t.TextColor3 = color
	t.TextScaled = true
	t.Parent = parent
	return t
end

-- El papel del diploma
local paper = Instance.new("Frame")
paper.AnchorPoint = Vector2.new(0.5, 0.5)
paper.Position = UDim2.new(0.5, 0, 0.5, -36)
paper.Size = UDim2.fromOffset(900, 580)
paper.BackgroundColor3 = Color3.fromRGB(250, 246, 232)
paper.Parent = holder
corner(paper, 18)
local border = Instance.new("UIStroke")
border.Thickness = 8
border.Color = C.Gold
border.Parent = paper
local inner = Instance.new("Frame")
inner.Size = UDim2.new(1, -40, 1, -40)
inner.Position = UDim2.fromOffset(20, 20)
inner.BackgroundTransparency = 1
inner.Parent = paper
local innerStroke = Instance.new("UIStroke")
innerStroke.Thickness = 2
innerStroke.Color = Color3.fromRGB(60, 46, 140)
innerStroke.Parent = inner
corner(inner, 12)

local INK = Color3.fromRGB(36, 28, 90)
local MUTED = Color3.fromRGB(110, 100, 150)
label(paper, string.upper(Config.GameTitle or "MOON BASE"), 44, 26, Enum.Font.GothamBold, MUTED)
label(paper, "JUNIOR ASTRONAUT", 76, 74, Enum.Font.FredokaOne, INK)
label(paper, "This certifies that", 162, 26, Enum.Font.GothamBold, MUTED)
local nameT = label(paper, "", 192, 58, Enum.Font.FredokaOne, Color3.fromRGB(226, 46, 64))
local roleT = label(paper, "", 254, 30, Enum.Font.GothamBold, INK)
local resultT = label(paper, "", 288, 26, Enum.Font.GothamBold, MUTED)

-- Estrellas (dibujadas con un polígono de Frames no queda bien: se usa el carácter ★ en FredokaOne)
local starRow = Instance.new("Frame")
starRow.Size = UDim2.fromOffset(560, 150)
starRow.Position = UDim2.new(0.5, -280, 0, 330)
starRow.BackgroundTransparency = 1
starRow.Parent = paper
local stars = {}
local STAR_NAMES = { "MISSION", "TEAMWORK", "EXPLORER" }
for i = 1, 3 do
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(170, 150)
	box.Position = UDim2.fromOffset((i - 1) * 195, 0)
	box.BackgroundTransparency = 1
	box.Parent = starRow
	local s = Instance.new("TextLabel")
	s.Size = UDim2.fromOffset(170, 105)
	s.BackgroundTransparency = 1
	s.Font = Enum.Font.FredokaOne
	s.Text = "★"
	s.TextScaled = true
	s.TextColor3 = Color3.fromRGB(214, 210, 226)
	s.Parent = box
	local st = Instance.new("UIStroke")
	st.Thickness = 2
	st.Color = Color3.fromRGB(150, 110, 30)
	st.Transparency = 1
	st.Parent = s
	local n = Instance.new("TextLabel")
	n.Size = UDim2.new(1, 0, 0, 22)
	n.Position = UDim2.fromOffset(0, 104)
	n.BackgroundTransparency = 1
	n.Font = Enum.Font.GothamBold
	n.TextScaled = true
	n.TextColor3 = MUTED
	n.Text = STAR_NAMES[i]
	n.Parent = box
	local why = Instance.new("TextLabel")
	why.Size = UDim2.new(1, 0, 0, 18)
	why.Position = UDim2.fromOffset(0, 128)
	why.BackgroundTransparency = 1
	why.Font = Enum.Font.Gotham
	why.TextScaled = true
	why.TextColor3 = MUTED
	why.Parent = box
	stars[i] = { star = s, stroke = st, why = why }
end
local rocksT = label(paper, "", 488, 24, Enum.Font.GothamBold, INK)

local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(0.5, 0)
btn.Position = UDim2.new(0.5, 0, 1, 12)
btn.Size = UDim2.fromOffset(300, 60)
btn.BackgroundColor3 = C.Red
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.FredokaOne
btn.TextScaled = true
btn.Text = "SEE RESULTS"
btn.Parent = paper
corner(btn, 14)
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = btn
btn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

local function hasRole(roles: string, role: string): boolean
	return string.find("," .. roles .. ",", "," .. role .. ",", 1, true) ~= nil
end

local shown = false
local function showDiploma()
	if shown then return end
	shown = true
	local won = GS:GetAttribute("Result") == "won"
	local roles = player:GetAttribute("Roles") or player:GetAttribute("Role") or ""
	local names = {}
	local missionDone = false
	for _, r in Config.RoleOrder do
		if hasRole(roles, r) then
			table.insert(names, Config.Roles[r].Name)
			if GS:GetAttribute("MissionComplete_" .. r) then missionDone = true end
		end
	end
	local rocks = player:GetAttribute("RocksFound") or 0
	nameT.Text = player.DisplayName
	roleT.Text = "served as " .. (#names > 0 and table.concat(names, " + ") or "CREW MEMBER") .. " on the Moon"
	local day = GS:GetAttribute("Day") or 0
	resultT.Text = won and "and helped the base survive 7 days!" or string.format("and kept the base going for %d of 7 days", math.max(0, day - 1))
	rocksT.Text = string.format("Moon rocks found: %d / 6", rocks)
	local got = { won, missionDone, rocks >= 3 }
	local whys = { won and "Survived 7 days" or "Survive 7 days", missionDone and "Did your mission" or "Do your mission", rocks >= 3 and "Found 3+ rocks" or "Find 3 rocks" }
	-- nadie se va con cero estrellas
	if not got[1] and not got[2] and not got[3] then got[2] = true; whys[2] = "Joined the crew" end
	for i, s in stars do
		s.why.Text = whys[i]
		s.star.TextColor3 = Color3.fromRGB(214, 210, 226)
		s.stroke.Transparency = 1
		s.star.Size = UDim2.fromOffset(170, 105)
	end
	gui.Enabled = true
	paper.Position = UDim2.new(0.5, 0, 0.5, 4)
	TweenService:Create(paper, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0.5, -36) }):Play()
	-- las estrellas ganadas se encienden una por una
	task.delay(0.7, function()
		for i, s in stars do
			if got[i] then
				s.star.TextColor3 = C.Gold
				s.stroke.Transparency = 0
				s.star.Size = UDim2.fromOffset(170, 60)
				TweenService:Create(s.star, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(170, 105) }):Play()
				task.wait(0.45)
			end
		end
	end)
end

local function onPhase()
	local phase = GS:GetAttribute("Phase") or ""
	if phase == "End" and (GS:GetAttribute("Result") or "") ~= "" then
		-- 16-nov: espera a que pase el cartel de victoria de Celebrations (3,2 s) para no taparlo
		task.delay(3.5, function()
			if GS:GetAttribute("Phase") == "End" then showDiploma() end
		end)
	elseif phase ~= "End" then
		shown = false
		gui.Enabled = false
	end
end
GS:GetAttributeChangedSignal("Phase"):Connect(onPhase)
GS:GetAttributeChangedSignal("Result"):Connect(onPhase)
onPhase()
