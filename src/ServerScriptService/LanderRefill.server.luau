-- LanderRefill (Script) -> ServerScriptService.LanderRefill
-- [15-nov, versión 2] Oxígeno y agua en la Luna:
-- 1. Fase 1 (Landing, Placement, Transition12): la nave elegida se ve más grande (Phase1Config.ShipScale) y
--    tiene un CUARTO pequeño adentro, con la puerta del lado +X. Adentro hay un tanque de OXÍGENO y uno de AGUA
--    (mantener E: cada tanque llena su barra).
-- 2. Fase 2 en adelante: la nave se aleja (Phase1Config.ShipFarOffset) y en su lugar aparece una BASE
--    PROVISIONAL (módulo blanco con franjas rojas, medio enterrado) con los mismos dos tanques.
-- 3. 2.º punto de recarga junto a la máquina de Life Support (igual que antes).
-- El cuarto y la base van DENTRO de MoonSite.ChosenLander (lo crea MoonExtras, de Isaac) para que los rayos que
-- ponen los puntos de misión en el suelo los ignoren. Los dos quedan dentro de LanderZone (Bars: "adentro").
-- Lee:     GameState.Phase, ReserveO2, ReserveWater, MissionComplete_life. Atributos del jugador O2, Water, Dead.
-- Escribe: atributos O2 y Water; GameState.ReserveO2 / ReserveWater (solo en Fase 3).
--          Agranda y mueve MoonSite.ChosenLander; esconde la rampa vieja de la nave en la Fase 2.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local T = P1.Text

-- Las mismas fases en que Bars baja las barras
local ACTIVE_PHASES = {
	Landing = true, Placement = true, Transition12 = true, Phase2Intro = true,
	Phase2 = true, Transition23 = true, Phase3 = true,
}
local ROOM_PHASES = { Landing = true, Placement = true, Transition12 = true }
local BASE_PHASES = { Phase2Intro = true, Phase2 = true, Transition23 = true, Phase3 = true, Rescue = true, End = true }

local site = workspace:WaitForChild("MoonSite")
local lander = site:WaitForChild("Lander") :: Model

local SKY = Config.Colors.Sky
local WHITE = Color3.fromRGB(240, 241, 244)
local INNER = Color3.fromRGB(222, 226, 234)
local METAL = Color3.fromRGB(150, 156, 166)
local DARK = Color3.fromRGB(40, 44, 54)
local RED = Color3.fromRGB(226, 46, 64)

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------
-- solid = choca con los jugadores. Las piezas de adorno no chocan ni las tocan los rayos.
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, solid: boolean, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid
	if not solid then
		p.CanQuery = false
		p.CanTouch = false
	end
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function billboard(parent: Instance, text: string, color: Color3, offset: Vector3, w: number): BillboardGui
	local b = Instance.new("BillboardGui")
	b.Name = "SO_RefillSign"
	b.Size = UDim2.fromOffset(w, 34)
	b.StudsOffsetWorldSpace = offset
	b.MaxDistance = 70
	b.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = color
	t.TextColor3 = Color3.fromHex("1A1240")
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = t
	t.Parent = b
	b.Parent = parent
	return b
end

