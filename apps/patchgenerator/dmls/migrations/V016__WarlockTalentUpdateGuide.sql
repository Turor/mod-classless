-- Backlash (WORKS
-- Pyroclasm (WORKS)
-- Empowered Imp Buff to 150% total?
-- description and damage on 47220, 47221, 47223 (Pretty sure pet auras handle it though)
-- 18727, 18728, 18729, 18730, 30147
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (47220, 47221, 47223);

update Spell
set effect_base_points_0=49
where id in (47220);
update Spell
set effect_base_points_0=99
where id in (47221);
update Spell
set effect_base_points_0=149
where id in (47223);

-- Malediction (WORKS)
-- Master Demonologist (Way too complicated for now, too little payoff)
-- Demonic Tactics (WORKS)
-- -- Demonic Pact
-- select id, Spell.effect_aura_0, Spell.effect_misc_value_0, spell.proc_type_mask, Spell.effect_spell_class_mask_a_0, Spell.effect_spell_class_mask_b_0,
--        Spell.effect_spell_class_mask_c_0, name_lang_en_gb, description_lang_en_gb
-- from Spell where id in (47236,47237,47238,47239,47240);

update Spell
set effect_aura_0 = 79, effect_misc_value_0 = 126, effect_spell_class_mask_a_0=0, effect_spell_class_mask_b_0=0, effect_spell_class_mask_c_0=0
where id in (47236,47237,47238,47239,47240);

-- Improved demonic Tactics  up to 100% at max level
-- Demonic Resilience, up to 33% mitigation at max level
-- Unholy Power, Up to 100% at max level
-- Fel Vitality up to 10% per level
--
