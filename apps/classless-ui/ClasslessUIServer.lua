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

local nameCache = {}
local familiesByName

local function cachedSpellName(spellId)
    local cached = nameCache[spellId]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached
    end
    local name = spellName(spellId)
    nameCache[spellId] = name or false
    return name
end

local function buildFamilies()
    if familiesByName or not Catalog or not Catalog.spellSet then
        return
    end
    familiesByName = {}
    for id in pairs(Catalog.spellSet) do
        local n = cachedSpellName(id)
        if n then
            local list = familiesByName[n]
            if not list then
                list = {}
                familiesByName[n] = list
            end
            list[#list + 1] = { id = id, level = spellLevel(id) }
        end
    end
    for _, list in pairs(familiesByName) do
        table.sort(list, function(a, b)
            if a.level ~= b.level then
                return a.level < b.level
            end
            return a.id < b.id
        end)
    end
end

local function previousRankId(spellId)
    buildFamilies()
    local n = cachedSpellName(spellId)
    local list = n and familiesByName and familiesByName[n]
    if not list then
        return nil
    end
    for i = 1, #list do
        if list[i].id == spellId then
            if i > 1 then
                return list[i - 1].id
            end
            return nil
        end
    end
    return nil
end

local function inSpellCatalog(spellId)
    return Catalog and Catalog.spellSet and Catalog.spellSet[spellId]
end

local function talentOwnsSpell(spellId)
    if not Catalog or not Catalog.talentById then
        return false
    end
    for _, node in pairs(Catalog.talentById) do
        for i = 1, #node.r do
            if node.r[i] == spellId then
                return true
            end
        end
    end
    return false
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

local function canLearnSpell(player, spellId)
    if player:HasSpell(spellId) or not inSpellCatalog(spellId) then
        return false
    end
    local req = spellLevel(spellId)
    if req > 1 and player:GetLevel() < req then
        return false
    end
    local prev = previousRankId(spellId)
    if prev and not player:HasSpell(prev) then
        return false
    end
    return true
end

local function collectLearnable(player)
    local learnable = {}
    if Catalog and Catalog.spellSet then
        for spellId in pairs(Catalog.spellSet) do
            if canLearnSpell(player, spellId) then
                learnable[spellId] = true
            end
        end
    end
    return learnable
end

local function sendState(player)
    local points = 0
    if player.GetFreeTalentPoints then
        points = player:GetFreeTalentPoints() or 0
    end
    AIO.Handle(player, "ClasslessUIClient", "ApplyState", {
        learned = collectLearned(player),
        learnable = collectLearnable(player),
        points = points,
    })
end

function Handlers.RequestState(player)
    if not player then
        return
    end
    sendState(player)
end

function Handlers.LearnSpell(player, spellId)
    spellId = tonumber(spellId)
    if type(spellId) ~= "number" or not player then
        return
    end
    if not canLearnSpell(player, spellId) then
        return
    end
    player:LearnSpell(spellId)
    sendState(player)
end

function Handlers.CastSpell(player, spellId)
    spellId = tonumber(spellId)
    if type(spellId) ~= "number" or not player then
        return
    end
    if not player:HasSpell(spellId) then
        return
    end
    if not inSpellCatalog(spellId) and not talentOwnsSpell(spellId) then
        return
    end
    local target = player:GetSelection()
    if not target then
        target = player
    end
    player:CastSpell(target, spellId, false)
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
