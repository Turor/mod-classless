#pragma once

#include "Define.h"

class Player;

// Fully drop a classless talent rank from m_spells (PLAYERSPELL_REMOVED),
// including higher talent ranks still sitting in the chain, then restore
// keepSpellId without Player::learnSpell re-teaching the dropped rank.
bool Classless_DropTalentRank(Player* player, uint32 dropSpellId, uint32 keepSpellId);
