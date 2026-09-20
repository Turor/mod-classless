local AIO = AIO or require("AIO")
if not AIO.IsMainState() then
    return
end

-- The 3.3.5 client only updates GetRuneCooldown for UnitClass DK.
-- Classless IsClass(ABILITY) inits runes for every class, so remaining CD
-- is pushed from here.

local Handlers = AIO.AddHandlers("ClasslessResourceBarServer", {})
local lastRuneKey = {}

local function runeReadyBit(mask, i)
    mask = tonumber(mask) or 0
    local bitv = 2 ^ (i - 1)
    return (math.floor(mask / bitv) % 2) == 1
end

local function pushRuneCooldowns(player)
    if not player then
        return
    end
    local cds = {}
    local keyParts = {}
    local mask
    if player.GetRunesState then
        local ok, value = pcall(function()
            return player:GetRunesState()
        end)
        if ok then
            mask = value
        end
    end
    for i = 1, 6 do
        local ms = 0
        if player.GetRuneCooldown then
            ms = tonumber(player:GetRuneCooldown(i)) or 0
        elseif mask ~= nil then
            ms = runeReadyBit(mask, i) and 0 or 10000
        else
            return
        end
        cds[i] = ms
        keyParts[i] = (ms > 50) and 1 or 0
    end
    local guid = player.GetGUIDLow and player:GetGUIDLow() or tostring(player)
    local key = table.concat(keyParts, "")
    if lastRuneKey[guid] == key then
        return
    end
    lastRuneKey[guid] = key
    AIO.Handle(player, "ClasslessResourceBar", "ApplyRuneCooldowns", cds)
end

function Handlers.RequestRuneCooldowns(player)
    if player then
        lastRuneKey[player.GetGUIDLow and player:GetGUIDLow() or tostring(player)] = nil
        pushRuneCooldowns(player)
    end
end

if RegisterPlayerEvent then
    RegisterPlayerEvent(3, function(_, player)
        pushRuneCooldowns(player)
    end)
    RegisterPlayerEvent(4, function(_, player)
        if player and player.GetGUIDLow then
            lastRuneKey[player:GetGUIDLow()] = nil
        end
    end)
    RegisterPlayerEvent(5, function(_, player)
        pushRuneCooldowns(player)
    end)
end
if CreateLuaEvent then
    CreateLuaEvent(function()
        if not GetPlayersInWorld then
            return
        end
        for _, player in pairs(GetPlayersInWorld()) do
            pushRuneCooldowns(player)
        end
    end, 200, 0)
end
