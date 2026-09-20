#include "ClasslessPlayerScripts.h"
#include "ClasslessTalent.h"
#include "Player.h"
#include "Config.h"
#include "Chat.h"
#include "DBCStores.h"
#include "SpellMgr.h"
#include "AchievementMgr.h"
#include "SpellAuraEffects.h"
#include "Unit.h"

enum MyPlayerAcoreString {
    HELLO_WORLD = 35410
};

ClasslessPlayerScripts::ClasslessPlayerScripts() : PlayerScript("ClasslessPlayerScript") {
}

void ClasslessPlayerScripts::SetTalentYieldAchievements(std::unordered_set<uint32> ids) {
    achievements_which_yield_talents_ = std::move(ids);
}

void ClasslessPlayerScripts::OnPlayerLogin(Player *player) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false))
        ChatHandler(player->GetSession()).PSendSysMessage(HELLO_WORLD);
}

Optional<bool> ClasslessPlayerScripts::OnPlayerIsClass(Player const *, Classes classes, ClassContext context) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        switch (context) {
            case CLASS_CONTEXT_QUEST:
            case CLASS_CONTEXT_TAXI:
            case CLASS_CONTEXT_TALENT_POINT_CALC:
            case CLASS_CONTEXT_ABILITY:
            case CLASS_CONTEXT_ABILITY_REACTIVE:
            case CLASS_CONTEXT_EQUIP_RELIC:
            case CLASS_CONTEXT_EQUIP_SHIELDS:
            case CLASS_CONTEXT_EQUIP_ARMOR_CLASS:
            case CLASS_CONTEXT_WEAPON_SWAP:
            case CLASS_CONTEXT_CLASS_TRAINER:
             // 233 of Pet.cpp might be an issue, not sure if we can allow Death Knight broadly, it might short circuit
                return true;
            case CLASS_CONTEXT_PET:
                if (classes == CLASS_DEATH_KNIGHT) return std::nullopt;
                return true;
            default:
                return std::nullopt;
        }
    }
    return std::nullopt;
}

bool ClasslessPlayerScripts::OnPlayerLearnTalentUseAlternativeLogic(Player *player, uint32 talentId, uint32 talentRank,
                                                                    bool command) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        // ... original logic kept unchanged ...
        uint32 CurTalentPoints = player->GetFreeTalentPoints();
        if (!command) {
            if (!CurTalentPoints) return true;
            if (talentRank >= MAX_TALENT_RANK) return true;
        }

        TalentEntry const *talentInfo = sTalentStore.LookupEntry(talentId);
        if (!talentInfo) return true;

        TalentTabEntry const *talentTabInfo = sTalentTabStore.LookupEntry(talentInfo->TalentTab);
        if (!talentTabInfo) return true;

        // Classless: other-class trees are valid. Do not swallow the learn.
        uint32 currentTalentRank = Classless_KnownTalentRank(player, talentId);

        if (currentTalentRank >= talentRank + 1) return true;

        uint32 talentPointsChange = (talentRank - currentTalentRank + 1);
        if (!command && CurTalentPoints < talentPointsChange) return true;

        // Classless: no arrow prereqs. Unlock is 5 × row points spent anywhere
        // in this tree (TalentEntry::Row is 0-based).
        if (!command && talentInfo->Row > 0) {
            uint32 spentPoints = 0;
            for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i) {
                TalentEntry const* other = sTalentStore.LookupEntry(i);
                if (!other || other->TalentTab != talentInfo->TalentTab)
                    continue;
                spentPoints += Classless_KnownTalentRank(player, other->TalentID);
            }
            if (spentPoints < (talentInfo->Row * MAX_TALENT_RANK)) return true;
        }

        uint32 spellId = talentInfo->RankID[talentRank];
        if (!spellId) return true;

        SpellInfo const *spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!spellInfo) return true;

        bool learned = false;
        if (talentInfo->addToSpellBook)
            if (!spellInfo->HasAttribute(SPELL_ATTR0_PASSIVE) && !spellInfo->HasEffect(SPELL_EFFECT_LEARN_SPELL)) {
                player->learnSpell(spellId);
                learned = true;
            }

        if (!learned) player->SendLearnPacket(spellId, true);

        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (spellInfo->Effects[i].Effect == SPELL_EFFECT_LEARN_SPELL)
                if (sSpellMgr->IsAdditionalTalentSpell(spellInfo->Effects[i].TriggerSpell))
                    player->learnSpell(spellInfo->Effects[i].TriggerSpell);

        player->addTalent(spellId, player->GetActiveSpecMask(), currentTalentRank);

        if (!command) player->SetFreeTalentPoints(CurTalentPoints - talentPointsChange);

        sScriptMgr->OnPlayerLearnTalents(player, talentId, talentRank, spellId);
        return true;
    }
    return false;
}

