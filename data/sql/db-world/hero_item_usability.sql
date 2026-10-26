-- Hero class (class ID 10, class mask 512) can use every item. Idempotent: safe to re-run.
--
-- 1) Class-restricted items: add the Hero bit. update_item_templates.sql sets every item to -1
--    (all classes), but items imported later (e.g. the custom 2,039,xxx+ tier/PvP copies on Standard)
--    keep their original single-class masks, and masks written before Hero existed (1535, the old
--    "all ten classes" value) leave bit 512 out. -1 already includes Hero and is left alone.
UPDATE `item_template`
SET `AllowableClass` = `AllowableClass` | 512
WHERE `AllowableClass` <> -1 AND (`AllowableClass` & 512) = 0;

-- 2) Old (pre-2.0) PvP rank gear (Knight-Lieutenant's, Marshal's, General's, ...): RequiredHonorRank
--    is checked by the 3.3.5 client against a rank system that no longer exists, so nobody (Hero
--    included) can equip it ("You don't have the required rank for that item"). Blizzard removed
--    the requirement in 2.0; do the same.
UPDATE `item_template` SET `RequiredHonorRank` = 0 WHERE `RequiredHonorRank` <> 0;
