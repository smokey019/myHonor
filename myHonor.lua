--[[

-----------
--myHonor--
-----------

By Smokey - Area 52 Horde US

Website: https://smokey.gg/
Twitch: https://twitch.tv/Smokey

--]]

--[[
	Config
--]]
local mhVersion = C_AddOns.GetAddOnMetadata("myHonor", "Version") .. " Release"
local rawVersion = C_AddOns.GetAddOnMetadata("myHonor", "Version")
local mhAddon = "myHonor"
local mqVersion = C_AddOns.GetAddOnMetadata("myHonor", "Version") .. " Release"
local mqAddon = "myConquest"
local addon = ...
local myHonor = LibStub("AceAddon-3.0"):NewAddon("myHonor")

--[[
	Icons, graphics, etc..
--]]
local healsIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:1:20|t"
local dmgIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:22:41|t"
local honorIcon = "Interface\\PVPFrame\\PVP-Currency-" .. UnitFactionGroup("player")
local conquestIcon = "Interface\\PVPFrame\\PVPCurrency-Conquest-" .. UnitFactionGroup("player")
MinimapButton = LibStub("LibDBIcon-1.0", true)

-- Initializing the object and frame
local frame, events = CreateFrame "Frame", {}

-- [[    Variables, etc    ]] --
local showedUpdate, peopleUsing = false, { ["Character"] = {} }
local session, total, startTime
local HonorGained, SessionHonor, StartingHonor, BGHonor, LastBG, HonorBefore = 0, 0, 0, 0, 0, 0, 0, 0, 0
local ConqTotal, StartingConquest = 0, 0
local HonorGained_InBG = 0
local BGCount, AvgHonor, EnteredBG, InBG, perHour = 0, 0, 0, 0, 0
local FinallyLoaded, AddonLded = nil, nil
local VarisLoaded = false
local HonorGoalFinal, ConquestGoalFinal = 0, 0
local ConquestGoalPercent, HonorGoalPercent = 0, 0
local Splashed = 1
local StartingHKs, SessionHKs, TotalHKs = 0, 0, 0
local ConquestGained, SessionCP, BGConquest, LastBG, ConquestBefore = 0, 0, 0, 0, 0, 0, 0, 0
local ConquestGained_InBG = 0
local WGCount, AvgCP, EnteredWG, InWG, WGHonor = 0, 0, 0, 0, 0
local ConqCap, ConqCapTotal = 0, 0
local SpentPoints = 0
local TotalDmg, TotalHeals, BGDmg, BGHeals = 0, 0, 0, 0
local silentTitan = 0

--[[
	Option defaults here
]] --
local mhDefaults = {
	ShowMinimapButton = true,
	TrackStats = true,
	BattleStatistics = true,
	LastDate = date("%Y %j"),
	Tooltip = 1,
	["DisplayBar"] = { [1] = true, [2] = true, [3] = false, [4] = false, [5] = false, [6] = false, [7] = false, [8] = false, [9] = false, [10] = false, [11] = false, [12] = false },
	LastVersion = rawVersion,
}
local StatDefaults = {
	BattleCount = 0,
	HonorGoal = 0,
	ConquestGoal = 0,
	HonorToday = 0,
	HonorYesterday = 0,
}


--[[
	Register Events
--]]
frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...);
end);
frame:RegisterEvent "PLAYER_ENTERING_WORLD"
frame:RegisterEvent "CHAT_MSG_COMBAT_HONOR_GAIN"
frame:RegisterEvent "ADDON_LOADED"
frame:RegisterEvent "PLAYER_LOGOUT"
frame:RegisterEvent "CHAT_MSG_ADDON"
frame:RegisterEvent "RAID_ROSTER_UPDATE"
frame:RegisterEvent "UPDATE_BATTLEFIELD_SCORE"

local function ShortPrint(text)
	DEFAULT_CHAT_FRAME:AddMessage("myHonor: " .. text, 0.41, 0.80, 0.94)
