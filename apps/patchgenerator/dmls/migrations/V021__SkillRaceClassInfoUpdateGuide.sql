select display_name_lang_en_gb, SkillLineCategory.name_lang_en_gb, skill_id, SkillRaceClassInfo.id,flags, race_mask, class_mask
from SkillRaceClassInfo
join SkillLine on SkillRaceClassInfo.skill_id=SkillLine.id
join SkillLineCategory on category_id=SkillLineCategory.id
WHERE SkillLineCategory.name_lang_en_gb like 'Languages'
-- Where SkillRaceClassInfo.skill_id = 134
-- WHERE display_name_lang_en_gb like '%First%' or display_name_lang_en_gb like '%Fishing%'
ORDER BY  skill_id;

select * from SkillLine where id = 205;

select * from SkillRaceClassInfo;
select * from SkillRaceClassInfo where skill_id in (109,98);
-- There must be two language entries, a skill tier 0 and skill tier 21
insert into SkillRaceClassInfo values (181,109, -1, -1, 128, 0,0,0);

select display_name_lang_en_gb, SkillLineAbility.id, race_mask, class_mask from SkillLineAbility
join SkillLine on skill_line=SkillLine.id
ORDER BY  display_name_lang_en_gb;

-- These corrections are because I goofed the file originally
-- update SkillRaceClassInfo set flags = 2048 where skill_id = 205;
-- update SkillRaceClassInfo set flags = 128 where skill_id = 356;
-- update SkillRaceClassInfo set flags = 128 where skill_id = 129;
-- update SkillRaceClassInfo set flags = 128 where skill_id = 185;

update SkillRaceClassInfo
Set flags = 1040
where id in (select SkillRaceClassInfo.id
             from SkillRaceClassInfo
                 join SkillLine on SkillRaceClassInfo.skill_id=SkillLine.id
                 join SkillLineCategory on category_id=SkillLineCategory.id
                 where SkillLineCategory.name_lang_en_gb like 'Class Skills');

select SkillRaceClassInfo.id, SkillLine.display_name_lang_en_gb, SkillLineCategory.name_lang_en_gb, flags
from SkillRaceClassInfo
         join SkillLine on SkillRaceClassInfo.skill_id=SkillLine.id
         join SkillLineCategory on category_id=SkillLineCategory.id
where SkillLineCategory.name_lang_en_gb like 'Class Skills';

update SkillRaceClassInfo
Set flags = 128
where id in (select SkillRaceClassInfo.id
             from SkillRaceClassInfo
                      join SkillLine on SkillRaceClassInfo.skill_id=SkillLine.id
                      join SkillLineCategory on category_id=SkillLineCategory.id
             where SkillLineCategory.name_lang_en_gb like 'Languages');

