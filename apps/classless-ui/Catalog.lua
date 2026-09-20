-- Shared classless UI catalog.
-- Header data lives here. Spell first-ranks and talent grids are filled later
-- from Spell.dbc / Talent.dbc exports. Rank chains are NOT stored here;
-- the server expands them from Spell.dbc.
--
-- This file is loaded by Eluna on the server (global ClasslessUICatalog) and
-- registered with AIO so the client gets the same table.

ClasslessUICatalog = {
    -- XML order, DBC class ids (Druid is 11, not 10).
    classOrder = { 6, 11, 3, 8, 2, 5, 4, 7, 9, 1 },

    -- Extra header tabs that do not rewrite with class.
    extraTabs = {
        { id = "glyph", name = "Glyph", icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
        { id = "pet",   name = "Pet",   icon = "Interface\\Icons\\Ability_Hunter_BeastTaming" },
    },

    -- Not player-trainable (triggered effects, extra "ranks" that share a name).
    blockedSpells = {
        [42651] = true, -- Army of the Dead ghoul-summon trigger, not rank 2
    },

    classes = {},
    spells = {},  -- [classId][specId] = { { first = spellId }, ... }
    talents = {}, -- [tabId] = { { id, tier, column, ranks = {}, prereq }, ... }
    -- TalentTab.dbc background_file (Interface\\TalentFrame\\<name>-TopLeft etc.)
    tabBg = {
        [41] = "MageFire",
        [61] = "MageFrost",
        [81] = "MageArcane",
        [161] = "WarriorArms",
        [163] = "WarriorProtection",
        [164] = "WarriorFury",
        [181] = "RogueCombat",
        [182] = "RogueAssassination",
        [183] = "RogueSubtlety",
        [201] = "PriestDiscipline",
        [202] = "PriestHoly",
        [203] = "PriestShadow",
        [261] = "ShamanElementalCombat",
        [262] = "ShamanRestoration",
        [263] = "ShamanEnhancement",
        [281] = "DruidFeralCombat",
        [282] = "DruidRestoration",
        [283] = "DruidBalance",
        [301] = "WarlockDestruction",
        [302] = "WarlockCurses",
        [303] = "WarlockSummoning",
        [361] = "HunterBeastMastery",
        [362] = "HunterSurvival",
        [363] = "HunterMarksmanship",
        [381] = "PaladinCombat",
        [382] = "PaladinHoly",
        [383] = "PaladinProtection",
        [398] = "DeathKnightBlood",
        [399] = "DeathKnightFrost",
        [400] = "DeathKnightUnholy",
        [409] = "HunterPetTenacity",
        [410] = "HunterPetFerocity",
        [411] = "HunterPetCunning",
    },
}

local C = ClasslessUICatalog.classes

local function spec(id, name, icon, tabId)
    return { id = id, name = name, icon = icon, tabId = tabId }
end

local function cls(id, name, icon, s1, s2, s3)
    C[id] = {
        id = id,
        name = name,
        icon = icon,
        specs = {
            s1,
            s2,
            s3,
        },
    }
end

cls(6, "Death Knight", "Interface\\Icons\\Spell_Deathknight_ClassIcon",
    spec("blood",  "Blood",  "Interface\\Icons\\Spell_Deathknight_BloodPresence",  398),
    spec("frost",  "Frost",  "Interface\\Icons\\Spell_Deathknight_FrostPresence",  399),
    spec("unholy", "Unholy", "Interface\\Icons\\Spell_Deathknight_UnholyPresence", 400))

cls(11, "Druid", "Interface\\Icons\\Ability_Druid_Maul",
    spec("balance", "Balance",      "Interface\\Icons\\Spell_Nature_StarFall",      283),
    spec("feral",   "Feral",        "Interface\\Icons\\Ability_Racial_BearForm",    281),
    spec("resto",   "Restoration",  "Interface\\Icons\\Spell_Nature_HealingTouch",  282))

cls(3, "Hunter", "Interface\\Icons\\INV_Weapon_Bow_07",
    spec("bm",       "Beast Mastery", "Interface\\Icons\\Ability_Hunter_BeastTaming", 361),
    spec("marks",    "Marksmanship",  "Interface\\Icons\\Ability_Marksmanship",       363),
    spec("survival", "Survival",      "Interface\\Icons\\Ability_Hunter_SwiftStrike", 362))

cls(8, "Mage", "Interface\\Icons\\INV_Staff_13",
    spec("arcane", "Arcane", "Interface\\Icons\\Spell_Holy_MagicalSentry", 81),
    spec("fire",   "Fire",   "Interface\\Icons\\Spell_Fire_FireBolt02",    41),
    spec("frost",  "Frost",  "Interface\\Icons\\Spell_Frost_FrostBolt02",  61))

cls(2, "Paladin", "Interface\\Icons\\Spell_Holy_DevotionAura",
    spec("holy", "Holy",        "Interface\\Icons\\Spell_Holy_HolyBolt",     382),
    spec("prot", "Protection",  "Interface\\Icons\\Spell_Holy_DevotionAura", 383),
    spec("ret",  "Retribution", "Interface\\Icons\\Spell_Holy_AuraOfLight",  381))

cls(5, "Priest", "Interface\\Icons\\INV_Staff_30",
    spec("disc",   "Discipline", "Interface\\Icons\\Spell_Holy_WordFortitude",     201),
    spec("holy",   "Holy",       "Interface\\Icons\\Spell_Holy_HolyBolt",          202),
    spec("shadow", "Shadow",     "Interface\\Icons\\Spell_Shadow_ShadowWordPain",  203))

cls(4, "Rogue", "Interface\\Icons\\INV_ThrowingKnife_04",
    spec("assassination", "Assassination", "Interface\\Icons\\Ability_Rogue_Eviscerate", 182),
    spec("combat",        "Combat",        "Interface\\Icons\\Ability_BackStab",         181),
    spec("subtlety",      "Subtlety",      "Interface\\Icons\\Ability_Stealth",          183))

cls(7, "Shaman", "Interface\\Icons\\Spell_Nature_BloodLust",
    spec("elemental",   "Elemental",    "Interface\\Icons\\Spell_Nature_Lightning",       261),
    spec("enhancement", "Enhancement",  "Interface\\Icons\\Spell_Nature_LightningShield", 263),
    spec("resto",       "Restoration",  "Interface\\Icons\\Spell_Nature_MagicImmunity",   262))

cls(9, "Warlock", "Interface\\Icons\\Spell_Nature_FaerieFire",
    spec("affliction",  "Affliction",  "Interface\\Icons\\Spell_Shadow_DeathCoil",       302),
    spec("demonology",  "Demonology",  "Interface\\Icons\\Spell_Shadow_Metamorphosis",   303),
    spec("destruction", "Destruction", "Interface\\Icons\\Spell_Shadow_RainOfFire",      301))

cls(1, "Warrior", "Interface\\Icons\\INV_Sword_27",
    spec("arms", "Arms",       "Interface\\Icons\\Ability_Rogue_Eviscerate", 161),
    spec("fury", "Fury",       "Interface\\Icons\\Ability_Warrior_InnerRage", 164),
    spec("prot", "Protection", "Interface\\Icons\\INV_Shield_06",             163))

local AIO = AIO or require("AIO")
if AIO.IsMainState and AIO.IsMainState() and AIO.AddAddon then
    AIO.AddAddon()
end
