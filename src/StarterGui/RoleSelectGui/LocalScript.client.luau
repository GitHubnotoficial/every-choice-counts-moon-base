-- Script para manejar las tarjetas de roles en la pantalla 2D
-- Autor: Equipo Shackleton One

local replicatedStorage = game:GetService("ReplicatedStorage")
local elegirRolEvent = replicatedStorage:WaitForChild("ElegirRolEvent")

local background = script.Parent:WaitForChild("Background")
local ultimoClic = 0
local rolSeleccionadoActual = nil

-- Recorremos las tarjetas de roles (asumiendo que se llaman CaptainCard, EngineerCard, etc.)
for _, tarjeta in ipairs(background:GetChildren()) do
	if tarjeta:IsA("Frame") and tarjeta.Name:match("Card") then
		local botonInvisible = tarjeta:FindFirstChild("TextButton") or Instance.new("TextButton", tarjeta)
		botonInvisible.Size = UDim2.new(1, 0, 1, 0)
		botonInvisible.BackgroundTransparency = 1
		botonInvisible.Text = ""

		botonInvisible.MouseButton1Click:Connect(function()
			local tiempoActual = tick()
			-- Detectar doble clic (si pasa menos de 0.4 segundos entre clic y clic)
			if tiempoActual - ultimoClic < 0.4 then
				local nombreRol = tarjeta.Name:gsub("Card", "")
				print("Doble clic detectado en el rol: " .. nombreRol)

				-- Avisar al servidor que queremos este rol
				elegirRolEvent:FireServer(nombreRol)
				rolSeleccionadoActual = nombreRol
			end
			ultimoClic = tiempoActual
		end)
	end
end