# SplitWatch — Project Guide

## What this is

A WoW addon that **auto-splits a 20-man raid into 2 balanced teams** for split-mechanic fights (Spirit Kings MoP, certain Mythic+ etc.). Balancing criteria :

- 1+ tank per team
- Healers count equalized
- DPS distributed by recent damage output (snake/zig-zag pattern)
- One-click "Apply" → reassigns subgroups via `SetRaidSubgroup`

- **Author**: Timikana
- **Slash command**: `/splitw` (canonical) + `/splitwatch` (alias)
- **SavedVariables**: `SplitWatchDB`
- **Global namespace**: `_G.SplitWatch` (also exposed as `SplitW` inside addon files — same convention as `BossW` / `TankW`)
- **Sister addons family**: BossWatch + TankWatch + SplitWatch all share UI patterns, side tabs, and cross-addon position handoff.

This is a NEW addon, no upstream. Greenfield repo. Created 2026-05-11.

## Sister addons reference

The user has built two sister addons that establish the conventions to follow.
**Read them before doing anything else** — they encode 6 months of decisions
about UI, namespacing, Classic support, secret-value handling, and release flow.

- **BossWatch** at `u:\WoW_BossWatch` — primary reference. The CLAUDE.md
  at `u:\WoW_BossWatch\CLAUDE.md` is the canonical playbook.
- **TankWatch** at `u:\WoW_TankWatch` — mirror conventions but for tank
  visibility/debuffs.

When in doubt, **copy the BossWatch pattern verbatim** (UI factories,
section system, Locales structure, Options/Panel.lua skeleton). Then adapt
the content to SplitWatch's domain.

## Feature scope — phased

### v0.1.0 MVP (start here)
- Roster reader (uses `GetRaidRosterInfo`, `UnitGroupRolesAssigned`)
- **Manual weight mode**: per-player slider 1-5 in options panel
- Snake-distribution algorithm: highest weight to A, 2nd to B, 3rd to A…
- Tanks: 1 to A, rest to B (or balanced if 2+ tanks)
- Healers: alternate A/B
- Preview pane: table showing proposed assignments + visual diff
- **Apply** button → throttled `SetRaidSubgroup` calls, gated on `UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")`
- French locale (frFR) at parity with English

### v0.2.0 — auto DPS source
- **Details piggyback**: read `Details:GetCurrentCombat():GetActorList(1)`
  for the last encounter's damage per actor. ~100 LOC.
- Skada fallback: try `Skada.current` if Details absent.
- Auto-refresh weights when combat ends (`PLAYER_REGEN_ENABLED` + Details event).

### v0.3.0 — presets
- Save named splits ("Spirit Kings", "Lei Shen", etc.)
- Load preset → directly populate the split target without recomputing

### v1.0.0 — polish + release
- Test mode (simulated 20-man roster for UI preview)
- Profile import/export (same b64 codec as BossWatch — copy from `BossWatch.lua` lines 240-323)
- CurseForge + Wago publishing via BigWigsMods/packager

## Mandatory conventions (copied from BossWatch)

### Namespace
Every Lua file starts with:
```lua
local addonName, SplitW = ...
```
And `SplitWatch.lua` does `_G[addonName] = SplitW` so `/dump SplitWatch` works.

### Slash command
`/splitw` canonical. **Never** use `/sw` (collides with at least 3 other addons).
Subcommands: `/splitw`, `/splitw apply`, `/splitw preview`, `/splitw reset`, `/splitw test`.

