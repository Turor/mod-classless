#pragma once

#include "Define.h"

class Player;

// Fully drop a classless talent rank from m_spells (PLAYERSPELL_REMOVED),
// including higher talent ranks still sitting in the chain, then restore
// keepSpellId without Player::learnSpell re-teaching the dropped rank.
bool Classless_DropTalentRank(Player* player, uint32 dropSpellId, uint32 keepSpellId);

// Highest known rank (1-based) from HasTalent or HasSpell on Talent.dbc RankID[].
uint32 Classless_KnownTalentRank(Player* player, uint32 talentId);
void Classless_ClearLearnedTalentSpells(Player* player);
uint32 Classless_GetPetTalentTabs(Player* player, uint32* out, uint32 maxOut);
void Classless_RequestSpellSave(Player* player);
