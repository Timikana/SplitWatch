local addonName, SplitW = ...

SplitW.Splitter = SplitW.Splitter or {}
local Splitter = SplitW.Splitter

-- Resolve the effective weight for an entry, going through DPSSource when
-- the user picked an automatic source. Manual mode = the per-name slider.
local function resolveDmgWeight(entry)
    return SplitW:GetEffectiveWeight(entry) or 50
end

local function resolveHealWeight(entry)
    return SplitW:GetEffectiveHPS(entry) or 50
end

-- ============================================================
-- CONSTRAINT DEFINITIONS — keyed into SplitW:GetDB().constraint*.
-- Each rule provides a class set; the resolver pass swaps minimally to
-- guarantee both teams have at least one matching class. Melee/ranged
-- is handled separately because it's a ratio, not a presence check.
-- ============================================================
Splitter.CONSTRAINTS = {
    -- Battle Rez in retail: Druid (Rebirth), DK (Raise Ally), Warlock (Soulstone).
    -- Hunter / Paladin / DH do NOT have an in-combat resurrection.
    { dbKey = "constraintBR",       id = "BR",
      classes = { DRUID = true, DEATHKNIGHT = true, WARLOCK = true } },
    -- Lust givers: Shaman (Heroism/BL), Mage (Time Warp), Hunter (Primal Rage,
    -- BM-only), Evoker (Fury of the Aspects). Hunter included as approximate;
    -- toggle off if your hunters are MM/Survival.
    { dbKey = "constraintLust",     id = "LUST",
      classes = { SHAMAN = true, MAGE = true, HUNTER = true, EVOKER = true } },
    -- Mass Dispel: Priest (any spec).
    { dbKey = "constraintMassDisp", id = "MASS_DISPEL",
      classes = { PRIEST = true } },
    -- Decurse (Curse removal): Mage (Remove Curse), Druid (Remove Corruption),
    -- Shaman (Cleanse Spirit). Monk Detox handles Magic + Disease, NOT Curse.
    -- Paladin Cleanse Toxins handles Poison + Disease, NOT Curse.
    { dbKey = "constraintDecurse",  id = "DECURSE",
      classes = { MAGE = true, DRUID = true, SHAMAN = true } },
}

-- Class → default attack range (approximate; the most common DPS spec).
-- An entry can override this by setting entry.attackRange directly (e.g.
-- via inspect spec when the DPSSource ilvl scan also captures spec).
Splitter.CLASS_RANGE = {
    ROGUE       = "MELEE",   WARRIOR     = "MELEE",
    DEATHKNIGHT = "MELEE",   DEMONHUNTER = "MELEE",
    MONK        = "MELEE",   PALADIN     = "MELEE",
    MAGE        = "RANGED",  WARLOCK     = "RANGED",
    EVOKER      = "RANGED",  PRIEST      = "RANGED",
    HUNTER      = "RANGED",
    DRUID       = "RANGED",  -- Balance more common as DPS
    SHAMAN      = "RANGED",  -- Elemental more common as DPS
}

local function entryRange(entry)
    return entry.attackRange or Splitter.CLASS_RANGE[entry.class] or "MELEE"
end

local function teamHasClass(team, classSet)
    for _, e in ipairs(team) do
        if classSet[e.class] then return true end
    end
    return false
end

