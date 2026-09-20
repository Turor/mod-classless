//
// Created by Drago on 2/9/2026.
//

#include "ClasslessPetScripts.h"
#include "ClasslessConfig.h"

#include "Pet.h"
#include "Player.h"

ClasslessPetScripts::ClasslessPetScripts(ClasslessPlayerScripts* cps) : PetScript("ClasslessPetScript") {
    cps_ = cps;
}

void ClasslessPetScripts::OnCalculateMaxTalentPointsForLevel(Pet *pet, uint8 level, uint8 &points) {
    if (Classless_IsEnabled()) {
        Player* owner = pet->GetOwner();
        if (!owner)
            return;
        uint32 talentPointsForLevel = 0;
        cps_->OnPlayerCalculateTalentsPoints(owner, talentPointsForLevel);
        talentPointsForLevel = talentPointsForLevel - (owner->GetLevel() - level); // Adjust for current pet level
        points = talentPointsForLevel/4; // Divide by 4
    }
}

ClasslessPetScripts* AddClasslessPetScripts(ClasslessPlayerScripts* classless_player_scripts) {
    auto *cps = new ClasslessPetScripts(classless_player_scripts); // ScriptMgr takes ownership
    return cps;
}

