-- SoundManager (LocalScript) -> StarterPlayer.StarterPlayerScripts.SoundManager
-- Toda la música y los efectos de sonido del juego, en este cliente. Los números están en ReplicatedStorage.SoundConfig.
-- Música: una en la Tierra (menús, edificio, despegue) y otra en la Luna; cambian con un fundido suave.
-- Efectos: clic en cualquier botón de pantalla, pitido al terminar un "mantener E" y al empezar cada día,
-- alarma al empezar una emergencia (PDF Fase 3), despegue y motores (con LaunchCinematic), aterrizaje,
-- fanfarria al ganar y sonido triste al perder o al morir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local S = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "SO_Sounds"
folder.Parent = SoundService

-- [15-nov] Dos grupos para el menú de opciones (SettingsMenu): música y efectos.
-- El volumen elegido llega como atributo del jugador (Opt_Music / Opt_SFX, de 0 a 1).
local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "SO_MusicGroup"
musicGroup.Parent = SoundService
local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "SO_SFXGroup"
sfxGroup.Parent = SoundService
local function applyVolumes()
	musicGroup.Volume = player:GetAttribute("Opt_Music") or 1
	sfxGroup.Volume = player:GetAttribute("Opt_SFX") or 1
end
player:GetAttributeChangedSignal("Opt_Music"):Connect(applyVolumes)
player:GetAttributeChangedSignal("Opt_SFX"):Connect(applyVolumes)
applyVolumes()

local function make(name: string, looped: boolean?): Sound
	local info = S[name]
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. info.Id
	s.Volume = info.Volume
	s.Looped = looped == true
	s.SoundGroup = (name == "EarthMusic" or name == "MoonMusic") and musicGroup or sfxGroup
	s.Parent = folder
	return s
end

local earthMusic = make("EarthMusic", true)
local moonMusic = make("MoonMusic", true)
local click = make("Click")
local beep = make("Beep")
local alarm = make("Alarm", true)
local launch = make("Launch")
local rumble = make("Rumble")
local victory = make("Victory")
local fail = make("Fail")

local function oneShot(s: Sound)
	s.TimePosition = 0
	s:Play()
end

---------------------------------------------------------------------
-- Música según la fase (fundido de 1,5 s)
---------------------------------------------------------------------
local MOON = { Landing = true, Placement = true, Transition12 = true, Phase2Intro = true, Phase2 = true,
	Transition23 = true, Phase3 = true, Rescue = true }
local current: Sound? = nil
local function fadeTo(target: Sound?)
	if current == target then return end
	local old = current
	current = target
	if old then
		local t = TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 })
		t:Play()
		t.Completed:Once(function()
			if current ~= old then old:Pause() end
		end)
	end
	if target then
		local full = S[target.Name].Volume
		target.Volume = 0
		if not target.IsPlaying then target:Play() end
		TweenService:Create(target, TweenInfo.new(1.5), { Volume = full }):Play()
	end
end

local lastPhase = ""
local function onPhase()
	local p = GS:GetAttribute("Phase") or ""
	if p == "End" then
		fadeTo(nil)
		if GS:GetAttribute("Result") == "won" then oneShot(victory) else oneShot(fail) end
	elseif p == "Failed" then
		fadeTo(nil)
		oneShot(fail)
	elseif MOON[p] then
		fadeTo(moonMusic)
	else
		fadeTo(earthMusic)
	end
	if p == "Landing" and lastPhase ~= "Landing" then
		-- motores del aterrizaje (la animación dura ~6 s)
		rumble.Volume = S.Rumble.Volume
		oneShot(rumble)
		task.delay(5.2, function()
			TweenService:Create(rumble, TweenInfo.new(0.8), { Volume = 0 }):Play()
		end)
	end
	if p ~= "Phase3" then alarm:Stop() end
	lastPhase = p
end
GS:GetAttributeChangedSignal("Phase"):Connect(onPhase)
onPhase()

---------------------------------------------------------------------
-- Despegue (va junto con la cuenta regresiva de LaunchCinematic)
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("Launched"):Connect(function()
	if GS:GetAttribute("Launched") ~= true then return end
	task.delay(1.3, function()
		oneShot(launch)
		rumble.Volume = S.Rumble.Volume * 1.5
		oneShot(rumble)
		task.delay(3.5, function()
			TweenService:Create(rumble, TweenInfo.new(1), { Volume = 0 }):Play()
		end)
	end)
end)

---------------------------------------------------------------------
-- Emergencias: alarma unos segundos al aparecer la tarjeta
---------------------------------------------------------------------
GS:GetAttributeChangedSignal("Emergency"):Connect(function()
	if (GS:GetAttribute("Emergency") or "") ~= "" and GS:GetAttribute("Phase") == "Phase3" then
		alarm.Volume = S.Alarm.Volume
		oneShot(alarm)
		task.delay(S.Alarm.Seconds or 4, function()
			alarm:Stop() -- suena solo unos segundos, no toda la emergencia
		end)
	else
		alarm:Stop()
	end
end)

-- Pitido al empezar cada día de la Fase 3
GS:GetAttributeChangedSignal("Day"):Connect(function()
	if GS:GetAttribute("Phase") == "Phase3" and (GS:GetAttribute("Day") or 0) >= 1 then
		oneShot(beep)
	end
end)

---------------------------------------------------------------------
-- Pitido al terminar cualquier "mantener E" (colocar, misiones, recargar, cosechar, emergencias)
---------------------------------------------------------------------
ProximityPromptService.PromptTriggered:Connect(function(_prompt, who)
	if who == player then oneShot(beep) end
end)

---------------------------------------------------------------------
-- Clic en cualquier botón de pantalla (PLAY, READY, CHOOSE, respuestas A/B/C...)
---------------------------------------------------------------------
local hooked = setmetatable({}, { __mode = "k" })
local function hook(b: Instance)
	if (b:IsA("TextButton") or b:IsA("ImageButton")) and not hooked[b] then
		hooked[b] = true
		(b :: GuiButton).MouseButton1Click:Connect(function() oneShot(click) end)
	end
end
local pg = player:WaitForChild("PlayerGui")
for _, d in pg:GetDescendants() do hook(d) end
pg.DescendantAdded:Connect(hook)

-- Al morir: sonido triste (solo para quien murió)
player:GetAttributeChangedSignal("Dead"):Connect(function()
	if player:GetAttribute("Dead") == true then oneShot(fail) end
end)
