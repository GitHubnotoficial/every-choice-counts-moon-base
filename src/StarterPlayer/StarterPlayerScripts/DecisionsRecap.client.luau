-- DecisionsRecap (LocalScript) -> StarterPlayer.StarterPlayerScripts.DecisionsRecap
-- [15-nov] Pantalla final "YOUR CHOICES AND WHAT HAPPENED" (la idea de "Every Choice Counts").
-- Al llegar a End aparece abajo a la izquierda el botón "YOUR CHOICES" (no tapa el diploma ni la pantalla final).
-- Al abrirlo: una fila por rol con 3 columnas:
--   YOU CHOSE     → la opción de la Fase 0 (Choice_<rol>) y dónde se colocó (Spot_<rol>)
--   WHAT HAPPENED → calculado con lo que guardó el juego (carga, aterrizaje, energía, reservas, comida, misión)
--   IN REAL LIFE  → el dato real de esa opción (Fact + UsedIn de Config.Options)
-- Solo lee GameState. Textos en Config.Extras.Recap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local R = Config.Extras.Recap
local C = Config.Colors
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer
local INK = Color3.fromHex("1A1240")

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end
local function corner(o: Instance, r: number)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end
local function txt(parent: Instance, text: string, size: number, color: Color3, font: Enum.Font?, order: number?): TextLabel
	return new("TextLabel", { Text = text, TextSize = size, TextColor3 = color, Font = font or Enum.Font.GothamMedium, BackgroundTransparency = 1,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 0 }, parent)
end

local gui = new("ScreenGui", { Name = "SO_DecisionsRecap", ResetOnSpawn = false, DisplayOrder = 30, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

local openBtn = new("TextButton", { Text = R.Button, Font = Enum.Font.FredokaOne, TextSize = 24, TextColor3 = INK, BackgroundColor3 = C.Gold,
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -20), Size = UDim2.fromOffset(240, 56), Visible = false }, gui)
corner(openBtn, 16)
new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, openBtn)

local shade = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Visible = false, Active = true }, gui)
local panel = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1180, 660), BackgroundColor3 = Color3.fromHex("1B1446") }, shade)
corner(panel, 24)
new("UIStroke", { Color = C.Gold, Thickness = 3 }, panel)
local scale = new("UIScale", {}, panel)

local title = new("TextLabel", { Text = R.Title, Font = Enum.Font.FredokaOne, TextSize = 34, TextColor3 = C.Gold, BackgroundTransparency = 1,
	Position = UDim2.fromOffset(30, 16), Size = UDim2.fromOffset(900, 40), TextXAlignment = Enum.TextXAlignment.Left }, panel)
local sub = new("TextLabel", { Text = "", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.Text, BackgroundTransparency = 1,
	Position = UDim2.fromOffset(30, 56), Size = UDim2.fromOffset(1000, 26), TextXAlignment = Enum.TextXAlignment.Left }, panel)
local closeBtn = new("TextButton", { Text = R.Close, Font = Enum.Font.FredokaOne, TextSize = 22, TextColor3 = INK, BackgroundColor3 = C.Text,
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 18), Size = UDim2.fromOffset(120, 44) }, panel)
corner(closeBtn, 14)

-- encabezados de columnas
local COLX = { 150, 470, 820 }
local COLW = { 300, 330, 330 }
for i, h in { R.ColChose, R.ColHappened, R.ColReal } do
	new("TextLabel", { Text = h, Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = Color3.fromHex("B7A8F0"), BackgroundTransparency = 1,
		Position = UDim2.fromOffset(COLX[i], 92), Size = UDim2.fromOffset(COLW[i], 20), TextXAlignment = Enum.TextXAlignment.Left }, panel)
end
local rows = new("ScrollingFrame", { Position = UDim2.fromOffset(20, 118), Size = UDim2.new(1, -40, 1, -134), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, panel)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, rows)

local function findOption(role: string, id: string?)
	for _, o in Config.Options[role] or {} do
		if o.Id == id then
			return o
		end
	end
	return nil
end
local function findSpot(role: string, id: string?)
	for _, s in (Config.Spots and Config.Spots[role]) or {} do
		if s.Id == id then
			return s
		end
	end
	return nil
end
local function n(key: string): number
	return tonumber(GS:GetAttribute(key)) or 0
end

