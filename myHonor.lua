--[[
-----------
--myHonor--
-----------

By Smokey - Area 52 Horde US

Website: https://smokey.gg/
Twitch: https://twitch.tv/Smokey
--]]

-- Core addon initialization
local addon = ...
local myHonor = LibStub("AceAddon-3.0"):NewAddon("myHonor")

-- Version and metadata
local mhVersion = C_AddOns.GetAddOnMetadata("myHonor", "Version") .. " Release"
local rawVersion = C_AddOns.GetAddOnMetadata("myHonor", "Version")
local mhAddon = "myHonor"
local mqVersion = C_AddOns.GetAddOnMetadata("myHonor", "Version") .. " Release"
local mqAddon = "myConquest"

-- UI Icons and graphics
local ICONS = {
    heals = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:1:20|t",
    damage = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:22:41|t",
    honor = "Interface\\PVPFrame\\PVP-Currency-" .. UnitFactionGroup("player"),
    conquest = "Interface\\PVPFrame\\PVPCurrency-Conquest-" .. UnitFactionGroup("player")
}

local MinimapButton = LibStub("LibDBIcon-1.0", true)

-- Main frame and event system
local frame = CreateFrame("Frame")
local events = {}

-- Core state variables
local STATE = {
    showedUpdate = false,
    startTime = nil,
    finallyLoaded = false,
    addonLoaded = false,
    varisLoaded = false,
    splashed = 1,
    silentTitan = 0
}

-- Session tracking
local SESSION = {
    honor = 0,
    conquest = 0,
    hks = 0,
    starting = {
        honor = 0,
        conquest = 0,
        hks = 0
    }
}

-- Battleground tracking
local BG_STATS = {
    count = 0,
    avgHonor = 0,
    inBG = 0,
    honorInBG = 0,
    lastBG = 0,
    honorBefore = 0,
    damage = 0,
    heals = 0,
    totalDamage = 0,
    totalHeals = 0
}

-- War game/Arena tracking
local WG_STATS = {
    count = 0,
    avgCP = 0,
    inWG = 0,
    conquestInBG = 0,
    lastWG = 0,
    conquestBefore = 0
}

-- Goal tracking
local GOALS = {
    honor = {
        current = 0,
        percent = 0
    },
    conquest = {
        current = 0,
        percent = 0
    }
}

-- User tracking
local peopleUsing = { Character = {} }

-- Default configuration
local mhDefaults = {
    ShowMinimapButton = true,
    TrackStats = true,
    BattleStatistics = true,
    LastDate = date("%Y %j"),
    Tooltip = 1,
    DisplayBar = {
        [1] = true, [2] = true, [3] = false, [4] = false,
        [5] = false, [6] = false, [7] = false, [8] = false,
        [9] = false, [10] = false, [11] = false, [12] = false
    },
    LastVersion = rawVersion,
}

local StatDefaults = {
    BattleCount = 0,
    HonorGoal = 0,
    ConquestGoal = 0,
    HonorToday = 0,
    HonorYesterday = 0,
}

-- Utility functions
local function ShortPrint(text)
    DEFAULT_CHAT_FRAME:AddMessage("myHonor: " .. text, 0.41, 0.80, 0.94)
end

local function GetCurrencyAmount(currencyID)
    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    return info and info.quantity or 0
end

local function format_number(num)
    if type(num) == "string" then return num end
    if not num or num == 0 then return "0" end

    local formatted = tostring(num)
    local result = ""
    local len = #formatted

    for i = 1, len do
        result = result .. formatted:sub(i, i)
        -- Add comma if we're not at the end and the remaining digits are divisible by 3
        if (len - i) % 3 == 0 and i ~= len then
            result = result .. ","
        end
    end

    return result
end

