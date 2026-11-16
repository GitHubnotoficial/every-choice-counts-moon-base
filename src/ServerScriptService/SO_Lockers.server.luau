-- SO_Lockers: una taquilla de traje por cuarto de la Fase 0, con un maniquí vestido como los jugadores
-- (cuerpo blanco, casco, guantes, botas y la mochila del color del rol, de ServerStorage.SO_Suit).
-- Plantilla: ServerStorage.SO_Locker (taquilla de Yamir sin el traje genérico, assets/yamir/taquilla_vacia.glb).
-- Si un cuarto ya tiene su taquilla (por ejemplo, construida en Edit), no la repite.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local LC = Config.Lockers

local TEMPLATE = ServerStorage:FindFirstChild("SO_Locker")
local SUIT = ServerStorage:FindFirstChild("SO_Suit")
local base = workspace:WaitForChild("EarthBase", 30)
if not TEMPLATE or not base then return end

local function freeze(m: Instance)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		end
	end
end

-- Pega una pieza del traje (escalada al ancho de la parte del cuerpo)
local function gear(rig: Model, name: string, bodyName: string, mult: number, where: string)
	local src = SUIT and SUIT:FindFirstChild(name)
	local body = rig:FindFirstChild(bodyName) :: BasePart?
	if not src or not body then return end
	local m = src:Clone() :: Model
	m.Name = "SO_" .. name
	local _, sz = m:GetBoundingBox()
	local ref = (name == "Helmet") and body.Size.Y or math.min(body.Size.X, body.Size.Z)
	m:ScaleTo(m:GetScale() * ref * mult / math.max(sz.X, 0.01))
	local _, sz2 = m:GetBoundingBox()
	local y = (where == "bottom") and (-body.Size.Y / 2 + sz2.Y / 2 - 0.05) or 0.08
	m:PivotTo(body.CFrame * CFrame.new(0, y, 0))
	m.Parent = rig
end

local function backpack(rig: Model, role: string)
	local src = SUIT and SUIT:FindFirstChild("Backpack_" .. role)
	local torso = rig:FindFirstChild("UpperTorso") :: BasePart?
	if not src or not torso then return end
	local m = src:Clone() :: Model
	m.Name = "SO_Backpack"
	local _, sz = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * torso.Size.X * 0.9 / math.max(sz.X, 0.01))
	local _, sz2 = m:GetBoundingBox()
	m:PivotTo(torso.CFrame * CFrame.new(0, 0.05, torso.Size.Z / 2 + sz2.Z / 2 - 0.05))
	m.Parent = rig
end

-- Maniquí con la misma forma que los jugadores (R15 por defecto)
local function mannequin(role: string): Model?
	local ok, rig = pcall(function()
		return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	end)
	if not ok or not rig then return nil end
	rig.Name = "SO_SuitMannequin"
	for _, d in rig:GetDescendants() do
		if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Color = LC.SuitColor
		end
	end
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end
	rig:PivotTo(CFrame.new(0, 100, 0))
	gear(rig, "Helmet", "Head", 1.35, "center")
	gear(rig, "GloveL", "LeftHand", 1.45, "bottom")
	gear(rig, "GloveR", "RightHand", 1.45, "bottom")
	gear(rig, "BootL", "LeftFoot", 1.35, "bottom")
	gear(rig, "BootR", "RightFoot", 1.35, "bottom")
	backpack(rig, role)
	local head = rig:FindFirstChild("Head")
	local face = head and head:FindFirstChildOfClass("Decal")
	if face then face.Transparency = 1 end
	freeze(rig)
	return rig
end