end

function events:CHAT_MSG_ADDON(prefix, msg, channel, sender)
	--print("Prefix: " .. prefix,"|Msg: '" .. msg,"'|Channel: " .. channel,"|Sender: " .. sender)

	if (prefix == "myHonor") then
		local AlreadyIn = false

		for v in pairs(peopleUsing.Character) do
			if (sender:lower() == peopleUsing.Character[v]:lower()) then
				AlreadyIn = true
			end
		end

		if (AlreadyIn == false) then
			table.insert(peopleUsing.Character, sender)

			--ShortPrint(sender.." is using myHonor!")
		end

		if (string.find(msg, "V")) then
			--is this a beta version? probably me sending out messages in which case we will ignore :p
			if (string.find(msg, "Beta")) then return end

			msg = string.gsub(msg, "V: ", "")
			msg = string.gsub(msg, " Release", "")
			msg = string.gsub(msg, " ", "")

			local CurrentVersion = string.gsub(mhVersion, " Release", "")
			CurrentVersion = string.gsub(CurrentVersion, " Beta", "")
			CurrentVersion = string.gsub(CurrentVersion, " ", "")

			if (msg > CurrentVersion and showedUpdate == false) then
				ShortPrint("myHonor is out of date. Latest Version: " ..
				msg .. " You have: " .. mhVersion .. ".  Please visit Curse.com to get the latest version!")
				showedUpdate = true
			end
		end
	end
end

function events:ADDON_LOADED(arg1)
	if (VarisLoaded == true) then return end

	if (not myOptions) then myOptions = mhDefaults end
	if (not myStats) then myStats = StatDefaults end
	if not myOptions.ShowMinimapButton then HideMinimapButton() end
	if (not myOptions["DisplayBar"]) then myOptions["DisplayBar"] = mhDefaults["DisplayBar"] end
	VarisLoaded = true

	if (myOptions.BattleStatistics == false) then
		frame:UnregisterEvent "UPDATE_BATTLEFIELD_SCORE"
	end
end

function events:PLAYER_LOGOUT()
	self:SaveStuff()
end

function events:PLAYER_ENTERING_WORLD()
	if (not myHonor) then
		myHonor = {}
	end

	if (not startTime) then
		startTime = time()
	end

	if (VarisLoaded == true) then
		frame:CheckDate()
	end

	HonorGained = (C_CurrencyInfo.GetCurrencyInfo(1792).quantity)
	ZoneInfo = (select(2, IsInInstance()))
	local ZoneName = GetZoneText()

	--in a BG
	if (ZoneInfo == "pvp") then
		InBG = 1
		myStats.BattleCount = tonumber(myStats.BattleCount) or 0
		myStats.BattleCount = myStats.BattleCount + 1
		BGCount = BGCount + 1
		HonorGained_InBG = HonorGained_InBG + BGHonor

		--moved this to "none" for sanity
		--LastBG = BGHonor
		--BGHonor = 0

		HonorBefore = (C_CurrencyInfo.GetCurrencyInfo(1792).quantity)

		--reset BG DMG
		BGDmg = 0
		BGHeals = 0
	elseif (ZoneInfo == "arena") then
		InWG = 1
		WGCount = WGCount + 1
		ConquestGained_InBG = ConquestGained_InBG + WGHonor
		LastWG = WGHonor
		WGHonor = 0
		ConquestBefore = C_CurrencyInfo.GetCurrencyInfo(1602).quantity
	elseif (ZoneInfo == "none") then --PROBABLY not in a BG
		if (InBG == 1) then
			LastBG = BGHonor
			BGHonor = 0
		end

		InBG = 0
	end

	if (FinallyLoaded == nil) then
		self:CheckHonor()
	end
end

function frame:SaveStuff()
	myOptions.LastDate = date("%Y %j")
end

