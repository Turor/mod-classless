# Classless UI via AIO (pure Lua)

Living plan for the AIO talent/spellbook UI. Session kickoff: Grok `plan.md`. **Update the Iteration log after every pass.**

Replace the unfinished XML addon (`ClasslessUIAddons/TalentsAndSpellbook.xml`) with a new AIO-served Lua UI and a new learn system. Do **not** drive this off `GetTalentInfo` / the player's class talent tabs / NPC trainers.

## Iteration log

| Date | Iter | Landed | Still stubbed |
|---|---|---|---|
| 2026-09-19 | 0–1 | Living plan; header chrome; empty panes | Catalog + rendering |
| 2026-09-19 | 2–5 | `CatalogData.lua` from Talent.sql + SkillLineAbility (2604 spells, 1014 talent nodes); spellbook families with rank arrows; talent grid; LearnSpell / LearnTalent / UnlearnTalent; RequestState sends real `HasSpell` | Prereq branch textures, glyph pane, pet spells, pickup edge cases, strip XML from MPQ, N-key hook |
| 2026-09-19 | debug | AIO errors go to chat, Blizzard script-error UI (`scriptErrors`), `AIO_ERRORS` in WTF SavedVariables, and worldserver `[AIO client][Name]`. Obfuscation off. Ignore `TalentsAndSpellbook.xml` FontString warning. | Restore `AIO_CODE_OBFUSCATE` before a real patch |
| 2026-09-19 | catalog | Spellbook is **class trainer_spell** (Type=0), not raw SkillLineAbility. SLA only assigns a trained spell to a spec. `class_trainer_spells.txt` is a dump from acore_world. | Glyph pane; talent-node denylist if a talent should be hidden |
| 2026-09-19 | glyph | Glyph tab is a Lua port of `Blizzard_GlyphUI.xml`: 384×512 `UI-GlyphFrame`, 3 major + 3 minor sockets, `GetGlyphSocketInfo` / `PlaceGlyphInSocket`. | Talent prereq branch textures, strip XML from MPQ, N-key hook |
| 2026-09-19 | unlearn | Maxed talent ranks can be unlearned. `LearnSpell(previous)` was re-teaching the dropped rank via next-in-chain; UnlearnTalent peels the highest known rank and recasts the previous. Right-click unlearns; left-click on a maxed node pickups. | Talent prereq branch textures, strip XML from MPQ, N-key hook |
| 2026-09-19 | unlearn-cpp | `Classless_DropTalentRank` fully marks dropped ranks `PLAYERSPELL_REMOVED` (Lua `RemoveSpell` cannot). `Player:DropTalentRank` peels 5→4→3→… without re-teaching the chain. | Talent prereq branch textures, strip XML from MPQ, N-key hook |
| 2026-09-19 | talent-sync | Classless UI learned ranks include stock `HasTalent` (m_talents), not only `HasSpell`. Client refreshes on `PLAYER_TALENT_UPDATE` / `CHARACTER_POINTS_CHANGED`. DropTalentRank also `_removeTalent` / `addTalent` so both maps stay aligned. | Talent prereq branch textures, strip XML from MPQ, N-key hook |
| 2026-09-19 | talent-learn-path | Classless left-click uses `Player:LearnTalent` (addTalent), same as the default panel. Known rank is the highest HasTalent/HasSpell on Talent.dbc RankID, and 1..rank are marked learned so a stock max rank shows as max. | Talent prereq branch textures, strip XML from MPQ, N-key hook |
| 2026-09-19 | talent-plus | Learnable talent ranks show the same green plus as spells. Tree unlock is 5× row points spent anywhere in that tree; arrow prereqs are not required. | Talent prereq branch textures, strip XML from MPQ, N-key hook |
| 2026-09-19 | talent-branches | Stock UI-TalentBranches / UI-TalentArrows drawn from catalog `p`/`pr`. Chains also gate LearnTalent (Lua + C++ DependsOn). Row still needs 5× points in the tree. | Strip XML from MPQ, N-key hook |
| 2026-09-19 | unlearn-orphan | Unlearn is blocked if it would drop global spent points below 5× a remaining talent's row, or drop a prereq below a dependent's need. Fail sound `igQuestFailed` plus error text. Row unlock counts points in any tree. | Strip XML from MPQ, N-key hook |
| 2026-09-20 | row-histogram | Learn/unlearn recompute an 11-slot row histogram (all trees). Row k needs `sum(n[0]..n[k-1]) >= 5k`. Unlearn peels one rank then rechecks every occupied row. | Strip XML from MPQ, N-key hook |
| 2026-09-19 | spell-gold | Learning a spell rank charges `classless_spell_train_cost.money_cost` (seeded from class `trainer_spell.MoneyCost`). Optional `currency_item_id`/`currency_count` is an item token charged in the same take. Starting spells with no row stay free. Tooltip shows gold. | Strip XML from MPQ, N-key hook |
| 2026-09-19 | spell-cost-cell | Unlearned spell cells show gold (and item currency) under name then rank/passive. Red if the player cannot pay. Known ranks hide the line. | Strip XML from MPQ, N-key hook |
| 2026-09-19 | resource-bar | Live `Interface/AddOns/ClasslessUIAddons/ResourceBar.lua` was the old energy/rage/mana stack (no runes). Restored the patch-n rune grid + runic bar; MainFrame height is 4 bars. | Strip XML from MPQ, N-key hook |
| 2026-09-19 | aio-resource | Resource bar is AIO `ClasslessResourceBar.lua`. ClasslessUIAddons lua/xml/toc stripped from patch-n; only parchment + bar TGAs remain. Native Linux `mpqcli` packs the MPQ. | N-key hook |

