-- Spells work by targeting the origin spell and amping it further
-- Demon Passives for Stamina and Intellect 402653184
-- 0x0800000: 18735,18736,18737,18738,30148 -- Stamina
-- 0x1000000: 18739,18740,18741,18742,30149 -- Intellect
-- 18727, 18728, 18729, 18730, 30147: -- effect_0 = physical damage, effect_1 = spell damage
-- Tamed Pet Passive 01: 8875  - Total Damage Done : effect_spell_class_mask_b_0=33554432, effect_misc_value_0 = 126 aura=107 effect=6
-- Tamed Pet Passive 02: 19580 - Base Armor Percent
-- Tamed Pet Passive 03: 19581 - Max Health : effect_spell_class_mask_b_0=134217728, effect_misc_value_0 = 8 aura=107 effect=6
-- Tamed Pet Passive 04: 19582 - Speed :
-- Tamed Pet Passive 05: 19589 - Focus Regeneration :
-- Tamed Pet Passive 06: 19590 - Critical Strike Chance -- effect_0 = physical, effect_1 = spell
-- Tamed Pet Passive 08: 34666 - Chance to Hit -- effect_0 = physical, effect_1 = spell
-- Tamed Pet Passive 09: 34667 - Dodge Chance
-- Tamed Pet Passive 10: 34675 - Attack Speed
-- Tamed Pet Passive 11: 55566 - All element Resistance
-- 8875, 19580, 19581, 19582, 19589, 19590, 34666, 34667, 34675, 55566

-- select id from spell where effect_misc_value_0 = 1 and name_lang_en_gb like '%Tamed Pet%'; -- agility
-- select * from Faction where name_lang_en_gb like '%Dalaran%';
-- select * from FactionTemplate join faction on faction.id = FactionTemplate.faction where name_lang_en_gb like '%Dalaran%';

-- select id, effect_0,effect_1,effect_2,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0, effect_spell_class_mask_a_0,
--        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1, effect_spell_class_mask_a_1,
--        effect_aura_2, effect_die_sides_2, effect_base_points_2, implicit_target_a_2, effect_bonus_coefficient_2, effect_chain_amplitude_2, effect_misc_value_2, effect_misc_value_b_2, effect_spell_class_mask_a_2,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (53270,19583);


update Spell
set effect_1=6, effect_aura_1 = 107, effect_misc_value_1 = 8, effect_spell_class_mask_a_1=33554432, effect_spell_class_mask_b_1=0, effect_spell_class_mask_c_1=0, effect_base_points_1 = 49, effect_die_sides_1=1, implicit_target_a_1=1, effect_chain_amplitude_1=1, effect_bonus_coefficient_1=1,
    effect_2=6, effect_aura_2 = 107, effect_misc_value_2 = 8, effect_spell_class_mask_a_2=134217728, effect_spell_class_mask_b_2=0, effect_spell_class_mask_c_2=0, effect_base_points_2 = 99, effect_die_sides_2=1, implicit_target_a_2=1, effect_chain_amplitude_2=1, effect_bonus_coefficient_2=1,
    description_lang_en_gb = 'You master the art of Beast training, teaching you the ability to tame Exotic pets and increasing your total pets damage by $s2% and maximum health by $s3%.'
where id in (53270);

-- select SkillLine.display_name_lang_en_gb, spell.name_lang_en_gb, spell.id, SkillLineAbility.* from SkillLineAbility
-- join SkillLine on SkillLine.id = SkillLineAbility.skill_line
-- join Spell on Spell.id = SkillLineAbility.spell
-- where spell.name_lang_en_gb like '%Call%';

-- To create summoner types remove from attributes ex dismiss pet first from
-- 688, 697, 712, 691, 30146,