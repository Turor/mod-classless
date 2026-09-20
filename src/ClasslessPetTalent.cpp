#include "ClasslessPetTalent.h"
#include "ClasslessConfig.h"

#include "DBCStores.h"
#include "DBCStructure.h"
#include "Pet.h"
#include "PetDefines.h"
#include "Player.h"
#include "SpellMgr.h"

static constexpr uint32 PET_POINTS_PER_ROW = 3;
static constexpr uint32 PET_MAX_ROW = 15;

static Pet* ClasslessPet_Get(Player* player)
{
    if (!player)
        return nullptr;
    return player->GetPet();
}

static uint32 ClasslessPet_RankOf(Pet* pet, TalentEntry const* info)
{
    if (!pet || !info)
        return 0;
    uint32 rank = 0;
    for (uint8 i = 0; i < MAX_TALENT_RANK; ++i)
    {
        uint32 spellId = info->RankID[i];
        if (spellId && pet->HasSpell(spellId))
            rank = i + 1;
    }
    return rank;
}

static void ClasslessPet_BuildRowCounts(Pet* pet, uint32 tabId, uint32* counts)
{
    for (uint32 r = 0; r <= PET_MAX_ROW; ++r)
        counts[r] = 0;
    if (!pet)
        return;
    for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
    {
        TalentEntry const* info = sTalentStore.LookupEntry(i);
        if (!info || info->TalentTab != tabId)
            continue;
        uint32 rank = ClasslessPet_RankOf(pet, info);
        if (!rank)
            continue;
        uint32 row = info->Row;
        if (row > PET_MAX_ROW)
            continue;
        counts[row] += rank;
    }
}

static bool ClasslessPet_RowUnlocked(uint32 const* counts, uint32 row)
{
    if (row == 0)
        return true;
    return counts[row - 1] >= PET_POINTS_PER_ROW;
}

static bool ClasslessPet_HistogramLegal(uint32 const* counts)
{
    for (uint32 r = 1; r <= PET_MAX_ROW; ++r)
    {
        if (counts[r] > 0 && counts[r - 1] < PET_POINTS_PER_ROW)
            return false;
    }
    return true;
}

static void ClasslessPet_SyncPoints(Pet* pet)
{
    if (!pet)
        return;
    uint32 maxp = pet->GetMaxTalentPointsForLevel(pet->GetLevel());
    uint32 used = pet->m_usedTalentCount;
    uint32 remain = maxp > used ? maxp - used : 0;
    if (remain > 255)
        remain = 255;
    pet->SetFreeTalentPoints(uint8(remain));
}

static void ClasslessPet_Save(Player* player, Pet* pet)
{
    if (!player || !pet)
        return;
    ClasslessPet_SyncPoints(pet);
    pet->SavePetToDB(PET_SAVE_AS_CURRENT);
    if (player->IsInWorld())
        player->SendTalentsInfoData(true);
}

uint32 ClasslessPet_FreePoints(Player* player)
{
    if (!Classless_IsEnabled())
        return 0;
    Pet* pet = ClasslessPet_Get(player);
    if (!pet)
        return 0;
    ClasslessPet_SyncPoints(pet);
    return pet->GetFreeTalentPoints();
}

uint32 ClasslessPet_KnownRank(Player* player, uint32 talentId)
{
    Pet* pet = ClasslessPet_Get(player);
    TalentEntry const* info = sTalentStore.LookupEntry(talentId);
    return ClasslessPet_RankOf(pet, info);
}

bool ClasslessPet_Learn(Player* player, uint32 talentId, uint32 rank1Based)
{
    if (!Classless_IsEnabled() || !player || rank1Based < 1)
        return false;

    Pet* pet = ClasslessPet_Get(player);
    if (!pet)
        return false;

    TalentEntry const* talentInfo = sTalentStore.LookupEntry(talentId);
    if (!talentInfo)
        return false;

    TalentTabEntry const* talentTabInfo = sTalentTabStore.LookupEntry(talentInfo->TalentTab);
    if (!talentTabInfo || !talentTabInfo->petTalentMask)
        return false;

    CreatureTemplate const* ci = pet->GetCreatureTemplate();
    if (!ci)
        return false;
    CreatureFamilyEntry const* family = sCreatureFamilyStore.LookupEntry(ci->family);
    if (!family || family->petTalentType < 0)
        return false;
    if (!((1u << family->petTalentType) & talentTabInfo->petTalentMask))
        return false;

    uint32 talentRank = rank1Based - 1;
    if (talentRank >= MAX_PET_TALENT_RANK)
        return false;

    uint32 spellId = talentInfo->RankID[talentRank];
    if (!spellId)
        return false;

    uint32 current = ClasslessPet_RankOf(pet, talentInfo);
    if (current >= rank1Based)
        return false;
    if (rank1Based > current + 1)
        return false;

    ClasslessPet_SyncPoints(pet);
    if (pet->GetFreeTalentPoints() < 1)
        return false;

    uint32 counts[PET_MAX_ROW + 1];
    ClasslessPet_BuildRowCounts(pet, talentInfo->TalentTab, counts);
    if (!ClasslessPet_RowUnlocked(counts, talentInfo->Row))
        return false;

    if (talentInfo->DependsOn > 0)
    {
        TalentEntry const* dep = sTalentStore.LookupEntry(talentInfo->DependsOn);
        if (!dep)
            return false;
        bool hasDep = false;
        for (uint8 r = talentInfo->DependsOnRank; r < MAX_TALENT_RANK; ++r)
        {
            if (dep->RankID[r] && pet->HasSpell(dep->RankID[r]))
            {
                hasDep = true;
                break;
            }
        }
        if (!hasDep)
            return false;
    }

    uint32 usedBefore = pet->m_usedTalentCount;
    pet->learnSpell(spellId);
    if (!pet->HasSpell(spellId))
        return false;
    if (pet->m_usedTalentCount <= usedBefore)
        pet->m_usedTalentCount = usedBefore + 1;

    ClasslessPet_Save(player, pet);
    return true;
}

bool ClasslessPet_Unlearn(Player* player, uint32 talentId)
{
    if (!Classless_IsEnabled() || !player)
        return false;

    Pet* pet = ClasslessPet_Get(player);
    if (!pet)
        return false;

    TalentEntry const* talentInfo = sTalentStore.LookupEntry(talentId);
    if (!talentInfo)
        return false;

    uint32 current = ClasslessPet_RankOf(pet, talentInfo);
    if (current < 1)
        return false;

    uint32 dropSpellId = talentInfo->RankID[current - 1];
    if (!dropSpellId)
        return false;

    uint32 counts[PET_MAX_ROW + 1];
    ClasslessPet_BuildRowCounts(pet, talentInfo->TalentTab, counts);
    uint32 row = talentInfo->Row;
    if (row <= PET_MAX_ROW && counts[row] > 0)
        counts[row] -= 1;
    if (!ClasslessPet_HistogramLegal(counts))
        return false;

    uint32 usedBefore = pet->m_usedTalentCount;
    pet->removeSpell(dropSpellId, current > 1, true);
    if (pet->m_usedTalentCount >= usedBefore && usedBefore > 0)
        pet->m_usedTalentCount = usedBefore - 1;

    ClasslessPet_Save(player, pet);
    return true;
}
