-- MissionAnims (LocalScript) -> StarterPlayer.StarterPlayerScripts.MissionAnims
-- [15-nov] Animaciones simples para las misiones "mantener E" (solo visual, en este cliente; no cambia el juego):
-- 1. Sobre cada punto de misión (MissionPoint_<rol> de Missions y Task_<rol> de DailyTasks) flota un rombo
--    que gira y sube y baja, y un anillo que late en el suelo. Cuando la misión se termina, desaparecen.
-- 2. Mientras mantengo E: mi personaje mira hacia el objeto, aparece un ícono con barra de progreso y salen
--    partículas según el tipo de tarea (chispas, gotas, hojas, polvo, rayos, anillos o números).
--    El tipo se elige por palabras del texto del botón (Config.Extras.MissionFx).
-- 3. Al terminar: estallido de estrellas y un cartel "Done!" que sube.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local player = Players.LocalPlayer

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local fxFolder = Instance.new("Folder")
fxFolder.Name = "SO_MissionFx"
fxFolder.Parent = workspace

local function anchorPart(pos: Vector3): Part
	local p = Instance.new("Part")
	p.Name = "FxAnchor"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = fxFolder
	return p
end

local function promptPos(prompt: ProximityPrompt): Vector3?
	local par = prompt.Parent
	if par and par:IsA("Attachment") then
		return par.WorldPosition
	elseif par and par:IsA("BasePart") then
		return par.Position
	elseif par and par:IsA("Model") then
		return par:GetPivot().Position
	end
	return nil
end

local function styleFor(text: string)
	local low = string.lower(text or "")
	for _, s in X.MissionFx do
		for _, w in s.Words do
			if string.find(low, w, 1, true) then
				return s
			end
		end
	end
	return X.MissionFxDefault
end

---------------------------------------------------------------------
-- 1. Marcadores flotantes sobre los puntos de misión
---------------------------------------------------------------------
local markers = {} -- { point, gem, ring, prompt, t0 }

local function addMarker(point: BasePart)
	local pr = point:FindFirstChildOfClass("ProximityPrompt")
	local color = point.Color
	local gem = Instance.new("Part")
	gem.Name = "MissionGem"
	gem.Anchored = true
	gem.CanCollide = false
	gem.CanQuery = false
	gem.CanTouch = false
	gem.Material = Enum.Material.Neon
	gem.Color = color
	gem.Size = Vector3.new(1.1, 1.1, 1.1)
	gem.Parent = fxFolder
	local ring = Instance.new("Part")
	ring.Name = "MissionPulse"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Parent = fxFolder
	table.insert(markers, { point = point, gem = gem, ring = ring, prompt = pr, t0 = math.random() * 3 })
end

local function isMissionPoint(d: Instance): boolean
	return d:IsA("BasePart") and (string.sub(d.Name, 1, 13) == "MissionPoint_" or (string.sub(d.Name, 1, 5) == "Task_" and d:FindFirstChild("Marker") ~= nil))
end
for _, d in workspace:GetDescendants() do
	if isMissionPoint(d) then
		addMarker(d :: BasePart)
	end
