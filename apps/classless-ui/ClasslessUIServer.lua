local AIO = AIO or require("AIO")
if not AIO.IsMainState() then
    return
end

local Handlers = AIO.AddHandlers("ClasslessUIServer", {})
local Catalog = ClasslessUICatalog

local function classlessEnabled()
    if not GetConfigValue then
        return true
    end
    local v = GetConfigValue("ClasslessModule.Enable")
    return v == true or v == 1
end

local function pushEnabled(player)
    if player then
        AIO.Handle(player, "ClasslessUIClient", "SetEnabled", classlessEnabled())
        AIO.Handle(player, "ClasslessResourceBar", "SetEnabled", classlessEnabled())
    end
end

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

local dkSpellSet
local function isDkSpell(spellId)
    if not dkSpellSet then
        dkSpellSet = {}
        local specs = Catalog and Catalog.spells and Catalog.spells[6]
        if specs then
            for _, ids in pairs(specs) do
                for i = 1, #ids do
                    dkSpellSet[ids[i]] = true
                end
            end
        end
    end
    return dkSpellSet[spellId]
end

local function spellLevel(spellId)
    if not LookupEntry then
        return isDkSpell(spellId) and 55 or 0
    end
    local entry = LookupEntry("Spell", spellId)
    if not entry then
        return isDkSpell(spellId) and 55 or 0
    end
    local level = 0
    if entry.GetSpellLevel then
        level = entry:GetSpellLevel() or 0
    end
    if level == 0 and entry.GetBaseLevel then
        level = entry:GetBaseLevel() or 0
    end
    if isDkSpell(spellId) and level < 55 then
        level = 55
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
    if familiesByName or not Catalog then
        return
    end
    familiesByName = {}
    local seen = {}
    local function addId(id)
        if not id or seen[id] then
            return
        end
        seen[id] = true
        local n = cachedSpellName(id)
        if not n then
            return
        end
        local list = familiesByName[n]
        if not list then
            list = {}
            familiesByName[n] = list
        end
        list[#list + 1] = { id = id, level = spellLevel(id) }
    end
    if Catalog.spellSet then
        for id in pairs(Catalog.spellSet) do
            addId(id)
        end
    end
    -- Talent ranks share names with later trainer ranks; they must sit in
    -- the chain so rank 2 is not learnable until the talent taught rank 1.
    if Catalog.talentById then
        for _, node in pairs(Catalog.talentById) do
            for i = 1, #node.r do
                addId(node.r[i])
            end
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

local petSpellSet
local function isPetCatalogSpell(spellId)
    if not spellId then
        return false
    end
    if not petSpellSet then
        petSpellSet = {}
        for _, id in ipairs((Catalog and Catalog.petSpells) or {}) do
            petSpellSet[id] = true
        end
    end
    return petSpellSet[spellId] and true or false
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

local petTabSet
local function isPetTabId(tabId)
    if not petTabSet then
        petTabSet = {}
        for _, id in ipairs((Catalog and Catalog.petTabs) or { 409, 410, 411 }) do
            petTabSet[id] = true
        end
    end
    return tabId and petTabSet[tabId]
end

local function unitHasSpell(unit, spellId)
    return unit and unit.HasSpell and unit:HasSpell(spellId)
end

-- Stock LearnTalent writes m_talents (HasTalent). Classless LearnSpell writes
-- m_spells (HasSpell). The UI has to treat either as a known talent rank.
local function playerHasTalentRank(player, spellId)
    if not player or not spellId then
        return false
    end
    if player:HasSpell(spellId) then
        return true
    end
    if not player.HasTalent then
        return false
    end
    local spec = 0
    if player.GetActiveSpec then
        spec = player:GetActiveSpec() or 0
    end
    return player:HasTalent(spellId, spec) and true or false
end

local function highestKnownTalentRank(hasFn, node)
    local rank = 0
    for i = 1, #node.r do
        if hasFn(node.r[i]) then
            rank = i
        end
    end
    return rank
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
            if not isPetTabId(node.tabId) then
                local rank = 0
                if player.GetClasslessTalentRank then
                    rank = tonumber(player:GetClasslessTalentRank(node.id)) or 0
                else
                    rank = highestKnownTalentRank(function(id)
                        return playerHasTalentRank(player, id)
                    end, node)
                end
                -- Stock LearnTalent only keeps the current rank in m_talents.
                -- Mark 1..rank so the classless tree shows the true current rank.
                for i = 1, rank do
                    if node.r[i] then
                        learned[node.r[i]] = true
                    end
                end
            end
        end
    end
    return learned
end

local function collectPetLearned(pet)
    local learned = {}
    if not pet then
        return learned
    end
    if Catalog and Catalog.petSpells then
        for i = 1, #Catalog.petSpells do
            local spellId = Catalog.petSpells[i]
            if unitHasSpell(pet, spellId) then
                learned[spellId] = true
            end
        end
    end
    if Catalog and Catalog.petTabs then
        for _, tabId in ipairs(Catalog.petTabs) do
            local nodes = Catalog.talents and Catalog.talents[tabId]
            if nodes then
                for _, node in ipairs(nodes) do
                    for i = 1, #node.r do
                        local spellId = node.r[i]
                        if unitHasSpell(pet, spellId) then
                            learned[spellId] = true
                        end
                    end
                end
            end
        end
    end
    return learned
end

local function treePointsOn(hasFn, tabId)
    local nodes = Catalog.talents and Catalog.talents[tabId]
    if not nodes then
        return 0
    end
    local spent = 0
    for _, node in ipairs(nodes) do
        local rank = 0
        for i = 1, #node.r do
            if hasFn(node.r[i]) then
                rank = i
            end
        end
        spent = spent + rank
    end
    return spent
end

local UNLEARN_BLOCKED_MSG = "Can't unlearn that talent; it would leave a later talent dangling."

local function forEachTalentNode(pet, fn)
    if not Catalog or not Catalog.talents then
        return
    end
    if pet then
        for _, tabId in ipairs(Catalog.petTabs or { 409, 410, 411 }) do
            local nodes = Catalog.talents[tabId]
            if nodes then
                for i = 1, #nodes do
                    fn(nodes[i])
                end
            end
        end
        return
    end
    local petSet = {}
    for _, tabId in ipairs(Catalog.petTabs or { 409, 410, 411 }) do
        petSet[tabId] = true
    end
    for tabId, nodes in pairs(Catalog.talents) do
        if not petSet[tabId] then
            for i = 1, #nodes do
                fn(nodes[i])
            end
        end
    end
end

local function nodeSpend(player, hasFn, n, pet)
    if not pet and player and player.GetClasslessTalentRank then
        return tonumber(player:GetClasslessTalentRank(n.id)) or 0
    end
    return highestKnownTalentRank(hasFn, n)
end

local MAX_TALENT_ROW = 15
local POINTS_PER_ROW = 5

local function buildRowHistogram(player, hasFn, pet)
    local counts = {}
    for r = 0, MAX_TALENT_ROW do
        counts[r] = 0
    end
    forEachTalentNode(pet, function(n)
        local rank = nodeSpend(player, hasFn, n, pet)
        local row = n.t or 0
        if rank > 0 and row >= 0 and row <= MAX_TALENT_ROW then
            counts[row] = counts[row] + rank
        end
    end)
    return counts
end

local function prefixBelow(counts, row)
    local sum = 0
    for r = 0, row - 1 do
        sum = sum + (counts[r] or 0)
    end
    return sum
end

local function rowUnlocked(counts, row)
    if not row or row <= 0 then
        return true
    end
    return prefixBelow(counts, row) >= (row * POINTS_PER_ROW)
end

local function histogramLegal(counts)
    for r = 1, MAX_TALENT_ROW do
        if (counts[r] or 0) > 0 and not rowUnlocked(counts, r) then
            return false
        end
    end
    return true
end

local function unlearnWouldOrphan(player, hasFn, node, pet)
    local current = nodeSpend(player, hasFn, node, pet)
    if current < 1 then
        return true, UNLEARN_BLOCKED_MSG
    end
    local counts = buildRowHistogram(player, hasFn, pet)
    local row = node.t or 0
    if row >= 0 and row <= MAX_TALENT_ROW then
        counts[row] = (counts[row] or 0) - 1
        if counts[row] < 0 then
            counts[row] = 0
        end
    end
    if not histogramLegal(counts) then
        return true, UNLEARN_BLOCKED_MSG
    end
    return false, UNLEARN_BLOCKED_MSG
end

local function canLearnSpell(player, spellId)
    if Catalog.blockedSpells and Catalog.blockedSpells[spellId] then
        return false
    end
    if Catalog.generalSet and Catalog.generalSet[spellId] then
        return false
    end
    if isPetCatalogSpell(spellId) then
        return false
    end
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
    -- Talent-taught ranks: only the next rank after what they already have.
    if talentOwnsSpell(spellId) then
        local node
        for _, n in pairs(Catalog.talentById) do
            for i = 1, #n.r do
                if n.r[i] == spellId then
                    node = n
                    if i > 1 and not player:HasSpell(n.r[i - 1]) then
                        return false
                    end
                    break
                end
            end
            if node then
                break
            end
        end
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

local function collectReqLevels(player)
    local req = {}
    if not Catalog or not Catalog.spellSet then
        return req
    end
    for spellId in pairs(Catalog.spellSet) do
        if not player:HasSpell(spellId) and not canLearnSpell(player, spellId) then
            local lvl = spellLevel(spellId)
            if lvl and lvl > 0 then
                req[spellId] = lvl
            end
        end
    end
    return req
end

local trainCosts
local CHARGE_OK = 0
local CHARGE_NO_GOLD = 1
local CHARGE_NO_CURRENCY = 2

local function loadTrainCosts(player)
    if trainCosts then
        return
    end
    trainCosts = {}
    if not player or not player.GetClasslessSpellTrainCost or not Catalog or not Catalog.spellSet then
        return
    end
    for spellId in pairs(Catalog.spellSet) do
        local money, item, itemCount = player:GetClasslessSpellTrainCost(spellId)
        money = tonumber(money) or 0
        item = tonumber(item) or 0
        itemCount = tonumber(itemCount) or 0
        if money > 0 or (item > 0 and itemCount > 0) then
            trainCosts[spellId] = {
                money = money,
                item = item,
                itemCount = itemCount,
            }
        end
    end
end

local function collectTrainCosts(player)
    loadTrainCosts(player)
    local costs = {}
    local alt = {}
    for spellId, c in pairs(trainCosts) do
        if c.money and c.money > 0 then
            costs[spellId] = c.money
        end
        if c.item and c.item > 0 and c.itemCount and c.itemCount > 0 then
            alt[spellId] = { id = c.item, n = c.itemCount }
        end
    end
    return costs, alt
end

local function learnFailed(player, msg)
    if player.SendBroadcastMessage then
        player:SendBroadcastMessage(msg)
    end
    AIO.Handle(player, "ClasslessUIClient", "LearnFailed", msg)
end

local function petFreeTalentPoints(pet)
    if not pet then
        return 0
    end
    local used = 0
    if pet.GetUsedTalentCount then
        used = tonumber(pet:GetUsedTalentCount()) or 0
    end
    local maxp = 0
    if pet.GetMaxTalentPointsForLevel and pet.GetLevel then
        maxp = tonumber(pet:GetMaxTalentPointsForLevel(pet:GetLevel())) or 0
    end
    local remain = maxp - used
    if remain < 0 then
        remain = 0
    end
    local current = 0
    if pet.GetFreeTalentPoints then
        current = tonumber(pet:GetFreeTalentPoints()) or 0
    end
    if remain ~= current and pet.SetFreeTalentPoints then
        pet:SetFreeTalentPoints(remain)
    end
    return remain
end

local function sendState(player)
    local points = 0
    if player.GetFreeTalentPoints then
        points = player:GetFreeTalentPoints() or 0
    end
    local pet = player:GetPet()
    local petPoints = petFreeTalentPoints(pet)
    local costs, altCosts = collectTrainCosts(player)
    AIO.Handle(player, "ClasslessUIClient", "ApplyState", {
        learned = collectLearned(player),
        learnable = collectLearnable(player),
        reqLevels = collectReqLevels(player),
        costs = costs,
        altCosts = altCosts,
        petLearned = collectPetLearned(pet),
        petOut = pet ~= nil,
        points = points,
        petPoints = petPoints,
    })
end

function Handlers.RequestState(player)
    if not classlessEnabled() then
        pushEnabled(player)
        return
    end
    if not player then
        return
    end
    sendState(player)
end

function Handlers.LearnSpell(player, spellId)
    if not classlessEnabled() then
        return
    end
    spellId = tonumber(spellId)
    if type(spellId) ~= "number" or not player then
        return
    end
    if isPetCatalogSpell(spellId) then
        return
    end
    if not canLearnSpell(player, spellId) then
        return
    end
    if player.ChargeClasslessSpellTrainCost then
        local charged = tonumber(player:ChargeClasslessSpellTrainCost(spellId)) or CHARGE_OK
        if charged == CHARGE_NO_GOLD then
            learnFailed(player, "Not enough gold.")
            return
        end
        if charged == CHARGE_NO_CURRENCY then
            learnFailed(player, "Not enough currency.")
            return
        end
    end
    player:LearnSpell(spellId)
    sendState(player)
end

function Handlers.CastSpell(player, spellId)
    if not classlessEnabled() then
        return
    end
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

local function talentPrereqsOk(player, hasFn, node, rank)
    if rank > 1 and not hasFn(node.r[rank - 1]) then
        return false, "Learn the previous talent rank first."
    end
    if node.p and node.p > 0 then
        local dep = Catalog.talentById[node.p]
        local need = (node.pr or 0) + 1
        if not dep or not dep.r[need] or not hasFn(dep.r[need]) then
            return false, "Missing talent prerequisite."
        end
    end
    local row = node.t or 0
    local pet = isPetTabId(node.tabId)
    local counts = buildRowHistogram(player, hasFn, pet)
    if not rowUnlocked(counts, row) then
        return false, "Not enough talent points in earlier rows."
    end
    return true
end

function Handlers.LearnTalent(player, talentId, rank)
    if not classlessEnabled() then
        return
    end
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
    local maxRank = #node.r
    if rank < 1 or rank > maxRank then
        return
    end
    local spellId = node.r[rank]
    if not spellId then
        return
    end
    if isPetTabId(node.tabId) then
        local pet = player:GetPet()
        if not pet then
            player:SendBroadcastMessage("You need a pet out to learn pet talents.")
            return
        end
        local hasFn = function(id)
            return unitHasSpell(pet, id)
        end
        if hasFn(spellId) or hasFn(node.r[maxRank]) then
            sendState(player)
            return
        end
        local points = petFreeTalentPoints(pet)
        if points < 1 then
            player:SendBroadcastMessage("No pet talent points remaining.")
            return
        end
        local ok, err = talentPrereqsOk(player, hasFn, node, rank)
        if not ok then
            player:SendBroadcastMessage(err)
            return
        end
        if hasFn(spellId) then
            sendState(player)
            return
        end
        if player.LearnPetTalent then
            player:LearnPetTalent(pet:GetGUID(), talentId, rank - 1)
        end
        if not unitHasSpell(pet, spellId) and pet.LearnSpell then
            pet:LearnSpell(spellId)
            pet:SetFreeTalentPoints(points - 1)
        end
        sendState(player)
        return
    end
    local points = player:GetFreeTalentPoints() or 0
    if points < 1 then
        player:SendBroadcastMessage("No talent points remaining.")
        return
    end
    local hasFn = function(id)
        return playerHasTalentRank(player, id)
    end
    if hasFn(spellId) or hasFn(node.r[maxRank]) then
        sendState(player)
        return
    end
    local ok, err = talentPrereqsOk(player, hasFn, node, rank)
    if not ok then
        player:SendBroadcastMessage(err)
        return
    end
    if playerHasTalentRank(player, spellId) then
        sendState(player)
        return
    end
    -- Same path as the default talent frame: Player::LearnTalent → addTalent.
    if player.LearnTalent then
        player:LearnTalent(talentId, rank - 1)
    else
        player:LearnSpell(spellId)
        player:SetFreeTalentPoints(points - 1)
    end
    sendState(player)
end

function Handlers.UnlearnTalent(player, talentId, rank)
    if not classlessEnabled() then
        return
    end
    talentId = tonumber(talentId)
    rank = tonumber(rank)
    if type(talentId) ~= "number" or not player then
        return
    end
    local node = Catalog and Catalog.talentById and Catalog.talentById[talentId]
    if not node then
        return
    end
    if isPetTabId(node.tabId) then
        local pet = player:GetPet()
        if not pet then
            return
        end
        local hasFn = function(id)
            return unitHasSpell(pet, id)
        end
        local current = highestKnownTalentRank(hasFn, node)
        if current < 1 then
            return
        end
        local orphaned, err = unlearnWouldOrphan(player, hasFn, node, true)
        if orphaned then
            player:SendBroadcastMessage(err)
            return
        end
        local spellId = node.r[current]
        if pet.UnlearnSpell then
            pet:UnlearnSpell(spellId, current > 1, true)
        elseif pet.RemoveSpell then
            pet:RemoveSpell(spellId, current > 1, true)
        end
        sendState(player)
        return
    end
    local hasFn = function(id)
        return playerHasTalentRank(player, id)
    end
    local current = highestKnownTalentRank(hasFn, node)
    if player.GetClasslessTalentRank then
        current = tonumber(player:GetClasslessTalentRank(node.id)) or current
    end
    if current < 1 then
        return
    end
    local orphaned, err = unlearnWouldOrphan(player, hasFn, node, false)
    if orphaned then
        player:SendBroadcastMessage(err)
        return
    end
    local spellId = node.r[current]
    local prevId = current > 1 and node.r[current - 1] or 0
    if not player.DropTalentRank then
        player:SendBroadcastMessage("Talent unlearn is unavailable (server needs a rebuild).")
        return
    end
    local dropped = player:DropTalentRank(spellId, prevId or 0)
    if not dropped then
        return
    end
    local points = player:GetFreeTalentPoints() or 0
    player:SetFreeTalentPoints(points + 1)
    sendState(player)
end

local function OnCommand(event, player, command)
    if command == "classless" then
        pushEnabled(player)
        if not classlessEnabled() then
            if player then
                player:SendBroadcastMessage("Classless module is disabled.")
            end
            return false
        end
        AIO.Handle(player, "ClasslessUIClient", "ShowUI")
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)
if RegisterPlayerEvent then
    RegisterPlayerEvent(3, function(_, player)
        pushEnabled(player)
    end)
end
