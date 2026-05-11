local addonName, SplitW = ...

SplitW.DPSSource = SplitW.DPSSource or {}
local DPSSource = SplitW.DPSSource

-- ============================================================
-- BUILT-IN COMBAT LOG TRACKER
-- Always available, zero addon dependency. Sums friendly damage from
-- COMBAT_LOG_EVENT_UNFILTERED per source name; resets on each combat start
-- and stores the previous combat's duration for DPS computation.
-- ============================================================
local builtin = {
    totalDamage  = {},         -- name -> raw damage this combat
    totalHealing = {},         -- name -> effective healing this combat (overheal stripped)
    combatStart  = nil,
    lastCombatDuration = 0,
    -- Snapshots persist after combat so DPS/HPS stay readable between pulls.
    snapshotDamage   = {},
    snapshotHealing  = {},
    snapshotDuration = 0,
}

local FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x00000010
local bit_band = bit.band

local function trackCombatEvent()
    local _, subevent, _, _, sourceName, sourceFlags = CombatLogGetCurrentEventInfo()
    if not sourceName or not sourceFlags then return end
    if bit_band(sourceFlags, FRIENDLY) == 0 then return end

    if subevent == "SWING_DAMAGE" then
        local amount = select(12, CombatLogGetCurrentEventInfo())
        if type(amount) == "number" and amount > 0 then
            builtin.totalDamage[sourceName] = (builtin.totalDamage[sourceName] or 0) + amount
        end
    elseif subevent == "SPELL_DAMAGE"
        or subevent == "SPELL_PERIODIC_DAMAGE"
        or subevent == "RANGE_DAMAGE" then
        local amount = select(15, CombatLogGetCurrentEventInfo())
        if type(amount) == "number" and amount > 0 then
            builtin.totalDamage[sourceName] = (builtin.totalDamage[sourceName] or 0) + amount
        end
    elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
        local amount, overheal = select(15, CombatLogGetCurrentEventInfo()),
                                 select(16, CombatLogGetCurrentEventInfo())
        if type(amount) == "number" and amount > 0 then
            local effective = amount - (tonumber(overheal) or 0)
            if effective > 0 then
                builtin.totalHealing[sourceName] = (builtin.totalHealing[sourceName] or 0) + effective
            end
        end
    end
end

local clf = CreateFrame("Frame")
clf:RegisterEvent("PLAYER_REGEN_DISABLED")
clf:RegisterEvent("PLAYER_REGEN_ENABLED")
clf:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
clf:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        wipe(builtin.totalDamage)
        wipe(builtin.totalHealing)
        builtin.combatStart = GetTime()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if builtin.combatStart then
            builtin.lastCombatDuration = GetTime() - builtin.combatStart
            wipe(builtin.snapshotDamage)
            wipe(builtin.snapshotHealing)
            for k, v in pairs(builtin.totalDamage)  do builtin.snapshotDamage[k]  = v end
            for k, v in pairs(builtin.totalHealing) do builtin.snapshotHealing[k] = v end
            builtin.snapshotDuration = builtin.lastCombatDuration
        end
        builtin.combatStart = nil
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if CombatLogGetCurrentEventInfo then trackCombatEvent() end
    end
end)

local function readBuiltin(name, liveTable, snapTable)
    if not name then return nil end
    if builtin.combatStart then
        local dur = math.max(1, GetTime() - builtin.combatStart)
        local v = liveTable[name]
        if v and v > 0 then return v / dur end
    end
    if builtin.snapshotDuration > 0 then
        local v = snapTable[name]
        if v and v > 0 then return v / builtin.snapshotDuration end
    end
    return nil
end

local function getDPSFromBuiltin(name)
    return readBuiltin(name, builtin.totalDamage, builtin.snapshotDamage)
end

local function getHPSFromBuiltin(name)
    return readBuiltin(name, builtin.totalHealing, builtin.snapshotHealing)
end

-- ============================================================
-- DETAILS! — containerIdx 1 = damage, 2 = healing
-- ============================================================
local function getFromDetails(name, containerIdx)
    local Details = _G.Details
    if not Details then return nil end
    local ok, combat = pcall(function() return Details:GetCurrentCombat() end)
    if not ok or not combat then
        ok, combat = pcall(function() return Details:GetCombat(1) end)
        if not ok or not combat then return nil end
    end
    local container = combat and combat.GetContainer and combat:GetContainer(containerIdx)
    if not container and combat.GetActorList then
        container = combat:GetActorList(containerIdx)
    end
    if not container then return nil end
    local actor
    if type(container) == "table" and container.GetActor then
        actor = container:GetActor(name)
    elseif type(container) == "table" then
        for _, a in ipairs(container) do
            if a.nome == name or a.name == name then actor = a; break end
        end
    end
    if not actor then return nil end
    local total = actor.total or 0
    local elapsed = (combat.GetCombatTime and combat:GetCombatTime()) or actor.tempo or 1
    if elapsed <= 0 then elapsed = 1 end
    return total / elapsed
