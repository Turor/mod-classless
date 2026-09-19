-- Careful Aim needs effect 2 268
# select * from spell where id in (34482,34483,34484);
#
# select id, effect_0,effect_1,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (34482,34483,34484);

update Spell
Set effect_1=6,effect_aura_1 = 268, effect_misc_value_1=3, effect_misc_value_b_1=1, /*effect_die_sides_1=1,*/ implicit_target_a_1=1, /*effect_base_points_1=0,*/ effect_bonus_coefficient_1=1, effect_chain_amplitude_1=1,
    description_lang_en_gb = 'Increases your Ranged and Melee Attack Power by $s1% of your Agility.'
where id in (34482,34483,34484);

update Spell set effect_base_points_1 = 32, effect_base_points_0=32 where id = 34482;
update Spell set effect_base_points_1 = 65, effect_base_points_0=65 where id = 34483;
update Spell set effect_base_points_1 = 99, effect_base_points_0=99 where id = 34484;


-- Change Serpents swiftness to affect melee as well
# select id, effect_0,effect_1,effect_2,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_aura_2, effect_die_sides_2, effect_base_points_2, implicit_target_a_2, effect_bonus_coefficient_2, effect_chain_amplitude_2, effect_misc_value_2, effect_misc_value_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (34466,34467,34468,34469,34470);

update spell set effect_aura_0 = 192, description_lang_en_gb='Increases ranged and melee combat attack speed by $s1% and your pet''s melee attack speed by $s2%.' where id in (34466,34467,34468,34469,34470);

-- update Spell
-- Set effect_2=6,effect_aura_2 = 218, effect_misc_value_2=0, effect_misc_value_b_2=0, effect_die_sides_2=1, implicit_target_a_2=1, /*effect_base_points_2=0,*/ effect_bonus_coefficient_2=1, /*effect_chain_amplitude_2=1,*/
--     description_lang_en_gb = 'Increases your melee and ranged attack speed by $s2%.  In addition your Rend and Deep Wounds abilities also increase all physical damage caused to that target by $30069s1%.'
-- where id in (29836,29859);

# select id, effect_0,effect_1,effect_2,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_aura_2, effect_die_sides_2, effect_base_points_2, implicit_target_a_2, effect_bonus_coefficient_2, effect_chain_amplitude_2, effect_misc_value_2, effect_misc_value_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (19255,19256,19257,19258,19259);

update spell set effect_base_points_0 = 2 where id = 19255;
update spell set effect_base_points_0 = 5 where id = 19256;
update spell set effect_base_points_0 = 8 where id = 19257;
update spell set effect_base_points_0 = 11 where id = 19258;
update spell set effect_base_points_0 = 14 where id = 19259;

