local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')
local ABM = E:GetModule('AuraMover')

-- Inject "detach / width / spacing" controls into each unit's Aura Bars options
local units = { 'player', 'target', 'focus', 'pet' }

for _, unit in ipairs(units) do
	local aurabar = E.Options.args.unitframe.args[unit] and E.Options.args.unitframe.args[unit].args.aurabar
	if aurabar then
		aurabar.args.detach = {
			order = 25,
			type = "toggle",
			name = '|cff30ee30'..L['Detach From Frame']..'|r',
			get = function() return E.db.abm[unit] end,
			set = function(_, value) E.db.abm[unit] = value; UF:CreateAndUpdateUF(unit); ABM:MoverToggle() end,
		}

		aurabar.args.width = {
			order = 26,
			type = "range",
			name = '|cff30ee30'..L['Width']..'|r',
			min = 50, max = 500, step = 1,
			get = function() return E.db.abm[unit..'w'] end,
			set = function(_, value) E.db.abm[unit..'w'] = value; UF:CreateAndUpdateUF(unit) end,
		}

		aurabar.args.space = {
			order = 27,
			type = "range",
			name = '|cff30ee30'..L["Vertical Spacing"]..'|r',
			min = -10, max = 20, step = 1,
			get = function() return E.db.abm[unit..'Space'] end,
			set = function(_, value) E.db.abm[unit..'Space'] = value; UF:CreateAndUpdateUF(unit) end,
		}
	end
end
