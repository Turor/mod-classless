-- Spell ID cutover (characters DB, run on BOTH realms): 360001-360016 -> 350011-350026 (new = old - 9990).
-- Idempotent. Run with the worldserver STOPPED (otherwise it rewrites these tables on save).
UPDATE `character_action`          SET `action` = `action` - 9990 WHERE `type` = 0 AND `action` BETWEEN 360001 AND 360016;
UPDATE `character_aura`            SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
UPDATE `character_talent`          SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
UPDATE `character_spell`           SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
UPDATE `character_spell_cooldown`  SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
UPDATE `pet_aura`                  SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
UPDATE `pet_spell`                 SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
UPDATE `pet_spell_cooldown`        SET `spell`  = `spell`  - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
