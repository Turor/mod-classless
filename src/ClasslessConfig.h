#pragma once

#include "Config.h"

inline bool Classless_IsEnabled()
{
    return sConfigMgr->GetOption<bool>("ClasslessModule.Enable", false);
}

// 0 disables achievement talent points. Any other value scales each matching
// completed achievement in classless_achievements_which_yield_talents.
inline float Classless_AchievementTalentPointScalar()
{
    if (!Classless_IsEnabled())
        return 0.0f;
    return sConfigMgr->GetOption<float>("ClasslessModule.AchievementTalentPoints", 1.0f);
}

inline bool Classless_AchievementTalentPointsEnabled()
{
    return Classless_AchievementTalentPointScalar() != 0.0f;
}
