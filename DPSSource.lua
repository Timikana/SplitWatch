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
-- WoW 12.0 surfaces ADDON_ACTION_FORBIDDEN on COMBAT_LOG_EVENT_UNFILTERED
-- when SplitWatch registers it (root cause undiagnosed — Details!/Recount/Skada
-- all succeed). Deferring registration to PLAYER_LOGIN doesn't fix it either;
-- the protection appears to apply specifically to our load context. So the
-- built-in tracker stays unwired by default — the addon falls back gracefully
-- to Details!/Recount/Skada/Manual.
DPSSource._builtinAvailable = false
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
-- DETAILS! — attr 1 = damage, 2 = healing.
-- Try current combat, then the last completed combat (GetCombat(1)) so the
-- preview still shows DPS/HPS after a fight ends.
-- ============================================================
local function _detailsCombat()
    local Details = _G.Details or _G._detalhes
    if not Details then return nil end
    local function tryGet(getter)
        local ok, c = pcall(getter)
        if ok and type(c) == "table" then return c end
        return nil
    end
    -- A combat is "non-empty" if either its public actor list OR its raw
    -- container index has actor entries with a name. On retail 12.0 the
    -- public GetActorList sometimes returns an empty array even when the
    -- raw container c[1]/c[2] holds Combat actor objects.
    local function hasActors(c)
        if type(c) ~= "table" then return false end
        if c.GetActorList then
            for _, attr in ipairs({1, 2}) do
                local ok, list = pcall(c.GetActorList, c, attr)
                if ok and type(list) == "table" and #list > 0 then return true end
            end
        end
        for _, idx in ipairs({1, 2}) do
            local cont = c[idx]
            if type(cont) == "table" then
                local arr = cont._ActorTable or cont
                if type(arr) == "table" then
                    for _, v in pairs(arr) do
                        if type(v) == "table" and (v.nome or v.name) then return true end
                    end
                end
            end
        end
        return false
    end
    -- Probe a wide set of segment getters AND internal fields. The order
    -- matters: prefer current/recent over overall, prefer public API over
    -- internal table access. Each version of Details / each install state
    -- (post-/reload, mid-combat, post-combat, freshly-loaded) populates a
    -- different subset of these — we accept the first that has actors.
    local candidates = {
        function() return Details:GetCurrentCombat() end,
        function() return Details:GetCombat(0) end,
        function() return Details:GetCombat(1) end,
        function() return Details:GetCombat(2) end,
        function() return Details:GetCombat("overall") end,
        function() return Details:GetCombat(-1) end,
        function() return Details.tabela_vigente end,
        function() return Details.current_combat end,
        function() return Details.tabela_overall end,
    }
    local fallback
    for _, getter in ipairs(candidates) do
        local c = tryGet(getter)
        if c then
            if hasActors(c) then return c end
            fallback = fallback or c
        end
    end
    return fallback
end

