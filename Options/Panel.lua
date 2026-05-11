local addonName, SplitW = ...
local L = SplitW.L

local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

local panel
local pages = {}
local pageHolder
local selectTab
local refresh

-- Currently-being-built section: widget factories push themselves into it so
-- collapse/reset operate on the right list. Reset via makeSection() at top of
-- each page section.
local _currentSection = nil

local function _registerInSection(widget, dbKey)
    if not _currentSection or not widget then return end
    _currentSection.children[#_currentSection.children + 1] = widget
    if dbKey then
        _currentSection.dbKeys[#_currentSection.dbKeys + 1] = dbKey
    end
    if _currentSection._collapsed and widget.Hide then widget:Hide() end
end

local function _cloneDefault(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, val in pairs(v) do out[k] = _cloneDefault(val) end
    return out
end

local CLASS_COLORS = (_G.RAID_CLASS_COLORS) or {}

-- ============================================================
-- HELPERS
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

local function classColor(class)
    local c = class and CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.8, 0.8, 0.8
end

local function roleIcon(role)
    if role == "TANK"   then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:0:19:22:41|t" end
    if role == "HEALER" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:1:20|t" end
    return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:22:41|t"
end

-- "NEW" badge: dismisses on first hover/click. Account-wide tracker.
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

-- ============================================================
-- WIDGET FACTORIES
-- ============================================================
local function makeCheck(parent, label, key, x, y, tip)
    local cb = CreateFrame("CheckButton", "SWOpt_"..key, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.Text:SetFontObject("GameFontHighlight")
    cb.Text:SetText(label)
    cb.dbKey = key
    cb:SetChecked(SplitW:GetDB()[key] and true or false)
    cb:SetScript("OnClick", function(self)
        SplitW:GetDB()[key] = self:GetChecked() and true or false
        if refresh then refresh() end
    end)
    if tip then addTooltip(cb, tip) end
    _registerInSection(cb, key)
    return cb
end

local function makeSlider(parent, label, key, minV, maxV, step, x, y, width, tip, onChange)
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
        if refresh then refresh() end
    end, sl)
    sl.refresh = function() sl:Init(readDB(), minV, maxV, numSteps, formatters) end
    if tip then addTooltip(sl, tip) end
    _registerInSection(sl, key)
    return sl
end

local function makeDropdown(parent, label, key, options, x, y, width, tip)
    local dd = CreateFrame("DropdownButton", "SWOpt_DD_"..key, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(width or 180)
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 16)
    dd.dbKey = key
    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 0, 2)
    labelFS:SetText(label)
    dd:SetupMenu(function(_, root)
        for _, opt in ipairs(options) do
            root:CreateRadio(opt.text,
                function() return SplitW:GetDB()[key] == opt.value end,
                function()
                    SplitW:GetDB()[key] = opt.value
                    if refresh then refresh() end
                end)
        end
    end)
    dd.refresh = function() dd:GenerateMenu() end
    if tip then addTooltip(dd, tip) end
    _registerInSection(dd, key)
    _registerInSection(labelFS)
    return dd
end

local function makeButton(parent, label, x, y, width, onClick, tip)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 140, 24)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    if tip then addTooltip(b, tip) end
    _registerInSection(b)
    return b
end

-- makeHeader is now a thin wrapper around makeSection so existing absolute-positioned
-- page builders keep working. Each section gets: header text + horizontal gold line,
-- chevron (click to collapse/expand its registered widgets), and a reset button (resets
-- the registered dbKeys to Defaults).
local TEX_EXPANDED  = "Interface\\Buttons\\UI-MinusButton-Up"
local TEX_COLLAPSED = "Interface\\Buttons\\UI-PlusButton-Up"

local function makeSection(parent, title, x, y, key, width)
    width = width or 640
    SplitWatchDB = SplitWatchDB or {}
    SplitWatchDB.collapsedSections = SplitWatchDB.collapsedSections or {}

    local section = {
        children = {},
        dbKeys   = {},
        key      = key,
        parent   = parent,
        _origin  = y,
    }

    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(title)
    header:SetTextColor(1, 0.82, 0)
    section.header = header

    local chevron = parent:CreateTexture(nil, "OVERLAY")
    chevron:SetSize(14, 14)
    chevron:SetPoint("LEFT", header, "RIGHT", 4, -1)
    chevron:SetTexture(TEX_EXPANDED)
    section.chevron = chevron

    -- Reset button at the right edge (built first so click area can stop before it)
    local btnReset = CreateFrame("Button", nil, parent)
    btnReset:SetSize(14, 14)
    btnReset:SetPoint("TOPLEFT", parent, "TOPLEFT", x + width - 18, y - 2)
    btnReset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    btnReset:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    btnReset:SetFrameLevel(parent:GetFrameLevel() + 6)
    section.resetBtn = btnReset

    -- Click area: cover the whole header-line strip except where the reset button
    -- sits. Use two SetPoints so the area stretches with the requested width and
    -- doesn't depend on the FontString's measured size (which is 0 at build time).
    local clickArea = CreateFrame("Button", nil, parent)
    clickArea:SetPoint("TOPLEFT",     parent, "TOPLEFT", x - 4,            y + 4)
    clickArea:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x + width - 22,   y - 14)
    clickArea:SetFrameLevel(parent:GetFrameLevel() + 5)
    clickArea:RegisterForClicks("LeftButtonUp")
    section.clickArea = clickArea

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    line:SetSize(width - 4, 1)
    line:SetColorTexture(1, 0.82, 0, 0.35)
    section.line = line

    function section:SetCollapsed(state, persist)
        state = state and true or false
        for _, w in ipairs(self.children) do
            if state then if w.Hide then w:Hide() end
            else if w.Show then w:Show() end end
        end
        chevron:SetTexture(state and TEX_COLLAPSED or TEX_EXPANDED)
        if persist and self.key then
            SplitWatchDB.collapsedSections[self.key] = state or nil
        end
        self._collapsed = state
    end

    function section:Toggle()
        self:SetCollapsed(not self._collapsed, true)
    end

    function section:ResetToDefaults()
        local db = SplitW:GetDB()
        for _, k in ipairs(self.dbKeys) do
            local def = SplitW.Defaults and SplitW.Defaults[k]
            if def ~= nil then db[k] = _cloneDefault(def) end
        end
        if SplitW.RefreshAll then SplitW:RefreshAll() end
        if panel and panel.refreshAll then panel.refreshAll() end
    end

    clickArea:SetScript("OnClick", function() section:Toggle() end)
    btnReset:SetScript("OnClick", function() section:ResetToDefaults() end)

    addTooltip(clickArea, L["Click to collapse/expand this section."])
    addTooltip(btnReset,  L["Reset this section to default values."])

    -- Restore persisted collapsed state
    local restored = key and SplitWatchDB.collapsedSections[key]
    section:SetCollapsed(restored or false, false)

    _currentSection = section
    return section
