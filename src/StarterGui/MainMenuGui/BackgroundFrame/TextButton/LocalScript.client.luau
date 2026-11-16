local botonPlay = script.Parent
local menuGui = botonPlay:FindFirstAncestorOfClass("ScreenGui")

botonPlay.MouseButton1Click:Connect(function()
	print("¡Botón PLAY presionado!")

	-- Oculta la pantalla de título
	if menuGui then
		menuGui.Enabled = false
	end

	-- Si ya crearon la pantalla de elección de roles, la muestra
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local pantallaRoles = playerGui:FindFirstChild("RoleSelectGui")

	if pantallaRoles then
		pantallaRoles.Enabled = true
	end
end)
