local E, L, V, P, G = unpack(ElvUI)
local UF = E:GetModule("UnitFrames")
local LSM = E.Libs.LSM

local pairs = pairs
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

function UF:Construct_Swingbar(frame, isSecondary)
	local frameName = frame:GetName()
	local suffix = isSecondary and "SwingBar2" or "SwingBar"
	local swingbar = CreateFrame("Frame", frameName..suffix, frame)
	swingbar:SetFrameLevel(frame.RaisedElementParent:GetFrameLevel() + 30)
	swingbar:SetClampedToScreen(true)

	swingbar.Holder = CreateFrame("Frame", nil, swingbar)
	swingbar.Holder:Point("TOPRIGHT", frame, "BOTTOMRIGHT", 0, isSecondary and -60 or -36)
	swingbar:Point("BOTTOMRIGHT", swingbar.Holder, "BOTTOMRIGHT", -E.Border, E.Border)

	if isSecondary then
		E:CreateMover(swingbar.Holder, frameName..suffix.."Mover", L["Player SwingBar (Secondary)"], nil, -6, nil, "ALL,SOLO", nil, "unitframe,player,swingbar2")
	else
		E:CreateMover(swingbar.Holder, frameName..suffix.."Mover", L["Player SwingBar"], nil, -6, nil, "ALL,SOLO", nil, "unitframe,player,swingbar")
	end

	swingbar.Twohand = CreateFrame("StatusBar", frameName..suffix.."_Twohand", swingbar)
	swingbar.Twohand:Point("TOPLEFT", swingbar, "TOPLEFT", 0, 0)
	swingbar.Twohand:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT", 0, 0)

	swingbar.Mainhand = CreateFrame("StatusBar", frameName..suffix.."_Mainhand", swingbar)
	swingbar.Offhand = CreateFrame("StatusBar", frameName..suffix.."_Offhand", swingbar)

	for _, Bar in pairs({swingbar.Twohand, swingbar.Mainhand, swingbar.Offhand}) do
		UF.statusbars[Bar] = true
		Bar:CreateBackdrop("Default", nil, nil, self.thinBorders, true)
		Bar:Hide()

		Bar.bg = Bar:CreateTexture(nil, "BORDER")
		Bar.bg:SetAllPoints(Bar)
		Bar.bg:SetTexture(E.media.blankTex)

		Bar.Spark = Bar:CreateTexture(nil, "OVERLAY")
		Bar.Spark:SetBlendMode("ADD")
		Bar.Spark:SetVertexColor(1, 1, 1)
		Bar.Spark:Size(20, 40)

		Bar.Text = swingbar:CreateFontString(nil, "OVERLAY")

		-- The other half of the bar, used only for the "Center Fill" mode. It mirrors
		-- the main bar's value/visibility (see the hooks below) and fills toward the
		-- opposite edge, so the two halves grow out from (or in to) the center.
		local Mirror = CreateFrame("StatusBar", Bar:GetName().."_Mirror", swingbar)
		UF.statusbars[Mirror] = true
		Mirror:Hide()

		Mirror.bg = Mirror:CreateTexture(nil, "BORDER")
		Mirror.bg:SetAllPoints(Mirror)
		Mirror.bg:SetTexture(E.media.blankTex)

		Bar.Mirror = Mirror

		hooksecurefunc(Bar, "SetValue", function(self, value)
			if self.Mirror.active then self.Mirror:SetValue(value) end
		end)
		hooksecurefunc(Bar, "SetMinMaxValues", function(self, lo, hi)
			if self.Mirror.active then self.Mirror:SetMinMaxValues(lo, hi) end
		end)
		hooksecurefunc(Bar, "Show", function(self)
			if self.Mirror.active then self.Mirror:Show() end
		end)
		hooksecurefunc(Bar, "Hide", function(self)
			self.Mirror:Hide()
		end)
	end

	return swingbar
end

