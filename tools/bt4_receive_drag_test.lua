-- Models 3.3.5 SecureHandlers Wrapped_Drag + PickupAny against Bartender4's OnReceiveDrag wraps.
-- Protected PlaceAction/PickupAction are refused in combat when called from tainted (addon) code.
-- usage: lua5.1 tools/bt4_receive_drag_test.lua UIMods/patch-n/Interface/AddOns/Bartender4/ActionButton.lua
local src = assert(io.open(arg[1])):read("*a")
local wraps, pass, fail = {}, 0, 0
for call in src:gmatch('WrapScript%(button, "OnReceiveDrag",(.-%]%])%)\n') do
    local blocks = {}
    for b in call:gmatch("%[%[(.-)%]%]") do blocks[#blocks + 1] = b end
    wraps[#wraps + 1] = { pre = blocks[1], post = blocks[2] }
end
local function check(n, c) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. n) end end
local W = {}
local function newWorld(combat, cursor)
    W = { combat = combat, cursor = cursor, slots = {}, blocked = 0, autoassist = 0 }
end
local function protected(name, f)
    return function(tainted, ...)
        if W.combat and tainted then W.blocked = W.blocked + 1; return end
        return f(...)
    end
end
local PickupAction = protected("PickupAction", function(slot)
    local old = W.slots[slot]; W.slots[slot] = W.cursor; W.cursor = old
end)
local PlaceAction = PickupAction
local self = { GetAttribute = function(_, k) if k == "action" then return 25 end; if k == "UpdateAutoAssist" then return "AA" end end }
local control = { RunFor = function(_, _, snip) if snip == "AA" then W.autoassist = W.autoassist + 1 end end }
local function snippet(body)
    return assert(loadstring("local self, button, kind, value, control = ...\n" .. body))
end
-- Wrapped_Drag(inner): pre may pick up (secure) or return a message; then the inner handler; post if message.
local function handler(level)
    if level == 0 then  -- template OnReceiveDrag: PlaceAction(self.action), self.action set by addon code = tainted
        return function() PlaceAction(true, 25) end
    end
    local w, inner = wraps[level], handler(level - 1)
    return function()
        local kind = W.cursor and W.cursor.kind
        local t, a = snippet(w.pre)(self, "LeftButton", kind, W.cursor and W.cursor.id, control)
        if t == false then return end
        local msg
        if t == "message" then msg = a elseif t == "action" then PickupAction(false, a); return end
        inner()
        if w.post and msg ~= nil then snippet(w.post)(self, msg, "LeftButton", nil, control) end
    end
end
check("two OnReceiveDrag wraps found", #wraps == 2)
local drop = handler(#wraps)
newWorld(true, { kind = "spell", id = 133 }); drop()
check("in combat: spell lands on the bar", W.slots[25] and W.slots[25].id == 133 and W.blocked == 0)
check("in combat: auto-assist refresh still runs", W.autoassist == 1)
newWorld(true, { kind = "spell", id = 133 }); W.slots[25] = { kind = "spell", id = 5 }; drop()
check("in combat: old action swaps onto the cursor", W.cursor and W.cursor.id == 5 and W.slots[25].id == 133)
newWorld(false, { kind = "macro", id = 3 }); drop()
check("out of combat: macro placed", W.slots[25] and W.slots[25].id == 3)
newWorld(true, nil); drop()
check("empty cursor: falls through, nothing blocked that matters", W.slots[25] == nil)
-- the old wrap (empty pre) reproduces the bug
wraps = { { pre = "", post = 'control:RunFor(self, self:GetAttribute("UpdateAutoAssist"))' } }
drop = handler(1)
newWorld(true, { kind = "spell", id = 133 }); drop()
check("old wrap: blocked in combat (the bug)", W.slots[25] == nil and W.blocked == 1)
print(("bt4 receive-drag test: %d passed, %d failed"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
