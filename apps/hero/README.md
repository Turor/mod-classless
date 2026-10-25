# Hero class (class ID 10)

Choosing **Hero** at character creation marks a character as a Gauntlet character
(design: `gauntlet-design.md` §3). Gauntlet behaviour itself (config window, submit, apply) lives in the
private `Turor/mod-turoran-roguelike` repo. This directory only adds the class, which both realms
(Standard and roguelike) share because `patch-n.mpq` is shared.

## Approach: reuse the unused class slot 10

3.3.5a reserves class ID 10 (`CLASS_UNK`): `MAX_CLASSES` is already 12, every per-class array in the
core already has a slot for it, and the stock gt* combat tables already have 1100 rows (11 classes × 100).
So adding the class is data plus a handful of placeholder fixes, no array resizing or client binary edits.

| Piece | Where | Change |
|---|---|---|
| ChrClasses row 10 `HERO` | client `ChrClasses.dbc` (V023 + `gen_hero.py --client-dbc`); server `chrclasses_dbc` (world DB override) | Copy of the Paladin row, names "Hero", token `HERO`, no spell family, no cinematic |
| Race/class combos | client `CharBaseInfo.dbc` | All 10 playable races |
| Starting outfit | client `CharStartOutfit.dbc` (display) + server `charstartoutfit_dbc` (items) | Race's Warrior armour (Blood Elf: Paladin), Battleworn Hammer, Hearthstone |
| Creation rows | world `playercreateinfo`, `playercreateinfo_action` | Race's Warrior start position (Blood Elf: Paladin); Auto Attack + racial on the bar |
| Skills | world `playercreateinfo_skills` | Nothing to do: classless rows already use classMask 0/2047 (Hero bit included) |
| Base stats | world `player_class_stats` levels 1–85 | See below |
| Combat/regen ratios | world `gt*_dbc` overrides + client gt*.dbc | Class-10 rows = mean of Paladin and Druid (stock rows are placeholders: 20% base melee crit, 0 spell crit, 0 rating scalars) |
| Core | `Turor/azerothcore-wotlk-classless` `feature/gauntlet-hero` | `CLASS_HERO = 10`; slot-10 dodge/parry/miss caps were 0 (NaN miss chance); enum info; DBW trinket lists |
| Playerbots | `Turor/mod-playerbots` `feature/gauntlet-hero` | Refuse to log a Hero in as a bot. Random bots never roll Hero because `CLASSMASK_ALL_PLAYABLE` deliberately excludes it |
| Create screen | `UIMods/patch-n/Interface/GlueXML/CharacterCreate.{lua,xml}` | 11th class button, Hero icon/strings |
| In-game UI | `UIMods/patch-n/Interface/AddOns/TuroranHeroClass` | `RAID_CLASS_COLORS`/`CLASS_ICON_TCOORDS` entries for `HERO` |

Rejected alternatives:

- **Class ID 12+**: `MAX_CLASSES` is a compile-time array size used across the core, Playerbots and
  the client (class masks are 32-bit, gt tables are sized for 11 classes). Far more invasive than slot 10.
- **Reuse an existing class + a flag** (e.g. "Warrior with a gauntlet flag"): contradicts the design
  (Hero *is* the flag), and needs a separate create-screen toggle the 3.3.5 client does not have.
- **Server-only custom class without client DBCs**: the client refuses to create or display a class it has
  no ChrClasses/CharBaseInfo row for.

## Numbers

`gen_hero.py` derives everything from a snapshot of Standard prod (`inputs/`). See `hero_numbers.md`.

- Primary stats per level: per-stat mean of the 9 non-DK classes (balanced profile), scaled so the five-stat
  total equals the Paladin/Druid average total at that level (hybrid budget). Level 80: 101/104/116/123/135 = 579
  (Paladin 587, Druid 571, Warrior 541, Mage 493, 9-class mean 548).
- BaseHP/BaseMana: classless already gives every class the Warrior HP and Mage mana curves
  (`data/sql/db-world/update_player_class_stats.sql`); Hero follows that.
- gt* rows and the core's slot-10 dodge/parry constants: mean of Paladin and Druid.

## Power type: `POWER_MANA` (0)

Following gauntlet-design.md section 12, Hero's ChrClasses `DisplayPower` is **0 (mana)** in the server
override row, the client DBC and V023. mod-classless `OnPlayerHasActivePowerType()` returns true for every power,
so rage, energy, focus and runic power stay live for Hero, and the Classless resource bar draws them.

- Rejected: 127 (`POWER_ALL`). It only means "any power" on auras; as a class power it is past `MAX_POWERS`.
- Rejected: copying the other classless classes' 6 (runic power). That keeps Hero's primary bar the same as every
  other classless character but makes mana a secondary pool, even though most cross-class spells cost mana.
  If Matthew prefers uniformity, set `HERO_DISPLAY_POWER = 6` in `gen_hero.py` and regenerate.

Note: the shipped (Dec 2025) client `ChrClasses.dbc` and the server DBC have `DisplayPower = 6` for every class,
while `dmls/required/ChrClasses.sql` has 127. Pre-existing, not caused by Hero; worth reconciling before the next
full DBC rebuild.

## Build / deploy

```bash
python3 apps/hero/gen_hero.py --client-dbc /tmp/hero-client-dbc \
    --base-chrclasses-dbc <ChrClasses.dbc from the live patch-n.mpq>
cp /tmp/hero-client-dbc/*.dbc UIMods/patch-n/DBFilesClient/   # then pack + publish per classless-wow-patch
```

Server: `data/sql/db-world/hero_class.sql` is picked up by the DB updater on the next worldserver start
(`Updates.EnableDatabases = 7`), together with a core built from `feature/gauntlet-hero`.
