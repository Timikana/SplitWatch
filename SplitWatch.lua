local addonName, SplitW = ...
_G[addonName] = SplitW

-- ============================================================
-- DEFAULTS
-- ============================================================
SplitW.Defaults = {
    -- General
    minimapHidden = false,
    showOnApply   = true,   -- print A/B summary to chat on Apply
    confirmApply  = true,   -- ask confirmation before mass SetRaidSubgroup

    -- Algorithm
    weightMin     = 1,
    weightMax     = 100,
    weightDefault = 50,
    dpsSource     = "DETAILS", -- DETAILS | RECOUNT | SKADA | BUILTIN | MANUAL — Details! by default since it's the most accurate and most users have it. Built-in (combat log parser) is currently blocked by Blizzard event protection on retail 12.0 — kept in the dropdown but auto-degrades to MANUAL when unavailable.
    autoRefresh   = false,    -- auto-rescan after each combat ends

    -- Per-player manual weights: { ["Name"] = 50, ... }
    weights       = {},

    -- Last computed split (preview cache)
    lastSplit     = nil,

    -- Panel state
    panelPoint    = nil,   -- { point, relPoint, x, y }
    panelWidth    = 720,
    panelHeight   = 540,
}

-- ============================================================
-- LOCALIZATION (fallback returns the key)
-- ============================================================
SplitW.L = setmetatable({}, { __index = function(_, k) return k end })
local L = SplitW.L

-- ============================================================
-- DB / PROFILES
-- ============================================================
function SplitW:GetCharKey()
    return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
end

