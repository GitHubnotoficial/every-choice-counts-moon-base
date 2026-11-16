-- SO_WorldLabels (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_WorldLabels
-- Dueño: Isaac + Claude. Carteles flotantes de la Luna menos intrusivos (pedido de Isaac, 15-nov).
-- Problema: los carteles usaban tamaño en píxeles (fromOffset): miden lo mismo en pantalla a cualquier
-- distancia, así que de lejos se ven enormes sobre la base y de cerca se ven chicos para lo que rotulan.
-- Solución (como en los juegos buenos de Roblox), sin tocar los scripts que crean los carteles:
--   1) Rótulos de información (no AlwaysOnTop): pasan a tamaño en studs, como un letrero real (se achican con
--      la distancia), y solo se ven de cerca: visibles hasta Near, se desvanecen hasta Far, ocultos más lejos.
--   2) Marcadores de navegación (AlwaysOnTop: puntos de colocación, objeto dañado): siguen viéndose de lejos,
--      pero se encogen y se vuelven más transparentes con la distancia; a tamaño completo solo de cerca.
--   3) Estilo: fondo semitransparente y borde fino en el texto para que se lea sin tapar.
-- Actúa sobre todos los carteles con texto del Workspace (Luna, Tierra y etiquetas de rol sobre los jugadores),
-- menos los del cielo (dentro de la cámara) y efectos. Solo en este cliente. Números en Config.WorldLabels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local L = Config.WorldLabels

local camera = workspace.CurrentCamera

type Info = { gui: BillboardGui, nav: boolean, size: UDim2, texts: { TextLabel }, bgBase: { [GuiObject]: number }, txtBase: { [TextLabel]: number } }
local labels: { [BillboardGui]: Info } = {}

local IGNORE = { SO_StompStars = true } -- efectos que no son carteles

local function setup(b: BillboardGui)
	if labels[b] or IGNORE[b.Name] or not b:IsDescendantOf(workspace) then return end
	if b:IsDescendantOf(workspace.CurrentCamera) then return end -- cielo (estrellas, nubes, halos)
	local first = b:FindFirstChildWhichIsA("TextLabel", true)
	if not first then return end
	local info: Info = { gui = b, nav = b.AlwaysOnTop, size = b.Size, texts = {}, bgBase = {}, txtBase = {} }
	-- Tamaño original en píxeles → en studs (solo los rótulos de información)
	if not info.nav and b.Size.X.Scale == 0 then
		b.Size = UDim2.fromScale(b.Size.X.Offset / L.PixelsPerStud, b.Size.Y.Offset / L.PixelsPerStud)
	end
	-- Nunca más lejos de lo que ya tenía (p. ej. la etiqueta de rol: 80)
	b.MaxDistance = math.min(b.MaxDistance, info.nav and L.NavMaxDistance or L.Far + 2)
	for _, d in b:GetDescendants() do
		if d:IsA("TextLabel") then
			table.insert(info.texts, d)
			d.TextScaled = true
			info.txtBase[d] = d.TextTransparency
			-- Borde fino al texto (si no tiene ninguno, ni el borde clásico TextStroke)
			if not d:FindFirstChildOfClass("UIStroke") and d.TextStrokeTransparency >= 1 then
				local s = Instance.new("UIStroke")
				s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
				s.Thickness = 1.2
				s.Transparency = 0.35
				local light = d.TextColor3.R + d.TextColor3.G + d.TextColor3.B > 1.5
				s.Color = light and Color3.fromHex("10142A") or Color3.fromHex("FFFFFF")
				s.Parent = d
			end
		end
		if d:IsA("GuiObject") then
			-- Fondo un poco transparente: se ve el mundo detrás
			if d.BackgroundTransparency < L.MinBackground then d.BackgroundTransparency = L.MinBackground end
			info.bgBase[d] = d.BackgroundTransparency
		end
	end
	labels[b] = info
	b.Destroying:Connect(function() labels[b] = nil end)
end

local function scan(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("BillboardGui") then task.defer(setup, d) end
	end
end
scan(workspace)
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BillboardGui") then task.defer(setup, d) end -- defer: que termine de armarlo quien lo crea
end)

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- Cada cuadro: desvanecido y tamaño según la distancia a la cámara
RunService.RenderStepped:Connect(function()
	camera = workspace.CurrentCamera
	local cam = camera.CFrame.Position
	for b, info in labels do
		local adornee = b.Adornee or b.Parent
		local pos = adornee and adornee:IsA("BasePart") and adornee.Position
			or adornee and adornee:IsA("Attachment") and adornee.WorldPosition
			or adornee and adornee:IsA("Model") and adornee:GetPivot().Position
		if not pos then continue end
		local d = (pos - cam).Magnitude
		local fade: number -- 0 = se ve normal, 1 = invisible
		if info.nav then
			-- Navegación: tamaño completo de cerca, se encoge hasta NavMinScale de lejos y se aclara un poco
			local k = (d - L.NavNear) / (L.NavFar - L.NavNear)
			local s = lerp(1, L.NavMinScale, k)
			b.Size = UDim2.new(info.size.X.Scale, info.size.X.Offset * s, info.size.Y.Scale, info.size.Y.Offset * s)
			fade = lerp(0, L.NavFarFade, k)
		else
			fade = (d - L.Near) / (L.Far - L.Near)
		end
		fade = math.clamp(fade, 0, 1)
		for gObj, base in info.bgBase do gObj.BackgroundTransparency = lerp(base, 1, fade) end
		for t, base in info.txtBase do
			t.TextTransparency = lerp(base, 1, fade)
			local s = t:FindFirstChildOfClass("UIStroke")
			if s then s.Transparency = lerp(0.35, 1, fade) end
		end
	end
end)
