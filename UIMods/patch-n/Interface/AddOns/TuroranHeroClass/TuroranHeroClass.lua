-- Turoran: the Hero class (ChrClasses ID 10, file token "HERO") is not in Blizzard's FrameXML tables.
-- Anything that indexes those tables by class token (chat class colours, raid/party frames, who list,
-- LFG, addons) would hit nil for a Hero. Register sensible defaults once, before other addons run.
local TOKEN = "HERO"

if RAID_CLASS_COLORS and not RAID_CLASS_COLORS[TOKEN] then
    RAID_CLASS_COLORS[TOKEN] = { r = 0.85, g = 0.70, b = 0.40 }
end

-- UI-Classes-Circles has no Hero cell; reuse the Paladin circle until a custom texture ships.
if CLASS_ICON_TCOORDS and not CLASS_ICON_TCOORDS[TOKEN] then
    CLASS_ICON_TCOORDS[TOKEN] = CLASS_ICON_TCOORDS["PALADIN"] or { 0, 0.25, 0.5, 0.75 }
end

if CLASS_SORT_ORDER then
    local present = false
    for _, token in ipairs(CLASS_SORT_ORDER) do
        if token == TOKEN then present = true break end
    end
    if not present then
        table.insert(CLASS_SORT_ORDER, TOKEN)
    end
end

if CLASS_BUTTONS and not CLASS_BUTTONS[TOKEN] then
    CLASS_BUTTONS[TOKEN] = CLASS_BUTTONS["PALADIN"]
end
