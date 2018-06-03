--[[

-----------
--myHonor--
-----------

By Smokey - Area 52 Horde US

Website: www.smokeys.network
Twitch: www.twitch.tv/Smokey
 
--]]

--[[  
	Config 
--]]
local mhVersion = GetAddOnMetadata("myHonor", "Version") .. " Release"
local rawVersion = GetAddOnMetadata("myHonor", "Version")
local mhAddon = "myHonor"
local mqVersion = GetAddOnMetadata("myHonor", "Version") .. " Release"
local mqAddon = "myConquest"
local addon = ...
 
--[[
	Icons, graphics, etc..
--]]
local healsIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:1:20|t"
local dmgIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:22:41|t"
local honorIcon = "Interface\\PVPFrame\\PVP-Currency-"..UnitFactionGroup("player")
local conquestIcon = "Interface\\PVPFrame\\PVPCurrency-Conquest-"..UnitFactionGroup("player")

-- Initializing the object and frame
local OnEvent = function(self, event, ...) self[event](self, event, ...) end
local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("myHonor", {
	type = "data source",
	icon = honorIcon,
	label = "myHonor",
})
local myHonor = {}
local frame, events = CreateFrame("Frame", "myHonorFrame"),{}

-- [[    Varibles, etc    ]] --
local showedUpdate, peopleUsing = false, { ["Character"] = {} }
local session, total, startTime
local HonorGained, SessionHonor, BGHonor, LastBG, HonorBefore = 0, 0, 0, 0, 0, 0, 0, 0, 0
local ConqTotal, StartingConquest = 0, 0
local HonorGained_InBG = 0
local BGCount, AvgHonor, EnteredBG, InBG, perHour = 0,0,0,0,0
local FinallyLoaded, AddonLded = nil, nil
local VarisLoaded = false
local HonorGoalFinal, ConquestGoalFinal = 0, 0
local ConquestGoalPercent, HonorGoalPercent = 0, 0
local Splashed = 1
local StartingHKs, SessionHKs, TotalHKs = 0,0,0
local ConquestGained, SessionCP, BGConquest, LastBG, ConquestBefore = 0, 0, 0, 0, 0, 0, 0, 0
local ConquestGained_InBG = 0
local WGCount, AvgCP, EnteredWG, InWG, WGHonor = 0,0,0,0,0
local ConqCap, ConqCapTotal = 0, 0
local SpentPoints = 0
local TotalDmg, TotalHeals, BGDmg, BGHeals = 0,0,0,0
local silentTitan = 0

--[[
	Option defaults here
]]--
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
frame:RegisterEvent"PLAYER_ENTERING_WORLD"
frame:RegisterEvent"CHAT_MSG_COMBAT_HONOR_GAIN"
frame:RegisterEvent"ADDON_LOADED"
frame:RegisterEvent"PLAYER_LOGOUT"
frame:RegisterEvent"RAID_ROSTER_UPDATE"
frame:RegisterEvent"UPDATE_BATTLEFIELD_SCORE"
--frame:RegisterEvent"CHAT_MSG_CURRENCY"

--TitanPanel Registration

--self.registry = {id = "myHonor"}


--[[
	End Configuration
]]--

local function ShortPrint(text)
	DEFAULT_CHAT_FRAME:AddMessage("myHonor: " .. text, 0.41, 0.80, 0.94)
end





function events:ADDON_LOADED(arg1)

	if (VarisLoaded==true) then 
		return 
	end

	if (not myOptions) then 
		myOptions = mhDefaults 
	end
	if (not myStats) then 
		myStats = StatDefaults 
	end
	if not myOptions.ShowMinimapButton then 
		HideMinimapButton() 
	end
	if (not myOptions["DisplayBar"]) then 
		myOptions["DisplayBar"] = mhDefaults["DisplayBar"] 
	end
	VarisLoaded = true

	if (myOptions.BattleStatistics==false) then
		frame:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
	end
	
	if (type(myOptions.LastDate) ~= "table") then
		frame:SaveStuff()
	end
	
	UpdateDisplayBar();

end

function events:PLAYER_LOGOUT()
	frame:CheckDate()
	self:SaveStuff()
end

