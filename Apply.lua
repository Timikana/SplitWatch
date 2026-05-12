local addonName, SplitW = ...

SplitW.Apply = SplitW.Apply or {}
local Apply = SplitW.Apply
local L = SplitW.L

-- ============================================================
-- PERMISSION GATE
-- ============================================================
function Apply:CanApply()
    if SplitW.Roster and SplitW.Roster:IsTestMode() then
        return false, L["test mode active — apply is disabled"]
    end
    if not IsInRaid() then
        return false, L["not in a raid"]
    end
    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        return false, L["leader or assistant required"]
    end
    return true
end

-- ============================================================
-- QUEUE
-- SetRaidSubgroup is combat-protected since 4.0.1 — defer until
-- PLAYER_REGEN_ENABLED if we're in combat.
-- ============================================================
Apply._queue = nil
Apply._running = false
Apply._waitingForCombat = false

local function broadcastSplit()
    local db = SplitW:GetDB()
    if not db.broadcastOnApply then return end
    local split = db.lastSplit
    if not split then return end
    local channel = db.broadcastChannel or "RAID"
    if channel == "RAID_WARNING"
       and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        channel = "RAID"  -- raid warning requires lead/assist; fall back
    end
    local function fmt(team) local names = {}; for _, e in ipairs(team) do names[#names + 1] = e.name end; return table.concat(names, ", ") end
    SendChatMessage("[SplitWatch] Team A: " .. fmt(split.teamA), channel)
    SendChatMessage("[SplitWatch] Team B: " .. fmt(split.teamB), channel)
end

local function step()
    if not Apply._queue or #Apply._queue == 0 then
        Apply._running = false
        Apply._queue = nil
        print("|cffffd100SplitWatch:|r " .. L["split applied"])
        broadcastSplit()
        if SplitW.RefreshAll then SplitW:RefreshAll() end
        return
    end
    if InCombatLockdown() then
        Apply._waitingForCombat = true
        Apply._running = false
        print("|cffffd100SplitWatch:|r " .. L["combat detected — resuming after combat ends"])
        return
    end
    local item = table.remove(Apply._queue, 1)
    -- Defensive: re-check still in raid + still leader/assistant each call.
    if not (IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))) then
        Apply._queue = nil
        Apply._running = false
        print("|cffff5555SplitWatch:|r " .. L["lost lead/assist — apply aborted"])
        return
    end
    -- SetRaidSubgroup only accepts moves into a non-full subgroup. If both
    -- target slots are full, SwapRaidSubgroup with a player in the target
    -- group who needs to be elsewhere would be needed — for v0.1.0 we just
    -- try Set and continue on failure (Blizzard silently ignores when full).
    pcall(SetRaidSubgroup, item.raidIndex, item.target)
    C_Timer.After(0.15, step)
end

function Apply:Run()
    local ok, err = self:CanApply()
    if not ok then
        print("|cffff5555SplitWatch:|r " .. (err or "cannot apply"))
        return
    end
    local db = SplitW:GetDB()
    if not db.lastSplit then
        -- Auto-compute if user hits apply without a preview.
        local r = SplitW.Roster:Scan()
        db.lastSplit = SplitW.Splitter:Compute(r)
    end
    local plan = SplitW.Splitter:BuildPlan(db.lastSplit)
    if #plan == 0 then
        print("|cffffd100SplitWatch:|r " .. L["nothing to do — split already matches"])
        return
    end
    Apply._queue = plan
    Apply._running = true
    Apply._waitingForCombat = false
    if db.showOnApply then
        print(format("|cffffd100SplitWatch:|r " .. L["applying split — %d moves queued"], #plan))
    end
    step()
end

function Apply:OnCombatEnd()
    if Apply._waitingForCombat and Apply._queue and #Apply._queue > 0 then
        Apply._waitingForCombat = false
        Apply._running = true
        print("|cffffd100SplitWatch:|r " .. L["combat ended — resuming apply"])
        C_Timer.After(0.3, step)
    end
end

function Apply:Cancel()
    Apply._queue = nil
    Apply._running = false
    Apply._waitingForCombat = false
end
