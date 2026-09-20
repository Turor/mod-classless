#include "ClasslessSpellTrainCost.h"
#include "ClasslessConfig.h"

#include "Config.h"
#include "Player.h"

static std::unordered_map<uint32, ClasslessSpellTrainCost> spellTrainCosts;

void Classless_SetSpellTrainCosts(std::unordered_map<uint32, ClasslessSpellTrainCost> costs)
{
    spellTrainCosts = std::move(costs);
}

ClasslessSpellTrainCost Classless_LookupSpellTrainCost(uint32 spellId)
{
    auto itr = spellTrainCosts.find(spellId);
    if (itr == spellTrainCosts.end())
        return {};
    return itr->second;
}

void Classless_GetSpellTrainCost(uint32 spellId, uint32& moneyCost, uint32& currencyItemId, uint32& currencyCount)
{
    ClasslessSpellTrainCost const cost = Classless_LookupSpellTrainCost(spellId);
    moneyCost = cost.moneyCost;
    currencyItemId = cost.currencyItemId;
    currencyCount = cost.currencyCount;
}

uint32 Classless_TryChargeSpellTrainCost(Player* player, uint32 spellId)
{
    if (!player)
        return uint32(ClasslessSpellTrainChargeResult::Ok);

    if (!Classless_IsEnabled())
        return uint32(ClasslessSpellTrainChargeResult::Ok);

    ClasslessSpellTrainCost const cost = Classless_LookupSpellTrainCost(spellId);
    bool const takeMoney = cost.moneyCost > 0;
    bool const takeItem = cost.currencyItemId > 0 && cost.currencyCount > 0;

    if (!takeMoney && !takeItem)
        return uint32(ClasslessSpellTrainChargeResult::Ok);

    if (takeMoney && !player->HasEnoughMoney(cost.moneyCost))
        return uint32(ClasslessSpellTrainChargeResult::NotEnoughMoney);

    if (takeItem && !player->HasItemCount(cost.currencyItemId, cost.currencyCount, false))
        return uint32(ClasslessSpellTrainChargeResult::NotEnoughCurrency);

    if (takeMoney)
        player->ModifyMoney(-int32(cost.moneyCost));

    if (takeItem)
        player->DestroyItemCount(cost.currencyItemId, cost.currencyCount, true);

    return uint32(ClasslessSpellTrainChargeResult::Ok);
}