local function siUnits(value)
    if not value or value == 0 then return "0" end

    local units = {"", "K", "M", "B", "T"}
    local index = 1
    local num = tonumber(value) or 0

    while num >= 1000 and index < #units do
        num = num / 1000
        index = index + 1
    end

    if index == 1 then
        return tostring(math.floor(num))
    else
        return string.format("%.1f%s", num, units[index])
    end
end

-- Text coloring functions
local function RedText(text) return "|cffff0000" .. text .. "|r" end
local function GreenText(text) return "|cff00ff00" .. text .. "|r" end
local function BlueText(text) return "|cff0000ff" .. text .. "|r" end
local function PurpleText(text) return "|cff800080" .. text .. "|r" end
local function GetHighText(text) return "|cffffff00" .. text .. "|r" end

local function Should_I_Be_Red(value)
    if not value or value == 0 or value == "0" then
        return RedText(tostring(value))
    else
        return GetHighText(tostring(value))
    end
end

local function texIcon(iconPath)
    return "|T" .. iconPath .. ":16:16:0:0|t"
end

-- Event handlers
function events:ADDON_LOADED(arg1)
    if STATE.varisLoaded then return end

    if not myOptions then myOptions = mhDefaults end
    if not myStats then myStats = StatDefaults end
    if not myOptions.ShowMinimapButton then HideMinimapButton() end
    if not myOptions.DisplayBar then myOptions.DisplayBar = mhDefaults.DisplayBar end

    STATE.varisLoaded = true

    if not myOptions.BattleStatistics then
        frame:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
    end
end

function events:PLAYER_LOGOUT()
    frame:SaveStuff()
end

function events:PLAYER_ENTERING_WORLD()
    if not myHonor then myHonor = {} end
    if not STATE.startTime then STATE.startTime = time() end
    if STATE.varisLoaded then frame:CheckDate() end

    local currentHonor = GetCurrencyAmount(1792)
    local zoneInfo = select(2, IsInInstance())
    local zoneName = GetZoneText()

    if zoneInfo == "pvp" then
        BG_STATS.inBG = 1
        myStats.BattleCount = (tonumber(myStats.BattleCount) or 0) + 1
        BG_STATS.count = BG_STATS.count + 1
        BG_STATS.honorBefore = currentHonor
        BG_STATS.damage = 0
        BG_STATS.heals = 0
    elseif zoneInfo == "arena" then
        WG_STATS.inWG = 1
        WG_STATS.count = WG_STATS.count + 1
        WG_STATS.conquestBefore = GetCurrencyAmount(1602)
    elseif zoneInfo == "none" then
        if BG_STATS.inBG == 1 then
            BG_STATS.lastBG = BG_STATS.honorInBG
            BG_STATS.honorInBG = 0
        end
        BG_STATS.inBG = 0
    end

    if not STATE.finallyLoaded then
        frame:CheckHonor()
    end
end

function events:CHAT_MSG_COMBAT_HONOR_GAIN(value)
    local honorGained = tonumber(string.match(value, "%d+"))
    if not honorGained then return end

    local currentHonor = GetCurrencyAmount(1792)
    local currentConquest = GetCurrencyAmount(1602)

    myStats.HonorToday = myStats.HonorToday + honorGained

    if STATE.finallyLoaded then
        SESSION.honor = SESSION.honor + honorGained
        SESSION.conquest = currentConquest - SESSION.starting.conquest
        SESSION.hks = select(1, GetPVPLifetimeStats()) - SESSION.starting.hks

        frame:CheckDate()

        local conquestInfo = C_CurrencyInfo.GetCurrencyInfo(1602)
        local conqCap = conquestInfo and conquestInfo.maxQuantity or 0
        local conqCapTotal = conquestInfo and conquestInfo.totalEarned or 0
    end

    if BG_STATS.inBG == 1 then
        BG_STATS.honorInBG = BG_STATS.honorInBG + honorGained
        WG_STATS.conquestInBG = currentConquest - WG_STATS.conquestBefore
    end

    -- Calculate averages
    if BG_STATS.count >= 3 then
        BG_STATS.avgHonor = BG_STATS.honorInBG / myStats.BattleCount
    end

    if WG_STATS.count > 0 then
        WG_STATS.avgCP = WG_STATS.conquestInBG / WG_STATS.count
    end

    -- Check goals
    frame:CheckGoals(currentHonor, currentConquest)
    frame:UpdateDisplayBar()
