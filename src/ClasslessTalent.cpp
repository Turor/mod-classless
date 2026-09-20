#include "ClasslessTalent.h"
#include "ClasslessConfig.h"

#include "Config.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "Opcodes.h"
#include "Player.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldPacket.h"

static void ErasePlayerSpell(Player* player, uint32 spellId)
{
    PlayerSpellMap& spells = player->GetSpellMap();
    auto itr = spells.find(spellId);
    if (itr == spells.end() || itr->second->State == PLAYERSPELL_REMOVED)
        return;

    player->RemoveOwnedAura(spellId);

    if (SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId))
    {
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            if (info->Effects[i].TriggerSpell)
                player->RemoveAurasDueToSpell(info->Effects[i].TriggerSpell);
        }
    }

    if (itr->second->State == PLAYERSPELL_NEW || itr->second->State == PLAYERSPELL_TEMPORARY)
    {
        delete itr->second;
        spells.erase(itr);
    }
    else
    {
        itr->second->State = PLAYERSPELL_REMOVED;
        itr->second->specMask = 0;
        itr->second->Active = false;
    }

    player->SendLearnPacket(spellId, false);
}

static void ActivatePlayerSpell(Player* player, uint32 spellId)
{
    PlayerSpellMap& spells = player->GetSpellMap();
    uint8 specMask = player->GetActiveSpecMask();
    auto itr = spells.find(spellId);

    if (itr == spells.end())
    {
        PlayerSpell* spell = new PlayerSpell();
        spell->State = PLAYERSPELL_NEW;
        spell->Active = true;
        spell->specMask = specMask;
        spells[spellId] = spell;
    }
    else
    {
        if (itr->second->State == PLAYERSPELL_REMOVED)
            itr->second->State = PLAYERSPELL_CHANGED;
        else if (itr->second->State != PLAYERSPELL_NEW && itr->second->State != PLAYERSPELL_TEMPORARY)
            itr->second->State = PLAYERSPELL_CHANGED;
        itr->second->Active = true;
        itr->second->specMask |= specMask;
    }

    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (info && (info->IsPassive() || (info->HasAttribute(SPELL_ATTR0_DO_NOT_DISPLAY) && info->Stances)))
    {
        if (player->IsNeedCastPassiveSpellAtLearn(info))
            player->CastSpell(player, spellId, true);
    }

    player->SendLearnPacket(spellId, true);

    if (!info || info->IsStackableWithRanks() || !info->IsRanked())
        return;

    for (SpellInfo const* prev = info->GetPrevRankSpell(); prev; prev = prev->GetPrevRankSpell())
    {
        auto pit = spells.find(prev->Id);
        if (pit == spells.end() || pit->second->State == PLAYERSPELL_REMOVED || !pit->second->Active)
            continue;
        pit->second->Active = false;
        if (pit->second->State != PLAYERSPELL_NEW && pit->second->State != PLAYERSPELL_TEMPORARY)
            pit->second->State = PLAYERSPELL_CHANGED;
        WorldPacket data(SMSG_SUPERCEDED_SPELL, 4 + 4);
        data << uint32(prev->Id);
        data << uint32(spellId);
        player->SendDirectMessage(&data);
    }
}

bool Classless_DropTalentRank(Player* player, uint32 dropSpellId, uint32 keepSpellId)
{
    if (!player || !dropSpellId || dropSpellId == keepSpellId)
        return false;
    if (!Classless_IsEnabled())
        return false;

    uint8 specMask = player->GetActiveSpecMask();
    ErasePlayerSpell(player, dropSpellId);
    player->_removeTalent(dropSpellId, specMask);
    player->_removeTalentAurasAndSpells(dropSpellId);

    uint32 nextId = sSpellMgr->GetNextSpellInChain(dropSpellId);
    while (nextId && nextId != keepSpellId)
    {
        if (!GetTalentSpellPos(nextId))
            break;
        ErasePlayerSpell(player, nextId);
        player->_removeTalent(nextId, specMask);
        player->_removeTalentAurasAndSpells(nextId);
        nextId = sSpellMgr->GetNextSpellInChain(nextId);
    }

    uint8 droppedRank = 0;
    if (TalentSpellPos const* pos = GetTalentSpellPos(dropSpellId))
        droppedRank = pos->rank + 1;

    if (keepSpellId)
    {
        ActivatePlayerSpell(player, keepSpellId);
        if (GetTalentSpellPos(keepSpellId))
            player->addTalent(keepSpellId, specMask, droppedRank);
    }

    player->RecalculateUsedTalentCount();
    player->SendTalentsInfoData(false);

    return !player->HasSpell(dropSpellId) && !player->HasTalent(dropSpellId, player->GetActiveSpec());
}

uint32 Classless_KnownTalentRank(Player* player, uint32 talentId)
{
    if (!player || !talentId)
        return 0;

    TalentEntry const* info = sTalentStore.LookupEntry(talentId);
    if (!info)
        return 0;

    // Prefer the talent map (current rank only). HasSpell is true for every
    // superceded rank in the chain and would over-count spend.
    uint32 talentRank = 0;
    uint32 spellRank = 0;
    for (uint8 i = 0; i < MAX_TALENT_RANK; ++i)
    {
        uint32 spellId = info->RankID[i];
        if (!spellId)
            continue;
        if (player->HasTalent(spellId, player->GetActiveSpec()))
            talentRank = i + 1;
        if (player->HasSpell(spellId))
            spellRank = i + 1;
    }
    return talentRank > 0 ? talentRank : spellRank;
}

void Classless_ClearLearnedTalentSpells(Player* player)
{
    if (!player)
        return;

    for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
    {
        TalentEntry const* info = sTalentStore.LookupEntry(i);
        if (!info)
            continue;
        TalentTabEntry const* tab = sTalentTabStore.LookupEntry(info->TalentTab);
        if (!tab || tab->petTalentMask)
            continue;
        for (uint8 r = 0; r < MAX_TALENT_RANK; ++r)
        {
            if (info->RankID[r])
                ErasePlayerSpell(player, info->RankID[r]);
        }
    }
}
