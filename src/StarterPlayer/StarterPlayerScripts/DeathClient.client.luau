-- DeathClient (LocalScript) -> StarterPlayer.StarterPlayerScripts.DeathClient
-- Mientras el jugador está muerto (atributo Dead, lo pone Bars):
--   - no ve los avisos de "mantener E" (no puede usarlos igual), y
--   - no puede reiniciarse con Esc -> Reset (así no reaparece como fantasma).
-- Cuando vuelve a estar vivo (partida nueva), todo se activa otra vez.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local function setReset(allowed: boolean)
	-- SetCore puede fallar si el menú todavía no cargó: se reintenta unas veces
	for _ = 1, 10 do
		if pcall(function() StarterGui:SetCore("ResetButtonCallback", allowed) end) then
			return
		end
		task.wait(0.5)
	end
end

local function apply()
	local dead = player:GetAttribute("Dead") == true
	ProximityPromptService.Enabled = not dead
	task.spawn(setReset, not dead)
end

player:GetAttributeChangedSignal("Dead"):Connect(apply)
apply()
