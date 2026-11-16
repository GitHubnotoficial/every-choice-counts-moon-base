-- SO_LiveSpaceWeather (Script) -> ServerScriptService.SO_LiveSpaceWeather
-- Dueño: Isaac + Claude (15-nov). "EL SOL DE VERDAD": las emergencias de clima espacial siguen al Sol real.
-- Al empezar la Fase 3 el servidor pide a NASA DONKI (CCMC, sin clave) los eventos de los últimos días:
-- llamaradas (FLR), eyecciones de masa coronal (CME), tormentas geomagnéticas (GST) y partículas solares (SEP).
--   * Calcula la actividad real del Sol (LOW / MEDIUM / HIGH) y con eso sube o baja la probabilidad de las
--     emergencias de clima espacial (flare, cme, geostorm, sep): GameState.SW_Mult.
--   * Cada tarjeta de esas emergencias muestra el último evento real (clase, fecha) en la línea de datos.
-- Si DONKI no responde (o HttpService está apagado), usa datos guardados y lo dice claro: "SAVED NASA DATA".
-- Escribe en GameState: SW_Live, SW_Level, SW_Mult, SW_Summary, SW_flare, SW_cme, SW_geostorm, SW_sep.
-- Textos y números en Config.LiveSpaceWeather. Requiere "Allow HTTP Requests" en Game Settings > Security.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local GS = ReplicatedStorage:WaitForChild("GameState")
local LSW = Config.LiveSpaceWeather

local CLASS_RANK = { A = 0, B = 1, C = 2, M = 3, X = 4 }

local function isoDay(t: number): string
	return os.date("!%Y-%m-%d", t)
end
local function niceDate(iso: string?): string
	-- "2026-11-11T21:21Z" -> "Nov 11, 2026"
	if not iso then return "?" end
	local y, m, d = string.match(iso, "^(%d+)-(%d+)-(%d+)")
	local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
	if not y then return iso end
	return string.format("%s %d, %s", months[tonumber(m)] or m, tonumber(d), y)
end
local function ageDays(iso: string?): number
	if not iso then return 999 end
	local y, m, d = string.match(iso, "^(%d+)-(%d+)-(%d+)")
	if not y then return 999 end
	local t = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
	return (os.time() - t) / 86400
end

local function get(kind: string): { any }?
	local now = os.time()
	local url = string.format("%s/%s?startDate=%s&endDate=%s", LSW.BaseUrl, kind, isoDay(now - LSW.Days * 86400), isoDay(now))
	local ok, body = pcall(function() return HttpService:GetAsync(url) end)
	if not ok then
		warn("[LiveSpaceWeather] DONKI no respondió (" .. kind .. "): " .. tostring(body))
		return nil
	end
	local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok2 or typeof(data) ~= "table" then return nil end
	return data
end

local function applySaved()
	GS:SetAttribute("SW_Live", false)
	GS:SetAttribute("SW_Level", "MEDIUM")
	GS:SetAttribute("SW_Mult", 1)
	GS:SetAttribute("SW_Summary", LSW.Text.Saved)
	for id, t in LSW.SavedEvents do GS:SetAttribute("SW_" .. id, LSW.Text.SavedPrefix .. t) end
end

local busy = false
local function refresh()
	if busy then return end
	busy = true
	local flr, cme, gst, sep = get("FLR"), get("CME"), get("GST"), get("SEP")
	busy = false
	if not flr and not cme and not gst then
		applySaved()
		return
	end
	flr, cme, gst, sep = flr or {}, cme or {}, gst or {}, sep or {}

	-- Llamaradas: la última, la más fuerte y cuántas fuertes (M o X) en la última semana
	local lastF, strongF, strongWeek = nil, nil, 0
	for _, f in flr do
		local cls = tostring(f.classType or "")
		local letter, num = string.match(cls, "^(%a)([%d%.]*)")
		local rank = (CLASS_RANK[letter or ""] or 0) * 100 + (tonumber(num) or 0)
		f._rank = rank
		if not lastF or tostring(f.peakTime) > tostring(lastF.peakTime) then lastF = f end
		if not strongF or rank > strongF._rank then strongF = f end
		if (letter == "M" or letter == "X") and ageDays(f.peakTime) <= 7 then strongWeek += 1 end
	end
	local lastC, cmeWeek = nil, 0
	for _, c in cme do
		if not lastC or tostring(c.startTime) > tostring(lastC.startTime) then lastC = c end
		if ageDays(c.startTime) <= 7 then cmeWeek += 1 end
	end
	local lastG, maxKp, gstWeek = nil, 0, 0
	for _, g in gst do
		if not lastG or tostring(g.startTime) > tostring(lastG.startTime) then lastG = g end
		for _, k in (g.allKpIndex or {}) do maxKp = math.max(maxKp, tonumber(k.kpIndex) or 0) end
		if ageDays(g.startTime) <= 7 then gstWeek += 1 end
	end
	local lastS = nil
	for _, s in sep do
		if not lastS or tostring(s.eventTime) > tostring(lastS.eventTime) then lastS = s end
	end

	-- Actividad real del Sol esta semana
	local score = strongWeek * 2 + cmeWeek + gstWeek * 3 + ((lastS and ageDays(lastS.eventTime) <= 7) and 3 or 0)
	local level = score >= LSW.HighScore and "HIGH" or (score >= LSW.MediumScore and "MEDIUM" or "LOW")
	GS:SetAttribute("SW_Live", true)
	GS:SetAttribute("SW_Level", level)
	GS:SetAttribute("SW_Mult", LSW.Mult[level])
	GS:SetAttribute("SW_Summary", string.format(LSW.Text.Summary, LSW.Text.Level[level], #flr, LSW.Days))

	GS:SetAttribute("SW_flare", lastF and string.format(LSW.Text.Flare, tostring(lastF.classType), niceDate(lastF.peakTime), #flr, LSW.Days,
		strongF and tostring(strongF.classType) or "?") or LSW.Text.SavedPrefix .. LSW.SavedEvents.flare)
	GS:SetAttribute("SW_cme", lastC and string.format(LSW.Text.Cme, niceDate(lastC.startTime), #cme, LSW.Days) or LSW.Text.SavedPrefix .. LSW.SavedEvents.cme)
	GS:SetAttribute("SW_geostorm", lastG and string.format(LSW.Text.Gst, niceDate(lastG.startTime), maxKp) or LSW.Text.SavedPrefix .. LSW.SavedEvents.geostorm)
	GS:SetAttribute("SW_sep", lastS and string.format(LSW.Text.Sep, niceDate(lastS.eventTime)) or LSW.Text.SavedPrefix .. LSW.SavedEvents.sep)
end

if not LSW or not LSW.Enabled then return end
applySaved() -- hasta que llegue la respuesta, datos guardados (y dicho así)
task.spawn(refresh)
GS:GetAttributeChangedSignal("Phase"):Connect(function()
	if GS:GetAttribute("Phase") == "Phase3" then task.spawn(refresh) end
end)
