-- V024: move the custom client spells 360001-360016 into the 350k custom block: new = old - 9990 (350011-350026).
-- 350001-350010 are the server-only Mythic+ advancement auras; new custom spells start at 350027 and go on BOTH realms.
-- Only rows still on the old IDs are touched.
UPDATE main.Spell SET id = id - 9990 WHERE id BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_0 = spell_rank_0 - 9990 WHERE spell_rank_0 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_1 = spell_rank_1 - 9990 WHERE spell_rank_1 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_2 = spell_rank_2 - 9990 WHERE spell_rank_2 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_3 = spell_rank_3 - 9990 WHERE spell_rank_3 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_4 = spell_rank_4 - 9990 WHERE spell_rank_4 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_5 = spell_rank_5 - 9990 WHERE spell_rank_5 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_6 = spell_rank_6 - 9990 WHERE spell_rank_6 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_7 = spell_rank_7 - 9990 WHERE spell_rank_7 BETWEEN 360001 AND 360016;
UPDATE main.Talent SET spell_rank_8 = spell_rank_8 - 9990 WHERE spell_rank_8 BETWEEN 360001 AND 360016;
UPDATE main.SkillLineAbility SET spell = spell - 9990 WHERE spell BETWEEN 360001 AND 360016;
UPDATE main.SkillLineAbility SET superceded_by_spell = superceded_by_spell - 9990 WHERE superceded_by_spell BETWEEN 360001 AND 360016;
