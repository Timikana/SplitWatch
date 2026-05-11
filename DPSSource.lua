local addonName, SplitW = ...

SplitW.DPSSource = SplitW.DPSSource or {}
local DPSSource = SplitW.DPSSource

-- ============================================================
-- Return the most recent DPS value for `name`, in raw damage-per-second.
-- Picks the source configured in SplitWatchDB. Falls back gracefully when
-- the target addon isn't loaded or has no current combat.
-- ============================================================

local function getFromDetails(name)
    local Details = _G.Details
    if not Details then return nil end
    local ok, combat = pcall(function() return Details:GetCurrentCombat() end)
    if not ok or not combat then
        -- Try previous combat if current isn't ready.
        ok, combat = pcall(function() return Details:GetCombat(1) end)
        if not ok or not combat then return nil end
    end
    -- Damage actor container is index 1 in Details.
    local container = combat and combat.GetContainer and combat:GetContainer(1)
    if not container then
        if combat.GetActorList then
            container = combat:GetActorList(1)
        end
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
    local total = actor.total or actor.damage_taken or 0
    local elapsed = (combat.GetCombatTime and combat:GetCombatTime()) or actor.tempo or 1
    if elapsed <= 0 then elapsed = 1 end
    return total / elapsed
end

local function getFromRecount(name)
    local Recount = _G.Recount
    if not Recount or not Recount.db or not Recount.db2 then
        -- Recount fingerprint differs by version; bail if the basic table isn't there.
    end
    if not Recount then return nil end
    -- Public-ish accessor used by some addons:
    if Recount.GetCurrentDataSet then
        local ok, set = pcall(Recount.GetCurrentDataSet, Recount)
        if ok and set and set[name] then
            local p = set[name]
            return tonumber(p.DPS or p.dps or (p.Damage and p.ActiveTime and p.Damage / p.ActiveTime))
        end
    end
    -- Fallback: read Recount.db2.combats[Recount.CurrentDataCollect].Fight[name]
    local cur = Recount.CurrentDataCollect
    if Recount.db2 and Recount.db2.combats and cur and Recount.db2.combats[cur] then
        local fight = Recount.db2.combats[cur].Fight
        if fight and fight[name] then
            local p = fight[name]
            local dmg = p.Damage or 0
            local time = p.ActiveTime or p.TimeDamage or 1
            if time > 0 then return dmg / time end
        end
    end
    return nil
end

function DPSSource:GetDPS(name)
    local db = SplitW:GetDB()
    if db.dpsSource == "DETAILS" then
        return getFromDetails(name)
    elseif db.dpsSource == "RECOUNT" then
        return getFromRecount(name)
    end
    return nil
end

function DPSSource:IsAvailable(source)
    if source == "DETAILS" then return _G.Details ~= nil end
    if source == "RECOUNT" then return _G.Recount ~= nil end
    return true -- MANUAL is always available
end

function DPSSource:ActiveSourceLabel()
    local db = SplitW:GetDB()
    if db.dpsSource == "DETAILS" then
        return self:IsAvailable("DETAILS") and "Details!" or "Details (not loaded)"
    elseif db.dpsSource == "RECOUNT" then
        return self:IsAvailable("RECOUNT") and "Recount" or "Recount (not loaded)"
    end
    return "Manual"
end
