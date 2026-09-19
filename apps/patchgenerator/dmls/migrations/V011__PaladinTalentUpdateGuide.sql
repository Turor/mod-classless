-- Holy Power
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (5923,5924,5925,5926,25829);

update Spell
set effect_aura_0 = 57, effect_misc_value_0 = 2, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (5923,5924,5925,5926,25829);

-- Extend judgement range
-- select id, range_index, name_lang_en_gb from spell where id in (57774,53408, 53407,20271, 9472);

update spell set range_index = 5 where id in (20271,57774,53408, 53407);

-- Apply Improved Judgement
-- select s.id,s.casting_time_index,sct.base,recovery_time, category_recovery_time, name_subtext_lang_en_gb
-- from spell s
--          join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (57774,53408, 53407,20271);

update spell set recovery_time = 4000, category_recovery_time = 4000 where id in (20271,57774,53408, 53407);

-- Improved Judgement -> Divine Resilience (effect_misc_value_0=1 charm, effect_misc_value_1=12 stun) 9453 example
-- select id, effect_0, effect_1,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
--        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
--        effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (25956,25957,9453);

update spell set effect_0=6, effect_aura_0=232, effect_die_sides_0=1, implicit_target_a_0=1, effect_bonus_coefficient_0=1,
                    effect_misc_value_0=1, effect_misc_value_b_0=0, effect_spell_class_mask_a_0=0, effect_spell_class_mask_a_1=0, effect_spell_class_mask_a_2=0,
                 effect_1=6, effect_aura_1=232, effect_die_sides_1=1, implicit_target_a_1=1, effect_bonus_coefficient_1=1,
                    effect_misc_value_1=12, effect_misc_value_b_1=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_b_1=0, effect_spell_class_mask_b_2=0,
                 description_lang_en_gb='Reduces the duration of all Charm and Stun effects by $s1%.', name_lang_en_gb='Divine Resilience', spell_icon_id=2542
where id in (25956,25957);
update spell set effect_base_points_0=-16, effect_base_points_1=-16 where id in (25956);
update spell set effect_base_points_0=-31, effect_base_points_1=-31 where id in (25957);


