#pragma once

#include "Define.h"
#include <unordered_map>

class Player;

// Copper from trainer_spell.MoneyCost, plus an optional item currency.
// Both are charged when both are set. Missing spells cost nothing.
struct ClasslessSpellTrainCost
{
    uint32 moneyCost = 0;
    uint32 currencyItemId = 0;
    uint32 currencyCount = 0;
};

enum class ClasslessSpellTrainChargeResult : uint32
{
    Ok = 0,
    NotEnoughMoney = 1,
    NotEnoughCurrency = 2,
};

void Classless_SetSpellTrainCosts(std::unordered_map<uint32, ClasslessSpellTrainCost> costs);
ClasslessSpellTrainCost Classless_LookupSpellTrainCost(uint32 spellId);
void Classless_GetSpellTrainCost(uint32 spellId, uint32& moneyCost, uint32& currencyItemId, uint32& currencyCount);
uint32 Classless_TryChargeSpellTrainCost(Player* player, uint32 spellId);
