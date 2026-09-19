local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local Handlers = AIO.AddHandlers("ClasslessUIClient", {})
local Catalog = ClasslessUICatalog

local FRAME_W, FRAME_H = 1000, 700
local HEADER_CLASS_H = 100
local HEADER_TAB_H = 52
local PANE_PAD = 12

local ui = {
    frame = nil,
    classButtons = {},
    specButtons = {},
    extraButtons = {},
    selectedClassId = 6,
    selectedSpecIndex = 1,
    selectedExtra = nil, -- "glyph" | "pet" | nil
    spellPane = nil,
    talentPane = nil,
    spellButtons = {},
    talentButtons = {},
    talentBranchPool = {},
    spellRankSel = {},
    state = { learned = {}, learnable = {}, points = 0 },
}

local refreshPanes

local SPELL_ICON = 36
local SPELL_BORDER = 64
local SPELL_ARROW = 24
local SPELL_CELL_W = 112
local SPELL_CELL_H = 80
local TALENT_ICON = 32
local TALENT_GAP = 63
local TALENT_OFF_X = 28
local TALENT_OFF_Y = 12

local function setShown(tex, shown)
    if not tex then
        return
    end
    if shown then
        tex:Show()
    else
        tex:Hide()
    end
end

local function classInfo(classId)
    return Catalog and Catalog.classes and Catalog.classes[classId]
end

local function highlightButton(btn, on)
    setShown(btn and btn.SelectedTexture, on)
end

local function createIconButton(name, parent, w, h, iconSize)
    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(w, h)
    btn:RegisterForClicks("LeftButtonUp")

    local icon = btn:CreateTexture(name and (name .. "Icon") or nil, "BACKGROUND")
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("TOP", 0, 0)
    btn.Icon = icon

    local selected = btn:CreateTexture(name and (name .. "Selected") or nil, "ARTWORK")
    selected:SetSize(iconSize, iconSize)
    selected:SetPoint("TOP", 0, 0)
    selected:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    selected:SetBlendMode("ADD")
    selected:Hide()
    btn.SelectedTexture = selected

    local hilight = btn:CreateTexture(nil, "HIGHLIGHT")
    hilight:SetSize(iconSize, iconSize)
    hilight:SetPoint("TOP", 0, 0)
    hilight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hilight:SetBlendMode("ADD")

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    label:SetWidth(w + 16)
    label:SetJustifyH("CENTER")
    btn.Label = label

    return btn
end

local function createTabButton(name, parent, w, h)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetSize(w, h)
    btn:RegisterForClicks("LeftButtonUp")

    local selected = btn:CreateTexture(nil, "OVERLAY")
    selected:SetAllPoints(btn)
    selected:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    selected:SetBlendMode("ADD")
    selected:Hide()
    btn.SelectedTexture = selected

    return btn
end

local function layoutCornerArt(pane)
    local art = pane.CornerArt
    if not art then
        return
    end
    -- Anchor to CENTER so the four pieces always fill the pane, including
    -- while it is being resized (GetWidth can be 0 before first layout).
    art.TopLeft:ClearAllPoints()
    art.TopLeft:SetPoint("TOPLEFT", 4, -4)
    art.TopLeft:SetPoint("BOTTOMRIGHT", pane, "CENTER", 0, 0)
    art.TopRight:ClearAllPoints()
    art.TopRight:SetPoint("TOPRIGHT", -4, -4)
    art.TopRight:SetPoint("BOTTOMLEFT", pane, "CENTER", 0, 0)
    art.BottomLeft:ClearAllPoints()
    art.BottomLeft:SetPoint("BOTTOMLEFT", 4, 4)
    art.BottomLeft:SetPoint("TOPRIGHT", pane, "CENTER", 0, 0)
    art.BottomRight:ClearAllPoints()
    art.BottomRight:SetPoint("BOTTOMRIGHT", -4, 4)
    art.BottomRight:SetPoint("TOPLEFT", pane, "CENTER", 0, 0)
end

