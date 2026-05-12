local addonName, SplitW = ...

SplitW.Roster = SplitW.Roster or {}
local Roster = SplitW.Roster

-- ============================================================
-- TEST MODE (simulated 20-man for UI testing without a raid)
-- ============================================================
Roster._testMode = false

-- Test mode pools — pick subsets sized to the user's selected test roster
-- size (Roster:GetTestSize, default 20). Realistic ratios per size class.
local TEST_TANKS = {
    { name = "Brewmir",       class = "MONK"        },
    { name = "Stoneguard",    class = "DEATHKNIGHT" },
    { name = "Frostsentinel", class = "DEATHKNIGHT" },
    { name = "Earthbulwark",  class = "WARRIOR"     },
}
local TEST_HEALERS = {
    { name = "Lumenara",   class = "PRIEST"  },
    { name = "Sageleaf",   class = "DRUID"   },
    { name = "Stormpaw",   class = "SHAMAN"  },
    { name = "Dawnsworn",  class = "PALADIN" },
    { name = "Mosswind",   class = "DRUID"   },
    { name = "Sunwhisper", class = "PALADIN" },
    { name = "Tideheart",  class = "SHAMAN"  },
    { name = "Veilsong",   class = "PRIEST"  },
    { name = "Mistgrove",  class = "MONK"    },
    { name = "Wavebloom",  class = "EVOKER"  },
}
local TEST_DPS = {
    { name = "Shadeclaw",    class = "ROGUE"       },
    { name = "Pyrowave",     class = "MAGE"        },
    { name = "Voidcaller",   class = "WARLOCK"     },
    { name = "Stagstride",   class = "HUNTER"      },
    { name = "Fanglight",    class = "DEMONHUNTER" },
    { name = "Sunblade",     class = "PALADIN"     },
    { name = "Tempest",      class = "SHAMAN"      },
    { name = "Razorvein",    class = "DEATHKNIGHT" },
    { name = "Brackenroot",  class = "DRUID"       },
    { name = "Vexxis",       class = "EVOKER"      },
    { name = "Glaivewing",   class = "DEMONHUNTER" },
    { name = "Skyburn",      class = "MAGE"        },
    { name = "Ironpierce",   class = "WARRIOR"     },
    { name = "Quicksilver",  class = "ROGUE"       },
    { name = "Doomspeaker",  class = "WARLOCK"     },
    { name = "Arrowstorm",   class = "HUNTER"      },
    { name = "Crimsonfang",  class = "DEATHKNIGHT" },
    { name = "Frostweaver",  class = "MAGE"        },
    { name = "Thornstrike",  class = "DRUID"       },
    { name = "Stormhowl",    class = "SHAMAN"      },
    { name = "Ravenheart",   class = "PRIEST"      },
    { name = "Vengewing",    class = "DEMONHUNTER" },
    { name = "Lightbringer", class = "PALADIN"     },
    { name = "Whirlblade",   class = "WARRIOR"     },
    { name = "Soulrend",     class = "WARLOCK"     },
    { name = "Embertongue",  class = "EVOKER"      },
    { name = "Nightveil",    class = "ROGUE"       },
    { name = "Sandstrike",   class = "MONK"        },
    { name = "Ashenshard",   class = "WARRIOR"     },
    { name = "Twilightpaw",  class = "DRUID"       },
}

-- Given a target raid size, return desired (#tanks, #healers, #dps) using
-- standard raid ratios (~2-3 tanks, ~1 healer per 4-5 DPS).
local function targetComposition(size)
    if size <= 10 then return 2, 2, size - 4 end
    if size <= 15 then return 2, 3, size - 5 end
    if size <= 20 then return 2, 4, size - 6 end
    if size <= 25 then return 2, 5, size - 7 end
    if size <= 30 then return 3, 7, size - 10 end
    return 3, 9, size - 12  -- 31-40 man
end

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
function Roster:GetTestSize()
    local v = SplitW:GetDB().testRosterSize
    if type(v) ~= "number" or v < 10 then v = 20 end
    if v > 40 then v = 40 end
    return v
end

function Roster:Scan()
    local out = { tanks = {}, healers = {}, dps = {}, raid = 0 }

    if self._testMode then
        local size = self:GetTestSize()
        local nT, nH, nD = targetComposition(size)
        local raidIdx = 0
        local function pushPool(pool, want, role, list)
            for i = 1, math.min(want, #pool) do
                raidIdx = raidIdx + 1
                local m = pool[i]
                table.insert(list, {
                    name      = m.name,
                    raidIndex = raidIdx,
                    subgroup  = math.ceil(raidIdx / 5),
                    class     = m.class,
                    role      = role,
                    weight    = SplitW:GetWeight(m.name) or (SplitW:GetDB().weightDefault or 50),
                })
            end
        end
        pushPool(TEST_TANKS,   nT, "TANK",    out.tanks)
        pushPool(TEST_HEALERS, nH, "HEALER",  out.healers)
        pushPool(TEST_DPS,     nD, "DAMAGER", out.dps)
        out.raid = raidIdx
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
