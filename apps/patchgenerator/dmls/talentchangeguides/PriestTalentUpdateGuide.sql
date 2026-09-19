-- Twin Disciplines
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (47586,47587,47588,52802,52803);

update Spell
set effect_aura_0 = 79, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0,
    description_lang_en_gb = 'Increases the damage and healing done by your spells by $s1%.'
where id in (47586,47587,47588,52802,52803);

update Spell
set effect_aura_1 = 118, effect_misc_value_1 = 126, effect_spell_class_mask_a_1=0, effect_spell_class_mask_b_1=0, effect_spell_class_mask_c_1=0
where id in (47586,47587,47588,52802,52803);
-- Focused Power (Works? - Needs Testing)
-- Focused Will (WORKS)
-- Holy Specialization
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (14889,15008,15009,15010,15011);

update Spell
set effect_aura_0 = 57, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (14889,15008,15009,15010,15011);
-- Blessed Resilience (WORKS)
-- Test of Faith (Too hard to change, likely works)
-- Darkness
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (15259,15307,15308,15309,15310);

update Spell
set effect_aura_0 = 79, effect_misc_value_0 = 32, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (14889,15008,15009,15010,15011);

-- Shadow Focus
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (15260,15327,15328);

update Spell
set effect_aura_0 = 55, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0,
    description_lang_en_gb='Increases your chance to hit with all your spells by $s1%, and reduces the mana cost of your Shadow spells by $s2%.'
where id in (15260,15327,15328);

-- Shadow Reach
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (17322,17323);

update Spell
set description_lang_en_gb='Increases the range of your offensive Shadow Priest spells by $s1% when your base class is a priest.'
where id in (17322,17323);


-- Update Shadow Power to apply to all shadow damage
# select id, effect_0,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#         effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#         effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (33221,33222,33223,33224,33225, 11151);

update spell
set effect_0=6, effect_aura_0 = 163, effect_die_sides_0=1, implicit_target_a_0=1,effect_misc_value_0=32, effect_spell_class_mask_a_0=0, effect_spell_class_mask_a_1=0,
    description_lang_en_gb='Increases the critical strike damage of your shadow spells by $s1% and further increases the critical strike damage bonus of your Mind Blast, Mind Flay, and Shadow Word: Death spells by $s2%.'
where id in (33221,33222,33223,33224,33225);
update spell set effect_base_points_0=14 where id=33221;
update spell set effect_base_points_0=29 where id=33222;
update spell set effect_base_points_0=44 where id=33223;
update spell set effect_base_points_0=59 where id=33224;
update spell set effect_base_points_0=74 where id=33225;

-- Revert Devouring Plague to RAW
# select id, effect_0,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (63625,63626,63627);

update spell set effect_base_points_0=4, effect_base_points_1=10 where id=63625;
update spell set effect_base_points_0=9, effect_base_points_1=21 where id=63626;
update spell set effect_base_points_0=14, effect_base_points_1=32 where id=63627;


