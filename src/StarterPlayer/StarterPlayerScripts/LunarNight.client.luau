-- LunarNight (LocalScript) -> StarterPlayer.StarterPlayerScripts.LunarNight
-- [15-nov] Noche en la Fase 3 (solo visual, en este cliente): al final de cada día (DayTimeLeft) el mundo se
-- oscurece y se pone azulado, se prenden los focos de los postes (NightLamp) y las ventanas de la base
-- (NightWindow) se iluminan. Al empezar el día siguiente vuelve la luz. Números en Config.Extras.Night.
-- Usa su propio ColorCorrection dentro de la cámara: no toca Lighting ni ZoneLighting.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local N = X.Night
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer
local DAY = (Config.Phase3 and Config.Phase3.DayLength) or 120

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "SO_LunarNightCC"
local function placeCC()
	local cam = workspace.CurrentCamera
	if cam and cc.Parent ~= cam then
		cc.Parent = cam
	end
end
placeCC()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(placeCC)

-- Aviso corto "se pone el Sol"
local gui = Instance.new("ScreenGui")
gui.Name = "SO_LunarNight"
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
gui.Parent = player:WaitForChild("PlayerGui")
local note = Instance.new("TextLabel")
note.AnchorPoint = Vector2.new(0.5, 0)
note.Position = UDim2.new(0.5, 0, 0, 120)
note.Size = UDim2.fromOffset(0, 40)
note.AutomaticSize = Enum.AutomaticSize.X
note.BackgroundColor3 = Color3.fromRGB(30, 30, 80)
note.BackgroundTransparency = 0.15
note.TextColor3 = Color3.fromRGB(255, 230, 160)
note.Font = Enum.Font.FredokaOne
note.TextSize = 22
note.Text = X.Text.NightComing
note.Visible = false
local nc = Instance.new("UICorner")
nc.CornerRadius = UDim.new(0, 14)
nc.Parent = note
local np = Instance.new("UIPadding")
np.PaddingLeft = UDim.new(0, 18)
np.PaddingRight = UDim.new(0, 18)
np.Parent = note
note.Parent = gui

local windowColor: { [BasePart]: Color3 } = setmetatable({}, { __mode = "k" }) :: any
local lampsOn = false
local function setLamps(on: boolean)
	if on == lampsOn then
		return
	end
	lampsOn = on
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("NightLamp") then
				for _, l in d:GetChildren() do
					if l:IsA("Light") then
						l.Enabled = on
					end
				end
			elseif d:GetAttribute("NightWindow") then
				if windowColor[d] == nil then
					windowColor[d] = d.Color
				end
				d.Color = on and Color3.fromRGB(255, 214, 120) or windowColor[d]
				d.Material = on and Enum.Material.Neon or Enum.Material.Glass
			end
		end
	end
	if on then
		note.Visible = true
		note.TextTransparency = 0
		note.BackgroundTransparency = 0.15
		task.delay(3, function()
			TweenService:Create(note, TweenInfo.new(0.6), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end)
	end
end

local shown = 0
RunService.Heartbeat:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local goal = 0
	if GS:GetAttribute("Phase") == "Phase3" and cam and cam.CFrame.Position.X > X.Footprints.MoonX then
		local frac = (GS:GetAttribute("DayTimeLeft") or DAY) / DAY
		goal = math.clamp((N.Start - frac) / (N.Start - N.Full), 0, 1)
	end
	-- cambio suave
	shown += (goal - shown) * math.min(1, dt * 1.5)
	cc.Brightness = N.Brightness * shown
	cc.TintColor = Color3.new(1, 1, 1):Lerp(N.Tint, shown)
	cc.Saturation = -0.15 * shown
	setLamps(shown > 0.25)
end)