local function setPanePaper(pane)
    local art = pane.CornerArt
    if not art then
        return
    end
    -- 3.3.5 spellbook page pieces (Spellbook-Page-1 does not exist in WotLK).
    art.TopLeft:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-TopLeft")
    art.TopLeft:SetTexCoord(0, 1, 0, 1)
    art.TopRight:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-TopRight")
    art.TopRight:SetTexCoord(0, 1, 0, 1)
    art.BottomLeft:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-BotLeft")
    art.BottomLeft:SetTexCoord(0, 1, 0, 1)
    art.BottomRight:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-BotRight")
    art.BottomRight:SetTexCoord(0, 1, 0, 1)
    layoutCornerArt(pane)
end

local function setPaneTalentArt(pane, tabId)
    local art = pane.CornerArt
    if not art then
        return
    end
    local bg = Catalog and Catalog.tabBg and Catalog.tabBg[tabId]
    if not bg then
        setPanePaper(pane)
        return
    end
    local base = "Interface\\TalentFrame\\" .. bg .. "-"
    art.TopLeft:SetTexture(base .. "TopLeft")
    art.TopLeft:SetTexCoord(0, 1, 0, 1)
    art.TopRight:SetTexture(base .. "TopRight")
    art.TopRight:SetTexCoord(0, 1, 0, 1)
    art.BottomLeft:SetTexture(base .. "BottomLeft")
    art.BottomLeft:SetTexCoord(0, 1, 0, 1)
    art.BottomRight:SetTexture(base .. "BottomRight")
    art.BottomRight:SetTexCoord(0, 1, 0, 1)
    layoutCornerArt(pane)
end

local function createScrollPane(name, parent, title)
    local pane = CreateFrame("Frame", name, parent)
    pane:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    pane:SetBackdropColor(0, 0, 0, 0)

    local art = {}
    for _, key in ipairs({ "TopLeft", "TopRight", "BottomLeft", "BottomRight" }) do
        local tex = pane:CreateTexture(nil, "BACKGROUND")
        tex:SetDrawLayer("BACKGROUND", 1)
        tex:Show()
        art[key] = tex
    end
    pane.CornerArt = art
    setPanePaper(pane)

    local titleFs = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs:SetPoint("TOP", 0, -8)
    titleFs:SetText(title)
    pane.Title = titleFs

    local scroll = CreateFrame("ScrollFrame", name .. "Scroll", pane, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -28)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local child = CreateFrame("Frame", name .. "Child", scroll)
    child:SetWidth(1)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    pane.Scroll = scroll
    pane.Child = child

    local points = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    points:SetPoint("BOTTOMLEFT", 10, 6)
    points:SetText("")
    pane.Points = points
    return pane
end

local function isKnown(spellId)
    if not spellId then
        return false
    end
    local learned = ui.state.learned
    if learned and (learned[spellId] or learned[tostring(spellId)]) then
        return true
    end
    if IsSpellKnown and IsSpellKnown(spellId) then
        return true
    end
    return false
end

local function isLearnable(spellId)
    if not spellId then
        return false
    end
    local t = ui.state.learnable
    if not t then
        return false
    end
    return t[spellId] or t[tostring(spellId)]
end

local function talentRank(node)
    local rank = 0
    for i, spellId in ipairs(node.r) do
        if isKnown(spellId) then
            rank = i
        end
    end
    return rank
end

local function specSpellIds()
    local info = classInfo(ui.selectedClassId)
    local spec = info and info.specs and info.specs[ui.selectedSpecIndex]
    if not spec or not Catalog or not Catalog.spells then
        return {}, spec
    end
    local byClass = Catalog.spells[ui.selectedClassId]
    return (byClass and byClass[spec.id]) or {}, spec
end

