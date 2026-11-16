-- Phase0HUD (LocalScript) -> StarterPlayer.StarterPlayerScripts.Phase0HUD
-- Lo mínimo de la Fase 0 en pantalla para que la partida pueda seguir hasta la Fase 1:
-- 1. Fase "Phase0": arriba, el tiempo que queda para preparar la nave.
-- 2. Fase "Launch": "CAPTAIN: LAUNCH NOW! 15". Se despega SOLO con el botón rojo de la consola de la sala de
--    control (Phase0Launch). Aquí el Captain ve un aviso para ir al botón; los demás esperan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local C = Config.Colors
local T = P1.Text2
local player = Players.LocalPlayer

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function fmt(t: number): string
	t = math.max(0, math.floor(t))
	return string.format("%d:%02d", t // 60, t % 60)
end

local function isCaptain(): boolean
	return table.find(string.split(player:GetAttribute("Roles") or "", ","), "cap") ~= nil
end

local gui = new("ScreenGui", { Name = "SO_Phase0HUD", ResetOnSpawn = false, DisplayOrder = 12 }, player:WaitForChild("PlayerGui"))

-- Arriba: tiempo de la Fase 0 o aviso de lanzamiento
local top = new("TextLabel", {
	Text = "", Font = Enum.Font.FredokaOne, TextSize = 26, TextColor3 = C.Text,
	BackgroundColor3 = C.Stage, BackgroundTransparency = 0.1,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(520, 48), Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 24) }, top)

-- Aviso para el Captain: ir al botón rojo (ya no hay botón en pantalla)
local goText = new("TextLabel", {
	Text = T.GoToButton, Font = Enum.Font.FredokaOne, TextSize = 26, TextColor3 = C.Text, BackgroundColor3 = C.Red,
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -60), Size = UDim2.fromOffset(640, 64), Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 18) }, goText)
local waitText = new("TextLabel", {
	Text = T.WaitCaptain, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.Text,
	BackgroundColor3 = C.Stage, BackgroundTransparency = 0.1,
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -60), Size = UDim2.fromOffset(460, 48), Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 16) }, waitText)

-- [15-nov] Botón READY de la Fase 0: aparece cuando los 4 roles ya eligieron su opción.
-- Si todos lo pulsan, GameManager termina la Fase 0 antes de que acabe el reloj.
local readyBtn = new("TextButton", {
	Text = P1.Text.Phase0Ready, Font = Enum.Font.FredokaOne, TextSize = 24, TextColor3 = C.Text, BackgroundColor3 = C.Red,
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(300, 58), Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 18) }, readyBtn)
new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, readyBtn)
local readySent = false
readyBtn.MouseButton1Click:Connect(function()
	if readySent or GS:GetAttribute("Phase") ~= "Phase0" then
		return
	end
	readySent = true
	Remotes.ReadyUp:FireServer()
end)

local function allChosen(): boolean
	for _, r in Config.RoleOrder do
		local v = GS:GetAttribute("Choice_" .. r)
		if v == nil or v == "" then
			return false
		end
	end
	return true
end


local function draw()
	local p = GS:GetAttribute("Phase") or ""
	local t = GS:GetAttribute("TimeLeft") or 0
	local launching = p == "Launch" and GS:GetAttribute("Launched") ~= true
	top.Visible = p == "Phase0" or launching
	if p == "Phase0" then
		top.Text = string.format(T.Phase0Top, fmt(t))
		top.TextColor3 = t <= 10 and C.Bad or C.Text
	elseif launching then
		top.Text = string.format(Config.Text.LaunchNow, t)
		top.TextColor3 = C.Gold
	end
	local captain = isCaptain()
	goText.Visible = launching and captain
	waitText.Visible = launching and not captain
	-- READY de la Fase 0
	if p ~= "Phase0" then
		readySent = false
	end
	readyBtn.Visible = p == "Phase0" and allChosen()
	if readySent then
		readyBtn.Text = string.format(P1.Text.RolesWaiting, GS:GetAttribute("ReadyCount") or 0, #Players:GetPlayers())
		readyBtn.BackgroundColor3 = C.Good
	else
		readyBtn.Text = P1.Text.Phase0Ready
		readyBtn.BackgroundColor3 = C.Red
	end
end

for _, r in Config.RoleOrder do
	GS:GetAttributeChangedSignal("Choice_" .. r):Connect(draw)
end
for _, name in { "Phase", "TimeLeft", "Launched", "ReadyCount" } do
	GS:GetAttributeChangedSignal(name):Connect(draw)
end
player:GetAttributeChangedSignal("Roles"):Connect(draw)
draw()
