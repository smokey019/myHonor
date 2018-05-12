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
local frame, events = CreateFrame"Frame", {}

-- [[    Varibles, etc    ]] --
local showedUpdate, peopleUsing = false, { ["Character"] = {} }
local session, total, startTime
local HonorGained, SessionHonor, StartingHonor, BGHonor, LastBG, HonorBefore = 0, 0, 0, 0, 0, 0, 0, 0, 0
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
frame:RegisterEvent"PLAYER_LEAVING_WORLD"
frame:RegisterEvent"CHAT_MSG_COMBAT_HONOR_GAIN"
frame:RegisterEvent"COMBAT_TEXT_UPDATE"
frame:RegisterEvent"ADDON_LOADED"
frame:RegisterEvent"PLAYER_LOGOUT"
frame:RegisterEvent"CHAT_MSG_ADDON"
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

local function sendSync(prefix,msg)

local zoneType = select(2, IsInInstance())

	if zoneType == "pvp" or zoneType == "arena" then
		SendAddonMessage("myHonor", prefix .. ": " .. msg, "INSTANCE_CHAT")
	end
	
	if IsInGuild() then
		SendAddonMessage("myHonor", prefix .. ": " .. msg, "GUILD")
	end

end

function events:CHAT_MSG_ADDON(prefix, msg, channel, sender)

--print("Prefix: " .. prefix,"|Msg: '" .. msg,"'|Channel: " .. channel,"|Sender: " .. sender)

if (prefix=="myHonor") then

local AlreadyIn = false

for v in pairs(peopleUsing.Character) do
	if (sender:lower()==peopleUsing.Character[v]:lower()) then
		AlreadyIn = true
	end
end

if (AlreadyIn==false) then
	table.insert(peopleUsing.Character,sender)
	
	--ShortPrint(sender.." is using myHonor!")
end

	if (string.find(msg,"V")) then
		
		--is this a beta version? probably me sending out messages in which case we will ignore :p
		if (string.find(msg,"Beta")) then return end
		
		msg = string.gsub(msg,"V: ","")
		msg = string.gsub(msg," Release","")
		msg = string.gsub(msg," ","")
		
		local CurrentVersion = string.gsub(mhVersion," Release","")
		CurrentVersion = string.gsub(CurrentVersion," Beta","")
		CurrentVersion = string.gsub(CurrentVersion," ","")
		
		if (msg > CurrentVersion and showedUpdate == false) then
			ShortPrint("myHonor is out of date. Latest Version: " .. msg .. " You have: " .. mhVersion .. ".  Please visit Curse.com to get the latest version!")
			showedUpdate = true
		end
		
	end

end

end

function events:RAID_ROSTER_UPDATE()

--someone joined the raid (BG or otherwise) send a version sync
sendSync("V",mhVersion)

end

function events:ADDON_LOADED(arg1)

	if (VarisLoaded==true) then return end

	if (not myOptions) then myOptions = mhDefaults end
	if (not myStats) then myStats = StatDefaults end
	if not myOptions.ShowMinimapButton then HideMinimapButton() end
	if (not myOptions["DisplayBar"]) then myOptions["DisplayBar"] = mhDefaults["DisplayBar"] end
	VarisLoaded = true

	if (myOptions.BattleStatistics==false) then

		frame:UnregisterEvent"UPDATE_BATTLEFIELD_SCORE"

	end

end


function events:PLAYER_LEAVING_WORLD()

--self:SaveStuff()

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
	
	if (VarisLoaded==true) then
		frame:CheckDate()
	end
	
    HonorGained = (UnitHonor("player"))
	ZoneInfo = (select(2, IsInInstance()))
	local WorldBG_Active = (select(3, GetWorldPVPAreaInfo(2)))
	local ZoneName = GetZoneText()
	
	--in a BG
	if (ZoneInfo == "pvp" or ZoneName == "Tol Barad" and WorldBGActive == true or ZoneName == "Wintergrasp" and WorldBGActive == true) then
	
		InBG = 1
		myStats.BattleCount = tonumber(myStats.BattleCount) or 0
		myStats.BattleCount = myStats.BattleCount + 1
		BGCount = BGCount + 1
	    HonorGained_InBG = HonorGained_InBG + BGHonor
		 
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
		ConquestGained_InBG = ConquestGained_InBG + WGHonor
	    LastWG = WGHonor
	    WGHonor = 0
        ConquestBefore = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY)))
		
	elseif (ZoneInfo == "none") then --PROBABLY not in a BG
	
		if (InBG == 1) then
		
			LastBG = BGHonor
			BGHonor = 0
		
		end
		
		 InBG = 0
		 
		 
	  end
	
	if (FinallyLoaded==nil) then
		self:CheckHonor()
	end

