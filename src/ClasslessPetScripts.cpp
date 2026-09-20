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

void ClasslessPetScripts::OnCalculateMaxTalentPointsForLevel(Pet* pet, uint8 /*level*/, uint8& points)
{
    if (!Classless_IsEnabled() || !pet || !cps_)
        return;
    Player* owner = pet->GetOwner();
    if (!owner)
        return;
    uint32 playerPoints = 0;
    cps_->OnPlayerCalculateTalentsPoints(owner, playerPoints);
    points = static_cast<uint8>(playerPoints / 3);
}

ClasslessPetScripts* AddClasslessPetScripts(ClasslessPlayerScripts* classless_player_scripts) {
    auto *cps = new ClasslessPetScripts(classless_player_scripts); // ScriptMgr takes ownership
    return cps;
}