end

function events:CHAT_MSG_ADDON(prefix, msg, channel, sender)
    if prefix ~= "myHonor" then return end

    local alreadyIn = false
    for _, name in pairs(peopleUsing.Character) do
        if sender:lower() == name:lower() then
            alreadyIn = true
            break
        end
    end

    if not alreadyIn then
        table.insert(peopleUsing.Character, sender)
    end

    if string.find(msg, "V") and not string.find(msg, "Beta") then
        local version = msg:gsub("V: ", ""):gsub(" Release", ""):gsub(" ", "")
        local currentVersion = mhVersion:gsub(" Release", ""):gsub(" Beta", ""):gsub(" ", "")

        if version > currentVersion and not STATE.showedUpdate then
            ShortPrint("myHonor is out of date. Latest Version: " .. version ..
                      " You have: " .. mhVersion .. ". Please visit Curse.com to get the latest version!")
            STATE.showedUpdate = true
        end
    end
end

function events:UPDATE_BATTLEFIELD_SCORE()
    local playerName = UnitName("player")

    for i = 1, GetNumBattlefieldScores() do
        local name, _, _, _, _, _, race, class, classToken, damageDone, healingDone = GetBattlefieldScore(i)

        if name == playerName then
            if BG_STATS.inBG == 1 then
                BG_STATS.damage = damageDone
                BG_STATS.heals = healingDone

                if GetBattlefieldWinner() then
                    BG_STATS.totalDamage = (tonumber(BG_STATS.totalDamage) or 0) + (tonumber(BG_STATS.damage) or 0)
                    BG_STATS.totalHeals = (tonumber(BG_STATS.totalHeals) or 0) + (tonumber(BG_STATS.heals) or 0)
                end
            end
            break
        end
    end
end

-- Core functionality
function frame:SaveStuff()
    myOptions.LastDate = date("%Y %j")
end

function frame:CheckDate()
    if string.find(myOptions.LastDate, "/") then
        myOptions.LastDate = "0001 " .. date("%j")
    end

    local lastOnYear, lastOnDay = strsplit(" ", myOptions.LastDate)
    lastOnYear = tonumber(lastOnYear)
    lastOnDay = tonumber(lastOnDay)

    local year, today = strsplit(" ", date("%Y %j"))
    year = tonumber(year)
    today = tonumber(today)

    local sameday = (lastOnYear == year) and (lastOnDay == today)
    local yesterday = false

    if (lastOnYear == year) and (lastOnDay == today - 1) then
        yesterday = true
    elseif (lastOnYear == year - 1) and (today == 1) then
        local isLeapYear = (math.floor(lastOnYear / 4) == lastOnYear / 4)
        local lastDayOfYear = isLeapYear and 366 or 365
        yesterday = (lastOnDay == lastDayOfYear)
    end

    if sameday then return end

    if yesterday then
        myStats.HonorYesterday = myStats.HonorToday
    else
        myStats.HonorYesterday = 0
    end

    myStats.BattleCount = 0
    myStats.HonorToday = 0
end

function frame:CheckHonor()
    if not STATE.finallyLoaded then
        SESSION.starting.honor = GetCurrencyAmount(1792)
        SESSION.starting.hks = select(1, GetPVPLifetimeStats())
        SESSION.starting.conquest = GetCurrencyAmount(1602)
        STATE.finallyLoaded = true
    end
end