-- Qué pasó con cada rol (solo con datos que el juego guardó)
local function happened(role: string, opt): { string }
	local out = {}
	if role == "cap" then
		local used, cap = n("CargoUsed"), n("CargoCapacity")
		if n("PenaltyPct") > 0 then
			table.insert(out, string.format(R.CargoHeavy, used, cap, n("StartO2")))
		elseif cap > 0 then
			table.insert(out, string.format(R.CargoOk, used, cap))
		end
		if opt and (opt.LateSolPenalty or 0) > 0 then
			table.insert(out, R.Late)
		end
		if GS:GetAttribute("RoughLanding") == true then
			table.insert(out, R.Rough)
		end
		for _, s in Config.Sites do
			if s.Id == GS:GetAttribute("Site") then
				table.insert(out, string.format(R.Site, s.Name))
			end
		end
	elseif role == "eng" then
		local made, used = n("EnergyMade"), n("EnergyUsed")
		table.insert(out, string.format(R.Energy, math.floor(made + 0.5), math.floor(used + 0.5)))
		if used > made then
			table.insert(out, R.EnergyShort)
		end
	elseif role == "life" then
		table.insert(out, string.format(R.Reserve, math.floor(n("ReserveO2") + 0.5), math.floor(n("ReserveWater") + 0.5)))
	elseif role == "bot" then
		table.insert(out, string.format(R.Food, n("Harvests"), string.format("%.1f", n("Food"))))
	end
	if GS:GetAttribute("Mission_" .. role .. "_Total") ~= nil then
		table.insert(out, GS:GetAttribute("MissionComplete_" .. role) == true and R.MissionDone or R.MissionNot)
	end
	return out
end

local function build()
	for _, c in rows:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local won = GS:GetAttribute("Result") == "won"
	sub.Text = (won and R.Won or R.Lost) .. "   •   " .. string.format(R.Emergencies, n("EmergenciesSolved"), n("EmergenciesSeen"))
	sub.TextColor3 = won and C.Good or C.Bad
	for i, role in Config.RoleOrder do
		local info = Config.Roles[role]
		local opt = findOption(role, GS:GetAttribute("Choice_" .. role))
		local spot = findSpot(role, GS:GetAttribute("Spot_" .. role))
		local row = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromHex("2A1C6E") }, rows)
		corner(row, 16)
		new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14) }, row)
		-- nombre del rol
		local tag = new("TextLabel", { Text = info.Name, Font = Enum.Font.FredokaOne, TextSize = 18, TextColor3 = INK, BackgroundColor3 = info.Color, TextWrapped = true,
			Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(110, 48) }, row)
		corner(tag, 12)
		-- 3 columnas
		local cols = {}
		for c = 1, 3 do
			local col = new("Frame", { Position = UDim2.fromOffset(COLX[c] - 20, 0), Size = UDim2.fromOffset(COLW[c], 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, row)
			new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, col)
			cols[c] = col
		end
		txt(cols[1], opt and opt.Name or R.NoChoice, 20, C.Gold, Enum.Font.FredokaOne, 1)
		if spot then
			txt(cols[1], string.format(R.PlacedAt, spot.Name), 15, C.Text, Enum.Font.GothamBold, 2)
			if spot.Pro then txt(cols[1], "✅ " .. spot.Pro, 14, C.Good, nil, 3) end
			if spot.Con then txt(cols[1], "❌ " .. spot.Con, 14, C.Bad, nil, 4) end
		end
		for k, line in happened(role, opt) do
			txt(cols[2], line, 15, C.Text, nil, k)
		end
		if opt and opt.Fact then
			txt(cols[3], opt.Fact, 15, C.Text, nil, 1)
			if opt.UsedIn then
				txt(cols[3], opt.UsedIn, 13, C.Sky, Enum.Font.GothamBold, 2)
			end
		end
	end
end

local function open(on: boolean)
	shade.Visible = on
	if on then
		build()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local fit = math.min(1, (vp.Y - 40) / 660, (vp.X - 40) / 1180)
		scale.Scale = fit * 0.85
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = fit }):Play()
	end
end
openBtn.MouseButton1Click:Connect(function() open(true) end)
closeBtn.MouseButton1Click:Connect(function() open(false) end)

local function onPhase()
	local p = GS:GetAttribute("Phase") or ""
	openBtn.Visible = (p == "End")
	if p ~= "End" then
		open(false)
	end
end
GS:GetAttributeChangedSignal("Phase"):Connect(onPhase)
onPhase()