function UF:Configure_Swingbar(frame, isSecondary)
	local elementName = isSecondary and "Swing2" or "Swing"
	local swingbar = isSecondary and frame.Swing2 or frame.Swing
	local db = isSecondary and frame.db.swingbar2 or frame.db.swingbar
	local moverName = frame:GetName()..(isSecondary and "SwingBar2Mover" or "SwingBarMover")

	swingbar.track = db.track

	if db.enable then
		if not frame:IsElementEnabled(elementName) then
			frame:EnableElement(elementName)
		end

		swingbar:Show()
		swingbar:Size(db.width - (E.Border * 2), db.height)

		swingbar.Holder:Size(db.width, db.height + E.Border * 2)

		if swingbar.Holder:GetScript("OnSizeChanged") then
			swingbar.Holder:GetScript("OnSizeChanged")(swingbar.Holder)
		end

		local sp = db.spacing

		swingbar.Twohand:ClearAllPoints()
		swingbar.Mainhand:ClearAllPoints()
		swingbar.Offhand:ClearAllPoints()
		swingbar.Twohand.Mirror:ClearAllPoints()
		swingbar.Mainhand.Mirror:ClearAllPoints()
		swingbar.Offhand.Mirror:ClearAllPoints()

		if db.centerFill then
			-- Each bar is split at the center; the main half spans center->far edge and
			-- the mirror spans center->near edge, so the fill grows out from the middle.
			if db.verticalOrientation then
				swingbar.Twohand:Point("TOPLEFT", swingbar, "TOPLEFT")
				swingbar.Twohand:Point("BOTTOMRIGHT", swingbar, "RIGHT")
				swingbar.Twohand.Mirror:Point("TOPLEFT", swingbar, "LEFT")
				swingbar.Twohand.Mirror:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")

				swingbar.Mainhand:Point("TOPLEFT", swingbar, "TOPLEFT")
				swingbar.Mainhand:Point("BOTTOMRIGHT", swingbar, "CENTER", -sp, 0)
				swingbar.Mainhand.Mirror:Point("TOPLEFT", swingbar, "LEFT")
				swingbar.Mainhand.Mirror:Point("BOTTOMRIGHT", swingbar, "BOTTOM", -sp, 0)

				swingbar.Offhand:Point("TOPLEFT", swingbar, "TOP", sp + E.Border, 0)
				swingbar.Offhand:Point("BOTTOMRIGHT", swingbar, "RIGHT")
				swingbar.Offhand.Mirror:Point("TOPLEFT", swingbar, "CENTER", sp + E.Border, 0)
				swingbar.Offhand.Mirror:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")
			else
				swingbar.Twohand:Point("TOPLEFT", swingbar, "TOP")
				swingbar.Twohand:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")
				swingbar.Twohand.Mirror:Point("TOPLEFT", swingbar, "TOPLEFT")
				swingbar.Twohand.Mirror:Point("BOTTOMRIGHT", swingbar, "BOTTOM")

				swingbar.Mainhand:Point("TOPLEFT", swingbar, "TOP")
				swingbar.Mainhand:Point("BOTTOMRIGHT", swingbar, "RIGHT", 0, sp)
				swingbar.Mainhand.Mirror:Point("TOPLEFT", swingbar, "TOPLEFT")
				swingbar.Mainhand.Mirror:Point("BOTTOMRIGHT", swingbar, "CENTER", 0, sp)

				swingbar.Offhand:Point("TOPLEFT", swingbar, "CENTER", 0, -sp - E.Border)
				swingbar.Offhand:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")
				swingbar.Offhand.Mirror:Point("TOPLEFT", swingbar, "LEFT", 0, -sp - E.Border)
				swingbar.Offhand.Mirror:Point("BOTTOMRIGHT", swingbar, "BOTTOM")
			end
		else
			swingbar.Twohand:Point("TOPLEFT", swingbar, "TOPLEFT")
			swingbar.Twohand:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")

			if db.verticalOrientation then
				swingbar.Mainhand:Point("TOPLEFT", swingbar, "TOPLEFT")
				swingbar.Mainhand:Point("BOTTOMRIGHT", swingbar, "BOTTOM", -sp, 0)

				swingbar.Offhand:Point("TOPLEFT", swingbar, "TOP", sp + E.Border, 0)
				swingbar.Offhand:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")
			else
				swingbar.Mainhand:Point("TOPLEFT", swingbar, "TOPLEFT")
				swingbar.Mainhand:Point("BOTTOMRIGHT", swingbar, "RIGHT", 0, sp)

				swingbar.Offhand:Point("TOPLEFT", swingbar, "LEFT", 0, -sp - E.Border)
				swingbar.Offhand:Point("BOTTOMRIGHT", swingbar, "BOTTOMRIGHT")
			end
		end

		for _, Bar in pairs({swingbar.Twohand, swingbar.Mainhand, swingbar.Offhand}) do
			local color = db.color
			Bar:SetStatusBarColor(color.r, color.g, color.b, color.a)

			color = db.backdropColor
			Bar.bg:SetVertexColor(color.r * 0.35, color.g * 0.35, color.b * 0.35, color.a)

			Bar:SetOrientation(db.verticalOrientation and "VERTICAL" or "HORIZONTAL")
			Bar:SetFrameStrata("BACKGROUND")

			-- Center Fill: style the mirror half and set the fill direction (Shot Point).
			local Mirror = Bar.Mirror
			Mirror.active = db.centerFill
			Bar._centerFill = db.centerFill
			Bar._shotEither = db.centerFill and db.shotPoint == "EITHER"
			Bar._invert = false

			if db.centerFill then
				color = db.color
				Mirror:SetStatusBarColor(color.r, color.g, color.b, color.a)
				local tex = Bar:GetStatusBarTexture()
				Mirror:SetStatusBarTexture(tex and tex:GetTexture() or E.media.blankTex)

				color = db.backdropColor
				Mirror.bg:SetVertexColor(color.r * 0.35, color.g * 0.35, color.b * 0.35, color.a)

				Mirror:SetOrientation(db.verticalOrientation and "VERTICAL" or "HORIZONTAL")
				Mirror:SetFrameStrata("BACKGROUND")
				Mirror:SetMinMaxValues(Bar:GetMinMaxValues())
				Mirror:SetValue(Bar:GetValue())

				-- "OUTSIDE": grow center->edges. "MIDDLE": grow edges->center.
				-- "EITHER": start OUTSIDE, then alternate per swing (handled in swing.lua).
				local outward = db.shotPoint ~= "MIDDLE"
				if Bar.SetReverseFill then
					Bar:SetReverseFill(not outward)
					Mirror:SetReverseFill(outward)
				end

				if Bar:IsShown() then Mirror:Show() else Mirror:Hide() end
			else
				if Bar.SetReverseFill then Bar:SetReverseFill(false) end
				Mirror:Hide()
			end
			if db.spark then
				if db.verticalOrientation then
					if Bar == swingbar.Twohand then
						Bar.Spark:Width(db.width * 1.8)
					else
						Bar.Spark:Width(db.width)
					end
					Bar.Spark:Height(10)
				else
					if Bar == swingbar.Twohand then
						Bar.Spark:Height(db.height * 1.8)
					else
						Bar.Spark:Height(db.height / 1.2)
					end
					Bar.Spark:Width(20)
				end

				Bar.Spark:ClearAllPoints()
				if db.verticalOrientation then
					Bar.Spark:Point("CENTER", Bar:GetStatusBarTexture(), "TOP")
				else
					Bar.Spark:Point("CENTER", Bar:GetStatusBarTexture(), "RIGHT")
				end
				Bar.Spark:Show()
			else
				Bar.Spark:Hide()
			end

			local x, y = self:GetPositionOffset(db.text.position)
			color = db.text.color

			Bar.Text:ClearAllPoints()
			Bar.Text:Point(db.text.position, Bar, db.text.position, x + db.text.xOffset, y + db.text.yOffset)
			Bar.Text:FontTemplate(LSM:Fetch("font", db.text.font), db.text.fontSize, db.text.fontOutline)
			Bar.Text:SetTextColor(color.r, color.g, color.b)

			if db.text.enable then
				Bar.Text:Show()
			else
				Bar.Text:Hide()
			end
		end

		E:EnableMover(moverName)
	elseif frame:IsElementEnabled(elementName) then
		frame:DisableElement(elementName)

		swingbar:Hide()
		E:DisableMover(moverName)
	end
end
