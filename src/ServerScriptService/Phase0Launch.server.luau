-- Phase0Launch (Script) -> ServerScriptService.Phase0Launch
-- Lanzamiento de la Fase 0 (PDF Fase 0, cap. 10.1). Se despega SOLO con el botón rojo de la consola de la sala de
-- control, frente a la ventana que da a la nave (EarthBase.ControlRoom.ConsoleButton):
--   - Mantener E en la consola (aviso de Tables, de Isaac) o hacer clic en el botón rojo.
--   - Solo el Captain (o quien tenga ese rol), solo en la fase "Launch". Escribe GameState.Launched = true.
-- Durante "Launch" el botón se enciende, parpadea y tiene un cartel que se ve desde todo el edificio.
-- El Remote "Launch" se sigue aceptando, pero solo si el Captain está junto a la consola.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local P1 = require(ReplicatedStorage:WaitForChild("Phase1Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local T = P1.Text2

local base = workspace:WaitForChild("EarthBase")
local room = base:WaitForChild("ControlRoom")
local button = room:WaitForChild("ConsoleButton") :: BasePart
local console = room:WaitForChild("LaunchConsole") :: BasePart

local MAX_DIST = 12 -- el Captain tiene que estar junto a la consola

local function isCaptain(player: Player): boolean
	return table.find(string.split(player:GetAttribute("Roles") or "", ","), "cap") ~= nil
end

local function nearConsole(player: Player): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - console.Position).Magnitude <= MAX_DIST
end

local function tryLaunch(player: Player)
	if GS:GetAttribute("Phase") ~= "Launch" or GS:GetAttribute("Launched") then
		return
	end
	if not isCaptain(player) then
		Remotes.Toast:FireClient(player, T.OnlyCaptain, 2.5)
		return
	end
	if not nearConsole(player) then
		return
	end
	GS:SetAttribute("Launched", true)
end

-- Hacer clic en el botón rojo
local click = Instance.new("ClickDetector")
click.Name = "SO_LaunchClick"
click.MaxActivationDistance = MAX_DIST
click.Parent = button
click.MouseClick:Connect(tryLaunch)

-- Remote (por si otra pantalla lo usa): también pide estar junto a la consola
Remotes:WaitForChild("Launch").OnServerEvent:Connect(tryLaunch)

---------------------------------------------------------------------
-- El botón se enciende y parpadea durante "Launch"
---------------------------------------------------------------------
local glow = Instance.new("Part")
glow.Name = "SO_LaunchGlow"
glow.Shape = Enum.PartType.Cylinder
glow.Size = Vector3.new(0.25, 2.2, 2.2)
glow.CFrame = CFrame.new(button.Position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
glow.Anchored = true
glow.CanCollide = false
glow.CanQuery = false
glow.Material = Enum.Material.Neon
glow.Color = Config.Colors.Red
glow.Transparency = 1
glow.Parent = room

local light = Instance.new("PointLight")
light.Color = Config.Colors.Red
light.Range = 14
light.Brightness = 0
light.Parent = glow

-- Cartel que se ve a través de las paredes para encontrar el botón
local sign = Instance.new("BillboardGui")
sign.Name = "SO_LaunchSign"
sign.Size = UDim2.fromOffset(220, 70)
sign.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
sign.AlwaysOnTop = true
sign.MaxDistance = 200
sign.Enabled = false
sign.Parent = button
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Config.Colors.Red
label.TextColor3 = Config.Colors.Text
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.Text = T.LaunchSign
label.Parent = sign
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = label
local stroke = Instance.new("UIStroke")
stroke.Color = Config.Colors.Text
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = label

local pulse: Tween? = nil
local function apply()
	local on = GS:GetAttribute("Phase") == "Launch" and GS:GetAttribute("Launched") ~= true
	click.MaxActivationDistance = on and MAX_DIST or 0
	sign.Enabled = on
	if pulse then
		pulse:Cancel()
		pulse = nil
	end
	if on then
		glow.Transparency = 0
		light.Brightness = 3
		pulse = TweenService:Create(glow, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.7 })
		pulse:Play()
	else
		glow.Transparency = 1
		light.Brightness = 0
	end
end
GS:GetAttributeChangedSignal("Phase"):Connect(apply)
GS:GetAttributeChangedSignal("Launched"):Connect(apply)
apply()
