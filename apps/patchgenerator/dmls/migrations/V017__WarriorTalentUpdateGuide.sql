-- Blood Frenzy to increase ranged haste
-- select id, effect_0,effect_1,effect_2,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
--        effect_aura_2, effect_die_sides_2, effect_base_points_2, implicit_target_a_2, effect_bonus_coefficient_2, effect_chain_amplitude_2, effect_misc_value_2, effect_misc_value_b_2,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (29836,29859);

update spell set effect_aura_1 = 192 where id in (29836,29859);

update Spell
Set effect_2=6,effect_aura_2 = 140, effect_misc_value_2=0, effect_misc_value_b_2=0, effect_die_sides_2=1, implicit_target_a_2=1, /*effect_base_points_2=0,*/ effect_bonus_coefficient_2=1, /*effect_chain_amplitude_2=1,*/
    description_lang_en_gb = 'Increases your melee and ranged attack speed by $s2% with ranged attack speed receive $s3% extra haste.  In addition your Rend and Deep Wounds abilities also increase all physical damage caused to that target by $30069s1%.'
where id in (29836,29859);

update Spell set effect_base_points_2=4 where id in (29836);
update Spell set effect_base_points_2=9 where id in (29859);

-- Update titan grip to work for every item type
-- select equipped_item_subclass, description_lang_en_gb from spell where id in (46917);
update spell set equipped_item_subclass = -1, description_lang_en_gb='Allows you to equip two-handed weapons in one hand.  While you have a two-handed weapon equipped in one hand, your damage done is reduced by $49152s1%.' where id in (46917);
update spell set effect_misc_value_0=127 where id=49152;


