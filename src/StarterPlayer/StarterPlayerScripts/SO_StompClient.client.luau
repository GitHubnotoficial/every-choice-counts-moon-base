-- SO_StompClient (LocalScript) -> StarterPlayer.StarterPlayerScripts.SO_StompClient
-- Dueño: Isaac + Claude. Rebote del que aplasta a otro (lo avisa SO_Stomp por SO_StompBounce).
-- El personaje lo mueve el cliente, por eso el impulso se aplica aquí.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SO_StompBounce")

event.OnClientEvent:Connect(function(speed: number)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or root.Anchored then return end
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X, speed, v.Z)
end)
