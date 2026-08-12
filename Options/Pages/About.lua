local addonName, SplitW = ...
local L = SplitW.L
local O = SplitW.Options

local addTooltip = O.addTooltip

local CreateFrame = CreateFrame
local C_AddOns = C_AddOns
local ipairs = ipairs

function O.Pages.about(parent)
    local makeSection         = O.makeSection
    local _registerInSection  = O._registerInSection

    local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local author  = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Author")  or "Timikana"

    -- ---- HEADER ROW: logo (left) + title/version/author/sisters (right) ----
    O.setCurrentSection(nil)

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

    -- ---- Links (GitHub / CurseForge / Wago / Discord) ----
    makeSection(parent, L["Links"], 14, -160, "about.links")

    local function urlField(yOff, label, url)
        local lab = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, yOff)
        lab:SetText(label)
        _registerInSection(lab)

        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        eb:SetSize(440, 22)
        eb:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOff - 16)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetText(url)
        eb:SetCursorPosition(0)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
        eb:SetScript("OnMouseDown", function(self) self:HighlightText(); self:SetFocus() end)
        addTooltip(eb, L["Click to select, then Ctrl+C to copy."])
        _registerInSection(eb)
        return eb
    end

    urlField(-190, "|cffffffff" .. L["GitHub repository:"] .. "|r",
        "https://github.com/Timikana/SplitWatch")
    urlField(-240, "|cffffffff" .. L["Report an issue:"] .. "|r",
        "https://github.com/Timikana/SplitWatch/issues")
    urlField(-290, "|cffeda14a" .. L["CurseForge:"] .. "|r",
        "https://www.curseforge.com/wow/addons/splitwatch")
    urlField(-340, "|cffb371ff" .. L["Wago:"] .. "|r",
        "https://addons.wago.io/addons/splitwatch")
    urlField(-390, "|cff5865f2" .. L["Discord (support / bugs / suggestions):"] .. "|r",
        "https://discord.gg/uFmxwexQ4P")

    -- ---- Slash commands ----
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
        local panel = O.GetPanel()
        if panel then panel:SetAlpha(v2) end
    end, alphaSlider)
    addTooltip(alphaSlider, L["Opacity of this options window. Saved account-wide."])

    local btnResetWin = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnResetWin:SetSize(220, 22)
    btnResetWin:SetPoint("TOPLEFT", parent, "TOPLEFT", 260, -334)
    btnResetWin:SetText(L["Reset window position"])
    btnResetWin:SetScript("OnClick", function()
        SplitW:GetDB().panelPoint = nil
        local panel = O.GetPanel()
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
        { ver = "0.3.5", date = "2026-08-12", lines = {
            L["• Patch 12.1 compatibility — TOC bumped (120100 retail, 50504 MoP Classic). Full 12.1 API audit: nothing SplitWatch uses is broken; the new secret-value returns on group APIs never apply to your own raid members."],
            L["• Fix: Details! reader falls back to the raw actor container when GetActorList returns empty (post-/reload states), and probes internal combat fields as a last resort."],
            L["• Fix: tank balancing with locks — an unlocked tank now goes to the team with FEWER tanks instead of strict A/B alternation, so one tank locked to A no longer risks putting both tanks on A."],
            L["• 0 required addons. Sister addons: BossWatch, TankWatch."],
        }},
        { ver = "0.3.4", date = "2026-05-14", lines = {
            L["• Fix: Details! source preview was empty when the current combat had no actors yet. The reader now probes multiple combat segments and uses the first one with data."],
            L["• Fix: cross-realm player names (Name-Realm) now match correctly against meters that store them as short names — both forms are tried."],
            L["• New /splitw dps debug command — dumps which actors the active source returns and matches them against the roster."],
            L["• 0 required addons. Sister addons: BossWatch, TankWatch."],
        }},
        { ver = "0.3.3", date = "2026-05-14", lines = {
            L["• Fix: Apply was failing with \"group is full\" when a target subgroup already contained an off-split player. BuildPlan now pre-fills each subgroup's counter with current occupancy (non-team members keep their slot)."],
            L["• Apply minimises moves: players whose current subgroup is already in their team's target groups stay put rather than being shuffled around."],
            L["• 0 required addons. Sister addons: BossWatch, TankWatch."],
        }},
        { ver = "0.3.2", date = "2026-05-14", lines = {
            L["• New \"Links\" section on the About tab — clickable GitHub / Issues / CurseForge / Wago / Discord URL fields. Same convention as BossWatch / TankWatch."],
            L["• Discord support server now has a dedicated SplitWatch category (#sw-changelog, #sw-bugs, #sw-support, #sw-suggestions). Same BWTW guild as BossWatch / TankWatch."],
            L["• 0 required addons. Sister addons: BossWatch, TankWatch."],
        }},
        { ver = "0.3.1", date = "2026-05-14", lines = {
            L["• Internal refactor of the options panel: the ~2070-line Panel.lua is split into 6 files (Widgets.lua + a slimmer Panel.lua + 4 tab files under Options/Pages/). Mirrors the BossWatch / TankWatch convention. Zero user-visible change."],
            L["• 0 required addons — Details!/Recount/Skada/Item Level/Manual all still optional. Sister addons to BossWatch + TankWatch."],
        }},
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
