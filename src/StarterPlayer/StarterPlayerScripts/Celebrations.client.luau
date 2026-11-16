-- Celebrations (LocalScript) -> StarterPlayer.StarterPlayerScripts.Celebrations
-- [15-nov] Celebración corta en pantalla (confeti de colores + cartel que salta):
-- 1. Cuando un rol termina su misión (GameState.MissionComplete_<rol> pasa a true).
-- 2. Cuando se pasa de fase (Transition01, Transition12, Transition23).
-- 3. Al ganar (End con Result = "won").
-- Solo visual, en este cliente. Textos y números en Config.Extras.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local C = Config.Colors
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SO_Celebrations"
gui.ResetOnSpawn = false
gui.DisplayOrder = 70
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local COLORS = { C.Red, C.Gold, C.Good, C.Sky, C.Pink, Color3.fromRGB(160, 120, 255), Color3.new(1, 1, 1) }
local rng = Random.new()

local function confetti(count: number)
	for _ = 1, count do
		local w = rng:NextInteger(8, 14)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = COLORS[rng:NextInteger(1, #COLORS)]
		f.Size = UDim2.fromOffset(w, math.floor(w * rng:NextNumber(0.4, 1)))
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		local x = rng:NextNumber(0.02, 0.98)
		f.Position = UDim2.new(x, 0, 0, -rng:NextInteger(10, 260))
		f.Rotation = rng:NextInteger(0, 360)
		if rng:NextNumber() < 0.4 then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent = f
		end
		f.Parent = gui
		local t = rng:NextNumber(2.2, 3.6)
		local tw = TweenService:Create(f, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Position = UDim2.new(x + rng:NextNumber(-0.12, 0.12), 0, 1, 40),
			Rotation = f.Rotation + rng:NextInteger(-540, 540),
		})
		tw:Play()
		tw.Completed:Once(function()
			f:Destroy()
		end)
	end
end

local banner = Instance.new("TextLabel")
banner.Font = Enum.Font.FredokaOne
banner.TextSize = 38
banner.TextColor3 = Color3.fromHex("1A1240")
banner.BackgroundColor3 = C.Gold
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.26)
banner.Size = UDim2.fromOffset(0, 72)
banner.AutomaticSize = Enum.AutomaticSize.X
banner.Visible = false
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 24)
bc.Parent = banner
local bp = Instance.new("UIPadding")
bp.PaddingLeft = UDim.new(0, 30)
bp.PaddingRight = UDim.new(0, 30)
bp.Parent = banner
local bs = Instance.new("UIStroke")
bs.Color = Color3.new(1, 1, 1)
bs.Thickness = 3
bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bs.Parent = banner
local scale = Instance.new("UIScale")
scale.Parent = banner
banner.Parent = gui

local showId = 0
local function celebrate(text: string, color: Color3?)
	showId += 1
	local my = showId
	banner.Text = text
	banner.BackgroundColor3 = color or C.Gold
	banner.Visible = true
	scale.Scale = 0.3
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	confetti(X.ConfettiCount)
	task.delay(3.2, function()
		if showId == my then
			local tw = TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 0 })
			tw:Play()
			tw.Completed:Once(function()
				if showId == my then
					banner.Visible = false
				end
			end)
		end
	end)
end

-- 1. Misiones terminadas
for _, role in Config.RoleOrder do
	local key = "MissionComplete_" .. role
	local was = GS:GetAttribute(key) == true
	GS:GetAttributeChangedSignal(key):Connect(function()
		local now = GS:GetAttribute(key) == true
		if now and not was then
			local info = Config.Roles[role]
			celebrate(string.format(X.Text.MissionDone, info and info.Name or role), C.Good)
		end
		was = now
	end)
end

-- 2 y 3. Pasar de fase y ganar
local PHASE_DONE = { Transition01 = true, Transition12 = true, Transition23 = true }
local lastPhase = GS:GetAttribute("Phase") or ""
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local p = GS:GetAttribute("Phase") or ""
	if p ~= lastPhase then
		if PHASE_DONE[p] then
			celebrate(X.Text.PhaseDone, C.Gold)
		elseif p == "End" then
			-- Result se escribe junto con End; esperamos un instante
			task.delay(0.3, function()
				if GS:GetAttribute("Result") == "won" then
					celebrate(X.Text.Win, C.Good)
					task.delay(1.2, function() confetti(X.ConfettiCount) end)
				end
			end)
		end
	end
	lastPhase = p
end)
