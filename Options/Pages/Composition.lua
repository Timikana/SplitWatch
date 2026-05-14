local addonName, SplitW = ...
local L = SplitW.L
local O = SplitW.Options

local addTooltip          = O.addTooltip
local markAsNew           = O.markAsNew
local classColor          = O.classColor
local roleIcon            = O.roleIcon
local makeCheck           = O.makeCheck
local makeButton          = O.makeButton

local CreateFrame = CreateFrame
local ipairs, pairs = ipairs, pairs

function O.Pages.weights(parent)
    local makeSection         = O.makeSection
    local _registerInSection  = O._registerInSection

    -- ---- Constraints ----
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

    -- ---- Active locks ----
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

    -- ---- Manual weights ----
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
    local row_empty
    local function makeRow(idx)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(580, 24)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(idx-1) * 26)
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