local function groupSpellFamilies(ids)
    local byName = {}
    local families = {}
    for _, spellId in ipairs(ids) do
        local name, rank, icon = GetSpellInfo(spellId)
        if name then
            local fam = byName[name]
            if not fam then
                fam = { name = name, icon = icon, ids = {} }
                byName[name] = fam
                families[#families + 1] = fam
            end
            fam.ids[#fam.ids + 1] = spellId
            if icon and not fam.icon then
                fam.icon = icon
            end
        end
    end
    for _, fam in ipairs(families) do
        table.sort(fam.ids)
        local highestKnown = 1
        for i, id in ipairs(fam.ids) do
            if isKnown(id) then
                highestKnown = i
            end
        end
        local selected = ui.spellRankSel[fam.name] or highestKnown
        if selected < 1 then
            selected = 1
        elseif selected > #fam.ids then
            selected = #fam.ids
        end
        fam.selected = selected
        ui.spellRankSel[fam.name] = selected
    end
    table.sort(families, function(a, b)
        return a.name < b.name
    end)
    return families
end

local function cursorHasSpell()
    if CursorHasSpell and CursorHasSpell() then
        return true
    end
    if GetCursorInfo then
        local kind = GetCursorInfo()
        return kind == "spell"
    end
    return false
end

local function bookTypeSpell()
    return BOOKTYPE_SPELL or "spell"
end

local function spellBookSlotForId(spellId)
    local book = bookTypeSpell()
    local wantName, wantRank = GetSpellInfo(spellId)
    local function slotMatches(slot)
        local link = GetSpellLink and GetSpellLink(slot, book)
        if link then
            local id = tonumber(string.match(link, "spell:(%d+)"))
            if id == spellId then
                return true
            end
        end
        if wantName and GetSpellName then
            local n, r = GetSpellName(slot, book)
            if n == wantName and (not wantRank or wantRank == "" or r == wantRank) then
                return true
            end
        end
        return false
    end
    if GetNumSpellTabs and GetSpellTabInfo then
        local tabs = GetNumSpellTabs() or 0
        for tab = 1, tabs do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            offset = offset or 0
            numSpells = numSpells or 0
            for i = 1, numSpells do
                local slot = offset + i
                if slotMatches(slot) then
                    return slot
                end
            end
        end
    end
    local maxSlots = MAX_SPELLS or 1024
    for slot = 1, maxSlots do
        if slotMatches(slot) then
            return slot
        end
    end
    return nil
end

local function pickupSpellId(spellId)
    if not spellId or not isKnown(spellId) then
        return
    end
    if ClearCursor then
        ClearCursor()
    end
    local name, rank = GetSpellInfo(spellId)
    local slot = spellBookSlotForId(spellId)
    if slot and PickupSpell then
        pcall(PickupSpell, slot, bookTypeSpell())
        if cursorHasSpell() then
            return
        end
    end
    if name and PickupSpell then
        if rank and rank ~= "" then
            pcall(PickupSpell, name, rank)
            if cursorHasSpell() then
                return
            end
        end
        pcall(PickupSpell, name)
        if cursorHasSpell() then
            return
        end
        pcall(PickupSpell, spellId)
    end
end

local function castSpellId(spellId)
    if not spellId or not isKnown(spellId) then
        return
    end
    local book = bookTypeSpell()
    local slot = spellBookSlotForId(spellId)
    local onSelf = IsModifiedClick and IsModifiedClick("SELFCAST")
    if slot and CastSpell then
        if onSelf then
            pcall(CastSpell, slot, book, true)
        else
            pcall(CastSpell, slot, book)
        end
        return
    end
    local name, rank = GetSpellInfo(spellId)
    if name and CastSpellByName then
        local cmd = name
        if rank and rank ~= "" then
            cmd = name .. "(" .. rank .. ")"
        end
        pcall(CastSpellByName, cmd, onSelf)
    end
end

local function createSpellButton(index)
    local parent = ui.spellPane.Child
    local name = "ClasslessUISpellBtn" .. index
    local btn = CreateFrame("Frame", name, parent)
    btn:SetSize(SPELL_CELL_W, SPELL_CELL_H)
    btn:EnableMouse(false)

    local iconBtn = CreateFrame("Button", name .. "Icon", btn)
    iconBtn:SetSize(SPELL_ICON, SPELL_ICON)
    iconBtn:SetPoint("CENTER", 0, 6)
    iconBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    iconBtn:RegisterForDrag("LeftButton")
    iconBtn:EnableMouse(true)
    btn.IconBtn = iconBtn

    local prev = CreateFrame("Button", name .. "Prev", btn)
    prev:SetSize(SPELL_ARROW, SPELL_ARROW)
    prev:SetPoint("RIGHT", iconBtn, "LEFT", 2, 0)
    prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    btn.Prev = prev

    local icon = iconBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconBtn)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.Icon = icon

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetSize(SPELL_BORDER, SPELL_BORDER)
    border:SetPoint("CENTER", iconBtn, "CENTER")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    btn.Border = border

    local plus = iconBtn:CreateTexture(nil, "OVERLAY")
    plus:SetSize(18, 18)
    plus:SetPoint("TOPLEFT", -3, 3)
    plus:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    plus:SetVertexColor(0.15, 1, 0.15)
    plus:Hide()
    btn.Plus = plus

    local next = CreateFrame("Button", name .. "Next", btn)
    next:SetSize(SPELL_ARROW, SPELL_ARROW)
    next:SetPoint("LEFT", iconBtn, "RIGHT", -2, 0)
    next:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    next:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    next:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    btn.Next = next

    local rankFs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankFs:SetPoint("TOP", iconBtn, "BOTTOM", 0, -1)
    btn.RankText = rankFs

    local hilight = iconBtn:CreateTexture(nil, "HIGHLIGHT")
    hilight:SetAllPoints(iconBtn)
    hilight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hilight:SetBlendMode("ADD")

    local function selectedId()
        if not btn.family then
            return nil
        end
        return btn.family.ids[btn.family.selected]
    end

    local function updatePlus()
        local id = selectedId()
        if isLearnable(id) then
            plus:Show()
        else
            plus:Hide()
        end
    end

    prev:SetScript("OnClick", function()
        if btn.family and btn.family.selected > 1 then
            btn.family.selected = btn.family.selected - 1
            ui.spellRankSel[btn.family.name] = btn.family.selected
            refreshPanes()
        end
    end)
    next:SetScript("OnClick", function()
        if btn.family and btn.family.selected < #btn.family.ids then
            btn.family.selected = btn.family.selected + 1
            ui.spellRankSel[btn.family.name] = btn.family.selected
            refreshPanes()
        end
    end)

    iconBtn:SetScript("OnEnter", function(self)
        local id = selectedId()
        if not id then
            plus:Hide()
            return
        end
        updatePlus()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. id)
        GameTooltip:Show()
    end)
    iconBtn:SetScript("OnLeave", function()
        plus:Hide()
        GameTooltip:Hide()
    end)
    iconBtn:SetScript("OnClick", function(self, mouse)
        local id = selectedId()
        if not id then
            return
        end
        if mouse == "RightButton" then
            return
        end
        if not isKnown(id) then
            AIO.Handle("ClasslessUIServer", "LearnSpell", id)
            return
        end
        if IsModifiedClick and IsModifiedClick("PICKUPACTION") then
            pickupSpellId(id)
            return
        end
        AIO.Handle("ClasslessUIServer", "CastSpell", id)
    end)
    iconBtn:SetScript("OnDragStart", function()
        local id = selectedId()
        if id and isKnown(id) then
            pickupSpellId(id)
        end
    end)

    return btn