--[[
	Yesterday/today/reset stuff
]]                                            --
function frame:CheckDate()
	if string.find(myOptions.LastDate, "/") then -- upgrade to new date style will force a new day
		myOptions.LastDate = "0001 " .. date("%j")
	end

	local LastOnYear, LastOnDay = strsplit(" ", myOptions.LastDate)
	LastOnYear = tonumber(LastOnYear)            -- 4 digit year for leap year detection YYYY
	LastOnDay = tonumber(LastOnDay)              -- last on day of year as one number DDD
	local Year, Today = strsplit(" ", date("%Y %j")) -- need to supply the format so it is easibly useable Century   Day Of Year
	Year = tonumber(Year)
	Today = tonumber(Today)
	local Sameday, Yesterday = false, false

	if (LastOnYear == Year) and (LastOnDay == Today) then Sameday = true end                         --same day, don't change anything
	if (LastOnYear == Year) and (LastOnDay == Today - 1) then Yesterday = true end                   --should be yesterday
	if (LastOnYear == Year - 1) and (Today == 1) then                                                --First Day Of Year Checks
		if (LastOnDay == 366) and (math.floor(LastOnYear / 4) == LastOnYear / 4) then Yesterday = true end --Leap Year Last Day
		if (LastOnDay == 365) and (math.floor(LastOnYear / 4) ~= LastOnYear / 4) then Yesterday = true end --Non Leap Year Last Day
	end

	if Sameday then return end

	if Yesterday then
		myStats.BattleCount = 0
		myStats.HonorYesterday = myStats.HonorToday
		myStats.HonorToday = 0
		return
	end

	myStats.BattleCount = 0
	myStats.HonorYesterday = 0
	myStats.HonorToday = 0
end

