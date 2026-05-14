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
local makeButton          = O.makeButton
local makeLabel           = O.makeLabel

local CreateFrame = CreateFrame
local ipairs, pairs = ipairs, pairs
local format = string.format

function O.Pages.preview(parent)
    local makeSection         = O.makeSection
    local _registerInSection  = O._registerInSection

    makeSection(parent, L["Preview the split"], 14, -8, "preview.main", 640)

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

    local ARROW_TEX = "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:18:18:0:0|t"
    local beforeFS = makeLabel(parent, "|cffaaaaaa" .. L["Before"] .. "|r", 14, -180, "GameFontNormalLarge")
    local arrowFS  = makeLabel(parent, ARROW_TEX, 326, -182, "GameFontNormalLarge")
    local afterFS  = makeLabel(parent, "|cffffd100" .. L["After"] .. "|r", 360, -180, "GameFontNormalLarge")

    local beforeStatsFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    beforeStatsFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -206)
    beforeStatsFS:SetWidth(300); beforeStatsFS:SetJustifyH("LEFT")
    _registerInSection(beforeStatsFS)

    local afterStatsFS = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    afterStatsFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 360, -206)
    afterStatsFS:SetWidth(300); afterStatsFS:SetJustifyH("LEFT")
    _registerInSection(afterStatsFS)

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

    local lockDropdown = _G.SplitWatchLockDropdown
        or CreateFrame("Frame", "SplitWatchLockDropdown", UIParent, "UIDropDownMenuTemplate")
    local rowsA, rowsB = {}, {}

    local recomputeAndRefresh

    local function showLockMenu(entry, ownerFrame)
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
                row = CreateFrame("Button", nil, parent)
                row:SetSize(320, 18)
                row:SetFrameLevel((parent:GetFrameLevel() or 0) + 10)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
                row.text:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                row.text:SetJustifyH("LEFT")
                row:EnableMouse(true)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetScript("OnEnter", showRowTooltip)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
                row:SetScript("OnClick", function(self, button)
                    if button ~= "LeftButton" then return end
                    if not self._entry then return end
                    local source = dragSource
                    if not source then
                        dragSource = self._entry
                        clearDragVisuals()
                        self.text:SetAlpha(0.5)
                        return
                    end
                    if source.name == self._entry.name then
                        dragSource = nil
                        clearDragVisuals()
                        return
                    end
                    if source.team == self._entry.team then
                        dragSource = self._entry
                        clearDragVisuals()
                        self.text:SetAlpha(0.5)
                        return
                    end
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
                -- → rows disappear.
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

    -- Vertical separator between the two team columns.
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
        if #split.teamA == 0 then emptyA:Show() else emptyA:Hide() end
        if #split.teamB == 0 then emptyB:Show() else emptyB:Hide() end
        renderTeamRows(split.teamA, rowsA, titleA, 14)
        renderTeamRows(split.teamB, rowsB, titleB, 360)

        local rowCount = math.max(#split.teamA, #split.teamB, 5)
        local needed = 300 + rowCount * 20 + 80
        if parent.GetHeight and parent:GetHeight() < needed then
            parent:SetHeight(needed)
        end

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

-- ============================================================
-- Static popups owned by the Preview workflow
-- ============================================================
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
