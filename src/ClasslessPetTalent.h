#pragma once

#include "Define.h"

class Player;

uint32 ClasslessPet_FreePoints(Player* player);
uint32 ClasslessPet_KnownRank(Player* player, uint32 talentId);
bool ClasslessPet_Learn(Player* player, uint32 talentId, uint32 rank1Based);
bool ClasslessPet_Unlearn(Player* player, uint32 talentId);