### File layout (mirror BossWatch)
```
SplitWatch.toc                  # retail (Interface: 120000, 120001, 120005, 120007)
SplitWatch-Mists.toc            # MoP Classic (Interface: 50500)
                                # Multi-toc: BigWigsMods/packager handles both in one zip.

SplitWatch.lua                  # namespace, defaults, slash, DB, namespace
                                # /splitw command, LSM registration if needed
Roster.lua                      # GetRaidRosterInfo wrapper, role detection
Splitter.lua                    # the balancing algorithm (pure function)
Apply.lua                       # SetRaidSubgroup queue + permission gate
DPSSource.lua                   # Details/Skada/Manual switcher (interface)
                                # MVP only implements Manual; rest is stubs
Options/Panel.lua               # standalone tabbed panel (PortraitFrameTemplate)
                                # COPY the build()/makeSection/makeCheck/
                                # makeDropdown/makeSlider helpers from BossWatch
                                # Options/Panel.lua. Don't reinvent.
Locales/enUS.lua                # __index fallback returns key
Locales/frFR.lua                # ~50 keys for v0.1.0
Locales/deDE.lua                # placeholder
Locales/esES.lua                # placeholder
Locales/itIT.lua                # placeholder
Locales/ptBR.lua                # placeholder
Libs/LibStub                    # bundled OR external via .pkgmeta
Libs/CallbackHandler-1.0
Libs/LibSharedMedia-3.0         # for shared texture pickers (consistent w/ BW)
Libs/LibDataBroker-1.1          # minimap icon
Libs/LibDBIcon-1.0
Media/minimap.png               # custom minimap icon (128x128 — ask user
                                # for logo, generate the icon variant)
Media/logo.png                  # CurseForge + portrait
```

### UI must match BossWatch family

- `PortraitFrameTemplate` for the main panel
- Custom **left-edge side tabs** (BossWatch / TankWatch / SplitWatch), only
  visible when sister addons are loaded. Pattern in BossWatch Panel.lua
  around line 2117. **Copy that block verbatim**, add SplitWatch as a
  visible self-tab, and expose `SplitW:ShowOptionsAt(point, relPoint, x, y)`
  for cross-addon handoff (see BossWatch lines 2247-2270).
- **Search bar** top-right, **collapsible sections** (BossWatch lines ~610-790),
  **resize grip** bottom-right, **bottom tabs** with multi-row wrap
  (BossWatch lines 2054-2095).
- Gold accent (`#FFD100` / `1, 0.82, 0`), dark glass backdrop on side tabs.
- Section column convention: column 1 starts at x=14, column 2 at x=260.
- Auto-flow: right-column controls (sliders, checks, dropdowns, color pickers)
  slide along the right edge when the panel is widened (BossWatch
  `_captureAndReparent` logic).

### Always tooltip (memory rule from BossWatch)
Every interactive control gets `addTooltip(widget, L["…"])` with a translated
description. No exceptions.

### NEW badge convention
Mark genuinely new controls with a "NEW" badge that disappears on first
hover/click. Tracked in `SplitWatchDB.seenFeatures` (account-wide, NOT
per-profile). Same widget helper as BossWatch.

### Localization
- `SplitW.L = setmetatable({}, { __index = function(_, k) return k end })`
  → enUS needs no entries.
- `Locales/frFR.lua` self-skips with `if GetLocale() ~= "frFR" then return end`.
- All literals in Panel.lua and slash-help wrapped in `L["…"]`.

### Profiles
Copy the profile system from BossWatch (`BossW:GetActiveProfileName`,
`BossW:CreateProfile`, `BossW:ResetProfile`, `BossW:DeleteProfile`,
`BossW:ImportProfile/ExportProfile`). The b64 + serialize codec at
`BossWatch.lua` lines 240-323 is generic — copy and rename prefix
`BW1:` to `SW1:`.

### Changelog (in About tab + CHANGELOG.md sync)
- The version history lives as a **SECTION at the bottom of the About tab**,
  NOT as a separate tab. Pattern: `_BuildChangelogSection(parent)` called from
  the end of `buildAboutPage` (see BossWatch Options/Panel.lua).
- Maintain a single `CHANGELOG.md` at repo root (Keep a Changelog format).
  No per-version `.changelog_v*.md` files — they were retired in v0.7.5.
- Release pattern: rename `[Unreleased]` → `[X.Y.Z] - date`, add new
  `[Unreleased]` on top. Then `scripts/extract_changelog.sh X.Y.Z` extracts
  the block for `git tag -F` and Discord webhook.

### Naming policy in changelog entries
- ✅ Sister `*Watch` addons (BossWatch, TankWatch, SplitWatch) MAY be named.
- ❌ Third-party addons (BigWigs, Plater, Details, Skada, etc.) must NOT
  be named in user-facing entries. Describe the underlying change instead.

### Classic build banner
If `WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE`,
display a yellow banner at the top of the panel: "⚠ Version Classic — UI not
fully tested in raids yet, please report bugs." (FR equivalent in frFR.lua).
Copy pattern from BossWatch Panel.lua around line 1791.

