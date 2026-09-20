#include "ClasslessUnitScripts.h"
#include "ClasslessConfig.h"

#include "SharedDefines.h"
#include "SpellMgr.h"
#include "Unit.h"
#include "Config.h"

ClasslessUnitScripts::ClasslessUnitScripts() : UnitScript("ClasslessUnitScript") {
}

bool ClasslessUnitScripts::OnExtraProcHandleReactionStates(Unit* unit, Unit* target, bool isVictim, uint32 procs) {
    if (Classless_IsEnabled()) {
        // If exist crit/parry/dodge/block need update aura state (for victim and attacker)
        if (procs)
        {
            // for victim
            if (isVictim)
            {
                // if victim and dodge attack
                if (procs & PROC_EX_DODGE)
                {
                    // Update AURA_STATE on dodge
                    unit->ModifyAuraState(AURA_STATE_DEFENSE, true);
                    unit->StartReactiveTimer(REACTIVE_DEFENSE);

                }
                // if victim and parry attack
                if (procs & PROC_EX_PARRY)
                {

                    unit->ModifyAuraState(AURA_STATE_HUNTER_PARRY, true);
                    unit->StartReactiveTimer(REACTIVE_HUNTER_PARRY);
                    unit->ModifyAuraState(AURA_STATE_DEFENSE, true);
                    unit->StartReactiveTimer(REACTIVE_DEFENSE);

                }
                // if and victim block attack
                if (procs & PROC_EX_BLOCK)
                {
                    unit->ModifyAuraState(AURA_STATE_DEFENSE, true);
                    unit->StartReactiveTimer(REACTIVE_DEFENSE);
                }
            }
            else // For attacker
            {
                // Overpower on victim dodge
                if (procs & PROC_EX_DODGE)
                {
                    unit->AddComboPoints(target, 1);
                    unit->StartReactiveTimer(REACTIVE_OVERPOWER);
                }

                // Wolverine Bite
                if ((procs & PROC_HIT_CRITICAL) && unit->IsHunterPet())
                {
                    unit->AddComboPoints(target, 1);
                    unit->StartReactiveTimer(REACTIVE_WOLVERINE_BITE);
                }
            }
        }
    }
    return false;
}

ClasslessUnitScripts* AddClasslessUnitScripts() {
    auto *cps = new ClasslessUnitScripts(); // ScriptMgr takes ownership
    return cps;
}