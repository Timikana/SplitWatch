local addonName, SplitW = ...
local L = SplitW.L
local O = SplitW.Options

local addTooltip          = O.addTooltip
local markAsNew           = O.markAsNew
local classColor          = O.classColor
local fmtNum              = O.fmtNum
local roleIcon            = O.roleIcon
local makeCheck           = O.makeCheck
local makeSlider          = O.makeSlider
local makeDropdown        = O.makeDropdown
local makeButton          = O.makeButton
local makeLabel           = O.makeLabel

local CreateFrame = CreateFrame
local ipairs = ipairs
local format = string.format

function O.Pages.setup(parent)
    local makeSection         = O.makeSection
    local _registerInSection  = O._registerInSection

    makeSection(parent, L["General"], 14, -8, "setup.general")
    local mm = makeCheck(parent, L["Show minimap icon"], "minimapHidden",
        14, -40, L["Toggle the minimap launcher button"])
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

    -- ---- Live source preview ----
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

    -- ---- Presets ----
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
