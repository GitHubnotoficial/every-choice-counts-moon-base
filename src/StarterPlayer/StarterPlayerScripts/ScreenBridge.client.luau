-- ScreenBridge (LocalScript) -> StarterPlayer.StarterPlayerScripts.ScreenBridge
-- Dueño: Isaac + Claude. Hace convivir las pantallas de Celeste (StarterGui.MainMenuGui y RoleSelectGui)
-- con SO_MenuScreens SIN tocar los scripts de Celeste:
-- - Si la pantalla de Celeste de esa fase está activa, se oculta SO_MenuScreens (no se ven dos a la vez).
-- - Cuando Celeste esconde su título (su botón PLAY), avisamos al servidor con Remotes.PlayPressed.
-- - Fuera de su fase, sus pantallas se apagan en este cliente (no en StarterGui).
-- Sus tarjetas de rol usan ReplicatedStorage.ElegirRolEvent, que traduce RolesAndSuits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GS = ReplicatedStorage:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local wasTitleOn = false

while true do
	task.wait(0.2)
	local phase = GS:GetAttribute("Phase") or ""
	local title = playerGui:FindFirstChild("MainMenuGui") :: ScreenGui?
	local roles = playerGui:FindFirstChild("RoleSelectGui") :: ScreenGui?
	local menus = playerGui:FindFirstChild("SO_MenuScreens") :: ScreenGui?

	-- PLAY de Celeste: su título pasó de visible a oculto durante la fase Title
	local titleOn = title ~= nil and title.Enabled
	if phase == "Title" and wasTitleOn and not titleOn then
		Remotes.PlayPressed:FireServer()
	end
	wasTitleOn = titleOn

	-- Apagar sus pantallas fuera de su fase (solo en este cliente)
	if roles and roles.Enabled and phase ~= "RoleSelect" and phase ~= "Title" then
		roles.Enabled = false
	end
	if title and title.Enabled and phase ~= "Title" and phase ~= "" then
		title.Enabled = false
	end

	-- Si la de Celeste está activa en su fase, no mostrar la otra
	local celesteOn = (phase == "Title" and titleOn) or (phase == "RoleSelect" and roles ~= nil and roles.Enabled)
	if menus then
		menus.Enabled = not celesteOn
	end
end