function events:PLAYER_ENTERING_WORLD()

	if (not myHonor) then
		myHonor = {}
	end
	
	if (not startTime) then
		startTime = time()
	end
	
	if (VarisLoaded==true) then
		frame:CheckDate()
	end
	
    --HonorGained = (UnitHonor("player"))
	ZoneInfo = (select(2, IsInInstance()))
	local WorldBG_Active = (select(3, GetWorldPVPAreaInfo(2)))
	local ZoneName = GetZoneText()
	
	--in a BG
	if (ZoneInfo == "pvp" or ZoneName == "Tol Barad" and WorldBGActive == true or ZoneName == "Wintergrasp" and WorldBGActive == true) then
	
		InBG = 1
		myStats.BattleCount = tonumber(myStats.BattleCount) or 0
		myStats.BattleCount = myStats.BattleCount + 1
		BGCount = BGCount + 1
	    
		 
		--moved this to "none" for sanity
	    --LastBG = BGHonor
	    --BGHonor = 0
		 
        HonorBefore = (UnitHonor("player"))
		
		--reset BG DMG
		BGDmg = 0
		BGHeals = 0
		 
	
	elseif (ZoneInfo == "arena") then
	  	 
		InWG = 1
		WGCount = WGCount + 1
	    LastWG = WGHonor
	    WGHonor = 0
        
		
	elseif (ZoneInfo == "none") then --PROBABLY not in a BG
	
		if (InBG == 1) then
			HonorGained_InBG = HonorGained_InBG + BGHonor
			LastBG = BGHonor
			BGHonor = 0
		
		end
		
		 InBG = 0
		 
		 
	  end
	
	if (FinallyLoaded==nil) then
		self:CheckHonor()
	end

end

function frame:SaveStuff()

	local _date = date("*t");
	_date["hour"] = nil;
	_date["min"] = nil;
	_date["wday"] = nil;
	_date["day"] = nil;
	_date["month"] = nil;
	_date["sec"] = nil;
	_date["isdst"] = nil;
	
	
    myOptions.LastDate = _date
end

--[[
	Yesterday/today/reset stuff
]]--
function frame:CheckDate()

	--local dayDelta = (difftime(time(),time(myOptions.LastDate)) / (24 * 60 * 60));
	--print(dayDelta)
	local currentDate = date("*t");
	
	

	if (currentDate.year > myOptions.LastDate.year or currentDate.yday > myOptions.LastDate.yday) then 
		
		print("currentYesterday ".. myStats.HonorYesterday .. " new " .. myStats.HonorToday)
		myStats.BattleCount = 0
		myStats.HonorYesterday = myStats.HonorToday
		myStats.HonorToday = 0
		frame:SaveStuff()
		return
	end
end


---------------------
--Currency updating--
---------------------
function events:CHAT_MSG_COMBAT_HONOR_GAIN(value)

	if (value == nil) then
		return
	end

	HonorGained = tonumber(string.match (value, "%d+"))
	--print(HonorGained)


	if (FinallyLoaded==true) then
		myStats.HonorToday = myStats.HonorToday + HonorGained
		SessionHonor = SessionHonor + HonorGained
		
		
		SessionHKs = GetPVPLifetimeStats() - StartingHKs
		
		frame:CheckDate()
		
		TotalHKs = GetPVPLifetimeStats()
	end
	
	if (InBG==1) then
		BGHonor = BGHonor + HonorGained	
	end
	
	if (BGCount>=3) then
		AvgHonor = HonorGained_InBG / myStats.BattleCount   
	end
	


	--if (Splashed==0) then

		--if (myStats.HonorGoal==0) then return end
		
	if (myStats.HonorGoal<=HonorGained and myStats.HonorGoal>0) then

		RaidNotice_AddMessage(RaidWarningFrame, mH_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
		--DEFAULT_CHAT_FRAME:AddMessage(mH_TXT_GOALMET, 1, 0.50, 0)
		ShortPrint("** You've reached your honor goal! **")
		ShortPrint("** You've reached your honor goal! **")
		ShortPrint("** You've reached your honor goal! **")
		ShortPrint("** You've reached your honor goal! **")
		PlaySound(8959, "Master")
		myStats.HonorGoal=0
		--Splashed = 1
	end

	if (myStats.HonorGoal>0) then
		HonorGoalFinal = myStats.HonorGoal - HonorGained
	else
		HonorGoalFinal = 0
	end
	
	if (myStats.HonorGoal<HonorGained) then
		HonorGoalFinal = GreenText("N/A")
	end
	
	UpdateDisplayBar();

	--TitanPanelButton_UpdateButton("myHonor");
	
end
  
function events:UPDATE_BATTLEFIELD_SCORE()
  
	local PlayerName, myFaction, myDamage, myHealing, playerWon = 0,0,0,0,0

	for i=1, GetNumBattlefieldScores() do

			local name, _, _, _, _, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)
					
			if (name==UnitName("player")) then
				PlayerName = name
				myFaction = faction
				myDamage = damageDone
				myHealing = healingDone
				break
			end
			
	end

	if (InBG==1) then

		BGDmg = myDamage
		BGHeals = myHealing

		if( GetBattlefieldWinner() ) then
		
			--playerWon = 1
			TotalDmg = tonumber(TotalDmg) or 0
			TotalDmg = tonumber(TotalDmg)+tonumber(BGDmg)
			TotalHeals = tonumber(TotalHeals) or 0
			TotalHeals = tonumber(TotalHeals)+tonumber(BGHeals)
			--BGDmg = 0
			--BGHeals = 0
			--InBG = 0
			
		end
	end