void ClasslessPlayerScripts::OnPlayerCalculateTalentsPoints(Player const *player, uint32 &talentPointsForLevel) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        uint32 talentPoints = player->GetLevel();
        CompletedAchievementMap const &completed = player->GetAchievementMgr()->GetCompletedAchievements();
        for (auto const &kv: completed)
            if (achievements_which_yield_talents_.find(kv.first) != achievements_which_yield_talents_.end())
                ++talentPoints;
        talentPointsForLevel = talentPoints;
    }
}

bool ClasslessPlayerScripts::OnUpdateAttackPowerAndDamageReplaceWithAlternativeCalculation(
    Player *player, bool ranged) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        float baseAttackPower = 0.0f;
        float level = float(player->GetLevel());

        sScriptMgr->OnPlayerBeforeUpdateAttackPowerAndDamage(player, level, baseAttackPower, ranged);

        UnitMods unitMod = ranged ? UNIT_MOD_ATTACK_POWER_RANGED : UNIT_MOD_ATTACK_POWER;

        uint16 index = UNIT_FIELD_ATTACK_POWER;
        uint16 index_mod = UNIT_FIELD_ATTACK_POWER_MODS;
        uint16 index_mult = UNIT_FIELD_ATTACK_POWER_MULTIPLIER;

        if (ranged) {
            index = UNIT_FIELD_RANGED_ATTACK_POWER;
            index_mod = UNIT_FIELD_RANGED_ATTACK_POWER_MODS;
            index_mult = UNIT_FIELD_RANGED_ATTACK_POWER_MULTIPLIER;

            switch (player->GetShapeshiftForm()) {
                case FORM_CAT:
                case FORM_BEAR:
                case FORM_DIREBEAR:
                    baseAttackPower = 0.0f;
                    break;
                default:
                    baseAttackPower = baseAttackPower = level * 2.0f + player->GetStat(STAT_AGILITY) - 10.0f;
                    break;
            }
        } else {
            float mLevelMult = 0.0f;
            float weapon_bonus = 0.0f;
            if (player->IsInFeralForm()) {
                Unit::AuraEffectList const &mDummy = player->GetAuraEffectsByType(SPELL_AURA_DUMMY);
                for (Unit::AuraEffectList::const_iterator itr = mDummy.begin(); itr != mDummy.end(); ++itr) {
                    AuraEffect *aurEff = *itr;
                    if (aurEff->GetSpellInfo()->SpellIconID == 1563) {
                        switch (aurEff->GetEffIndex()) {
                            case 0: // Predatory Strikes (effect 0)
                                mLevelMult = CalculatePct(1.0f, aurEff->GetAmount());
                                break;
                            case 1: // Predatory Strikes (effect 1)
                                if (Item *mainHand = player->GetItemByPos(EQUIPMENT_SLOT_MAINHAND)) {
                                    // also gains % attack power from equipped weapon
                                    ItemTemplate const *proto = mainHand->GetTemplate();
                                    if (!proto)
                                        continue;

                                    uint32 ap = proto->getFeralBonus();
                                    // Get AP Bonuses from weapon
                                    for (uint8 i = 0; i < MAX_ITEM_PROTO_STATS; ++i) {
                                        if (i >= proto->StatsCount)
                                            break;

                                        if (proto->ItemStat[i].ItemStatType == ITEM_MOD_ATTACK_POWER)
                                            ap += proto->ItemStat[i].ItemStatValue;
                                    }

                                    // Get AP Bonuses from weapon spells
                                    for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i) {
                                        // no spell
                                        if (!proto->Spells[i].SpellId || proto->Spells[i].SpellTrigger !=
                                            ITEM_SPELLTRIGGER_ON_EQUIP)
                                            continue;

                                        // check if it is valid spell
                                        SpellInfo const *spellproto = sSpellMgr->GetSpellInfo(proto->Spells[i].SpellId);
                                        if (!spellproto)
                                            continue;

                                        for (uint8 j = 0; j < MAX_SPELL_EFFECTS; ++j)
                                            if (spellproto->Effects[j].ApplyAuraName == SPELL_AURA_MOD_ATTACK_POWER)
                                                ap += spellproto->Effects[j].CalcValue();
                                    }

                                    weapon_bonus = CalculatePct(float(ap), aurEff->GetAmount());
                                }
                                break;
                            default:
                                mLevelMult = CalculatePct(1.0f, aurEff->GetAmount());
                                break;
                        }
                    }
                }
            }
            switch (player->GetShapeshiftForm()) {
                case FORM_CAT:
                case FORM_BEAR:
                case FORM_DIREBEAR:
                    baseAttackPower = (player->GetLevel() * mLevelMult) + player->GetStat(STAT_STRENGTH) * 1.5f + player->GetStat(STAT_AGILITY) * 1.5f - 20.0f + weapon_bonus
                    + player->GetFeralAPBonus();
                    break;
                case FORM_MOONKIN:
                    baseAttackPower = (player->GetLevel() * mLevelMult) + player->GetStat(STAT_STRENGTH) * 1.5f + player->GetStat(STAT_AGILITY) * 1.5f - 20.0f
                    + player->GetFeralAPBonus();
                    break;
                default:
                    baseAttackPower = level * 3.0f + player->GetStat(STAT_STRENGTH) * 1.5f + player->GetStat(STAT_AGILITY) * 1.5f  - 20.0f;
                    break;
            }
        }

        player->SetStatFlatModifier(unitMod, BASE_VALUE, baseAttackPower);

        float base_attPower = player->GetFlatModifierValue(unitMod, BASE_VALUE) * player->GetPctModifierValue(unitMod, BASE_PCT);
        float attPowerMod = player->GetFlatModifierValue(unitMod, TOTAL_VALUE);

        //add dynamic flat mods
        if (ranged) {
            std::vector<AuraEffect*> const &mRAPbyStat = player->GetAuraEffectsByType(SPELL_AURA_MOD_RANGED_ATTACK_POWER_OF_STAT_PERCENT);
            for (std::vector<AuraEffect*>::const_iterator i = mRAPbyStat.begin(); i != mRAPbyStat.end(); ++i)
                attPowerMod += CalculatePct(player->GetStat(Stats((*i)->GetMiscValue())), (*i)->GetAmount());

            std::vector<AuraEffect*> const &mAPbyArmor = player->GetAuraEffectsByType(SPELL_AURA_MOD_ATTACK_POWER_OF_ARMOR);
            for (std::vector<AuraEffect*>::const_iterator iter = mAPbyArmor.begin(); iter != mAPbyArmor.end(); ++iter)
                // always: ((*i)->GetModifier()->m_miscvalue == 1 == SPELL_SCHOOL_MASK_NORMAL)
                    attPowerMod += int32(player->GetArmor() / (*iter)->GetAmount());
        } else {
            std::vector<AuraEffect*> const &mAPbyStat = player->GetAuraEffectsByType(SPELL_AURA_MOD_ATTACK_POWER_OF_STAT_PERCENT);
            for (std::vector<AuraEffect*>::const_iterator i = mAPbyStat.begin(); i != mAPbyStat.end(); ++i)
                attPowerMod += CalculatePct(player->GetStat(Stats((*i)->GetMiscValue())), (*i)->GetAmount());

            std::vector<AuraEffect*> const &mAPbyArmor = player->GetAuraEffectsByType(SPELL_AURA_MOD_ATTACK_POWER_OF_ARMOR);
            for (std::vector<AuraEffect*>::const_iterator iter = mAPbyArmor.begin(); iter != mAPbyArmor.end(); ++iter)
                // always: ((*i)->GetModifier()->m_miscvalue == 1 == SPELL_SCHOOL_MASK_NORMAL)
                    attPowerMod += int32(player->GetArmor() / (*iter)->GetAmount());
        }

        float attPowerMultiplier = player->GetPctModifierValue(unitMod, TOTAL_PCT) - 1.0f;

        sScriptMgr->OnPlayerAfterUpdateAttackPowerAndDamage(player, level, base_attPower, attPowerMod, attPowerMultiplier,
                                                            ranged);
        player->SetInt32Value(index, (uint32) base_attPower); //UNIT_FIELD_(RANGED)_ATTACK_POWER field
        player->SetInt32Value(index_mod, (uint32) attPowerMod); //UNIT_FIELD_(RANGED)_ATTACK_POWER_MODS field
        player->SetFloatValue(index_mult, attPowerMultiplier); //UNIT_FIELD_(RANGED)_ATTACK_POWER_MULTIPLIER field

        //automatically update weapon damage after attack power modification
        if (ranged) {
            player->UpdateDamagePhysical(RANGED_ATTACK);
        } else {
            player->UpdateDamagePhysical(BASE_ATTACK);
            if (player->CanDualWield() && player->HasOffhandWeaponForAttack())
                //allow update offhand damage only if player knows DualWield Spec and has equipped offhand weapon
                    player->UpdateDamagePhysical(OFF_ATTACK);
            player->UpdateSpellDamageAndHealingBonus();
        }
        return true;
    }
    return false;
}