if (IsAddonMessagePrefixRegistered("myHonor")==false) then
	RegisterAddonMessagePrefix("myHonor")
end

-- We're entering the world so send a Version Sync.
sendSync("V",mhVersion)

end

function frame:SaveStuff()
    myOptions.LastDate = date("%Y %j")
end

--[[
	Yesterday/today/reset stuff
]]--
function frame:CheckDate()
	if string.find(myOptions.LastDate, "/") then -- upgrade to new date style will force a new day
		myOptions.LastDate = "0001 "..date("%j")
	end
	
	local LastOnYear, LastOnDay = strsplit(" ",myOptions.LastDate)
	LastOnYear = tonumber( LastOnYear ) -- 4 digit year for leap year detection YYYY
	LastOnDay = tonumber( LastOnDay ) -- last on day of year as one number DDD
	local Year, Today = strsplit(" ",date("%Y %j")) -- need to supply the format so it is easibly useable Century   Day Of Year
	Year = tonumber( Year )
	Today = tonumber( Today )
	local Sameday, Yesterday = false, false
	
	if (LastOnYear == Year) and (LastOnDay == Today) then Sameday = true end --same day, don't change anything
	if (LastOnYear == Year) and (LastOnDay == Today-1) then Yesterday = true end --should be yesterday
	if (LastOnYear == Year - 1) and (Today == 1) then --First Day Of Year Checks
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

--[[
	When we get honor..
]]--
function events:COMBAT_TEXT_UPDATE(event,amount)

if (event=="HONOR_GAINED") then
	--print(amount)
	myStats.HonorToday = myStats.HonorToday + amount
	--SessionHonor = SessionHonor + amount
	--SessionCP = SessionCP + amount
end

end

--[[
function events:CHAT_MSG_CURRENCY(message,textmessage)

--print("1 "..message)
--print("2 "..textmessage)

	if (string.find(message,"Honor Points")) then

		--print("honor found")
		--message = textmessage
		--message = string.gsub(message,"You receive currency: Honor Points x","")
		--message = string.gsub(message,".","")
		
		local hnr1, hnr2 = strsplit("x",message)

		print (hnr1)
		print(hnr2)
		hnr2 = string.gsub(hnr2,".","")
		
		--print(message)
		--print(textmessage)
		
		SessionHonor = SessionHonor + hnr2

	end

--arg1 = strsplit(" ",arg1)

--for v in pairs(arg1) do
	--print(arg1[v])
--end

end
]]--

---------------------
--Currency updating--
---------------------
function events:CHAT_MSG_COMBAT_HONOR_GAIN()

