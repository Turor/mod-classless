-- V027: Roguelike "Rest" (spell 58645, client name "Refreshment") in the General spellbook tab.
-- RoguelikeRest.lua teaches 58645 to every Roguelike character on login, but the client lists a known spell
-- only when SkillLineAbility maps it to a skill line the character has; 58645 had no row, so it never showed.
-- Skill line 183 = General (Attack, etc.). acquire_method 0 (not auto-learned): the server keeps its own DBC,
-- and Standard realm characters never learn 58645. Client DBC only.
insert into main.SkillLineAbility (id, skill_line, spell, race_mask, class_mask, exclude_race, exclude_class, min_skill_line_rank, superceded_by_spell, acquire_method, trivial_skill_line_rank_high, trivial_skill_line_rank_low, character_points_0, character_points_1)
values (21984, 183, 58645, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
