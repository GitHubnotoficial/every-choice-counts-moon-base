-- MoonVsEarth (LocalScript) -> StarterPlayer.StarterPlayerScripts.MoonVsEarth
-- [15-nov] Datos cortos "MOON vs EARTH" que aparecen una vez por partida, cuando pasa algo relacionado:
--   Gravity     → al llegar a la Luna (fase Placement, después del aterrizaje)
--   Oxygen      → la primera vez que lleno oxígeno ("mantener E" con "oxygen" en el texto)
--   Water       → la primera vez que lleno agua
--   DayLength   → al empezar el día 1 de la Fase 3
--   Temperature → la primera noche de la Fase 3 (Config.Extras.Night.Start)
-- Textos y fuentes en Config.Extras.Compare. Solo visual; se reinicia al volver al título.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local C = Config.Colors
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer
local DAY = (Config.Phase3 and Config.Phase3.DayLength) or 120

local gui = Instance.new("ScreenGui")
gui.Name = "SO_MoonVsEarth"
gui.ResetOnSpawn = false
gui.DisplayOrder = 35
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 0.5)
card.Position = UDim2.new(1, -16, 0.42, 0)
card.Size = UDim2.fromOffset(340, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
card.BackgroundColor3 = Color3.fromHex("14204A")
card.BackgroundTransparency = 0.05
card.Visible = false
card.Parent = gui
local c1 = Instance.new("UICorner")
c1.CornerRadius = UDim.new(0, 16)
c1.Parent = card
local st = Instance.new("UIStroke")
st.Color = C.Sky
st.Thickness = 3
st.Parent = card
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 12)
pad.PaddingLeft = UDim.new(0, 14)
pad.PaddingRight = UDim.new(0, 14)
pad.Parent = card
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 6)
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = card
local title = Instance.new("TextLabel")
title.Text = "🌍 " .. X.CompareTitle .. " 🌙"
title.Font = Enum.Font.FredokaOne
title.TextSize = 22
title.TextColor3 = C.Sky
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 26)
title.TextXAlignment = Enum.TextXAlignment.Left
title.LayoutOrder = 1
title.Parent = card
local body = Instance.new("TextLabel")
body.Font = Enum.Font.GothamBold
body.TextSize = 18
body.TextColor3 = C.Text
body.TextWrapped = true
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.TextXAlignment = Enum.TextXAlignment.Left
body.LayoutOrder = 2
body.Parent = card

local seen: { [string]: boolean } = {}
local queue: { string } = {}
local busy = false

local function pump()
	if busy or #queue == 0 then
		return
	end
	busy = true
	body.Text = table.remove(queue, 1)
	card.Visible = true
	card.Position = UDim2.new(1, 380, 0.42, 0)
	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.42, 0) }):Play()
	task.delay(X.CompareSeconds, function()
		local tw = TweenService:Create(card, TweenInfo.new(0.35), { Position = UDim2.new(1, 380, 0.42, 0) })
		tw:Play()
		tw.Completed:Wait()
		card.Visible = false
		busy = false
		task.wait(1)
		pump()
	end)
end

local function fact(key: string, delaySec: number?)
	if seen[key] then
		return
	end
	seen[key] = true
	task.delay(delaySec or 0, function()
		local text = X.Compare[key]
		if key == "DayLength" then
			text = string.format(text, DAY)
		end
		table.insert(queue, text)
		pump()
	end)
end

-- Fases
local function onPhase()
	local p = GS:GetAttribute("Phase") or ""
	if p == "Title" then
		table.clear(seen)
		table.clear(queue)
	elseif p == "Placement" then
		-- después del aterrizaje (espera a que termine la animación)
		task.spawn(function()
			local w = 0
			while player:GetAttribute("SO_Cinematic") == true and w < 15 do
				w += task.wait(0.3)
			end
			fact("Gravity", 4)
		end)
	end
end
GS:GetAttributeChangedSignal("Phase"):Connect(onPhase)

-- Día 1 y primera noche de la Fase 3
GS:GetAttributeChangedSignal("Day"):Connect(function()
	if GS:GetAttribute("Phase") == "Phase3" and GS:GetAttribute("Day") == 1 then
		fact("DayLength", 6)
	end
end)
GS:GetAttributeChangedSignal("DayTimeLeft"):Connect(function()
	if GS:GetAttribute("Phase") == "Phase3" and (GS:GetAttribute("DayTimeLeft") or DAY) / DAY < X.Night.Start then
		fact("Temperature", 3)
	end
end)

-- Primer llenado de oxígeno o de agua
ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	local low = string.lower(prompt.ActionText .. " " .. prompt.Name)
	if string.find(low, "oxygen", 1, true) or string.find(low, "tank_o2", 1, true) or string.find(low, " air", 1, true) then -- con espacio: "repair" no cuenta
		fact("Oxygen", 1.5)
	end
	if string.find(low, "water", 1, true) or string.find(low, "melt", 1, true) then
		fact("Water", 1.5)
	end
end)