end

-- ============================================================
-- RECOUNT
-- ============================================================
local function getFromRecount(name, kind)  -- kind = "damage" | "healing"
    local Recount = _G.Recount
    if not Recount then return nil end
    if Recount.GetCurrentDataSet then
        local ok, set = pcall(Recount.GetCurrentDataSet, Recount)
        if ok and set and set[name] then
            local p = set[name]
            if kind == "healing" then
                return tonumber(p.HPS or p.hps
                    or (p.Healing and p.ActiveTime and p.ActiveTime > 0 and p.Healing / p.ActiveTime))
            end
            return tonumber(p.DPS or p.dps
                or (p.Damage and p.ActiveTime and p.ActiveTime > 0 and p.Damage / p.ActiveTime))
        end
    end
    local cur = Recount.CurrentDataCollect
    if Recount.db2 and Recount.db2.combats and cur and Recount.db2.combats[cur] then
        local fight = Recount.db2.combats[cur].Fight
        if fight and fight[name] then
            local p = fight[name]
            local val  = (kind == "healing") and (p.Healing or 0) or (p.Damage or 0)
            local time = p.ActiveTime or p.TimeDamage or 1
            if time > 0 then return val / time end
        end
    end
    return nil
end

-- ============================================================
-- SKADA
-- ============================================================
local function getFromSkada(name, kind)
    local Skada = _G.Skada
    if not Skada then return nil end
    local set = Skada.current or (Skada.GetSet and Skada:GetSet("current"))
    if not set or not set.players then
        set = Skada.last or (Skada.GetSet and Skada:GetSet("last"))
    end
    if not set or not set.players then return nil end
    for _, p in ipairs(set.players) do
        if p.name == name then
            local val
            if kind == "healing" then
                val = p.healing or p.healingdone or p.heal or 0
            else
                val = p.damage or p.damagedone or 0
            end
            local time = p.time or set.time or 1
            if time > 0 and val and val > 0 then return val / time end
        end
    end
    return nil
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function DPSSource:GetDPS(name)
    local src = SplitW:GetDB().dpsSource
    if src == "BUILTIN" then return getDPSFromBuiltin(name) end
    if src == "DETAILS" then return getFromDetails(name, 1) end
    if src == "RECOUNT" then return getFromRecount(name, "damage") end
    if src == "SKADA"   then return getFromSkada(name, "damage") end
    return nil
end

function DPSSource:GetHPS(name)
    local src = SplitW:GetDB().dpsSource
    if src == "BUILTIN" then return getHPSFromBuiltin(name) end
    if src == "DETAILS" then return getFromDetails(name, 2) end
    if src == "RECOUNT" then return getFromRecount(name, "healing") end
    if src == "SKADA"   then return getFromSkada(name, "healing") end
    return nil
end

function DPSSource:IsAvailable(source)
    if source == "BUILTIN" then return true end
    if source == "DETAILS" then return _G.Details ~= nil end
    if source == "RECOUNT" then return _G.Recount ~= nil end
    if source == "SKADA"   then return _G.Skada ~= nil end
    return true -- MANUAL
end

function DPSSource:ActiveSourceLabel()
    local src = SplitW:GetDB().dpsSource
    if src == "BUILTIN" then
        if builtin.snapshotDuration > 0 then
            return string.format("Built-in (last combat: %ds)", math.floor(builtin.snapshotDuration + 0.5))
        elseif builtin.combatStart then
            return "Built-in (combat in progress)"
        else
            return "Built-in (no combat data yet)"
        end
    elseif src == "DETAILS" then
        return self:IsAvailable("DETAILS") and "Details!" or "Details! (not loaded)"
    elseif src == "RECOUNT" then
        return self:IsAvailable("RECOUNT") and "Recount" or "Recount (not loaded)"
    elseif src == "SKADA" then
        return self:IsAvailable("SKADA") and "Skada" or "Skada (not loaded)"
    end
    return "Manual"
end
