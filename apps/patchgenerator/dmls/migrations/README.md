# Flyway migrations (classless SQLite)

These files are applied to `wow_dbc/wrath_dbcs.sqlite` by `../apply_patches.sh` / `../apply_patches.ps1`.

Naming: `V<version>__<description>.sql` (two underscores). Next patch is `V026__…`. (V022 is intentionally unused: TalentSpellLevels shipped as V025 so it orders after V023/V024.)

`dmls/required/` stays as DBC export input for `wow_custom_dbc`, not this folder.
