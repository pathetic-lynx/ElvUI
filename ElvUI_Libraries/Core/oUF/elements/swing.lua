--[[
# Element: Swing Timer

Tracks the player's melee and ranged weapon swing timers.

## Widget

Swing - A frame to hold the `Twohand`, `Mainhand` and `Offhand` sub-widgets.

A second, independent timer can be registered as `Swing2` (same sub-widgets and
options). Each element carries its own state, so two bars can run concurrently --
e.g. a hunter's ranged Auto Shot alongside the melee swing. Which attack type an
element tracks is controlled by `element.track`:

	"ALL"    - melee and ranged, mutually exclusive (legacy single-bar behaviour)
	"MELEE"  - only melee/auto-attack swings
	"RANGED" - only ranged (Auto Shot / Multi-Shot)

## Sub-Widgets

Twohand  - A StatusBar used for two-handed and ranged weapons.
Mainhand - A StatusBar used for the main-hand weapon while dual wielding.
Offhand  - A StatusBar used for the off-hand weapon while dual wielding.

## Sub-Widget Options

.Spark - A Texture used to highlight the current position on each StatusBar.
.Text  - A FontString used to display the remaining time on each StatusBar.

## Notes

A default texture will be applied to the StatusBars and Sparks if they don't have one set.

## Examples

	-- Position and size
	local Swing = CreateFrame('Frame', nil, self)
	Swing.Twohand = CreateFrame('StatusBar', nil, Swing)
	Swing.Mainhand = CreateFrame('StatusBar', nil, Swing)
	Swing.Offhand = CreateFrame('StatusBar', nil, Swing)

	-- Register it with oUF
	self.Swing = Swing
--]]

local _, ns = ...
local oUF = ns.oUF

local pairs = pairs
local next = next
local find = string.find

local GetInventoryItemID = GetInventoryItemID
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAttackSpeed = UnitAttackSpeed
local UnitCastingInfo = UnitCastingInfo
local UnitGUID = UnitGUID
local UnitRangedDamage = UnitRangedDamage

local slam = GetSpellInfo(1464)

local function SwingStopped(element)
	for _, Bar in pairs({element.Twohand, element.Mainhand, element.Offhand}) do
		if Bar:IsShown() then return end
	end

	element:Hide()
end

-- For the "Either" shot point of a center-filling bar: flip the fill direction at
-- each new swing so the swing lands alternately at the edges and at the center.
-- (Static "Outside"/"Middle" directions are set once in UF:Configure_Swingbar.)
local function FlipEither(Bar)
	if Bar._shotEither and Bar.SetReverseFill then
		Bar._invert = not Bar._invert
		Bar:SetReverseFill(Bar._invert)
		if Bar.Mirror then
			Bar.Mirror:SetReverseFill(not Bar._invert)
		end
	end
end

local function OnDurationUpdate(self, elapsed)
	local now = GetTime()
	local owner = self.__owner

	if owner.meleeing then
		if self._checkElapsed > 0.01 then
			if owner.lastHit + self.speed + self._slamTime < now then
				self:Hide()
				self:SetScript("OnUpdate", nil)
				SwingStopped(owner)

				owner.meleeing, owner.ranging = false, false
			end

			self._checkElapsed = 0
		else
			self._checkElapsed = self._checkElapsed + elapsed
		end
	end

	if slam == UnitCastingInfo("player") then
		self._slamElapsed = self._slamElapsed + elapsed
		self._slamTime = self._slamTime + elapsed
	else
		if self._slamElapsed ~= 0 then
			self.min = self.min + self._slamElapsed
			self.max = self.max + self._slamElapsed

			self:SetMinMaxValues(self.min - now, self.max - now)

			self._slamElapsed = 0
		end

		if now > self.max then
			if owner.meleeing then
				if owner.lastHit then
					self.min = self.max
					self.max = self.max + self.speed

					self:SetMinMaxValues(self.min - now, self.max - now)

					self._slamTime = 0

					FlipEither(self)
				end
			else
				self:Hide()
				self:SetScript("OnUpdate", nil)

				owner.meleeing, owner.ranging = false, false
			end
		else
			self:SetValue(now - self.min)

			if self.Text then
				self.Text:SetFormattedText("%.1f", self.max - now)
			end
		end
	end
