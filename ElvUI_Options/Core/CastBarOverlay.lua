local E, L, V, P, G = unpack(ElvUI)
local CBO = E:GetModule('CastBarOverlay')

local function CreateOptionsGroup(order, name, unit)
	return {
		order = order,
		type = "group",
		name = name,
		args = {
			info = {
				order = 1,
				type = 'header',
				name = name,
			},
			overlay = {
				order = 2,
				type = 'toggle',
				name = L['Enable Overlay'],
				desc = L['Overlay the castbar on the chosen panel.'],
				get = function() return E.db.CBO[unit].overlay end,
				set = function(_, value) E.db.CBO[unit].overlay = value; CBO:UpdateSettings(unit) end,
			},
			overlayOnFrame = {
				order = 3,
				type = 'select',
				name = L['Overlay Panel'],
				desc = L['Choose which panel to overlay the castbar on.'],
				disabled = function() return not E.db.CBO[unit].overlay end,
				values = {
					["POWER"] = L["Power"],
					["HEALTH"] = L["Health"],
				},
				get = function() return E.db.CBO[unit].overlayOnFrame end,
				set = function(_, value)
					if value == "POWER" and not E.db.unitframe.units[unit].power.enable then
						E:StaticPopup_Show('CBO_PowerDisabled')
						value = "HEALTH"
					end
					E.db.CBO[unit].overlayOnFrame = value;
					CBO:UpdateSettings(unit);
				end,
			},
			hidetext = {
				order = 4,
				type = 'toggle',
				name = L['Hide Text'],
				desc = L['Hide Castbar text. Useful if your power height is very low or if you use power offset.'],
				get = function() return E.db.CBO[unit].hidetext end,
				set = function(_, value) E.db.CBO[unit].hidetext = value; CBO:UpdateSettings(unit); end,
				disabled = function() return not E.db.CBO[unit].overlay end,
			},
			spacer1 = {
				order = 5,
				type = 'description',
				name ='',
			},
			xOffsetText = {
				order = 6,
				type = 'range',
				name = L['Text xOffset'],
				desc = L['Move castbar text to the left or to the right. Default is 4'],
				get = function() return E.db.CBO[unit].xOffsetText end,
				set = function(_, value) E.db.CBO[unit].xOffsetText = value; CBO:UpdateSettings(unit); end,
				min = -100, max = 100, step = 1,
				disabled = function() return (not E.db.CBO[unit].overlay or E.db.CBO[unit].hidetext) end,
			},
			yOffsetText = {
				order = 7,
				type = 'range',
				name = L['Text yOffset'],
				desc = L['Move castbar text up or down. Default is 0'],
				get = function() return E.db.CBO[unit].yOffsetText end,
				set = function(_, value) E.db.CBO[unit].yOffsetText = value; CBO:UpdateSettings(unit); end,
				min = -50, max = 50, step = 1,
				disabled = function() return (not E.db.CBO[unit].overlay or E.db.CBO[unit].hidetext) end,
			},
			spacer2 = {
				order = 8,
				type = 'description',
				name ='',
			},
			xOffsetTime = {
				order = 9,
				type = 'range',
				name = L['Time xOffset'],
				desc = L['Move castbar time to the left or to the right. Default is -4'],
				get = function() return E.db.CBO[unit].xOffsetTime end,
				set = function(_, value) E.db.CBO[unit].xOffsetTime = value; CBO:UpdateSettings(unit); end,
				min = -100, max = 100, step = 1,
				disabled = function() return (not E.db.CBO[unit].overlay or E.db.CBO[unit].hidetext) end,
			},
			yOffsetTime = {
				order = 10,
				type = 'range',
				name = L['Time yOffset'],
				desc = L['Move castbar time up or down. Default is 0'],
				get = function() return E.db.CBO[unit].yOffsetTime end,
				set = function(_, value) E.db.CBO[unit].yOffsetTime = value; CBO:UpdateSettings(unit); end,
				min = -50, max = 50, step = 1,
				disabled = function() return (not E.db.CBO[unit].overlay or E.db.CBO[unit].hidetext) end,
			},
		},
	}
end

E.Options.args.castbaroverlay = {
	order = 1000,
	type = 'group',
	name = L["CastBar Overlay"],
	childGroups = 'tab',
	disabled = function() return not E.private.unitframe.enable end,
	args = {
		player = CreateOptionsGroup(1, L["Player"], "player"),
		target = CreateOptionsGroup(2, L["Target"], "target"),
		focus = CreateOptionsGroup(3, L["Focus"], "focus"),
		pet = CreateOptionsGroup(4, L["Pet"], "pet"),
		arena = CreateOptionsGroup(5, L["Arena"], "arena"),
		boss = CreateOptionsGroup(6, L["Boss"], "boss"),
	},
}