## Why a new system

The current XML UI is a shell (`/acui`): class icons, hardcoded Blood/Frost/Unholy tabs, empty spellbook/talent panes. It cannot show other classes' trees because Blizzard talent APIs only return the character's real class.

`player:LearnTalent` is also blocked for other-class tabs: `ClasslessPlayerScripts::OnPlayerLearnTalentUseAlternativeLogic` returns without learning when `getClassMask() & talentTab.ClassMask == 0`. Trainers only teach a handful of special spells.

So: a catalog of (class → spec → spells + talent grid), AIO handlers that `LearnSpell` after validating against that catalog, and a client UI built entirely with `CreateFrame`.

## Rank rule (one active rank, pickup the selected rank)

Keep AzerothCore's existing rank chain for **scripts and auras**. Learning rank N still deactivates lower ranks (`SMSG_SUPERCEDED_SPELL`). **No C++ change to `Player::addSpell`.** `HasSpell` remains true for known lower ranks; only one rank is `Active`.

Rank arrows **select** which rank is in focus. Pickup always uses **that** spell ID, not the highest known rank. WotLK action buttons store a specific spell ID; AzerothCore does too. If the player has learned the selected rank, dragging/clicking puts **that** rank on the cursor even when a higher rank is the active one.

- Tooltip always shows the selected rank (`GameTooltip:SetHyperlink("spell:"..id)`).
- If that rank is unlearned, left-click asks the server to learn **that** spell ID.
- If that rank is known (`IsSpellKnown` / `HasSpell`), left-click / drag picks up **that spell ID** for the action bar.
- Do not rewrite a lower-rank pickup to the highest rank.

Learn ranks one at a time (rank 1, then 2, …). Server rejects a rank if the previous rank is not known.

## Layout on disk

```
modules/mod-classless/apps/classless-ui/
  PLAN.md                     -- this file
  Catalog.lua                 -- shared class/spec/spell/talent tables
  ClasslessUIClient.lua       -- AIO.AddAddon client UI
  ClasslessUIServer.lua       -- AIO.IsMainState handlers
  ClasslessResourceBar.lua    -- AIO.AddAddon energy/rage/mana/runic HUD
```

Deploy:

```
scp -o BatchMode=yes apps/classless-ui/*.lua \
  wow-dev:/usr/games/wow/server/lua_scripts/ClasslessUI/
# ALE.AutoReload watches lua_scripts; wait ~1s. Client: /aio reset (or relog).
# In-game GM: .reload ale  if the watcher misses. Do not restart worldserver for Lua.
```

Keep `lua_scripts/AIO_Server` in place. After client-Lua changes, players need `/aio reset` then relog.

AIO channels: client `ClasslessUIClient`, server `ClasslessUIServer`.

