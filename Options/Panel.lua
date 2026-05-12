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
-- collapse/reset operate on the right list.
local _currentSection = nil
-- Chain of last-built section per page (so subsequent sections anchor to the
-- previous section's BOTTOMLEFT, which makes the lower sections move up when
-- an upper section is collapsed).
local _lastSectionOnPage = {}
local _allSectionsOnPage = {}

local SECTION_GAP = 18
local COLLAPSED_HEIGHT = 22

-- Capture all of widget's SetPoint anchors, reparent it onto the container, and
-- re-anchor it relative to the container. y offsets are translated from page-
-- relative to container-relative by subtracting the section's origin y.
local function _captureAndReparent(widget, container, sectionOriginY)
    if not widget or not widget.GetPoint or not widget.SetPoint or not widget.SetParent then return end
    local nPoints = widget.GetNumPoints and widget:GetNumPoints() or 0
    if nPoints == 0 then return end
    local pageRoot = container:GetParent()
    local saved = {}
    for i = 1, nPoints do
        local p, relTo, relPoint, x, y = widget:GetPoint(i)
        saved[i] = { p = p, relTo = relTo, relPoint = relPoint, x = x or 0, y = y or 0 }
    end
    widget:SetParent(container)
    widget:ClearAllPoints()
    for _, a in ipairs(saved) do
        local relTo = a.relTo
        local newY  = a.y
        -- If the widget was anchored to the page itself, switch its anchor to
        -- the container at an equivalent local Y so it tracks container moves.
        if relTo == pageRoot or relTo == nil then
            relTo = container
            newY  = a.y - sectionOriginY
        end
        widget:SetPoint(a.p, relTo, a.relPoint, a.x, newY)
    end
end