local function seedDefaults(target)
    for k, v in pairs(SplitW.Defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                local c = {}
                for kk, vv in pairs(v) do c[kk] = vv end
                target[k] = c
            else
                target[k] = v
            end
        end
    end
end

local function ensureProfilesDB()
    SplitWatchDB = SplitWatchDB or {}
    if not SplitWatchDB.profiles then
        SplitWatchDB.profiles = { Default = {} }
        SplitWatchDB.charBindings = {}
        SplitWatchDB.version = 1
    end
    SplitWatchDB.profiles.Default = SplitWatchDB.profiles.Default or {}
    SplitWatchDB.charBindings = SplitWatchDB.charBindings or {}
    SplitWatchDB.minimap = SplitWatchDB.minimap or { hide = false }
    SplitWatchDB.seenFeatures = SplitWatchDB.seenFeatures or {}
end

function SplitW:GetActiveProfileName()
    ensureProfilesDB()
    local key = SplitW:GetCharKey()
    local n = SplitWatchDB.charBindings[key]
    if n and SplitWatchDB.profiles[n] then return n end
    SplitWatchDB.charBindings[key] = "Default"
    return "Default"
end

function SplitW:GetDB()
    ensureProfilesDB()
    local p = SplitWatchDB.profiles[SplitW:GetActiveProfileName()]
    seedDefaults(p)
    return p
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

function SplitW:SetActiveProfile(name)
    ensureProfilesDB()
    if not SplitWatchDB.profiles[name] then return false end
    SplitWatchDB.charBindings[SplitW:GetCharKey()] = name
    if SplitW.RefreshAll then SplitW:RefreshAll() end
    return true
end

function SplitW:CreateProfile(newName, copyFromName)
    ensureProfilesDB()
    if not newName or newName == "" or SplitWatchDB.profiles[newName] then return false end
    local source = SplitWatchDB.profiles[copyFromName or SplitW:GetActiveProfileName()]
    SplitWatchDB.profiles[newName] = source and deepCopy(source) or {}
    return true
end

function SplitW:ResetProfile(name)
    ensureProfilesDB()
    if not SplitWatchDB.profiles[name] then return false end
    SplitWatchDB.profiles[name] = {}
    return true
end

function SplitW:DeleteProfile(name)
    ensureProfilesDB()
    if name == "Default" then return false, "cannot delete Default" end
    if not SplitWatchDB.profiles[name] then return false end
    SplitWatchDB.profiles[name] = nil
    for k, v in pairs(SplitWatchDB.charBindings) do
        if v == name then SplitWatchDB.charBindings[k] = "Default" end
    end
    return true
end

function SplitW:ListProfiles()
    ensureProfilesDB()
    local list = {}
    for n in pairs(SplitWatchDB.profiles) do list[#list + 1] = n end
    table.sort(list, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a:lower() < b:lower()
    end)
    return list
end

-- ============================================================
-- WEIGHTS API (manual mode helper)
-- ============================================================
function SplitW:GetWeight(name)
    if not name then return nil end
    local db = SplitW:GetDB()
    return db.weights[name]
end

function SplitW:SetWeight(name, value)
    if not name then return end
    local db = SplitW:GetDB()
    value = tonumber(value)
    if value then
        if value < db.weightMin then value = db.weightMin
        elseif value > db.weightMax then value = db.weightMax end
        db.weights[name] = math.floor(value + 0.5)
    end
end

function SplitW:GetEffectiveWeight(entry)
    local db = SplitW:GetDB()
    if db.dpsSource ~= "MANUAL" and SplitW.DPSSource and SplitW.DPSSource.GetDPS then
        local v = SplitW.DPSSource:GetDPS(entry.name)
        if v and v > 0 then return v end
    end
    return self:GetWeight(entry.name) or db.weightDefault or 50
end

-- Effective HPS for healer balancing. Returns the live HPS from the active
-- damage-meter source, or falls back to the manual per-player weight (which
-- doubles as a generic strength score in the absence of healing data).
function SplitW:GetEffectiveHPS(entry)
    local db = SplitW:GetDB()
    if db.dpsSource ~= "MANUAL" and SplitW.DPSSource and SplitW.DPSSource.GetHPS then
        local v = SplitW.DPSSource:GetHPS(entry.name)
        if v and v > 0 then return v end
    end
    return self:GetWeight(entry.name) or db.weightDefault or 50
end

-- ============================================================
-- SLASH COMMAND
-- ============================================================
SLASH_SPLITWATCH1 = "/splitw"
SLASH_SPLITWATCH2 = "/splitwatch"
SlashCmdList["SPLITWATCH"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    if msg == "" or msg == "config" or msg == "options" then
        if SplitW.ToggleOptions then SplitW:ToggleOptions() end
        return
    end
    if cmd == "preview" then
        local roster = SplitW.Roster:Scan()
        local split  = SplitW.Splitter:Compute(roster)
        SplitW:GetDB().lastSplit = split
        if SplitW.ToggleOptions and not (SplitW._panel and SplitW._panel:IsShown()) then
            SplitW:ToggleOptions()
        end
        if SplitW.RefreshAll then SplitW:RefreshAll() end
    elseif cmd == "apply" then
        if SplitW.Apply then SplitW.Apply:Run() end
    elseif cmd == "test" then
        if SplitW.Roster then SplitW.Roster:SetTestMode(arg ~= "off") end
        local r = SplitW.Roster:Scan()
        local s = SplitW.Splitter:Compute(r)
        SplitW:GetDB().lastSplit = s
        if SplitW.RefreshAll then SplitW:RefreshAll() end
        print("|cffffd100SplitWatch:|r " .. (arg == "off" and L["test mode off"] or L["test mode on (20 simulated members)"]))
    elseif cmd == "reset" then
        SplitWatchDB = nil
        ReloadUI()
    else
        print("|cffffd100SplitWatch:|r " .. L["commands:"])
        print("  /splitw            - " .. L["open options"])
        print("  /splitw preview    - " .. L["compute and show split preview"])
        print("  /splitw apply      - " .. L["apply the current split via SetRaidSubgroup"])
        print("  /splitw test [off] - " .. L["toggle simulated 20-man roster"])
        print("  /splitw reset      - " .. L["reset all settings + reload"])
    end
end

-- ============================================================
-- MINIMAP ICON
-- ============================================================
function SplitW:RegisterMinimapIcon()
    if SplitW._minimapRegistered then return end
    local LDB  = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not LDB or not Icon then return end
    local broker = LDB:NewDataObject("SplitWatch", {
        type = "launcher",
        text = "SplitWatch",
        icon = "Interface\\AddOns\\SplitWatch\\Media\\logo.tga",
        OnClick = function(_, button)
            if button == "RightButton" then
                if SplitW.Apply then SplitW.Apply:Run() end
            else
                if SplitW.ToggleOptions then SplitW:ToggleOptions() end
            end
        end,
        OnTooltipShow = function(tip)
            tip:AddLine("|cffffd100SplitWatch|r")
            tip:AddLine("|cffaaaaaa" .. L["left-click: options"] .. "|r")
            tip:AddLine("|cffaaaaaa" .. L["right-click: apply current split"] .. "|r")
        end,
    })
    Icon:Register("SplitWatch", broker, SplitWatchDB.minimap)
    SplitW._minimapRegistered = true
end

function SplitW:ToggleMinimapIcon(show)
    SplitWatchDB.minimap = SplitWatchDB.minimap or { hide = false }
    SplitWatchDB.minimap.hide = not show
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if Icon then
        if show then Icon:Show("SplitWatch") else Icon:Hide("SplitWatch") end
    end
end

-- ============================================================
-- INIT
-- ============================================================
local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("PLAYER_REGEN_ENABLED")
init:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        SplitW:GetDB()
        if SplitW.RegisterMinimapIcon then SplitW:RegisterMinimapIcon() end
        if SplitW.RegisterBlizzardSettings then SplitW:RegisterBlizzardSettings() end
        local v = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
        print(format(L["|cffffd100SplitWatch|r v%s loaded — type |cffffff00/splitw|r for options"], v))
    elseif event == "PLAYER_REGEN_ENABLED" then
        if SplitW.Apply and SplitW.Apply.OnCombatEnd then SplitW.Apply:OnCombatEnd() end
    end
end)