end


-- [[   The tooltip  ]] --
function dataobj.OnTooltipShow(tooltip)
	myHonorTT(tooltip,myOptions.Tooltip)
	tooltip.updateFunction = dataobj.OnTooltipShow
end

SLASH_GOAL1 = "/goal"
function SlashCmdList.GOAL(msg)

	local cmd = msg:lower()

	if (cmd=="") then
		ShortPrint(mH_TXT_GOALSYN)
		--elseif (tonumber(msg)>4000) then
		--ShortPrint(mH_TXT_GOALERR)
	else
		myStats.HonorGoal = tonumber(msg)
		ShortPrint(mH_TXT_GOALSET..myStats.HonorGoal)
		Splashed = 0
		events:CHAT_MSG_COMBAT_HONOR_GAIN()
	end
end

SLASH_AJBG1 = "/mh"
function SlashCmdList.AJBG(msg)
	local cmd = msg:lower()

	if (cmd=="tt") then
		if (myOptions.Tooltip==1) then
			myOptions.Tooltip = 2
		elseif (myOptions.Tooltip==2) then
			myOptions.Tooltip = 1
		end
	elseif (cmd=="mm") then
		ToggleMinimapButton()	
	elseif (cmd=="goal") then
		ShortPrint(mH_TXT_GOALSYN)
	elseif (cmd=="help" or cmd=="") then
		ShortPrint(mH_HELP_ONE)
		ShortPrint(mH_HELP_TWO)
		ShortPrint(mH_HELP_THREE)
		ShortPrint(mH_HELP_FIVE)
		ShortPrint(mH_HELP_SIX..mhVersion)	
	elseif (cmd=="bgstat") then
		frame:CallBGStat()		
	elseif (cmd=="reset") then
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
		ShortPrint(mH_HELP_SIX..mhVersion)
	end

end

function frame:CallBGStat()

	if (myOptions.BattleStatistics==true) then
		myOptions.BattleStatistics=false
		ShortPrint("No longer tracking BG damage or heals.")
		frame:UnregisterEvent"UPDATE_BATTLEFIELD_SCORE"
	else
		myOptions.BattleStatistics=true
		ShortPrint("BG Damage/heal tracking enabled.")
		frame:RegisterEvent"UPDATE_BATTLEFIELD_SCORE"
	end

end

--[[
When we click on the tool-bar:
--]]
function dataobj.OnClick(self, button)
	if(button == "RightButton") then
		if (mh_OptionsWindow:IsVisible()) then
			mh_OptionsWindow:Hide()
		else
			mh_OptionsWindow:Show()
		end
	end
end

--[[

Initial Honor Check

--]]

function frame:CheckHonor()

	if (FinallyLoaded==nil) then
		StartingHKs, pRank = GetPVPLifetimeStats()
		FinallyLoaded = true
	end

end

