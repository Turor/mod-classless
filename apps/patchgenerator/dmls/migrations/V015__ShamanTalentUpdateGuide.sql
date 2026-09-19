-- Elemental Devastation (WORKS)
-- Elemental Fury
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (16089,60184,60185,60187,60188);

update Spell
set effect_aura_0 = 163, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (16089,60184,60185,60187,60188);

update Spell set description_lang_en_gb = 'Increases the critical strike damage bonus of your spells by $s1%.' where id in (16089,60184,60185,60187,60188);

-- Elemental Focus (WORKS)
-- Novas sharing cooldown??
-- Fire Blast and Fire Shock sharing same cooldowns??
-- Elemental Precision (WORKS)
-- Elemental oath
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (51466,51470);

update Spell
set effect_aura_0 = 57, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (51466,51470);

update Spell
set effect_aura_1 = 79, effect_misc_value_1 = 126, effect_spell_class_mask_a_1=0, effect_spell_class_mask_b_1=0, effect_spell_class_mask_c_1=0
where id in (51466,51470);

-- Tidal Mastery
-- select id, Spell.effect_die_sides_0, Spell.effect_base_points_0, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (16194,16218,16219,16220,16221);

update Spell
set effect_aura_0 = 57, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0, effect_base_points_0 = 1,
    description_lang_en_gb = 'Increases the critical effect chance of your spells by $s1%.'
where id in (16194,16218,16219,16220,16221);

update Spell set effect_base_points_0 = 3 where id = 16218;
update Spell set effect_base_points_0 = 5 where id = 16219;
update Spell set effect_base_points_0 = 7 where id = 16220;
update Spell set effect_base_points_0 = 9 where id = 16221;

-- Purification
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (16178,16210,16211,16212,16213);

update Spell
set effect_aura_0 = 118, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (16178,16210,16211,16212,16213);

-- Blessing of the Eternals
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (51554,51555);

update Spell
set effect_aura_0 = 57, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (51554,51555);

-- Mental Dexterity needs effect 2 with 212
-- select * from spell where id in (51883,51884,51885);
--
-- select id, effect_0, effect_1,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (51883,51884,51885);

update Spell
Set effect_1=6,effect_aura_1 = 212, effect_misc_value_1=3, effect_misc_value_b_1=3, effect_die_sides_1=1, implicit_target_a_1=1, /*effect_base_points_1=0,*/ effect_bonus_coefficient_1=0, effect_chain_amplitude_1=1,
    description_lang_en_gb = 'Increases your Ranged and Melee Attack Power by $s1% of your Intellect.'
where id in (51883,51884,51885);

update Spell set effect_base_points_1 = 32, effect_base_points_0=32 where id = 51883;
update Spell set effect_base_points_1 = 65, effect_base_points_0=65 where id = 51884;
update Spell set effect_base_points_1 = 99, effect_base_points_0=99 where id = 51885;


-- Weapon mastery to affect every weapon like it implies
-- select equipped_item_subclass from spell where id in (29082, 29084, 29086);
update spell set equipped_item_subclass = -1 where id in (29082, 29084, 29086);

-- Update Storm, Earth, and Fire
-- select id, effect_0,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (51483,51485,51486, 33853);

update spell set effect_aura_0 = 137, effect_bonus_coefficient_0=1,effect_misc_value_0=-1,
             effect_spell_class_mask_a_0=0, effect_spell_class_mask_a_1=0, effect_spell_class_mask_a_2=0,
             description_lang_en_gb='Increases all attributes by $s1%, your Earthbind Totem also has a $s2% chance to root targets for $64695d when cast and the periodic damage done by your Flame Shock is increased by $s3%.'
             where id in (51483,51485,51486);
update spell set effect_base_points_0 = 1 where id=51483;
update spell set effect_base_points_0 = 3 where id=51485;
update spell set effect_base_points_0 = 5 where id=51486;

-- Update Chain Lightning cooldown to be what it would be after being modified by Stone Earth and Fire, and reduce cast time to what it'd be with lightning mastery
-- select * from SpellCastTimes;
-- 16 1.5s, 5 2s, 4 1s, 3 .5s

