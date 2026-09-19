INSERT INTO spell (
    id,
    category,
    dispel_type,
    mechanic,
    attributes,
    attributes_ex,
    attributes_ex_b,
    attributes_ex_c,
    attributes_ex_d,
    attributes_ex_e,
    attributes_ex_f,
    attributes_ex_g,
    shapeshift_mask_0,
    shapeshift_mask_1,
    shapeshift_exclude_0,
    shapeshift_exclude_1,
    targets,
    target_creature_type,
    requires_spell_focus,
    facing_caster_flags,
    caster_aura_state,
    target_aura_state,
    exclude_caster_aura_state,
    exclude_target_aura_state,
    caster_aura_spell,
    target_aura_spell,
    exclude_caster_aura_spell,
    exclude_target_aura_spell,
    casting_time_index,
    recovery_time,
    category_recovery_time,
    interrupt_flags,
    aura_interrupt_flags,
    channel_interrupt_flags,
    proc_type_mask,
    proc_chance,
    proc_charges,
    max_level,
    base_level,
    spell_level,
    duration_index,
    power_type,
    mana_cost,
    mana_cost_per_level,
    mana_per_second,
    mana_per_second_per_level,
    range_index,
    speed,
    modal_next_spell,
    cumulative_aura,
    totem_0,
    totem_1,
    reagent_0,
    reagent_1,
    reagent_2,
    reagent_3,
    reagent_4,
    reagent_5,
    reagent_6,
    reagent_7,
    reagent_count_0,
    reagent_count_1,
    reagent_count_2,
    reagent_count_3,
    reagent_count_4,
    reagent_count_5,
    reagent_count_6,
    reagent_count_7,
    equipped_item_class,
    equipped_item_subclass,
    equipped_item_inv_types,
    effect_0,
    effect_1,
    effect_2,
    effect_die_sides_0,
    effect_die_sides_1,
    effect_die_sides_2,
    effect_real_points_per_level_0,
    effect_real_points_per_level_1,
    effect_real_points_per_level_2,
    effect_base_points_0,
    effect_base_points_1,
    effect_base_points_2,
    effect_mechanic_0,
    effect_mechanic_1,
    effect_mechanic_2,
    implicit_target_a_0,
    implicit_target_a_1,
    implicit_target_a_2,
    implicit_target_b_0,
    implicit_target_b_1,
    implicit_target_b_2,
    effect_radius_index_0,
    effect_radius_index_1,
    effect_radius_index_2,
    effect_aura_0,
    effect_aura_1,
    effect_aura_2,
    effect_aura_period_0,
    effect_aura_period_1,
    effect_aura_period_2,
    effect_amplitude_0,
    effect_amplitude_1,
    effect_amplitude_2,
    effect_chain_targets_0,
    effect_chain_targets_1,
    effect_chain_targets_2,
    effect_item_type_0,
    effect_item_type_1,
    effect_item_type_2,
    effect_misc_value_0,
    effect_misc_value_1,
    effect_misc_value_2,
    effect_misc_value_b_0,
    effect_misc_value_b_1,
    effect_misc_value_b_2,
    effect_trigger_spell_0,
    effect_trigger_spell_1,
    effect_trigger_spell_2,
    effect_points_per_combo_0,
    effect_points_per_combo_1,
    effect_points_per_combo_2,
    effect_spell_class_mask_a_0,
    effect_spell_class_mask_a_1,
    effect_spell_class_mask_a_2,
    effect_spell_class_mask_b_0,
    effect_spell_class_mask_b_1,
    effect_spell_class_mask_b_2,
    effect_spell_class_mask_c_0,
    effect_spell_class_mask_c_1,
    effect_spell_class_mask_c_2,
    spell_visual_id_0,
    spell_visual_id_1,
    spell_icon_id,
    active_icon_id,
    spell_priority,
    name_lang_en_gb,
    name_lang_ko_kr,
    name_lang_fr_fr,
    name_lang_de_de,
    name_lang_en_cn,
    name_lang_en_tw,
    name_lang_es_es,
    name_lang_es_mx,
    name_lang_ru_ru,
    name_lang_ja_jp,
    name_lang_pt_pt,
    name_lang_it_it,
    name_lang_unknown_12,
    name_lang_unknown_13,
    name_lang_unknown_14,
    name_lang_unknown_15,
    name_lang_flags,
    name_subtext_lang_en_gb,
    name_subtext_lang_ko_kr,
    name_subtext_lang_fr_fr,
    name_subtext_lang_de_de,
    name_subtext_lang_en_cn,
    name_subtext_lang_en_tw,
    name_subtext_lang_es_es,
    name_subtext_lang_es_mx,
    name_subtext_lang_ru_ru,
    name_subtext_lang_ja_jp,
    name_subtext_lang_pt_pt,
    name_subtext_lang_it_it,
    name_subtext_lang_unknown_12,
    name_subtext_lang_unknown_13,
    name_subtext_lang_unknown_14,
    name_subtext_lang_unknown_15,
    name_subtext_lang_flags,
    description_lang_en_gb,
    description_lang_ko_kr,
    description_lang_fr_fr,
    description_lang_de_de,
    description_lang_en_cn,
    description_lang_en_tw,
    description_lang_es_es,
    description_lang_es_mx,
    description_lang_ru_ru,
    description_lang_ja_jp,
    description_lang_pt_pt,
    description_lang_it_it,
    description_lang_unknown_12,
    description_lang_unknown_13,
    description_lang_unknown_14,
    description_lang_unknown_15,
    description_lang_flags,
    aura_description_lang_en_gb,
    aura_description_lang_ko_kr,
    aura_description_lang_fr_fr,
    aura_description_lang_de_de,
    aura_description_lang_en_cn,
    aura_description_lang_en_tw,
    aura_description_lang_es_es,
    aura_description_lang_es_mx,
    aura_description_lang_ru_ru,
    aura_description_lang_ja_jp,
    aura_description_lang_pt_pt,
    aura_description_lang_it_it,
    aura_description_lang_unknown_12,
    aura_description_lang_unknown_13,
    aura_description_lang_unknown_14,
    aura_description_lang_unknown_15,
    aura_description_lang_flags,
    mana_cost_pct,
    start_recovery_category,
    start_recovery_time,
    max_target_level,
    spell_class_set,
    spell_class_mask_0,
    spell_class_mask_1,
    spell_class_mask_2,
    max_targets,
    defense_type,
    prevention_type,
    stance_bar_order,
    effect_chain_amplitude_0,
    effect_chain_amplitude_1,
    effect_chain_amplitude_2,
    min_faction_id,
    min_reputation,
    required_aura_vision,
    required_totem_category_id_0,
    required_totem_category_id_1,
    required_areas_id,
    school_mask,
    rune_cost_id,
    spell_missile_id,
    power_display_id,
    effect_bonus_coefficient_0,
    effect_bonus_coefficient_1,
    effect_bonus_coefficient_2,
    description_variables_id,
    difficulty
)
VALUES

    (
        360007,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        3063,
     0,0,
     'Fiery Tempest',
     '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
     'Causes all your mage type periodic spells to benefit from spell haste and crit chance.',
     '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
     3,
     0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360008,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        2774,
        0,0,
        'Bloody Rampage',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your warrior based periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        4,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360009,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        3222,
        0,0,
        'The Silent Killer',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your roguish periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        8,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360010,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        3033,
        0,0,
        'The Coming Judgement',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your priestly periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        6,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360011,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        2017,
        0,0,
        'Force of Nature',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your shamanic periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        11,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360012,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        2317,
        0,0,
        'Creeping Death',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your druidic periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        7,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360013,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        2206,
        0,0,
        'Suffering',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your warlock-based periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        5,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360014,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        3377,
        0,0,
        'The Survivalist',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your hunter periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        9,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360015,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        2268,
        0,0,
        'Divine Storm',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your paladin-based periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        10,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    ),
    (
        360016,
        0,0,0,464,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,101,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,6,6,0,1,1,0,0,0,0,99,99,0,0,0,0,1,1,0,0,0,0,0,0,0,286,316,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,pow(2,28),0,0,pow(2,28),0,0,0,0,0,
        4160,
        0,0,
        'The Inevitable Death',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,
        'Causes all your death knight periodic spells to benefit from spell haste and crit chance.',
        '','','','','','','','','','','','','','','',16712190,'','','','','','','','','','','','','','','','',16712190,0,0,0,0,
        15,
        0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
    );

