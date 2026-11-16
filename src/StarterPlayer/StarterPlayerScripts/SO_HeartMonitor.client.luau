-- SO_HeartMonitor: anima la pantalla "CREW HEART RATE" del cuarto de Soporte Vital.
-- Solo aparece una línea por cada rol que tiene jugador (1 a 4), con su color, su nombre y sus BPM.
-- Un único bip suave (tu latido, o el primero) y solo mientras estás dentro del cuarto.
-- Corre en el cliente: no toca la pantalla del servidor (la de otra persona), solo oculta sus barras viejas.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local HM = Config.HeartMonitor
local player = Players.LocalPlayer

-- Busca la pantalla por su título (vive en EarthBase.Room_life.Decor_LifeLab)
local function findScreen(): (BasePart?, SurfaceGui?)
	local base = workspace:FindFirstChild("EarthBase")
	if not base then return nil, nil end
	for _, d in base:GetDescendants() do
		if d:IsA("TextLabel") and d.Text == HM.Title then
			local sg = d:FindFirstAncestorOfClass("SurfaceGui")
			local part = sg and (sg.Adornee or sg.Parent)
			if sg and part and part:IsA("BasePart") then return part, sg end
		end
	end
	return nil, nil
end

local part, sg
for _ = 1, 60 do
	part, sg = findScreen()
	if part then break end
	task.wait(1)
end
if not part or not sg then return end

-- Zona del cuarto (para el bip): el piso del cuarto, o su caja si no tiene piso
local room = part:FindFirstAncestor("Room_life")
local roomCF, roomSize
do
	local floor = room and room:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		roomCF, roomSize = floor.CFrame, floor.Size
	elseif room then
		roomCF, roomSize = room:GetBoundingBox()
	else
		roomCF, roomSize = part.CFrame, Vector3.new(30, 0, 30)
	end
end
local function insideRoom(): boolean
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local p = roomCF:PointToObjectSpace(hrp.Position)
	local pad = HM.Beep.RoomPadding
	return math.abs(p.X) <= roomSize.X / 2 + pad and math.abs(p.Z) <= roomSize.Z / 2 + pad and p.Y > -2 and p.Y < 16
end

-- Ocultar el dibujo viejo (todo menos el fondo y el título)
local root = sg:FindFirstChildOfClass("Frame") or sg
for _, d in root:GetDescendants() do
	if d:IsA("GuiObject") and not (d:IsA("TextLabel") and d.Text == HM.Title) then d.Visible = false end
end

-- Capa nueva encima
local layer = Instance.new("Frame")
layer.Name = "SO_ECG"
layer.BackgroundTransparency = 1
layer.Size = UDim2.fromScale(1, 1)
layer.ZIndex = 5
layer.Parent = root

local W, H = sg.CanvasSize.X, sg.CanvasSize.Y
local TOP, BOTTOM = 0.2, 0.97
local X0, X1 = 0.27, 0.97 -- zona del trazo (en fracción del ancho)
local N = HM.Points

-- Bip único
local beep = Instance.new("Sound")
beep.Name = "SO_HeartBeep"
beep.SoundId = HM.Beep.SoundId
beep.Volume = HM.Beep.Volume
beep.Parent = part

-- Forma de un latido (P, QRS, T) en función de la fase 0..1
local function wave(ph: number): number
	local function g(c, w, a) return a * math.exp(-((ph - c) / w) ^ 2) end
	return g(0.12, 0.035, 0.12) - g(0.22, 0.012, 0.15) + g(0.25, 0.014, 1.0) - g(0.28, 0.014, 0.3) + g(0.45, 0.06, 0.25)
end

local function label(parent, text, color, pos, size)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color
	l.Text = text
	l.ZIndex = 6
	l.Parent = parent
	return l
end

-- Construye las líneas solo para los roles con jugador
local lanes = {}
local phases = {} -- se conserva el ritmo de cada rol al reconstruir
local laneH = 0

local function holders()
	local list = {}
	for _, role in Config.RoleOrder do
		for _, p in Players:GetPlayers() do
			if p:GetAttribute("Role") == role then
				table.insert(list, { role = role, player = p })
				break
			end
		end
	end
	return list
end

