# select name_lang_en_gb, equipped_item_subclass from spell where name_lang_en_gb like 'Enchant Weapon%';
update spell set equipped_item_subclass = -1 where name_lang_en_gb like 'Enchant Weapon%';