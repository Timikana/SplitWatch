-- Options/Panel.lua — section system + build harness + public API.
-- Widget factories live in Options/Widgets.lua. Page builders live in
-- Options/Pages/*.lua and register themselves into SplitW.Options.Pages.<id>.
local addonName, SplitW = ...
local L = SplitW.L

SplitW.Options = SplitW.Options or {}
SplitW.Options.Pages = SplitW.Options.Pages or {}
local O = SplitW.Options

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
-- re-anchor it relative to the container.
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

-- Resolved at panel-build time so widget factories created during the build
-- can refer to it consistently. Widgets.lua looks up addTooltip from O.
local addTooltip = O.addTooltip

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

    local btnReset = CreateFrame("Button", nil, container)
    btnReset:SetSize(14, 14)
    btnReset:SetPoint("TOPRIGHT", container, "TOPRIGHT", -8, -2)
    btnReset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    btnReset:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    btnReset:SetFrameLevel(container:GetFrameLevel() + 6)
    section.resetBtn = btnReset

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

    if addTooltip then
        addTooltip(clickArea, L["Click to collapse/expand this section."])
        addTooltip(btnReset,  L["Reset this section to default values."])
    end

    local restored = key and SplitWatchDB.collapsedSections[key]
    section:SetCollapsed(restored or false, false)

    _currentSection = section
    C_Timer.After(0, function() section:UpdateNaturalHeight() end)
    return section
end

-- ============================================================
-- EXPOSE TO OPTIONS PAGE FILES
-- Page files do `local O = SplitW.Options` then pull what they need.
-- ============================================================
O._registerInSection  = _registerInSection
O._captureAndReparent = _captureAndReparent
O.makeSection         = makeSection
O.setCurrentSection   = function(v) _currentSection = v end
O.GetPanel            = function() return panel end
O.refreshPanel        = function() if panel and panel.refreshAll then panel.refreshAll() end end

-- ============================================================
-- BUILD MAIN PANEL
-- ============================================================
local PANEL_MIN_W, PANEL_MIN_H = 720, 500
local PANEL_DEF_W, PANEL_DEF_H = 720, 540

local function build()
    panel = CreateFrame("Frame", "SplitWatchOptionsPanel", UIParent, "PortraitFrameTemplate")
    SplitWatchDB = SplitWatchDB or {}
    local sw = (UIParent and UIParent.GetWidth  and UIParent:GetWidth())  or 1920
    local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 1080
    local startW = math.max(PANEL_MIN_W, math.min(sw - 40, SplitWatchDB.panelW or PANEL_DEF_W))
    local startH = math.max(PANEL_MIN_H, math.min(sh - 40, SplitWatchDB.panelH or PANEL_DEF_H))
    panel:SetSize(startW, startH)
    local db = SplitW:GetDB()
    local function restorePosition()
        if not db.panelPoint then
            panel:SetPoint("CENTER"); return
        end
        local p = db.panelPoint
        local sw = (UIParent and UIParent.GetWidth  and UIParent:GetWidth())  or 1920
        local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 1080
        if math.abs(p.x or 0) > sw or math.abs(p.y or 0) > sh then
            db.panelPoint = nil
            panel:SetPoint("CENTER")
            return
        end
        panel:SetPoint(p.point or "CENTER", UIParent, p.relPoint or p.point or "CENTER",
                       p.x or 0, p.y or 0)
    end
    restorePosition()
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
    if addTooltip then addTooltip(grip, L["Drag to resize the options window. Saved account-wide."]) end

    SplitWatchDB = SplitWatchDB or {}
    if SplitWatchDB.panelAlpha == nil then SplitWatchDB.panelAlpha = 0.85 end
    panel:SetAlpha(SplitWatchDB.panelAlpha)

    if panel.TitleContainer and panel.TitleContainer.TitleText then
        panel.TitleContainer.TitleText:SetText("SplitWatch")
    elseif panel.TitleText then
        panel.TitleText:SetText("SplitWatch")
    end

    local PORTRAIT_TEX = "Interface\\AddOns\\SplitWatch\\Media\\logo.tga"
    if panel.portrait then panel.portrait:SetTexture(PORTRAIT_TEX) end
    if panel.PortraitContainer and panel.PortraitContainer.portrait then
        panel.PortraitContainer.portrait:SetTexture(PORTRAIT_TEX)
    end
    if panel.SetPortraitToAsset then
        pcall(panel.SetPortraitToAsset, panel, PORTRAIT_TEX)
    end

    pageHolder = CreateFrame("Frame", nil, panel)
    pageHolder:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -60)
    pageHolder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 32)

    local function makePage(name, builder)
        local sf = CreateFrame("ScrollFrame", "SWScroll_"..name, pageHolder, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     pageHolder, "TOPLEFT",      0, 0)
        sf:SetPoint("BOTTOMRIGHT", pageHolder, "BOTTOMRIGHT", -24, 0)
        sf:Hide()

        local content = CreateFrame("Frame", nil, sf)
        content:SetSize(680, 800)
        sf:SetScrollChild(content)
        sf.content = content
        sf:SetScript("OnSizeChanged", function(self, w, h)
            if w and w > 0 and self.content then self.content:SetWidth(w) end
            if h and h > 0 and self.content then
                local cur = self.content:GetHeight() or 0
                if cur < h then self.content:SetHeight(h) end
            end
        end)

        builder(content)

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

    makePage("setup",   O.Pages.setup)
    makePage("weights", O.Pages.weights)
    makePage("preview", O.Pages.preview)
    makePage("about",   O.Pages.about)

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
        if addTooltip then addTooltip(t, t:GetText() or "") end
    end

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
            if addTooltip then addTooltip(tab, def.tooltip) end
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
    if addTooltip then addTooltip(btn, L["Open the floating SplitWatch options panel."]) end

    local hint = host:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["You can also use the slash command: /splitw"])

    local category = Settings.RegisterCanvasLayoutCategory(host, "SplitWatch")
    category.ID = "SplitWatch"
    Settings.RegisterAddOnCategory(category)
    SplitW._settingsCategoryID = category:GetID()
end