end
workspace.DescendantAdded:Connect(function(d)
	task.defer(function()
		if d.Parent and isMissionPoint(d) then
			addMarker(d :: BasePart)
		end
	end)
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for i = #markers, 1, -1 do
		local m = markers[i]
		if not m.point.Parent then
			m.gem:Destroy()
			m.ring:Destroy()
			table.remove(markers, i)
		else
			local active = m.prompt == nil or (m.prompt.Parent ~= nil and m.prompt.Enabled)
			m.gem.Transparency = active and 0.05 or 1
			local k = ((t + m.t0) % 1.6) / 1.6
			m.ring.Transparency = active and (0.3 + 0.7 * k) or 1
			if active then
				local base = m.point.Position
				m.gem.CFrame = CFrame.new(base + Vector3.new(0, 4.2 + math.sin((t + m.t0) * 2.2) * 0.45, 0))
					* CFrame.Angles(0, t * 1.8, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
				local s = 3.5 + k * 3
				m.ring.Size = Vector3.new(0.12, s, s)
				m.ring.CFrame = CFrame.new(base + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
			end
		end
	end
end)

---------------------------------------------------------------------
-- 2. Mientras mantengo E
---------------------------------------------------------------------
local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 0.6
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function makeEffect(kind: string, color: Color3, att: Attachment)
	local cs = ColorSequence.new(color)
	if kind == "sparks" then
		emitter(att, { Texture = SPARK, Color = cs, Rate = 40, Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(8, 14), SpreadAngle = Vector2.new(70, 70),
			Acceleration = Vector3.new(0, -25, 0), Size = NumberSequence.new(0.35, 0), LightEmission = 1 })
	elseif kind == "drops" then
		emitter(att, { Texture = SPARK, Color = cs, Rate = 30, Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(4, 7), SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, -18, 0), Size = NumberSequence.new(0.4, 0.15), EmissionDirection = Enum.NormalId.Top })
	elseif kind == "leaves" then
		emitter(att, { Texture = SPARK, Color = cs, Rate = 18, Lifetime = NumberRange.new(1.2, 1.8), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(60, 60),
			Acceleration = Vector3.new(0, 1.5, 0), Size = NumberSequence.new(0.5, 0.2), RotSpeed = NumberRange.new(-120, 120), Rotation = NumberRange.new(0, 360) })
	elseif kind == "dust" then
		emitter(att, { Texture = SMOKE, Color = cs, Rate = 16, Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(80, 80),
			Size = NumberSequence.new(0.8, 2.4), Transparency = NumberSequence.new(0.3, 1), LightEmission = 0 })
	elseif kind == "rays" then
		emitter(att, { Texture = SPARK, Color = cs, Rate = 22, Lifetime = NumberRange.new(0.6, 0.9), Speed = NumberRange.new(5, 8), SpreadAngle = Vector2.new(180, 180),
			Size = NumberSequence.new(0.6, 0), LightEmission = 1 })
	else -- rings / count / default
		emitter(att, { Texture = SPARK, Color = cs, Rate = 20, Lifetime = NumberRange.new(0.8, 1.2), Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(50, 50),
			Acceleration = Vector3.new(0, 3, 0), Size = NumberSequence.new(0.4, 0), LightEmission = 1 })
	end
end

local active: { [ProximityPrompt]: { anchor: Part, conn: RBXScriptConnection?, running: boolean } } = {}

local function stopHold(prompt: ProximityPrompt)
	local a = active[prompt]
	if not a then
		return
	end
	active[prompt] = nil
	a.running = false
	if a.conn then
		a.conn:Disconnect()
	end
	for _, e in a.anchor:GetDescendants() do
		if e:IsA("ParticleEmitter") then
			e.Enabled = false
		end
	end
	local bb = a.anchor:FindFirstChild("FxIcon")
	if bb then
		bb:Destroy()
	end
	task.delay(1.5, function()
		a.anchor:Destroy()
	end)
end

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, who)
	if who ~= player or active[prompt] then
		return
	end
	local pos = promptPos(prompt)
	if not pos then
		return
	end
	local style = styleFor(prompt.ActionText)
	local anchor = anchorPart(pos + Vector3.new(0, 1.5, 0))
	local att = Instance.new("Attachment")
	att.Parent = anchor
	makeEffect(style.Kind, style.Color, att)

	-- ícono que se mece + barra de progreso
	local bb = Instance.new("BillboardGui")
	bb.Name = "FxIcon"
	bb.Size = UDim2.fromOffset(70, 86)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(70, 64)
	icon.BackgroundColor3 = Color3.new(1, 1, 1)
	icon.BackgroundTransparency = 0.1
	icon.Text = style.Icon
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(1, 0)
	ic.Parent = icon
	local ip = Instance.new("UIPadding")
	ip.PaddingTop = UDim.new(0.15, 0)
	ip.PaddingBottom = UDim.new(0.15, 0)
	ip.Parent = icon
	local st = Instance.new("UIStroke")
	st.Color = style.Color
	st.Thickness = 4
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = icon
	icon.Parent = bb
	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(5, 72)
	barBg.Size = UDim2.fromOffset(60, 10)
	barBg.BackgroundColor3 = Color3.fromRGB(26, 18, 64)
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = barBg
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = style.Color
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill
	fill.Parent = barBg
	barBg.Parent = bb
	bb.Parent = anchor

	-- números que saltan (tipo "count")
	local entry = { anchor = anchor, conn = nil :: RBXScriptConnection?, running = true }
	active[prompt] = entry
	if style.Kind == "count" then
		task.spawn(function()
			local n = 0
			while entry.running do
				n += 1
				local nb = Instance.new("BillboardGui")
				nb.Size = UDim2.fromOffset(40, 40)
				nb.StudsOffset = Vector3.new(math.random(-15, 15) / 10, 1, 0)
				nb.AlwaysOnTop = true
				local tl = Instance.new("TextLabel")
				tl.Size = UDim2.fromScale(1, 1)
				tl.BackgroundTransparency = 1
				tl.Text = tostring(n)
				tl.TextScaled = true
				tl.Font = Enum.Font.FredokaOne
				tl.TextColor3 = style.Color
				tl.TextStrokeTransparency = 0.3
				tl.Parent = nb
				nb.Parent = anchor
				TweenService:Create(nb, TweenInfo.new(0.8), { StudsOffset = nb.StudsOffset + Vector3.new(0, 2.5, 0) }):Play()
				TweenService:Create(tl, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				task.delay(0.85, function() nb:Destroy() end)
				task.wait(0.5)
			end
		end)
	end

	local t0 = os.clock()
	local hold = math.max(prompt.HoldDuration, 0.1)
	local ringT = 0
	entry.conn = RunService.RenderStepped:Connect(function(dt)
		local a = math.clamp((os.clock() - t0) / hold, 0, 1)
		fill.Size = UDim2.fromScale(a, 1)
		icon.Rotation = math.sin(os.clock() * 10) * 12
		-- mirar hacia el objeto
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local flat = Vector3.new(pos.X, root.Position.Y, pos.Z)
			if (flat - root.Position).Magnitude > 0.5 then
				root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, flat), math.min(1, dt * 8))
			end
		end
		-- anillos que suben (tipo "rings")
		if style.Kind == "rings" then
			ringT += dt
			if ringT > 0.45 then
				ringT = 0
				local r = Instance.new("Part")
				r.Shape = Enum.PartType.Cylinder
				r.Anchored = true
				r.CanCollide = false
				r.CanQuery = false
				r.Material = Enum.Material.Neon
				r.Color = style.Color
				r.Transparency = 0.3
				r.Size = Vector3.new(0.1, 1.5, 1.5)
				r.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
				r.Parent = fxFolder
				TweenService:Create(r, TweenInfo.new(1), { Size = Vector3.new(0.1, 6, 6), Transparency = 1,
					CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)) }):Play()
				task.delay(1.05, function() r:Destroy() end)
			end
		end
	end)