end

-- Backwards-compat shim: existing code calling makeHeader(parent, text, x, y)
-- gets a section with no key (no persistence, no reset registry) so we can roll
-- it out gradually. Pages that want reset+collapse pass a key by calling
-- makeSection directly.
local function makeHeader(parent, text, x, y)
    return makeSection(parent, text, x, y, nil)
end

local function makeLabel(parent, text, x, y, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    _registerInSection(fs)
    return fs
end

-- ============================================================
-- PAGE BUILDERS
-- ============================================================

local function buildSetupPage(parent)
    makeSection(parent, L["General"], 14, -8, "setup.general", 420)
    local mm = makeCheck(parent, L["Show minimap icon"], "minimapHidden",
        14, -40, L["Toggle the minimap launcher button"])
    -- minimapHidden is inverted: checkbox checked = icon visible.
    mm:SetChecked(not (SplitWatchDB.minimap and SplitWatchDB.minimap.hide))
    mm:SetScript("OnClick", function(self)
        SplitW:ToggleMinimapIcon(self:GetChecked())
    end)
    addTooltip(mm, L["Toggle the minimap launcher button"])

    makeCheck(parent, L["Confirm before applying"], "confirmApply",
        14, -68, L["Show a popup before mass-moving raid members"])
    makeCheck(parent, L["Print summary on apply"], "showOnApply",
        14, -96, L["Print a one-line summary to chat after a successful apply"])
    markAsNew(makeCheck(parent, L["Auto-refresh after combat"], "autoRefresh",
        14, -124, L["Recompute weights from the DPS source every time combat ends"]),
        "autoRefresh")

    makeSection(parent, L["DPS source"], 14, -160, "setup.dps_source", 420)
    local sources = {
        { text = "Details!",                       value = "DETAILS" },
        { text = "Recount",                        value = "RECOUNT" },
        { text = "Skada",                          value = "SKADA"   },
        { text = L["Manual (per-player slider)"], value = "MANUAL"  },
    }
    makeDropdown(parent, L["Pick the data source for DPS / HPS"], "dpsSource",
        sources, 14, -195, 220,
        L["Details!/Recount/Skada read live DPS+HPS from those addons when loaded. Manual uses the per-player sliders on the Weights tab."])

    local statusFS = makeLabel(parent, "", 260, -211)
    statusFS.refresh = function()
        statusFS:SetText("|cffaaaaaa" .. L["Active source"] .. ":|r " .. SplitW.DPSSource:ActiveSourceLabel())
    end
    statusFS:refresh()
    -- makeLabel already registered statusFS — but only since the recent factory change.
    -- Defensive: re-register isn't needed.

    -- ---- Source preview (live read of DPS+HPS for the current roster) ----
    -- Spans full width below the Permission status section (which sits on the
    -- right at y=-250). Pushed down to y=-340 so the two don't overlap.
    local sourcePrevSection = makeSection(parent, L["Source preview"], 14, -340, "setup.source_preview", 640)
    local hintFS = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hintFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -364)
    hintFS:SetWidth(640); hintFS:SetJustifyH("LEFT")
    hintFS:SetText(L["Live values read from the selected source for the current (or test) roster."])
    _registerInSection(hintFS)

    local previewScroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    previewScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -382)
    previewScroll:SetSize(640, 110)
    local previewContent = CreateFrame("Frame", nil, previewScroll)
    previewContent:SetSize(620, 1)
    previewScroll:SetScrollChild(previewContent)
    _registerInSection(previewScroll)
    local previewRows = {}

    local function fmtNum(v)
        if not v or v <= 0 then return "|cff666666—|r" end
        if v >= 1e6 then return string.format("%.2fM", v / 1e6) end
        if v >= 1e3 then return string.format("%.1fk", v / 1e3) end
        return string.format("%d", math.floor(v + 0.5))
    end

    local function refreshPreview()
        local roster = SplitW.Roster:Scan()
        local list, fromSource = {}, false
        -- Prefer roster (real or test) so role icons + class colors are accurate.
        for _, e in ipairs(roster.tanks)   do table.insert(list, e) end
        for _, e in ipairs(roster.healers) do table.insert(list, e) end
        for _, e in ipairs(roster.dps)     do table.insert(list, e) end
        -- No roster — fall back to whatever actors the active source has, so the
        -- user can confirm Details!/Recount/Skada is wired up even when solo.
        if #list == 0 and SplitW.DPSSource and SplitW.DPSSource.ListActors then
            local actors = SplitW.DPSSource:ListActors()
            for _, a in ipairs(actors) do
                if type(a.name) == "string" and a.name ~= "" then
                    table.insert(list, { name = a.name, class = a.class,
                                         role = "DAMAGER", _sourceDps = a.dps, _sourceHps = a.hps })
                end
            end
            fromSource = true
        end

        for i, entry in ipairs(list) do
            local row = previewRows[i]
            if not row then
                row = CreateFrame("Frame", nil, previewContent)
                row:SetSize(620, 18)
                row:SetPoint("TOPLEFT", previewContent, "TOPLEFT", 0, -(i - 1) * 18)
                row.roleFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.roleFS:SetPoint("LEFT", row, "LEFT", 0, 0)
                row.roleFS:SetWidth(20); row.roleFS:SetJustifyH("CENTER")
                row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.nameFS:SetPoint("LEFT", row.roleFS, "RIGHT", 4, 0)
                row.nameFS:SetWidth(180); row.nameFS:SetJustifyH("LEFT")
                row.dpsFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.dpsFS:SetPoint("LEFT", row.nameFS, "RIGHT", 8, 0)
                row.dpsFS:SetWidth(140); row.dpsFS:SetJustifyH("LEFT")
                row.hpsFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.hpsFS:SetPoint("LEFT", row.dpsFS, "RIGHT", 8, 0)
                row.hpsFS:SetWidth(140); row.hpsFS:SetJustifyH("LEFT")
                previewRows[i] = row
            end
            row.roleFS:SetText(fromSource and "" or roleIcon(entry.role))
            local r, g, b = classColor(entry.class)
            row.nameFS:SetText(entry.name or "?")
            row.nameFS:SetTextColor(r, g, b)
            local dps = entry._sourceDps or (SplitW.DPSSource and SplitW.DPSSource:GetDPS(entry.name))
            local hps = entry._sourceHps or (SplitW.DPSSource and SplitW.DPSSource:GetHPS(entry.name))
            row.dpsFS:SetText("|cffaaaaaaDPS:|r " .. fmtNum(dps))
            row.hpsFS:SetText("|cffaaaaaaHPS:|r " .. fmtNum(hps))
            row:Show()
        end
        for i = #list + 1, #previewRows do previewRows[i]:Hide() end
        previewContent:SetHeight(math.max(1, #list * 18 + 4))

        if #list == 0 then
            previewEmpty = previewEmpty or previewContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            previewEmpty:SetPoint("TOPLEFT", previewContent, "TOPLEFT", 14, -8)
            previewEmpty:SetText(L["No data — join a raid, enable test mode, or fight something so the active source has actors to show."])
            previewEmpty:Show()
        elseif previewEmpty then
            previewEmpty:Hide()
        end
    end
    parent._refreshPreview = refreshPreview
    refreshPreview()

    -- Auto-refresh every 1.5s while the Setup page is visible (covers live
    -- combat ticks without spamming on hidden tabs).
    local ticker
    parent:SetScript("OnShow", function()
        refreshPreview()
        if ticker then ticker:Cancel() end
        ticker = C_Timer.NewTicker(1.5, refreshPreview)
    end)
    parent:SetScript("OnHide", function()
        if ticker then ticker:Cancel(); ticker = nil end
    end)

    makeSection(parent, L["Permission status"], 360, -250, "setup.permissions", 300)
    local permFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    permFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 360, -278)
    permFS:SetWidth(300); permFS:SetJustifyH("LEFT")
    _registerInSection(permFS)
    permFS.refresh = function()
        local ok, err = SplitW.Apply:CanApply()
        if ok then
            permFS:SetText("|cff66ff66" .. L["You can apply splits (leader or assistant in a raid)."] .. "|r")
        else
            permFS:SetText("|cffff8855" .. (err or "?") .. "|r")
        end
    end
    permFS:refresh()

    -- Classic banner
    if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        local banner = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        banner:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 14, 14)
        banner:SetWidth(640); banner:SetJustifyH("LEFT")
        banner:SetText("|cffffd100" .. L["WARN_CLASSIC"] .. "|r")
    end

    parent.refresh = function()
        statusFS:refresh()
        permFS:refresh()
        if parent._refreshPreview then parent._refreshPreview() end
    end