bool ClasslessPlayerScripts::OnPlayerHasActivePowerType(Player const */*player*/, Powers /*power*/) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        return true;
    }
    return false;
}

bool ClasslessPlayerScripts::OnPlayerUpdateParryUseAlternative(Player* player) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        player->SetCanParry(true);
        const float parry_cap = 145.560408f;
        const float m_diminishing_k =  0.9880f;

        // No parry
        float value = 0.0f;
        float m_realParry = 0.0f;

        float nondiminishing = 5.0f;
        // Parry from rating
        float diminishing = player->GetRatingBonusValue(CR_PARRY);
        // Modify value from defense skill (only bonus from defense rating diminishes)
        nondiminishing += (player->GetSkillValue(SKILL_DEFENSE) - player->GetMaxSkillValueForLevel()) * 0.04f;
        diminishing += (int32(player->GetRatingBonusValue(CR_DEFENSE_SKILL))) * 0.04f;
        // Parry from SPELL_AURA_MOD_PARRY_PERCENT aura
        nondiminishing += player->GetTotalAuraModifier(SPELL_AURA_MOD_PARRY_PERCENT);
        // apply diminishing formula to diminishing parry chance
        m_realParry = nondiminishing + diminishing * parry_cap / (
                          diminishing + parry_cap * m_diminishing_k);
        m_realParry = m_realParry < 0.0f ? 0.0f : m_realParry;

        value = std::max(diminishing + nondiminishing, 0.0f);

        if (sConfigMgr->GetOption<bool>("Stats.Limits.Enable", false)) {
            value = value > sConfigMgr->GetOption<float>("Stats.Limits.Parry", 95.0f)
                        ? sConfigMgr->GetOption<float>("Stats.Limits.Parry", 95.0f)
                        : value;

        }
        player->SetRealParry(m_realParry);
        player->SetStatFloatValue(PLAYER_PARRY_PERCENTAGE, value);
        return true;
    }
    return false;
}

