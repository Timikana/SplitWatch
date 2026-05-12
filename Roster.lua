local addonName, SplitW = ...

SplitW.Roster = SplitW.Roster or {}
local Roster = SplitW.Roster

-- ============================================================
-- TEST MODE (simulated 20-man for UI testing without a raid)
-- ============================================================
Roster._testMode = false

-- Mock names + classes for 20-man simulation. 2 tanks, 4 healers, 14 DPS.
local TEST_ROSTER = {
    -- TANKS
    { name = "Brewmir",   class = "MONK",        role = "TANK"    },
    { name = "Stoneguard", class = "DEATHKNIGHT", role = "TANK"   },
    -- HEALERS
    { name = "Lumenara",  class = "PRIEST",      role = "HEALER"  },
    { name = "Sageleaf",  class = "DRUID",       role = "HEALER"  },
    { name = "Stormpaw",  class = "SHAMAN",      role = "HEALER"  },
    { name = "Dawnsworn", class = "PALADIN",     role = "HEALER"  },
    -- DPS (mixed classes)
    { name = "Shadeclaw", class = "ROGUE",       role = "DAMAGER" },
    { name = "Pyrowave",  class = "MAGE",        role = "DAMAGER" },
    { name = "Voidcaller", class = "WARLOCK",    role = "DAMAGER" },
    { name = "Stagstride", class = "HUNTER",     role = "DAMAGER" },
    { name = "Fanglight", class = "DEMONHUNTER", role = "DAMAGER" },
    { name = "Sunblade",  class = "PALADIN",     role = "DAMAGER" },
    { name = "Tempest",   class = "SHAMAN",      role = "DAMAGER" },
    { name = "Razorvein", class = "DEATHKNIGHT", role = "DAMAGER" },
    { name = "Brackenroot", class = "DRUID",     role = "DAMAGER" },
    { name = "Vexxis",    class = "EVOKER",      role = "DAMAGER" },
    { name = "Glaivewing", class = "DEMONHUNTER", role = "DAMAGER" },
    { name = "Skyburn",   class = "MAGE",        role = "DAMAGER" },
    { name = "Ironpierce", class = "WARRIOR",    role = "DAMAGER" },
    { name = "Quicksilver", class = "ROGUE",     role = "DAMAGER" },
}

function Roster:SetTestMode(on)
    self._testMode = on and true or false
end

function Roster:IsTestMode()
    return self._testMode
end

-- ============================================================
-- SCAN
-- Returns { tanks = {...}, healers = {...}, dps = {...}, raid = N }
-- Each entry: { name, raidIndex, subgroup, class, role, weight }
-- ============================================================
function Roster:Scan()
    local out = { tanks = {}, healers = {}, dps = {}, raid = 0 }

    if self._testMode then
        out.raid = #TEST_ROSTER
        for i, m in ipairs(TEST_ROSTER) do
            local subgroup = math.ceil(i / 5)
            local entry = {
                name      = m.name,
                raidIndex = i,
                subgroup  = subgroup,
                class     = m.class,
                role      = m.role,
                weight    = SplitW:GetWeight(m.name) or (SplitW:GetDB().weightDefault or 50),
            }
            if m.role == "TANK" then
                table.insert(out.tanks, entry)
            elseif m.role == "HEALER" then
                table.insert(out.healers, entry)
            else
                table.insert(out.dps, entry)
            end
        end
        return out
    end

    out.raid = GetNumGroupMembers() or 0
    if out.raid == 0 or not IsInRaid() then return out end

    for i = 1, out.raid do
        local name, _, subgroup, _, _, fileName, _, online, _, _, _, combatRole = GetRaidRosterInfo(i)
        if name then
            local r = combatRole
            if not r or r == "NONE" then
                r = UnitGroupRolesAssigned("raid" .. i) or "DAMAGER"
            end
            local entry = {
                name      = name,
                raidIndex = i,
                subgroup  = subgroup,
                class     = fileName,
                role      = r,
                online    = online,
                weight    = SplitW:GetWeight(name) or (SplitW:GetDB().weightDefault or 50),
            }
            -- Enrich with inspected spec → attack range if we already have it
            -- cached (the ilvl scan populates this for the whole raid).
            if SplitW.DPSSource and SplitW.DPSSource.GetCachedRange then
                entry.attackRange = SplitW.DPSSource:GetCachedRange(name)
            end
            if r == "TANK" then
                table.insert(out.tanks, entry)
            elseif r == "HEALER" then
                table.insert(out.healers, entry)
            else
                table.insert(out.dps, entry)
            end
        end
    end
    return out
end
