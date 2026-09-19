-- Omen of Clarity (WORKS)
-- Gift of Nature
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (17104,24943, 24944,24945,24946);

update Spell
set description_lang_en_gb='Increases the effect of all nature healing spells by $s1%.'
where id in (17104,24943, 24944,24945,24946);
-- Natural Perfection (WORKS)
-- Genesis
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (57810,57811, 57812,57813,57814);

update Spell
set description_lang_en_gb='Increases the damage and healing done by your periodic nature spell damage and healing effects by $s1%.'
where id in (57810,57811, 57812,57813,57814);
-- Nature's Grace (WORKS- Needs testing)

-- Starlight Wrath -> Gift of Elune
# select id, effect_0,
#        effect_aura_0, effect_die_sides_0, effect_base_points_0, implicit_target_a_0, effect_bonus_coefficient_0, effect_chain_amplitude_0, effect_misc_value_0, effect_misc_value_b_0,
#        effect_spell_class_mask_a_0, effect_spell_class_mask_a_1, effect_spell_class_mask_a_2,
#        name_lang_en_gb, description_lang_en_gb, spell_icon_id
# from Spell where id in (16814,16815,16816,16817,16818, 33853);
update spell set effect_aura_0=137, effect_misc_value_0=-1, effect_spell_class_mask_a_0=0,
                 description_lang_en_gb='Increases all attributes by $s1%.', name_lang_en_gb='Gift of Elune', spell_icon_id=1714
where id in (16814,16815,16816,16817,16818);
update spell set effect_base_points_0=1 where id=16814;
update spell set effect_base_points_0=3 where id=16815;
update spell set effect_base_points_0=5 where id=16816;
update spell set effect_base_points_0=7 where id=16817;
update spell set effect_base_points_0=9 where id=16818;


-- Update Wrath to reflect casting time with Starlight Wrath applied automatically
# select s.id,s.casting_time_index,sct.base,recovery_time, category_recovery_time, name_subtext_lang_en_gb
# from spell s
#          join SpellCastTimes sct on casting_time_index=sct.id
# where s.id in (5176,5177,5178,5179,5180,6780,8905,9912,26984,26985,48459,48461);

update spell set casting_time_index=3 where id in (5176,5177);
update spell set casting_time_index=4 where id in (5178,5179,5180,6780,8905,9912,26984,26985,48459,48461);
