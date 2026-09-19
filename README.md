# Classless Wow Module

[English](README.md) | [Español](.github/README_ES.md)

## Introduction
The goal of this module is to provide a classless version of the Wotlk version of AzerothCore. The gameplay experience will
be curated for small groups of players, and there will be no PvP balance. The purpose of this module is to develop overpowered
builds.

Progression is primarily handled through talent points which are computed based off of the level of the player + the number of
unlocked achievements. There is currently no cap- although a configuration setting for a talent cap is planned.

## Creating the dbcs

### Requirements
- [Rust](https://www.rust-lang.org/tools/install)
- [wow_dbc](https://crates.io/crates/wow_dbc)
- [Ladik's MPQ Editor](http://www.zezula.net/download/mpqeditor_en.zip)
- [mpqcli](https://github.com/thegraydot/mpqcli)

### Automatic Installation

Automated scripts are provided to handle the entire installation process, including DBC conversion, SQL patching, DBC generation, and MPQ creation.

**On Windows (PowerShell):**
```powershell
./install.ps1 -DbcInputPath "C:\Path\To\Your\Extracted\DBFilesClient"
```

**On Linux/Unix (Bash):**
```bash
./install.sh /path/to/extracted/DBFilesClient
```

### Creating the SQLite Database

To create a SQLite database from your extracted `.dbc` files, use the `wow_dbc_converter` tool:

1. Open a terminal in `modules/mod-classless/apps/patchgenerator/wow_dbc`.
2. Run the following command:

```powershell
cargo run -p wow_dbc_converter -- wrath -i "C:\Path\To\Your\Extracted\DBFilesClient" -o "wrath_dbcs.sqlite"
```

*   `wrath`: Specifies the game version (use `vanilla` or `burning-crusade` for other versions).
*   `-i`: The input path containing your `.dbc` files (usually the `DBFilesClient` folder).
*   `-o`: The output path for the `.sqlite` file.

### Modifying the Database

My workflow involves using the generated sqlite database to create patches. I then
use sql to create my patches. I have talent update guides for the modifications that
have to be done to the spell file to make the talents work as written. After I modify the
spell table, I export the table to insert statements and name it Spell.sql to convert
using the wow_custom_dbc crate of wow_dbc.

#### The Patching Process

The database modification process follows a structured workflow to ensure all DBC dependencies and talent changes are applied correctly:

1.  **DBC Extraction & Conversion**: Raw `.dbc` files are extracted from the game client and converted into a single SQLite database (`wrath_dbcs.sqlite`) using `wow_dbc_converter`.
2.  **SQL Patch Development**: SQL scripts are written to modify specific tables (like `spell`, `talent`, `talent_tab`, etc.) within the SQLite database.
3.  **Sequential Patching**: Patches are applied in a specific order to maintain data integrity, starting with core requirements and moving to specific talent/spell adjustments.
4.  **DBC Generation**: After applying patches, the modified SQLite tables are exported back to `.dbc` files using `wow_custom_dbc`.
5.  **Client/Server Deployment**: The new `.dbc` files are packed into an MPQ for the client and copied to the server's `dbc` directory.

Note: Increasing mount speed can only be done once and is found in the HighlyOptionalBalanceChanges.sql. Ensure you only execute
those three commented out statements a single time if you are going to increase mount speed.

#### Executing SQL Patches

SQLite patches are versioned Flyway migrations in `apps/patchgenerator/dmls/migrations/` (`V001__…` through `V021__…`). `apply_patches.sh` / `apply_patches.ps1` download the Flyway CLI on first run (into `apps/patchgenerator/.flyway/`, gitignored) and run `flyway migrate` against `wrath_dbcs.sqlite`. Already-applied versions are recorded in `flyway_schema_history` inside that database, so re-running the script is a no-op.

**On Windows (PowerShell):**
```powershell
./apply_patches.ps1 -SqliteDb "./wow_dbc/wrath_dbcs.sqlite"
```

**On Linux/Unix (Bash):**
```bash
./apply_patches.sh
```

New DBC-sqlite changes belong in `dmls/migrations/` as the next `Vnnn__Description.sql`. Do not add unordered files under `spellchangeguides/` / `talentchangeguides/` and expect them to run.

`dmls/required/*.sql` are full-table dumps consumed by `wow_custom_dbc` when generating `.dbc` files. They are not Flyway migrations (re-inserting them into a populated converter database would collide on primary keys).

The numbered migration order matches the previous patch sequence:
1.  Spell change guides (`V001`–`V004`)
2.  Stat file modifications (`V005`–`V006`)
3.  Talent update guides (`V007`–`V017`)
4.  Custom talents (`V018`–`V020`)
5.  Skill race/class info (`V021`)

### Outputting Generated DBCs to UIMods and Worldserver

To use the generated DBCs in a client-side patch and for the server, copy them to the `UIMods/patch-n/DBFilesClient` directory and the worldserver `dbc` directory. This is often part of a larger build process:

```powershell
# Generate DBCs
cargo run -p wow_custom_dbc -- wrath -o "D:\CustomWowRebuild\patchn-new\gen" -i "D:\CustomWowRebuild\azerothcore-wotlk-classless\modules\mod-classless\apps\patchgenerator\dmls\required"

# Copy to UIMods for MPQ creation
copy /y "D:\CustomWowRebuild\patchn-new\gen\dbc" "D:\CustomWowRebuild\azerothcore-wotlk-classless\modules\mod-classless\UIMods\patch-n\DBFilesClient"

# Copy to worldserver location
copy /y "D:\CustomWowRebuild\patchn-new\gen\dbc" "D:\CustomWowRebuild\azerothcore-wotlk-classless\cmake-build-debug-visual-studio\bin\Debug\dbc"
```

### Generating the MPQ

To create the `.mpq` file for the client, use `mpqcli`:

```powershell
# Delete old mpq, create new one from UIMods folder, and copy to game client
del D:\CustomWowRebuild\patchn-new\patch-n.mpq
D:\CustomWowRebuild\Tools\mpqcli\mpqcli.exe create -o D:\CustomWowRebuild\patchn-new\patch-n.mpq D:\CustomWowRebuild\azerothcore-wotlk-classless\modules\mod-classless\UIMods\patch-n
copy /y D:\CustomWowRebuild\patchn-new\patch-n.mpq D:\CustomWowRebuild\GameClient\Data\patch-n.mpq
```

### Reviewing the MPQ

After generating the MPQ, it is important to review its appearance to ensure everything is correctly structured. Open the generated `.mpq` file with [Ladik's MPQ Editor](http://www.zezula.net/download/mpqeditor_en.zip) and compare its layout to the example image below.

![Example MPQ Layout](.github/ExampleDBCLayout.png)


# Old
## Useful commands
- cargo run -p wow_dbc_converter -- wrath -i /path/to/dbc/folder -o wrath_dbcs.sqlite
- cargo run -p wow_custom_dbc -- wrath -o /usr/games/wow/server/data -i /usr/games/wow/

## Implemented Features
- Talent points are computed based off of the player's achievements and level.
- Trainers can train any class
- Players can learn any talent from any tree
- Portal Master to dungeons
- Teleport spell to alliance training and horde training zones (trainers have to be manually added)
- TotemBar added to bartender for every class, totems have to be created with GM commands currently
- 

## TODOS
- A UI mod to allow players to select talents from any tree
- A UI mod to allow players to access all their spells.
- Configuration setting to set talent cap
- Overhaul the pet system

## Licensing

The default license of the skeleton-module template is the MIT but you can use a different license for your own modules.

So modules can also be kept private. However, if you need to add new hooks to the core, as well as improving existing ones, you have to share your improvements because the main core is released under the AGPL license. Please [provide a PR](https://www.azerothcore.org/wiki/how-to-create-a-pr) if that is the case.


## Notes for myself
### Spell specific modifiers
CalculateSpellMod()
SpellInfo
SpellModifier
- SpellModOp (MiscValueA)
- SpellModType (Aura Type)
- mask (SpellClassMask)

IsAffectedBySpellMod

Plan:
- Switch on spellID

Script hook: OnIsAffectedBySpellModCheck(affectingSpell, affectedSpell, mod)
