#pragma once

#include "Define.h"
#include <vector>

class Player;

uint32 ClasslessPet_FreePoints(Player* player);
uint32 ClasslessPet_KnownRank(Player* player, uint32 talentId);
bool ClasslessPet_Learn(Player* player, uint32 talentId, uint32 rank1Based);
bool ClasslessPet_Unlearn(Player* player, uint32 talentId);
bool ClasslessPet_Cast(Player* player, uint32 spellId);
bool ClasslessPet_ToggleAutocast(Player* player, uint32 spellId);
bool ClasslessPet_IsAutocastable(Player* player, uint32 spellId);
bool ClasslessPet_IsAutocast(Player* player, uint32 spellId);
void ClasslessPet_AutocastMaps(Player* player, std::vector<uint32>& allowed, std::vector<uint32>& enabled);
