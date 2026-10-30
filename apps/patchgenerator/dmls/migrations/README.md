# Flyway migrations (classless SQLite)

These files are applied to `wow_dbc/wrath_dbcs.sqlite` by `../apply_patches.sh` / `../apply_patches.ps1`.

Naming: `V<version>__<description>.sql` (two underscores). Next patch is `V025__…`. V022 is held by the unpublished local branch `fix/talent-spell-levels` (`V022__TalentSpellLevels.sql`); renumber it to V025+ before merging, since Flyway rejects a V022 that arrives after V023/V024 are applied.

`dmls/required/` stays as DBC export input for `wow_custom_dbc`, not this folder.