-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
--          join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (49271, 49270,421,930,2860,10605,25439,25442);
-- -- id 4 for casting_time_index
-- update spell set category_recovery_time = 3000, casting_time_index=4 where id in (49271, 49270,421,930,2860,10605,25439,25442);

-- Update Lightning Mastery
-- select id, effect_0,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (16578,16579,16580,16581,16582, 11151);

update spell set effect_aura_0 = 79, effect_bonus_coefficient_0=0, effect_misc_value_0=12, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0,
                 description_lang_en_gb='Increases the damage done by your Nature and Fire spells by $s1%.',
                 name_lang_en_gb='Nature Mastery'
             where id in (16578,16579,16580,16581,16582);
update spell set effect_base_points_0 = 1 where id=16578;
update spell set effect_base_points_0 = 3 where id=16579;
update spell set effect_base_points_0 = 5 where id=16580;
update spell set effect_base_points_0 = 7 where id=16581;
update spell set effect_base_points_0 = 9 where id=16582;


-- Update Lightning Bolt Casting time to always have the effect of Lightning Mastery
-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
-- join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (49237, 49238,25449,25448,15208,15207,10392,10391,6041,943,915,548,529,403);

update spell set casting_time_index=16 where id in (49237, 49238,25449,25448,15208,15207,10392,10391,6041,943,915,548);
update spell set casting_time_index=3 where id in (403);
update spell set casting_time_index=4 where id in (529);

-- Update Lava Burst Casting time to always have the effect of Lightning Mastery
-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
-- join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (51505,60043);
update spell set casting_time_index=4 where id in (51505,60043);



-- Booming Echoes
-- select id, effect_0, effect_1,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--             effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
--        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
--             effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
--        name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (63370,63372, 33853);

update spell set effect_aura_0 = 137, effect_bonus_coefficient_0=1,effect_misc_value_0=-1, effect_spell_class_mask_a_0=0,
                 description_lang_en_gb='Increases all attributes by $s1%, and increases the direct damage done by your Flame Shock and Frost Shock spells by an additional $s2%.'
where id in (63370,63372);
update spell set effect_base_points_0 = 1 where id=63370;
update spell set effect_base_points_0 = 3 where id=63372;

-- Reverberation -> Nature's Fury
-- select id, effect_0,
--        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
--        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
--        name_lang_en_gb, description_lang_en_gb, spell_icon_id
-- from Spell where id in (16040,16113,16114,16115,16116, 11151);

update spell set effect_aura_0 = 79, effect_bonus_coefficient_0=0, effect_misc_value_0=8, effect_spell_class_mask_a_0=0, effect_spell_class_mask_a_1=0,
                 name_lang_en_gb='Nature''s Fury', description_lang_en_gb='Increases the damage done by your Nature Spells by $s1%', spell_icon_id=2025
where id in (16040,16113,16114,16115,16116);
update spell set effect_base_points_0 = 2 where id=16040;
update spell set effect_base_points_0 = 5 where id=16113;
update spell set effect_base_points_0 = 8 where id=16114;
update spell set effect_base_points_0 = 11 where id=16115;
update spell set effect_base_points_0 = 14 where id=16116;

-- Frost shock
-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
--          join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (8056,8058,10472,10473,25464,49235,49236);

update spell set category_recovery_time=3000 where id in (8056,8058,10472,10473,25464,49235,49236);

-- Earth Shock
-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
--          join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (8042,8044,8045,8046,10412,10413,10414,25454,49230,49231,65973,68100,68101,68102);
-- update spell set category_recovery_time=3000 where id in (8042,8044,8045,8046,10412,10413,10414,25454,49230,49231,65973,68100,68101,68102);

-- Flame Shock
-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
--          join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (8050,8052,8053,10447,10448,25457,29228,49232,49233);
-- update spell set category_recovery_time=3000 where id in (8050,8052,8053,10447,10448,25457,29228,49232,49233);

-- Wind Shear
-- select s.casting_time_index,sct.base,recovery_time, category_recovery_time
-- from spell s
--          join SpellCastTimes sct on casting_time_index=sct.id
-- where s.id in (57994);
-- update spell set recovery_time=5000 where id in (57994);

-- Adds a disclaimer to elemental reach

