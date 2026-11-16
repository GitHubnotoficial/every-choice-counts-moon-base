-- DeathGuard (Script) -> ServerScriptService.DeathGuard
-- Arreglos de las muertes (no cambia Bars, de Isaac, que es quien mata al jugador con el atributo Dead):
-- 1. Si un jugador muerto se reinicia (Esc -> Reset) o reaparece, vuelve a quedar como espectador:
--    invisible, sin chocar y quieto. Antes reaparecía visible y podía caminar como "fantasma".
-- 2. La etiqueta con el nombre/rol sobre la cabeza se esconde al morir (antes quedaba flotando).
-- 3. Se borra el aviso de "sin agua" (NoWaterLeft) al morir.
-- Cuando empieza una partida nueva, GameManager pone Dead = false y DayCycle hace LoadCharacter: todo vuelve a la normalidad.

local Players = game:GetService("Players")

local function spectator(char: Model)
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CanCollide = false
		elseif d:IsA("Decal") then
			d.Transparency = 1
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			d.Enabled = false
		end
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = true
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		hum.JumpHeight = 0
		hum.JumpPower = 0
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function onPlayer(p: Player)
	p:GetAttributeChangedSignal("Dead"):Connect(function()
		if p:GetAttribute("Dead") then
			p:SetAttribute("NoWaterLeft", nil)
			if p.Character then
				spectator(p.Character)
			end
		end
	end)
	p.CharacterAdded:Connect(function(char)
		if not p:GetAttribute("Dead") then
			return
		end
		char:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.2) -- deja que otros scripts lo coloquen primero
		if p:GetAttribute("Dead") and char.Parent then
			spectator(char)
			-- lo que se cargue después (accesorios, etiqueta) también se esconde
			char.DescendantAdded:Connect(function()
				if p:GetAttribute("Dead") then
					task.defer(spectator, char)
				end
			end)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	onPlayer(p)
end