local function _detailsActors(combat, attr)
    if not combat then return nil end
    -- Public API path
    if combat.GetActorList then
        local ok, list = pcall(combat.GetActorList, combat, attr)
        if ok and type(list) == "table" and #list > 0 then return list end
    end
    -- Raw container fallback: combat[attr] is a Container; its _ActorTable
    -- (or the container itself in some versions) holds the actor objects.
    local cont = combat[attr]
    if type(cont) == "table" then
        local arr = cont._ActorTable or cont
        if type(arr) == "table" then
            local out = {}
            for _, v in pairs(arr) do
                if type(v) == "table" and (v.nome or v.name) then
                    out[#out + 1] = v
                end
            end
            if #out > 0 then return out end
        end
    end
    return nil
end

-- Cross-realm normalisation: GetRaidRosterInfo returns "Name-Realm" for
-- cross-realm players; damage meters may store the same actor under either
-- "Name-Realm" or just "Name" depending on how the combat log reported it.
-- We compare both the full name and the short-name-only form on both sides.
local function _shortName(n) return type(n) == "string" and (n:match("^([^-]+)") or n) or n end
local function _nameMatch(actorName, lookup)
    if not actorName or not lookup then return false end
    if actorName == lookup then return true end
    return _shortName(actorName) == _shortName(lookup)
end

local function getFromDetails(name, attr)
    local combat = _detailsCombat()
    local actors = _detailsActors(combat, attr)
    if not actors then return nil end
    local actor
    for _, a in ipairs(actors) do
        if _nameMatch(a.nome, name) or _nameMatch(a.name, name) then actor = a; break end
    end
    if not actor then return nil end
    local total = actor.total or 0
    local elapsed = (combat.GetCombatTime and combat:GetCombatTime()) or actor.tempo or 1
    if elapsed <= 0 then elapsed = 1 end
    return total > 0 and (total / elapsed) or nil
end

-- ============================================================
-- RECOUNT
-- ============================================================
local function getFromRecount(name, kind)  -- kind = "damage" | "healing"
    local Recount = _G.Recount
    if not Recount then return nil end
    local short = _shortName(name)
    if Recount.GetCurrentDataSet then
        local ok, set = pcall(Recount.GetCurrentDataSet, Recount)
        if ok and set and (set[name] or set[short]) then
            local p = set[name] or set[short]
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
        if fight and (fight[name] or fight[short]) then
            local p = fight[name] or fight[short]
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
        if _nameMatch(p.name, name) then
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
-- ============================================================
-- ILVL SCANNER — uses Blizzard's NotifyInspect API to fetch each raid
-- member's average item level. Works without any third-party addon, but:
--   * inspect has a ~28-yard range limit
--   * one inspect at a time (we throttle ~1.5s between requests)
--   * results trickle in async via INSPECT_READY
-- Ilvl maps to both DPS and HPS weights (it's a single character-power
-- number) — a high-ilvl character is treated as both a strong damager and
-- a strong healer for balancing purposes.
-- ============================================================
local ilvlCache = {}        -- name -> { ilvl = N, time = T, range = "MELEE"|"RANGED"|nil }

-- Spec ID → attack range. Captured at inspect time alongside ilvl so
-- melee/ranged classification is accurate for hybrid classes (Druid /
-- Shaman / Hunter / Paladin / Monk DPS specs all have melee + ranged
-- variants). Spec IDs are stable across patches.
local SPEC_RANGE = {
    -- Druid
    [102] = "RANGED",  -- Balance
    [103] = "MELEE",   -- Feral
    -- Hunter
    [253] = "RANGED",  -- Beast Mastery
    [254] = "RANGED",  -- Marksmanship
    [255] = "MELEE",   -- Survival
    -- Shaman
    [262] = "RANGED",  -- Elemental
    [263] = "MELEE",   -- Enhancement
    -- Paladin
    [70]  = "MELEE",   -- Retribution
    -- Monk
    [269] = "MELEE",   -- Windwalker
    -- Tank / healer specs return their canonical range too (used for
    -- completeness even though only DPS specs flow into melee/ranged
    -- balancing):
    [104] = "MELEE",   -- Druid Guardian
    [250] = "MELEE",   -- DK Blood
    [581] = "MELEE",   -- DH Vengeance
    [268] = "MELEE",   -- Monk Brewmaster
    [66]  = "MELEE",   -- Paladin Protection
    [73]  = "MELEE",   -- Warrior Protection
}

-- Public access for Splitter to enrich roster entries.
local DPSSource = DPSSource
function DPSSource:GetCachedRange(name)
    local e = ilvlCache[name]
    return e and e.range or nil
end
local ilvlQueue = {}        -- list of unit IDs awaiting inspect
local ilvlBusy = false
local ILVL_CACHE_TTL = 90   -- seconds before we refetch

local ilvlFrame = CreateFrame("Frame")
ilvlFrame:RegisterEvent("INSPECT_READY")

local function _ilvlProcessNext()
    if ilvlBusy then return end
    local unit = table.remove(ilvlQueue, 1)
    if not unit then return end
    if not UnitExists(unit) or not CanInspect or not CanInspect(unit) then
        C_Timer.After(0.3, _ilvlProcessNext)
        return
    end
    ilvlBusy = true
    pcall(NotifyInspect, unit)
    -- Safety timeout: if INSPECT_READY never fires (out of range, etc.),
    -- unblock the queue after 3s and move on.
    C_Timer.After(3, function()
        if ilvlBusy then
            ilvlBusy = false
            _ilvlProcessNext()
        end
    end)
end

ilvlFrame:SetScript("OnEvent", function(_, _, guid)
    if not guid then ilvlBusy = false; _ilvlProcessNext(); return end
    -- Find the raid unit matching this guid.
    local total = GetNumGroupMembers() or 0
    for i = 1, total do
        local unit = (IsInRaid() and ("raid" .. i)) or ("party" .. i)
        if UnitGUID(unit) == guid then
            local ilvl
            if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
                local ok, v = pcall(C_PaperDollInfo.GetInspectItemLevel, unit)
                if ok then ilvl = v end
            end
            if type(ilvl) == "number" and ilvl > 0 then
                local n = UnitName(unit)
                if n then
                    -- Capture spec at the same time — same inspect window, no
                    -- extra requests.
                    local range
                    if GetInspectSpecialization then
                        local ok2, sid = pcall(GetInspectSpecialization, unit)
                        if ok2 and type(sid) == "number" then
                            range = SPEC_RANGE[sid]
                        end
                    end
                    ilvlCache[n] = { ilvl = ilvl, time = GetTime(), range = range }
                end
            end
            pcall(ClearInspectPlayer)
            break
        end
    end
    ilvlBusy = false
    C_Timer.After(1.5, _ilvlProcessNext)
end)

function DPSSource:RefreshIlvl()
    wipe(ilvlQueue)
    local n = GetNumGroupMembers() or 0
    if n == 0 then return end
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, n do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            ilvlQueue[#ilvlQueue + 1] = unit
        end
    end
    -- Cache our own ilvl directly (no inspect needed for the player).
    if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
        local ok, v = pcall(C_PaperDollInfo.GetInspectItemLevel, "player")
        if ok and v and v > 0 then
            ilvlCache[UnitName("player") or "?"] = { ilvl = v, time = GetTime() }
        end
    elseif GetAverageItemLevel then
        local _, equipped = pcall(GetAverageItemLevel)
        if equipped and equipped > 0 then
            ilvlCache[UnitName("player") or "?"] = { ilvl = equipped, time = GetTime() }
        end
    end
    _ilvlProcessNext()
end

local function getFromIlvl(name)
    if not name then return nil end
    local entry = ilvlCache[name]
    if entry and (GetTime() - entry.time) < ILVL_CACHE_TTL then
        return entry.ilvl
    end
    return nil
end

local function listFromIlvl()
    local out = {}
    for name, entry in pairs(ilvlCache) do
        if entry and entry.ilvl and entry.ilvl > 0
            and (GetTime() - entry.time) < ILVL_CACHE_TTL then
            out[#out + 1] = { name = name, class = nil, dps = entry.ilvl, hps = entry.ilvl }
        end
    end
    return out
end

function DPSSource:GetDPS(name)
    local src = SplitW:GetDB().dpsSource
    if src == "BUILTIN" then return getDPSFromBuiltin(name) end
    if src == "DETAILS" then return getFromDetails(name, 1) end
    if src == "RECOUNT" then return getFromRecount(name, "damage") end
    if src == "SKADA"   then return getFromSkada(name, "damage") end
    if src == "ILVL"    then return getFromIlvl(name) end
    return nil
end

function DPSSource:GetHPS(name)
    local src = SplitW:GetDB().dpsSource
    if src == "BUILTIN" then return getHPSFromBuiltin(name) end
    if src == "DETAILS" then return getFromDetails(name, 2) end
    if src == "RECOUNT" then return getFromRecount(name, "healing") end
    if src == "SKADA"   then return getFromSkada(name, "healing") end
    if src == "ILVL"    then return getFromIlvl(name) end
    return nil
end

-- ============================================================
-- LIST ACTORS — enumerates everyone the active source has data for.
-- Used by the preview pane when the user isn't in a raid so they can still
-- verify Details!/Recount/Skada is hooked correctly. Returns:
--   { { name = "...", class = "WARRIOR" | nil, dps = N|nil, hps = N|nil }, ... }
-- ============================================================
local function listFromDetails()
    local out = {}
    local combat = _detailsCombat()
    if not combat then return out end
    local elapsed = (combat.GetCombatTime and combat:GetCombatTime()) or 1
    if elapsed <= 0 then elapsed = 1 end

    local seen = {}
    local function walk(actors, key)
        if not actors then return end
        for _, actor in ipairs(actors) do
            local n = actor.nome or actor.name
            -- Drop only the synthetic [*] aggregate Details inserts at index 1
            -- (its name starts with [). Keep everything else so solo / pet
            -- damage / environment actors all show up — better to show too
            -- much than miss the player.
            if type(n) == "string" and not n:match("^%[") then
                local rec = seen[n] or { name = n, class = actor.classe or actor.class }
                local total = actor.total or 0
                if total > 0 then rec[key] = total / elapsed end
                seen[n] = rec
            end
        end
    end
    walk(_detailsActors(combat, 1), "dps")
    walk(_detailsActors(combat, 2), "hps")
    for _, rec in pairs(seen) do
        if rec.dps or rec.hps then out[#out + 1] = rec end
    end
    return out
end

local function listFromRecount()
    local out = {}
    local Recount = _G.Recount
    if not Recount then return out end
    local cur = Recount.CurrentDataCollect
    if Recount.db2 and Recount.db2.combats and cur and Recount.db2.combats[cur] then
        local fight = Recount.db2.combats[cur].Fight
        if fight then
            for n, p in pairs(fight) do
                if type(p) == "table" then
                    local dps = (p.Damage and p.ActiveTime and p.ActiveTime > 0)
                        and (p.Damage / p.ActiveTime) or nil
                    local hps = (p.Healing and p.ActiveTime and p.ActiveTime > 0)
                        and (p.Healing / p.ActiveTime) or nil
                    out[#out + 1] = { name = n, dps = dps, hps = hps, class = p.Class or p.class }
                end
            end
        end
    end
    return out
end

local function listFromSkada()
    local out = {}
    local Skada = _G.Skada
    if not Skada then return out end
    local set = Skada.current or (Skada.GetSet and Skada:GetSet("current"))
    if not set or not set.players then
        set = Skada.last or (Skada.GetSet and Skada:GetSet("last"))
    end
    if not set or not set.players then return out end
    local elapsed = set.time or 1
    if elapsed <= 0 then elapsed = 1 end
    for _, p in ipairs(set.players) do
        local dmg  = p.damage or p.damagedone or 0
        local heal = p.healing or p.healingdone or p.heal or 0
        out[#out + 1] = {
            name  = p.name,
            class = p.class,
            dps   = (dmg  > 0) and (dmg  / elapsed) or nil,
            hps   = (heal > 0) and (heal / elapsed) or nil,
        }
    end
    return out
end

function DPSSource:ListActors()
    local src = SplitW:GetDB().dpsSource
    if src == "DETAILS" then return listFromDetails() end
    if src == "RECOUNT" then return listFromRecount() end
    if src == "SKADA"   then return listFromSkada() end
    if src == "ILVL"    then return listFromIlvl()    end
    return {}
end

function DPSSource:IsAvailable(source)
    if source == "BUILTIN" then return DPSSource._builtinAvailable and true or false end
    if source == "DETAILS" then return _G.Details ~= nil end
    if source == "RECOUNT" then return _G.Recount ~= nil end
    if source == "SKADA"   then return _G.Skada ~= nil end
    if source == "ILVL"    then return true end  -- uses Blizzard inspect API
    return true -- MANUAL
end

function DPSSource:ActiveSourceLabel()
    local src = SplitW:GetDB().dpsSource
    if src == "BUILTIN" then
        if not DPSSource._builtinAvailable then
            return "Built-in (blocked by Blizzard event protection)"
        elseif builtin.snapshotDuration > 0 then
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
    elseif src == "ILVL" then
        local n = 0
        for _ in pairs(ilvlCache) do n = n + 1 end
        return string.format("Item Level (inspect) — %d cached", n)
    end
    return "Manual"
end
