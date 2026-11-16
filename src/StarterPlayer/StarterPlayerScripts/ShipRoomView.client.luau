-- ShipRoomView (LocalScript) -> StarterPlayer.StarterPlayerScripts.ShipRoomView
-- [15-nov] Cuando MI personaje (o la cámara) está dentro del cuarto de la nave (MoonSite.ChosenLander.ShipRoom),
-- escondo SOLO para mí las piezas de la nave que atraviesan el cuarto (LanderRefill las marca con LR_InRoom).
-- Afuera la nave se ve completa. No cambia nada del servidor.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local hidden: { BasePart } = {}

local function inside(cf: CFrame, size: Vector3, p: Vector3): boolean
	local rel = cf:PointToObjectSpace(p)
	return math.abs(rel.X) <= size.X / 2 and math.abs(rel.Y) <= size.Y / 2 and math.abs(rel.Z) <= size.Z / 2
end

local function setHidden(ship: Model?, on: boolean)
	if not on then
		for _, p in hidden do
			p.LocalTransparencyModifier = 0
		end
		table.clear(hidden)
		return
	end
	if #hidden > 0 or not ship then
		return
	end
	for _, d in ship:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("LR_InRoom") then
			d.LocalTransparencyModifier = 1
			table.insert(hidden, d)
		end
	end
end

while true do
	task.wait(0.15)
	local site = workspace:FindFirstChild("MoonSite")
	local ship = site and site:FindFirstChild("ChosenLander") :: Model?
	local room = ship and ship:FindFirstChild("ShipRoom") :: Model?
	local isIn = false
	if room then
		local cf, size = room:GetBoundingBox()
		size += Vector3.new(1, 2, 1)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local cam = workspace.CurrentCamera
		isIn = (root ~= nil and inside(cf, size, root.Position)) or (cam ~= nil and inside(cf, size, cam.CFrame.Position))
	end
	setHidden(ship, isIn)
end