end

-- Start a bar with a fresh swing window, clearing per-bar bookkeeping.
local function StartBar(Bar, min, speed, now)
	Bar.min = min
	Bar.max = min + speed
	Bar.speed = speed
	Bar._checkElapsed = 0
	Bar._slamElapsed = 0
	Bar._slamTime = 0

	Bar:Show()
	Bar:SetMinMaxValues(Bar.min - now, Bar.max - now)
	Bar:SetScript("OnUpdate", OnDurationUpdate)

	FlipEither(Bar)
end

local function MeleeChange(element, unit)
	if not element.meleeing then return end

	local now = GetTime()
	local newMainHandID = GetInventoryItemID("player", 16)
	local newOffHandID = GetInventoryItemID("player", 17)
	local mainSpeed, offSpeed = UnitAttackSpeed("player")

	if (element.mainHandID ~= newMainHandID) or (element.offHandID ~= newOffHandID) then
		if offSpeed then
			element.Twohand:Hide()
			element.Twohand:SetScript("OnUpdate", nil)

			StartBar(element.Mainhand, now, mainSpeed, now)
			StartBar(element.Offhand, now, offSpeed, now)
		else
			StartBar(element.Twohand, now, mainSpeed, now)

			element.Mainhand:Hide()
			element.Mainhand:SetScript("OnUpdate", nil)

			element.Offhand:Hide()
			element.Offhand:SetScript("OnUpdate", nil)
		end

		element.lastHit = now

		element.mainHandID, element.offHandID = newMainHandID, newOffHandID
	else
		if offSpeed then
			if element.Mainhand.speed ~= mainSpeed then
				local percentage = (element.Mainhand.max - now) / (element.Mainhand.speed)
				element.Mainhand.min = now - mainSpeed * (1 - percentage)
				element.Mainhand.max = now + mainSpeed * percentage
				element.Mainhand:SetMinMaxValues(element.Mainhand.min - now, element.Mainhand.max - now)
				element.Mainhand.speed = mainSpeed
			end
			if element.Offhand.speed ~= offSpeed then
				local percentage = (element.Offhand.max - now) / (element.Offhand.speed)
				element.Offhand.min = now - offSpeed * (1 - percentage)
				element.Offhand.max = now + offSpeed * percentage
				element.Offhand:SetMinMaxValues(element.Offhand.min - now, element.Offhand.max - now)
				element.Offhand.speed = offSpeed
			end
		else
			if element.Twohand.speed ~= mainSpeed then
				local percentage = (element.Twohand.max - now) / (element.Twohand.speed)
				element.Twohand.min = now - mainSpeed * (1 - percentage)
				element.Twohand.max = now + mainSpeed * percentage
				element.Twohand:SetMinMaxValues(element.Twohand.min - now, element.Twohand.max - now)
				element.Twohand.speed = mainSpeed
			end
		end
	end
end

local function RangedChange(element, unit)
	if not element.ranging then return end

	local now = GetTime()
	local newRangedID = GetInventoryItemID("player", 18)
	local speed = UnitRangedDamage("player")

	if element.rangedID ~= newRangedID then
		StartBar(element.Twohand, now, UnitRangedDamage(unit), now)

		element.rangedID = newRangedID
	else
		if element.Twohand.speed ~= speed then
			local percentage = (element.Twohand.max - now) / (element.Twohand.speed)
			element.Twohand.min = now - speed * (1 - percentage)
			element.Twohand.max = now + speed * percentage
			element.Twohand.speed = speed
		end
	end
end

local function Ranged(element, unit, spellName)
	if spellName ~= GetSpellInfo(75) and spellName ~= GetSpellInfo(5019) then return end

	local now = GetTime()

	element:Show()

	StartBar(element.Twohand, now, UnitRangedDamage(unit), now)

	element.Mainhand:Hide()
	element.Mainhand:SetScript("OnUpdate", nil)

	element.Offhand:Hide()
	element.Offhand:SetScript("OnUpdate", nil)

	element.meleeing, element.ranging = false, true