end

local function createTalentButton(index)
    local parent = ui.talentPane.Child
    local name = "ClasslessUITalentBtn" .. index
    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(TALENT_ICON, TALENT_ICON)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(btn)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.Icon = icon

    local slot = btn:CreateTexture(nil, "OVERLAY")
    slot:SetPoint("CENTER")
    slot:SetSize(64, 64)
    slot:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    btn.Slot = slot

    local rankFs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankFs:SetPoint("BOTTOMRIGHT", 2, -2)
    btn.RankText = rankFs

    local hilight = btn:CreateTexture(nil, "HIGHLIGHT")
    hilight:SetAllPoints(btn)
    hilight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hilight:SetBlendMode("ADD")

    btn:SetScript("OnEnter", function(self)
        if not self.node then
            return
        end
        local rank = math.max(talentRank(self.node), 1)
        local id = self.node.r[rank]
        if not id then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. id)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function(self, mouse)
        if not self.node then
            return
        end
        local current = talentRank(self.node)
        if mouse == "RightButton" then
            if current > 0 then
                AIO.Handle("ClasslessUIServer", "UnlearnTalent", self.node.id, current)
            end
            return
        end
        if current < #self.node.r then
            AIO.Handle("ClasslessUIServer", "LearnTalent", self.node.id, current + 1)
        else
            local id = self.node.r[current]
            if id and isKnown(id) then
                pickupSpellId(id)
            end
        end
    end)
    btn:SetScript("OnDragStart", function(self)
        if not self.node then
            return
        end
        local current = talentRank(self.node)
        local id = self.node.r[math.max(current, 1)]
        if id and isKnown(id) then
            pickupSpellId(id)
        end
    end)
    return btn
end

local function hidePool(pool, fromIndex)
    for i = fromIndex, #pool do
        pool[i]:Hide()
    end