end

-- ----------------------------------------------------------------
-- WEIGHTS PAGE
-- ----------------------------------------------------------------
local function buildWeightsPage(parent)
    makeSection(parent, L["Manual weights"], 14, -8, "weights.main", 640)
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -32)
    hint:SetWidth(640); hint:SetJustifyH("LEFT")
    hint:SetText("|cffaaaaaa" .. L["Adjust each DPS player's relative weight (1-100). Higher = goes into the lower-scoring team first."] .. "|r")
    _registerInSection(hint)

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -56)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -32, 56)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(620, 1)
    scroll:SetScrollChild(content)
    _registerInSection(scroll)

    local rows = {}
    local function makeRow(idx)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(620, 22)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(idx-1) * 24)
        row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.nameFS:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.nameFS:SetWidth(220); row.nameFS:SetJustifyH("LEFT")
        row.roleFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.roleFS:SetPoint("LEFT", row.nameFS, "RIGHT", 4, 0)
        row.roleFS:SetWidth(60); row.roleFS:SetJustifyH("LEFT")

        row.slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
        row.slider:SetWidth(220); row.slider:SetHeight(14)
        row.slider:SetPoint("LEFT", row.roleFS, "RIGHT", 8, 0)
        row.slider:SetMinMaxValues(1, 100)
        row.slider:SetValueStep(1); row.slider:SetObeyStepOnDrag(true)
        if row.slider.Low  then row.slider.Low:SetText("1") end
        if row.slider.High then row.slider.High:SetText("100") end

        row.valFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.valFS:SetPoint("LEFT", row.slider, "RIGHT", 8, 0)
        row.valFS:SetWidth(40)

        row.slider:SetScript("OnValueChanged", function(self, v)
            v = math.floor(v + 0.5)
            row.valFS:SetText(tostring(v))
            if row._entry then
                SplitW:SetWeight(row._entry.name, v)
            end
        end)
        return row
    end

    local function populate()
        local roster = SplitW.Roster:Scan()
        -- Show tanks + healers + dps. DPS first (most important for weight tuning).
        local list = {}
        for _, e in ipairs(roster.dps) do table.insert(list, e) end
        for _, e in ipairs(roster.healers) do table.insert(list, e) end
        for _, e in ipairs(roster.tanks) do table.insert(list, e) end

        for i, entry in ipairs(list) do
            local row = rows[i] or makeRow(i)
            rows[i] = row
            row._entry = entry
            local r, g, b = classColor(entry.class)
            row.nameFS:SetText(entry.name)
            row.nameFS:SetTextColor(r, g, b)
            row.roleFS:SetText(roleIcon(entry.role))
            local w = SplitW:GetWeight(entry.name) or (SplitW:GetDB().weightDefault or 50)
            row.slider:SetValue(w)
            row.valFS:SetText(tostring(w))
            row:Show()
        end
        for i = #list + 1, #rows do rows[i]:Hide() end
        content:SetHeight(math.max(1, #list * 24 + 8))

        if #list == 0 then
            row_empty = row_empty or content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            row_empty:SetPoint("TOPLEFT", content, "TOPLEFT", 14, -10)
            row_empty:SetText(L["No raid members detected. Use /splitw test for a simulated 20-man roster."])
            row_empty:Show()
        elseif row_empty then
            row_empty:Hide()
        end
    end

    -- Bottom action bar
    local resetBtn = makeButton(parent, L["Reset all weights"], 14, -8, 160, function()
        local db = SplitW:GetDB()
        local default = db.weightDefault or 50
        for k in pairs(db.weights) do db.weights[k] = default end
        populate()
    end, L["Reset every stored weight back to the default value."])
    resetBtn:ClearAllPoints()
    resetBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 14, 14)

    local refreshBtn = makeButton(parent, L["Refresh roster"], 0, 0, 160, function()
        populate()
    end, L["Re-read the raid roster from Blizzard's API."])
    refreshBtn:ClearAllPoints()
    refreshBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)

    local testBtn = makeButton(parent, L["Toggle test mode"], 0, 0, 160, function()
        SplitW.Roster:SetTestMode(not SplitW.Roster:IsTestMode())
        populate()
    end, L["Use a simulated 20-man roster for UI testing."])
    testBtn:ClearAllPoints()
    testBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 8, 0)

    parent.refresh = populate
    populate()
