-- EmotesServer (Script) -> ServerScriptService.EmotesServer
-- [15-nov] Gestos de astronauta para hablar sin chat. El cliente (EmotesClient) pide "wave" o "point" por
-- Remotes.EmoteRequest; aquí se pone un globo con el dibujo sobre la cabeza para que TODOS lo vean.
-- La animación la reproduce el propio cliente (las animaciones del personaje se ven en todos solas).
-- Crea: Remotes.EmoteRequest. No toca GameState.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local remote = Remotes:FindFirstChild("EmoteRequest") or Instance.new("RemoteEvent")
remote.Name = "EmoteRequest"
remote.Parent = Remotes

local ICONS = { wave = X.Text.WaveIcon, point = X.Text.PointIcon }
local last: { [Player]: number } = {}

remote.OnServerEvent:Connect(function(p: Player, kind: any)
	if typeof(kind) ~= "string" or not ICONS[kind] then
		return
	end
	if last[p] and os.clock() - last[p] < X.EmoteCooldown then
		return
	end
	last[p] = os.clock()
	local head = p.Character and p.Character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local old = head:FindFirstChild("SO_EmoteBubble")
	if old then
		old:Destroy()
	end
	local b = Instance.new("BillboardGui")
	b.Name = "SO_EmoteBubble"
	b.Size = UDim2.fromOffset(64, 64)
	b.StudsOffset = Vector3.new(0, 3.2, 0)
	b.MaxDistance = 120
	b.AlwaysOnTop = true
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.new(1, 1, 1)
	t.Text = ICONS[kind]
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = t
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.14, 0)
	pad.PaddingBottom = UDim.new(0.14, 0)
	pad.Parent = t
	t.Parent = b
	b.Parent = head
	task.delay(X.EmoteShow, function()
		if b.Parent then
			b:Destroy()
		end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)
