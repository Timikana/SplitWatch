<div align="center">
  <img src="logo.png" alt="SplitWatch logo" width="220">

  # SplitWatch

  **Auto-split a 10-40 man raid into 2 balanced teams for split-mechanic encounters.**

  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
  ![WoW Version](https://img.shields.io/badge/WoW-12.0%20Midnight-blue)
  ![MoP Classic](https://img.shields.io/badge/Classic-MoP%205.5-purple)
</div>

---

## What it does

SplitWatch reads your raid roster, runs a snake-distribution algorithm balanced across **tanks, healers (by HPS) and DPS (by damage)**, and reassigns subgroups in one click via `SetRaidSubgroup`. Made for split-mechanic boss fights — Spirit Kings (MoP), and any other encounter that asks the raid to fight as two halves.

**0 required addons** — SplitWatch works standalone. Details!, Recount, and Skada are optional integrations: when loaded, the algorithm reads live DPS+HPS from them instead of the manual sliders.

**Sister addon to [BossWatch](https://github.com/Timikana/BossWatch) and TankWatch** — shares side-tab navigation, gold-accent UI, and the family colour palette. Click between the three from the left edge of any panel.

## Features

- **Roster scanner** — reads your raid via `GetRaidRosterInfo` + `UnitGroupRolesAssigned`, infers role (TANK/HEALER/DAMAGER) and class
- **Snake-distribution algorithm** — tanks alternate, healers snake-distribute by HPS, DPS snake-distribute by damage; weakest player fills the gap on the larger team for uneven raids
- **10-to-40 man support** — subgroups assigned dynamically (1 vs 2 / 1+2 vs 3+4 / 1+2+3 vs 4+5+6 / 1+2+3+4 vs 5+6+7+8)
- **Damage meter integration** — Details!, Recount, Skada or Manual sliders; unavailable sources are greyed out in the dropdown
- **Live source preview** — verify your meter is hooked up by seeing the live DPS/HPS values for every roster member (or for all tracked actors when solo)
- **Before / after preview** — see each team's tank count, healer count, DPS count, total DPS score and total HPS score before applying
- **Permission-gated Apply** — only leader/assistant can mass-move; combat-locked calls deferred until `PLAYER_REGEN_ENABLED`
- **Tabbed options panel** with collapsible sections, per-section reset button, page-level scrolling
- Built-in **test mode** (simulated 20-man roster) to preview the UI without a real raid
- **Multi-toc** — single zip installs on Retail 12.x AND MoP Classic 5.5

## Installation

### Manual
1. Download the latest release from the [Releases page](https://github.com/Timikana/SplitWatch/releases)
2. Extract the `SplitWatch` folder into `World of Warcraft/_retail_/Interface/AddOns/` (or `_classic_/Interface/AddOns/` for MoP)
3. Restart WoW or `/reload`

## Slash commands

| Command | Description |
|---|---|
| `/splitw` | Open the options panel |
| `/splitw preview` | Compute the split and show the preview |
| `/splitw apply` | Apply the current split via `SetRaidSubgroup` (leader/assist only) |
| `/splitw test` | Toggle a simulated 20-man roster for UI testing |
| `/splitw reset` | Wipe all settings and reload the UI |

`/splitwatch` is available as an alias for `/splitw`.

## Configuration

Open with `/splitw`. Tabs:

- **Setup** — minimap icon, confirm-before-apply, summary-on-apply, auto-refresh, DPS source picker, live source preview, permission status
- **Players** — per-player weight sliders (1-100), role icon + class colour, reset all weights, refresh roster, toggle test mode
- **Preview** — Before/After stats, Team A / Team B columns with names, warnings (uneven teams, missing tank, oversize team), one-click Apply
- **About** — addon info, slash commands list, panel opacity, reset window position, full changelog

## How the split works

1. **Tanks** are alternated 1→A, 2→B, 3→A, … so each team has at least one
2. **Healers** are sorted by HPS descending, then snake-distributed (each healer goes to whichever team has the lower total healing score so far)
3. **DPS** are sorted by damage descending, then snake-distributed the same way
4. **Uneven raids** (e.g. 11-man): the weakest player ends up on the larger team — score stays balanced even when player counts differ

Apply pushes everyone to their target subgroup with a 150ms throttle. If you're in combat, the queue waits for `PLAYER_REGEN_ENABLED`.

## Localization

| Locale | Status |
|---|---|
| English (`enUS`) | ✓ Complete |
| French (`frFR`) | ✓ Complete |
| German / Spanish / Italian / Portuguese | ⌛ Placeholder |

Want to contribute another locale? Copy `Locales/frFR.lua`, change the `GetLocale()` check, translate the values, and open a PR.

## Optional integrations

| Addon | What it provides |
|---|---|
| [Details!](https://www.curseforge.com/wow/addons/details) | Live DPS + HPS via `combat:GetActorList(1/2)` |
| [Recount](https://www.curseforge.com/wow/addons/recount) | Live DPS + HPS via `Recount.db2.combats[cur].Fight` |
| [Skada](https://www.curseforge.com/wow/addons/skada) | Live DPS + HPS via `Skada.current.players` |

Without any of those, the algorithm uses the per-player weight sliders on the Players tab (defaults to 50 / 100).

## Bundled libraries

- [LibStub](https://www.wowace.com/projects/libstub)
- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler)
- [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0)
- [LibDataBroker-1.1](https://github.com/tekkub/libdatabroker-1-1)
- [LibDBIcon-1.0](https://www.wowace.com/projects/libdbicon-1-0)

## Issues & feedback

Found a bug or want to suggest a feature? Open an issue on the [issue tracker](https://github.com/Timikana/SplitWatch/issues).

## License

[MIT](LICENSE) — feel free to fork, modify, and contribute back.

---

<div align="center">
  Made with ❤ for the WoW Midnight + Mists Classic community.
</div>
