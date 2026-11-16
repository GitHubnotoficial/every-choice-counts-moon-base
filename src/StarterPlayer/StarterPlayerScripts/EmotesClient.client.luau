-- EmotesClient (LocalScript) -> StarterPlayer.StarterPlayerScripts.EmotesClient
-- [15-nov] Dos botones a la izquierda (debajo del engranaje): SALUDAR y SEÑALAR. También con las teclas G y H.
-- Reproduce la animación en mi personaje y pide a EmotesServer el globo sobre la cabeza.
-- Solo se ven cuando hay personaje en el mundo (no en las pantallas de menú).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local C = Config.Colors
local GS = ReplicatedStorage:WaitForChild("GameState")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EmoteRequest")
local player = Players.LocalPlayer

-- Animaciones de Roblox para saludar y señalar (R15 y R6)
local ANIMS = {
	wave = { R15 = "rbxassetid://507770239", R6 = "rbxassetid://128777973" },
	point = { R15 = "rbxassetid://507770453", R6 = "rbxassetid://128853357" },
}
-- Fases con pantalla de menú encima (sin botones)
local MENU = { Title = true, RoleSelect = true, Briefing = true, SiteSelect = true, End = true, Failed = true }

local gui = Instance.new("ScreenGui")
gui.Name = "SO_Emotes"
gui.ResetOnSpawn = false
gui.DisplayOrder = 55
gui.Parent = player:WaitForChild("PlayerGui")

local function btn(icon: string, key: string, y: number): TextButton
	local b = Instance.new("TextButton")
	b.Text = icon
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundColor3 = C.Text
	-- 16-nov (Claude): abajo a la izquierda; en el medio tapaban la lista de tareas de la Fase 3
	b.AnchorPoint = Vector2.new(0, 0.5)
	b.Position = UDim2.new(0, 12, 1, y - 124)
	b.Size = UDim2.fromOffset(52, 52)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.16, 0)
	pad.PaddingBottom = UDim.new(0.16, 0)
	pad.Parent = b
	local k = Instance.new("TextLabel")
	k.Text = key
	k.Font = Enum.Font.GothamBlack
	k.TextSize = 12
	k.TextColor3 = C.Text
	k.BackgroundColor3 = Color3.fromHex("2A1C6E")
	k.AnchorPoint = Vector2.new(1, 1)
	k.Position = UDim2.new(1, 4, 1, 4)
	k.Size = UDim2.fromOffset(18, 18)
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = k
	k.Parent = b
	b.Parent = gui
	return b
end
local waveBtn = btn(X.Text.WaveIcon, "G", 0)
local pointBtn = btn(X.Text.PointIcon, "H", 60)

local lastUse = 0
local function play(kind: string)
	if os.clock() - lastUse < X.EmoteCooldown then
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or player:GetAttribute("Dead") then
		return
	end
	lastUse = os.clock()
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local a = Instance.new("Animation")
	a.AnimationId = ANIMS[kind][hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"]
	local ok, track = pcall(function()
		return animator:LoadAnimation(a)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		task.delay(X.EmoteShow, function()
			track:Stop(0.3)
		end)
	end
	remote:FireServer(kind)
end

waveBtn.MouseButton1Click:Connect(function() play("wave") end)
pointBtn.MouseButton1Click:Connect(function() play("point") end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		play("wave")
	elseif input.KeyCode == Enum.KeyCode.H then
		play("point")
	end
end)

local function draw()
	local show = not MENU[GS:GetAttribute("Phase") or ""] and player:GetAttribute("SO_Cinematic") ~= true
	waveBtn.Visible = show
	pointBtn.Visible = show
end
GS:GetAttributeChangedSignal("Phase"):Connect(draw)
player:GetAttributeChangedSignal("SO_Cinematic"):Connect(draw)
draw()