---------------------
--Currency updating--
---------------------
function events:CHAT_MSG_COMBAT_HONOR_GAIN(value)
	HonorGained = tonumber(string.match(value, "%d+"))
	myStats.HonorToday = myStats.HonorToday + HonorGained
	ConqTotal = C_CurrencyInfo.GetCurrencyInfo(1602).quantity
	local NegativeCP = C_CurrencyInfo.GetCurrencyInfo(1602).quantity - StartingConquest

	if (FinallyLoaded == true) then
		SessionHonor = SessionHonor + HonorGained
		SessionCP = C_CurrencyInfo.GetCurrencyInfo(1602).quantity - StartingConquest

		SessionHKs = (select(1, GetPVPLifetimeStats())) - StartingHKs

		frame:CheckDate()

		TotalHKs = (select(1, GetPVPLifetimeStats()))
		ConqCap = (select(5, C_CurrencyInfo.GetCurrencyInfo(1602)))
		ConqCapTotal = (select(4, C_CurrencyInfo.GetCurrencyInfo(1602)))
	end

	if (InBG == 1) then
		BGHonor = BGHonor + HonorGained
		BGConquest = C_CurrencyInfo.GetCurrencyInfo(1602).quantity - ConquestBefore
	end

	if (BGCount >= 3) then
		AvgHonor = HonorGained_InBG / myStats.BattleCount
	end

	if (WGCount > 0) then
		AvgCP = ConquestGained_InBG / WGCount
	end

	if (myStats.HonorGoal <= HonorGained and myStats.HonorGoal > 0) then
		RaidNotice_AddMessage(RaidWarningFrame, mH_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
		--DEFAULT_CHAT_FRAME:AddMessage(mH_TXT_GOALMET, 1, 0.50, 0)
		ShortPrint("** You've reached your honor goal! **")
		ShortPrint("** You've reached your honor goal! **")
		ShortPrint("** You've reached your honor goal! **")
		ShortPrint("** You've reached your honor goal! **")
		PlaySound(8959, "Master")
		myStats.HonorGoal = 0
		--Splashed = 1
	end

	if (myStats.ConquestGoal <= ConqTotal and myStats.ConquestGoal > 0) then
		CombatText_AddMessage(mq_TXT_GOALMET, CombatText_StandardScroll, 1, 0.50, 0)
		RaidNotice_AddMessage(RaidWarningFrame, mq_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
		--DEFAULT_CHAT_FRAME:AddMessage(mq_TXT_GOALMET, 1, 0.50, 0)
		ShortPrint("** You've reached your conquest goal! **")
		ShortPrint("** You've reached your conquest goal! **")
		ShortPrint("** You've reached your conquest goal! **")
		ShortPrint("** You've reached your conquest goal! **")
		PlaySound(8959, "Master")
		myStats.ConquestGoal = 0
		--Splashed = 1
	end

	if (myStats.ConquestGoal > 0) then
		ConquestGoalFinal = myStats.ConquestGoal - ConqTotal
	end
	if (myStats.ConquestGoal < ConqTotal) then
		ConquestGoalFinal = GreenText("N/A")
	end

	if (myStats.HonorGoal > 0) then
		HonorGoalFinal = myStats.HonorGoal - HonorGained
	else
		HonorGoalFinal = 0
	end

	if (myStats.HonorGoal < HonorGained) then
		HonorGoalFinal = GreenText("N/A")
	end

	UpdateDisplayBar();
end

function events:UPDATE_BATTLEFIELD_SCORE()
	local PlayerName, myFaction, myDamage, myHealing, playerWon = 0, 0, 0, 0, 0

	for i = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)

		if (name == UnitName("player")) then
			PlayerName = name
			myFaction = faction
			myDamage = damageDone
			myHealing = healingDone
		end
	end

	if (InBG == 1) then
		BGDmg = myDamage
		BGHeals = myHealing

		if (GetBattlefieldWinner()) then
			--playerWon = 1
			TotalDmg = tonumber(TotalDmg) or 0
			TotalDmg = tonumber(TotalDmg) + tonumber(BGDmg)
			TotalHeals = tonumber(TotalHeals) or 0
			TotalHeals = tonumber(TotalHeals) + tonumber(BGHeals)
			--BGDmg = 0
			--BGHeals = 0
			--InBG = 0
		end
	end
end

SLASH_GOAL1 = "/goal"
function SlashCmdList.GOAL(msg)
	local cmd = msg:lower()

	if (cmd == "") then
		ShortPrint(mH_TXT_GOALSYN)

		--elseif (tonumber(msg)>4000) then

		--ShortPrint(mH_TXT_GOALERR)
	else
		if (myOptions.Tooltip == 1) then
			--honor
			myStats.HonorGoal = tonumber(msg)
			ShortPrint(mH_TXT_GOALSET .. myStats.HonorGoal)
			Splashed = 0
			--events:CHAT_MSG_COMBAT_HONOR_GAIN()
		else
			--conquest
			myStats.ConquestGoal = tonumber(msg)
			ShortPrint(mq_TXT_GOALSET .. myStats.ConquestGoal)
			Splashed = 0
			--events:CHAT_MSG_COMBAT_HONOR_GAIN()
		end
	end
end

SLASH_AJBG1 = "/mh"
function SlashCmdList.AJBG(msg)
	local cmd = msg:lower()

	if (cmd == "ahquest") then
		if (mhAutoQuest == 0) then
			mhAutoQuest = 1
			ShortPrint("Auto Quest Tracker Hider ON")
		else
			mhAutoQuest = 0
			ShortPrint("Auto Quest Tracker Hider OFF")
		end
	elseif (cmd == "tt") then
		if (myOptions.Tooltip == 1) then
			myOptions.Tooltip = 2
		elseif (myOptions.Tooltip == 2) then
			myOptions.Tooltip = 1
		end
	elseif (cmd == "mm") then
		ToggleMinimapButton()
	elseif (cmd == "goal") then
		ShortPrint(mH_TXT_GOALSYN)
	elseif (cmd == "help" or cmd == "") then
		ShortPrint(mH_HELP_ONE)
		ShortPrint(mH_HELP_TWO)
		ShortPrint(mH_HELP_THREE)
		ShortPrint(mH_HELP_FIVE)
		ShortPrint(mH_HELP_SIX .. mhVersion)
	elseif (cmd == "secret") then
		print("People using add-on:", (#peopleUsing.Character))
	elseif (cmd == "secret2") then
		for k, v in pairs(peopleUsing.Character) do
			print(k, v)
		end
	elseif (cmd == "bgstat") then
		frame:CallBGStat()
	elseif (cmd == "reset") then
		SessionHonor = 0
		BGHonor = 0
		myStats.BattleCount = 0
		AvgHonor = 0
		BGCount = 0
		LastBG = 0
		TotalDmg = 0
		TotalHeals = 0
	else
		ShortPrint(mH_HELP_ONE)
		ShortPrint(mH_HELP_TWO)
		ShortPrint(mH_HELP_THREE)
		ShortPrint(mH_HELP_FOUR)
		ShortPrint(mH_HELP_FIVE)
		ShortPrint(mH_HELP_SIX .. mhVersion)
	end
end

function frame:CallBGStat()
	if (myOptions.BattleStatistics == true) then
		myOptions.BattleStatistics = false
		ShortPrint("No longer tracking BG damage or heals.")
		frame:UnregisterEvent "UPDATE_BATTLEFIELD_SCORE"
	else
		myOptions.BattleStatistics = true
		ShortPrint("BG Damage/heal tracking enabled.")
		frame:RegisterEvent "UPDATE_BATTLEFIELD_SCORE"
	end
end

--[[

Initial Honor Check

--]]

function frame:CheckHonor()
	if (FinallyLoaded == nil) then
		StartingHonor = (C_CurrencyInfo.GetCurrencyInfo(1792).quantity)
		StartingHKs, pRank = (select(1, GetPVPLifetimeStats()))
		StartingConquest = C_CurrencyInfo.GetCurrencyInfo(1602).quantity
		FinallyLoaded = true
	end
end

--[[

Toggle Honor Tooltip

--]]

function ToggleHonor()
	if (myOptions.Tooltip == 1) then
		myOptions.Tooltip = 2
		ShortPrint("Conquest will be displayed in the tooltip.")
	else
		myOptions.Tooltip = 1
		ShortPrint("Honor will be displayed in the tooltip.")
	end
end

--[[

This function is to help reduce clutter, it selects which tooltip to be displaying: conquest or honor.
Added in 2.0.

]] --
function myHonorTT(tt, which)
	local hc, InBGtext, pname, rname, fname
	local sessionTime = time() - startTime
	pname = GetHighText(UnitName("player"))
	rname = GreenText(GetRealmName())
	fname = UnitFactionGroup("player")
	hc = (select(1, GetPVPLifetimeStats()))

	if (which == 1) then
		--diplay Honor Tooltip
		local AJBGtext
		local HonorGoalFinal, HonorGoalTime = 0, 0
		local HonorGoalPercent = 0

		if (InBG == 1) then
			InBGtext = RedText(GetZoneText())
		else
			InBGtext = GreenText("None")
		end

		if (SessionHonor > 0) then
			if (startTime) then perHour = SessionHonor / sessionTime * 3600 end
		else
			perHour = 0
		end

		if (fname == "Alliance") then
			fname = BlueText(UnitFactionGroup("player"))
		else
			fname = RedText(UnitFactionGroup("player"))
		end

		if (myStats.HonorGoal > 0) then
			HonorGoalFinal = myStats.HonorGoal - HonorGained
			HonorGoalPercent = (HonorGained / myStats.HonorGoal) * 100
			HonorGoalPercent = ("%.1f"):format(HonorGoalPercent)

			if (BGCount >= 2) then
				if (AvgHonor > 0) then
					HonorGoalTime = HonorGoalFinal / AvgHonor
					HonorGoalTime = format("%d", HonorGoalTime)

					HonorGoalTime = tonumber(string.format("%." .. (1 or 0) .. "f", HonorGoalTime))

					if (HonorGoalTime <= 0) then
						HonorGoalTime = "N/A"
					end
				else
					HonorGoalTime = "Play at least 2 BGs"
				end
			else
				HonorGoalTime = "Play at least 2 BGs"
			end
		else
			HonorGoalFinal = "Play at least 2 BGs"
		end

		if (myStats.HonorGoal == 0) then
			HonorGoalTime = GetHighText("N/A")
			HonorGoalPercent = 0
		elseif (myStats.HonorGoal < HonorGained) then
			HonorGoalFinal = GreenText("Goal Accomplished!")
			HonorGoalPercent = 0
		end

		tt:AddLine(pname .. " - " .. rname .. " (" .. fname .. ") " .. texIcon(honorIcon))
		tt:AddLine(GetHighText(mhAddon .. " v" .. mhVersion))
		tt:AddLine(" ")
		tt:AddDoubleLine(mH_TT_STATUS, format_number(InBGtext))
		tt:AddDoubleLine(mH_TT_TOTALHKS, GetHighText(format_number(hc)))
		tt:AddDoubleLine(mH_TT_TOTALPTS,
			GetHighText(format_number(C_CurrencyInfo.GetCurrencyInfo(1792).quantity)) .. texIcon(honorIcon))
		tt:AddDoubleLine(mH_TT_TODAYPTS,
			GetHighText(format_number(("%d"):format(myStats.HonorToday))) .. texIcon(honorIcon))
		tt:AddDoubleLine(mH_TT_YESPTS,
			GetHighText(format_number(("%d"):format(myStats.HonorYesterday))) .. texIcon(honorIcon))
		tt:AddLine("---------------------------------")
		tt:AddLine(GetHighText(mH_TT_SESSIONSTATS))
		tt:AddDoubleLine(mH_TT_SESSIONPTS, Should_I_Be_Red(format("%d", SessionHonor)))
		tt:AddDoubleLine(mH_TT_SESSIONHKS, Should_I_Be_Red(SessionHKs))
		tt:AddDoubleLine(mH_TT_TTLDMG, RedText(siUnits(TotalDmg)) .. dmgIcon)
		tt:AddDoubleLine(mH_TT_TTLHEAL, GreenText(siUnits(TotalHeals)) .. healsIcon)
		tt:AddLine("---------------------------------")
		tt:AddDoubleLine(GetHighText(mH_TT_BGSTATS))
		tt:AddDoubleLine(mH_TT_LASTBG, Should_I_Be_Red(LastBG))
		tt:AddDoubleLine(mH_TT_BGHONOR, Should_I_Be_Red(BGHonor))
		tt:AddDoubleLine(mH_TT_AVGHONOR, Should_I_Be_Red(format("%d", AvgHonor)))
		tt:AddDoubleLine(mH_TT_BGCOUNT, Should_I_Be_Red(BGCount))
		tt:AddDoubleLine(mH_TT_BGTTL, Should_I_Be_Red(myStats.BattleCount))
		tt:AddDoubleLine(mH_TT_PERHR, Should_I_Be_Red(format_number(format("%d", perHour))))
		tt:AddDoubleLine(mH_TT_BGDMG, RedText(siUnits(BGDmg)) .. dmgIcon)
		tt:AddDoubleLine(mH_TT_BGHEAL, GreenText(siUnits(BGHeals)) .. healsIcon)
		tt:AddLine("---------------------------------")
		tt:AddDoubleLine(mH_TT_GOALTEXT,
			GetHighText(HonorGained) .. "/" .. GreenText(myStats.HonorGoal) ..
			" " .. PurpleText("(" .. HonorGoalPercent .. "%)"))
		tt:AddDoubleLine(mH_TT_GOALTEXT2, GetHighText(HonorGoalFinal))
		tt:AddDoubleLine(mH_TT_GOALTIME, GreenText(HonorGoalTime))
		tt:AddDoubleLine("People Using myHonor:", Should_I_Be_Red(table.getn(peopleUsing.Character)))
		tt:AddLine(" ")
		tt:AddLine("Left click to change tooltip display.")
		tt:AddLine(GreenText("Right click to open the options."), nil, nil, nil, 1)
		tt:Show()
	else
		--display Conquest Tooltip
		local teamTwos, teamThrees, teamFives = GetPersonalRatedInfo(1), GetPersonalRatedInfo(2), GetPersonalRatedInfo(3)
		local ConquestPossible
		local CurrentSeason = GetCurrentArenaSeason()
		local CPPercent, CPcapPercent = 0, 0

		if (CurrentSeason == 0) then
			CurrentSeason = "Inactive"
		end

		if (SessionCP > 0) then
			if (startTime) then perHour = SessionCP / sessionTime * 3600 end
		else
			perHour = 0
		end

		if (fname == "Alliance") then
			fname = BlueText(UnitFactionGroup("player"))
		else
			fname = RedText(UnitFactionGroup("player"))
		end

		if (myStats.ConquestGoal > 0) then
			ConquestGoalFinal = myStats.ConquestGoal - ConqTotal
			ConquestGoalPercent = (ConqTotal / myStats.ConquestGoal) * 100
			ConquestGoalPercent = ("%.1f"):format(ConquestGoalPercent)
			CPcapPercent = (ConqCapTotal / ConqCap) * 100
			CPcapPercent = ("%.1f"):format(CPcapPercent)

			if (WGCount > 0) then
				if (AvgCP > 0) then
					ConquestGoalTime = ConquestGoalFinal / AvgCP
					ConquestGoalTime = format("%d", ConquestGoalTime)
				else
					ConquestGoalTime = "N/A"
				end
			else
				ConquestGoalTime = "N/A"
			end
		else
			ConquestGoalFinal = "N/A"
		end

		if (myStats.ConquestGoal == 0) then
			ConquestGoalTime = GetHighText("N/A")
		elseif (myStats.ConquestGoal < ConqTotal) then
			ConquestGoalFinal = GreenText("Goal Accomplished!")
		end

		tt:AddLine(pname .. " - " .. rname .. " (" .. fname .. ") " .. texIcon(conquestIcon))
		tt:AddLine(GetHighText(mqAddon .. " v" .. mqVersion))
		tt:AddLine(GetHighText(mC_TT_SEASONTXT .. CurrentSeason))
		tt:AddLine(" ")
		tt:AddLine("---------------------------------")
		tt:AddDoubleLine(GetHighText(mC_TT_WGSTATS))
		tt:AddDoubleLine(mC_TT_LASTWG, Should_I_Be_Red(LastBG))
		tt:AddDoubleLine(mC_TT_SESSIONCP, Should_I_Be_Red(SessionCP))
		tt:AddDoubleLine(mC_TT_AVGPTS, Should_I_Be_Red(format("%d", AvgCP)))
		tt:AddDoubleLine(mC_TT_BGCOUNT, Should_I_Be_Red(WGCount))
		tt:AddDoubleLine(mC_TT_CAP, GreenText(ConqTotal .. "/" .. ConqCap) .. PurpleText(" (" .. CPcapPercent .. "%)"))
		tt:AddDoubleLine(mC_TT_PERHR, Should_I_Be_Red(format("%d", perHour)))
		tt:AddLine("----------------------------------")
		tt:AddDoubleLine(mC_TT_GOALTEXT,
			GreenText(ConqTotal .. "/" .. myStats.ConquestGoal) .. PurpleText(" (" .. ConquestGoalPercent .. "%)"))
		tt:AddDoubleLine(mC_TT_GOALTEXT2, GetHighText(ConquestGoalFinal))
		tt:AddDoubleLine(mC_TT_GOALTIME, GreenText(ConquestGoalTime))
		tt:AddLine("---------------------------------")
		tt:AddLine(GetHighText("2v2 Team Statistics"))
		tt:AddLine("Team Rating: " .. GetHighText((select(1, teamTwos))))
		tt:AddLine(GetHighText("3v3 Team Statistics"))
		tt:AddLine("Team Rating: " .. GetHighText((select(1, teamThrees))))
		tt:AddLine(GetHighText("5v5 Team Statistics"))
		tt:AddLine("Team Rating: " .. GetHighText((select(1, teamFives))))
		tt:AddLine(" ")
		tt:AddLine("Left click to change tooltip display.")
		tt:AddLine(GreenText("Right click to open the options."), nil, nil, nil, 1)
		tt:Show()
	end
end

function UpdateDisplayBar()
	HonorGained = (C_CurrencyInfo.GetCurrencyInfo(1792).quantity)
	ConqTotal = C_CurrencyInfo.GetCurrencyInfo(1602).quantity
	local NegativeHP = (C_CurrencyInfo.GetCurrencyInfo(1792).quantity) - StartingHonor
	local NegativeCP = C_CurrencyInfo.GetCurrencyInfo(1602).quantity - StartingConquest

	if (InBG == 1) then
		BGHonor = (C_CurrencyInfo.GetCurrencyInfo(1792).quantity) - HonorBefore
		BGConquest = C_CurrencyInfo.GetCurrencyInfo(1602).quantity - ConquestBefore
	end

	if (BGCount >= 3) then
		AvgHonor = HonorGained_InBG / myStats.BattleCount
	end

	if (WGCount > 0) then
		AvgCP = ConquestGained_InBG / WGCount
	end

	if (Splashed == 0) then
		if (myStats.HonorGoal == 0) then return end

		if (myStats.HonorGoal < HonorGained) then
			RaidNotice_AddMessage(RaidWarningFrame, mH_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
			DEFAULT_CHAT_FRAME:AddMessage(mH_TXT_GOALMET, 1, 0.50, 0)
			PlaySound(8959, "Master")
			Splashed = 1
		end

		if (myStats.ConquestGoal == 0) then return end

		if (myStats.ConquestGoal < ConqTotal) then
			CombatText_AddMessage(mq_TXT_GOALMET, CombatText_StandardScroll, 1, 0.50, 0)
			RaidNotice_AddMessage(RaidWarningFrame, mq_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
			DEFAULT_CHAT_FRAME:AddMessage(mq_TXT_GOALMET, 1, 0.50, 0)
			PlaySound(8959, "Master")
			Splashed = 1
		end
	end

	if (myStats.ConquestGoal > 0) then
		ConquestGoalFinal = myStats.ConquestGoal - ConqTotal
	end

	if (myStats.ConquestGoal < ConqTotal) then
		ConquestGoalFinal = GreenText("N/A")
	end

	if (myStats.HonorGoal > 0) then
		HonorGoalFinal = myStats.HonorGoal - HonorGained
	else
		HonorGoalFinal = 0
	end

	if (myStats.HonorGoal < HonorGained) then
		HonorGoalFinal = GreenText("N/A")
	end
end

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("myHonor", {
	type = "data source",
	text = "myHonor",
	icon = honorIcon,
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			ToggleHonor()
		elseif btn == "RightButton" then
			if mh_OptionsWindow:IsShown() then
				mh_OptionsWindow:Hide()
			else
				mh_OptionsWindow:Show()
			end
		end
	end,

	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end

		myHonorTT(tooltip, myOptions.Tooltip)
	end,
})

function myHonor:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("myHonorMinimapPOS", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	MinimapButton:Register("myHonor", miniButton, self.db.profile.minimap)
end

MinimapButton:Show("myHonor")


--word, ©opyright Smokey, 2010-2020 All Rights Reserved, released under MIT License.
--if you're going to edit, at least give me credit or tell me about it and we can work together
--2010-2020
