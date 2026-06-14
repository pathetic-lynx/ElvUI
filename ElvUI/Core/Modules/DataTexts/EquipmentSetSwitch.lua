local E, L, V, P, G = unpack(ElvUI)
local ESS = E:NewModule('EquipmentSetSwitch', 'AceEvent-3.0')
local EP = E.Libs.EP

local GetNumEquipmentSets = GetNumEquipmentSets
local GetEquipmentSetInfo = GetEquipmentSetInfo
local GetActiveTalentGroup = GetActiveTalentGroup
local UseEquipmentSet = UseEquipmentSet

P['equipSetSwitch'] = {
	['enable'] = false,
	['primary'] = 'none',
	['secondary'] = 'none',
}

local function SwapEquipmentSet()
	if not E.db.equipSetSwitch.enable then return end
	if GetNumEquipmentSets() == 0 then return end

	local active = GetActiveTalentGroup()
	local targetSet = active == 1 and E.db.equipSetSwitch.primary or E.db.equipSetSwitch.secondary
	if targetSet == 'none' then return end

	for i = 1, GetNumEquipmentSets() do
		local name = GetEquipmentSetInfo(i)
		if name == targetSet then
			UseEquipmentSet(name)
			return
		end
	end
end

local function GetEquipmentSetValues()
	local sets = { ['none'] = L["No Change"] }
	for i = 1, GetNumEquipmentSets() do
		local name = GetEquipmentSetInfo(i)
		if name then sets[name] = name end
	end
	return sets
end

local function AddOptions()
	E.Options.args.datatexts.args.equipSetSwitch = {
		order = 50,
		type = 'group',
		name = L["Equipment Set Switch"],
		get = function(info) return E.db.equipSetSwitch[info[#info]] end,
		set = function(info, value) E.db.equipSetSwitch[info[#info]] = value end,
		args = {
			enable = {
				order = 1,
				type = 'toggle',
				name = L["Swap Equipment Sets"],
				desc = L["Change equipment sets when you change your spec."],
			},
			primary = {
				order = 2,
				type = 'select',
				name = L["Primary Talents"],
				desc = L["Choose the equipment set to use for your primary spec."],
				disabled = function() return not E.db.equipSetSwitch.enable end,
				values = GetEquipmentSetValues,
			},
			secondary = {
				order = 3,
				type = 'select',
				name = L["Secondary Talents"],
				desc = L["Choose the equipment set to use for your secondary spec."],
				disabled = function() return not E.db.equipSetSwitch.enable end,
				values = GetEquipmentSetValues,
			},
		},
	}
end

function ESS:ACTIVE_TALENT_GROUP_CHANGED()
	SwapEquipmentSet()
end

function ESS:Initialize()
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	EP:RegisterPlugin('ElvUI_ImprovedSpecSwitch', AddOptions)
end

E:RegisterModule(ESS:GetName())
