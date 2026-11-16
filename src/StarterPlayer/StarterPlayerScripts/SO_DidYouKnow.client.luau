-- SO_DidYouKnow (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_DidYouKnow
-- Dueño: Isaac + Claude. Tarjeta "DID YOU KNOW?" con un dato real al azar (Config.DidYouKnow)
-- debajo del panel entre la Fase 2 y la 3 (Transition23) y abajo en la pantalla final (End).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local D = Config.DidYouKnow
local C = Config.Colors

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SO_DidYouKnow"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20 -- encima del HUD (la pantalla final ocupa toda la pantalla)
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(640, 74)
card.BackgroundColor3 = C.BgDark
card.BackgroundTransparency = 0.15
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = card

local function label(text: string, size: UDim2, pos: UDim2, font: Enum.Font, color: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = size
	t.Position = pos
	t.BackgroundTransparency = 1
	t.Text = text
	t.Font = font
	t.TextColor3 = color
	t.TextScaled = true
	t.TextWrapped = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = card
	return t
end
label(D.Title, UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 6), Enum.Font.FredokaOne, C.Gold)
local fact = label("", UDim2.new(1, -24, 1, -34), UDim2.fromOffset(14, 28), Enum.Font.GothamBold, C.Text)
fact.TextYAlignment = Enum.TextYAlignment.Top
local max = Instance.new("UITextSizeConstraint")
max.MaxTextSize = 20
max.Parent = fact

local last = 0
local function pickFact(): string
	local i = math.random(1, #D.Facts)
	if i == last and #D.Facts > 1 then i = i % #D.Facts + 1 end
	last = i
	return D.Facts[i]
end

local function update()
	local phase = GS:GetAttribute("Phase") or ""
	if phase == "Transition23" then
		-- Debajo del panel de 430 px centrado
		card.Size = UDim2.fromOffset(640, 74)
		card.Position = UDim2.new(0.5, -320, 0.5, 225)
	elseif phase == "End" then
		-- Esquina de abajo a la derecha, al lado del botón TRY AGAIN / PLAY AGAIN (que está centrado)
		card.Size = UDim2.fromOffset(380, 96)
		card.Position = UDim2.new(1, -396, 1, -112)
	else
		card.Visible = false
		return
	end
	fact.Text = pickFact()
	card.Visible = true
end

GS:GetAttributeChangedSignal("Phase"):Connect(update)
update()
