local E, L, V, P, G = unpack(ElvUI)
local DTC = E:NewModule('DataTextColors', 'AceEvent-3.0')
local DT = E:GetModule('DataTexts')
local EP = E.Libs.EP

local classColor = RAID_CLASS_COLORS[E.myclass]

local color = { r = 1, g = 1, b = 1 }
local function unpackColor(c)
	return c.r, c.g, c.b
end

function DTC:ColorFont()
	for _, panel in pairs(DT.RegisteredPanels) do
		for _, dataPanel in pairs(panel.dataPanels) do
			if E.db.dtc.customColor == 1 then
				dataPanel.text:SetTextColor(classColor.r, classColor.g, classColor.b)
			elseif E.db.dtc.customColor == 2 then
				dataPanel.text:SetTextColor(unpackColor(E.db.dtc.userColor))
			else
				dataPanel.text:SetTextColor(unpackColor(E.media.rgbvaluecolor))
			end
		end
	end
end

P['dtc'] = {
	['userColor'] = { r = 1, g = 1, b = 1 },
	['customColor'] = 2,
}

local function AddOptions()
	E.Options.args.datatexts.args.general.args.fontGroup.args.dtc = {
		order = 10,
		type = 'group',
		name = L["DTC Text Color"],
		guiInline = true,
		args = {
			customColor = {
				order = 1,
				type = 'select',
				name = COLOR,
				values = {
					[1] = CLASS_COLORS,
					[2] = CUSTOM,
					[3] = L["Value Color"],
				},
				get = function(info) return E.db.dtc[info[#info]] end,
				set = function(info, value) E.db.dtc[info[#info]] = value; DTC:ColorFont() end,
			},
			userColor = {
				order = 2,
				type = 'color',
				name = COLOR_PICKER,
				disabled = function() return E.db.dtc.customColor == 1 or E.db.dtc.customColor == 3 end,
				get = function(info)
					local t = E.db.dtc[info[#info]]
					return t.r, t.g, t.b, t.a
				end,
				set = function(info, r, g, b)
					local t = E.db.dtc[info[#info]]
					t.r, t.g, t.b = r, g, b
					DTC:ColorFont()
				end,
			},
		},
	}
end

function DTC:PLAYER_ENTERING_WORLD()
	self:ColorFont()
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function DTC:Initialize()
	EP:RegisterPlugin('ElvUI_DataTextColors', AddOptions)
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

E:RegisterModule(DTC:GetName())