end

-- ----------------------------------------------------------------
-- PREVIEW PAGE (before/after with HPS/DPS counts)
-- ----------------------------------------------------------------
local function buildPreviewPage(parent)
    makeSection(parent, L["Preview the split"], 14, -8, "preview.main", 640)

    -- Top button bar
    local computeBtn = makeButton(parent, L["Compute split"], 14, -38, 160, function()
        local r = SplitW.Roster:Scan()
        SplitW:GetDB().lastSplit = SplitW.Splitter:Compute(r)
        if parent.refresh then parent.refresh() end
    end, L["Read the current roster and run the snake-distribution algorithm."])

    local applyBtn = makeButton(parent, L["Apply split"], 178, -38, 160, function()
        if SplitW:GetDB().confirmApply then
            StaticPopup_Show("SPLITWATCH_CONFIRM_APPLY")
        else
            SplitW.Apply:Run()
        end
    end, L["Move every player to their assigned subgroup. Requires leader or assistant."])

    -- Test-mode toggle (discoverable here too, not just on Weights page).
    local testBtn = makeButton(parent, L["Toggle test mode"], 342, -38, 180, function()
        SplitW.Roster:SetTestMode(not SplitW.Roster:IsTestMode())
        local r = SplitW.Roster:Scan()
        SplitW:GetDB().lastSplit = SplitW.Splitter:Compute(r)
        if parent.refresh then parent.refresh() end
    end, L["Use a simulated 20-man roster for UI testing."])

    local modeFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -68)
    modeFS:SetWidth(640); modeFS:SetJustifyH("LEFT")
    _registerInSection(modeFS)

    -- BEFORE / AFTER label. Use a Blizzard texture inline for the arrow because
    -- the FRIZQT__ font doesn't include U+2192 → and renders it as an empty box.
    local ARROW_TEX = "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:18:18:0:0|t"
    local beforeFS = makeLabel(parent, "|cffaaaaaa" .. L["Before"] .. "|r", 14, -92, "GameFontNormalLarge")
    local arrowFS  = makeLabel(parent, ARROW_TEX, 326, -94, "GameFontNormalLarge")
    local afterFS  = makeLabel(parent, "|cffffd100" .. L["After"] .. "|r", 360, -92, "GameFontNormalLarge")

    -- Stats lines
    local beforeStatsFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    beforeStatsFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -118)
    beforeStatsFS:SetWidth(300); beforeStatsFS:SetJustifyH("LEFT")
    _registerInSection(beforeStatsFS)

    local afterStatsFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    afterStatsFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 360, -118)
    afterStatsFS:SetWidth(300); afterStatsFS:SetJustifyH("LEFT")
    _registerInSection(afterStatsFS)

    -- Team A / Team B columns (after split)
    local function makeTeamColumn(title, x)
        local titleFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleFS:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -200)
        titleFS:SetText(title)
        titleFS:SetTextColor(1, 0.82, 0)
        local listFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        listFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -6)
        listFS:SetWidth(300); listFS:SetJustifyH("LEFT")
        _registerInSection(titleFS)
        _registerInSection(listFS)
        return titleFS, listFS
    end
    local titleA, listA = makeTeamColumn(L["Team A"], 14)
    local titleB, listB = makeTeamColumn(L["Team B"], 360)

    -- Warnings line
    local warnFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    warnFS:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 14, 14)
    warnFS:SetWidth(640); warnFS:SetJustifyH("LEFT")
    _registerInSection(warnFS)

    local WARN_TEXT = {
        ONE_TANK     = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tOnly one tank — both teams share the same tank? Check your roster."],
        NO_TANK      = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo tank detected in the raid."],
        TEAM_A_OVER  = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam A is too large for any reasonable raid size."],
        TEAM_B_OVER  = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam B is too large for any reasonable raid size."],
        UNEVEN_TEAMS = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeams differ by more than 1 player — score is balanced by giving the weakest DPS to the larger team."],
    }

    local function fmtTeam(team, sum)
        if #team == 0 then return "|cff888888" .. L["(empty)"] .. "|r" end
        local lines = {}
        local tanks, heals, dps = 0, 0, 0
        for _, e in ipairs(team) do
            if e.role == "TANK" then tanks = tanks + 1
            elseif e.role == "HEALER" then heals = heals + 1
            else dps = dps + 1 end
            local r, g, b = classColor(e.class)
            lines[#lines + 1] = string.format("%s |cff%02x%02x%02x%s|r",
                roleIcon(e.role),
                math.floor(r*255), math.floor(g*255), math.floor(b*255),
                e.name)
        end
        local header = string.format("|cffffd100[%d players: %dT %dH %dDPS — score %d]|r\n",
            #team, tanks, heals, dps, math.floor(sum + 0.5))
        return header .. table.concat(lines, "\n")
    end

    parent.refresh = function()
        local roster = SplitW.Roster:Scan()
        if SplitW.Roster:IsTestMode() then
            modeFS:SetText("|cffffd100" .. L["Test mode ON (20 simulated)"] .. "|r")
        elseif roster.raid == 0 then
            modeFS:SetText("|cffff8855" .. L["No raid detected — enable test mode to preview"] .. "|r")
        else
            modeFS:SetText("|cff66ff66" .. format(L["Live roster (%d members)"], roster.raid) .. "|r")
        end
        -- BEFORE stats: count current subgroup distribution.
        local beforeA, beforeB = 0, 0
        local bTA, bHA, bDA = 0, 0, 0
        local bTB, bHB, bDB = 0, 0, 0
        for _, list in ipairs({roster.tanks, roster.healers, roster.dps}) do
            for _, e in ipairs(list) do
                local toA = (e.subgroup or 1) <= 2
                if toA then beforeA = beforeA + 1 else beforeB = beforeB + 1 end
                if e.role == "TANK" then
                    if toA then bTA = bTA + 1 else bTB = bTB + 1 end
                elseif e.role == "HEALER" then
                    if toA then bHA = bHA + 1 else bHB = bHB + 1 end
                else
                    if toA then bDA = bDA + 1 else bDB = bDB + 1 end
                end
            end
        end
        beforeStatsFS:SetText(string.format(
            "|cffaaaaaa%s|r\n  A (1-2): %d (%dT %dH %dDPS)\n  B (3-4): %d (%dT %dH %dDPS)",
            L["Current raid distribution"],
            beforeA, bTA, bHA, bDA,
            beforeB, bTB, bHB, bDB))

        local split = SplitW:GetDB().lastSplit
        if not split then
            afterStatsFS:SetText("|cff888888" .. L["No split computed yet — click 'Compute split'."] .. "|r")
            listA:SetText("")
            listB:SetText("")
            warnFS:SetText("")
            return
        end

        afterStatsFS:SetText(string.format(
            "|cffffd100%s|r\n  A: %d (%dT %dH %dDPS)\n      DPS: %d  HPS: %d\n  B: %d (%dT %dH %dDPS)\n      DPS: %d  HPS: %d",
            L["Proposed split"],
            #split.teamA, split.tanksA, split.healsA, split.dpsA,
            math.floor(split.scoreA + 0.5), math.floor((split.healScoreA or 0) + 0.5),
            #split.teamB, split.tanksB, split.healsB, split.dpsB,
            math.floor(split.scoreB + 0.5), math.floor((split.healScoreB or 0) + 0.5)))

        listA:SetText(fmtTeam(split.teamA, split.scoreA))
        listB:SetText(fmtTeam(split.teamB, split.scoreB))

        if #split.warnings > 0 then
            local out = {}
            for _, w in ipairs(split.warnings) do
                out[#out + 1] = WARN_TEXT[w] or w
            end
            warnFS:SetText("|cffff8855" .. table.concat(out, "\n") .. "|r")
        else
            warnFS:SetText("|cff66ff66" .. L["Looks good — no warnings."] .. "|r")
        end
    end
end

StaticPopupDialogs["SPLITWATCH_CONFIRM_APPLY"] = {
    text = L["Apply the proposed split? This will move raid members."],
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    OnAccept = function() SplitW.Apply:Run() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- ----------------------------------------------------------------
-- ABOUT + CHANGELOG PAGE
-- ----------------------------------------------------------------
local function buildAboutPage(parent)
    makeSection(parent, L["About SplitWatch"], 14, -8, "about.info", 420)
    local v = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -40)
    fs:SetWidth(420); fs:SetJustifyH("LEFT")
    fs:SetText(format(
        L["SplitWatch v%s — auto-split a 20-man raid into 2 balanced teams.\nAuthor: Timikana\nSlash command: |cffffff00/splitw|r\nSister addons: BossWatch + TankWatch.\n"],
        v))
    _registerInSection(fs)

    -- Panel opacity slider (account-wide preference)
    makeSection(parent, L["Panel"], 450, -8, "about.panel", 200)
    local alphaSlider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    alphaSlider:SetWidth(220)
    alphaSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 450, -50)
    _registerInSection(alphaSlider)
    local function fmtPct(v2) return math.floor(v2 * 100 + 0.5) .. "%" end
    local alphaFormatters = {
        [MinimalSliderWithSteppersMixin.Label.Min] = function() return "20%" end,
        [MinimalSliderWithSteppersMixin.Label.Max] = function() return "100%" end,
        [MinimalSliderWithSteppersMixin.Label.Top] = function(v2) return L["Panel opacity"] .. ": " .. fmtPct(v2) end,
    }
    SplitWatchDB.panelAlpha = SplitWatchDB.panelAlpha or 0.85
    alphaSlider:Init(SplitWatchDB.panelAlpha, 0.2, 1.0, 16, alphaFormatters)
    alphaSlider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, v2)
        v2 = math.floor(v2 * 100 + 0.5) / 100
        SplitWatchDB.panelAlpha = v2
        if panel then panel:SetAlpha(v2) end
    end, alphaSlider)
    addTooltip(alphaSlider, L["Opacity of this options window. Saved account-wide."])

    makeSection(parent, L["Changelog"], 14, -160, "about.changelog", 640)
    local entries = {
        { ver = "0.1.0", date = "2026-05-11", lines = {
            L["• Initial release: manual weight mode, snake-distribution algorithm, preview pane with before/after stats, permission-gated Apply via SetRaidSubgroup."],
            L["• Supports retail 12.x and MoP Classic 5.5."],
            L["• Test mode (/splitw test) for UI preview without a raid."],
        }},
    }
    local y = -195
    for _, e in ipairs(entries) do
        local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
        h:SetText(string.format("|cffffd100v%s|r |cffaaaaaa(%s)|r", e.ver, e.date))
        _registerInSection(h)
        y = y - 18
        for _, line in ipairs(e.lines) do
            local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            l:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
            _registerInSection(l)
            l:SetWidth(620); l:SetJustifyH("LEFT")
            l:SetText(line)
            y = y - (math.ceil(l:GetStringHeight()) + 6)
        end
        y = y - 6
    end

    parent.refresh = function() end