---------------------------------------------------------------------
-- Recargar
---------------------------------------------------------------------
-- Ambas barras (la usa el punto junto a la máquina de Life Support)
local function doRefill(p: Player)
	if p:GetAttribute("Dead") or p:GetAttribute("O2") == nil then
		return
	end
	local o2, water = p:GetAttribute("O2") or 0, p:GetAttribute("Water") or 0
	local needO2, needWater = 100 - o2, 100 - water
	if needO2 + needWater < 1 then
		Remotes.Toast:FireClient(p, T.ShipRefillFull, 2)
		return
	end
	if GS:GetAttribute("Phase") == "Phase3" then
		-- En la Fase 3 sale de la reserva compartida (1 % de barra = RefillCost % de reserva)
		local byN = Config.Reserve.RefillCostByPlayers -- 16-nov: costo según cuántos jugadores hay
		local cost = byN and byN[math.clamp(#Players:GetPlayers(), 1, #byN)] or Config.Reserve.RefillCost
		local rO2, rW = GS:GetAttribute("ReserveO2") or 0, GS:GetAttribute("ReserveWater") or 0
		needO2 = math.min(needO2, rO2 / cost)
		needWater = math.min(needWater, rW / cost)
		if needO2 + needWater < 1 then
			Remotes.Toast:FireClient(p, Config.Text3.ReserveEmpty, 3)
			return
		end
		GS:SetAttribute("ReserveO2", rO2 - needO2 * cost)
		GS:SetAttribute("ReserveWater", rW - needWater * cost)
	end
	p:SetAttribute("O2", o2 + needO2)
	p:SetAttribute("Water", water + needWater)
	Remotes.Toast:FireClient(p, T.ShipRefillFull, 2)
end

-- Una sola barra: kind = "O2" o "Water" (los tanques del cuarto y de la base)
local function refillOne(p: Player, kind: string)
	if p:GetAttribute("Dead") or p:GetAttribute(kind) == nil then
		return
	end
	if not ACTIVE_PHASES[GS:GetAttribute("Phase") or ""] then
		return
	end
	local full = kind == "O2" and T.TankO2Full or T.TankWaterFull
	local cur = p:GetAttribute(kind) or 0
	local need = 100 - cur
	if need < 1 then
		Remotes.Toast:FireClient(p, full, 2)
		return
	end
	if GS:GetAttribute("Phase") == "Phase3" then
		local key = kind == "O2" and "ReserveO2" or "ReserveWater"
		local byN = Config.Reserve.RefillCostByPlayers -- 16-nov: costo según cuántos jugadores hay
		local cost = byN and byN[math.clamp(#Players:GetPlayers(), 1, #byN)] or Config.Reserve.RefillCost
		local r = GS:GetAttribute(key) or 0
		need = math.min(need, r / cost)
		if need < 1 then
			Remotes.Toast:FireClient(p, Config.Text3.ReserveEmpty, 3)
			return
		end
		GS:SetAttribute(key, r - need * cost)
	end
	p:SetAttribute(kind, cur + need)
	Remotes.Toast:FireClient(p, full, 2)
end

---------------------------------------------------------------------
-- Tanque de oxígeno o de agua (cilindro de pie con anillo que brilla, cartel y "mantener E")
---------------------------------------------------------------------
local prompts: { ProximityPrompt } = {}

local function tank(parent: Instance, kind: string, cf: CFrame)
	local isO2 = kind == "O2"
	local col = isO2 and Color3.fromRGB(236, 246, 255) or Color3.fromRGB(64, 140, 236)
	local glow = isO2 and SKY or Color3.fromRGB(90, 180, 255)
	part(parent, "TankBase", Vector3.new(3, 0.4, 3), cf * CFrame.new(0, 0.2, 0), METAL, Enum.Material.DiamondPlate, true)
	local body = part(parent, "Tank_" .. kind, Vector3.new(4, 2.4, 2.4), cf * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
		col, Enum.Material.SmoothPlastic, true, { Shape = Enum.PartType.Cylinder })
	part(parent, "TankTop", Vector3.new(2.4, 2.4, 2.4), cf * CFrame.new(0, 4.4, 0), col, Enum.Material.SmoothPlastic, false, { Shape = Enum.PartType.Ball })
	local ring = part(parent, "TankRing", Vector3.new(0.35, 2.55, 2.55), cf * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		glow, Enum.Material.Neon, false, { Shape = Enum.PartType.Cylinder })
	part(parent, "TankRing", Vector3.new(0.35, 2.55, 2.55), cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		glow, Enum.Material.Neon, false, { Shape = Enum.PartType.Cylinder })
	part(parent, "Valve", Vector3.new(0.5, 0.5, 0.9), cf * CFrame.new(0, 5.6, 0), Color3.fromRGB(255, 196, 60), Enum.Material.SmoothPlastic, false)
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 9
	light.Brightness = 1.5
	light.Parent = ring
	billboard(body, isO2 and T.TankO2Sign or T.TankWaterSign, glow, Vector3.new(0, 3.9, 0), 120)
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "SO_Tank_" .. kind
	pr.ActionText = isO2 and T.FillO2 or T.FillWater
	pr.ObjectText = isO2 and T.TankO2Object or T.TankWaterObject
	pr.HoldDuration = P1.LanderRefillHold
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.RequiresLineOfSight = false
	pr.MaxActivationDistance = Config.PromptDistance + 2
	pr.Enabled = ACTIVE_PHASES[GS:GetAttribute("Phase") or ""] == true
	pr.Parent = body
	pr.Triggered:Connect(function(p)
		refillOne(p, kind)
	end)
	table.insert(prompts, pr)
end

local function cleanPrompts()
	for i = #prompts, 1, -1 do
		if not prompts[i].Parent then
			table.remove(prompts, i)
		end
	end
end

---------------------------------------------------------------------
-- [15-nov] Detalles para que el cuarto y la base se vean acogedores: ventana con la Tierra, estante con cajas,
-- cables y lucecitas de colores (MoonAmbient las hace parpadear con el atributo AnimBlink).
---------------------------------------------------------------------
-- Ventana con vista al espacio y la Tierra. La cara Front de la pieza mira hacia adentro.
local function earthWindow(parent: Instance, cf: CFrame, w: number, h: number)
	part(parent, "WindowFrame", Vector3.new(w + 0.5, h + 0.5, 0.12), cf, DARK, nil, false)
	local win = part(parent, "SpaceWindow", Vector3.new(w, h, 0.16), cf, Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, false)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.LightInfluence = 0
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 60
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(6, 6, 22)
	bg.BorderSizePixel = 0
	bg.Parent = g
	local rng = Random.new(8)
	for _ = 1, 26 do
		local s = Instance.new("Frame")
		local px = rng:NextInteger(2, 4)
		s.Size = UDim2.fromOffset(px, px)
		s.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
		s.BackgroundColor3 = Color3.new(1, 1, 1)
		s.BackgroundTransparency = rng:NextNumber(0, 0.5)
		s.BorderSizePixel = 0
		s.Parent = bg
	end
	local earth = Instance.new("Frame")
	earth.AnchorPoint = Vector2.new(0.5, 0.5)
	earth.Position = UDim2.fromScale(0.66, 0.42)
	earth.Size = UDim2.fromScale(0.5, 0.5)
	earth.BackgroundColor3 = Color3.fromRGB(46, 112, 220)
	earth.BorderSizePixel = 0
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.Parent = earth
	local ec = Instance.new("UICorner")
	ec.CornerRadius = UDim.new(1, 0)
	ec.Parent = earth
	local es = Instance.new("UIStroke")
	es.Color = Color3.fromRGB(150, 210, 255)
	es.Thickness = 4
	es.Transparency = 0.3
	es.Parent = earth
	for _, l in { { 0.3, 0.35, 0.35, 0.25 }, { 0.62, 0.62, 0.3, 0.22 }, { 0.55, 0.2, 0.18, 0.14 } } do
		local land = Instance.new("Frame")
		land.Position = UDim2.fromScale(l[1], l[2])
		land.Size = UDim2.fromScale(l[3], l[4])
		land.AnchorPoint = Vector2.new(0.5, 0.5)
		land.BackgroundColor3 = Color3.fromRGB(86, 170, 90)
		land.BorderSizePixel = 0
		local lc = Instance.new("UICorner")
		lc.CornerRadius = UDim.new(1, 0)
		lc.Parent = land
		land.Parent = earth
	end
	earth.Parent = bg
	g.Parent = win
end

-- Estante pegado a una pared (a lo largo de X) con cajitas de colores
local function shelf(parent: Instance, cf: CFrame, w: number)
	local COLS = { Color3.fromRGB(240, 150, 50), Color3.fromRGB(90, 130, 210), Color3.fromRGB(80, 190, 120), Color3.fromRGB(230, 80, 90), WHITE }
	local rng = Random.new(3)
	for _, s in { -1, 1 } do
		part(parent, "ShelfSide", Vector3.new(0.15, 5, 1), cf * CFrame.new(s * w / 2, 2.5, 0), METAL, nil, false)
	end
	for _, y in { 1.2, 2.7, 4.2 } do
		part(parent, "ShelfBoard", Vector3.new(w, 0.15, 1), cf * CFrame.new(0, y, 0), METAL, nil, false)
		local x = -w / 2 + 0.4
		while x < w / 2 - 0.6 do
			local bw = rng:NextNumber(0.5, 0.9)
			local bh = rng:NextNumber(0.5, 1.1)
			part(parent, "ShelfBox", Vector3.new(bw, bh, 0.7), cf * CFrame.new(x + bw / 2, y + 0.08 + bh / 2, 0), COLS[rng:NextInteger(1, #COLS)], nil, false)
			x += bw + rng:NextNumber(0.1, 0.3)
		end
	end
end

-- Panel con lucecitas de colores que parpadean (la cara Front mira hacia adentro)
local function lightPanel(parent: Instance, cf: CFrame)
	local COLS = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(80, 230, 120), Color3.fromRGB(255, 190, 60), SKY }
	local rng = Random.new(11)
	part(parent, "LightPanel", Vector3.new(2.2, 1.8, 0.12), cf, DARK, nil, false)
	for i = 0, 2 do
		for j = 0, 2 do
			local l = part(parent, "PanelLight", Vector3.new(0.35, 0.35, 0.1), cf * CFrame.new(-0.6 + i * 0.6, -0.5 + j * 0.5, -0.08),
				COLS[rng:NextInteger(1, #COLS)], Enum.Material.Neon, false)
			l:SetAttribute("AnimBlink", rng:NextNumber(0.5, 2.2))
		end
	end
end

-- Cable entre dos puntos
local function cable(parent: Instance, a: Vector3, b: Vector3, color: Color3)
	local len = (b - a).Magnitude
	part(parent, "Cable", Vector3.new(0.18, 0.18, len), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.SmoothPlastic, false)
end

local function floorCF(): CFrame
	-- El pivote de la nave está sobre la plataforma
	return CFrame.new(lander:GetPivot().Position)
end

---------------------------------------------------------------------
-- 1. Cuarto dentro de la nave (Fase 1)
---------------------------------------------------------------------
local RW, RD, RH = 11, 11, 7.5 -- medidas por dentro (X, Z, alto)

-- Las piezas de la nave que tapan el cuarto o el pasillo dejan de chocar (para poder entrar)
local function shipCollisions(ship: Model, regionCF: CFrame?, regionSize: Vector3?)
	for _, d in ship:GetDescendants() do
		if d:IsA("BasePart") and not d:FindFirstAncestor("ShipRoom") and not d:FindFirstAncestor("TempBase") then
			if d:GetAttribute("LR_CC") == nil then
				d:SetAttribute("LR_CC", d.CanCollide)
			end
			local block = false
			if regionCF and regionSize then
				-- ¿se cruza la caja de la pieza con la caja del cuarto + pasillo?
				local rel = regionCF:PointToObjectSpace(d.Position)
				local half = regionSize / 2 + d.Size / 2
				block = math.abs(rel.X) < half.X and math.abs(rel.Y) < half.Y and math.abs(rel.Z) < half.Z
			end
			d.CanCollide = (not block) and d:GetAttribute("LR_CC")
			-- ShipRoomView (cliente) esconde estas piezas solo para quien está dentro del cuarto
			d:SetAttribute("LR_InRoom", block or nil)
		end
	end
end

local function buildRoom(ship: Model)
	local old = ship:FindFirstChild("ShipRoom")
	if old then
		old:Destroy()
	end
	local c = floorCF()
	local bcf, size = ship:GetBoundingBox()
	local room = Instance.new("Model")
	room.Name = "ShipRoom"

	local hx, hz = RW / 2, RD / 2
	-- piso, techo y paredes
	part(room, "Floor", Vector3.new(RW + 1.2, 0.4, RD + 1.2), c * CFrame.new(0, 0.2, 0), METAL, Enum.Material.DiamondPlate, true)
	part(room, "Ceiling", Vector3.new(RW + 1.2, 0.5, RD + 1.2), c * CFrame.new(0, RH + 0.25, 0), INNER, nil, true)
	part(room, "Wall", Vector3.new(0.6, RH, RD + 1.2), c * CFrame.new(-hx - 0.3, RH / 2, 0), INNER, nil, true)
	part(room, "Wall", Vector3.new(RW + 1.2, RH, 0.6), c * CFrame.new(0, RH / 2, hz + 0.3), INNER, nil, true)
	part(room, "Wall", Vector3.new(RW + 1.2, RH, 0.6), c * CFrame.new(0, RH / 2, -hz - 0.3), INNER, nil, true)
	-- pared de la puerta (+X) con hueco de 4,4 x 6,5
	local side = hz + 0.6 - 2.2
	part(room, "Wall", Vector3.new(0.6, RH, side), c * CFrame.new(hx + 0.3, RH / 2, 2.2 + side / 2), INNER, nil, true)
	part(room, "Wall", Vector3.new(0.6, RH, side), c * CFrame.new(hx + 0.3, RH / 2, -2.2 - side / 2), INNER, nil, true)
	part(room, "Wall", Vector3.new(0.6, RH - 6.5, 4.4), c * CFrame.new(hx + 0.3, 6.5 + (RH - 6.5) / 2, 0), INNER, nil, true)
	-- franja de color y luz en el techo
	for _, z in { -hz + 0.05, hz - 0.05 } do
		part(room, "Stripe", Vector3.new(RW, 0.5, 0.1), c * CFrame.new(0, 1.2, z), SKY, Enum.Material.Neon, false)
	end
	local lamp = part(room, "Lamp", Vector3.new(5, 0.15, 2), c * CFrame.new(0, RH - 0.05, 0), Color3.fromRGB(255, 250, 236), Enum.Material.Neon, false)
	local pl = Instance.new("PointLight")
	pl.Range = 18
	pl.Brightness = 1.6
	pl.Color = Color3.fromRGB(255, 244, 226)
	pl.Parent = lamp
	-- banca y pantalla
	part(room, "Bench", Vector3.new(5, 1.2, 1.6), c * CFrame.new(1, 0.8, -hz + 1), Color3.fromRGB(90, 110, 160), nil, true)
	part(room, "Screen", Vector3.new(3.6, 2.2, 0.15), c * CFrame.new(1, 4.4, -hz + 0.1), DARK, Enum.Material.SmoothPlastic, false)
	part(room, "ScreenGlow", Vector3.new(3.2, 1.8, 0.1), c * CFrame.new(1, 4.4, -hz + 0.2), Color3.fromRGB(70, 190, 255), Enum.Material.Neon, false, { Transparency = 0.3 })
	-- tanques al fondo
	tank(room, "O2", c * CFrame.new(-hx + 1.8, 0.4, -2.6))
	tank(room, "Water", c * CFrame.new(-hx + 1.8, 0.4, 2.6))
	-- detalles acogedores (15-nov)
	earthWindow(room, c * CFrame.new(2, 4.2, hz - 0.05), 3.2, 2.2)
	shelf(room, c * CFrame.new(-1.6, 0.4, hz - 0.6), 2.6)
	lightPanel(room, c * CFrame.new(-2.8, 4, -hz + 0.08) * CFrame.Angles(0, math.pi, 0))
	cable(room, (c * CFrame.new(-hx + 0.2, RH - 0.3, -hz + 0.3)).Position, (c * CFrame.new(hx - 0.2, RH - 0.3, -hz + 0.3)).Position, Color3.fromRGB(240, 150, 50))
	cable(room, (c * CFrame.new(-hx + 0.2, RH - 0.5, -hz + 0.3)).Position, (c * CFrame.new(hx - 0.2, RH - 0.5, -hz + 0.3)).Position, Color3.fromRGB(90, 130, 210))
	for _, z in { -2.6, 2.6 } do
		cable(room, (c * CFrame.new(-hx + 0.25, RH - 0.3, z)).Position, (c * CFrame.new(-hx + 0.25, 3, z)).Position, DARK)
		cable(room, (c * CFrame.new(-hx + 0.25, 3, z)).Position, (c * CFrame.new(-hx + 1.2, 3, z)).Position, DARK)
	end

	-- pasillo desde la puerta hasta el borde de la nave
	local x0 = hx + 0.6
	local x1 = math.max(x0 + 1.5, (bcf.X - c.X) + size.X / 2 + 0.8)
	local len = x1 - x0
	local mid = (x0 + x1) / 2
	part(room, "TunnelFloor", Vector3.new(len, 0.4, 5.6), c * CFrame.new(mid, 0.2, 0), METAL, Enum.Material.DiamondPlate, true)
	part(room, "TunnelRoof", Vector3.new(len, 0.4, 5.6), c * CFrame.new(mid, 6.9, 0), INNER, nil, true)
	part(room, "TunnelWall", Vector3.new(len, 6.7, 0.4), c * CFrame.new(mid, 3.55, 2.6), INNER, nil, true)
	part(room, "TunnelWall", Vector3.new(len, 6.7, 0.4), c * CFrame.new(mid, 3.55, -2.6), INNER, nil, true)
	-- marco de la puerta afuera (brilla para encontrarla)
	part(room, "DoorFrame", Vector3.new(0.5, 7.2, 0.6), c * CFrame.new(x1, 3.6, 2.9), SKY, Enum.Material.Neon, false)
	part(room, "DoorFrame", Vector3.new(0.5, 7.2, 0.6), c * CFrame.new(x1, 3.6, -2.9), SKY, Enum.Material.Neon, false)
	local top = part(room, "DoorFrame", Vector3.new(0.5, 0.6, 6.4), c * CFrame.new(x1, 7.3, 0), SKY, Enum.Material.Neon, false)
	billboard(top, T.ShipRoomSign, SKY, Vector3.new(0, 2.4, 0), 220)
	part(room, "Step", Vector3.new(2.4, 0.3, 5.6), c * CFrame.new(x1 + 1.2, 0.15, 0), METAL, Enum.Material.DiamondPlate, true)

	room.Parent = ship
	-- la nave deja de chocar en el cuarto y el pasillo
	local regionCF = c * CFrame.new((x1 - hx - 0.6) / 2, RH / 2, 0)
	local regionSize = Vector3.new(x1 + hx + 1.2, RH + 1, RD + 1.2)
	shipCollisions(ship, regionCF, regionSize)
end

---------------------------------------------------------------------
-- 2. Base provisional (Fase 2 en adelante): módulo blanco con franjas rojas, medio enterrado
---------------------------------------------------------------------
local BL, BW = 16, 12 -- largo (X) y ancho (Z) por fuera

local function buildBase(parent: Instance)
	local old = parent:FindFirstChild("TempBase")
	if old then
		old:Destroy()
	end
	local c = floorCF() * CFrame.new(P1.TempBaseOffset)
	local m = Instance.new("Model")
	m.Name = "TempBase"
	local hl, hw = BL / 2, BW / 2

	-- casco (por dentro queda hueco para caminar)
	part(m, "Floor", Vector3.new(BL, 0.5, BW), c * CFrame.new(0, 0.25, 0), METAL, Enum.Material.DiamondPlate, true)
	for _, s in { -1, 1 } do
		part(m, "Wall", Vector3.new(BL, 7.5, 0.6), c * CFrame.new(0, 3.75, s * (hw - 0.3)), WHITE, nil, true)
		-- borde de arriba redondeado
		part(m, "Edge", Vector3.new(BL, 3, 3), c * CFrame.new(0, 7.5, s * (hw - 1.5)), WHITE, nil, true, { Shape = Enum.PartType.Cylinder })
	end
	part(m, "Roof", Vector3.new(BL, 0.6, BW - 3), c * CFrame.new(0, 8.7, 0), WHITE, nil, true)
	-- pared del fondo (-X)
	part(m, "EndWall", Vector3.new(0.6, 9, BW - 3), c * CFrame.new(-hl + 0.3, 4.5, 0), WHITE, nil, true)
	for _, s in { -1, 1 } do
		part(m, "EndWall", Vector3.new(0.6, 7.5, 1.5), c * CFrame.new(-hl + 0.3, 3.75, s * (hw - 0.75)), WHITE, nil, true)
		part(m, "EndWall", Vector3.new(0.6, 7.5, 1.5), c * CFrame.new(hl - 0.3, 3.75, s * (hw - 0.75)), WHITE, nil, true)
		-- pared de la puerta (+X): hueco de 4 x 6,2 en el centro
		part(m, "DoorWall", Vector3.new(0.6, 9, 2.5), c * CFrame.new(hl - 0.3, 4.5, s * 3.25), WHITE, nil, true)
	end
	part(m, "DoorWall", Vector3.new(0.6, 2.8, 4), c * CFrame.new(hl - 0.3, 7.6, 0), WHITE, nil, true)

	-- módulo de la puerta (marco gris que sobresale, borde oscuro y puerta de vidrio corrida a un lado)
	local GRAY = Color3.fromRGB(214, 216, 222)
	for _, s in { -1, 1 } do
		part(m, "DoorModule", Vector3.new(1.8, 7.4, 1.1), c * CFrame.new(hl + 0.9, 3.7, s * 2.55), GRAY, nil, true)
		part(m, "DoorTrim", Vector3.new(1.9, 6.4, 0.2), c * CFrame.new(hl + 0.9, 3.2, s * 2.0), DARK, nil, false)
	end
	part(m, "DoorModule", Vector3.new(1.8, 1.2, 6.2), c * CFrame.new(hl + 0.9, 7.0, 0), GRAY, nil, true)
	part(m, "DoorTrim", Vector3.new(1.9, 0.2, 4.2), c * CFrame.new(hl + 0.9, 6.4, 0), DARK, nil, false)
	part(m, "GlassDoor", Vector3.new(0.15, 6, 3.6), c * CFrame.new(hl + 1.85, 3.1, 4.6), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, false, { Transparency = 0.35 })
	part(m, "DoorLight", Vector3.new(0.2, 0.3, 3.6), c * CFrame.new(hl + 1.85, 6.6, 0), Color3.fromRGB(255, 160, 60), Enum.Material.Neon, false)
	part(m, "Step", Vector3.new(2.6, 0.3, 5), c * CFrame.new(hl + 3, 0.15, 0), METAL, Enum.Material.DiamondPlate, true)

	-- franjas rojas que rodean el módulo
	for _, x in { -hl + 3.6, hl - 3.6 } do
		for _, s in { -1, 1 } do
			part(m, "RedBand", Vector3.new(1.5, 7.6, 0.15), c * CFrame.new(x, 3.8, s * (hw + 0.05)), RED, nil, false)
			part(m, "RedBand", Vector3.new(1.5, 3.2, 3.2), c * CFrame.new(x, 7.5, s * (hw - 1.5)), RED, nil, false, { Shape = Enum.PartType.Cylinder })
		end
		part(m, "RedBand", Vector3.new(1.5, 0.15, BW - 2.9), c * CFrame.new(x, 9.05, 0), RED, nil, false)
	end
	-- ventanas azules con marco oscuro y rejillas
	for _, s in { -1, 1 } do
		for _, x in { -hl + 1.6, 0, hl - 1.6 } do
			part(m, "WindowFrame", Vector3.new(2.3, 2.3, 0.15), c * CFrame.new(x, 4.6, s * (hw + 0.08)), DARK, nil, false)
			part(m, "Window", Vector3.new(1.9, 1.9, 0.2), c * CFrame.new(x, 4.6, s * (hw + 0.1)), Color3.fromRGB(40, 140, 230), Enum.Material.Glass, false, { Reflectance = 0.2 })
		end
		part(m, "Vent", Vector3.new(0.9, 0.6, 0.12), c * CFrame.new(-1.8, 1.5, s * (hw + 0.08)), DARK, nil, false)
		part(m, "Vent", Vector3.new(0.9, 0.6, 0.12), c * CFrame.new(hl - 1.6, 1.5, s * (hw + 0.08)), DARK, nil, false)
	end
	-- escotilla con rejilla y antenas en el techo
	part(m, "Hatch", Vector3.new(3.4, 0.35, 2.2), c * CFrame.new(0, 9.15, 0), GRAY, nil, false)
	for i = -2, 2 do
		part(m, "Grill", Vector3.new(0.12, 0.1, 1.6), c * CFrame.new(i * 0.55, 9.37, 0), DARK, nil, false)
	end
	part(m, "Antenna", Vector3.new(0.15, 1.8, 0.15), c * CFrame.new(-1.9, 10.2, 0), DARK, nil, false)
	part(m, "Antenna", Vector3.new(0.15, 1.4, 0.15), c * CFrame.new(1.9, 10, 0), DARK, nil, false)
	part(m, "AntennaTip", Vector3.new(0.35, 0.35, 0.35), c * CFrame.new(-1.9, 11.15, 0), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, false, { Shape = Enum.PartType.Ball })
	part(m, "AntennaTip", Vector3.new(0.3, 0.3, 0.3), c * CFrame.new(1.9, 10.75, 0), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, false, { Shape = Enum.PartType.Ball })

	-- montículo de regolito alrededor (medio enterrado), sin tapar la puerta
	local ground = site:FindFirstChild("Ground") :: BasePart?
	local soil = ground and ground.Color or Color3.fromRGB(200, 198, 220)
	local rng = Random.new(4)
	for i = 0, 17 do
		local a = math.rad(i * 20)
		local x, z = math.cos(a) * (hl + 1.5), math.sin(a) * (hw + 1.5)
		if not (x > hl - 1 and math.abs(z) < 5) then
			local s = rng:NextNumber(6, 9)
			part(m, "Regolith", Vector3.new(s, s * 0.5, s), c * CFrame.new(x, -0.3, z), soil, Enum.Material.Sand, false, { Shape = Enum.PartType.Ball })
		end
	end
	-- adentro: luz, tanques al fondo, banca y consola
	local lamp = part(m, "Lamp", Vector3.new(6, 0.15, 2), c * CFrame.new(0, 8.32, 0), Color3.fromRGB(255, 250, 236), Enum.Material.Neon, false)
	local pl = Instance.new("PointLight")
	pl.Range = 20
	pl.Brightness = 1.6
	pl.Color = Color3.fromRGB(255, 244, 226)
	pl.Parent = lamp
	tank(m, "O2", c * CFrame.new(-hl + 2.2, 0.5, -2.6))
	tank(m, "Water", c * CFrame.new(-hl + 2.2, 0.5, 2.6))
	part(m, "Bench", Vector3.new(5, 1.2, 1.6), c * CFrame.new(1.5, 1.1, -hw + 1.6), Color3.fromRGB(90, 110, 160), nil, true)
	part(m, "Console", Vector3.new(4, 2.6, 1.2), c * CFrame.new(1.5, 1.8, hw - 1.4), Color3.fromRGB(70, 78, 96), nil, true)
	part(m, "ConsoleGlow", Vector3.new(3.4, 1, 0.1), c * CFrame.new(1.5, 2.6, hw - 2.05), Color3.fromRGB(70, 190, 255), Enum.Material.Neon, false)
	-- detalles acogedores (15-nov)
	local inner = hw - 0.62
	earthWindow(m, c * CFrame.new(6.2, 4.6, inner), 2.4, 2.2)
	shelf(m, c * CFrame.new(-3.2, 0.5, -inner + 0.55), 2.6)
	lightPanel(m, c * CFrame.new(6, 4, -inner) * CFrame.Angles(0, math.pi, 0))
	cable(m, (c * CFrame.new(-hl + 0.7, 7.1, -inner + 0.2)).Position, (c * CFrame.new(hl - 0.7, 7.1, -inner + 0.2)).Position, Color3.fromRGB(240, 150, 50))
	cable(m, (c * CFrame.new(-hl + 0.7, 6.9, -inner + 0.2)).Position, (c * CFrame.new(hl - 0.7, 6.9, -inner + 0.2)).Position, Color3.fromRGB(90, 130, 210))
	for _, z in { -2.6, 2.6 } do
		cable(m, (c * CFrame.new(-hl + 0.9, 7.1, z)).Position, (c * CFrame.new(-hl + 0.9, 3, z)).Position, DARK)
		cable(m, (c * CFrame.new(-hl + 0.9, 3, z)).Position, (c * CFrame.new(-hl + 1.7, 3, z)).Position, DARK)
	end
	for _, w in m:GetChildren() do
		if w.Name == "Window" then
			w:SetAttribute("NightWindow", true) -- MoonAmbient las ilumina de noche
		end
	end
	-- cartel arriba
	local sign = part(m, "SignAnchor", Vector3.new(0.2, 0.2, 0.2), c * CFrame.new(hl + 1, 9.5, 0), WHITE, nil, false, { Transparency = 1 })
	billboard(sign, T.TempBaseSign, SKY, Vector3.new(0, 1.5, 0), 220)

	m.Parent = parent
end

---------------------------------------------------------------------
-- 3. Qué se ve en cada fase
---------------------------------------------------------------------
local ramp = lander:FindFirstChild("Ramp") :: BasePart?
local rampT = ramp and ramp.Transparency or 0

local function chosen(): Model?
	return site:FindFirstChild("ChosenLander") :: Model?
end

local function update()
	local phase = GS:GetAttribute("Phase") or ""
	local ship = chosen()

	-- Fase 1: cuarto dentro de la nave
	if ROOM_PHASES[phase] then
		if ship and not ship:FindFirstChild("ShipRoom") then
			buildRoom(ship)
		end
	elseif ship then
		local r = ship:FindFirstChild("ShipRoom")
		if r then
			r:Destroy()
			shipCollisions(ship, nil, nil)
		end
	end

	-- Fase 2 en adelante: la nave se aleja y aparece la base provisional
	if BASE_PHASES[phase] then
		if ship and not ship:GetAttribute("LR_Moved") then
			ship:SetAttribute("LR_Moved", true)
			local off = P1.ShipFarOffset
			for _, d in ship:GetDescendants() do
				if d:IsA("BasePart") and not d:FindFirstAncestor("TempBase") then
					d.CFrame += off
				end
			end
			shipCollisions(ship, nil, nil)
		end
		local holder = ship or lander
		if not holder:FindFirstChild("TempBase") then
			buildBase(holder)
		end
		if ramp then
			ramp.Transparency = 1
			ramp.CanCollide = false
		end
	else
		local b = lander:FindFirstChild("TempBase")
		if b then
			b:Destroy()
		end
		if ramp then
			ramp.Transparency = rampT
			ramp.CanCollide = true
		end
	end

	cleanPrompts()
	local on = ACTIVE_PHASES[phase] == true
	for _, pr in prompts do
		pr.Enabled = on
	end
end

-- La nave elegida aparece (MoonExtras): se agranda una vez y se arma lo que toque
local function onShip(ship: Instance)
	if ship.Name ~= "ChosenLander" or not ship:IsA("Model") then
		return
	end
	task.defer(function()
		if not ship.Parent or ship:GetAttribute("LR_Big") then
			return
		end
		ship:SetAttribute("LR_Big", true)
		ship:ScaleTo(ship:GetScale() * P1.ShipScale)
		update()
	end)
end
site.ChildAdded:Connect(onShip)
local existing = chosen()
if existing then
	onShip(existing)
end
GS:GetAttributeChangedSignal("Phase"):Connect(update)
update()

---------------------------------------------------------------------
-- 4. 2.º punto de recarga: junto a la máquina de Life Support (PDF Fase 2). Aparece cuando Life Support
-- termina su misión (GameState.MissionComplete_life = true) y sirve en la Fase 2 y la Fase 3.
-- Llena las dos barras (doRefill). Se quita al empezar una partida nueva.
---------------------------------------------------------------------
-- Molde del tanque azul (no está en el mundo; solo se clona)
local station = Instance.new("Part")
station.Name = "LanderRefill"
station.Shape = Enum.PartType.Cylinder
station.Size = Vector3.new(3, 2.2, 2.2)
station.Anchored = true
station.Material = Enum.Material.Neon
station.Color = SKY
local stLight = Instance.new("PointLight")
stLight.Color = SKY
stLight.Range = 12
stLight.Brightness = 2
stLight.Parent = station
billboard(station, T.ShipRefillSign, SKY, Vector3.new(0, 3, 0), 150)
local stPrompt = Instance.new("ProximityPrompt")
stPrompt.Name = "SO_ShipRefill"
stPrompt.ActionText = T.ShipRefill
stPrompt.ObjectText = T.ShipRefillObject
stPrompt.HoldDuration = P1.LanderRefillHold
stPrompt.KeyboardKeyCode = Enum.KeyCode.E
stPrompt.RequiresLineOfSight = false
stPrompt.MaxActivationDistance = Config.PromptDistance + 4
stPrompt.Parent = station

local MACHINE_PHASES = { Phase2 = true, Transition23 = true, Phase3 = true }
local machineStation: BasePart? = nil

local function removeMachineStation()
	if machineStation then
		machineStation:Destroy()
		machineStation = nil
	end
end

local function makeMachineStation()
	if machineStation and machineStation.Parent then
		return
	end
	local placed = site:FindFirstChild("Placed")
	local machine = placed and placed:FindFirstChild("life") :: Model?
	if not machine then
		return
	end
	local cf, size = machine:GetBoundingBox()
	local ground = site:FindFirstChild("Ground") :: BasePart?
	local y = ground and (ground.Position.Y + ground.Size.Y / 2) or 0
	-- Al lado de la máquina, del lado de la nave (así queda en el camino)
	local toLander = (lander:GetPivot().Position - cf.Position) * Vector3.new(1, 0, 1)
	toLander = toLander.Magnitude > 0.1 and toLander.Unit or Vector3.new(0, 0, 1)
	local pos = Vector3.new(cf.X, y, cf.Z) + toLander * (math.max(size.X, size.Z) / 2 + 4)

	local s = station:Clone()
	s.Name = "MachineRefill"
	s.CFrame = CFrame.new(pos + Vector3.new(0, s.Size.X / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	s.CanCollide = true
	local pr = s:FindFirstChild("SO_ShipRefill") :: ProximityPrompt
	pr.Name = "SO_MachineRefill"
	pr.ObjectText = T.MachineRefillObject
	pr.Enabled = true
	pr.Triggered:Connect(doRefill)
	s.Parent = machine
	machineStation = s
	Remotes.Toast:FireAllClients(T.MachineRefillReady, 4)
end

local function checkMachine()
	local phase = GS:GetAttribute("Phase") or ""
	if GS:GetAttribute("MissionComplete_life") == true and MACHINE_PHASES[phase] then
		makeMachineStation()
	elseif not MACHINE_PHASES[phase] then
		removeMachineStation()
	end
end
GS:GetAttributeChangedSignal("MissionComplete_life"):Connect(checkMachine)
GS:GetAttributeChangedSignal("Phase"):Connect(checkMachine)
checkMachine()
