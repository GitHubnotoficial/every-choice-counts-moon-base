-- MoonFootprints (LocalScript) -> StarterPlayer.StarterPlayerScripts.MoonFootprints
-- [15-nov] Huellas de bota en el suelo de la Luna para TODOS los personajes (izquierda y derecha alternadas).
-- Duran Config.Extras.Footprints.Life segundos y luego se borran solas. Solo visual y solo en este cliente:
-- no chocan, los rayos no las ven y no cambian nada del juego.
-- Dato real: en la Luna no hay viento ni lluvia, así que las huellas de los astronautas siguen ahí.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local F = Config.Extras.Footprints

local folder = Instance.new("Folder")
folder.Name = "SO_Footprints"
folder.Parent = workspace

-- Solo se marcan en suelo lunar (no en pisos de la base ni de la nave)
local SOIL = {
	[Enum.Material.Sand] = true, [Enum.Material.Slate] = true, [Enum.Material.Rock] = true, [Enum.Material.Basalt] = true,
	[Enum.Material.Ground] = true, [Enum.Material.Salt] = true, [Enum.Material.Snow] = true, [Enum.Material.Mud] = true,
	[Enum.Material.Pebble] = true, [Enum.Material.Sandstone] = true, [Enum.Material.Limestone] = true,
}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true

local prints: { BasePart } = {}
local state: { [Model]: { last: Vector3?, left: boolean } } = setmetatable({}, { __mode = "k" }) :: any

local function makePrint(pos: Vector3, normal: Vector3, forward: Vector3, color: Color3)
	-- huella: suela ovalada + tacón, un poco más oscuras que el suelo
	local right = forward:Cross(normal).Unit
	forward = normal:Cross(right).Unit
	local base = CFrame.fromMatrix(pos + normal * 0.06, right, normal, -forward) -- encima de las manchas del suelo (0.04)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.32)
	local parts = {}
	for i, spec in { { Vector3.new(0.75, 0.05, 1.05), CFrame.new(0, 0, -0.35) }, { Vector3.new(0.6, 0.05, 0.6), CFrame.new(0, 0, 0.6) } } do
		local p = Instance.new("Part")
		p.Name = i == 1 and "Sole" or "Heel"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = dark
		p.Transparency = 0.15
		p.Size = spec[1]
		p.CFrame = base * spec[2]
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		p.Parent = folder
		table.insert(parts, p)
		table.insert(prints, p)
	end
	-- se borran solas
	task.delay(F.Life, function()
		for _, p in parts do
			if p.Parent then
				local tw = TweenService:Create(p, TweenInfo.new(3), { Transparency = 1 })
				tw:Play()
				tw.Completed:Once(function()
					p:Destroy()
				end)
			end
		end
	end)
	-- tope: borra las más viejas
	while #prints > F.Max do
		local old = table.remove(prints, 1)
		if old and old.Parent then
			old:Destroy()
		end
	end
end

local function stepFor(char: Model)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or root.Position.X < F.MoonX then
		return
	end
	if hum.FloorMaterial == Enum.Material.Air then
		return
	end
	local st = state[char]
	if not st then
		st = { last = nil, left = false }
		state[char] = st
	end
	local flat = root.Position * Vector3.new(1, 0, 1)
	if st.last and (flat - st.last).Magnitude < F.Step then
		return
	end
	local move = st.last and (flat - st.last) or root.CFrame.LookVector * Vector3.new(1, 0, 1)
	st.last = flat
	if move.Magnitude < 0.05 then
		return
	end
	st.left = not st.left
	local side = move.Unit:Cross(Vector3.yAxis) * (st.left and 0.55 or -0.55)
	local ignore = { folder }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(root.Position + side, Vector3.new(0, -(hum.HipHeight + root.Size.Y / 2 + 3), 0), params)
	if not hit or not SOIL[hit.Material] then
		return
	end
	local color = hit.Instance:IsA("BasePart") and (hit.Instance :: BasePart).Color or Color3.fromRGB(190, 188, 200)
	if hit.Instance:IsA("Terrain") then
		color = Color3.fromRGB(190, 188, 200)
	end
	makePrint(hit.Position, hit.Normal, move.Unit, color)
end

while true do
	task.wait(0.08)
	for _, p in Players:GetPlayers() do
		local char = p.Character
		if char and char.Parent then
			stepFor(char)
		end
	end
end
