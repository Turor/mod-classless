-- Ice Shards
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (11207,12672,15047);

update Spell
set effect_aura_0 = 163, effect_misc_value_0 = 16, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (11207,12672,15047);

-- Piercing Ice
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (11207,12672,15047);

update Spell
set effect_aura_0 = 79, effect_misc_value_0 = 16, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (11151,12952,12953);

-- Frost Channeling
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (11160,12518,12519);

update Spell
set description_lang_en_gb = 'Reduces the mana cost of all Mage Frost Spells by $s1% and reduces the threat caused by your Frost spells by $s2%.'
where id in (11160,12518,12519);

-- Shatter (NEEDS TESTING)
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (11207,12672,15047);
--
-- update Spell
-- set effect_aura_0 = 79, effect_misc_value_0 = 16, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
-- where id in (11151,12952,12953);

-- Arctic Winds (WORKS)
-- Arcane Focus (WORKS)
-- Arcane Concentration (NEEDS TESTING)
-- Focus Magic (WORKS)
-- Arcane Potency (WORKS)
-- Arcane Power (WORKS)
-- Spell Power
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (35578,35581);

update Spell
set effect_aura_0 = 163, effect_misc_value_0 = 16, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (35578,35581);

-- REDO fire talents if needed

-- Improved Frost Bolt -> Frozen Resilience 1% per rank of intellect becomes resistances
# select id, effect_0, effect_1,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (11070,12473, 16763,16765,16766, 28574);

update spell set effect_0=6,effect_aura_0 = 182, effect_misc_value_0=124, effect_misc_value_b_0=3, effect_spell_class_mask_a_0=0, implicit_target_a_1=0, effect_spell_class_mask_b_0=0,
                 description_lang_en_gb= 'Increases your magical resistances by an amount equal to $s1% of your Intellect.', name_lang_en_gb = 'Frozen Resilience', spell_icon_id=4169
where id in (11070,12473, 16763,16765,16766);

update spell set effect_base_points_0 = 0 where id=11070;
update spell set effect_base_points_0 = 1 where id=12473;
update spell set effect_base_points_0 = 2 where id=16763;
update spell set effect_base_points_0 = 3 where id=16765;
update spell set effect_base_points_0 = 4 where id=16766;

-- Update Empowered Frost Bolt to have increased chill chance
# select id, effect_0,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where id in (31682,31683,44543);

update spell set effect_1=0,effect_aura_1=0,implicit_target_a_1=0,effect_bonus_coefficient_1=0,effect_chain_amplitude_1=0,
                 effect_misc_value_1=0,effect_misc_value_b_1=0, effect_die_sides_1=0, effect_base_points_1=0,
                 effect_spell_class_mask_a_1=0, effect_spell_class_mask_b_1=0, effect_spell_class_mask_c_1=0,
                 description_lang_en_gb= 'Increases the damage of your Frostbolt and Ice Lance spell by an amount equal to $s1% of your spell power.',
                 effect_spell_class_mask_a_0=32+131072
where id in (31682,31683);

# select * from spell where id=44543;


-- More spell hit and melee hit 54, 55
-- More Spell Haste 216
-- Proccing more spells, ramping
-- Durability - Glass cannon, damage taken or health reduction in exchange for more damage
-- Spell crit chance has a chance to reduce spell damage
-- Runic Power is generated via autos, or through anger management type

# select * from SpellCastTimes;
#
# select * from SpellCastTimes where base in (0,100, 250,400,500,800,750,1200,1600);
-- 196 for 800, 3 for 500, 2 for 100,
-- 3 .5, 4 1, 5 2, 16, 1.5

-- Apply cast time reduction to frost bolt
# select s.id,s.name_subtext_lang_en_gb,s.casting_time_index,sct.base,recovery_time, category_recovery_time
# from spell s
#          join SpellCastTimes sct on casting_time_index=sct.id
# where s.id in (116,205,7322,837,8406,8407,8408,10179,10180,10181,25304,27071,27072,38697,42841,42842);

update spell set casting_time_index=1 where id=116;
update spell set casting_time_index=2 where id=205;
update spell set casting_time_index=3 where id=837;
update spell set casting_time_index=4 where id=7322;
update spell set casting_time_index=202 where id in (8406,8407,8408,10179,10180,10181,25304,27071,27072,38697,42841,42842);

-- Cold as Ice
-- Improved Fireball
-- Incineration
-- Improved Fire Blast


# select id, effect_0, effect_1,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where effect_aura_0=316 or effect_aura_1=316 or effect_aura_2=316;

# select id, effect_0, effect_1,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        effect_aura_1, effect_die_sides_1, effect_base_points_1, implicit_target_a_1, effect_bonus_coefficient_1, effect_chain_amplitude_1, effect_misc_value_1, effect_misc_value_b_1,
#        effect_spell_class_mask_b_0, effect_spell_class_mask_b_1, effect_spell_class_mask_b_2,
#        name_lang_en_gb, description_lang_en_gb
# from Spell where effect_aura_0=286 or effect_aura_1=286 or effect_aura_2=286;

-- For Periodic Haste, each class needs its own talent for spells in that class.
-- effect_aura_0=316, effect_spell_class_mask_a_0=-1,effect_spell_class_mask_b_0=-1,effect_spell_class_mask_c_0=-1,effect_base_points_0=99, effect_die_sides_0=1
-- AuraEffect::CalculatePeriodic is where this is handled

-- For Periodic Crit, similarly each class needs it own talent to target all spells in that class.
-- effect_aura_1=286, effect_spell_class_mask_a_1=0,effect_spell_class_mask_b_1=0,effect_spell_class_mask_c_1=0, effect_base_points_1=99, effect_die_sides_1=1
-- AuraEffect::CalcPeriodicCritChance is where this is handled