HonorGained = (UnitHonor("player"))
ConqTotal = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY)))
local NegativeHP = (UnitHonor("player")) - StartingHonor
local NegativeCP = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY))) - StartingConquest

	if (FinallyLoaded==true) then
		
		SessionHonor = (UnitHonor("player")) - StartingHonor
		SessionCP = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY))) - StartingConquest
		
		SessionHKs = GetPVPLifetimeStats() - StartingHKs
		
		frame:CheckDate()
		
		TotalHKs = GetPVPLifetimeStats()
		ConqCap = (select(5,GetCurrencyInfo(CONQUEST_CURRENCY)))
		ConqCapTotal = (select(4,GetCurrencyInfo(CONQUEST_CURRENCY)))	

	end
	
	if (InBG==1) then
	
		BGHonor = (UnitHonor("player")) - HonorBefore
		BGConquest = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY))) - ConquestBefore
		
	end
	
	if (BGCount>=3) then
	
		AvgHonor = HonorGained_InBG / myStats.BattleCount   
		
	end
	
	if (WGCount>0) then
	
		AvgCP = ConquestGained_InBG / WGCount   
		
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
	
		--if (myStats.ConquestGoal==0) then return end
		
		if (myStats.ConquestGoal<=ConqTotal and myStats.ConquestGoal>0) then

			CombatText_AddMessage(mq_TXT_GOALMET, CombatText_StandardScroll, 1, 0.50, 0)
			RaidNotice_AddMessage(RaidWarningFrame, mq_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
			--DEFAULT_CHAT_FRAME:AddMessage(mq_TXT_GOALMET, 1, 0.50, 0)
			ShortPrint("** You've reached your conquest goal! **")
			ShortPrint("** You've reached your conquest goal! **")
			ShortPrint("** You've reached your conquest goal! **")
			ShortPrint("** You've reached your conquest goal! **")
			PlaySound(8959, "Master")
			myStats.ConquestGoal=0
			--Splashed = 1

		end

	--end

	if (myStats.ConquestGoal>0) then
		ConquestGoalFinal = myStats.ConquestGoal - ConqTotal
	end
	if (myStats.ConquestGoal<ConqTotal) then
		ConquestGoalFinal = GreenText("N/A")
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

	if (myOptions.Tooltip==1) then
	--honor
		myStats.HonorGoal = tonumber(msg)
		ShortPrint(mH_TXT_GOALSET..myStats.HonorGoal)
		Splashed = 0
		events:CHAT_MSG_COMBAT_HONOR_GAIN()
	
	else
	
	--conquest
		myStats.ConquestGoal = tonumber(msg)
		ShortPrint(mq_TXT_GOALSET..myStats.ConquestGoal)
		Splashed = 0
		events:CHAT_MSG_COMBAT_HONOR_GAIN()
	
	end
	
end

end

SLASH_AJBG1 = "/mh"
function SlashCmdList.AJBG(msg)
local cmd = msg:lower()

if (cmd=="ahquest") then

	if (mhAutoQuest==0) then
	
		mhAutoQuest = 1
		ShortPrint("Auto Quest Tracker Hider ON")
		
	else
	
		mhAutoQuest = 0
		ShortPrint("Auto Quest Tracker Hider OFF")
		
	end
	
elseif (cmd=="tt") then

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
	
elseif (cmd=="secret") then

	print("People using add-on:",table.getn(peopleUsing.Character))
	
elseif (cmd=="secret2") then

	for k,v in pairs(peopleUsing.Character) do
		print(k,v)
	end
	
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
	
	if(button == "LeftButton") then
		
		if (myOptions.Tooltip == 1) then
		
		myOptions.Tooltip = 2
		ShortPrint("Conquest will be displayed in the tooltip.")
		
	else
		
		myOptions.Tooltip = 1
		ShortPrint("Honor will be displayed in the tooltip.")
		
	end
		
	elseif(button == "RightButton") then
		
		if (mh_OptionsWindow:IsVisible()) then
		
			mh_OptionsWindow:Hide()
			
		else
		
			mh_OptionsWindow:Show()
		end

	end
	
	events:CHAT_MSG_COMBAT_HONOR_GAIN()
	
end

--[[

Initial Honor Check

--]]

function frame:CheckHonor()

	if (FinallyLoaded==nil) then

		StartingHonor = (UnitHonor("player"))
		StartingHKs, pRank = GetPVPLifetimeStats()
		StartingConquest = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY)))
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
			
		elseif (button == "LeftButton") then
		
			--[[if (myOptions.Tooltip==1) then
				
				myOptions.Tooltip = 2
				GameTooltip:Hide()

			elseif (myOptions.Tooltip==2) then
			
				myOptions.Tooltip = 1
				GameTooltip:Hide()
				
			end--]]
			
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
		
	if (which==1) then
		
		--diplay Honor Tooltip
	 	local AJBGtext
	 	local HonorGoalFinal, HonorGoalTime, ConquestGoalFinal, ConquestGoalTime = 0, 0, 0, 0
	 	local HonorGoalPercent = 0
		local _, _, WG_isActive, _, WG_startTime = GetWorldPVPAreaInfo(1)
		local _, _, TB_isActive, _, TB_startTime = GetWorldPVPAreaInfo(2)
		
     	if (InBG==1) then
		
     		InBGtext = RedText(GetZoneText())
			
     	else 
		
     		InBGtext = GreenText("None")
			
     	end

		if (SessionHonor>0) then
		
			if (startTime) then perHour = SessionHonor / sessionTime * 3600 end
			
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
		tt:AddDoubleLine(mH_TT_BGDMG,RedText(BGDmg)..dmgIcon)
		tt:AddDoubleLine(mH_TT_BGHEAL,GreenText(BGHeals)..healsIcon)
		tt:AddLine("---------------------------------")
		tt:AddDoubleLine(mH_TT_GOALTEXT,GetHighText(HonorGained).."/"..GreenText(myStats.HonorGoal).." "..PurpleText("\("..HonorGoalPercent.."\%\)"))
		tt:AddDoubleLine(mH_TT_GOALTEXT2,GetHighText(HonorGoalFinal))
		tt:AddDoubleLine(mH_TT_GOALTIME,GreenText(HonorGoalTime))
		tt:AddDoubleLine("People Using myHonor:",Should_I_Be_Red(table.getn(peopleUsing.Character)))
		tt:AddLine(" ")
		tt:AddLine("Left click to change tooltip display.")
		tt:AddLine(GreenText("Right click to open the options."),nil,nil,nil,1)
		tt:Show()
		
	else
	
	--display Conquest Tooltip
	local teamTwos, teamThrees, teamFives = {}, {}, {}
	local ConquestPossible
	local CurrentSeason = GetCurrentArenaSeason()
	local Team2Final, Team3Final, Team5Final
	local CPPercent, CPcapPercent = 0, 0
	
	teamTwos = { ["arenaName"] = "None", ["arenaRating"] = 0, ["PR"] = 0 }
	teamThrees = { ["arenaName"] = "None", ["arenaRating"] = 0, ["PR"] = 0 }
	teamFives = { ["arenaName"] = "None", ["arenaRating"] = 0, ["PR"] = 0 }
	
 	if (SessionCP>0) then
	
		if (startTime) then perHour = SessionCP / sessionTime * 3600 end
		
	else
	
		perHour = 0
		
	end
	
	--xpPerHour = 
	if (fname=="Alliance") then
	
        fname = BlueText(UnitFactionGroup("player"))
		
     else
	 
        fname = RedText(UnitFactionGroup("player"))
		
     end
	 
	 if (myStats.ConquestGoal>0) then
	 
	 	ConquestGoalFinal = myStats.ConquestGoal - ConqTotal
		ConquestGoalPercent = (ConqTotal/myStats.ConquestGoal) * 100
		ConquestGoalPercent = ("%.1f"):format(ConquestGoalPercent)
		CPcapPercent = (ConqCapTotal/ConqCap) * 100
		CPcapPercent = ("%.1f"):format(CPcapPercent)
		
		if (WGCount>0) then
		
			if (AvgCP>0) then
			
				ConquestGoalTime = ConquestGoalFinal/AvgCP
				ConquestGoalTime = format("%d",ConquestGoalTime)
				
			else
			
				ConquestGoalTime = "N/A"
				
			end
			
		else
		
			ConquestGoalTime = "N/A"
			
		end
		
	 else
	 
	 	ConquestGoalFinal = "N/A"
		
	 end
	 
	 if (myStats.ConquestGoal>0) then
	 
		if (ConqCap-ConqCapTotal>ConquestGoalFinal) then
		
			ConquestPossible = GreenText("Yes")
			
		else
		
			ConquestPossible = RedText("No")
			
		end
		
	 else
	 
	 	ConquestPossible = GreenText("N\/A")
		
	 end
	 
	 if (myStats.ConquestGoal==0) then
	 
	 ConquestGoalTime = GetHighText("N/A")
	 
	 elseif (myStats.ConquestGoal<ConqTotal) then
	 
		ConquestGoalFinal = GreenText("Goal Accomplished!")
		
	 end
	
	tt:AddLine(pname.." - "..rname.." ("..fname..") "..texIcon(conquestIcon))
	tt:AddLine(GetHighText(mqAddon.." v"..mqVersion))
	tt:AddLine(GetHighText(mC_TT_SEASONTXT..CurrentSeason))
	tt:AddLine(" ")
	tt:AddDoubleLine(mC_TT_STATUS,InBGtext)
	tt:AddLine("---------------------------------")
	tt:AddDoubleLine(GetHighText(mC_TT_WGSTATS))
	tt:AddDoubleLine(mC_TT_LASTWG,Should_I_Be_Red(LastBG))
	tt:AddDoubleLine(mC_TT_SESSIONCP,Should_I_Be_Red(SessionCP))
	tt:AddDoubleLine(mC_TT_AVGPTS,Should_I_Be_Red(format("%d",AvgCP)))
	tt:AddDoubleLine(mC_TT_BGCOUNT,Should_I_Be_Red(WGCount))
	tt:AddDoubleLine(mC_TT_CAP,GreenText(ConqTotal.."/"..ConqCap)..PurpleText(" \("..CPcapPercent.."\%\)"))
	tt:AddDoubleLine(mC_TT_PERHR,Should_I_Be_Red(format("%d",perHour)))
	tt:AddLine("----------------------------------")
	tt:AddDoubleLine(mC_TT_GOALTEXT,GreenText(ConqTotal.."/"..myStats.ConquestGoal)..PurpleText(" \("..ConquestGoalPercent.."\%\)"))
	tt:AddDoubleLine(mC_TT_GOALTEXT2,GetHighText(ConquestGoalFinal))
	tt:AddDoubleLine(mC_TT_GOALTIME,GreenText(ConquestGoalTime))
	tt:AddDoubleLine(mC_TT_POSSIBLE,ConquestPossible)
	tt:AddLine("---------------------------------")
	tt:AddLine(GetHighText("2v2 Team Statistics"))
	tt:AddLine("Team Rating: "..GetHighText(teamTwos["arenaRating"]))
	tt:AddLine("Conquest Point Cap: "..OrangeText(GetConqCap(teamTwos.PR)))
	tt:AddLine(GetHighText("3v3 Team Statistics"))
	tt:AddLine("Team Rating: "..GetHighText(teamThrees["arenaRating"]))
	tt:AddLine("Conquest Point Cap: "..OrangeText(GetConqCap(teamThrees.PR)))
	tt:AddLine(GetHighText("5v5 Team Statistics"))
	tt:AddLine("Team Rating: "..GetHighText(teamFives["arenaRating"]))
	tt:AddLine("Conquest Point Cap: "..OrangeText(GetConqCap(teamFives.PR)))
	tt:AddLine(" ")
	tt:AddLine("Left click to change tooltip display.")
	tt:AddLine(GreenText("Right click to open the options."),nil,nil,nil,1)
	tt:Show()
	
	end