-- ============================================================
-- COMPUTE
-- roster: { tanks={}, healers={}, dps={}, raid=N }
-- Returns: { teamA = {entries}, teamB = {entries},
--           scoreA, scoreB        (DPS damage score per team)
--           healScoreA, healScoreB (HPS healing score per team)
--           tanksA, tanksB, healsA, healsB, dpsA, dpsB,
--           warnings = { "..." } }
-- ============================================================
function Splitter:Compute(roster)
    local A, B = {}, {}
    local tanksA, tanksB = 0, 0
    local healsA, healsB = 0, 0
    local dpsA, dpsB = 0, 0
    local sumA, sumB = 0, 0          -- damage scores
    local healSumA, healSumB = 0, 0  -- healing scores
    local warnings = {}

    -- Tag locked entries from the saved manual locks. Locked players get
    -- placed on their pinned team first and are skipped by all later passes.
    local locks = SplitW:GetDB().lockedTeams or {}
    local function applyLockTag(list)
        for _, e in ipairs(list) do
            e.locked = locks[e.name] -- "A" / "B" / nil
        end
    end
    applyLockTag(roster.tanks)
    applyLockTag(roster.healers)
    applyLockTag(roster.dps)

    -- Tanks: respect lock first, otherwise alternate (1→A, 2→B, 3→A …).
    local autoTankIdx = 0
    for _, t in ipairs(roster.tanks) do
        local target = t.locked
        if not target then
            autoTankIdx = autoTankIdx + 1
            target = (autoTankIdx % 2 == 1) and "A" or "B"
        end
        t.team = target
        if target == "A" then
            table.insert(A, t); tanksA = tanksA + 1
        else
            table.insert(B, t); tanksB = tanksB + 1
        end
    end
    if #roster.tanks == 1 then
        table.insert(warnings, "ONE_TANK")
    elseif #roster.tanks == 0 then
        table.insert(warnings, "NO_TANK")
    end

    -- Healers: place locked first to seed the score totals, then snake the rest
    -- by HPS desc.
    table.sort(roster.healers, function(x, y)
        return resolveHealWeight(x) > resolveHealWeight(y)
    end)
    for _, h in ipairs(roster.healers) do
        if h.locked then
            local w = resolveHealWeight(h)
            h.team = h.locked
            if h.locked == "A" then
                table.insert(A, h); healsA = healsA + 1; healSumA = healSumA + w
            else
                table.insert(B, h); healsB = healsB + 1; healSumB = healSumB + w
            end
        end
    end
    for _, h in ipairs(roster.healers) do
        if not h.locked then
            local w = resolveHealWeight(h)
            if healSumA <= healSumB then
                h.team = "A"
                table.insert(A, h); healsA = healsA + 1; healSumA = healSumA + w
            else
                h.team = "B"
                table.insert(B, h); healsB = healsB + 1; healSumB = healSumB + w
            end
        end
    end

    -- DPS: locked first (seed scores), then snake the rest by DPS desc.
    table.sort(roster.dps, function(x, y)
        return resolveDmgWeight(x) > resolveDmgWeight(y)
    end)
    for _, d in ipairs(roster.dps) do
        if d.locked then
            local w = resolveDmgWeight(d)
            d.team = d.locked
            if d.locked == "A" then
                table.insert(A, d); dpsA = dpsA + 1; sumA = sumA + w
            else
                table.insert(B, d); dpsB = dpsB + 1; sumB = sumB + w
            end
        end
    end
    for _, d in ipairs(roster.dps) do
        if not d.locked then
            local w = resolveDmgWeight(d)
            if sumA <= sumB then
                d.team = "A"
                table.insert(A, d); dpsA = dpsA + 1; sumA = sumA + w
            else
                d.team = "B"
                table.insert(B, d); dpsB = dpsB + 1; sumB = sumB + w
            end
        end
    end

    -- Size rebalance pass — the per-role snake distribution can produce
    -- uneven team sizes when role counts are odd (e.g. 2T + 1H + 17DPS = 20
    -- → 1T+1H+9DPS = 11 vs 1T+0H+8DPS = 9, a gap of 2). For an even raid we
    -- want a 0-gap split, for an odd raid we tolerate a 1-gap. Move the
    -- weakest DPS from the larger team to the smaller one until the gap is
    -- ≤ 1. Picking the weakest minimises the score-balance disruption.
    local function _moveWeakestDps(fromTeam, fromIsA)
        for i = #fromTeam, 1, -1 do
            local e = fromTeam[i]
            if e.role ~= "TANK" and e.role ~= "HEALER" and not e.locked then
                table.remove(fromTeam, i)
                local w = resolveDmgWeight(e)
                if fromIsA then
                    table.insert(B, e); e.team = "B"
                    sumA = sumA - w; sumB = sumB + w
                    dpsA = dpsA - 1; dpsB = dpsB + 1
                else
                    table.insert(A, e); e.team = "A"
                    sumB = sumB - w; sumA = sumA + w
                    dpsB = dpsB - 1; dpsA = dpsA + 1
                end
                return true
            end
        end
        return false
    end
    while math.abs(#A - #B) > 1 do
        if not _moveWeakestDps(#A > #B and A or B, #A > #B) then break end
    end

    -- Constraint resolver pass. Each toggled constraint either runs a
    -- presence check (class set in CONSTRAINTS) or the melee/ranged ratio.
    -- Swap candidates with similar DPS scores so the balance doesn't tank.
    local db = SplitW:GetDB()

    -- Swap a DPS entry of (sourceTeam, lookingForClasses) with a DPS entry
    -- in (lackingTeam) that does NOT match the classes. Pick the swap that
    -- minimises |scoreA - scoreB| change.
    local function ensurePresence(constraint)
        local hasA = teamHasClass(A, constraint.classes)
        local hasB = teamHasClass(B, constraint.classes)
        if hasA and hasB then return true end
        if not hasA and not hasB then
            table.insert(warnings, "CONSTRAINT_MISSING_" .. constraint.id)
            return false
        end
        local lacking      = hasA and B or A
        local lackingIsA   = not hasA
        local source       = hasA and A or B
        local bestI, bestJ, bestDelta
        for i, candidate in ipairs(source) do
            if candidate.role == "DAMAGER" and constraint.classes[candidate.class]
               and not candidate.locked then
                for j, target in ipairs(lacking) do
                    if target.role == "DAMAGER"
                       and not constraint.classes[target.class]
                       and not target.locked then
                        local wc = resolveDmgWeight(candidate)
                        local wt = resolveDmgWeight(target)
                        -- Score delta on `lacking`: gains wc, loses wt → +(wc-wt)
                        local delta = math.abs((sumA - sumB)
                            + (lackingIsA and (wc - wt) or -(wc - wt)))
                        if not bestDelta or delta < bestDelta then
                            bestDelta, bestI, bestJ = delta, i, j
                        end
                    end
                end
            end
        end
        if not bestI then
            table.insert(warnings, "CONSTRAINT_UNSWAPPABLE_" .. constraint.id)
            return false
        end
        local cand, targ = source[bestI], lacking[bestJ]
        source[bestI], lacking[bestJ] = targ, cand
        cand.team, targ.team = (lackingIsA and "A" or "B"), (lackingIsA and "B" or "A")
        local wc, wt = resolveDmgWeight(cand), resolveDmgWeight(targ)
        if lackingIsA then
            sumA = sumA + (wc - wt); sumB = sumB + (wt - wc)
        else
            sumB = sumB + (wc - wt); sumA = sumA + (wt - wc)
        end
        return true
    end

    for _, c in ipairs(Splitter.CONSTRAINTS) do
        if db[c.dbKey] then ensurePresence(c) end
    end

    -- Melee/ranged equalisation — count DPS-only, then swap until |diff| ≤ 1.
    local function countMelee(team)
        local m = 0
        for _, e in ipairs(team) do
            if e.role == "DAMAGER" and entryRange(e) == "MELEE" then m = m + 1 end
        end
        return m
    end
    if db.constraintMR then
        local guard = 0
        while guard < 20 do
            guard = guard + 1
            local mA, mB = countMelee(A), countMelee(B)
            if math.abs(mA - mB) <= 1 then break end
            local fromTeam, fromIsA = (mA > mB) and A or B, mA > mB
            local toTeam = fromIsA and B or A
            -- Find a melee in source + a ranged in target with similar score.
            local bestI, bestJ, bestDelta
            for i, src in ipairs(fromTeam) do
                if src.role == "DAMAGER" and entryRange(src) == "MELEE" and not src.locked then
                    for j, tgt in ipairs(toTeam) do
                        if tgt.role == "DAMAGER" and entryRange(tgt) == "RANGED" and not tgt.locked then
                            local ws, wt = resolveDmgWeight(src), resolveDmgWeight(tgt)
                            local delta = math.abs((sumA - sumB)
                                + (fromIsA and (wt - ws) or (ws - wt)))
                            if not bestDelta or delta < bestDelta then
                                bestDelta, bestI, bestJ = delta, i, j
                            end
                        end
                    end
                end
            end
            if not bestI then
                table.insert(warnings, "CONSTRAINT_UNSWAPPABLE_MR")
                break
            end
            local s, t = fromTeam[bestI], toTeam[bestJ]
            fromTeam[bestI], toTeam[bestJ] = t, s
            s.team, t.team = fromIsA and "B" or "A", fromIsA and "A" or "B"
            local ws, wt = resolveDmgWeight(s), resolveDmgWeight(t)
            if fromIsA then
                sumA = sumA + (wt - ws); sumB = sumB + (ws - wt)
            else
                sumB = sumB + (wt - ws); sumA = sumA + (ws - wt)
            end
        end
    end

    -- Slot warnings: a raid has 8 subgroups of 5. Worst case each team gets up
    -- to 4 subgroups = 20 players. Anything beyond 40 total is impossible anyway.
    if #A > 20 then table.insert(warnings, "TEAM_A_OVER") end
    if #B > 20 then table.insert(warnings, "TEAM_B_OVER") end

    -- Uneven warning (informational): when team sizes differ by more than 1,
    -- the score balance is already optimized but the player-count gap is real.
    if math.abs(#A - #B) > 1 then
        table.insert(warnings, "UNEVEN_TEAMS")
    end

    return {
        teamA   = A, teamB   = B,
        scoreA  = sumA, scoreB = sumB,
        healScoreA = healSumA, healScoreB = healSumB,
        tanksA  = tanksA, tanksB = tanksB,
        healsA  = healsA, healsB = healsB,
        dpsA    = dpsA, dpsB = dpsB,
        warnings = warnings,
    }
end

-- ============================================================
-- TEAM → SUBGROUP MAPPING (dynamic, supports 10 to 40-man raids)
-- For team size N, each team uses ceil(N/5) subgroups (capped at 4 since
-- a WoW raid only has 8 subgroups total):
--   10-man  → A=group 1,           B=group 2              (5 max each)
--   11-20   → A=groups 1+2,        B=groups 3+4           (10 max each)
--   21-30   → A=groups 1+2+3,      B=groups 4+5+6         (15 max each)
--   31-40   → A=groups 1+2+3+4,    B=groups 5+6+7+8       (20 max each)
-- ============================================================
function Splitter:GetTargetGroups(split)
    local maxTeam = math.max(#split.teamA, #split.teamB)
    local perTeam = math.max(1, math.min(4, math.ceil(maxTeam / 5)))
    local A, B = {}, {}
    for i = 1, perTeam do A[#A + 1] = i end
    for i = 1, perTeam do B[#B + 1] = perTeam + i end
    return A, B
end

-- ============================================================
-- BUILD ASSIGNMENT PLAN
-- Fills team A subgroups left-to-right (5 per slot), then team B.
-- Skips no-op moves (player already in correct subgroup).
-- ============================================================
function Splitter:BuildPlan(split)
    local plan = {}
    local aGroups, bGroups = self:GetTargetGroups(split)

    local function assignTeam(team, groups)
        local count = {}
        for _, g in ipairs(groups) do count[g] = 0 end
        for _, e in ipairs(team) do
            local target
            for _, g in ipairs(groups) do
                if count[g] < 5 then target = g; break end
            end
            if not target then target = groups[#groups] end -- overflow safety
            count[target] = count[target] + 1
            if e.subgroup ~= target then
                plan[#plan + 1] = {
                    raidIndex = e.raidIndex,
                    target    = target,
                    name      = e.name,
                    fromGroup = e.subgroup,
                }
            end
        end
    end

    assignTeam(split.teamA, aGroups)
    assignTeam(split.teamB, bGroups)
    return plan
end