## API contract

### Reading the roster
```lua
function SplitW.Roster:Scan()
    local out = { tanks = {}, healers = {}, dps = {}, raid = GetNumGroupMembers() }
    if out.raid == 0 then return out end
    for i = 1, out.raid do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead,
              role, isML, combatRole = GetRaidRosterInfo(i)
        if name then
            local r = combatRole or UnitGroupRolesAssigned("raid"..i) or "DAMAGER"
            local entry = { name = name, raidIndex = i, subgroup = subgroup,
                            class = fileName, role = r,
                            weight = SplitW:GetWeight(name) or 50 }
            if r == "TANK" then table.insert(out.tanks, entry)
            elseif r == "HEALER" then table.insert(out.healers, entry)
            else table.insert(out.dps, entry) end
        end
    end
    return out
end
```

### The split algorithm (pure)
```lua
-- Returns { teamA = { entry, … }, teamB = { entry, … } }
function SplitW.Splitter:Compute(roster)
    local A, B = {}, {}
    -- Tanks: 1 to A, rest to B (if 2+ tanks). If exactly 1 → A.
    for i, t in ipairs(roster.tanks) do
        if i % 2 == 1 then table.insert(A, t) else table.insert(B, t) end
    end
    -- Healers: alternate
    for i, h in ipairs(roster.healers) do
        if i % 2 == 1 then table.insert(A, h) else table.insert(B, h) end
    end
    -- DPS: sort by weight desc, snake distribution
    table.sort(roster.dps, function(x, y) return x.weight > y.weight end)
    local sumA, sumB = 0, 0
    for _, d in ipairs(roster.dps) do
        if sumA <= sumB then
            table.insert(A, d); sumA = sumA + d.weight
        else
            table.insert(B, d); sumB = sumB + d.weight
        end
    end
    return { teamA = A, teamB = B, scoreA = sumA, scoreB = sumB }
end
```

### Applying the split
- 20-man raid: Team A = subgroups 1+2, Team B = subgroups 3+4.
  Each team has up to 10 slots split across 2 subgroups of 5 max.
- Iterate the proposed assignment, call `SetRaidSubgroup(raidIndex, targetSubgroup)`
  with throttle. Blizzard queues these natively but rate-limits ~500ms each.
- **Permission gate**: only enable Apply button if
  `UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")`.
- **25-man fallback**: 5 groups of 5 → can't split cleanly into 2 equal
  halves. Plan: groups 1+2+half-of-3 = A (12), rest = B (13). Show a warning
  in UI.

### Permission detection
```lua
function SplitW.Apply:CanApply()
    return IsInRaid()
       and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
end
```

## WoW 12.0 / Midnight secret-value rules

**Good news**: SplitWatch operates on FRIENDLY raid members (your own raid).
Their data is NOT secret-tagged. So no pcall hell like BossWatch.

**Exception**: if you ever expand to enemy-targeting features, see
BossWatch's secret-value playbook in its CLAUDE.md.

## Combat lockdown

**Correction (verified on warcraft.wiki.gg 2026-05-11)**: `SetRaidSubgroup`
AND `SwapRaidSubgroup` ARE **combat-locked since patch 4.0.1**. The Apply
queue MUST check `InCombatLockdown()` and defer until `PLAYER_REGEN_ENABLED`.
Roster reading (`GetRaidRosterInfo`, `UnitGroupRolesAssigned`) is NOT locked.

`SwapRaidSubgroup(idx1, idx2)` is also available on both retail 12.x and
Mists 5.5 — useful when the target subgroup is full (5/5), swap two players
instead of two Set calls.

The "~500ms throttle" mentioned in this doc is community folklore, not
officially documented. Safe practice: `C_Timer.After(0.1, ...)` between
calls and retry on failure.

## Release workflow (when ready)

Copy verbatim from BossWatch:
- `.pkgmeta` with multi-toc + externals
- `.github/workflows/release.yml` with BigWigsMods/packager@v2
- `CF_API_KEY` secret on GitHub repo
- Discord webhook for release announcements (set up after first push to
  GitHub — ask user for the `#sw-changelog` channel ID and webhook URL)

## Testing

