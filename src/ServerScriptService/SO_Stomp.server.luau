-- SO_Stomp (Script) -> ServerScriptService.SO_Stomp
-- Dueño: Isaac + Claude. Idea de Leticia + Isaac (friendslop, comedia física).
-- Si un astronauta cae de un salto lunar encima de otro, el de abajo queda tumbado y aturdido
-- Config.Stomp.StunTime segundos (estrellitas + sonido) y el de arriba rebota.
-- No quita oxígeno, agua ni vida. No cuenta para muertos, ni para quien mantiene E en un prompt
-- (emergencias, recarga, misiones), ni fuera de las fases en la Luna.
-- El rebote lo aplica SO_StompClient (el personaje es del cliente; el servidor no puede empujarlo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local S = Config.Stomp

local ACTIVE = { Placement = true, Phase2 = true, Phase3 = true }

local bounceEvent = Remotes:FindFirstChild("SO_StompBounce") or Instance.new("RemoteEvent")
bounceEvent.Name = "SO_StompBounce"
bounceEvent.Parent = Remotes

local holding: { [Player]: boolean } = {} -- mantiene E en un ProximityPrompt
local stunnedUntil: { [Player]: number } = {}
local immuneUntil: { [Player]: number } = {}
local factShown = false -- el dato de la gravedad sale una vez por partida

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if GS:GetAttribute("Phase") == "RoleSelect" then factShown = false end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(_prompt, p) holding[p] = true end)
ProximityPromptService.PromptButtonHoldEnded:Connect(function(_prompt, p) holding[p] = nil end)
ProximityPromptService.PromptTriggered:Connect(function(_prompt, p) holding[p] = nil end)
Players.PlayerRemoving:Connect(function(p)
	holding[p] = nil; stunnedUntil[p] = nil; immuneUntil[p] = nil
end)

local function parts(p: Player): (Model?, BasePart?, Humanoid?)
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return char, root, hum
end

-- Estrellitas girando sobre la cabeza (visibles para todos)
local function stars(char: Model, seconds: number)
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "SO_StompStars"
	bb.Size = UDim2.fromOffset(110, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "★ ✦ ★"
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.fromHex("FFD84A")
	t.TextStrokeTransparency = 0.4
	t.Parent = bb
	task.spawn(function()
		local t0 = os.clock()
		while bb.Parent and os.clock() - t0 < seconds do
			t.Rotation = math.sin((os.clock() - t0) * 8) * 18
			t.Text = math.floor((os.clock() - t0) * 4) % 2 == 0 and "★ ✦ ★" or "✦ ★ ✦"
			task.wait(0.05)
		end
		bb:Destroy()
	end)
end

local function boing(root: BasePart)
	local s = Instance.new("Sound")
	s.SoundId = S.Sound
	s.PlaybackSpeed = S.SoundPitch
	s.Volume = 0.8
	s.RollOffMaxDistance = 80
	s.Parent = root
	s:Play()
	task.delay(3, function() s:Destroy() end)
end

local function stun(victim: Player, attacker: Player)
	local char, root, hum = parts(victim)
	if not (char and root and hum) then return end
	local now = os.clock()
	stunnedUntil[victim] = now + S.StunTime
	immuneUntil[victim] = now + S.StunTime + S.ImmuneTime
	victim:SetAttribute("Stunned", true)

	-- Tumbado de espaldas en el suelo (anclado para que no se mueva ni flote con la gravedad lunar)
	local phase = GS:GetAttribute("Phase")
	local wasAnchored = root.Anchored
	local upright = root.CFrame
	local hip = hum.HipHeight + root.Size.Y / 2
	local flat = CFrame.new(root.Position - Vector3.new(0, hip - 0.6, 0)) * CFrame.Angles(0, select(2, upright:ToEulerAnglesYXZ()), 0)
		* CFrame.Angles(-math.pi / 2, 0, 0)
	root.Anchored = true
	char:PivotTo(flat)

	stars(char, S.StunTime)
	boing(root)
	Remotes.Toast:FireAllClients(string.format(S.Text, attacker.DisplayName, victim.DisplayName), 3)
	if not factShown then
		factShown = true
		task.delay(3, function() Remotes.Toast:FireAllClients(S.Fact, 6) end)
	end

	task.delay(S.StunTime, function()
		victim:SetAttribute("Stunned", nil)
		stunnedUntil[victim] = nil
		-- Si murió o cambió el personaje mientras tanto, no tocar nada
		if victim.Character ~= char or victim:GetAttribute("Dead") or not root.Parent then return end
		char:PivotTo(CFrame.new(root.Position + Vector3.new(0, hip, 0)) * (upright - upright.Position))
		-- Si la fase cambió, PhaseMovement ya decidió si queda anclado; si no, se devuelve como estaba
		if GS:GetAttribute("Phase") == phase then root.Anchored = wasAnchored end
	end)
end

if not S.Enabled then return end

-- Revisión cada cuadro: ¿alguien cae rápido justo encima de la cabeza de otro?
RunService.Heartbeat:Connect(function()
	if not ACTIVE[GS:GetAttribute("Phase") or ""] then return end
	local now = os.clock()
	local list = Players:GetPlayers()
	for _, a in list do
		if a:GetAttribute("Dead") or stunnedUntil[a] then continue end
		local _, aRoot = parts(a)
		if not aRoot or aRoot.Anchored then continue end
		local v = aRoot.AssemblyLinearVelocity
		if v.Y > -S.MinFallSpeed then continue end
		for _, b in list do
			if b == a or b:GetAttribute("Dead") or holding[b] then continue end
			if (immuneUntil[b] or 0) > now then continue end
			local _, bRoot = parts(b)
			if not bRoot then continue end
			local d = aRoot.Position - bRoot.Position
			if d.Y >= S.MinAbove and d.Y <= S.MaxAbove and Vector2.new(d.X, d.Z).Magnitude <= S.Radius then
				stun(b, a)
				bounceEvent:FireClient(a, S.Bounce)
				break
			end
		end
	end
end)
