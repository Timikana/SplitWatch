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

    -- Tanks: alternate (1→A, 2→B, 3→A, …). If exactly 1 tank → A.
    for i, t in ipairs(roster.tanks) do
        t.team = (i % 2 == 1) and "A" or "B"
        if t.team == "A" then
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

    -- Healers: sort by HPS desc, snake-distribute on healSum (balances by raw
    -- healing throughput so each team gets comparable healing power, not just
    -- a matching healer count).
    table.sort(roster.healers, function(x, y)
        return resolveHealWeight(x) > resolveHealWeight(y)
    end)
    for _, h in ipairs(roster.healers) do
        local w = resolveHealWeight(h)
        if healSumA <= healSumB then
            h.team = "A"
            table.insert(A, h); healsA = healsA + 1; healSumA = healSumA + w
        else
            h.team = "B"
            table.insert(B, h); healsB = healsB + 1; healSumB = healSumB + w
        end
    end

    -- DPS: sort by weight desc, then put each on the lighter team (greedy snake).
    table.sort(roster.dps, function(x, y)
        return resolveDmgWeight(x) > resolveDmgWeight(y)
    end)
    for _, d in ipairs(roster.dps) do
        local w = resolveDmgWeight(d)
        if sumA <= sumB then
            d.team = "A"
            table.insert(A, d); dpsA = dpsA + 1; sumA = sumA + w
        else
            d.team = "B"
            table.insert(B, d); dpsB = dpsB + 1; sumB = sumB + w
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