Deploy command (mirror BossWatch's wow-addon-deploy skill):
```
rm -rf "G:/World of Warcraft/_retail_/Interface/AddOns/SplitWatch"
mkdir -p "G:/World of Warcraft/_retail_/Interface/AddOns/SplitWatch"
cp -r u:/WoW_SplitWatch/SplitWatch.toc u:/WoW_SplitWatch/SplitWatch-Mists.toc \
      u:/WoW_SplitWatch/SplitWatch.lua \
      u:/WoW_SplitWatch/Roster.lua u:/WoW_SplitWatch/Splitter.lua \
      u:/WoW_SplitWatch/Apply.lua u:/WoW_SplitWatch/DPSSource.lua \
      u:/WoW_SplitWatch/Options u:/WoW_SplitWatch/Locales \
      u:/WoW_SplitWatch/Libs u:/WoW_SplitWatch/Media \
      "G:/World of Warcraft/_retail_/Interface/AddOns/SplitWatch/"
```
Same for `_classic_`.

## Memory rules (apply to this project)

The user's auto-memory file at
`C:\Users\timik\.claude\projects\u--WoW-BossWatch\memory\MEMORY.md`
contains FEEDBACK rules already established. The most important ones
to respect from day 1 in this new repo:

1. **No Claude attribution in commits/PRs/artifacts.** Never add
   "Co-Authored-By: Claude" or "Generated with Claude".
2. **Bump version only on GitHub push** — never bump for local-only changes.
3. **Never merge to main unattended.** Stay on `beta`; only merge/tag/release
   with explicit user instruction in the current turn.
4. **Update in-addon Changelog tab before release** — every version bump
   adds a top-of-list entry to `buildChangelogPage` with FR translation,
   BEFORE merging/tagging.
5. **Always tooltip** every interactive control.
6. **NEW badge** on new panel controls, disappears on first hover/click.
7. **No secret-value workarounds.** Drop features that depend on secret-tagged
   hostile data; don't build hacky fallbacks. (For SplitWatch this matters
   less since we deal with friendly raid only.)
8. **Collaboration style**: short FR exchanges, fast iterate-and-ship,
   no extra confirmations once the user has said go.

## Initial setup checklist (first session)

1. Initialize `git init`, create `beta` branch (dev branch by convention)
2. Create `SplitWatch.toc` (retail) + `SplitWatch-Mists.toc` (MoP Classic)
3. Copy `Libs/` from BossWatch (`cp -r u:/WoW_BossWatch/Libs u:/WoW_SplitWatch/`)
4. Stub `SplitWatch.lua` with namespace + Defaults table + slash command
5. Stub `Roster.lua` with the `Scan()` function from this doc
6. Stub `Splitter.lua` with the `Compute()` function from this doc
7. Stub `Apply.lua` with `CanApply()` + throttled queue
8. Copy `Options/Panel.lua` skeleton from BossWatch, rip out the BW-specific
   page builders, keep the harness (`build`, `makeSection`, `makeCheck`,
   `makeDropdown`, `makeSlider`, side tabs, search bar, resize grip).
9. Build 4 pages: **Setup**, **Manual Weights**, **Preview**, **About**.
10. Add Classic banner + frFR locale entries.
11. Deploy to `_retail_` AddOns folder, `/reload`, test in a fake raid
    (`/script JoinRaid()` won't work; use a test mode that simulates a
    20-man roster).
12. Once UI works end-to-end with manual mode, commit on beta. **Don't push
    or merge** until the user explicitly says.

## Open questions for the user (ask before coding)

1. **Repo creation on GitHub**: is the GitHub repo `Timikana/SplitWatch`
   already created, or should we wait until the first beta is ready?
2. **CurseForge project**: same — register now or after MVP works?
3. **Logo**: does the user have a logo PNG (square, 128x128 ideal) or
   should we generate a placeholder?
4. **Default weight mode**: in v0.1.0 with Manual mode only, what should
   the default weight be for newly-seen players? 50 (middle)? Sort
   alphabetically with same weight = even snake distribution?
5. **Test mode**: do we simulate a 20-man, 25-man, or both? Suggestion:
   default to 20 since the algorithm splits cleanly there; offer 25 as
   an option to preview the "uneven warning" UX.