----------------------
--  Minimap Button  --
----------------------
do
	local dragMode = nil
	
	local function moveButton(self)
		if dragMode == "free" then
			local centerX, centerY = Minimap:GetCenter()
			local x, y = GetCursorPosition()
			x, y = x / self:GetEffectiveScale() - centerX, y / self:GetEffectiveScale() - centerY
			self:ClearAllPoints()
			self:SetPoint("CENTER", x, y)
		else
			local centerX, centerY = Minimap:GetCenter()
			local x, y = GetCursorPosition()
			x, y = x / self:GetEffectiveScale() - centerX, y / self:GetEffectiveScale() - centerY
			centerX, centerY = math.abs(x), math.abs(y)
			centerX, centerY = (centerX / math.sqrt(centerX^2 + centerY^2)) * 80, (centerY / sqrt(centerX^2 + centerY^2)) * 80
			centerX = x < 0 and -centerX or centerX
			centerY = y < 0 and -centerY or centerY
			self:ClearAllPoints()
			self:SetPoint("CENTER", centerX, centerY)
		end
	end

	local button = CreateFrame("Button", "myHonorButton", Minimap)
	button:SetHeight(32)
	button:SetWidth(32)
	button:SetFrameStrata("MEDIUM")
	button:SetPoint("CENTER", -65.35, -38.8)
	button:SetMovable(true)
	button:SetUserPlaced(true)
	
	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetTexture("Interface\\AddOns\\"..addon.."\\icon")
	icon:SetSize(20, 20)
	icon:SetPoint("TOPLEFT", 6, -6)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT")

	button:SetScript("OnMouseDown", function(self, button)
	
		if IsShiftKeyDown() and IsAltKeyDown() then
		
			dragMode = "free"
			self:SetScript("OnUpdate", moveButton)
			
		elseif IsShiftKeyDown() then
		
			dragMode = nil
			self:SetScript("OnUpdate", moveButton)			
			
		elseif (button == "RightButton") then
		
			if ( mh_OptionsWindow:IsVisible() ) then		
				mh_OptionsWindow:Hide();			
			else			
				mh_OptionsWindow:Show();
			end
		
		end
	end)
	button:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	button:SetScript("OnClick", function(self, button)
		
		
	end)
	button:SetScript("OnEnter", function(self)
										 
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		myHonorTT(GameTooltip,myOptions.Tooltip)
		GameTooltip:Show()
		
	end)
	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	function ToggleMinimapButton()

	myOptions.ShowMinimapButton = not myOptions.ShowMinimapButton
	
	if myOptions.ShowMinimapButton then
		button:Show()
		ShortPrint("Minimap button is now showing.")
	else
		button:Hide()
		ShortPrint("Minimap button is now hidden.")
	end
end
--[[

End minimap button

--]]

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

function HideMinimapButton()
	return button:Hide()
end
	
end