-- delete from spell where id  in (360016,360015,360014,360013,360012,360011,360010,360009,360008,360007);
--
-- select id,Spell.name_lang_en_gb,Spell.shapeshift_mask_0,Spell.shapeshift_mask_1,Spell.shapeshift_exclude_0,Spell.shapeshift_exclude_1,attributes,attributes_ex, attributes_ex_b, attributes_ex_c, attributes_ex_d, attributes_ex_e, attributes_ex_f, attributes_ex_g
-- from spell where id in (71167, 20042, 360015, 58284,774,25780);
--
-- select * from spell where id = 20042;
--
-- select id from spell where (CAST(spell_class_mask_2 AS BIT) & pow(2,28)) = pow(2,28);

--
-- select id, name_lang_en_gb, name_subtext_lang_en_gb
-- from spell
-- where (effect_aura_0 in (3,8) or effect_aura_1 in (3,8) or effect_aura_2 in (3,8))
--   and name_subtext_lang_en_gb <> ''
--   and spell_class_set in (3,4,5,6,7,8,9,10,11,15)
-- order by Spell.spell_class_set,name_lang_en_gb;

update spell
set spell_class_mask_2 = spell_class_mask_2 | pow(2,28)
where (effect_aura_0 in (3,8) or effect_aura_1 in (3,8) or effect_aura_2 in (3,8))
  and name_subtext_lang_en_gb <> ''
  and spell_class_set in (3,4,5,6,7,8,9,10,11,15);

