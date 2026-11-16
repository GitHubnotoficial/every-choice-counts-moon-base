-- DeathTips (LocalScript) -> StarterPlayer.StarterPlayerScripts.DeathTips
-- [15-nov] Cuando muero, abajo aparece una tarjeta "TIP FOR NEXT TIME" con 1 o 2 consejos.
-- Lee lo que ya escribe Bars: atributos del jugador DeathCause ("oxygen" / "water") y DeathWhy (los motivos).
-- Cada motivo de Config.Text3.Why... tiene su consejo en Config.Extras.DeathTips. No cambia nada del juego.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local C = Config.Colors
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SO_DeathTips"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -24)
card.Size = UDim2.fromOffset(560, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
card.BackgroundColor3 = Color3.fromHex("2A1C6E")
card.Visible = false
card.Parent = gui
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 18)
cc.Parent = card
local cs = Instance.new("UIStroke")
cs.Color = C.Gold
cs.Thickness = 3
cs.Parent = card
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 14)
pad.PaddingLeft = UDim.new(0, 18)
pad.PaddingRight = UDim.new(0, 18)
pad.Parent = card
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = card

local title = Instance.new("TextLabel")
title.Text = "💡 " .. X.DeathTipTitle
title.Font = Enum.Font.FredokaOne
title.TextSize = 24
title.TextColor3 = C.Gold
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 28)
title.TextXAlignment = Enum.TextXAlignment.Left
title.LayoutOrder = 0
title.Parent = card

local lines: { TextLabel } = {}
for i = 1, 2 do
	local t = Instance.new("TextLabel")
	t.Font = Enum.Font.GothamBold
	t.TextSize = 19
	t.TextColor3 = C.Text
	t.TextWrapped = true
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 0)
	t.AutomaticSize = Enum.AutomaticSize.Y
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.LayoutOrder = i
	t.Parent = card
	lines[i] = t
end

-- ¿El texto de motivos contiene este "Why..."? (se compara la parte antes del primer %)
local function has(why: string, key: string): boolean
	local base = Config.Text3[key]
	if not base then
		return false
	end
	local cut = string.find(base, "%", 1, true)
	local piece = cut and string.sub(base, 1, cut - 1) or base
	return #piece > 4 and string.find(why, piece, 1, true) ~= nil
end

local function show()
	local why = player:GetAttribute("DeathWhy") or ""
	local tips = {}
	for _, d in X.DeathTips do
		if #tips < 2 and has(why, d.Why) then
			table.insert(tips, d.Tip)
		end
	end
	if #tips < 2 then
		table.insert(tips, player:GetAttribute("DeathCause") == "water" and X.DeathTipWater or X.DeathTipOxygen)
	end
	for i, t in lines do
		t.Text = tips[i] and ("• " .. tips[i]) or ""
		t.Visible = tips[i] ~= nil
	end
	card.Visible = true
	card.Position = UDim2.new(0.5, 0, 1, 200)
	TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 1, -24) }):Play()
	task.delay(14, function()
		card.Visible = false
	end)
end

player:GetAttributeChangedSignal("Dead"):Connect(function()
	if player:GetAttribute("Dead") == true then
		task.wait(1.5) -- que primero se vea el aviso de la muerte
		show()
	else
		card.Visible = false
	end
end)