--[[

This function is to help reduce clutter, it selects which tooltip to be displaying: conquest or honor.
Added in 2.0.

]]--
function myHonorTT(tt,which)

	local hc, InBGtext, pname, rname, fname
	local sessionTime = time() - startTime
    pname = GetHighText(UnitName("player"))
    rname = GreenText(GetRealmName())
    fname = UnitFactionGroup("player")
    hc = GetPVPLifetimeStats()
	

	--diplay Honor Tooltip
	local AJBGtext
	local HonorGoalFinal, HonorGoalTime = 0, 0
	local HonorGoalPercent = 0
	local _, _, WG_isActive, _, WG_startTime = GetWorldPVPAreaInfo(1)
	local _, _, TB_isActive, _, TB_startTime = GetWorldPVPAreaInfo(2)
	
    if (InBG==1) then
    	InBGtext = RedText(GetZoneText())	
    else 	
    	InBGtext = GreenText("None")
    end

	if (SessionHonor>0) then
	
		if (startTime) then 
			perHour = SessionHonor / sessionTime * 3600 
		end
		
	else
		perHour = 0		
	end
	
	if (fname=="Alliance") then
    	fname = BlueText(UnitFactionGroup("player"))
    else
    	fname = RedText(UnitFactionGroup("player"))		
    end
	
	 if (myStats.HonorGoal>0) then
	 
		HonorGoalFinal = myStats.HonorGoal - HonorGained
		HonorGoalPercent = (HonorGained/myStats.HonorGoal) * 100
		HonorGoalPercent = ("%.1f"):format(HonorGoalPercent)
		
		if (BGCount>=2) then
		
			if (AvgHonor>0) then
			
				HonorGoalTime = HonorGoalFinal/AvgHonor
				HonorGoalTime = format("%d",HonorGoalTime)
				
				HonorGoalTime = tonumber(string.format("%." .. (1 or 0) .. "f", HonorGoalTime))
				
				if (HonorGoalTime<=0) then
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
	
	 if (myStats.HonorGoal==0) then
	 
	 	HonorGoalTime = GetHighText("N/A")
	 	HonorGoalPercent = 0
		
	 elseif (myStats.HonorGoal<HonorGained) then
	 
		HonorGoalFinal = GreenText("Goal Accomplished!")
		HonorGoalPercent = 0
		
	 end

	tt:AddLine(pname.." - "..rname.." ("..fname..") "..texIcon(honorIcon))
	tt:AddLine(GetHighText(mhAddon.." v"..mhVersion))
	tt:AddLine(" ")
	tt:AddDoubleLine(mH_TT_STATUS,InBGtext)
	tt:AddDoubleLine(mH_TT_TOTALPTS,GetHighText((UnitHonor("player")))..texIcon(honorIcon))
	tt:AddDoubleLine(mH_TT_TOTALHKS,GetHighText(hc))
	tt:AddDoubleLine(mH_TT_TODAYPTS,GetHighText(("%d"):format(myStats.HonorToday))..texIcon(honorIcon))
	tt:AddDoubleLine(mH_TT_YESPTS,GetHighText(("%d"):format(myStats.HonorYesterday))..texIcon(honorIcon))
	
	--[[
	
	not really relevant any more. so we'll comment it out
	
	if ( WG_isActive ) then
	
		tt:AddLine(GetHighText("Wintergrasp is in progress!"))
		
	elseif ( WG_startTime > 0 ) then
	
		tt:AddDoubleLine("Wintergrasp's next battle: ",GetHighText(SecondsToTime(WG_startTime)))
		
	end
	
	if ( TB_isActive ) then
	
		tt:AddLine(GetHighText("Tol Barad is in progress!"))
		
	elseif ( TB_startTime > 0 ) then
	
		tt:AddDoubleLine("Tol Barad's next battle: ",GetHighText(SecondsToTime(TB_startTime)))
		
	end
	
	--]]
	
	tt:AddLine("---------------------------------")
	tt:AddLine(GetHighText(mH_TT_SESSIONSTATS))
	tt:AddDoubleLine(mH_TT_SESSIONPTS,Should_I_Be_Red(format("%d",SessionHonor)))
	tt:AddDoubleLine(mH_TT_SESSIONHKS,Should_I_Be_Red(SessionHKs))
	tt:AddDoubleLine(mH_TT_TTLDMG,RedText(siUnits(TotalDmg))..dmgIcon)
	tt:AddDoubleLine(mH_TT_TTLHEAL,GreenText(siUnits(TotalHeals))..healsIcon)
	tt:AddLine("---------------------------------")
	tt:AddDoubleLine(GetHighText(mH_TT_BGSTATS))
	tt:AddDoubleLine(mH_TT_LASTBG,Should_I_Be_Red(LastBG))
	tt:AddDoubleLine(mH_TT_BGHONOR,Should_I_Be_Red(BGHonor))
	tt:AddDoubleLine(mH_TT_AVGHONOR,Should_I_Be_Red(format("%d",AvgHonor)))
	tt:AddDoubleLine(mH_TT_BGCOUNT,Should_I_Be_Red(BGCount))
	tt:AddDoubleLine(mH_TT_BGTTL,Should_I_Be_Red(myStats.BattleCount))
	tt:AddDoubleLine(mH_TT_PERHR,Should_I_Be_Red(format("%d",perHour)))
	tt:AddDoubleLine(mH_TT_BGDMG,RedText(siUnits(BGDmg))..dmgIcon)
	tt:AddDoubleLine(mH_TT_BGHEAL,GreenText(siUnits(BGHeals))..healsIcon)
	tt:AddLine("---------------------------------")
	tt:AddDoubleLine(mH_TT_GOALTEXT,GetHighText(HonorGained).."/"..GreenText(myStats.HonorGoal).." "..PurpleText("\("..HonorGoalPercent.."\%\)"))
	tt:AddDoubleLine(mH_TT_GOALTEXT2,GetHighText(HonorGoalFinal))
	tt:AddDoubleLine(mH_TT_GOALTIME,GreenText(HonorGoalTime))
	--tt:AddDoubleLine("People Using myHonor:",Should_I_Be_Red(table.getn(peopleUsing.Character)))
	tt:AddLine(" ")
	tt:AddLine(GreenText("Right click to open the options."),nil,nil,nil,1)
	tt:Show()