bool ClasslessPlayerScripts::OnPlayerUpdateDodgeUseAlternative(Player *player) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        const float dodge_cap = 150.375940f;
        const float m_diminishing_k =  0.9880f;
        float m_realDodge = player->GetFloatValue(PLAYER_DODGE_PERCENTAGE);

        float diminishing = 0.0f, nondiminishing = 0.0f;

        const float dodge_base = 0.056097f;
        const float crit_to_dodge = 2.00f / 1.15f;

        uint8 level = player->GetLevel();
        uint32 pclass = player->getClass();

        if (level > GT_MAX_LEVEL)
            level = GT_MAX_LEVEL;

        // Dodge per agility is proportional to crit per agility, which is available from DBC files
        GtChanceToMeleeCritEntry  const* dodgeRatio = sGtChanceToMeleeCritStore.LookupEntry((pclass - 1) * GT_MAX_LEVEL + level - 1);
        if (!dodgeRatio || pclass > MAX_CLASSES)
            return false;

        float base_agility = player->GetCreateStat(STAT_AGILITY) * player->GetPctModifierValue(UnitMods(UNIT_MOD_STAT_START + AsUnderlyingType(STAT_AGILITY)), BASE_PCT);
        float bonus_agility = player->GetStat(STAT_AGILITY) - base_agility;

        // calculate diminishing (green in char screen) and non-diminishing (white) contribution
        diminishing = 100.0f * bonus_agility * dodgeRatio->ratio * crit_to_dodge;
        nondiminishing = 100.0f * (dodge_base + base_agility * dodgeRatio->ratio * crit_to_dodge);

        // Modify value from defense skill (only bonus from defense rating diminishes)
        nondiminishing += (player->GetSkillValue(SKILL_DEFENSE) - player->GetMaxSkillValueForLevel()) * 0.04f;
        diminishing += (int32(player->GetRatingBonusValue(CR_DEFENSE_SKILL))) * 0.04f;
        // Dodge from SPELL_AURA_MOD_DODGE_PERCENT aura
        nondiminishing += player->GetTotalAuraModifier(SPELL_AURA_MOD_DODGE_PERCENT);
        // Dodge from rating
        diminishing += player->GetRatingBonusValue(CR_DODGE);
        // apply diminishing formula to diminishing dodge chance
        m_realDodge = nondiminishing + (diminishing * dodge_cap / (
                                            diminishing + dodge_cap * m_diminishing_k));

        m_realDodge = m_realDodge < 0.0f ? 0.0f : m_realDodge;
        float value = std::max(diminishing + nondiminishing, 0.0f);

        if (sConfigMgr->GetOption<bool>("Stats.Limits.Enable", false)) {
            value = value > sConfigMgr->GetOption<float>("Stats.Limits.Dodge", 95.0f)
                        ? sConfigMgr->GetOption<float>("Stats.Limits.Dodge", 95.0f)
                        : value;
        }
        player->SetRealDodge(m_realDodge);
        player->SetStatFloatValue(PLAYER_DODGE_PERCENTAGE, value);
    }
    return false;
}