end

local function Melee(element, event, spellName)
	if not find(event, "SWING") and not find(event, "SPELL_CAST_SUCCESS") then return end
	if find(event, "SPELL_CAST_SUCCESS") then
		if spellName ~= GetSpellInfo(30324) and spellName ~= GetSpellInfo(25231) and spellName ~= GetSpellInfo(27014) and spellName ~= GetSpellInfo(26996) then return end
	end

	local now = GetTime()

	if not element.meleeing then
		element:Show()

		for _, Bar in pairs({element.Twohand, element.Mainhand, element.Offhand}) do
			Bar:Hide()
			Bar:SetScript("OnUpdate", nil)
		end

		local mainSpeed, offSpeed = UnitAttackSpeed("player")

		if offSpeed then
			StartBar(element.Mainhand, now, mainSpeed, now)
			StartBar(element.Offhand, now, offSpeed, now)
		else
			StartBar(element.Twohand, now, mainSpeed, now)
		end

		element.meleeing, element.ranging = true, false
	end

	element.lastHit = now
end

local function ParryHaste(element)
	if not element.meleeing then return end

	local now = GetTime()
	local _, offSpeed = UnitAttackSpeed("player")

	if offSpeed then
		local percentage = (element.Mainhand.max - now) / element.Mainhand.speed

		if percentage > 0.6 then
			element.Mainhand.max = now + element.Mainhand.speed * 0.6
			element.Mainhand.min = now - (element.Mainhand.max - now) * percentage / (1 - percentage)
			element.Mainhand:SetMinMaxValues(element.Mainhand.min - now, element.Mainhand.max - now)
		elseif percentage > 0.2 then
			element.Mainhand.max = now + element.Mainhand.speed * 0.2
			element.Mainhand.min = now - (element.Mainhand.max - now) * percentage / (1 - percentage)
			element.Mainhand:SetMinMaxValues(element.Mainhand.min - now, element.Mainhand.max - now)
		end

		percentage = (element.Offhand.max - now) / element.Offhand.speed

		if percentage > 0.6 then
			element.Offhand.max = now + element.Offhand.speed * 0.6
			element.Offhand.min = now - (element.Offhand.max - now) * percentage / (1 - percentage)
			element.Offhand:SetMinMaxValues(element.Offhand.min - now, element.Offhand.max - now)
		elseif percentage > 0.2 then
			element.Offhand.max = now + element.Offhand.speed * 0.2
			element.Offhand.min = now - (element.Offhand.max - now) * percentage / (1 - percentage)
			element.Offhand:SetMinMaxValues(element.Offhand.min - now, element.Offhand.max - now)
		end
	else
		local percentage = (element.Twohand.max - now) / element.Twohand.speed

		if percentage > 0.6 then
			element.Twohand.max = now + element.Twohand.speed * 0.6
			element.Twohand.min = now - (element.Twohand.max - now) * percentage / (1 - percentage)
			element.Twohand:SetMinMaxValues(element.Twohand.min - now, element.Twohand.max - now)
		elseif percentage > 0.2 then
			element.Twohand.max = now + element.Twohand.speed * 0.2
			element.Twohand.min = now - (element.Twohand.max - now) * percentage / (1 - percentage)
			element.Twohand:SetMinMaxValues(element.Twohand.min - now, element.Twohand.max - now)
		end
	end
end

-- Iterates the active swing elements on a frame, filtered by the attack type
-- the handler cares about ("MELEE" or "RANGED").
local function forEachSwing(self, attackType, fn, ...)
	local active = self.__swingActive
	if not active then return end

	for _, element in next, active do
		local track = element.track or "ALL"
		if track == "ALL" or track == attackType then
			fn(element, ...)
		end
	end
end

-- Event entry points (registered once per frame; dispatch to every active element).
local function OnMeleeChange(self, _, unit)
	if unit ~= "player" then return end
	forEachSwing(self, "MELEE", MeleeChange, unit)
end

local function OnRangedChange(self, _, unit)
	if unit ~= "player" then return end
	forEachSwing(self, "RANGED", RangedChange, unit)
