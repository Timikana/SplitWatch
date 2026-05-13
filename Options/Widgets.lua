-- Options/Widgets.lua — small helpers + widget factories.
-- Loaded BEFORE Options/Panel.lua. Factories register themselves onto
-- SplitW.Options.<name>. They use O._registerInSection at CALL time
-- (resolved when pages build), which Panel.lua exposes.
local addonName, SplitW = ...
local L = SplitW.L

SplitW.Options = SplitW.Options or {}
SplitW.Options.Pages = SplitW.Options.Pages or {}
local O = SplitW.Options

local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

local function refresh()
    if SplitW.RefreshAll then SplitW:RefreshAll() end
end

local CLASS_COLORS = (_G.RAID_CLASS_COLORS) or {}

-- ============================================================
-- SMALL HELPERS
-- ============================================================
local function addTooltip(widget, text)
    if not widget or not text then return end
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
O.addTooltip = addTooltip

local function classColor(class)
    local c = class and CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.8, 0.8, 0.8
end
O.classColor = classColor

local function fmtNum(v)
    if not v or v <= 0 then return "|cff666666—|r" end
    if v >= 1e6 then return string.format("%.2fM", v / 1e6) end
    if v >= 1e3 then return string.format("%.1fk", v / 1e3) end
    return string.format("%d", math.floor(v + 0.5))
end
O.fmtNum = fmtNum

local function roleIcon(role, size)
    size = size or 14
    if role == "TANK"   then return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:0:19:22:41|t", size, size) end
    if role == "HEALER" then return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:20:39:1:20|t", size, size) end
    return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:20:39:22:41|t", size, size)
end
O.roleIcon = roleIcon

-- ============================================================
-- markAsNew — "NEW" badge that dismisses on first hover/click
-- ============================================================
local function markAsNew(widget, key)
    if not widget or not key then return widget end
    SplitWatchDB = SplitWatchDB or {}
    SplitWatchDB.seenFeatures = SplitWatchDB.seenFeatures or {}
    if SplitWatchDB.seenFeatures[key] then return widget end

    local badge = CreateFrame("Frame", nil, widget, "BackdropTemplate")
    badge:SetSize(38, 16)
    badge:SetPoint("BOTTOMLEFT", widget, "TOPLEFT", -3, 1)
    badge:SetFrameLevel((widget.GetFrameLevel and widget:GetFrameLevel() or 1) + 5)
    badge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    badge:SetBackdropColor(1, 0.6, 0, 0.85)
    badge:SetBackdropBorderColor(1, 1, 0.5, 1)
    local t = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("CENTER"); t:SetText("NEW"); t:SetTextColor(1, 1, 1)

    local function clear()
        SplitWatchDB.seenFeatures[key] = true
        badge:Hide()
    end
    widget:HookScript("OnEnter", clear)
    local ot = widget.GetObjectType and widget:GetObjectType() or ""
    if ot == "CheckButton" or ot == "Button" then widget:HookScript("OnClick", clear)
    elseif ot == "Slider" then widget:HookScript("OnValueChanged", clear) end
    return widget
end
O.markAsNew = markAsNew

-- ============================================================
-- WIDGET FACTORIES
-- ============================================================
O.makeCheck = function(parent, label, key, x, y, tip)
    local cb = CreateFrame("CheckButton", "SWOpt_"..key, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.Text:SetFontObject("GameFontHighlight")
    cb.Text:SetText(label)
    cb.dbKey = key
    cb:SetChecked(SplitW:GetDB()[key] and true or false)
    cb:SetScript("OnClick", function(self)
        SplitW:GetDB()[key] = self:GetChecked() and true or false
        refresh()
    end)
    if tip then addTooltip(cb, tip) end
    if O._registerInSection then O._registerInSection(cb, key) end
    return cb
end

O.makeSlider = function(parent, label, key, minV, maxV, step, x, y, width, tip, onChange)
    local sl = CreateFrame("Frame", "SWOpt_"..key, parent, "MinimalSliderWithSteppersTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetWidth(width or 220)
    sl.dbKey = key
    local function fmt(v) return tostring(math.floor(v + 0.5)) end
    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Min] = function() return fmt(minV) end,
        [MinimalSliderWithSteppersMixin.Label.Max] = function() return fmt(maxV) end,
        [MinimalSliderWithSteppersMixin.Label.Top] = function(v) return label .. ": " .. fmt(v) end,
    }
    local numSteps = math.max(1, math.floor((maxV - minV) / step + 0.5))
    local function readDB()
        local v = (key and SplitW:GetDB()[key]) or minV
        if type(v) ~= "number" then v = minV end
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end
    sl:Init(readDB(), minV, maxV, numSteps, formatters)
    sl:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        value = math.floor(value + 0.5)
        if key then SplitW:GetDB()[key] = value end
        if onChange then onChange(value) end
        refresh()
    end, sl)
    sl.refresh = function() sl:Init(readDB(), minV, maxV, numSteps, formatters) end
    if tip then addTooltip(sl, tip) end
    if O._registerInSection then O._registerInSection(sl, key) end
    return sl
end

O.makeDropdown = function(parent, label, key, options, x, y, width, tip, availabilityFn)
    local dd = CreateFrame("DropdownButton", "SWOpt_DD_"..key, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(width or 180)
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 16)
    dd.dbKey = key
    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 0, 2)
    labelFS:SetText(label)
    dd:SetupMenu(function(_, root)
        for _, opt in ipairs(options) do
            local available = (not availabilityFn) or availabilityFn(opt.value)
            local text = available and opt.text
                or (opt.text .. "  |cff888888(" .. L["not installed"] .. ")|r")
            local radio = root:CreateRadio(text,
                function() return SplitW:GetDB()[key] == opt.value end,
                function()
                    if not available then return end
                    SplitW:GetDB()[key] = opt.value
                    refresh()
                end)
            if not available and radio and radio.SetEnabled then
                radio:SetEnabled(false)
            end
        end
    end)
    dd.refresh = function() dd:GenerateMenu() end
    if tip then addTooltip(dd, tip) end
    if O._registerInSection then
        O._registerInSection(dd, key)
        O._registerInSection(labelFS)
    end
    return dd
end

O.makeButton = function(parent, label, x, y, width, onClick, tip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 140, 24)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    if tip then addTooltip(b, tip) end
    if O._registerInSection then O._registerInSection(b) end
    return b
end

O.makeLabel = function(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    if O._registerInSection then O._registerInSection(fs) end
    return fs
end