void ClasslessPlayerScripts::OnPlayerBeforeGuardianInitStatsForLevel(Player* /*player*/, Guardian* guardian, CreatureTemplate const* cinfo, PetType& petType) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        if (guardian->IsPet()) {
            switch (cinfo->Entry) {
                case NPC_IMP:
                case NPC_VOIDWALKER:
                case NPC_FELGUARD:
                case NPC_FELHUNTER:
                case NPC_SUCCUBUS:
                case NPC_RISEN_GHOUL:
                case NPC_WATER_ELEMENTAL_PERM:
                    petType = SUMMON_PET;
                    break;
                default:
                    petType = HUNTER_PET;
                    break;
            }
        }
    }
}

void ClasslessPlayerScripts::OnPlayerAfterGuardianInitStatsForLevel(Player *, Guardian *guardian) {
    if (sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false)) {
        // -- 8875, 19580, 19581, 19582, 19589, 19590, 34666, 34667, 34675, 55566
        if (guardian->IsPet()) {
            if (!guardian->IsHunterPet()) { // Add Hunter Pet Scaling Auras
                if (!guardian->HasAura(8875)) guardian->AddAura(8875, guardian);  // Total Damage Done
                if (!guardian->HasAura(19580)) guardian->AddAura(19580, guardian); // Base Armor Percent
                if (!guardian->HasAura(19581)) guardian->AddAura(19581, guardian); // Max Health
                if (!guardian->HasAura(19582)) guardian->AddAura(19582, guardian); // Speed
                if (!guardian->HasAura(19589)) guardian->AddAura(19589, guardian); // Focus Regeneration
                if (!guardian->HasAura(19590)) guardian->AddAura(19590, guardian); // Critical Strike Chance
                if (!guardian->HasAura(34666)) guardian->AddAura(34666, guardian); // Chance to Hit
                if (!guardian->HasAura(34667)) guardian->AddAura(34667, guardian); // Dodge Chance
                if (!guardian->HasAura(34675)) guardian->AddAura(34675, guardian); // Attack Speed
                if (!guardian->HasAura(55566)) guardian->AddAura(55566, guardian); // All Element Resistance
            }
            if (guardian->GetEntry() != NPC_IMP &&
                guardian->GetEntry() != NPC_VOIDWALKER &&
                guardian->GetEntry() != NPC_FELGUARD &&
                guardian->GetEntry() != NPC_FELHUNTER &&
                guardian->GetEntry() != NPC_SUCCUBUS ) {

                // Damage Done
                if (!guardian->HasAura(18727)) guardian->AddAura(18727, guardian);
                if (!guardian->HasAura(18728)) guardian->AddAura(18728, guardian);
                if (!guardian->HasAura(18729)) guardian->AddAura(18729, guardian);
                if (!guardian->HasAura(18730)) guardian->AddAura(18730, guardian);
                if (!guardian->HasAura(30147)) guardian->AddAura(30147, guardian);

                // Stamina
                if (!guardian->HasAura(18735)) guardian->AddAura(18735, guardian);
                if (!guardian->HasAura(18736)) guardian->AddAura(18736, guardian);
                if (!guardian->HasAura(18737)) guardian->AddAura(18737, guardian);
                if (!guardian->HasAura(18738)) guardian->AddAura(18738, guardian);
                if (!guardian->HasAura(30148)) guardian->AddAura(30148, guardian);

                // Intellect
                if (!guardian->HasAura(18739)) guardian->AddAura(18739, guardian);
                if (!guardian->HasAura(18740)) guardian->AddAura(18740, guardian);
                if (!guardian->HasAura(18741)) guardian->AddAura(18741, guardian);
                if (!guardian->HasAura(18742)) guardian->AddAura(18742, guardian);
                if (!guardian->HasAura(30149)) guardian->AddAura(30149, guardian);

                if (!guardian->HasAura(35697)) guardian->AddAura(35697, guardian); // % Damage reduction
            }
            if (guardian->GetEntry() != NPC_RISEN_GHOUL) {
                if (!guardian->HasAura(SPELL_DK_PET_SCALING_01)) guardian->AddAura(SPELL_DK_PET_SCALING_01, guardian);
                if (!guardian->HasAura(SPELL_DK_PET_SCALING_02)) guardian->AddAura(SPELL_DK_PET_SCALING_02, guardian);
                if (!guardian->HasAura(SPELL_DK_PET_SCALING_03)) guardian->AddAura(SPELL_DK_PET_SCALING_03, guardian);
            }
            // if (guardian->GetEntry() != NPC_FIRE_ELEMENTAL) {
            //     guardian->AddAura(SPELL_FIRE_ELEMENTAL_SCALING_01, guardian);
            //     guardian->AddAura(SPELL_FIRE_ELEMENTAL_SCALING_02, guardian);
            //     guardian->AddAura(SPELL_FIRE_ELEMENTAL_SCALING_03, guardian);
            //     guardian->AddAura(SPELL_FIRE_ELEMENTAL_SCALING_04, guardian);
            // }
            // if (guardian->GetEntry() != NPC_EARTH_ELEMENTAL) {
            //     guardian->AddAura(SPELL_EARTH_ELEMENTAL_SCALING_01, guardian);
            //     guardian->AddAura(SPELL_EARTH_ELEMENTAL_SCALING_02, guardian);
            //     guardian->AddAura(SPELL_EARTH_ELEMENTAL_SCALING_03, guardian);
            //     guardian->AddAura(SPELL_EARTH_ELEMENTAL_SCALING_04, guardian);
            // }

        }
    }
}



ClasslessPlayerScripts *AddClasslessPlayerScripts() {
    auto *cps = new ClasslessPlayerScripts(); // ScriptMgr takes ownership
    return cps;
}
