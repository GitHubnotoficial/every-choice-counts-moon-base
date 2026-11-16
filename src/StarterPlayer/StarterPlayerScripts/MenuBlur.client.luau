-- MenuBlur (LocalScript) -> StarterPlayer.StarterPlayerScripts.MenuBlur
-- [15-nov] Efecto "cine": cuando hay una pantalla de menú encima (título, roles, briefing, elegir sitio,
-- intro de la Fase 2, final), el mundo de atrás se desenfoca suave; al jugar vuelve a verse nítido.
-- También se desenfoca mientras el menú de opciones (SettingsMenu) está abierto.
-- Usa su propio BlurEffect dentro de la cámara: no toca Lighting.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local MENU = { Title = true, RoleSelect = true, Briefing = true, SiteSelect = true, Phase2Intro = true, End = true, Failed = true }

local blur = Instance.new("BlurEffect")
blur.Name = "SO_MenuBlur"
blur.Size = 0
local function placeBlur()
	local cam = workspace.CurrentCamera
	if cam and blur.Parent ~= cam then
		blur.Parent = cam
	end
end
placeBlur()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(placeBlur)

local settingsOpen = false
local function update()
	local on = MENU[GS:GetAttribute("Phase") or ""] or settingsOpen
	TweenService:Create(blur, TweenInfo.new(0.5), { Size = on and Config.Extras.MenuBlur or 0 }):Play()
end
GS:GetAttributeChangedSignal("Phase"):Connect(update)
update()

-- Menú de opciones abierto = desenfoque
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local sg = pg:WaitForChild("SO_SettingsMenu", 30)
	if not sg then
		return
	end
	for _, c in sg:GetChildren() do
		if c:IsA("TextButton") and c.Text == "" then -- el fondo oscuro del menú
			c:GetPropertyChangedSignal("Visible"):Connect(function()
				settingsOpen = c.Visible
				update()
			end)
		end
	end
end)
