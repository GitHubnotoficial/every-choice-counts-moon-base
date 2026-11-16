-- PhaseFlyover (LocalScript) -> StarterPlayer.StarterPlayerScripts.PhaseFlyover
-- [15-nov] Al empezar la Fase 0, la Fase 2 y la Fase 3: vuelo corto de cámara (Config.Extras.FlyoverSeconds)
-- que da media vuelta alto sobre el lugar y baja hasta detrás del jugador. Un clic o una tecla lo salta.
-- No corre si otra animación tiene la cámara (SO_Cinematic o cámara que no es Custom) ni si el jugador murió.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local X = Config.Extras
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local PHASES = { Phase0 = true, Phase2 = true, Phase3 = true }
local running = false
local skip = false

UserInputService.InputBegan:Connect(function(input)
	if running and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Keyboard
		or input.UserInputType == Enum.UserInputType.Touch) then
		skip = true
	end
end)

local function focusPoint(phase: string): Vector3?
	if phase == "Phase0" then
		local eb = workspace:FindFirstChild("EarthBase")
		return eb and (eb :: Model):GetBoundingBox().Position
	end
	local site = workspace:FindFirstChild("MoonSite")
	local ship = site and (site:FindFirstChild("TempBase", true) or site:FindFirstChild("ChosenLander") or site:FindFirstChild("Lander"))
	if ship and ship:IsA("Model") then
		return ship:GetBoundingBox().Position
	end
	return nil
end

local function ease(a: number): number
	return a < 0.5 and 4 * a * a * a or 1 - (-2 * a + 2) ^ 3 / 2
end

local function fly(phase: string)
	if running then
		return
	end
	-- esperar a que terminen otras animaciones (despegue, transiciones)
	local waited = 0
	while player:GetAttribute("SO_Cinematic") == true and waited < 15 do
		waited += task.wait(0.2)
	end
	task.wait(0.4)
	if GS:GetAttribute("Phase") ~= phase or player:GetAttribute("Dead") then
		return
	end
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local focus = focusPoint(phase)
	if not cam or not root or not hum or not focus or cam.CameraType ~= Enum.CameraType.Custom then
		return
	end
	-- el jugador tiene que estar cerca del lugar (si no, no tiene sentido)
	if (root.Position - focus).Magnitude > 400 then
		return
	end
	running = true
	skip = false
	local T = X.FlyoverSeconds
	local start = math.atan2(root.Position.Z - focus.Z, root.Position.X - focus.X) + math.pi
	cam.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	while true do
		local a = math.clamp((os.clock() - t0) / T, 0, 1)
		if skip or a >= 1 or not root.Parent then
			break
		end
		local e = ease(a)
		-- media vuelta alta alrededor del lugar...
		local ang = start + e * math.pi
		local radius = 95 - 40 * e
		local orbit = focus + Vector3.new(math.cos(ang) * radius, 60 - 35 * e, math.sin(ang) * radius)
		local orbitCF = CFrame.lookAt(orbit, focus)
		-- ...y al final baja hasta detrás del jugador
		local behind = CFrame.lookAt((root.CFrame * CFrame.new(0, 5, 14)).Position, root.Position + Vector3.new(0, 2, 0))
		local k = math.clamp((a - 0.6) / 0.4, 0, 1)
		cam.CFrame = orbitCF:Lerp(behind, ease(k))
		RunService.RenderStepped:Wait()
	end
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum
	running = false
end

GS:GetAttributeChangedSignal("Phase"):Connect(function()
	local p = GS:GetAttribute("Phase") or ""
	if PHASES[p] then
		task.spawn(fly, p)
	end
end)