end

-- ============================================================
-- BUILD MAIN PANEL
-- ============================================================
local function build()
    panel = CreateFrame("Frame", "SplitWatchOptionsPanel", UIParent, "PortraitFrameTemplate")
    panel:SetSize(720, 540)
    local db = SplitW:GetDB()
    if db.panelPoint then
        panel:SetPoint(db.panelPoint.point, UIParent, db.panelPoint.relPoint,
                       db.panelPoint.x, db.panelPoint.y)
    else
        panel:SetPoint("CENTER")
    end
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint(1)
        SplitW:GetDB().panelPoint = {
            point = point, relPoint = relPoint,
            x = math.floor(x + 0.5), y = math.floor(y + 0.5),
        }
    end)
    panel:SetFrameStrata("HIGH")
    panel:Hide()

    -- Account-wide opacity (mirrors BossWatch's 0.85 default).
    SplitWatchDB = SplitWatchDB or {}
    if SplitWatchDB.panelAlpha == nil then SplitWatchDB.panelAlpha = 0.85 end
    panel:SetAlpha(SplitWatchDB.panelAlpha)

    -- Title
    if panel.TitleContainer and panel.TitleContainer.TitleText then
        panel.TitleContainer.TitleText:SetText("SplitWatch")
    elseif panel.TitleText then
        panel.TitleText:SetText("SplitWatch")
    end

    -- Portrait — PortraitFrameTemplate exposes either `panel.portrait` (legacy)
    -- or `panel.PortraitContainer.portrait` (modern). Set both, harmlessly.
    local PORTRAIT_TEX = "Interface\\AddOns\\SplitWatch\\Media\\logo.tga"
    if panel.portrait then panel.portrait:SetTexture(PORTRAIT_TEX) end
    if panel.PortraitContainer and panel.PortraitContainer.portrait then
        panel.PortraitContainer.portrait:SetTexture(PORTRAIT_TEX)
    end
    if panel.SetPortraitToAsset then
        pcall(panel.SetPortraitToAsset, panel, PORTRAIT_TEX)
    end

    -- Page holder — leave a clear strip at the bottom so the docked tabs aren't
    -- visually clipped under page content (BW gets away with 8px because its pages
    -- are scrollable; ours aren't yet, so use 32px).
    pageHolder = CreateFrame("Frame", nil, panel)
    pageHolder:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -60)
    pageHolder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 32)

    local function makePage(name, builder)
        local p = CreateFrame("Frame", nil, pageHolder)
        p:SetAllPoints(pageHolder)
        p:Hide()
        builder(p)
        pages[name] = p
        return p
    end

    makePage("setup",   buildSetupPage)
    makePage("weights", buildWeightsPage)
    makePage("preview", buildPreviewPage)
    makePage("about",   buildAboutPage)

    -- Bottom tabs
    local tabDefs = {
        { id = "setup",   label = L["Setup"]   },
        { id = "weights", label = L["Weights"] },
        { id = "preview", label = L["Preview"] },
        { id = "about",   label = L["About"]   },
    }
    local tabFrames = {}
    selectTab = function(id)
        for _, t in ipairs(tabFrames) do
            if t.id == id then
                PanelTemplates_SelectTab(t)
            else
                PanelTemplates_DeselectTab(t)
            end
        end
        for k, p in pairs(pages) do
            if k == id then p:Show(); if p.refresh then p:refresh() end
            else p:Hide() end
        end
        panel._currentTab = id
    end

    for i, def in ipairs(tabDefs) do
        local t = CreateFrame("Button", "SplitWatchTab"..i, panel, "PanelTabButtonTemplate")
        t.id = def.id
        t:SetID(i)
        t:SetText(def.label)
        PanelTemplates_TabResize(t, 0)
        tabFrames[i] = t
    end
    local function layoutTabs()
        local available = panel:GetWidth() - 24
        local x, y = 12, 2
        local rowH = 24
        local row = 0
        local baseLevel = panel:GetFrameLevel()
        for _, tab in ipairs(tabFrames) do
            local w = tab:GetWidth()
            if x > 12 and (x + w) > available + 12 then
                x = 12; y = y - rowH; row = row + 1
            end
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", x, y)
            tab:SetFrameLevel(baseLevel + 2 + row * 2)
            x = x + w + 2
        end
    end
    layoutTabs()
    panel:HookScript("OnSizeChanged", layoutTabs)
    for _, t in ipairs(tabFrames) do
        t:SetScript("OnClick", function() selectTab(t.id) end)
        addTooltip(t, t:GetText() or "")
    end

    -- Refresh all pages
    refresh = function()
        local cur = pages[panel._currentTab or "setup"]
        if cur and cur.refresh then cur:refresh() end
    end
    SplitW.RefreshAll = refresh
    panel.refreshAll = refresh

    selectTab("setup")

    -- ============================================================
    -- SIDE TABS (sister addons)
    -- ============================================================
    local SIDE_TAB_SIZE = 48
    local sideTabs = {
        { id = "SplitWatch", isSelf = true, icon = "Interface\\AddOns\\SplitWatch\\Media\\logo.tga",
          tooltip = L["SplitWatch — Options"], onClick = function() end },
        { id = "BossWatch", isSelf = false, icon = "Interface\\AddOns\\BossWatch\\Media\\logo.tga",
          tooltip = L["Open BossWatch options"],
          loadedCheck = function()
              local BW = _G.BossWatch
              return C_AddOns and C_AddOns.IsAddOnLoaded
                     and C_AddOns.IsAddOnLoaded("BossWatch")
                     and BW and BW.ToggleOptions
          end,
          onClick = function()
              local point, _, relPoint, x, y
              if panel and panel:IsShown() then
                  point, _, relPoint, x, y = panel:GetPoint(1)
                  panel:Hide()
              end
              local BW = _G.BossWatch
              if BW and BW.ShowOptionsAt and point then
                  BW:ShowOptionsAt(point, relPoint, x, y)
              elseif BW and BW.ToggleOptions then
                  BW:ToggleOptions()
              end
          end },
        { id = "TankWatch", isSelf = false, icon = "Interface\\AddOns\\TankWatch\\Media\\icon",
          tooltip = L["Open TankWatch options"],
          loadedCheck = function()
              local TW = _G.TankWatch
              return C_AddOns and C_AddOns.IsAddOnLoaded
                     and C_AddOns.IsAddOnLoaded("TankWatch")
                     and TW and TW.ToggleOptions
          end,
          onClick = function()
              local point, _, relPoint, x, y
              if panel and panel:IsShown() then
                  point, _, relPoint, x, y = panel:GetPoint(1)
                  panel:Hide()
              end
              local TW = _G.TankWatch
              if TW and TW.ShowOptionsAt and point then
                  TW:ShowOptionsAt(point, relPoint, x, y)
              elseif TW and TW.ToggleOptions then
                  TW:ToggleOptions()
              end
          end },
    }
    local visibleIdx = 0
    for _, def in ipairs(sideTabs) do
        if def.isSelf or (def.loadedCheck and def.loadedCheck()) then
            visibleIdx = visibleIdx + 1
            local tab = CreateFrame("Button", nil, panel, "BackdropTemplate")
            tab:SetSize(SIDE_TAB_SIZE, SIDE_TAB_SIZE)
            tab:SetPoint("TOPLEFT", panel, "TOPLEFT", -SIDE_TAB_SIZE + 8,
                         -68 - (visibleIdx - 1) * (SIDE_TAB_SIZE + 8))
            tab:SetFrameLevel(panel:GetFrameLevel() + 5)
            tab:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            tab:SetBackdropColor(0.04, 0.04, 0.07, 0.95)
            local icon = tab:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("CENTER")
            icon:SetSize(SIDE_TAB_SIZE - 14, SIDE_TAB_SIZE - 14)
            icon:SetTexture(def.icon)
            icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            local function makeEdge(p1, p2, w, h)
                local t = tab:CreateTexture(nil, "BORDER")
                t:SetPoint(p1, tab, p1, 0, 0); t:SetPoint(p2, tab, p2, 0, 0)
                if w then t:SetWidth(w) end
                if h then t:SetHeight(h) end
                return t
            end
            local edges = {
                makeEdge("TOPLEFT", "TOPRIGHT", nil, 1),
                makeEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1),
                makeEdge("TOPLEFT", "BOTTOMLEFT", 1, nil),
                makeEdge("TOPRIGHT", "BOTTOMRIGHT", 1, nil),
            }
            local function setEdge(r, g, b, a)
                for _, t in ipairs(edges) do t:SetColorTexture(r, g, b, a) end
            end
            setEdge(0.20, 0.20, 0.24, 1)
            local marker = tab:CreateTexture(nil, "OVERLAY")
            marker:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -0.5, -3)
            marker:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -0.5, 3)
            marker:SetWidth(3); marker:SetColorTexture(1, 0.82, 0, 1)
            marker:Hide()
            if def.isSelf then
                setEdge(1, 0.82, 0, 1); marker:Show(); tab:EnableMouse(false)
            else
                tab:HookScript("OnEnter", function() setEdge(1, 0.82, 0, 1) end)
                tab:HookScript("OnLeave", function() setEdge(0.20, 0.20, 0.24, 1) end)
                tab:SetScript("OnClick", def.onClick)
            end
            addTooltip(tab, def.tooltip)
        end
    end