end

function UpdateDisplayBar()

	HonorGained = (UnitHonor("player"))
	ConqTotal = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY)))
	local NegativeHP = (UnitHonor("player")) - StartingHonor
	local NegativeCP = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY))) - StartingConquest
	
	if (InBG==1) then
	
		BGHonor = (UnitHonor("player")) - HonorBefore
		BGConquest = (select(2,GetCurrencyInfo(CONQUEST_CURRENCY))) - ConquestBefore
		
	end
	
	if (BGCount>=3) then
	
		AvgHonor = HonorGained_InBG / myStats.BattleCount   
		
	end
	
	if (WGCount>0) then
	
		AvgCP = ConquestGained_InBG / WGCount   
		
	end

	if (Splashed==0) then

		if (myStats.HonorGoal==0) then return end
		
		if (myStats.HonorGoal<HonorGained) then

			RaidNotice_AddMessage(RaidWarningFrame, mH_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
			DEFAULT_CHAT_FRAME:AddMessage(mH_TXT_GOALMET, 1, 0.50, 0)
			PlaySound(8959, "Master")
			Splashed = 1

		end
	
		if (myStats.ConquestGoal==0) then return end
		
		if (myStats.ConquestGoal<ConqTotal) then

			CombatText_AddMessage(mq_TXT_GOALMET, CombatText_StandardScroll, 1, 0.50, 0)
			RaidNotice_AddMessage(RaidWarningFrame, mq_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
			DEFAULT_CHAT_FRAME:AddMessage(mq_TXT_GOALMET, 1, 0.50, 0)
			PlaySound(8959, "Master")
			Splashed = 1

		end

	end

	if (myStats.ConquestGoal>0) then
	
		ConquestGoalFinal = myStats.ConquestGoal - ConqTotal
		
	end
	
	if (myStats.ConquestGoal<ConqTotal) then
	
		ConquestGoalFinal = GreenText("N/A")
		
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
		dataobj.text = dataobj.text..Should_I_Be_Red(HonorGained).."/4000"..mH_BAR_ONE.." | "
		
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
	
	--Total Conquest
	if (myOptions["DisplayBar"][8]==true) then
	
		dataobj.value = ConqTotal
		dataobj.text = dataobj.text..Should_I_Be_Red(ConqTotal)..mH_BAR_EIGHT.." | "
		
	end
	
	--Conquest this Session
	if (myOptions["DisplayBar"][9]==true) then
	
		dataobj.value = SessionCP
		dataobj.text = dataobj.text..Should_I_Be_Red(SessionCP)..mH_BAR_NINE.." | "
		
	end
	
	--Conquest Goal Text
	if (myOptions["DisplayBar"][10]==true) then
	
		dataobj.value = ConquestGoalFinal
		dataobj.text = dataobj.text..ConquestGoalFinal..mH_BAR_TEN.." | "
		
	end
	
	--Average Conquest Points (if available)
	if (myOptions["DisplayBar"][11]==true) then
	
		dataobj.value = AvgCP
		dataobj.text = dataobj.text..Should_I_Be_Red(AvgCP)..mH_BAR_ELEVEN.." | "
		
	end
	
	--Conquest Cap info
	if (myOptions["DisplayBar"][12]==true) then
	
		dataobj.value = ConqCap
		dataobj.text = dataobj.text..Should_I_Be_Red(ConqCapTotal).."/"..GreenText(ConqCap)..mH_BAR_TWELVE.." |"
		
	end

end

--word, �opyright Smokey, 2015 All Rights Reserved, released under GNU License #3.
--if you're going to edit, at least give me credit or tell me about it and we can work together
--2015