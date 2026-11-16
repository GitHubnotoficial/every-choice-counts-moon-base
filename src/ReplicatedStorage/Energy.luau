-- Energy (ModuleScript) -> ReplicatedStorage.Energy
-- Dueño: Isaac + Claude. Energía generada contra pedida (PDF Fase 2, cap. 7). La usan servidor y cliente.
-- Prueba: reactor + recycler + hydroponics + inflable = 75 usada / 80 generada.
--         paneles en Nobile, cresta + o2plant + hydroponics + anexo = 85 usada / 70 generada.

local Config = require(script.Parent:WaitForChild("Config"))

local Energy = {}

local function find(list, id)
	for _, x in list do
		if x.Id == id then return x end
	end
	return nil
end

-- gs = la carpeta GameState (o cualquier objeto con GetAttribute)
function Energy.calc(gs): (number, number)
	local eng = gs:GetAttribute("Choice_eng") or ""
	local life = gs:GetAttribute("Choice_life") or ""
	local bot = gs:GetAttribute("Choice_bot") or ""
	local site = find(Config.Sites, gs:GetAttribute("Site") or "")
	local engSpot = find(Config.Spots.eng, gs:GetAttribute("Spot_eng") or "")
	local botSpot = find(Config.Spots.bot, gs:GetAttribute("Spot_bot") or "")

	local made = 0
	if eng == "reactor" then
		made = Config.Energy.ReactorOutput
	elseif eng == "panels" or eng == "panels_bat" then
		made = (site and site.Light or 0) * (engSpot and engSpot.PanelMult or 1)
	end
	if gs:GetAttribute("Damaged_eng") then
		made *= Config.Energy.DamagedMult
	end

	local d = Config.Energy.Demand
	local used = d.habitat + (d[life] or 0) + (d[bot] or 0)
	if bot ~= "packaged" and botSpot then
		used += botSpot.ExtraEnergy or 0
	end
	return math.floor(made + 0.5), used
end

return Energy
