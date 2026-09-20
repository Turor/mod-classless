#include "ClasslessDatastoreInitializationScripts.h"
#include "ClasslessSpellTrainCost.h"

#include "ScriptMgr.h"
#include "DatabaseEnv.h"
#include <unordered_map>
#include <unordered_set>

void ClasslessDatastoreInitializationScripts::OnAfterDatabasesLoaded(uint32) {
    uint32 oldMSTime = getMSTime();
    std::unordered_set<uint32> ids;
    LOG_INFO("server.loading", "Loading achievements for talent point calculations");
    if (QueryResult r = WorldDatabase.Query("SELECT achievement_id FROM acore_world.classless_achievements_which_yield_talents")) {
        do { ids.insert(r->Fetch()[0].Get<uint32>()); } while (r->NextRow());
    } else {
        LOG_ERROR("server.loading", "Could not load achievements for talent point calculations");
    }
    if (cps_) cps_->SetTalentYieldAchievements(ids);
    LOG_INFO("server.loading", ">> Loaded achievements for talent point calculations in {} ms", GetMSTimeDiffToNow(oldMSTime));

    oldMSTime = getMSTime();
    std::unordered_map<uint32, ClasslessSpellTrainCost> costs;
    LOG_INFO("server.loading", "Loading classless spell train costs");
    if (QueryResult r = WorldDatabase.Query(
            "SELECT spell_id, money_cost, currency_item_id, currency_count FROM classless_spell_train_cost"))
    {
        do
        {
            Field* fields = r->Fetch();
            ClasslessSpellTrainCost cost;
            uint32 spellId = fields[0].Get<uint32>();
            cost.moneyCost = fields[1].Get<uint32>();
            cost.currencyItemId = fields[2].Get<uint32>();
            cost.currencyCount = fields[3].Get<uint32>();
            costs[spellId] = cost;
        } while (r->NextRow());
        LOG_INFO("server.loading", ">> Loaded {} classless spell train costs in {} ms", costs.size(), GetMSTimeDiffToNow(oldMSTime));
    }
    else
    {
        LOG_ERROR("server.loading", "Could not load classless_spell_train_cost");
    }
    Classless_SetSpellTrainCosts(std::move(costs));
}

void AddClasslessDatastoreInitializationScripts(ClasslessPlayerScripts* classless_player_scripts)
{
    new ClasslessDatastoreInitializationScripts(classless_player_scripts);
}