local function buildRoom(room: Model, role: string)
	if room:FindFirstChild("SO_SuitLocker") then return end
	local floor = room:FindFirstChild("Floor") :: BasePart?
	if not floor then return end
	-- Lado del pasillo: la puerta está en la pared más cercana a z = 0
	local inward = (floor.Position.Z >= 0) and 1 or -1
	local doorZ = floor.Position.Z - inward * floor.Size.Z / 2
	local floorY = floor.Position.Y + floor.Size.Y / 2
	local fx, hx = floor.Position.X, floor.Size.X / 2
	local W, D = LC.Width, LC.Depth
	local face = LC.WallThick -- las paredes van centradas en el borde del piso

	-- Hueco de la puerta (no se puede tapar)
	local fl, fr = room:FindFirstChild("DoorFrameL"), room:FindFirstChild("DoorFrameR")
	local doorX0 = fl and math.min(fl.Position.X, fr.Position.X) - 1 or fx - 5
	local doorX1 = fl and math.max(fl.Position.X, fr.Position.X) + 1 or fx + 5

	-- Lugares posibles pegados a la pared: junto a la puerta (mirando al cuarto) y en las paredes laterales
	-- Cada uno: centro en el piso, hacia dónde mira, y si su ancho va en X o en Z
	local candidates = {}
	for t = 0, hx * 2 - 2 * face - 2 * LC.WallGap - W, LC.SearchStep do
		for _, side in { -1, 1 } do
			local x = fx + side * (hx - face - LC.WallGap - W / 2 - t)
			if x + W / 2 < doorX0 or x - W / 2 > doorX1 then
				table.insert(candidates, { Vector3.new(x, 0, doorZ + inward * (face + LC.WallGap + D / 2)), Vector3.new(0, 0, inward) })
			end
		end
	end
	for t = 0, floor.Size.Z - 2 * face - LC.DoorGap - W - LC.WallGap, LC.SearchStep do
		for _, side in { -1, 1 } do
			local z = doorZ + inward * (face + LC.DoorGap + W / 2 + t)
			table.insert(candidates, { Vector3.new(fx + side * (hx - face - LC.WallGap - D / 2), 0, z), Vector3.new(-side, 0, 0) })
		end
	end

	-- Prueba: nada en la caja de la taquilla extendida hasta la pared (lo que haya colgado detrás),
	-- un poco más alta (lo que haya encima) y con espacio libre delante (para no estorbar el paso).
	-- Se revisan TODAS las piezas del cuarto (también las pantallas y luces que no responden a consultas
	-- de física), menos el piso, las que ocupan todo el cuarto (zócalo, techo), el papel tapiz
	-- (láminas finas y largas pegadas a la pared) y las piezas diminutas (estrellitas pintadas).
	local function ignore(p: BasePart): boolean
		local s = p.Size
		local mn, mx = math.min(s.X, s.Y, s.Z), math.max(s.X, s.Y, s.Z)
		return p == floor or (s.X > floor.Size.X * 0.8 and s.Z > floor.Size.Z * 0.8)
			or (mn <= LC.SkinThick and mx >= LC.SkinLength) or mx < LC.TinySize
	end
	local parts = {}
	for _, p in room:GetDescendants() do
		if p:IsA("BasePart") and not ignore(p) then
			local cf, sz = p.CFrame, p.Size / 2
			local ext = Vector3.new(
				math.abs(cf.RightVector.X) * sz.X + math.abs(cf.UpVector.X) * sz.Y + math.abs(cf.LookVector.X) * sz.Z,
				math.abs(cf.RightVector.Y) * sz.X + math.abs(cf.UpVector.Y) * sz.Y + math.abs(cf.LookVector.Y) * sz.Z,
				math.abs(cf.RightVector.Z) * sz.X + math.abs(cf.UpVector.Z) * sz.Y + math.abs(cf.LookVector.Z) * sz.Z)
			table.insert(parts, { p = p, lo = cf.Position - ext, hi = cf.Position + ext })
		end
	end
	local decor = room:FindFirstChild("SO_Decor")
	local movable = {}
	for _, n in LC.Movable do movable[n] = true end
	local function test(c, H, pass)
		local dir = c[2]
		local back = LC.WallGap - 0.05 -- hasta casi tocar la pared
		local depth = D + back + LC.FrontClear
		local mid = c[1] + dir * ((LC.FrontClear - back) / 2)
		local h = H + LC.TopClear
		local pos = Vector3.new(mid.X, floorY + 0.25 + h / 2, mid.Z)
		local half = ((math.abs(dir.X) > 0) and Vector3.new(depth, h, W + 0.4) or Vector3.new(W + 0.4, h, depth)) / 2
		local lo, hi = pos - half, pos + half
		local hits = {}
		for _, e in parts do
			if e.p.Parent and e.lo.X < hi.X and e.hi.X > lo.X and e.lo.Y < hi.Y and e.hi.Y > lo.Y and e.lo.Z < hi.Z and e.hi.Z > lo.Z then
				if pass == 1 or not (decor and e.p:IsDescendantOf(decor) and movable[e.p.Name]) then return nil end
				table.insert(hits, e.p)
			end
		end
		return hits
	end

	local spot, dir, H
	for pass = 1, 2 do
		for _, h in LC.Heights do
			for _, c in candidates do
				local hits = test(c, h, pass)
				if hits then
					for _, p in hits do p:Destroy() end
					spot, dir, H = Vector3.new(c[1].X, floorY + h / 2 + 0.05, c[1].Z), c[2], h
					break
				end
			end
			if spot then break end
		end
		if spot then break end
	end
	if not spot then
		warn("[SO_Lockers] sin hueco libre en " .. room.Name)
		return
	end

	local locker = TEMPLATE:Clone()
	locker.Name = "SO_SuitLocker"
	locker:SetAttribute("Height", H)
	-- Medidas: alto, ancho y fondo propios (un avatar de Roblox con los brazos mide ~4 de ancho)
	local pivot, s = locker:GetBoundingBox()
	local k = Vector3.new(W / s.X, H / s.Y, D / s.Z)
	for _, p in locker:GetDescendants() do
		if p:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(p.CFrame)
			p.Size = p.Size * k
			p.CFrame = pivot * CFrame.new(rel.Position * k) * rel.Rotation
		end
	end
	-- Colores, materiales y vidrio transparente
	for _, p in locker:GetDescendants() do
		local look = p:IsA("BasePart") and LC.Look[p.Name]
		if look then
			p.Color = Color3.fromHex(look[1])
			p.Material = look[2] and Enum.Material[look[2]] or Enum.Material.SmoothPlastic
			p.Transparency = look[3] or 0
			p.CastShadow = look[3] == nil
		end
	end

	-- La puerta del modelo mira a -Z (LookVector): se gira hacia el centro del cuarto
	local function placeCenter(m: Model, cf: CFrame)
		m:PivotTo(cf)
		local bb = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + (cf.Position - bb.Position))
	end
	placeCenter(locker, CFrame.lookAt(spot, spot + dir))
	-- Si la puerta quedó hacia la pared (depende de cómo se importó), se gira 180°
	local door = locker:FindFirstChild("Puerta", true) :: BasePart?
	if door and (door.Position - spot):Dot(dir) < 0 then
		locker:PivotTo(CFrame.new(spot) * CFrame.Angles(0, math.pi, 0) * CFrame.new(spot):ToObjectSpace(locker:GetPivot()))
	end
	freeze(locker)
	locker.Parent = room

	local rig = mannequin(role)
	if rig then
		local _, rs = rig:GetBoundingBox()
		local fit = math.min(1, LC.MannequinHeight / rs.Y, H * LC.InnerHeight / rs.Y, W * LC.InnerWidth / rs.X, D * LC.InnerDepth / rs.Z)
		rig:ScaleTo(rig:GetScale() * fit)
		local _, rs2 = rig:GetBoundingBox()
		local inner = floorY + LC.InnerFloor * H
		-- Mirando hacia afuera, como la puerta, y un poco hacia el fondo
		local c = Vector3.new(spot.X, inner + rs2.Y / 2, spot.Z) - dir * LC.BackOffset
		placeCenter(rig, CFrame.lookAt(c, c + dir))
		rig.Parent = locker
	end
end

local roleOf = { Room_cap = "cap", Room_eng = "eng", Room_life = "life", Room_bot = "bot" }
for roomName, role in roleOf do
	local room = base:FindFirstChild(roomName)
	if room then
		local ok, err = pcall(buildRoom, room, role)
		if not ok then warn("[SO_Lockers] " .. roomName .. ": " .. tostring(err)) end
	end
end
