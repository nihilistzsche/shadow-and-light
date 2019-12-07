﻿local SLE, T, E, L, V, P, G = unpack(select(2, ...))
local Armory = SLE:GetModule("Armory_Core")
-- local CA = SLE:GetModule("Armory_Character")
local M = E:GetModule("Misc")
local _G = _G
local STAT_CATEGORY_ATTRIBUTES = STAT_CATEGORY_ATTRIBUTES

local function configTable()
	if not SLE.initialized then return end

	E.Options.args.sle.args.modules.args.armory = {
		type = 'group',
		name = L["Armory Mode"],
		order = 1,
		childGroups = "tab",
		-- hidden = function() return not E.private.skins.blizzard.enable end,
		args = {
			info = {
				order = 1,
				type = "description",
				name = L["SLE_Armory_Info"].."\n",
				hidden = function() return not E.private.skins.blizzard.enable or (not E.private.skins.blizzard.character and not E.private.skins.blizzard.inspect) end,
			},
			CA_enable = {
				type = "toggle",
				name = L["Character Armory"],
				order = 10,
				desc = '',
				hidden = function() return not E.private.skins.blizzard.enable or not E.private.skins.blizzard.character end,
				get = function() return E.db.sle.armory.character.enable end,
				set = function(_, value)
					E.db.sle.armory.character.enable = value;
					SLE:GetModule("Armory_Character"):ToggleArmory();
					M:UpdatePageInfo(_G.CharacterFrame, "Character")
					if not E.db.general.itemLevel.displayCharacterInfo then M:ClearPageInfo(_G.CharacterFrame, "Character") end
				end,
			},
			IA_enable = {
				type = 'toggle',
				name = L["Inspect Armory"],
				order = 11,
				desc = '',
				hidden = function() return not E.private.skins.blizzard.enable or not E.private.skins.blizzard.inspect end,
				get = function() return E.db.sle.armory.inspect.enable end,
				set = function(_, value)
					E.db.sle.armory.inspect.enable = value;
					SLE:GetModule("Armory_Inspect"):ToggleArmory();
					M:UpdatePageInfo(_G.InspectFrame, "Inspect") --Putting this under the elv's option check just breaks the shit out of the frame
					if not E.db.general.itemLevel.displayInspectInfo then M:ClearPageInfo(_G.InspectFrame, "Inspect") end --Clear the infos if those are actually not supposed to be shown.
				end,
			},
			SA_enable = {
				type = 'toggle',
				name = STAT_CATEGORY_ATTRIBUTES,
				order = 12,
				desc = '',
				hidden = function() return not E.private.skins.blizzard.enable or not E.private.skins.blizzard.character end,
				disabled = function() return (SLE._Compatibility["DejaCharacterStats"] or not E.private.skins.blizzard.enable) end,
				get = function() return E.db.sle.armory.stats.enable end,
				set = function(_, value) E.db.sle.armory.stats.enable = value; SLE:GetModule("Armory_Stats"):ToggleArmory(); end
			},
			GoToElv = {
				order = 100,
				type = "execute",
				name = "ElvUI: "..L["Item Level"],
				func = function() E.Libs["AceConfigDialog"]:SelectGroup("ElvUI", "general", "blizzUIImprovements") end,
				hidden = function() 
					if not E.private.skins.blizzard.enable then return true end
					return not (E.private.skins.blizzard.character or E.private.skins.blizzard.inspect)
				end,
			},
			--In case some fucker disabled all the skins
			SkinsDisabled = {
				order = 500,
				type = "description",
				name = "|cffff0000 !!!|r "..L["SLE_Armory_SkinDisabled"].." |cffff0000 !!!|r",
				hidden = function() 
					if not E.private.skins.blizzard.enable then return false end
					return (E.private.skins.blizzard.character or E.private.skins.blizzard.inspect)
				end,
			},
			GoToElv_Skins = {
				order = 501,
				type = "execute",
				name = "ElvUI: "..L["Skins"],
				func = function() E.Libs["AceConfigDialog"]:SelectGroup("ElvUI", "skins") end,
				hidden = function() 
					if not E.private.skins.blizzard.enable then return false end
					return (E.private.skins.blizzard.character or E.private.skins.blizzard.inspect)
				end,
			},
		},
	}
end

T.tinsert(SLE.Configs, configTable)