function frame:CheckGoals(currentHonor, currentConquest)
    -- Honor goal check
    if myStats.HonorGoal > 0 and currentHonor >= myStats.HonorGoal then
        RaidNotice_AddMessage(RaidWarningFrame, mH_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
        ShortPrint("** You've reached your honor goal! **")
        PlaySound(8959, "Master")
        myStats.HonorGoal = 0
    end

    -- Conquest goal check
    if myStats.ConquestGoal > 0 and currentConquest >= myStats.ConquestGoal then
        RaidNotice_AddMessage(RaidWarningFrame, mq_TXT_GOALMET, ChatTypeInfo["RAID_WARNING"])
        ShortPrint("** You've reached your conquest goal! **")
        PlaySound(8959, "Master")
        myStats.ConquestGoal = 0
    end

    -- Update goal calculations
    if myStats.ConquestGoal > 0 then
        GOALS.conquest.current = myStats.ConquestGoal - currentConquest
    end

    if myStats.HonorGoal > 0 then
        GOALS.honor.current = myStats.HonorGoal - currentHonor
    else
        GOALS.honor.current = 0
    end

    if myStats.ConquestGoal < currentConquest then
        GOALS.conquest.current = GreenText("N/A")
    end

    if myStats.HonorGoal < currentHonor then
        GOALS.honor.current = GreenText("N/A")
    end
end

function frame:UpdateDisplayBar()
    local currentHonor = GetCurrencyAmount(1792)
    local currentConquest = GetCurrencyAmount(1602)

    if BG_STATS.inBG == 1 then
        BG_STATS.honorInBG = currentHonor - BG_STATS.honorBefore
        WG_STATS.conquestInBG = currentConquest - WG_STATS.conquestBefore
    end

    -- Recalculate averages
    if BG_STATS.count >= 3 then
        BG_STATS.avgHonor = BG_STATS.honorInBG / myStats.BattleCount
    end

    if WG_STATS.count > 0 then
        WG_STATS.avgCP = WG_STATS.conquestInBG / WG_STATS.count
    end

    -- Check goals if not already triggered
    if STATE.splashed == 0 then
        self:CheckGoals(currentHonor, currentConquest)
    end
end

function frame:CallBGStat()
    myOptions.BattleStatistics = not myOptions.BattleStatistics

    if myOptions.BattleStatistics then
        ShortPrint("BG Damage/heal tracking enabled.")
        frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
    else
        ShortPrint("No longer tracking BG damage or heals.")
        frame:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE")
    end
end

-- Tooltip functionality
function ToggleHonor()
    if myOptions.Tooltip == 1 then
        myOptions.Tooltip = 2
        ShortPrint("Conquest will be displayed in the tooltip.")
    else
        myOptions.Tooltip = 1
        ShortPrint("Honor will be displayed in the tooltip.")
    end
end

function myHonorTT(tt, which)
    local sessionTime = time() - (STATE.startTime or time())
    local pname = GetHighText(UnitName("player"))
    local rname = GreenText(GetRealmName())
    local fname = UnitFactionGroup("player")
    local hc = select(1, GetPVPLifetimeStats())
    local perHour = 0

    if which == 1 then
        -- Honor Tooltip
        local inBGtext = BG_STATS.inBG == 1 and RedText(GetZoneText()) or GreenText("None")

        if SESSION.honor > 0 and STATE.startTime then
            perHour = SESSION.honor / sessionTime * 3600
        end

        fname = (fname == "Alliance") and BlueText(fname) or RedText(fname)

        local honorGoalFinal, honorGoalPercent, honorGoalTime = "N/A", 0, "N/A"

        if myStats.HonorGoal > 0 then
            local currentHonor = GetCurrencyAmount(1792)
            honorGoalFinal = myStats.HonorGoal - currentHonor
            honorGoalPercent = (currentHonor / myStats.HonorGoal) * 100
            honorGoalPercent = ("%.1f"):format(honorGoalPercent)

            if BG_STATS.count >= 2 and BG_STATS.avgHonor > 0 then
                honorGoalTime = math.max(0, math.ceil(honorGoalFinal / BG_STATS.avgHonor))
                honorGoalTime = honorGoalTime <= 0 and "N/A" or tostring(honorGoalTime)
            else
                honorGoalTime = "Play at least 2 BGs"
            end
        end

        if myStats.HonorGoal == 0 then
            honorGoalTime = GetHighText("N/A")
            honorGoalPercent = 0
        elseif myStats.HonorGoal < GetCurrencyAmount(1792) then
            honorGoalFinal = GreenText("Goal Accomplished!")
            honorGoalPercent = 0
        end

        -- Build tooltip
        tt:AddLine(pname .. " - " .. rname .. " (" .. fname .. ") " .. texIcon(ICONS.honor))
        tt:AddLine(GetHighText(mhAddon .. " v" .. mhVersion))
        tt:AddLine(" ")
        tt:AddDoubleLine(mH_TT_STATUS or "Status:", inBGtext)
        tt:AddDoubleLine(mH_TT_TOTALHKS or "Total HKs:", GetHighText(format_number(hc)))
        tt:AddDoubleLine(mH_TT_TOTALPTS or "Total Honor:",
                        GetHighText(format_number(GetCurrencyAmount(1792))) .. texIcon(ICONS.honor))
        tt:AddDoubleLine(mH_TT_TODAYPTS or "Today's Honor:",
                        GetHighText(format_number(myStats.HonorToday)) .. texIcon(ICONS.honor))
        tt:AddDoubleLine(mH_TT_YESPTS or "Yesterday's Honor:",
                        GetHighText(format_number(myStats.HonorYesterday)) .. texIcon(ICONS.honor))
        tt:AddLine("---------------------------------")
        tt:AddLine(GetHighText("Session Statistics"))
        tt:AddDoubleLine("Session Honor:", Should_I_Be_Red(SESSION.honor))
        tt:AddDoubleLine("Session HKs:", Should_I_Be_Red(SESSION.hks))
        tt:AddDoubleLine("Total Damage:", RedText(siUnits(BG_STATS.totalDamage)) .. ICONS.damage)
        tt:AddDoubleLine("Total Healing:", GreenText(siUnits(BG_STATS.totalHeals)) .. ICONS.heals)
        tt:AddLine("---------------------------------")
        tt:AddLine(GetHighText("Battleground Statistics"))
        tt:AddDoubleLine("Last BG Honor:", Should_I_Be_Red(BG_STATS.lastBG))
        tt:AddDoubleLine("Current BG Honor:", Should_I_Be_Red(BG_STATS.honorInBG))
        tt:AddDoubleLine("Average Honor:", Should_I_Be_Red(format("%d", BG_STATS.avgHonor)))
        tt:AddDoubleLine("Session BGs:", Should_I_Be_Red(BG_STATS.count))
        tt:AddDoubleLine("Total BGs Today:", Should_I_Be_Red(myStats.BattleCount))
        tt:AddDoubleLine("Honor/Hour:", Should_I_Be_Red(format_number(format("%d", perHour))))
        tt:AddDoubleLine("BG Damage:", RedText(siUnits(BG_STATS.damage)) .. ICONS.damage)
        tt:AddDoubleLine("BG Healing:", GreenText(siUnits(BG_STATS.heals)) .. ICONS.heals)
        tt:AddLine("---------------------------------")
        tt:AddDoubleLine("Honor Goal:",
                        GetHighText(GetCurrencyAmount(1792)) .. "/" .. GreenText(myStats.HonorGoal) ..
                        " " .. PurpleText("(" .. honorGoalPercent .. "%)"))
        tt:AddDoubleLine("Honor Needed:", GetHighText(honorGoalFinal))
        tt:AddDoubleLine("BGs to Goal:", GreenText(honorGoalTime))
        tt:AddDoubleLine("Users Online:", Should_I_Be_Red(#peopleUsing.Character))
        tt:AddLine(" ")
        tt:AddLine("Left click to change tooltip display.")
        tt:AddLine(GreenText("Right click to open the options."), nil, nil, nil, 1)
    else
        -- Conquest Tooltip
        local currentSeason = GetCurrentArenaSeason()
        if currentSeason == 0 then currentSeason = "Inactive" end

        if SESSION.conquest > 0 and STATE.startTime then
            perHour = SESSION.conquest / sessionTime * 3600
        end

        fname = (fname == "Alliance") and BlueText(fname) or RedText(fname)

        local conquestInfo = C_CurrencyInfo.GetCurrencyInfo(1602)
        local conqCap = conquestInfo and conquestInfo.maxQuantity or 0
        local conqCapTotal = conquestInfo and conquestInfo.totalEarned or 0
        local currentConquest = GetCurrencyAmount(1602)

        local conquestGoalFinal, conquestGoalPercent, conquestGoalTime = "N/A", 0, "N/A"
        local cpCapPercent = conqCap > 0 and (conqCapTotal / conqCap) * 100 or 0
        cpCapPercent = ("%.1f"):format(cpCapPercent)

        if myStats.ConquestGoal > 0 then
            conquestGoalFinal = myStats.ConquestGoal - currentConquest
            conquestGoalPercent = (currentConquest / myStats.ConquestGoal) * 100
            conquestGoalPercent = ("%.1f"):format(conquestGoalPercent)

            if WG_STATS.count > 0 and WG_STATS.avgCP > 0 then
                conquestGoalTime = format("%d", conquestGoalFinal / WG_STATS.avgCP)
            end
        end

        if myStats.ConquestGoal == 0 then
            conquestGoalTime = GetHighText("N/A")
        elseif myStats.ConquestGoal < currentConquest then
            conquestGoalFinal = GreenText("Goal Accomplished!")
        end

        tt:AddLine(pname .. " - " .. rname .. " (" .. fname .. ") " .. texIcon(ICONS.conquest))
        tt:AddLine(GetHighText(mqAddon .. " v" .. mqVersion))
        tt:AddLine(GetHighText("Season: " .. currentSeason))
        tt:AddLine(" ")
        tt:AddLine("---------------------------------")
        tt:AddLine(GetHighText("War Game Statistics"))
        tt:AddDoubleLine("Last Match CP:", Should_I_Be_Red(WG_STATS.lastWG))
        tt:AddDoubleLine("Session CP:", Should_I_Be_Red(SESSION.conquest))
        tt:AddDoubleLine("Average CP:", Should_I_Be_Red(format("%d", WG_STATS.avgCP)))
        tt:AddDoubleLine("Matches Played:", Should_I_Be_Red(WG_STATS.count))
        tt:AddDoubleLine("Weekly Cap:",
                        GreenText(currentConquest .. "/" .. conqCap) .. PurpleText(" (" .. cpCapPercent .. "%)"))
        tt:AddDoubleLine("CP/Hour:", Should_I_Be_Red(format("%d", perHour)))
        tt:AddLine("----------------------------------")
        tt:AddDoubleLine("Conquest Goal:",
                        GreenText(currentConquest .. "/" .. myStats.ConquestGoal) ..
                        PurpleText(" (" .. conquestGoalPercent .. "%)"))
        tt:AddDoubleLine("CP Needed:", GetHighText(conquestGoalFinal))
        tt:AddDoubleLine("Matches to Goal:", GreenText(conquestGoalTime))
        tt:AddLine("---------------------------------")

        -- Arena ratings
        local teamTwos = GetPersonalRatedInfo(1)
        local teamThrees = GetPersonalRatedInfo(2)
        local teamFives = GetPersonalRatedInfo(3)

        tt:AddLine(GetHighText("2v2 Team Statistics"))
        tt:AddLine("Team Rating: " .. GetHighText(teamTwos))
        tt:AddLine(GetHighText("3v3 Team Statistics"))
        tt:AddLine("Team Rating: " .. GetHighText(teamThrees))
        tt:AddLine(GetHighText("5v5 Team Statistics"))
        tt:AddLine("Team Rating: " .. GetHighText(teamFives))
        tt:AddLine(" ")
        tt:AddLine("Left click to change tooltip display.")
        tt:AddLine(GreenText("Right click to open the options."), nil, nil, nil, 1)
    end

    tt:Show()
end

-- Slash commands
SLASH_GOAL1 = "/goal"
function SlashCmdList.GOAL(msg)
    local cmd = msg:lower()

    if cmd == "" then
        ShortPrint(mH_TXT_GOALSYN or "Usage: /goal <number>")
    else
        local goalValue = tonumber(msg)
        if goalValue then
            if myOptions.Tooltip == 1 then
                myStats.HonorGoal = goalValue
                ShortPrint("Honor goal set to: " .. goalValue)
            else
                myStats.ConquestGoal = goalValue
                ShortPrint("Conquest goal set to: " .. goalValue)
            end
            STATE.splashed = 0
        else
            ShortPrint("Invalid goal value. Please enter a number.")
        end
    end
end

SLASH_AJBG1 = "/mh"
function SlashCmdList.AJBG(msg)
    local cmd = msg:lower()

    if cmd == "tt" then
        ToggleHonor()
    elseif cmd == "mm" then
        ToggleMinimapButton()
    elseif cmd == "goal" then
        ShortPrint(mH_TXT_GOALSYN or "Usage: /goal <number>")
    elseif cmd == "bgstat" then
        frame:CallBGStat()
    elseif cmd == "reset" then
        SESSION.honor = 0
        BG_STATS.honorInBG = 0
        myStats.BattleCount = 0
        BG_STATS.avgHonor = 0
        BG_STATS.count = 0
        BG_STATS.lastBG = 0
        BG_STATS.totalDamage = 0
        BG_STATS.totalHeals = 0
        ShortPrint("Session statistics reset.")
    elseif cmd == "secret" then
        print("People using add-on:", #peopleUsing.Character)
    elseif cmd == "secret2" then
        for k, v in pairs(peopleUsing.Character) do
            print(k, v)
        end
    elseif cmd == "help" or cmd == "" then
        ShortPrint("myHonor Commands:")
        ShortPrint("/mh tt - Toggle tooltip display")
        ShortPrint("/mh mm - Toggle minimap button")
        ShortPrint("/mh bgstat - Toggle BG statistics tracking")
        ShortPrint("/mh reset - Reset session statistics")
        ShortPrint("/goal <number> - Set honor/conquest goal")
        ShortPrint("Version: " .. mhVersion)
    else
        ShortPrint("Unknown command. Use /mh help for available commands.")
    end
end

-- Minimap button
local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("myHonor", {
    type = "data source",
    text = "myHonor",
    icon = ICONS.honor,
    OnClick = function(self, btn)
        if btn == "LeftButton" then
            ToggleHonor()
        elseif btn == "RightButton" then
            if mh_OptionsWindow and mh_OptionsWindow:IsShown() then
                mh_OptionsWindow:Hide()
            elseif mh_OptionsWindow then
                mh_OptionsWindow:Show()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        myHonorTT(tooltip, myOptions.Tooltip)
    end,
})

function myHonor:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("myHonorMinimapPOS", {
        profile = {
            minimap = { hide = false },
        },
    })

    MinimapButton:Register("myHonor", miniButton, self.db.profile.minimap)
end

-- Event registration
frame:SetScript("OnEvent", function(self, event, ...)
    if events[event] then
        events[event](self, ...)
    end
end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

-- Show minimap button
if MinimapButton then
    MinimapButton:Show("myHonor")
end

-- Copyright Smokey, 2010-2025 All Rights Reserved, released under MIT License.
-- If you're going to edit, at least give me credit or tell me about it and we can work together