end

local function OnRanged(self, _, unit, spellName)
	if unit ~= "player" then return end
	forEachSwing(self, "RANGED", Ranged, unit, spellName)
end

local function OnMelee(self, _, _, event, GUID, _, _, _, _, _, _, spellName)
	if UnitGUID("player") ~= GUID then return end
	forEachSwing(self, "MELEE", Melee, event, spellName)
end

local function OnParryHaste(self, _, _, subEvent, _, _, _, _, _, tarGUID, _, missType)
	if UnitGUID("player") ~= tarGUID then return end
	if not find(subEvent, "MISSED") then return end
	if missType ~= "PARRY" then return end
	forEachSwing(self, "MELEE", ParryHaste)
end

local function NoCombatHide(self)
	local active = self.__swingActive
	if not active then return end

	for _, element in next, active do
		for _, Bar in pairs({element.Twohand, element.Mainhand, element.Offhand}) do
			Bar:Hide()
		end

		element:Hide()

		element.meleeing, element.ranging = false, false
	end
end

local function ToggleTestMode(self)
	local active = self.__swingActive
	if not active then return end

	for _, element in next, active do
		if element.testMode then
			if not (element.meleeing or element.ranging) then
				for _, Bar in pairs({element.Twohand, element.Mainhand, element.Offhand}) do
					Bar:Hide()
				end

				element:Hide()
			end

			element.testMode = nil
		end
	end
end

local function RegisterEvents(self)
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", OnRanged)
	self:RegisterEvent("UNIT_RANGEDDAMAGE", OnRangedChange)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", OnMelee)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", OnParryHaste)
	self:RegisterEvent("UNIT_ATTACK_SPEED", OnMeleeChange)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", NoCombatHide)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", ToggleTestMode)
end

local function UnregisterEvents(self)
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED", OnRanged)
	self:UnregisterEvent("UNIT_RANGEDDAMAGE", OnRangedChange)
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED", OnMelee)
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED", OnParryHaste)
	self:UnregisterEvent("UNIT_ATTACK_SPEED", OnMeleeChange)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED", NoCombatHide)
	self:UnregisterEvent("PLAYER_REGEN_DISABLED", ToggleTestMode)
end

local function EnableElement(self, unit, key)
	local element = self[key]

	if element and unit == "player" then
		element.meleeing, element.ranging, element.lastHit = false, false, nil
		element.mainHandID = GetInventoryItemID("player", 16)
		element.offHandID = GetInventoryItemID("player", 17)
		element.rangedID = GetInventoryItemID("player", 18)

		for _, Bar in pairs({element.Twohand, element.Mainhand, element.Offhand}) do
			Bar.__owner = element
			Bar._checkElapsed = 0
			Bar._slamElapsed = 0
			Bar._slamTime = 0

			if Bar:IsObjectType("StatusBar") and not Bar:GetStatusBarTexture() then
				Bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			if Bar.Spark and Bar.Spark:IsObjectType("Texture") and not Bar.Spark:GetTexture() then
				Bar.Spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
			end

			if Bar.Text then
				Bar.Text:SetParent(Bar)
			end
		end

		if not self.__swingActive then self.__swingActive = {} end
		self.__swingActive[key] = element

		RegisterEvents(self)

		return true
	end
end

local function DisableElement(self, key)
	local element = self[key]

	if element then
		if self.__swingActive then
			self.__swingActive[key] = nil

			if not next(self.__swingActive) then
				UnregisterEvents(self)
			end
		end

		for _, Bar in pairs({element.Twohand, element.Mainhand, element.Offhand}) do
			Bar:Hide()
			Bar:SetScript("OnUpdate", nil)
		end

		element:Hide()
	end
end

local function Enable(self, unit) return EnableElement(self, unit, "Swing") end
local function Disable(self) return DisableElement(self, "Swing") end

local function Enable2(self, unit) return EnableElement(self, unit, "Swing2") end
local function Disable2(self) return DisableElement(self, "Swing2") end

oUF:AddElement("Swing", nil, Enable, Disable)
oUF:AddElement("Swing2", nil, Enable2, Disable2)
