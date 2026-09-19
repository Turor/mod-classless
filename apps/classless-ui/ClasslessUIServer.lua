local AIO = AIO or require("AIO")
if not AIO.IsMainState() then
    return
end

local Handlers = AIO.AddHandlers("ClasslessUIServer", {})

local function sendState(player)
    local points = 0
    if player.GetFreeTalentPoints then
        points = player:GetFreeTalentPoints() or 0
    end
    AIO.Handle(player, "ClasslessUIClient", "ApplyState", {
        learned = {},
        talents = {},
        points = points,
    })
end

function Handlers.RequestState(player)
    if not player then
        return
    end
    sendState(player)
end

-- Stubs: catalog validation lands with the Mage spell pass.
function Handlers.LearnSpell(player, spellId)
    spellId = tonumber(spellId)
    if type(spellId) ~= "number" or not player then
        return
    end
    sendState(player)
end

function Handlers.LearnTalent(player, talentId, rank)
    talentId = tonumber(talentId)
    rank = tonumber(rank)
    if type(talentId) ~= "number" or type(rank) ~= "number" or not player then
        return
    end
    sendState(player)
end

function Handlers.UnlearnTalent(player, talentId, rank)
    talentId = tonumber(talentId)
    rank = tonumber(rank)
    if type(talentId) ~= "number" or type(rank) ~= "number" or not player then
        return
    end
    sendState(player)
end

local function OnCommand(event, player, command)
    if command == "classless" then
        AIO.Handle(player, "ClasslessUIClient", "ShowUI")
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)