local currentKey = ""
local function rebuild(list)
	for _, lane in lanes do lane.frame:Destroy() end
	lanes = {}
	if #list == 0 then return end
	laneH = (BOTTOM - TOP) / #list
	for i, h in list do
		local info = Config.Roles[h.role]
		local y0 = TOP + (i - 1) * laneH
		local f = Instance.new("Frame")
		f.Name = "Lane_" .. h.role
		f.BackgroundTransparency = 1
		f.Size = UDim2.fromScale(1, 1)
		f.ZIndex = 5
		f.Parent = layer
		local lane = { role = h.role, player = h.player, y0 = y0, frame = f, segs = {}, vals = table.create(N, 0),
			phase = phases[h.role] or math.random(), bpm = HM.BaseBPM[h.role] }
		lane.name = label(f, h.player.DisplayName, info.Color, UDim2.fromScale(0.03, y0 + laneH * 0.08), UDim2.fromScale(0.23, math.min(laneH * 0.4, 0.12)))
		lane.bpmLabel = label(f, "-- BPM", Color3.new(1, 1, 1), UDim2.fromScale(0.03, y0 + laneH * 0.5), UDim2.fromScale(0.23, math.min(laneH * 0.36, 0.1)))
		if i < #list then
			local sep = Instance.new("Frame")
			sep.BorderSizePixel = 0
			sep.BackgroundColor3 = info.Color
			sep.BackgroundTransparency = 0.85
			sep.Position = UDim2.fromScale(0.03, y0 + laneH - 0.004)
			sep.Size = UDim2.new(0.94, 0, 0, 2)
			sep.ZIndex = 5
			sep.Parent = f
		end
		for k = 1, N do
			local s = Instance.new("Frame")
			s.BorderSizePixel = 0
			s.BackgroundColor3 = info.Color
			s.BackgroundTransparency = 1
			s.Size = UDim2.fromOffset(math.ceil((X1 - X0) * W / N) + 1, 4)
			s.Position = UDim2.fromOffset((X0 + (X1 - X0) * (k - 1) / (N - 1)) * W, (y0 + laneH * 0.6) * H)
			s.ZIndex = 6
			s.Parent = f
			lane.segs[k] = s
		end
		lanes[i] = lane
	end
end

local function refresh()
	local list = holders()
	local parts = {}
	for _, h in list do table.insert(parts, h.role .. "=" .. h.player.UserId) end
	local key = table.concat(parts, ",")
	if key ~= currentKey then
		currentKey = key
		for _, lane in lanes do phases[lane.role] = lane.phase end
		rebuild(list)
	end
end
refresh()
task.spawn(function()
	while layer.Parent do
		task.wait(2)
		refresh()
	end
end)

-- Animación de barrido (como un monitor de hospital)
local cursor, acc = 1, 0
local stepTime = HM.SweepSeconds / N
local t0 = os.clock()

local function drawSeg(lane, k)
	local v, prev = lane.vals[k], lane.vals[math.max(k - 1, 1)]
	local mid = (lane.y0 + laneH * 0.62) * H
	local amp = laneH * H * 0.5
	local a, b = mid - v * amp, mid - prev * amp
	local seg = lane.segs[k]
	seg.Position = UDim2.fromOffset(seg.Position.X.Offset, math.min(a, b) - 2)
	seg.Size = UDim2.fromOffset(seg.Size.X.Offset, math.abs(a - b) + 4)
	seg.BackgroundTransparency = 0
end

RunService.RenderStepped:Connect(function(dt)
	-- Solo trabajar si el jugador está cerca (ahorra en teléfonos)
	local cam = workspace.CurrentCamera
	if #lanes == 0 or not cam or (cam.CFrame.Position - part.Position).Magnitude > 120 then return end
	acc += dt
	local now = os.clock() - t0
	-- El bip sigue tu propio latido; si no tienes rol, el de la primera línea
	local beepLane = lanes[1]
	for _, lane in lanes do if lane.player == player then beepLane = lane end end
	local canBeep = insideRoom()
	while acc >= stepTime do
		acc -= stepTime
		for _, lane in lanes do
			lane.bpm = HM.BaseBPM[lane.role] + math.sin(now * 0.2 + lane.y0 * 10) * HM.Drift
			local before = lane.phase
			lane.phase = (lane.phase + stepTime * lane.bpm / 60) % 1
			if lane == beepLane and canBeep and before < 0.25 and lane.phase >= 0.25 then
				beep.PlaybackSpeed = HM.Beep.Pitch[lane.role] or 1
				beep:Play()
			end
			lane.vals[cursor] = wave(lane.phase)
			lane.bpmLabel.Text = string.format("%d BPM", math.round(lane.bpm))
			drawSeg(lane, cursor)
			for g = 1, 3 do -- hueco delante del cursor
				lane.segs[(cursor + g - 1) % N + 1].BackgroundTransparency = 1
			end
		end
		cursor = cursor % N + 1
	end
end)