end

local function renderSpellbook(ids)
    local families = groupSpellFamilies(ids or {})
    local child = ui.spellPane.Child
    local paneW = math.max(ui.spellPane:GetWidth() - 36, SPELL_CELL_W)
    local cols = math.max(2, math.floor(paneW / SPELL_CELL_W))
    local width = math.max(paneW, cols * SPELL_CELL_W)
    child:SetWidth(width)
    local rows = math.max(1, math.ceil(#families / cols))
    child:SetHeight(math.max(rows * SPELL_CELL_H + 8, ui.spellPane:GetHeight() - 40))

    for i, fam in ipairs(families) do
        local btn = ui.spellButtons[i]
        if not btn then
            btn = createSpellButton(i)
            ui.spellButtons[i] = btn
        end
        btn.family = fam
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 4 + col * SPELL_CELL_W, -4 - row * SPELL_CELL_H)
        local sel = fam.selected or 1
        local id = fam.ids[sel]
        local _, _, icon = GetSpellInfo(id)
        btn.Icon:SetTexture(icon or fam.icon)
        if btn.Icon.SetDesaturated then
            btn.Icon:SetDesaturated(not isKnown(id))
        end
        btn.RankText:SetText(sel .. "/" .. #fam.ids)
        if sel > 1 then
            btn.Prev:Enable()
        else
            btn.Prev:Disable()
        end
        if sel < #fam.ids then
            btn.Next:Enable()
        else
            btn.Next:Disable()
        end
        btn:Show()
    end
    hidePool(ui.spellButtons, #families + 1)
end

local function renderTalentTree(tabId, yOffset, startIndex)
    yOffset = yOffset or 0
    startIndex = startIndex or 1
    local nodes = Catalog and Catalog.talents and Catalog.talents[tabId] or {}
    local used = startIndex - 1
    local maxTier = 0
    for _, node in ipairs(nodes) do
        used = used + 1
        local btn = ui.talentButtons[used]
        if not btn then
            btn = createTalentButton(used)
            ui.talentButtons[used] = btn
        end
        btn.node = node
        local rank = talentRank(node)
        local id = node.r[math.max(rank, 1)]
        local _, _, icon = GetSpellInfo(id)
        btn.Icon:SetTexture(icon)
        if btn.Icon.SetDesaturated then
            btn.Icon:SetDesaturated(rank == 0)
        end
        btn.RankText:SetText(rank .. "/" .. #node.r)
        if rank == 0 then
            btn.Slot:SetVertexColor(0.5, 0.5, 0.5)
        elseif rank < #node.r then
            btn.Slot:SetVertexColor(0.1, 1.0, 0.1)
        else
            btn.Slot:SetVertexColor(1.0, 0.82, 0)
        end
        local x = TALENT_OFF_X + (node.c * TALENT_GAP)
        local y = yOffset - TALENT_OFF_Y - (node.t * TALENT_GAP) -- yOffset is already negative or 0
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", x, y)
        btn:Show()
        if node.t > maxTier then
            maxTier = node.t
        end
    end
    return used, (maxTier + 1) * TALENT_GAP + TALENT_OFF_Y + 24
end

local function refreshSpecButtons()
    local info = classInfo(ui.selectedClassId)
    local specs = info and info.specs or {}
    for i = 1, 4 do
        local btn = ui.specButtons[i]
        local spec = specs[i]
        if spec then
            btn:SetText(spec.name)
            btn.spec = spec
            btn:Show()
            highlightButton(btn, ui.selectedExtra == nil and ui.selectedSpecIndex == i)
        else
            btn:Hide()
            highlightButton(btn, false)
        end
    end
    for _, extra in ipairs(ui.extraButtons) do
        highlightButton(extra, ui.selectedExtra == extra.extraId)
    end
end

function refreshPanes()
    if not ui.spellPane then
        return
    end
    local info = classInfo(ui.selectedClassId)
    local className = info and info.name or "?"
    local points = ui.state.points or 0
    ui.talentPane.Points:SetText("Unspent: " .. tostring(points))
    ui.spellPane.Points:SetText("")

    if ui.selectedExtra == "glyph" then
        ui.spellPane.Title:SetText(className .. " glyphs")
        ui.talentPane.Title:SetText("Glyph slots")
        setPanePaper(ui.spellPane)
        setPanePaper(ui.talentPane)
        renderSpellbook({})
        hidePool(ui.talentButtons, 1)
        return
    end
    if ui.selectedExtra == "pet" then
        ui.spellPane.Title:SetText("Pet spells")
        ui.talentPane.Title:SetText("Pet talents")
        setPanePaper(ui.spellPane)
        local petTabs = (Catalog and Catalog.petTabs) or { 409, 410, 411 }
        setPaneTalentArt(ui.talentPane, petTabs[1])
        renderSpellbook({})
        local tabs = (Catalog and Catalog.petTabs) or { 409, 410, 411 }
        local used = 0
        local totalHeight = 0
        for _, tabId in ipairs(tabs) do
            local u, h = renderTalentTree(tabId, -totalHeight, used + 1)
            used = u
            totalHeight = totalHeight + h
        end
        hidePool(ui.talentButtons, used + 1)
        ui.talentPane.Child:SetWidth(4 * TALENT_GAP + TALENT_OFF_X + 40)
        ui.talentPane.Child:SetHeight(math.max(totalHeight + 20, 200))
        return
    end

    local ids, spec = specSpellIds()
    local specName = spec and spec.name or "?"
    ui.spellPane.Title:SetText(specName .. " spells")
    ui.talentPane.Title:SetText(specName .. " talents")
    setPanePaper(ui.spellPane)
    setPaneTalentArt(ui.talentPane, spec and spec.tabId)
    renderSpellbook(ids)
    hidePool(ui.talentButtons, 1)
    local tabId = spec and spec.tabId
    local used, height = renderTalentTree(tabId, 0)
    hidePool(ui.talentButtons, used + 1)
    ui.talentPane.Child:SetWidth(4 * TALENT_GAP + TALENT_OFF_X + 40)
    ui.talentPane.Child:SetHeight(math.max(height, 200))
end

local function selectClass(classId)
    ui.selectedClassId = classId
    ui.selectedSpecIndex = 1
    ui.selectedExtra = nil
    for _, btn in ipairs(ui.classButtons) do
        highlightButton(btn, btn.classId == classId)
    end
    refreshSpecButtons()
    refreshPanes()
end

local function selectSpec(index)
    ui.selectedSpecIndex = index
    ui.selectedExtra = nil
    refreshSpecButtons()
    refreshPanes()
end

local function selectExtra(extraId)
    ui.selectedExtra = extraId
    refreshSpecButtons()
    refreshPanes()
end

local function buildFrame()
    if ui.frame then
        return ui.frame
    end

    local frame = CreateFrame("Frame", "ClasslessUIFrame", UIParent)
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetMinResize then
        frame:SetMinResize(800, 520)
        frame:SetMaxResize(1600, 1100)
    end
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    tinsert(UISpecialFrames, "ClasslessUIFrame")

    local grip = CreateFrame("Button", "ClasslessUIFrameResize", frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -6, 6)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatFrame-ResizeButton")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatFrame-ResizeButton")
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        if refreshPanes then
            refreshPanes()
        end
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Classless")

    local close = CreateFrame("Button", "ClasslessUIFrameClose", frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local classRow = CreateFrame("Frame", "ClasslessUIClassRow", frame)
    classRow:SetPoint("TOPLEFT", 20, -36)
    classRow:SetPoint("TOPRIGHT", -20, -36)
    classRow:SetHeight(HEADER_CLASS_H)

    local order = Catalog and Catalog.classOrder or {}
    local count = #order
    local btnW = 64
    local gap = 12
    local totalW = count * btnW + math.max(count - 1, 0) * gap

    local function layoutClassRow()
        local startX = math.max((frame:GetWidth() - 40 - totalW) / 2, 0)
        for i, btn in ipairs(ui.classButtons) do
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", startX + (i - 1) * (btnW + gap), 0)
        end
    end

    for i, classId in ipairs(order) do
        local info = classInfo(classId)
        local btn = createIconButton("ClasslessUIClass" .. classId, classRow, btnW, 80, 56)
        btn:SetPoint("TOPLEFT", 0, 0)
        btn.classId = classId
        if info then
            btn.Icon:SetTexture(info.icon)
            btn.Label:SetText(info.name)
        end
        btn:SetScript("OnClick", function()
            selectClass(classId)
        end)
        ui.classButtons[#ui.classButtons + 1] = btn
    end

    local tabRow = CreateFrame("Frame", "ClasslessUITabRow", frame)
    tabRow:SetPoint("TOPLEFT", 16, -36 - HEADER_CLASS_H)
    tabRow:SetPoint("TOPRIGHT", -16, -36 - HEADER_CLASS_H)
    tabRow:SetHeight(HEADER_TAB_H)

    local tabW, tabH, tabGap = 120, 36, 8
    for i = 1, 4 do
        local btn = createTabButton("ClasslessUISpec" .. i, tabRow, tabW, tabH)
        btn:SetPoint("LEFT", (i - 1) * (tabW + tabGap), 0)
        btn:SetScript("OnClick", function()
            selectSpec(i)
        end)
        ui.specButtons[i] = btn
    end

    local extras = Catalog and Catalog.extraTabs or {}
    for i, extra in ipairs(extras) do
        local btn = createTabButton("ClasslessUIExtra" .. extra.id, tabRow, tabW, tabH)
        btn:SetPoint("LEFT", (4 + i - 1) * (tabW + tabGap), 0)
        btn:SetText(extra.name)
        btn.extraId = extra.id
        btn:SetScript("OnClick", function()
            selectExtra(extra.id)
        end)
        ui.extraButtons[#ui.extraButtons + 1] = btn
    end

    local bodyTop = -(36 + HEADER_CLASS_H + HEADER_TAB_H + 4)
    local body = CreateFrame("Frame", "ClasslessUIBody", frame)
    body:SetPoint("TOPLEFT", PANE_PAD, bodyTop)
    body:SetPoint("BOTTOMRIGHT", -PANE_PAD, PANE_PAD)

    ui.spellPane = createScrollPane("ClasslessUISpellPane", body, "Spells")
    ui.spellPane:SetPoint("TOPLEFT")
    ui.spellPane:SetPoint("BOTTOMLEFT")
    ui.spellPane:SetPoint("RIGHT", body, "CENTER", -6, 0)

    ui.talentPane = createScrollPane("ClasslessUITalentPane", body, "Talents")
    ui.talentPane:SetPoint("TOPRIGHT")
    ui.talentPane:SetPoint("BOTTOMRIGHT")
    ui.talentPane:SetPoint("LEFT", body, "CENTER", 6, 0)

    frame:SetScript("OnShow", function()
        AIO.Handle("ClasslessUIServer", "RequestState")
        refreshPanes()
    end)
    frame:SetScript("OnSizeChanged", function()
        layoutClassRow()
        if ui.spellPane then
            layoutCornerArt(ui.spellPane)
        end
        if ui.talentPane then
            layoutCornerArt(ui.talentPane)
        end
    end)

    ui.frame = frame
    layoutClassRow()
    selectClass(ui.selectedClassId)
    return frame
end

function Handlers.ShowUI(player)
    local frame = buildFrame()
    frame:Show()
    AIO.Handle("ClasslessUIServer", "RequestState")
end

function Handlers.ApplyState(player, state)
    if type(state) == "table" then
        local learned = {}
        if type(state.learned) == "table" then
            for k, v in pairs(state.learned) do
                if v then
                    local id = tonumber(k) or k
                    learned[id] = true
                end
            end
        end
        local learnable = {}
        if type(state.learnable) == "table" then
            for k, v in pairs(state.learnable) do
                if v then
                    local id = tonumber(k) or k
                    learnable[id] = true
                end
            end
        end
        ui.state = {
            learned = learned,
            learnable = learnable,
            points = tonumber(state.points) or 0,
        }
    end
    if ui.frame and ui.frame:IsShown() then
        refreshPanes()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("SPELLS_CHANGED")
local lastStateReq = 0
events:SetScript("OnEvent", function()
    if not (ui.frame and ui.frame:IsShown()) then
        return
    end
    local now = (GetTime and GetTime()) or 0
    if now > 0 and (now - lastStateReq) < 0.25 then
        return
    end
    lastStateReq = now
    AIO.Handle("ClasslessUIServer", "RequestState")
end)

SLASH_CLASSLESSUI1 = "/classless"
SlashCmdList["CLASSLESSUI"] = function()
    local frame = buildFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        Handlers.ShowUI()
    end
end
