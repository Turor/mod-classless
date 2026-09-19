-- Black Ice
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (49140,49661, 49662,49663,49664);

update Spell
set effect_aura_0 = 79, effect_misc_value_0 = 48, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (49140,49661, 49662,49663,49664);
-- Tundra Stalker (WORKS? Needs Testing?)
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (49140,49661, 49662,49663,49664);

update Spell
set effect_aura_0 = 79, effect_misc_value_0 = 48, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (49140,49661, 49662,49663,49664);
-- Virulence
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (48962,49567, 49568);

update Spell
set effect_aura_0 = 55, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=997, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (48962,49567, 49568);
-- Rage of Rivendare (Unable to modify, too complex- Needs testing to determine what tool tip should say)

-- Improved Icy talons to affect Ranged haste
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (55610);

update spell set effect_aura_0 = 192, description_lang_en_gb='Increases the melee and ranged haste of all party and raid members within $55610a1 yds by $55610s1% and your haste by an additional $55610s2%.' where id = 55610;

-- Necrosis to proc on ranged damage
# select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
#        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
# from Spell where id in (51459,51462, 51463,51464,51465);