end)

ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, who)
	if who == player then
		stopHold(prompt)
	end
end)

---------------------------------------------------------------------
-- 3. Al terminar: estallido de estrellas + "Done!"
---------------------------------------------------------------------
ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	local pos = promptPos(prompt)
	stopHold(prompt)
	if not pos then
		return
	end
	local style = styleFor(prompt.ActionText)
	local anchor = anchorPart(pos + Vector3.new(0, 2, 0))
	local att = Instance.new("Attachment")
	att.Parent = anchor
	local burst = emitter(att, { Texture = SPARK, Color = ColorSequence.new(style.Color, Color3.new(1, 1, 1)), Rate = 0,
		Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -12, 0), Size = NumberSequence.new(0.6, 0), LightEmission = 1 })
	burst:Emit(40)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 44)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = X.MissionDoneText -- 16-nov: sin ✔ (la fuente no lo tiene y salía un cuadro vacío)
	tl.TextScaled = true
	tl.Font = Enum.Font.FredokaOne
	tl.TextColor3 = Color3.fromRGB(120, 255, 160)
	tl.TextStrokeTransparency = 0.2
	tl.Parent = bb
	bb.Parent = anchor
	local sc = Instance.new("UIScale")
	sc.Scale = 0.3
	sc.Parent = tl
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(bb, TweenInfo.new(1.4), { StudsOffset = Vector3.new(0, 5, 0) }):Play()
	task.delay(0.9, function()
		TweenService:Create(tl, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	task.delay(1.6, function()
		anchor:Destroy()
	end)
end)