local function _registerInSection(widget, dbKey)
    if not _currentSection or not widget then return end
    _currentSection.children[#_currentSection.children + 1] = widget
    if dbKey then
        _currentSection.dbKeys[#_currentSection.dbKeys + 1] = dbKey
    end
    _captureAndReparent(widget, _currentSection.container, _currentSection._originY)
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

local function fmtNum(v)
    if not v or v <= 0 then return "|cff666666—|r" end
    if v >= 1e6 then return string.format("%.2fM", v / 1e6) end
    if v >= 1e3 then return string.format("%.1fk", v / 1e3) end
    return string.format("%d", math.floor(v + 0.5))
end

local function roleIcon(role, size)
    size = size or 14
    if role == "TANK"   then return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:0:19:22:41|t", size, size) end
    if role == "HEALER" then return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:20:39:1:20|t", size, size) end
    return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:20:39:22:41|t", size, size)
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

local function makeDropdown(parent, label, key, options, x, y, width, tip, availabilityFn)
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
                    if refresh then refresh() end
                end)
            if not available and radio and radio.SetEnabled then
                radio:SetEnabled(false)
            end
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
        _originY = y,
    }

    -- Container frame: chains under the previous section on this page so when
    -- one is collapsed the rest move up automatically. First section anchors
    -- at the requested page-level (x, y); the right edge always sticks to the
    -- page's right edge for a consistent full-width look.
    local container = CreateFrame("Frame", nil, parent)
    local prev = _lastSectionOnPage[parent]
    if prev then
        container:SetPoint("TOPLEFT",  prev.container, "BOTTOMLEFT", 0, -SECTION_GAP)
        container:SetPoint("TOPRIGHT", prev.container, "BOTTOMRIGHT", 0, -SECTION_GAP)
    else
        container:SetPoint("TOPLEFT",  parent, "TOPLEFT",  x, y)
        container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
    end
    container:SetHeight(COLLAPSED_HEIGHT)
    section.container = container
    _lastSectionOnPage[parent] = section
    _allSectionsOnPage[parent] = _allSectionsOnPage[parent] or {}
    _allSectionsOnPage[parent][#_allSectionsOnPage[parent] + 1] = section

    -- Header (inside container at relative top so it moves with the container)
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    header:SetText(title)
    header:SetTextColor(1, 0.82, 0)
    section.header = header

    local chevron = container:CreateTexture(nil, "OVERLAY")
    chevron:SetSize(14, 14)
    chevron:SetPoint("LEFT", header, "RIGHT", 4, -1)
    chevron:SetTexture(TEX_EXPANDED)
    section.chevron = chevron

    -- Reset button at the right edge of the container
    local btnReset = CreateFrame("Button", nil, container)
    btnReset:SetSize(14, 14)
    btnReset:SetPoint("TOPRIGHT", container, "TOPRIGHT", -8, -2)
    btnReset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    btnReset:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    btnReset:SetFrameLevel(container:GetFrameLevel() + 6)
    section.resetBtn = btnReset

    -- Click area: the header strip, minus the reset-button zone
    local clickArea = CreateFrame("Button", nil, container)
    clickArea:SetPoint("TOPLEFT",     container, "TOPLEFT",  -4,  4)
    clickArea:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", -28, -16)
    clickArea:SetFrameLevel(container:GetFrameLevel() + 5)
    clickArea:RegisterForClicks("LeftButtonUp")
    section.clickArea = clickArea

    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT",  header,    "BOTTOMLEFT", 0, -3)
    line:SetPoint("TOPRIGHT", container, "TOPRIGHT",  -28, -19)
    line:SetHeight(1)
    line:SetColorTexture(1, 0.82, 0, 0.35)
    section.line = line

    function section:UpdateNaturalHeight()
        if self._collapsed then
            self.container:SetHeight(COLLAPSED_HEIGHT)
            return
        end
        local cTop = self.container:GetTop()
        if not cTop then
            C_Timer.After(0, function() self:UpdateNaturalHeight() end)
            return
        end
        local lowest, anyPos = cTop, false
        for _, w in ipairs(self.children) do
            if w.IsShown and w:IsShown() and w.GetBottom then
                local b = w:GetBottom()
                if b then
                    anyPos = true
                    if b < lowest then lowest = b end
                end
            end
        end
        if not anyPos and #self.children > 0 then
            C_Timer.After(0, function() self:UpdateNaturalHeight() end)
            return
        end
        local span = math.max(COLLAPSED_HEIGHT, cTop - lowest + 8)
        self.container:SetHeight(span)
    end

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
        if state then
            self.container:SetHeight(COLLAPSED_HEIGHT)
        else
            self:UpdateNaturalHeight()
        end
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
    -- Defer natural-height resolution to the next frame so widgets registered
    -- after this point have actually positioned themselves.
    C_Timer.After(0, function() section:UpdateNaturalHeight() end)
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
    -- Sections chain vertically; widget Y coords stay the same since
    -- _captureAndReparent translates page-Y to container-local-Y using each
    -- section's original Y as the origin.
    makeSection(parent, L["General"], 14, -8, "setup.general")
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
    markAsNew(makeCheck(parent, L["Broadcast team composition on Apply"], "broadcastOnApply",
        360, -40, L["Post the team rosters to chat when a split is applied."]),
        "broadcastOnApply")
    local channels = {
        { text = L["Raid chat"],          value = "RAID"          },
        { text = L["Raid warning"],       value = "RAID_WARNING"  },
        { text = L["Party chat"],         value = "PARTY"         },
        { text = L["Say"],                value = "SAY"           },
    }
    markAsNew(makeDropdown(parent, L["Broadcast channel"], "broadcastChannel",
        channels, 360, -90, 200,
        L["Where to post the team-rosters message when Broadcast is enabled."]),
        "broadcastChannel")

    makeSection(parent, L["DPS source"], 14, -160, "setup.dps_source")
    local sources = {
        { text = "Details!",                       value = "DETAILS" },
        { text = "Recount",                        value = "RECOUNT" },
        { text = "Skada",                          value = "SKADA"   },
        { text = L["Item Level (inspect)"],        value = "ILVL"    },
        { text = L["Manual (per-player slider)"], value = "MANUAL"  },
    }
    makeDropdown(parent, L["Pick the data source for DPS / HPS"], "dpsSource",
        sources, 14, -195, 220,
        L["Details!/Recount/Skada read live DPS+HPS from those addons when loaded. Item Level inspects each raid member (28y range). Manual uses the per-player sliders on the Weights tab."],
        function(v) return SplitW.DPSSource and SplitW.DPSSource:IsAvailable(v) end)

    local statusFS = makeLabel(parent, "", 260, -211)
    statusFS.refresh = function()
        statusFS:SetText("|cffaaaaaa" .. L["Active source"] .. ":|r " .. SplitW.DPSSource:ActiveSourceLabel())
    end
    statusFS:refresh()

    -- Refresh-ilvl button — only active when the ILVL source is selected
    -- (the inspect cache feeds only that source, no point scanning otherwise).
    local refreshIlvlBtn = makeButton(parent, L["Scan raid ilvl"], 260, -230, 140, function()
        if SplitW.DPSSource and SplitW.DPSSource.RefreshIlvl then
            SplitW.DPSSource:RefreshIlvl()
            C_Timer.After(0.5, function()
                if parent._refreshPreview then parent._refreshPreview() end
                statusFS:refresh()
            end)
        end
    end, L["Inspect every raid member to fetch their average item level. Each inspect is ~1.5s and limited to a 28-yard range. Active only when the Item Level source is selected."])
    parent._syncIlvlBtn = function()
        refreshIlvlBtn:SetEnabled(SplitW:GetDB().dpsSource == "ILVL")
    end
    parent._syncIlvlBtn()
    -- makeLabel already registered statusFS — but only since the recent factory change.
    -- Defensive: re-register isn't needed.

    -- ---- Live source preview (read-only check that the picker is wired) ----
    makeSection(parent, L["Source preview"], 14, -340, "setup.source_preview")
    local hintFS = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hintFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -364)
    hintFS:SetWidth(600); hintFS:SetJustifyH("LEFT")
    hintFS:SetText(L["Live values read from the selected source — use this to confirm your damage meter is feeding data before you compute a split."])
    _registerInSection(hintFS)

    local previewScroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    previewScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -382)
    previewScroll:SetSize(600, 110)
    local previewContent = CreateFrame("Frame", nil, previewScroll)
    previewContent:SetSize(580, 1)
    previewScroll:SetScrollChild(previewContent)
    _registerInSection(previewScroll)
    local previewRows, previewEmpty = {}, nil

    local function refreshPreview()
        local roster = SplitW.Roster:Scan()
        local list, fromSource = {}, false
        for _, e in ipairs(roster.tanks)   do table.insert(list, e) end
        for _, e in ipairs(roster.healers) do table.insert(list, e) end
        for _, e in ipairs(roster.dps)     do table.insert(list, e) end
        if #list == 0 and SplitW.DPSSource and SplitW.DPSSource.ListActors then
            for _, a in ipairs(SplitW.DPSSource:ListActors()) do
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
                row:SetSize(580, 18)
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
            previewEmpty:SetWidth(560); previewEmpty:SetJustifyH("LEFT")
            previewEmpty:SetText(L["No data — join a raid, enable test mode, or fight something so the active source has actors to show."])
            previewEmpty:Show()
        elseif previewEmpty then
            previewEmpty:Hide()
        end
    end
    parent._refreshPreview = refreshPreview
    refreshPreview()

    -- Auto-refresh every 1.5s while the Réglages tab is shown.
    local pageSF = parent:GetParent()
    local ticker
    if pageSF then
        pageSF:HookScript("OnShow", function()
            refreshPreview()
            if ticker then ticker:Cancel() end
            ticker = C_Timer.NewTicker(1.5, refreshPreview)
        end)
        pageSF:HookScript("OnHide", function()
            if ticker then ticker:Cancel(); ticker = nil end
        end)
    end

    makeSection(parent, L["Permission status"], 14, -520, "setup.permissions")
    local permFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    permFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -548)
    permFS:SetWidth(600); permFS:SetJustifyH("LEFT")
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

    -- ---- Presets section (save / load / delete named configurations) ----
    makeSection(parent, L["Presets"], 14, -600, "setup.presets")
    local pHint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    pHint:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -624)
    pHint:SetWidth(600); pHint:SetJustifyH("LEFT")
    pHint:SetText(L["Save the current constraints + locks + DPS source under a name. Reload any preset before a specific fight."])
    _registerInSection(pHint)

    local presetEdit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    presetEdit:SetSize(220, 22)
    presetEdit:SetPoint("TOPLEFT", parent, "TOPLEFT", 22, -650)
    presetEdit:SetAutoFocus(false)
    presetEdit:SetMaxLetters(40)
    presetEdit:SetFontObject("GameFontHighlightSmall")
    presetEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    _registerInSection(presetEdit)

    local presetSaveBtn = makeButton(parent, L["Save preset"], 250, -650, 120, function()
        local n = presetEdit:GetText()
        if n and n ~= "" then
            SplitW:SavePreset(n)
            presetEdit:SetText("")
            presetEdit:ClearFocus()
            if parent._refreshPresetList then parent._refreshPresetList() end
        end
    end, L["Save the current configuration under the name in the box."])

    local presetRestoreBtn = makeButton(parent, L["Restore built-ins"], 380, -650, 180, function()
        StaticPopup_Show("SPLITWATCH_RESTORE_PRESETS")
    end, L["Load the bundled split-fight presets (Spirit Kings, Lei Shen, Council, Conclave). Existing presets with the same name will be overwritten."])

    -- Scrollable list of saved presets with per-row Load + Delete buttons.
    local presetScroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    presetScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -682)
    presetScroll:SetSize(600, 110)
    local presetContent = CreateFrame("Frame", nil, presetScroll)
    presetContent:SetSize(580, 1)
    presetScroll:SetScrollChild(presetContent)
    _registerInSection(presetScroll)
    local presetRows = {}
    local presetEmpty

    local function refreshPresetList()
        local names = SplitW:ListPresets()
        for i, n in ipairs(names) do
            local row = presetRows[i]
            if not row then
                row = CreateFrame("Frame", nil, presetContent)
                row:SetSize(580, 22)
                row:SetPoint("TOPLEFT", presetContent, "TOPLEFT", 0, -(i - 1) * 24)
                row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.nameFS:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.nameFS:SetWidth(300); row.nameFS:SetJustifyH("LEFT")
                row.loadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.loadBtn:SetSize(80, 20)
                row.loadBtn:SetPoint("LEFT", row.nameFS, "RIGHT", 8, 0)
                row.loadBtn:SetText(L["Load"])
                row.delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.delBtn:SetSize(80, 20)
                row.delBtn:SetPoint("LEFT", row.loadBtn, "RIGHT", 8, 0)
                row.delBtn:SetText(L["Delete"])
                presetRows[i] = row
            end
            row.nameFS:SetText(n)
            row.loadBtn:SetScript("OnClick", function()
                if SplitW:LoadPreset(n) then
                    print("|cffffd100SplitWatch:|r " .. format(L["preset loaded: %s"], n))
                    if SplitW.RefreshAll then SplitW:RefreshAll() end
                end
            end)
            row.delBtn:SetScript("OnClick", function()
                local popup = StaticPopup_Show("SPLITWATCH_CONFIRM_DELETE_PRESET", n)
                if popup then popup.data = n end
            end)
            row:Show()
        end
        for i = #names + 1, #presetRows do presetRows[i]:Hide() end
        presetContent:SetHeight(math.max(1, #names * 24 + 4))
        if #names == 0 then
            presetEmpty = presetEmpty or presetContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            presetEmpty:SetPoint("TOPLEFT", presetContent, "TOPLEFT", 14, -8)
            presetEmpty:SetWidth(560); presetEmpty:SetJustifyH("LEFT")
            presetEmpty:SetText(L["No presets yet — save the current config to start."])
            presetEmpty:Show()
        elseif presetEmpty then
            presetEmpty:Hide()
        end
    end
    parent._refreshPresetList = refreshPresetList
    refreshPresetList()

    -- Classic banner
    if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        local banner = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        banner:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -810)
        banner:SetWidth(600); banner:SetJustifyH("LEFT")
        banner:SetText("|cffffd100" .. L["WARN_CLASSIC"] .. "|r")
    end

    parent.refresh = function()
        statusFS:refresh()
        permFS:refresh()
        if parent._syncIlvlBtn      then parent._syncIlvlBtn()      end
        if parent._refreshPreview   then parent._refreshPreview()   end
        if parent._refreshPresetList then parent._refreshPresetList() end
    end
end

-- ----------------------------------------------------------------
-- WEIGHTS PAGE
-- ----------------------------------------------------------------
local function buildWeightsPage(parent)
    -- ---- Constraints section (team-composition rules) ----
    makeSection(parent, L["Constraints"], 14, -8, "players.constraints")
    local cintro = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cintro:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -32)
    cintro:SetWidth(600); cintro:SetJustifyH("LEFT")
    cintro:SetText("|cffaaaaaa" .. L["Composition rules applied AFTER the score-based snake distribution. Each toggle swaps minimally-disruptive DPS pairs to satisfy the rule."] .. "|r")
    _registerInSection(cintro)
    markAsNew(makeCheck(parent, L["Battle Rez per team (Druid/DK/Warlock/Hunter/Paladin/DH)"],
        "constraintBR", 14, -58,
        L["Enforce at least one battle-rez class per team."]), "constraintBR")
    markAsNew(makeCheck(parent, L["Bloodlust per team (Shaman/Mage/Hunter/Evoker)"],
        "constraintLust", 14, -86,
        L["Enforce at least one Bloodlust/Heroism/Time Warp/Primal Rage source per team."]), "constraintLust")
    markAsNew(makeCheck(parent, L["Balance melee vs ranged"],
        "constraintMR", 14, -114,
        L["Equalise the melee/ranged DPS ratio between teams. Class-based heuristic (Druid/Shaman/Hunter default to ranged)."]), "constraintMR")
    markAsNew(makeCheck(parent, L["Mass Dispel per team (Priest)"],
        "constraintMassDisp", 14, -142,
        L["Enforce at least one Priest per team for Mass Dispel."]), "constraintMassDisp")
    markAsNew(makeCheck(parent, L["Decurse per team (Mage/Druid/Shaman)"],
        "constraintDecurse", 14, -170,
        L["Enforce at least one decurse class per team."]), "constraintDecurse")
    markAsNew(makeCheck(parent, L["External CD healer per team (Paladin/Priest/Druid/Monk healer)"],
        "constraintExternal", 14, -198,
        L["Enforce at least one healer with a tank-targetable defensive (BoP, Pain Sup, Ironbark, Life Cocoon) per team."]), "constraintExternal")
    markAsNew(makeCheck(parent, L["Soak immunity per team (Paladin/Mage/Hunter)"],
        "constraintSoak", 14, -226,
        L["Enforce at least one full damage-immunity class (Divine Shield / Ice Block / Aspect of the Turtle) per team."]), "constraintSoak")

    -- ---- Active locks section (lists pinned players, lets RL free them) ----
    makeSection(parent, L["Active locks"], 14, -270, "players.locks")
    local lHint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lHint:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -294)
    lHint:SetWidth(600); lHint:SetJustifyH("LEFT")
    lHint:SetText(L["Players pinned to a specific team. Right-click a name in the Preview team columns to add a lock; use the buttons below to remove one."])
    _registerInSection(lHint)

    local locksScroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    locksScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -320)
    locksScroll:SetSize(600, 90)
    local locksContent = CreateFrame("Frame", nil, locksScroll)
    locksContent:SetSize(580, 1)
    locksScroll:SetScrollChild(locksContent)
    _registerInSection(locksScroll)
    local locksRows = {}
    local locksEmpty

    local clearAllBtn = makeButton(parent, L["Clear all locks"], 14, -418, 160, function()
        StaticPopup_Show("SPLITWATCH_CONFIRM_CLEAR_LOCKS")
    end, L["Remove every player lock."])

    local function refreshLocks()
        local db = SplitW:GetDB()
        local pairs_ = {}
        for n, t in pairs(db.lockedTeams or {}) do pairs_[#pairs_ + 1] = { name = n, team = t } end
        table.sort(pairs_, function(a, b) return a.name < b.name end)
        for i, p in ipairs(pairs_) do
            local row = locksRows[i]
            if not row then
                row = CreateFrame("Frame", nil, locksContent)
                row:SetSize(580, 22)
                row:SetPoint("TOPLEFT", locksContent, "TOPLEFT", 0, -(i - 1) * 24)
                row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.nameFS:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.nameFS:SetWidth(280); row.nameFS:SetJustifyH("LEFT")
                row.teamFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.teamFS:SetPoint("LEFT", row.nameFS, "RIGHT", 4, 0)
                row.teamFS:SetWidth(80); row.teamFS:SetJustifyH("LEFT")
                row.freeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.freeBtn:SetSize(80, 20)
                row.freeBtn:SetPoint("LEFT", row.teamFS, "RIGHT", 8, 0)
                row.freeBtn:SetText(L["Free"])
                locksRows[i] = row
            end
            row.nameFS:SetText(p.name)
            row.teamFS:SetText(string.format("|cffffd100→ %s|r", p.team))
            row.freeBtn:SetScript("OnClick", function()
                SplitW:SetLock(p.name, nil)
                refreshLocks()
                if SplitW.RefreshAll then SplitW:RefreshAll() end
            end)
            row:Show()
        end
        for i = #pairs_ + 1, #locksRows do locksRows[i]:Hide() end
        locksContent:SetHeight(math.max(1, #pairs_ * 24 + 4))
        if #pairs_ == 0 then
            locksEmpty = locksEmpty or locksContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            locksEmpty:SetPoint("TOPLEFT", locksContent, "TOPLEFT", 14, -8)
            locksEmpty:SetWidth(560); locksEmpty:SetJustifyH("LEFT")
            locksEmpty:SetText(L["No active locks."])
            locksEmpty:Show()
        elseif locksEmpty then
            locksEmpty:Hide()
        end
    end
    parent._refreshLocks = refreshLocks
    refreshLocks()

    -- ---- Manual weights section ----
    makeSection(parent, L["Manual weights"], 14, -460, "weights.main", 640)
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -484)
    hint:SetWidth(600); hint:SetJustifyH("LEFT")
    hint:SetText("|cffaaaaaa" .. L["Adjust each DPS player's relative weight (1-100). Higher = goes into the lower-scoring team first. Used only when source = Manual."] .. "|r")
    _registerInSection(hint)

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -508)
    scroll:SetSize(600, 280)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(580, 1)
    scroll:SetScrollChild(content)
    _registerInSection(scroll)

    local rows = {}
    local function makeRow(idx)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(580, 24)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(idx-1) * 26)
        -- Role icon (20px) FIRST, then name right next to it.
        row.roleFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.roleFS:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.roleFS:SetWidth(22); row.roleFS:SetJustifyH("CENTER")
        row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.nameFS:SetPoint("LEFT", row.roleFS, "RIGHT", 4, 0)
        row.nameFS:SetWidth(200); row.nameFS:SetJustifyH("LEFT")

        row.slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
        row.slider:SetWidth(220); row.slider:SetHeight(14)
        row.slider:SetPoint("LEFT", row.nameFS, "RIGHT", 8, 0)
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
            row.roleFS:SetText(roleIcon(entry.role, 20))
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
            row_empty:SetWidth(560); row_empty:SetJustifyH("LEFT")
            row_empty:SetText(L["No raid members detected. Use /splitw test for a simulated 20-man roster."])
            row_empty:Show()
        elseif row_empty then
            row_empty:Hide()
        end
    end

    -- Action bar — below the scroll (TOPLEFT-anchored at a fixed Y rather than
    -- BOTTOMLEFT, so the chained section sizes them predictably).
    local resetBtn = makeButton(parent, L["Reset all weights"], 14, -800, 160, function()
        StaticPopup_Show("SPLITWATCH_CONFIRM_RESET_WEIGHTS")
    end, L["Reset every stored weight back to the default value."])

    local refreshBtn = makeButton(parent, L["Refresh roster"], 182, -800, 160, function()
        populate()
    end, L["Re-read the raid roster from Blizzard's API."])

    local function testLabel()
        return SplitW.Roster:IsTestMode() and L["Disable test mode"] or L["Enable test mode"]
    end
    local testBtn = makeButton(parent, testLabel(), 350, -800, 160, function() end,
        L["Use a simulated 20-man roster for UI testing."])
    testBtn:SetScript("OnClick", function()
        SplitW.Roster:SetTestMode(not SplitW.Roster:IsTestMode())
        testBtn:SetText(testLabel())
        populate()
    end)

    parent.refresh = function()
        populate()
        if parent._refreshLocks then parent._refreshLocks() end
    end
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
        SplitW._rosterDirty = false
        if parent.refresh then parent.refresh() end
    end, L["Read the current roster and run the snake-distribution algorithm."])

    local applyBtn = makeButton(parent, L["Apply split"], 178, -38, 160, function()
        if SplitW:GetDB().confirmApply then
            StaticPopup_Show("SPLITWATCH_CONFIRM_APPLY")
        else
            SplitW.Apply:Run()
        end
    end, L["Move every player to their assigned subgroup. Requires leader or assistant."])

    -- Test-mode toggle — label flips between Enable/Disable based on state.
    local function testLabel()
        return SplitW.Roster:IsTestMode() and L["Disable test mode"] or L["Enable test mode"]
    end
    local testBtn = makeButton(parent, testLabel(), 342, -38, 180, function() end,
        L["Use a simulated 20-man roster for UI testing."])
    testBtn:SetScript("OnClick", function()
        SplitW.Roster:SetTestMode(not SplitW.Roster:IsTestMode())
        testBtn:SetText(testLabel())
        local r = SplitW.Roster:Scan()
        SplitW:GetDB().lastSplit = SplitW.Splitter:Compute(r)
        if parent.refresh then parent.refresh() end
    end)
    parent._testBtnRefresh = function() testBtn:SetText(testLabel()) end

    -- Options tied to the buttons above — placed right under them so RL
    -- doesn't have to bounce to Réglages.
    markAsNew(makeCheck(parent, L["Auto-rebalance after manual swap"],
        "autoRebalanceAfterSwap", 14, -68,
        L["When OFF (default), a 2-click manual swap only moves those two players. When ON, the algorithm recomputes the entire split with the swapped pair locked, redistributing everyone else."]),
        "autoRebalanceAfterSwap")
    markAsNew(makeSlider(parent, L["Test roster size"], "testRosterSize",
        10, 40, 1, 342, -68, 200,
        L["Number of simulated players when test mode is on. Tank/healer/DPS ratios scale automatically (e.g. 10-man → 2T+2H+6DPS, 25-man → 2T+5H+18DPS, 40-man → 3T+9H+28DPS)."]),
        "testRosterSize")

    local modeFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -108)
    modeFS:SetWidth(600); modeFS:SetJustifyH("LEFT")
    _registerInSection(modeFS)

    -- Which damage-meter source the algorithm is reading from. Visible on the
    -- Preview page so you don't have to bounce to Réglages to check.
    local srcFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    srcFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -126)
    srcFS:SetWidth(600); srcFS:SetJustifyH("LEFT")
    _registerInSection(srcFS)

    -- Roster-change banner: visible only when GROUP_ROSTER_UPDATE fired since
    -- the last successful Compute. RL clicks the inline button to recompute.
    local dirtyBanner = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dirtyBanner:SetSize(600, 28)
    dirtyBanner:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -144)
    dirtyBanner:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dirtyBanner:SetBackdropColor(0.4, 0.3, 0.05, 0.6)
    dirtyBanner:SetBackdropBorderColor(1, 0.82, 0, 0.8)
    local dirtyText = dirtyBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dirtyText:SetPoint("LEFT", dirtyBanner, "LEFT", 8, 0)
    dirtyText:SetText("|cffffd100" .. L["Roster changed since last compute."] .. "|r")
    local dirtyBtn = CreateFrame("Button", nil, dirtyBanner, "UIPanelButtonTemplate")
    dirtyBtn:SetSize(140, 22)
    dirtyBtn:SetPoint("RIGHT", dirtyBanner, "RIGHT", -6, 0)
    dirtyBtn:SetText(L["Recompute"])
    dirtyBtn:SetScript("OnClick", function()
        local r = SplitW.Roster:Scan()
        SplitW:GetDB().lastSplit = SplitW.Splitter:Compute(r)
        SplitW._rosterDirty = false
        if parent.refresh then parent.refresh() end
    end)
    addTooltip(dirtyBtn, L["Re-run the split with the updated roster."])
    dirtyBanner:Hide()
    _registerInSection(dirtyBanner)

    -- BEFORE / AFTER label. Use a Blizzard texture inline for the arrow because
    -- the FRIZQT__ font doesn't include U+2192 → and renders it as an empty box.
    local ARROW_TEX = "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:18:18:0:0|t"
    local beforeFS = makeLabel(parent, "|cffaaaaaa" .. L["Before"] .. "|r", 14, -180, "GameFontNormalLarge")
    local arrowFS  = makeLabel(parent, ARROW_TEX, 326, -182, "GameFontNormalLarge")
    local afterFS  = makeLabel(parent, "|cffffd100" .. L["After"] .. "|r", 360, -180, "GameFontNormalLarge")

    -- Stats lines
    local beforeStatsFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    beforeStatsFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -206)
    beforeStatsFS:SetWidth(300); beforeStatsFS:SetJustifyH("LEFT")
    _registerInSection(beforeStatsFS)

    local afterStatsFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    afterStatsFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 360, -206)
    afterStatsFS:SetWidth(300); afterStatsFS:SetJustifyH("LEFT")
    _registerInSection(afterStatsFS)

    -- Team A / Team B titles. Each column's player rows are individual
    -- clickable Frames (built lazily by renderTeamRows) so right-click can
    -- open the lock context menu and hover can show a per-player tooltip.
    local function makeTeamTitle(title, x)
        local titleFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleFS:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -270)
        titleFS:SetText(title)
        titleFS:SetTextColor(1, 0.82, 0)
        _registerInSection(titleFS)
        return titleFS
    end
    local titleA = makeTeamTitle(L["Team A"], 14)
    local titleB = makeTeamTitle(L["Team B"], 360)
    local baseA, baseB = L["Team A"], L["Team B"]

    -- Shared dropdown frame used by EasyMenu to render the right-click lock menu.
    local lockDropdown = _G.SplitWatchLockDropdown
        or CreateFrame("Frame", "SplitWatchLockDropdown", UIParent, "UIDropDownMenuTemplate")
    local rowsA, rowsB = {}, {}

    -- Forward-declare so the menu callback can recompute.
    local recomputeAndRefresh

    local function showLockMenu(entry, ownerFrame)
        -- Retail 12.x removed EasyMenu. Use the modern MenuUtil API when
        -- available; fall back to UIDropDownMenu_Initialize on older clients
        -- (Mists Classic 5.5 still ships the legacy dropdown helpers).
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(ownerFrame or lockDropdown, function(_, root)
                root:CreateTitle(entry.name)
                local btnA = root:CreateButton(L["Lock to Team A"], function()
                    SplitW:SetLock(entry.name, "A"); recomputeAndRefresh()
                end)
                if btnA and btnA.SetEnabled then btnA:SetEnabled(entry.locked ~= "A") end
                local btnB = root:CreateButton(L["Lock to Team B"], function()
                    SplitW:SetLock(entry.name, "B"); recomputeAndRefresh()
                end)
                if btnB and btnB.SetEnabled then btnB:SetEnabled(entry.locked ~= "B") end
                local btnF = root:CreateButton(L["Free lock"], function()
                    SplitW:SetLock(entry.name, nil); recomputeAndRefresh()
                end)
                if btnF and btnF.SetEnabled then btnF:SetEnabled(entry.locked ~= nil) end
            end)
            return
        end
        -- Legacy path
        local menu = {
            { text = entry.name, isTitle = true, notCheckable = true },
            { text = " ",        disabled = true, notCheckable = true },
            { text = L["Lock to Team A"],
              func = function() SplitW:SetLock(entry.name, "A"); recomputeAndRefresh() end,
              notCheckable = true,
              disabled = entry.locked == "A" },
            { text = L["Lock to Team B"],
              func = function() SplitW:SetLock(entry.name, "B"); recomputeAndRefresh() end,
              notCheckable = true,
              disabled = entry.locked == "B" },
            { text = L["Free lock"],
              func = function() SplitW:SetLock(entry.name, nil); recomputeAndRefresh() end,
              notCheckable = true,
              disabled = not entry.locked },
        }
        if UIDropDownMenu_Initialize and ToggleDropDownMenu then
            UIDropDownMenu_Initialize(lockDropdown, function(self, level)
                for _, item in ipairs(menu) do
                    local info = UIDropDownMenu_CreateInfo()
                    for k, v in pairs(item) do info[k] = v end
                    UIDropDownMenu_AddButton(info, level)
                end
            end, "MENU")
            ToggleDropDownMenu(1, nil, lockDropdown, "cursor", 0, 0)
        end
    end

    local function showRowTooltip(self)
        local e = self._entry
        if not e then return end
        local r, g, b = classColor(e.class)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(e.name, r, g, b)
        if e.class then GameTooltip:AddLine(L["Class"] .. ": " .. e.class, 1, 1, 1) end
        if e.role then  GameTooltip:AddLine(L["Role"]  .. ": " .. e.role,  1, 1, 1) end
        local dps = SplitW.DPSSource and SplitW.DPSSource:GetDPS(e.name)
        if dps and dps > 0 then GameTooltip:AddLine("DPS: " .. fmtNum(dps), 1, 1, 1) end
        local hps = SplitW.DPSSource and SplitW.DPSSource:GetHPS(e.name)
        if hps and hps > 0 then GameTooltip:AddLine("HPS: " .. fmtNum(hps), 1, 1, 1) end
        local mw = SplitW:GetWeight(e.name)
        if mw then GameTooltip:AddLine(L["Manual weight"] .. ": " .. mw, 1, 1, 1) end
        if e.locked then
            GameTooltip:AddLine(string.format(L["Locked on Team %s"], e.locked), 1, 0.82, 0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffaaaaaa" .. L["Right-click for lock options"] .. "|r")
        GameTooltip:AddLine("|cffaaaaaa" .. L["Left-click to select, then left-click an opposing-team player to swap"] .. "|r")
        GameTooltip:Show()
    end

    local LOCK_ICON  = "|TInterface\\PetBattles\\PetIcon-Mechanical:14:14:0:0:32:32:2:30:2:30|t"
    -- Movement indicator: shown when this player's team in the current split
    -- differs from the team they were on at the last Apply. Helps spot
    -- recompute churn at a glance.
    local MOVED_ICON = "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:14:14:0:0|t"
    local function buildRowText(e, src)
        local r, g, b = classColor(e.class)
        local suffix = ""
        local v = SplitW.DPSSource and SplitW.DPSSource:GetDPS(e.name)
        if v and v > 0 then
            if src == "ILVL" then
                suffix = string.format("  |cffaaaaaa[ilvl %d]|r", math.floor(v + 0.5))
            else
                suffix = string.format("  |cffaaaaaa[%s]|r", fmtNum(v))
            end
        end
        local lockBadge = e.locked and (" " .. LOCK_ICON) or ""
        local movedBadge = ""
        local prev = SplitW:GetDB().lastAppliedSplit
        if prev and prev[e.name] and prev[e.name] ~= e.team then
            movedBadge = "  |cffff8855" .. MOVED_ICON .. "|r"
        end
        return string.format("%s  |cff%02x%02x%02x%s|r%s%s%s",
            roleIcon(e.role, 16),
            math.floor(r * 255), math.floor(g * 255), math.floor(b * 255),
            e.name, lockBadge, movedBadge, suffix)
    end

    -- Drag state shared across all team rows. Left-mouse-down on a row marks
    -- it as the drag source; left-mouse-up on any other row swaps the pair
    -- by setting locks on both names. The swap persists across recomputes.
    local dragSource

    local function clearDragVisuals()
        for _, r in ipairs(rowsA) do if r.text then r.text:SetAlpha(1) end end
        for _, r in ipairs(rowsB) do if r.text then r.text:SetAlpha(1) end end
    end

    local function renderTeamRows(team, cache, anchorTitle, columnX)
        local src = SplitW:GetDB().dpsSource
        for i, e in ipairs(team) do
            local row = cache[i]
            if not row then
                -- Button (not Frame): RegisterForClicks is a Button-only API.
                -- Plain Frames raise 'attempt to call a nil value' on it.
                row = CreateFrame("Button", nil, parent)
                row:SetSize(320, 18)
                -- Bump framelevel above whatever section.container layers
                -- (header line / chevron / backdrop) might sit on so the
                -- per-row text and mouse hits aren't shadowed.
                row:SetFrameLevel((parent:GetFrameLevel() or 0) + 10)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
                row.text:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                row.text:SetJustifyH("LEFT")
                row:EnableMouse(true)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetScript("OnEnter", showRowTooltip)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
                -- Two-step swap via OnClick: first left-click selects (sets
                -- dragSource + dims). Second left-click on a different-team
                -- row swaps the pair via auto-locks. Right-click opens the
                -- lock context menu (handled by OnMouseUp below).
                row:SetScript("OnClick", function(self, button)
                    if button ~= "LeftButton" then return end
                    if not self._entry then return end
                    local source = dragSource
                    if not source then
                        -- First click: arm the swap.
                        dragSource = self._entry
                        clearDragVisuals()
                        self.text:SetAlpha(0.5)
                        return
                    end
                    if source.name == self._entry.name then
                        -- Click same row again → cancel.
                        dragSource = nil
                        clearDragVisuals()
                        return
                    end
                    if source.team == self._entry.team then
                        -- Same team — re-arm onto the new selection.
                        dragSource = self._entry
                        clearDragVisuals()
                        self.text:SetAlpha(0.5)
                        return
                    end
                    -- Different team → swap. Default behaviour is a DIRECT
                    -- in-place swap of just these two players: no recompute,
                    -- so the rest of the raid stays put. RL can opt into the
                    -- old "auto-rebalance after swap" behaviour via the
                    -- Réglages toggle, which runs a full Splitter:Compute
                    -- with both players locked so the snake redistributes
                    -- everyone else.
                    dragSource = nil
                    clearDragVisuals()
                    SplitW:SetLock(source.name,     self._entry.team)
                    SplitW:SetLock(self._entry.name, source.team)
                    if SplitW:GetDB().autoRebalanceAfterSwap then
                        recomputeAndRefresh()
                        return
                    end
                    local split = SplitW:GetDB().lastSplit
                    if split then
                        local srcKey = (source.team == "A") and "teamA" or "teamB"
                        local tgtKey = (self._entry.team == "A") and "teamA" or "teamB"
                        local function pull(teamArr, name)
                            for i, x in ipairs(teamArr) do
                                if x.name == name then return table.remove(teamArr, i) end
                            end
                        end
                        local s = pull(split[srcKey], source.name)
                        local t = pull(split[tgtKey], self._entry.name)
                        if s and t then
                            s.team = (tgtKey == "teamA") and "A" or "B"
                            t.team = (srcKey == "teamA") and "A" or "B"
                            table.insert(split[tgtKey], s)
                            table.insert(split[srcKey], t)
                            -- Recount role/score totals so the After block,
                            -- per-team counts in the title, and the warnings
                            -- panel match the swapped composition.
                            local function recount(team)
                                local tk, hl, dp, sc, hs = 0, 0, 0, 0, 0
                                for _, e in ipairs(team) do
                                    if e.role == "TANK" then tk = tk + 1
                                    elseif e.role == "HEALER" then
                                        hl = hl + 1
                                        hs = hs + (SplitW:GetEffectiveHPS(e) or 50)
                                    else
                                        dp = dp + 1
                                        sc = sc + (SplitW:GetEffectiveWeight(e) or 50)
                                    end
                                end
                                return tk, hl, dp, sc, hs
                            end
                            split.tanksA, split.healsA, split.dpsA, split.scoreA, split.healScoreA = recount(split.teamA)
                            split.tanksB, split.healsB, split.dpsB, split.scoreB, split.healScoreB = recount(split.teamB)
                        end
                    end
                    if parent.refresh then parent.refresh() end
                end)
                row:SetScript("OnMouseUp", function(self, button)
                    if button == "RightButton" then
                        if self._entry then showLockMenu(self._entry, self) end
                        return
                    end
                end)
                -- NOTE: deliberately NOT _registerInSection(row). These rows
                -- are created lazily when the user clicks Compute, by which
                -- time module-level _currentSection points at the last
                -- section built across ALL pages (typically an About
                -- section). Registering would reparent the row into that
                -- foreign section's container — which is hidden on Aperçu
                -- → rows disappear. Rows stay parented to the page content
                -- frame directly, which Show/Hide cascades correctly with
                -- the active tab.
                cache[i] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", anchorTitle, "BOTTOMLEFT", 0, -10 - (i - 1) * 20)
            row._entry = e
            row.text:SetText(buildRowText(e, src))
            row.text:SetAlpha(1)
            row:Show()
        end
        for i = #team + 1, #cache do cache[i]:Hide() end
    end

    -- Vertical separator between the two team columns (gold gradient).
    -- Top fixed at the team-titles line; bottom is repositioned dynamically
    -- in refresh to match the longest team's last row.
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT",    parent, "TOPLEFT", 340, -270)
    sep:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 340, -530)
    sep:SetWidth(1)
    sep:SetColorTexture(1, 0.82, 0, 0.5)
    _registerInSection(sep)
    local function resizeSeparator(rowCount)
        local bottomY = -(298 + rowCount * 20 + 10)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT",    parent, "TOPLEFT", 340, -270)
        sep:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 340, bottomY)
    end

    -- Warnings — placed below the team columns at a fixed Y. With the outer
    -- page ScrollFrame, this is fine even if team lists for a 30-man push it
    -- below the viewport (user scrolls). A BOTTOMLEFT anchor would track
    -- container.bottom, which moves as the team lists grow, so we avoid it.
    local warnFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    warnFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -540)
    warnFS:SetWidth(600); warnFS:SetJustifyH("LEFT")
    _registerInSection(warnFS)

    local ICON = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|t"
    local WARN_TEXT = {
        ONE_TANK     = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tOnly one tank — both teams share the same tank? Check your roster."],
        NO_TANK      = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo tank detected in the raid."],
        TEAM_A_OVER  = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam A is too large for any reasonable raid size."],
        TEAM_B_OVER  = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam B is too large for any reasonable raid size."],
        UNEVEN_TEAMS = L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeams differ by more than 1 player — score is balanced by giving the weakest DPS to the larger team."],
        -- Constraint resolver warnings.
        CONSTRAINT_MISSING_BR            = ICON .. L["No Battle Rez class in the raid — constraint cannot be satisfied."],
        CONSTRAINT_MISSING_LUST          = ICON .. L["No Bloodlust giver in the raid — constraint cannot be satisfied."],
        CONSTRAINT_MISSING_MASS_DISPEL   = ICON .. L["No Priest in the raid — Mass Dispel constraint cannot be satisfied."],
        CONSTRAINT_MISSING_DECURSE       = ICON .. L["No decurse class in the raid — constraint cannot be satisfied."],
        CONSTRAINT_UNSWAPPABLE_BR        = ICON .. L["Couldn't swap to satisfy Battle Rez (no compatible role pair)."],
        CONSTRAINT_UNSWAPPABLE_LUST      = ICON .. L["Couldn't swap to satisfy Bloodlust (no compatible role pair)."],
        CONSTRAINT_UNSWAPPABLE_MASS_DISPEL = ICON .. L["Couldn't swap to satisfy Mass Dispel."],
        CONSTRAINT_UNSWAPPABLE_DECURSE   = ICON .. L["Couldn't swap to satisfy Decurse."],
        CONSTRAINT_UNSWAPPABLE_MR        = ICON .. L["Couldn't fully balance melee/ranged ratio."],
        CONSTRAINT_MISSING_EXTERNAL          = ICON .. L["No healer with an external defensive in the raid — constraint cannot be satisfied."],
        CONSTRAINT_UNSWAPPABLE_EXTERNAL      = ICON .. L["Couldn't swap to satisfy external CDs (no compatible healer pair)."],
        CONSTRAINT_MISSING_SOAK              = ICON .. L["No immunity class (Paladin / Mage / Hunter) in the raid — constraint cannot be satisfied."],
        CONSTRAINT_UNSWAPPABLE_SOAK          = ICON .. L["Couldn't swap to satisfy soak immunity."],
    }

    -- Empty-state placeholder FontStrings under each title.
    local emptyA = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyA:SetPoint("TOPLEFT", titleA, "BOTTOMLEFT", 0, -10)
    emptyA:SetText("|cff888888" .. L["(empty)"] .. "|r")
    emptyA:Hide()
    _registerInSection(emptyA)
    local emptyB = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyB:SetPoint("TOPLEFT", titleB, "BOTTOMLEFT", 0, -10)
    emptyB:SetText("|cff888888" .. L["(empty)"] .. "|r")
    emptyB:Hide()
    _registerInSection(emptyB)

    -- Recompute the split (re-runs Splitter with current locks / constraints)
    -- and refresh the page. Used by the right-click lock menu + the
    -- drag-and-drop swap path.
    recomputeAndRefresh = function()
        local r = SplitW.Roster:Scan()
        SplitW:GetDB().lastSplit = SplitW.Splitter:Compute(r)
        SplitW._rosterDirty = false
        if parent.refresh then parent.refresh() end
    end

    parent.refresh = function()
        if parent._testBtnRefresh then parent._testBtnRefresh() end
        if SplitW._rosterDirty and SplitW:GetDB().lastSplit then
            dirtyBanner:Show()
        else
            dirtyBanner:Hide()
        end
        local roster = SplitW.Roster:Scan()
        if SplitW.Roster:IsTestMode() then
            modeFS:SetText("|cffffd100" .. format(L["Test mode ON (%d simulated)"], SplitW.Roster:GetTestSize()) .. "|r")
        elseif roster.raid == 0 then
            modeFS:SetText("|cffff8855" .. L["No raid detected — enable test mode to preview"] .. "|r")
        else
            modeFS:SetText("|cff66ff66" .. format(L["Live roster (%d members)"], roster.raid) .. "|r")
        end
        local srcLabel = SplitW.DPSSource and SplitW.DPSSource:ActiveSourceLabel() or "?"
        srcFS:SetText("|cffaaaaaa" .. L["Source used for the split:"] .. "|r |cffffffff" .. srcLabel .. "|r")
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
            titleA:SetText(baseA); titleB:SetText(baseB)
            for _, row in ipairs(rowsA) do row:Hide() end
            for _, row in ipairs(rowsB) do row:Hide() end
            emptyA:Hide(); emptyB:Hide()
            warnFS:SetText("")
            return
        end

        -- Two-line format symmetric with the "Before" block. HPS suffix only
        -- appears when at least one team has heal data (otherwise it's noise).
        local hsA = math.floor((split.healScoreA or 0) + 0.5)
        local hsB = math.floor((split.healScoreB or 0) + 0.5)
        local hpsPart = (hsA > 0 or hsB > 0)
            and function(v) return string.format(" — HPS %d", v) end
            or function() return "" end
        afterStatsFS:SetText(string.format(
            "|cffffd100%s|r\n  A: %d (%dT %dH %dDPS — DPS %d%s)\n  B: %d (%dT %dH %dDPS — DPS %d%s)",
            L["Proposed split"],
            #split.teamA, split.tanksA, split.healsA, split.dpsA,
            math.floor(split.scoreA + 0.5), hpsPart(hsA),
            #split.teamB, split.tanksB, split.healsB, split.dpsB,
            math.floor(split.scoreB + 0.5), hpsPart(hsB)))

        titleA:SetText(string.format("%s  |cffaaaaaa(%d)|r", baseA, #split.teamA))
        titleB:SetText(string.format("%s  |cffaaaaaa(%d)|r", baseB, #split.teamB))
        -- Clamp empty placeholders FIRST so they don't visually shadow team
        -- rows in case the section's SetCollapsed Show'd them at some point.
        if #split.teamA == 0 then emptyA:Show() else emptyA:Hide() end
        if #split.teamB == 0 then emptyB:Show() else emptyB:Hide() end
        renderTeamRows(split.teamA, rowsA, titleA, 14)
        renderTeamRows(split.teamB, rowsB, titleB, 360)

        -- Expand the page content frame so all team rows and the warnings line
        -- fit within the scroll viewport. The makePage deferred sizing only
        -- counts registered sections; team rows live outside that registry.
        local rowCount = math.max(#split.teamA, #split.teamB, 5)
        local needed = 300 + rowCount * 20 + 80  -- titles at -270 + N rows + warnings + margin
        if parent.GetHeight and parent:GetHeight() < needed then
            parent:SetHeight(needed)
        end

        -- Anchor the warnings line BELOW the longest team column instead of a
        -- fixed Y. Otherwise a 40-man split with 20 rows per team pushes the
        -- last rows down to ~-680, far past the static y=-540 warnings line,
        -- and the row text overlaps the warnings.
        --   title top    : -270
        --   first row    : -270 - 18 (title height) - 10 = -298
        --   last row     : -298 - (rowCount - 1) * 20 - 20 (row height)
        --              = -278 - rowCount * 20
        --   warning at   : -298 - rowCount * 20 - 24 (margin)
        local warnY = -(298 + rowCount * 20 + 24)
        warnFS:ClearAllPoints()
        warnFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, warnY)
        resizeSeparator(rowCount)

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
StaticPopupDialogs["SPLITWATCH_RESTORE_PRESETS"] = {
    text = L["Load the built-in split-fight presets? Existing presets with the same name will be overwritten."],
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    OnAccept = function()
        local n = SplitW:RestoreBuiltinPresets()
        print(format("|cffffd100SplitWatch:|r " .. L["restored %d built-in presets"], n))
        if SplitW.RefreshAll then SplitW:RefreshAll() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["SPLITWATCH_CONFIRM_CLEAR_LOCKS"] = {
    text = L["Remove every player lock?"],
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    OnAccept = function()
        SplitW:ClearLocks()
        if SplitW.RefreshAll then SplitW:RefreshAll() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["SPLITWATCH_CONFIRM_RESET_WEIGHTS"] = {
    text = L["Reset every stored weight back to the default? This can't be undone."],
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    OnAccept = function()
        local db = SplitW:GetDB()
        local default = db.weightDefault or 50
        for k in pairs(db.weights) do db.weights[k] = default end
        if SplitW.RefreshAll then SplitW:RefreshAll() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["SPLITWATCH_CONFIRM_DELETE_PRESET"] = {
    text = L["Delete the preset '%s'?"],
    button1 = ACCEPT or "Accept",
    button2 = CANCEL or "Cancel",
    OnAccept = function(self)
        if self.data then
            SplitW:DeletePreset(self.data)
            if SplitW.RefreshAll then SplitW:RefreshAll() end
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- ----------------------------------------------------------------
-- ABOUT + CHANGELOG PAGE
-- ----------------------------------------------------------------
local function buildAboutPage(parent)
    local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local author  = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Author")  or "Timikana"

    -- ---- HEADER ROW: logo (left) + title/version/author/sisters (right) ----
    -- Drop the section header for this top block — the logo IS the visual anchor.
    _currentSection = nil

    local logo = parent:CreateTexture(nil, "ARTWORK")
    logo:SetSize(120, 120)
    logo:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -14)
    logo:SetTexture("Interface\\AddOns\\SplitWatch\\Media\\logo.tga")

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 16, -4)
    title:SetText("|cffffd100SplitWatch|r  |cffaaaaaav" .. version .. "|r")

    local sub = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    sub:SetWidth(480); sub:SetJustifyH("LEFT")
    sub:SetText(L["Auto-split a 10-40 man raid into 2 balanced teams (tanks, healers by HPS, DPS by damage) for split-mechanic encounters."])

    local meta = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    meta:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -10)
    meta:SetWidth(480); meta:SetJustifyH("LEFT"); meta:SetSpacing(3)
    meta:SetText(
        "|cffaaaaaa" .. L["Author"]        .. ":|r |cffffffff" .. author .. "|r\n" ..
        "|cffaaaaaa" .. L["Slash command"] .. ":|r |cffffff00/splitw|r" ..
        " |cff888888(" .. L["alias"] .. ": /splitwatch)|r\n" ..
        "|cffaaaaaa" .. L["Sister addons"] .. ":|r BossWatch, TankWatch")

    -- ---- Slash commands (chained, full width) ----
    makeSection(parent, L["Slash commands"], 14, -160, "about.slash")
    local cmds = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmds:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -190)
    cmds:SetWidth(600); cmds:SetJustifyH("LEFT"); cmds:SetSpacing(4)
    cmds:SetText(
        "|cffffff00/splitw|r — "         .. L["open options"] .. "\n" ..
        "|cffffff00/splitw preview|r — " .. L["compute and show split preview"] .. "\n" ..
        "|cffffff00/splitw apply|r — "   .. L["apply the current split via SetRaidSubgroup"] .. "\n" ..
        "|cffffff00/splitw test|r — "    .. L["toggle simulated 20-man roster"] .. "\n" ..
        "|cffffff00/splitw reset|r — "   .. L["reset all settings + reload"])
    _registerInSection(cmds)

    -- ---- Panel preferences (opacity + reset window) ----
    makeSection(parent, L["Panel"], 14, -300, "about.panel")
    local alphaSlider = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    alphaSlider:SetWidth(220)
    alphaSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -334)
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

    local btnResetWin = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnResetWin:SetSize(220, 22)
    btnResetWin:SetPoint("TOPLEFT", parent, "TOPLEFT", 260, -334)
    btnResetWin:SetText(L["Reset window position"])
    btnResetWin:SetScript("OnClick", function()
        SplitW:GetDB().panelPoint = nil
        if panel then
            panel:ClearAllPoints()
            panel:SetPoint("CENTER")
        end
    end)
    addTooltip(btnResetWin, L["Reset the options window to its default center position."])
    _registerInSection(btnResetWin)

    -- ---- Changelog (chained at the bottom) ----
    makeSection(parent, L["Changelog"], 14, -400, "about.changelog")
    local entries = {
        { ver = "0.3.0", date = "2026-05-12", lines = {
            L["• 0 required addons — Details!/Recount/Skada/Item Level/Manual all still optional / built-in."],
            L["• Sister addon to BossWatch + TankWatch."],
            L["• Manual locks: right-click a player in the Preview team columns to pin them on Team A / Team B / free. Lock icon shows next to pinned names. Active locks listed on the Composition tab with one-click Free buttons + Clear all."],
            L["• Broadcast on Apply: opt-in to auto-post the team rosters to chat (RAID / RAID_WARNING / PARTY / SAY) after a successful Apply."],
            L["• Named presets: save the current constraints + locks + DPS source under a name; reload before a specific fight. UI section with editbox / Save / Load / Delete + scrollable list."],
            L["• Spec detection via inspect — captured alongside ilvl, refines melee/ranged classification for Druid / Shaman / Hunter / Monk / Paladin hybrid specs (accurate range instead of class-default)."],
            L["• Fixed Battle Rez class list: only Druid / DK / Warlock actually have an in-combat resurrection. Hunter / Paladin / DH removed (false positive)."],
            L["• Fixed Decurse class list: Monk Detox doesn't remove curses; only Mage / Druid / Shaman do."],
            L["• Per-player tooltip on team-column rows showing class, role, DPS, HPS, manual weight, lock status."],
            L["• Composition tab rename (was 'Joueurs') — covers both Constraints and Manual weights more accurately."],
            L["• Two new constraints: External CD healer per team (Pala/Priest/Druid/Monk filtered to HEALER role), Soak immunity per team (Pala/Mage/Hunter)."],
            L["• Drag-and-drop swap on Preview team rows: left-click a name, then left-click any player on the OTHER team to swap them. Both auto-locked so the swap persists."],
            L["• Movement indicator on Preview rows: orange arrow next to players whose team changed since the last Apply — spot recompute churn at a glance."],
            L["• Built-in preset library: 'Restore built-ins' button on Réglages → Presets loads ready-to-use configs for Spirit Kings, Lei Shen, Council of Elders, Conclave of Wind."],
            L["• Roster-change banner: GROUP_ROSTER_UPDATE fired → yellow banner on Aperçu with inline Recompute button. RL decides when to commit a new split — no auto-recompute."],
            L["• Confirmation popups on destructive actions: Clear all locks, Reset all weights, Delete preset. Avoids accidental data loss."],
        }},
        { ver = "0.2.0", date = "2026-05-12", lines = {
            L["• 0 required addons — Details!/Recount/Skada remain optional integrations alongside the new Item Level (inspect) source and the per-player Manual sliders."],
            L["• Sister addon to BossWatch + TankWatch — shares the side-tab navigation and the family UI."],
            L["• New section 'Constraints' on Setup — Raid Leader can toggle Battle Rez per team (ON by default), Bloodlust per team (ON by default), Balance melee vs ranged, Mass Dispel per team, Decurse per team."],
            L["• Constraint resolver runs AFTER the score-based snake so swaps stay minimal — picks the DPS pair closest in score, preserves role boundaries."],
            L["• Team size rebalance: 2T / 1H / 17DPS no longer ends 11/9 — the weakest DPS migrates until |#A - #B| ≤ 1."],
            L["• Source used for the split is now displayed on the Preview tab, no round-trip to Setup needed."],
            L["• Each team-list line shows ilvl or DPS as a grey suffix next to the name."],
            L["• Team titles include the player count: 'Équipe A (5)'."],
            L["• Escape closes the panel (UISpecialFrames registration)."],
        }},
        { ver = "0.1.0", date = "2026-05-11", lines = {
            L["• 0 required addons — SplitWatch works standalone. Details!/Recount/Skada are optional for live DPS/HPS readings, otherwise Manual sliders are used."],
            L["• Sister addon to BossWatch + TankWatch — shares the side-tab navigation, gold accent UI, and family colour palette."],
            L["• Initial release: snake-distribution algorithm, preview pane with before/after stats, permission-gated Apply via SetRaidSubgroup."],
            L["• Supports retail 12.x and MoP Classic 5.5."],
            L["• Test mode (/splitw test) for UI preview without a raid."],
            L["• Damage meter sources: Details!, Recount, Skada, Manual — unavailable ones grey out in the dropdown."],
            L["• Healers balanced by HPS (live read from the active source), DPS by damage."],
            L["• Supports raids from 10 to 40 members — subgroups assigned dynamically."],
            L["• Collapsible sections with per-section reset, persisted across reloads."],
        }},
    }
    local y = -430
    for _, e in ipairs(entries) do
        local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
        h:SetText(string.format("|cffffd100v%s|r |cffaaaaaa(%s)|r", e.ver, e.date))
        _registerInSection(h)
        y = y - 20
        for _, line in ipairs(e.lines) do
            local l = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            l:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
            l:SetWidth(580); l:SetJustifyH("LEFT")
            l:SetText(line)
            _registerInSection(l)
            y = y - (math.ceil(l:GetStringHeight()) + 4)
        end
        y = y - 6
    end

    parent.refresh = function() end
end

-- ============================================================
-- BUILD MAIN PANEL
-- ============================================================
local PANEL_MIN_W, PANEL_MIN_H = 720, 500
local PANEL_DEF_W, PANEL_DEF_H = 720, 540

local function build()
    panel = CreateFrame("Frame", "SplitWatchOptionsPanel", UIParent, "PortraitFrameTemplate")
    -- Restore persisted size, clamped to current UIParent so a value saved on
    -- a bigger monitor doesn't make the panel overflow the screen on a smaller one.
    SplitWatchDB = SplitWatchDB or {}
    local sw = (UIParent and UIParent.GetWidth  and UIParent:GetWidth())  or 1920
    local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 1080
    local startW = math.max(PANEL_MIN_W, math.min(sw - 40, SplitWatchDB.panelW or PANEL_DEF_W))
    local startH = math.max(PANEL_MIN_H, math.min(sh - 40, SplitWatchDB.panelH or PANEL_DEF_H))
    panel:SetSize(startW, startH)
    local db = SplitW:GetDB()
    -- Restore saved panel position, but validate it's still on-screen — moving
    -- between monitors of different resolutions can leave saved offsets that
    -- put the frame entirely off the viewport. If abs(x) or abs(y) exceeds
    -- the current UIParent half-dimension, fall back to CENTER.
    local function restorePosition()
        if not db.panelPoint then
            panel:SetPoint("CENTER"); return
        end
        local p = db.panelPoint
        local sw = (UIParent and UIParent.GetWidth  and UIParent:GetWidth())  or 1920
        local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 1080
        -- Generous bounds: tolerate offsets up to a full screen away (the user
        -- might have a wider workspace than current). Beyond that, the panel
        -- is almost certainly invisible — reset to CENTER.
        if math.abs(p.x or 0) > sw or math.abs(p.y or 0) > sh then
            db.panelPoint = nil
            panel:SetPoint("CENTER")
            return
        end
        panel:SetPoint(p.point or "CENTER", UIParent, p.relPoint or p.point or "CENTER",
                       p.x or 0, p.y or 0)
    end
    restorePosition()
    -- Close on Escape via Blizzard's special-frames list.
    tinsert(UISpecialFrames, "SplitWatchOptionsPanel")
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
    panel:SetResizable(true)
    if panel.SetResizeBounds then
        panel:SetResizeBounds(PANEL_MIN_W, PANEL_MIN_H, 1400, 1100)
    end
    panel:Hide()

    -- Resize grip (bottom-right corner). Updates panelW/panelH on release.
    local grip = CreateFrame("Button", nil, panel)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetFrameLevel(panel:GetFrameLevel() + 10)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then panel:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        SplitWatchDB.panelW = math.floor(panel:GetWidth() + 0.5)
        SplitWatchDB.panelH = math.floor(panel:GetHeight() + 0.5)
    end)
    addTooltip(grip, L["Drag to resize the options window. Saved account-wide."])

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

    -- Each page is a ScrollFrame so tall content gets a Blizzard scrollbar
    -- (UIPanelScrollFrameTemplate). The builder receives the inner content
    -- frame as its `parent` so widgets created inside it sit on the scrollable
    -- canvas. Mirror of BossWatch's newPage() pattern.
    local function makePage(name, builder)
        local sf = CreateFrame("ScrollFrame", "SWScroll_"..name, pageHolder, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     pageHolder, "TOPLEFT",      0, 0)
        sf:SetPoint("BOTTOMRIGHT", pageHolder, "BOTTOMRIGHT", -24, 0)
        sf:Hide()

        local content = CreateFrame("Frame", nil, sf)
        content:SetSize(680, 800)
        sf:SetScrollChild(content)
        sf.content = content
        -- Keep the canvas width in sync with the scroll viewport so widgets
        -- anchored to TOPRIGHT stick to the visible edge as the panel resizes.
        -- Also grow content height to fill the viewport when the panel gets
        -- taller (otherwise empty space appears below the last section).
        sf:SetScript("OnSizeChanged", function(self, w, h)
            if w and w > 0 and self.content then self.content:SetWidth(w) end
            if h and h > 0 and self.content then
                local cur = self.content:GetHeight() or 0
                if cur < h then self.content:SetHeight(h) end
            end
        end)

        builder(content)

        -- After widgets are built, size the content frame: at least as tall
        -- as the viewport (so the page fills the available area cleanly), and
        -- taller only when the lowest section actually extends past it.
        -- Without this, content height stays at the initial 800 → the outer
        -- scrollbar shows even when nothing overflows.
        C_Timer.After(0.05, function()
            local secs = _allSectionsOnPage[content]
            local top = content:GetTop() or 0
            local lowest = top
            if secs then
                for _, s in ipairs(secs) do
                    if s.container and s.container.GetBottom then
                        local b = s.container:GetBottom()
                        if b and b < lowest then lowest = b end
                    end
                end
            end
            local viewport = sf:GetHeight() or 400
            local natural  = top - lowest + 24
            content:SetHeight(math.max(viewport, natural))
        end)

        pages[name] = sf
        return sf
    end

    makePage("setup",   buildSetupPage)
    makePage("weights", buildWeightsPage)
    makePage("preview", buildPreviewPage)
    makePage("about",   buildAboutPage)

    -- Bottom tabs
    local tabDefs = {
        { id = "setup",   label = L["Setup"]   },
        { id = "weights", label = L["Composition"] },
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
            if k == id then
                p:Show()
                local target = p.content or p
                if target.refresh then target:refresh() end
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

    -- Refresh all pages — pages[id] is the outer ScrollFrame, but each page
    -- builder stores its .refresh handler on the content child (sf.content),
    -- so unwrap before calling.
    refresh = function()
        local cur = pages[panel._currentTab or "setup"]
        local target = cur and cur.content or cur
        if target and target.refresh then target:refresh() end
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
        local sw = (UIParent and UIParent.GetWidth  and UIParent:GetWidth())  or 1920
        local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 1080
        if math.abs(x or 0) > sw or math.abs(y or 0) > sh then
            -- Sister addon handed us an off-screen position — clamp to CENTER.
            panel:ClearAllPoints()
            panel:SetPoint("CENTER")
            SplitW:GetDB().panelPoint = nil
        else
            panel:ClearAllPoints()
            panel:SetPoint(point, UIParent, relPoint or point, x or 0, y or 0)
            SplitW:GetDB().panelPoint = {
                point = point, relPoint = relPoint or point,
                x = math.floor((x or 0) + 0.5),
                y = math.floor((y or 0) + 0.5),
            }
        end
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