end

-- ============================================================
-- PUBLIC ENTRY POINTS
-- ============================================================
function SplitW:ToggleOptions()
    if not panel then build() end
    SplitW._panel = panel
    if panel:IsShown() then
        panel:Hide()
    else
        if panel.refreshAll then panel.refreshAll() end
        panel:Show()
    end
end

function SplitW:ShowOptionsAt(point, relPoint, x, y)
    if not panel then build() end
    SplitW._panel = panel
    if point then
        panel:ClearAllPoints()
        panel:SetPoint(point, UIParent, relPoint or point, x or 0, y or 0)
        SplitW:GetDB().panelPoint = {
            point = point, relPoint = relPoint or point,
            x = math.floor((x or 0) + 0.5),
            y = math.floor((y or 0) + 0.5),
        }
    end
    if panel.refreshAll then panel.refreshAll() end
    panel:Show()
end

function SplitW:RegisterBlizzardSettings()
    if SplitW._settingsCategoryID or not Settings or not Settings.RegisterCanvasLayoutCategory then
        return
    end
    local host = CreateFrame("Frame")
    host.name = "SplitWatch"

    local title = host:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16); title:SetText("SplitWatch")

    local v = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local sub = host:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetWidth(540); sub:SetJustifyH("LEFT")
    sub:SetText(format(L["Auto-split your 20-man raid — v%s\nClick the button below to open the SplitWatch options panel."], v))

    local btn = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    btn:SetSize(220, 26)
    btn:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
    btn:SetText(L["Open SplitWatch options"])
    btn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if not panel or not panel:IsShown() then SplitW:ToggleOptions() end
    end)
    addTooltip(btn, L["Open the floating SplitWatch options panel."])

    local hint = host:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["You can also use the slash command: /splitw"])

    local category = Settings.RegisterCanvasLayoutCategory(host, "SplitWatch")
    category.ID = "SplitWatch"
    Settings.RegisterAddOnCategory(category)
    SplitW._settingsCategoryID = category:GetID()
end