end

function UpdateDisplayBar()


	if (BGCount>=3) then
		AvgHonor = HonorGained_InBG / BGCount   		
	end
	
	if (Splashed==0) then

		if (myStats.HonorGoal==0) then 
			return 
		end
		
		if (myStats.HonorGoal<HonorGained) then
			RaidNotice_AddMessage(RaidWarningFrame, mH_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
			DEFAULT_CHAT_FRAME:AddMessage(mH_TXT_GOALMET, 1, 0.50, 0)
			PlaySound(8959)
			Splashed = 1
		end
	end


	if (myStats.HonorGoal>0) then
		HonorGoalFinal = myStats.HonorGoal - HonorGained
	else
		HonorGoalFinal = 0
	end
	
	if (myStats.HonorGoal<HonorGained) then
		HonorGoalFinal = GreenText("N/A")
	end
	
	dataobj.text = GoldText(" ")
	
	--Honor Gained
	if (myOptions["DisplayBar"][1]==true) then
	
		dataobj.value = HonorGained
		dataobj.text = dataobj.text..Should_I_Be_Red(myStats.HonorToday)..mH_BAR_ONE.." | "
		
	end
	
	--Session Honor
	if (myOptions["DisplayBar"][2]==true) then
	
		dataobj.value = SessionHonor
		dataobj.text = dataobj.text..Should_I_Be_Red(format("%d",SessionHonor))..mH_BAR_TWO.." | "
		
	end
	
	--Honor Goal Text
	if (myOptions["DisplayBar"][3]==true) then
	
		dataobj.value = HonorGoalFinal
		dataobj.text = dataobj.text..GetHighText(HonorGained).."/"..GreenText(myStats.HonorGoal)..mH_BAR_THREE.." | "
		
	end
	
	--Honor This Battleground
	if (myOptions["DisplayBar"][4]==true) then
	
		dataobj.value = BGHonor
		dataobj.text = dataobj.text..Should_I_Be_Red(BGHonor)..mH_BAR_FOUR.." | "
		
	end
	
	--Average Honor Per BG (if we can get it)
	if (myOptions["DisplayBar"][5]==true) then
	
		dataobj.value = AvgHonor
		dataobj.text = dataobj.text..Should_I_Be_Red(format("%d",AvgHonor))..mH_BAR_FIVE.." | "
		
	end
	
	--Total Honor Kills
	if (myOptions["DisplayBar"][6]==true) then
	
		dataobj.value = TotalHKs
		dataobj.text = dataobj.text..Should_I_Be_Red(TotalHKs)..mH_BAR_SIX.." | "
		
	end
	
	--Honor Kills this Session
	if (myOptions["DisplayBar"][7]==true) then
	
		dataobj.value = SessionHKs
		dataobj.text = dataobj.text..Should_I_Be_Red(SessionHKs)..mH_BAR_SEVEN.." | "
		
	end
	
	if (dataobj ~= nil) then
		if (dataobj.text ~= nil) then
			if (string.sub(dataobj.text, -1) == "|") then
				dataobj.text = dataobj.text:sub(1, -2)
			elseif (string.sub(dataobj.text, -2) == "| ") then
				dataobj.text = dataobj.text:sub(1, -3)
			end
		end
	end

end

--word, �opyright Smokey, 2015 All Rights Reserved, released under GNU License #3.
--if you're going to edit, at least give me credit or tell me about it and we can work together
--2015