-- update spell
-- set spell_class_mask_2 = spell_class_mask_2 & ~pow(2,28)
-- where (effect_aura_0 in (3,8) or effect_aura_1 in (3,8) or effect_aura_2 in (3,8))
--   and name_subtext_lang_en_gb <> ''
--   and spell_class_set in (3,4,5,6,7,8,9,10,11,15);



-- delete from spell where id  in (360016,360015,360014,360013,360012,360011,360010,360009,360008,360007);

insert into talent values(2287,41,0,3,360007,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2288,161,0,3,360008,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2289,181,0,3,360009,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2290,201,0,3,360010,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2291,261,0,3,360011,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2292,281,0,3,360012,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2293,301,0,3,360013,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2294,361,0,3,360014,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2295,381,0,3,360015,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         ),
                         (2296,398,0,3,360016,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                         );

-- delete from talent where id in (2287,2288,2289,2290,2291,2292,2293,2294,2295,2296);

-- select max(effect_0), id from Spell;
--
-- select max(id) from Talent;
-- select talenttab.name_lang_en_gb,talent.* from Talent join TalentTab on Talent.tab_id = TalentTab.id group by name_lang_en_gb;
-- select * from Talent join TalentTab on Talent.tab_id = TalentTab.id where Talent.id in (2287,2288,2289,2290,2291,2292,2293,2294,2295,2296);

-- id starting from 360007
-- Mage: Fire - spell_class_set=3 - 360007 - 41
-- Warrior: Arms - spell_class_set=4 - 360008 - 161
-- Rogue: Combat - spell_class_set=8 - 360009 - 181
-- Priest: Discipline - spell_class_set=6 - 360010 - 201
-- Shaman: Elemental - spell_class_set=11 - 360011 - 261
-- Druid: Feral - spell_class_set=7 - 360012 - 281
-- Warlock: Destruction - spell_class_set=5 - 360013 - 301
-- Hunter: Beast Mastery - spell_class_set=9 - 360014 - 361
-- Paladin: Retribution - spell_class_set=10 - 360015 - 381
-- Death Knight: Blood - spell_class_set=15 - 360016 - 398

-- Modify Battle Stance, Berserker Stance, and Defensive Stance to allow for Bloody Rampage
-- Modify Stealth and Vanish to allow for Silent Killer
-- Modify Shadowform to allow for The Coming Judgement
-- Druid: Bear Form, Dire Bear Form, Cat Form, Aquatic Form, Travel Form, Flight Form, and Swift Flight Form, Boomkin, and Tree of Life
-- Warlock: Metamorphosis - Make metamorphosis not be canceled? Maybe buff demon form?
-- Paladin: Auras, Righteous Fury
-- Hunter: Aspects
--
