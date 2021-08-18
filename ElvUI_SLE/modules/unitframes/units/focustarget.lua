local SLE, T, E, L, V, P, G = unpack(select(2, ...))
local SUF = SLE.UnitFrames
local UF = E.UnitFrames

--GLOBALS: hooksecurefunc
local _G = _G

function SUF:ArrangeFocusTarget()
	local enableState = E.private.sle.module.shadows.enable and E.db.unitframe.units.focustarget.enable
	local frame = _G["ElvUF_FocusTarget"]
	if not frame then return end
	local db = E.db.sle.shadows.unitframes[frame.unitframeType]

	frame.SLLEGACY_ENHSHADOW = enableState and db.legacy or false
	frame.SLHEALTH_ENHSHADOW = enableState and db.health or false
	frame.SLPOWER_ENHSHADOW = enableState and db.power or false

	-- Health
	SUF:Configure_Health(frame)

	-- Power
	SUF:Configure_Power(frame)
end

function SUF:InitFocusTarget()
	hooksecurefunc(UF, 'Update_FocusTargetFrame', function(_, frame)
		if frame.unitframeType == 'focustarget' then SUF:ArrangeFocusTarget() end
	end)
end
