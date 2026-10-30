-- Spell ID cutover (world DB, run on BOTH realms): custom spells 360001-360016 -> 350011-350026 (new = old - 9990).
-- Idempotent: only rows still on the old IDs are touched. Must ship together with the renumbered
-- server DBCs (Spell/Talent/SkillLineAbility) and the matching patch-n.mpq.
UPDATE `spell_target_position` SET `ID` = `ID` - 9990 WHERE `ID` BETWEEN 360001 AND 360016;
UPDATE `spell_dbc`             SET `ID` = `ID` - 9990 WHERE `ID` BETWEEN 360001 AND 360016;
UPDATE `spell_script_names`    SET `spell_id` = IF(`spell_id` < 0, `spell_id` + 9990, `spell_id` - 9990) WHERE ABS(`spell_id`) BETWEEN 360001 AND 360016;
UPDATE `spell_proc`            SET `SpellId` = IF(`SpellId` < 0, `SpellId` + 9990, `SpellId` - 9990) WHERE ABS(`SpellId`) BETWEEN 360001 AND 360016;
UPDATE `spell_bonus_data`      SET `entry` = `entry` - 9990 WHERE `entry` BETWEEN 360001 AND 360016;
UPDATE `spell_linked_spell`    SET `spell_trigger` = IF(`spell_trigger` < 0, `spell_trigger` + 9990, `spell_trigger` - 9990) WHERE ABS(`spell_trigger`) BETWEEN 360001 AND 360016;
UPDATE `spell_linked_spell`    SET `spell_effect` = IF(`spell_effect` < 0, `spell_effect` + 9990, `spell_effect` - 9990) WHERE ABS(`spell_effect`) BETWEEN 360001 AND 360016;
UPDATE `spell_custom_attr`     SET `spell_id` = `spell_id` - 9990 WHERE `spell_id` BETWEEN 360001 AND 360016;
UPDATE `spell_area`            SET `spell` = `spell` - 9990 WHERE `spell` BETWEEN 360001 AND 360016;