**ClasslessUIAddons is not a loadable addon.** `/classless` and the resource bar are AIO. `patch-n.mpq` only keeps `Interface/AddOns/ClasslessUIAddons/textures/{SpellbookParchment,normTex,Minimalist}.tga`. `TalentsAndSpellbook.*` and `ClasslessTalentFrameBase.lua` are gone.

## Frame layout

Movable, closable, ~1000×700. Slash `/classless`. Default class: Death Knight.

**Class row.** Ten DBC class ids, XML order (DK → Warrior). Icons from the old XML.

**Spec + extra tabs.**

| Buttons | Role |
|---|---|
| 1–3 | That class's three talent trees (rewrite on class click) |
| 4 | `General` — class spells not tied to a tree |
| 5 | `Glyph` — always present |
| 6 | `Pet` — always present |

Selecting a spec refreshes the two body panes. Glyph swaps to glyph UI. Pet swaps to pet spellbook + pet talent tree.

## Spellbook pane

One button per spell family. Rank arrows select a rank. Unlearned = desaturated. Known selected rank: pickup **that** spell ID. Unlearned selected rank: `LearnSpell`.

## Talent pane

Catalog grid, not `GetTalentInfo`. Click learns next rank. Right-click unlearns one rank and refunds a point. Draw prereq branch/arrow textures (port `ClasslessTalentFrameBase.lua` against catalog coords).

## Glyph pane

Lua recreation of stock `Blizzard_GlyphUI.xml` (not a glyph-item list). Native 384×512 frame centered in the body: `UI-GlyphFrame` 352×441, `GLYPHS` title, six sockets at the XML offsets (ids 1/2 major center, 3/5 major-minor top, 4/6 bottom). Socketing still uses the glyph item + `PlaceGlyphInSocket` / shift-right-click `RemoveGlyphFromSocket`.

## Pet pane

Left: read-only list of spells the **current pet already has**. The UI does not teach pet abilities. Right: centralized pet talent tree (`V018__CentralizePetTalentTrees`).

## Catalog and Spell.dbc

We **do** use Spell.dbc. The catalog exists because client Lua cannot enumerate SkillLineAbility / Talent.dbc for every class, and ALE `LookupEntry` currently exposes only `Spell` and `GemProperties`.

| Fact | Source |
|---|---|
| Name, icon, rank text, required level, passive | Spell.dbc at runtime (`GetSpellInfo` / `LookupEntry("Spell", id)`) |
| Rank chain | Spell.dbc on the server (next/first rank). Never trust client-sent chains |
| First-rank spells per spec | Catalog, generated from SkillLineAbility + SkillLine sqlite |
| Talent grid | Catalog from Talent + TalentTab sqlite |
| Glyphs / pet tree | Catalog from those DBCs |

Catalog stores first-rank spell IDs and talent node layout. Server expands spell ranks from Spell.dbc.

## AIO protocol

Server: `RequestState`, `LearnSpell(spellId)`, `LearnTalent(talentId, rank)`, `UnlearnTalent(talentId, rank)`. Coerce `tonumber`, catalog lookup, ignore anything else. Do **not** call `player:LearnTalent` (class-mask hook).

Client: `ShowUI`, `ApplyState(state)`.

## Pickup

Selected rank's spell ID, never a silent upgrade to the highest rank. `PickupSpell(selectedRankId)` first; spellbook-slot fallback if needed.

## Lua vs C++

Server Lua is the default (`LearnSpell`, `RemoveSpell`, `HasSpell`, `SetFreeTalentPoints`, `GetSpellInfo`). C++ already has talent-point formula and `OnPlayerIsClass`. Add a `ClasslessPlayerScripts` hook only if those Lua calls reject other-class data.

## Iteration sequence

0. Scaffold (this pass, with header).
1. Header (this pass).
2. Spellbook chrome.
3. Rank widget.
4. Mage catalog from DBC.
5. LearnSpell.
6. Pickup selected rank.
7. Talent pane + prereq branches.
8. Points / UnlearnTalent.
9. Glyph + Pet panes.
10. Rest of classes.
11. Remove XML wiremock from `patch-n.mpq`.
12. Hook N / `ToggleTalentFrame` only after every path works.

## Verification (current pass)

- `/classless` and `.classless` open the frame; drag and close work.
- Class click retargets spec 1–3 + General labels/icons.
- Glyph tab shows the stock 6-socket UI; Pet tab is selectable.
- Teleporter / transmog AIO still load.
