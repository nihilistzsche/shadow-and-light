local SLE, T, E, L, V, P, G = unpack(select(2, ...))
local SUF = SLE.UnitFrames
local UF = E.UnitFrames

--GLOBALS: hooksecurefunc
local _G = _G

function SUF:ArrangeRaid40()
	local enableState = E.private.sle.module.shadows.enable and E.db.unitframe.units.raid40.enable
	local header = _G['ElvUF_Raid40']

	for i = 1, header:GetNumChildren() do
		local group = select(i, header:GetChildren())

		for j = 1, group:GetNumChildren() do
			local frame = select(j, group:GetChildren())
			if not frame then return end
			local db = E.db.sle.shadows.unitframes.raid40

			frame.SLLEGACY_ENHSHADOW = enableState and db.legacy or false
			frame.SLHEALTH_ENHSHADOW = enableState and db.health or false
			frame.SLPOWER_ENHSHADOW = enableState and db.power or false

			-- Health
			SUF:Configure_Health(frame)

			-- Power
			SUF:Configure_Power(frame)
		end
	end
end

function SUF:InitRaid40()
	hooksecurefunc(UF, "CreateAndUpdateHeaderGroup", function(_, frame)
		if frame == 'raid40' then SUF:ArrangeRaid40() end
	end)
end
