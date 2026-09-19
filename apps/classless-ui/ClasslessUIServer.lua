local AIO = AIO or require("AIO")
if not AIO.IsMainState() then
    return
end

local Handlers = AIO.AddHandlers("ClasslessUIServer", {})
local Catalog = ClasslessUICatalog

local function spellName(spellId)
    if not LookupEntry then
        return nil
    end
    local entry = LookupEntry("Spell", spellId)
    if not entry or not entry.GetSpellName then
        return nil
    end
    local names = entry:GetSpellName()
    if type(names) == "table" then
        return names[1] or names[0]
    end
    return names
end

local function spellLevel(spellId)
    if not LookupEntry then
        return 0
    end
    local entry = LookupEntry("Spell", spellId)
    if not entry then
        return 0
    end
    local level = 0
    if entry.GetSpellLevel then
        level = entry:GetSpellLevel() or 0
    end
    if level == 0 and entry.GetBaseLevel then
        level = entry:GetBaseLevel() or 0
    end
    return level
end

local function collectLearned(player)
    local learned = {}
    if Catalog and Catalog.spellSet then
        for spellId in pairs(Catalog.spellSet) do
            if player:HasSpell(spellId) then
                learned[spellId] = true
            end
        end
    end
    if Catalog and Catalog.talentById then
        for _, node in pairs(Catalog.talentById) do
            for i = 1, #node.r do
                local spellId = node.r[i]
                if player:HasSpell(spellId) then
                    learned[spellId] = true
                end
            end
        end
    end
    return learned
end

local function sendState(player)
    local points = 0
    if player.GetFreeTalentPoints then
        points = player:GetFreeTalentPoints() or 0
    end
    AIO.Handle(player, "ClasslessUIClient", "ApplyState", {
        learned = collectLearned(player),
        points = points,
    })
end

function Handlers.RequestState(player)
    if not player then
        return
    end
    sendState(player)
end

local function inSpellCatalog(spellId)
    return Catalog and Catalog.spellSet and Catalog.spellSet[spellId]
end

function Handlers.LearnSpell(player, spellId)
    spellId = tonumber(spellId)
    if type(spellId) ~= "number" or not player then
        return
    end
    if not inSpellCatalog(spellId) then
        return
    end
    local req = spellLevel(spellId)
    if req > 1 and player:GetLevel() < req then
        player:SendBroadcastMessage("You are not high enough level for that rank.")
        return
    end
    local name = spellName(spellId)
    if name and Catalog.spellSet then
        local previous
        local prevLevel = -1
        local thisLevel = spellLevel(spellId)
        for id in pairs(Catalog.spellSet) do
            if id ~= spellId and spellName(id) == name then
                local lvl = spellLevel(id)
                if lvl < thisLevel and lvl >= prevLevel then
                    previous = id
                    prevLevel = lvl
                end
            end
        end
        if previous and not player:HasSpell(previous) then
            player:SendBroadcastMessage("Learn the previous rank first.")
            return
        end
    end
    player:LearnSpell(spellId)
    sendState(player)
end

local function treePoints(player, tabId)
    local nodes = Catalog.talents and Catalog.talents[tabId]
    if not nodes then
        return 0
    end
    local spent = 0
    for _, node in ipairs(nodes) do
        local rank = 0
        for i = 1, #node.r do
            if player:HasSpell(node.r[i]) then
                rank = i
            end
        end
        spent = spent + rank
    end
    return spent
end

function Handlers.LearnTalent(player, talentId, rank)
    talentId = tonumber(talentId)
    rank = tonumber(rank)
    if type(talentId) ~= "number" or type(rank) ~= "number" or not player then
        return
    end
    local node = Catalog and Catalog.talentById and Catalog.talentById[talentId]
    if not node then
        return
    end
    rank = math.floor(rank)
    local spellId = node.r[rank]
    if not spellId then
        return
    end
    local points = player:GetFreeTalentPoints() or 0
    if points < 1 then
        player:SendBroadcastMessage("No talent points remaining.")
        return
    end
    if rank > 1 and not player:HasSpell(node.r[rank - 1]) then
        player:SendBroadcastMessage("Learn the previous talent rank first.")
        return
    end
    if node.p and node.p > 0 then
        local dep = Catalog.talentById[node.p]
        local need = (node.pr or 0) + 1
        if not dep or not dep.r[need] or not player:HasSpell(dep.r[need]) then
            player:SendBroadcastMessage("Missing talent prerequisite.")
            return
        end
    end
    if node.t and node.t > 0 then
        if treePoints(player, node.tabId) < (node.t * 5) then
            player:SendBroadcastMessage("Not enough points in this tree.")
            return
        end
    end
    if player:HasSpell(spellId) then
        sendState(player)
        return
    end
    player:LearnSpell(spellId)
    player:SetFreeTalentPoints(points - 1)
    sendState(player)
end

function Handlers.UnlearnTalent(player, talentId, rank)
    talentId = tonumber(talentId)
    rank = tonumber(rank)
    if type(talentId) ~= "number" or type(rank) ~= "number" or not player then
        return
    end
    local node = Catalog and Catalog.talentById and Catalog.talentById[talentId]
    if not node then
        return
    end
    rank = math.floor(rank)
    local spellId = node.r[rank]
    if not spellId or not player:HasSpell(spellId) then
        return
    end
    -- Refuse if a later rank of this node is still known.
    if node.r[rank + 1] and player:HasSpell(node.r[rank + 1]) then
        player:SendBroadcastMessage("Unlearn the higher rank first.")
        return
    end
    player:RemoveSpell(spellId)
    local points = player:GetFreeTalentPoints() or 0
    player:SetFreeTalentPoints(points + 1)
    if rank > 1 then
        player:LearnSpell(node.r[rank - 1])
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
