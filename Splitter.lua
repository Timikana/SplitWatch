local addonName, SplitW = ...

SplitW.Splitter = SplitW.Splitter or {}
local Splitter = SplitW.Splitter

-- Resolve the effective weight for an entry, going through DPSSource when
-- the user picked an automatic source. Manual mode = the per-name slider.
local function resolveWeight(entry)
    return SplitW:GetEffectiveWeight(entry) or 50
end

-- ============================================================
-- COMPUTE
-- roster: { tanks={}, healers={}, dps={}, raid=N }
-- Returns: { teamA = {entries}, teamB = {entries},
--           scoreA = N, scoreB = N,
--           tanksA, tanksB, healsA, healsB, dpsA, dpsB,
--           warnings = { "..." } }
-- ============================================================
function Splitter:Compute(roster)
    local A, B = {}, {}
    local tanksA, tanksB = 0, 0
    local healsA, healsB = 0, 0
    local dpsA, dpsB = 0, 0
    local sumA, sumB = 0, 0
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

    -- Healers: alternate
    for i, h in ipairs(roster.healers) do
        h.team = (i % 2 == 1) and "A" or "B"
        if h.team == "A" then
            table.insert(A, h); healsA = healsA + 1
        else
            table.insert(B, h); healsB = healsB + 1
        end
    end

    -- DPS: sort by weight desc, then put each on the lighter team (greedy snake).
    table.sort(roster.dps, function(x, y)
        return resolveWeight(x) > resolveWeight(y)
    end)
    for _, d in ipairs(roster.dps) do
        local w = resolveWeight(d)
        if sumA <= sumB then
            d.team = "A"
            table.insert(A, d); dpsA = dpsA + 1; sumA = sumA + w
        else
            d.team = "B"
            table.insert(B, d); dpsB = dpsB + 1; sumB = sumB + w
        end
    end

    -- Slot warnings: each team's two raid subgroups hold 10 max.
    if #A > 10 then table.insert(warnings, "TEAM_A_OVER") end
    if #B > 10 then table.insert(warnings, "TEAM_B_OVER") end

    -- 25-man uneven split warning
    if roster.raid > 20 then
        table.insert(warnings, "UNEVEN_25")
    end

    return {
        teamA   = A, teamB   = B,
        scoreA  = sumA, scoreB = sumB,
        tanksA  = tanksA, tanksB = tanksB,
        healsA  = healsA, healsB = healsB,
        dpsA    = dpsA, dpsB = dpsB,
        warnings = warnings,
    }
end

-- ============================================================
-- BUILD ASSIGNMENT PLAN
-- Returns a list of {raidIndex, targetSubgroup} pairs.
-- Team A = subgroups 1+2, Team B = subgroups 3+4.
-- Skips no-op moves (player already in correct subgroup).
-- ============================================================
function Splitter:BuildPlan(split)
    local plan = {}

    local function assignTeam(team, firstGroup, secondGroup)
        local groupCount = { [firstGroup] = 0, [secondGroup] = 0 }
        for _, e in ipairs(team) do
            local target
            if groupCount[firstGroup] < 5 then
                target = firstGroup
            else
                target = secondGroup
            end
            groupCount[target] = groupCount[target] + 1
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

    assignTeam(split.teamA, 1, 2)
    assignTeam(split.teamB, 3, 4)
    return plan
end
