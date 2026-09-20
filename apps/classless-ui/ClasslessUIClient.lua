local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local Handlers = AIO.AddHandlers("ClasslessUIClient", {})
local Catalog = ClasslessUICatalog

-- Narrowest layout: 2 spell cols + 4 talent cols + 210px sidebar.
local FRAME_W, FRAME_H = 800, 560
local PANE_PAD = 12
local SIDEBAR_W = 210
local NAV_ROW_H = 14
local NAV_SPEC_GAP = 0
local CLASS_FILE = {
    [1] = "WARRIOR",
    [2] = "PALADIN",
    [3] = "HUNTER",
    [4] = "ROGUE",
    [5] = "PRIEST",
    [6] = "DEATHKNIGHT",
    [7] = "SHAMAN",
    [8] = "MAGE",
    [9] = "WARLOCK",
    [11] = "DRUID",
}

local function classRGB(classId)
    local file = CLASS_FILE[classId]
    local c = RAID_CLASS_COLORS and file and RAID_CLASS_COLORS[file]
    if c then
        return c.r, c.g, c.b
    end
    return 0.45, 0.45, 0.45
end

local function createBannerButton(name, parent, w, h, r, g, b, label)
    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(w, h)
    btn:RegisterForClicks("LeftButtonUp")
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(r, g, b, 0.92)
    btn.Bg = bg
    btn.baseR, btn.baseG, btn.baseB = r, g, b
    local selected = btn:CreateTexture(nil, "ARTWORK")
    selected:SetAllPoints(btn)
    selected:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    selected:SetVertexColor(1, 1, 1, 0.35)
    selected:Hide()
    btn.SelectedTexture = selected
    local hilight = btn:CreateTexture(nil, "HIGHLIGHT")
    hilight:SetAllPoints(btn)
    hilight:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    hilight:SetVertexColor(1, 1, 1, 0.2)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", 6, 0)
    fs:SetPoint("RIGHT", -4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(label or "")
    btn.Label = fs
    return btn
end

local ui = {
    frame = nil,
    classButtons = {},
    specButtons = {},
    extraButtons = {},
    navSpecButtons = {},
    navClassBlocks = {},
    navGeneral = nil,
    navGlyph = nil,
    navPet = nil,
    rightSpellButtons = {},
    glyphFrame = nil,
    glyphSockets = {},
    selectedClassId = 6,
    selectedSpecIndex = 1,
    selectedGeneral = false,
    selectedExtra = nil, -- "glyph" | "pet" | nil
    spellPane = nil,
    talentPane = nil,
    spellButtons = {},
    talentButtons = {},
    talentBranchPool = {},
    spellRankSel = {},
    state = { learned = {}, learnable = {}, petLearned = {}, petOut = false, points = 0, petPoints = 0 },
}

local refreshPanes

local SPELL_ICON = 36
local SPELL_BORDER = 64
local SPELL_ARROW = 24
local SPELL_CELL_W = 112
local SPELL_CELL_H = 92
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

-- Stock talent BGs are one 256x256 painting (TopLeft) plus a 44px right
-- strip and 75px bottom strip. SetTexture resets a Texture to native size
-- on 3.3.5, so we must SetWidth/SetHeight after every texture change.
local TALENT_ART_TL_W, TALENT_ART_TL_H = 256, 256
local TALENT_ART_TR_W, TALENT_ART_BL_H = 44, 75
local TALENT_ART_TOTAL_W = TALENT_ART_TL_W + TALENT_ART_TR_W
local TALENT_ART_TOTAL_H = TALENT_ART_TL_H + TALENT_ART_BL_H

local function layoutTalentArt(pane)
    local q = pane and pane.TalentQuads
    if not q or not q.holder or not q.holder:IsShown() then
        return
    end
    local w = pane:GetWidth()
    local h = pane:GetHeight()
    if w < 16 or h < 16 then
        return
    end
    q.holder:ClearAllPoints()
    q.holder:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, 0)
    q.holder:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", 0, 0)
    q.holder:SetWidth(w)
    q.holder:SetHeight(h)
    local tlw = w * (TALENT_ART_TL_W / TALENT_ART_TOTAL_W)
    local tlh = h * (TALENT_ART_TL_H / TALENT_ART_TOTAL_H)
    local trw = w - tlw
    local blh = h - tlh
    local function place(tex, x, y, pw, ph)
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT", q.holder, "TOPLEFT", x, -y)
        tex:SetWidth(math.max(pw, 1))
        tex:SetHeight(math.max(ph, 1))
        tex:Show()
    end
    place(q.TL, 0, 0, tlw, tlh)
    place(q.TR, tlw, 0, trw, tlh)
    place(q.BL, 0, tlh, tlw, blh)
    place(q.BR, tlw, tlh, trw, blh)
end

local function ensureTalentArt(pane)
    if pane.TalentQuads then
        return pane.TalentQuads
    end
    local holder = CreateFrame("Frame", nil, pane)
    holder:SetPoint("TOPLEFT", 0, 0)
    holder:SetPoint("BOTTOMRIGHT", 0, 0)
    holder:SetFrameLevel(pane:GetFrameLevel())
    local function makeTex()
        local tex = holder:CreateTexture(nil, "BACKGROUND")
        tex:SetDrawLayer("BACKGROUND", 0)
        return tex
    end
    pane.TalentQuads = {
        holder = holder,
        TL = makeTex(),
        TR = makeTex(),
        BL = makeTex(),
        BR = makeTex(),
    }
    pane:SetScript("OnSizeChanged", function(self)
        layoutTalentArt(self)
    end)
    return pane.TalentQuads
end

local function setPaneTalentArt(pane, tabId)
    local q = ensureTalentArt(pane)
    local bg = Catalog and Catalog.tabBg and tabId and Catalog.tabBg[tabId]
    if not bg then
        q.holder:Hide()
        if pane.PaperHold then
            pane.PaperHold:Show()
        end
        return
    end
    if pane.PaperHold then
        pane.PaperHold:Hide()
    end
    local base = "Interface\\TalentFrame\\" .. bg .. "-"
    q.TL:SetTexture(base .. "TopLeft")
    q.TL:SetTexCoord(0, 1, 0, 1)
    q.TR:SetTexture(base .. "TopRight")
    q.TR:SetTexCoord(0, 0.6875, 0, 1)
    q.BL:SetTexture(base .. "BottomLeft")
    q.BL:SetTexCoord(0, 1, 0, 0.5859375)
    q.BR:SetTexture(base .. "BottomRight")
    q.BR:SetTexCoord(0, 0.6875, 0, 0.5859375)
    q.holder:Show()
    layoutTalentArt(pane)
end

local function createScrollPane(name, parent, title)
    local pane = CreateFrame("Frame", name, parent)
    pane:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true, tileSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    pane:SetBackdropColor(0, 0, 0, 0)

    local paperHold = CreateFrame("Frame", nil, pane)
    paperHold:SetAllPoints(pane)
    paperHold:SetFrameLevel(pane:GetFrameLevel())
    local paper = paperHold:CreateTexture(nil, "BACKGROUND")
    paper:SetAllPoints(paperHold)
    paper:SetTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\SpellbookParchment")
    paper:SetAllPoints(paperHold)
    pane.Paper = paper
    pane.PaperHold = paperHold

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

    -- FontStrings on the pane sit under the ScrollFrame/talent buttons.
    -- A child frame with a higher frame level draws on top of them.
    local overlay = CreateFrame("Frame", name .. "PointsOverlay", pane)
    overlay:SetHeight(24)
    overlay:SetWidth(110)
    overlay:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 8, 8)
    overlay:SetFrameLevel(scroll:GetFrameLevel() + 20)
    overlay:EnableMouse(true)
    overlay:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    overlay:SetBackdropColor(0.2, 0.2, 0.2, 0.95)
    overlay:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
    local fs = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText("")
    overlay.Text = fs
    pane.Points = fs
    pane.PointsOverlay = overlay
    overlay:Hide()
    return pane
end

local function isKnown(spellId)
    if not spellId then
        return false
    end
    if ui.selectedExtra == "pet" then
        local pet = ui.state.petLearned
        if pet and (pet[spellId] or pet[tostring(spellId)]) then
            return true
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
    local learned = ui.state.learned
    if learned and (learned[spellId] or learned[tostring(spellId)]) then
        return true
    end
    if IsSpellKnown and IsSpellKnown(spellId) then
        return true
    end
    return false
end

local function hasPetOut()
    if ui.state.petOut then
        return true
    end
    if UnitExists and UnitExists("pet") then
        return true
    end
    return false
end

local function isLearnable(spellId)
    if not spellId then
        return false
    end
    if ui.selectedGeneral then
        return false
    end
    if Catalog and Catalog.blockedSpells and Catalog.blockedSpells[spellId] then
        return false
    end
    local t = ui.state.learnable
    if not t then
        return false
    end
    return t[spellId] or t[tostring(spellId)]
end

local function reqLevel(spellId)
    if not spellId then
        return nil
    end
    local t = ui.state.reqLevels
    if not t then
        return nil
    end
    return t[spellId] or t[tostring(spellId)]
end

local function talentRank(node)
    local learned = ui.state.learned
    if ui.selectedExtra == "pet" then
        learned = ui.state.petLearned
    end
    local rank = 0
    for i, spellId in ipairs(node.r) do
        if learned and (learned[spellId] or learned[tostring(spellId)]) then
            rank = i
        end
    end
    return rank
end

local function specSpellIds()
    if ui.selectedGeneral then
        return (Catalog and Catalog.generalSpells) or {}, { id = "general", name = "General" }
    end
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
        if Catalog and Catalog.blockedSpells and Catalog.blockedSpells[spellId] then
            -- skip
        else
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
    end
    for _, fam in ipairs(families) do
        table.sort(fam.ids, function(a, b)
            local function rankKey(id)
                local _, rank = GetSpellInfo(id)
                if rank then
                    local n = tonumber(string.match(rank, "(%d+)"))
                    if n then
                        return n
                    end
                end
                local req = reqLevel(id)
                if req then
                    return req
                end
                return id
            end
            return rankKey(a) < rankKey(b)
        end)
        local highestKnown = 0
        for i, id in ipairs(fam.ids) do
            if isKnown(id) then
                highestKnown = i
            end
        end
        local selected = ui.spellRankSel[fam.name]
        if not selected then
            selected = (highestKnown > 0) and highestKnown or 1
        end
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
        if not slot or slot < 1 then
            return false
        end
        if GetSpellLink then
            local ok, link = pcall(GetSpellLink, slot, book)
            if ok and link then
                local id = tonumber(string.match(link, "spell:(%d+)"))
                if id == spellId then
                    return true
                end
            end
        end
        if wantName and GetSpellName then
            local ok, n, r = pcall(GetSpellName, slot, book)
            if ok and n == wantName and (not wantRank or wantRank == "" or r == wantRank) then
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

local function createSpellButton(index, parent)
    parent = parent or ui.spellPane.Child
    local name = (parent:GetName() or "ClasslessUISpell") .. "Btn" .. index
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

    local levelFs = iconBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelFs:SetPoint("CENTER", iconBtn, "CENTER", 0, 0)
    if levelFs.SetFont then
        levelFs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    levelFs:SetTextColor(1, 0.1, 0.1)
    levelFs:SetText("")
    btn.LevelText = levelFs

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

    local nameFs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameFs:SetPoint("TOP", iconBtn, "BOTTOM", 0, -1)
    nameFs:SetWidth(SPELL_CELL_W - 4)
    nameFs:SetJustifyH("CENTER")
    nameFs:SetText("")
    btn.NameText = nameFs

    local subFs = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subFs:SetPoint("TOP", nameFs, "BOTTOM", 0, 0)
    subFs:SetWidth(SPELL_CELL_W - 4)
    subFs:SetJustifyH("CENTER")
    subFs:SetText("")
    btn.SubText = subFs

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
        plus:Hide()
        levelFs:SetText("")
        if not id or isKnown(id) then
            return
        end
        if isLearnable(id) then
            plus:Show()
            return
        end
        local req = reqLevel(id)
        if req and req > 0 then
            levelFs:SetText(tostring(req))
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
        GameTooltip:Hide()
        updatePlus()
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
            if isLearnable(id) then
                AIO.Handle("ClasslessUIServer", "LearnSpell", id)
            end
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
        local maxRank = self.node.r and #self.node.r or 0
        if mouse == "RightButton" then
            if current > 0 then
                AIO.Handle("ClasslessUIServer", "UnlearnTalent", self.node.id, current)
            end
            return
        end
        if IsModifiedClick and IsModifiedClick("PICKUPACTION") then
            local id = self.node.r[math.max(current, 1)]
            if id and isKnown(id) then
                pickupSpellId(id)
            end
            return
        end
        if maxRank < 1 or current >= maxRank then
            if current > 0 then
                AIO.Handle("ClasslessUIServer", "UnlearnTalent", self.node.id, current)
            end
            return
        end
        AIO.Handle("ClasslessUIServer", "LearnTalent", self.node.id, current + 1)
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

local function renderSpellbook(ids, pane, pool)
    pane = pane or ui.spellPane
    pool = pool or ui.spellButtons
    local families = groupSpellFamilies(ids or {})
    local compact = ui.selectedGeneral and not ui.selectedExtra
    if compact then
        for _, fam in ipairs(families) do
            local best = fam.ids[1]
            for _, id in ipairs(fam.ids) do
                if isKnown(id) then
                    best = id
                end
            end
            fam.ids = { best }
            fam.selected = 1
        end
    end
    local child = pane.Child
    local cellW = SPELL_CELL_W
    local cellH = SPELL_CELL_H
    local paneW = math.max(pane:GetWidth() - 36, cellW)
    local cols = math.max(2, math.floor(paneW / cellW))
    local width = math.max(paneW, cols * cellW)
    child:SetWidth(width)
    local rows = math.max(1, math.ceil(#families / cols))
    child:SetHeight(math.max(rows * cellH + 8, pane:GetHeight() - 40))

    for i, fam in ipairs(families) do
        local btn = pool[i]
        if not btn then
            btn = createSpellButton(i, child)
            pool[i] = btn
        end
        btn.family = fam
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        btn:SetSize(cellW, cellH)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 4 + col * cellW, -4 - row * cellH)
        local sel = fam.selected or 1
        local id = fam.ids[sel]
        local spellName, spellSub, icon = GetSpellInfo(id)
        btn.Icon:SetTexture(icon or fam.icon)
        if btn.Icon.SetDesaturated then
            btn.Icon:SetDesaturated(not isKnown(id))
        end
        btn.IconBtn:ClearAllPoints()
        btn.IconBtn:SetPoint("TOP", 0, -2)
        btn.RankText:SetText("")
        if btn.NameText then
            btn.NameText:SetWidth(cellW - 4)
            btn.NameText:SetText(spellName or fam.name or "")
            btn.NameText:Show()
        end
        if btn.SubText then
            btn.SubText:SetWidth(cellW - 4)
            btn.SubText:SetText(spellSub or "")
            btn.SubText:Show()
        end
        if compact then
            btn.Prev:Hide()
            btn.Next:Hide()
            if btn.LevelText then
                btn.LevelText:SetText("")
            end
            if btn.Plus then
                btn.Plus:Hide()
            end
        else
            btn.Prev:Show()
            btn.Next:Show()
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
            if btn.LevelText then
                btn.LevelText:SetText("")
                if not isKnown(id) and not isLearnable(id) then
                    local req = reqLevel(id)
                    if req and req > 0 then
                        btn.LevelText:SetText(tostring(req))
                    end
                end
            end
            if btn.Plus then
                if isLearnable(id) then
                    btn.Plus:Show()
                else
                    btn.Plus:Hide()
                end
            end
        end
        btn:Show()
    end
    hidePool(pool, #families + 1)
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

local NAV_BAR_COUNT = 33

local function layoutNav()
    if not ui.sidebar or not ui.navGeneral then
        return
    end
    local h = ui.sidebar:GetHeight()
    if not h or h < NAV_BAR_COUNT then
        return
    end
    local barH = h / NAV_BAR_COUNT
    local function placeWide(btn, index)
        btn:ClearAllPoints()
        btn:SetHeight(barH)
        btn:SetWidth(SIDEBAR_W)
        btn:SetPoint("TOPLEFT", 0, -index * barH)
    end
    placeWide(ui.navGeneral, 0)
    placeWide(ui.navGlyph, 1)
    local order = Catalog and Catalog.classOrder or {}
    local idx = 2
    for _, classId in ipairs(order) do
        local block = ui.navClassBlocks and ui.navClassBlocks[classId]
        local specBtns = ui.navSpecButtons[classId]
        if block and specBtns then
            local blockH = barH * 3
            block:ClearAllPoints()
            block:SetSize(SIDEBAR_W, blockH)
            block:SetPoint("TOPLEFT", 0, -idx * barH)
            local iconSz = blockH
            local bannerW = SIDEBAR_W - iconSz
            for i = 1, 3 do
                local btn = specBtns[i]
                btn:ClearAllPoints()
                btn:SetSize(bannerW, barH)
                btn:SetPoint("TOPLEFT", 0, -((i - 1) * barH))
            end
            if block.ClassIcon then
                block.ClassIcon:SetSize(iconSz, iconSz)
                block.ClassIcon:ClearAllPoints()
                block.ClassIcon:SetPoint("TOPRIGHT", 0, 0)
            end
        end
        idx = idx + 3
    end
    if ui.navPet then
        placeWide(ui.navPet, 32)
    end
end

local function refreshNav()
    if ui.navPet then
        ui.navPet:Show()
        if hasPetOut() then
            ui.navPet:Enable()
            if ui.navPet.Bg then
                ui.navPet.Bg:SetVertexColor(ui.navPet.baseR or 0.45, ui.navPet.baseG or 0.3, ui.navPet.baseB or 0.15, 0.92)
            end
        else
            ui.navPet:Disable()
            if ui.navPet.Bg then
                ui.navPet.Bg:SetVertexColor(0.22, 0.22, 0.22, 0.85)
            end
            if ui.selectedExtra == "pet" then
                ui.selectedExtra = nil
                ui.selectedGeneral = true
            end
        end
    end
    if ui.navGeneral then
        highlightButton(ui.navGeneral, ui.selectedGeneral and not ui.selectedExtra)
    end
    if ui.navGlyph then
        highlightButton(ui.navGlyph, ui.selectedExtra == "glyph")
    end
    if ui.navPet then
        highlightButton(ui.navPet, ui.selectedExtra == "pet")
    end
    for classId, specBtns in pairs(ui.navSpecButtons) do
        for i, btn in ipairs(specBtns) do
            local on = not ui.selectedGeneral and not ui.selectedExtra
                and ui.selectedClassId == classId and ui.selectedSpecIndex == i
            highlightButton(btn, on)
        end
    end
end

-- Stock Blizzard_GlyphUI.xml / .lua, rebuilt with CreateFrame.
local GLYPHTYPE_MAJOR = 1
local GLYPHTYPE_MINOR = 2
local GLYPH_MINOR = { r = 0, g = 0.25, b = 1 }
local GLYPH_MAJOR = { r = 1, g = 0.25, b = 0 }
local NUM_GLYPH_SLOTS = 6
local HIGHLIGHT_BASEALPHA = 0.4
local GLYPHFRAME_PULSEIN, GLYPHFRAME_PULSEOUT, GLYPHFRAME_FINISHED = 0.2, 0.2, 1.5
local GLYPH_SLOTS = {
    [0] = { left = 0.78125, right = 0.91015625, top = 0.69921875, bottom = 0.828125 },
    [1] = { left = 0, right = 0.12890625, top = 0.87109375, bottom = 1 },
    [2] = { left = 0.130859375, right = 0.259765625, top = 0.87109375, bottom = 1 },
    [3] = { left = 0.392578125, right = 0.521484375, top = 0.87109375, bottom = 1 },
    [4] = { left = 0.5234375, right = 0.65234375, top = 0.87109375, bottom = 1 },
    [5] = { left = 0.26171875, right = 0.390625, top = 0.87109375, bottom = 1 },
    [6] = { left = 0.654296875, right = 0.783203125, top = 0.87109375, bottom = 1 },
}
local GLYPH_SOCKET_LAYOUT = {
    { id = 1, point = "CENTER", x = -15, y = 140 },
    { id = 2, point = "CENTER", x = -14, y = -103 },
    { id = 3, point = "TOPLEFT", x = 28, y = -133 },
    { id = 4, point = "BOTTOMRIGHT", x = -56, y = 168 },
    { id = 5, point = "TOPRIGHT", x = -56, y = -133 },
    { id = 6, point = "BOTTOMLEFT", x = 26, y = 168 },
}
local slotAnimations = {
    [1] = { point = "CENTER", xStart = -13, xStop = -13, yStart = 17, yStop = 100 },
    [2] = { point = "CENTER", xStart = -13, xStop = -13, yStart = 17, yStop = -64 },
    [3] = { point = "CENTER", xStart = -13, xStop = -85, yStart = 17, yStop = 60 },
    [4] = { point = "CENTER", xStart = -13, xStop = 61, yStart = 18, yStop = -27 },
    [5] = { point = "CENTER", xStart = -13, xStop = 59, yStart = 17, yStop = 60 },
    [6] = { point = "CENTER", xStart = -13, xStop = -87, yStart = 18, yStop = -27 },
}

local function sizeTex(tex, w, h)
    if tex then
        tex:SetWidth(w)
        tex:SetHeight(h)
    end
end

local function setGlyphType(glyph, glyphType)
    glyph.glyphType = glyphType
    glyph.setting:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    if glyphType == GLYPHTYPE_MAJOR then
        glyph.glyph:SetVertexColor(GLYPH_MAJOR.r, GLYPH_MAJOR.g, GLYPH_MAJOR.b)
        sizeTex(glyph.setting, 108, 108)
        glyph.setting:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625)
        sizeTex(glyph.highlight, 108, 108)
        glyph.highlight:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625)
        sizeTex(glyph.ring, 82, 82)
        glyph.ring:ClearAllPoints()
        glyph.ring:SetPoint("CENTER", glyph, "CENTER", 0, -1)
        glyph.ring:SetTexCoord(0.767578125, 0.92578125, 0.32421875, 0.482421875)
        glyph.shine:SetTexCoord(0.9609375, 1, 0.9609375, 1)
        sizeTex(glyph.background, 70, 70)
    else
        glyph.glyph:SetVertexColor(GLYPH_MINOR.r, GLYPH_MINOR.g, GLYPH_MINOR.b)
        sizeTex(glyph.setting, 86, 86)
        glyph.setting:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
        sizeTex(glyph.highlight, 86, 86)
        glyph.highlight:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
        sizeTex(glyph.ring, 62, 62)
        glyph.ring:ClearAllPoints()
        glyph.ring:SetPoint("CENTER", glyph, "CENTER", 0, 1)
        glyph.ring:SetTexCoord(0.787109375, 0.908203125, 0.033203125, 0.154296875)
        glyph.shine:SetTexCoord(0.9609375, 1, 0.921875, 0.9609375)
        sizeTex(glyph.background, 64, 64)
    end
end

local function stopSlotAnimation(slotID)
    local animation = slotAnimations[slotID]
    local sparkleFrame = ui.glyphFrame and ui.glyphFrame.sparkleFrame
    if animation and animation.started and sparkleFrame and sparkleFrame.EndAnimation then
        sparkleFrame:EndAnimation(slotID)
        animation.started = nil
    end
end

local function startSlotAnimation(slotID, duration, size)
    local animation = slotAnimations[slotID]
    local sparkleFrame = ui.glyphFrame and ui.glyphFrame.sparkleFrame
    if not animation or not sparkleFrame or not sparkleFrame.StartAnimation then
        return
    end
    local template = "SparkleTextureNormal"
    if size == 1 then
        template = "SparkleTextureSmall"
    elseif size == 2 then
        template = "SparkleTextureKindaSmall"
    end
    local sparkle = sparkleFrame:StartAnimation(
        slotID, "LinearTranslate", template, false,
        animation.point, animation.xStart, animation.xStop,
        animation.yStart, animation.yStop, duration
    )
    if sparkle and sparkle.SetOnFinished then
        sparkle:SetOnFinished(function(s)
            if s.name and slotAnimations[s.name] then
                slotAnimations[s.name].started = false
            end
        end)
    end
    animation.started = true
end

local function pulseGlyphGlow()
    local frame = ui.glyphFrame
    if not frame or not frame.glow then
        return
    end
    frame.pulseElapsed = 0
    frame.glow:Show()
end

local function updateGlyphSlot(self)
    local id = self:GetID()
    local enabled, glyphType, glyphSpell, iconFilename = GetGlyphSocketInfo(id)
    if glyphType == GLYPHTYPE_MINOR then
        setGlyphType(self, GLYPHTYPE_MINOR)
    else
        setGlyphType(self, GLYPHTYPE_MAJOR)
    end
    self.elapsed = 0
    self.tintElapsed = 0
    if not enabled then
        slotAnimations[id].glyph = nil
        self.shine:Hide()
        self.background:Hide()
        self.glyph:Hide()
        self.ring:Hide()
        self.setting:SetTexture("Interface\\Spellbook\\UI-GlyphFrame-Locked")
        self.setting:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        sizeTex(self.setting, self.glyphType == GLYPHTYPE_MAJOR and 108 or 86, self.glyphType == GLYPHTYPE_MAJOR and 108 or 86)
    elseif not glyphSpell then
        slotAnimations[id].glyph = nil
        self.spell = nil
        self.shine:Show()
        self.background:Show()
        self.background:SetTexCoord(GLYPH_SLOTS[0].left, GLYPH_SLOTS[0].right, GLYPH_SLOTS[0].top, GLYPH_SLOTS[0].bottom)
        if not (GlyphMatchesSocket and GlyphMatchesSocket(id)) then
            self.background:SetAlpha(1)
        end
        self.glyph:Hide()
        self.ring:Show()
    else
        slotAnimations[id].glyph = true
        self.spell = glyphSpell
        self.shine:Show()
        self.background:Show()
        self.background:SetAlpha(1)
        self.background:SetTexCoord(GLYPH_SLOTS[id].left, GLYPH_SLOTS[id].right, GLYPH_SLOTS[id].top, GLYPH_SLOTS[id].bottom)
        self.glyph:Show()
        if iconFilename then
            self.glyph:SetTexture(iconFilename)
        else
            self.glyph:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1")
        end
        sizeTex(self.glyph, 53, 53)
        self.ring:Show()
    end
end

local function updateGlyphFrame()
    for i = 1, NUM_GLYPH_SLOTS do
        local socket = ui.glyphSockets[i]
        if socket then
            updateGlyphSlot(socket)
        end
    end
end

local function createGlyphSocket(parent, id, point, x, y)
    local btn = CreateFrame("Button", "ClasslessUIGlyph" .. id, parent)
    btn:SetWidth(90)
    btn:SetHeight(90)
    btn:SetID(id)
    btn:SetPoint(point, parent, point, x, y)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local setting = btn:CreateTexture(nil, "BACKGROUND")
    setting:SetPoint("CENTER", 0, 0)
    setting:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    sizeTex(setting, 86, 86)
    setting:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
    btn.setting = setting

    local highlight = btn:CreateTexture(nil, "BORDER")
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(1, 1, 1, 0.25)
    sizeTex(highlight, 86, 86)
    highlight:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
    highlight:Hide()
    btn.highlight = highlight

    local background = btn:CreateTexture(nil, "BORDER")
    background:SetPoint("CENTER", 0, 0)
    background:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    sizeTex(background, 64, 64)
    background:SetTexCoord(0.78125, 0.91015625, 0.69921875, 0.828125)
    btn.background = background

    local glyph = btn:CreateTexture(nil, "ARTWORK")
    glyph:SetPoint("CENTER", 0, 0)
    glyph:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1")
    sizeTex(glyph, 53, 53)
    btn.glyph = glyph

    local ring = btn:CreateTexture(nil, "OVERLAY")
    ring:SetPoint("CENTER", 0, 1)
    ring:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    sizeTex(ring, 62, 62)
    ring:SetTexCoord(0.787109375, 0.908203125, 0.033203125, 0.154296875)
    btn.ring = ring

    local shine = btn:CreateTexture(nil, "OVERLAY")
    shine:SetPoint("CENTER", -9, 12)
    shine:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    sizeTex(shine, 16, 16)
    shine:SetTexCoord(0.9609375, 1, 0.921875, 0.9609375)
    btn.shine = shine

    btn.elapsed = 0
    btn.tintElapsed = 0
    btn.glyphType = nil

    btn:SetScript("OnShow", function(self)
        updateGlyphSlot(self)
    end)
    btn:SetScript("OnClick", function(self, button)
        local slot = self:GetID()
        if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
            local link = GetGlyphLink and GetGlyphLink(slot)
            if link and ChatEdit_InsertLink then
                ChatEdit_InsertLink(link)
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                local _, _, glyphSpell = GetGlyphSocketInfo(slot)
                if glyphSpell then
                    local glyphName = GetSpellInfo(glyphSpell)
                    local dialog = StaticPopup_Show("CONFIRM_REMOVE_GLYPH", glyphName)
                    if dialog then
                        dialog.data = slot
                    end
                end
            end
        elseif self.glyph:IsShown() and GlyphMatchesSocket and GlyphMatchesSocket(slot) then
            local dialog = StaticPopup_Show("CONFIRM_GLYPH_PLACEMENT", slot)
            if dialog then
                dialog.data = slot
            end
        elseif PlaceGlyphInSocket then
            PlaceGlyphInSocket(slot)
        end
    end)
    btn:SetScript("OnEnter", function(self)
        self.hasCursor = true
        if self.background:IsShown() then
            self.highlight:Show()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetGlyph(self:GetID())
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self.hasCursor = nil
        self.highlight:Hide()
        GameTooltip:Hide()
    end)
    btn:SetScript("OnUpdate", function(self, elapsed)
        local GLYPHFRAMEGLYPH_FINISHED = 6
        local GLYPHFRAMEGLYPH_START = 2
        local GLYPHFRAMEGLYPH_HOLD = 4
        local hasGlyph = self.glyph:IsShown()
        if hasGlyph or self.elapsed > 0 then
            self.elapsed = self.elapsed + elapsed
            local e = self.elapsed
            if e >= GLYPHFRAMEGLYPH_FINISHED then
                self.setting:SetAlpha(0.6)
                self.elapsed = 0
            elseif e <= GLYPHFRAMEGLYPH_START then
                self.setting:SetAlpha(0.6 + (0.4 * e / GLYPHFRAMEGLYPH_START))
            elseif e >= GLYPHFRAMEGLYPH_HOLD then
                self.setting:SetAlpha(1 - (0.4 * (e - GLYPHFRAMEGLYPH_HOLD) / (GLYPHFRAMEGLYPH_FINISHED - GLYPHFRAMEGLYPH_HOLD)))
            end
        else
            self.setting:SetAlpha(0.6)
        end

        local TINT_START, TINT_HOLD, TINT_FINISHED = 0.6, 0.8, 1.6
        local slot = self:GetID()
        if not hasGlyph and self.background:IsShown() and GlyphMatchesSocket and GlyphMatchesSocket(slot) then
            self.tintElapsed = self.tintElapsed + elapsed
            self.background:SetTexCoord(GLYPH_SLOTS[slot].left, GLYPH_SLOTS[slot].right, GLYPH_SLOTS[slot].top, GLYPH_SLOTS[slot].bottom)
            local showHighlight = false
            if not MouseIsOver(self) then
                self.highlight:Show()
                showHighlight = true
            end
            local alpha
            local e = self.tintElapsed
            if e >= TINT_FINISHED then
                alpha = 1
                self.tintElapsed = 0
            elseif e <= TINT_START then
                alpha = 1 - (0.6 * e / TINT_START)
            elseif e >= TINT_HOLD then
                alpha = 0.4 + (0.6 * (e - TINT_HOLD) / (TINT_FINISHED - TINT_HOLD))
            end
            if alpha then
                self.background:SetAlpha(alpha)
                if showHighlight then
                    self.highlight:SetAlpha(HIGHLIGHT_BASEALPHA * alpha)
                else
                    self.highlight:SetAlpha(HIGHLIGHT_BASEALPHA)
                end
            end
        elseif not hasGlyph then
            self.background:SetTexCoord(GLYPH_SLOTS[0].left, GLYPH_SLOTS[0].right, GLYPH_SLOTS[0].top, GLYPH_SLOTS[0].bottom)
            self.background:SetAlpha(1)
        end

        if self.hasCursor and SpellIsTargeting and SpellIsTargeting() then
            if GlyphMatchesSocket and GlyphMatchesSocket(self:GetID()) and self.background:IsShown() then
                SetCursor("CAST_CURSOR")
            else
                SetCursor("CAST_ERROR_CURSOR")
            end
        end
    end)
    return btn
end

local function ensureGlyphFrame()
    if ui.glyphFrame then
        return ui.glyphFrame
    end
    local parent = ui.body
    local frame = CreateFrame("Frame", "ClasslessUIGlyphFrame", parent)
    frame:SetWidth(384)
    frame:SetHeight(512)
    frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    frame:EnableMouse(true)
    if frame.SetHitRectInsets then
        frame:SetHitRectInsets(0, 30, 0, 70)
    end
    frame:Hide()

    local bookIcon = frame:CreateTexture(nil, "BACKGROUND")
    bookIcon:SetTexture("Interface\\Spellbook\\Spellbook-Icon")
    sizeTex(bookIcon, 58, 58)
    bookIcon:SetPoint("TOPLEFT", 10, -8)

    local bg = frame:CreateTexture(nil, "ARTWORK")
    bg:SetTexture("Interface\\Spellbook\\UI-GlyphFrame")
    sizeTex(bg, 352, 441)
    bg:SetPoint("TOPLEFT")
    bg:SetTexCoord(0, 0.6875, 0, 0.861328125)
    frame.bg = bg

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("CENTER", 6, 230)
    title:SetText((type(GLYPHS) == "string" and GLYPHS) or "Glyphs")
    frame.title = title

    local glow = frame:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Spellbook\\UI-GlyphFrame-Glow")
    sizeTex(glow, 352, 441)
    glow:SetPoint("TOPLEFT", -9, -38)
    glow:SetTexCoord(0, 0.6875, 0, 0.861328125)
    glow:Hide()
    glow:SetAlpha(0)
    frame.glow = glow

    if SparkleFrame and SparkleFrame.New then
        frame.sparkleFrame = SparkleFrame:New(frame)
    end

    for _, layout in ipairs(GLYPH_SOCKET_LAYOUT) do
        ui.glyphSockets[layout.id] = createGlyphSocket(frame, layout.id, layout.point, layout.x, layout.y)
    end

    frame:SetScript("OnShow", function()
        updateGlyphFrame()
    end)
    frame:SetScript("OnEnter", function()
        if SpellIsTargeting and SpellIsTargeting() then
            SetCursor("CAST_ERROR_CURSOR")
        end
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self.pulseElapsed then
            self.pulseElapsed = self.pulseElapsed + elapsed
            local pulseElapsed = self.pulseElapsed
            if pulseElapsed >= GLYPHFRAME_FINISHED then
                self.glow:Hide()
                self.glow:SetAlpha(0)
                self.pulseElapsed = nil
            elseif pulseElapsed <= GLYPHFRAME_PULSEIN then
                self.glow:SetAlpha(pulseElapsed / GLYPHFRAME_PULSEIN)
            elseif pulseElapsed >= GLYPHFRAME_PULSEOUT then
                self.glow:SetAlpha(1 - ((pulseElapsed - GLYPHFRAME_PULSEOUT) / (GLYPHFRAME_FINISHED - GLYPHFRAME_PULSEOUT)))
            end
        end
        for i = 1, NUM_GLYPH_SLOTS do
            if not slotAnimations[i].started and slotAnimations[i].glyph then
                local sparkleSize = math.random(3)
                local mods = { 1.25, 1.5, 1.8 }
                startSlotAnimation(i, sparkleSize * mods[sparkleSize], sparkleSize)
            end
        end
    end)
    frame:RegisterEvent("GLYPH_ADDED")
    frame:RegisterEvent("GLYPH_REMOVED")
    frame:RegisterEvent("GLYPH_UPDATED")
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LEVEL_UP" then
            updateGlyphFrame()
            return
        end
        local index = ...
        local glyph = ui.glyphSockets[index]
        if not glyph then
            updateGlyphFrame()
            return
        end
        updateGlyphSlot(glyph)
        local glyphType = glyph.glyphType
        if event == "GLYPH_ADDED" or event == "GLYPH_UPDATED" then
            pulseGlyphGlow()
            if glyphType == GLYPHTYPE_MINOR then
                PlaySound("Glyph_MinorCreate")
            elseif glyphType == GLYPHTYPE_MAJOR then
                PlaySound("Glyph_MajorCreate")
            end
        elseif event == "GLYPH_REMOVED" then
            stopSlotAnimation(index)
            if glyphType == GLYPHTYPE_MINOR then
                PlaySound("Glyph_MinorDestroy")
            elseif glyphType == GLYPHTYPE_MAJOR then
                PlaySound("Glyph_MajorDestroy")
            end
        end
        if glyph.hasCursor then
            GameTooltip:SetOwner(glyph, "ANCHOR_RIGHT")
            GameTooltip:SetGlyph(glyph:GetID())
            GameTooltip:Show()
        end
    end)

    ui.glyphFrame = frame
    return frame
end

function refreshPanes()
    if not ui.spellPane then
        return
    end
    local info = classInfo(ui.selectedClassId)
    local className = ui.selectedGeneral and "General" or (info and info.name or "?")
    local points = ui.state.points or 0
    if ui.selectedExtra == "pet" then
        points = ui.state.petPoints or 0
    end
    if ui.spellPane.PointsOverlay then
        ui.spellPane.PointsOverlay:Hide()
    end
    if ui.talentPane.PointsOverlay then
        ui.talentPane.PointsOverlay:SetFrameLevel(ui.talentPane.Scroll:GetFrameLevel() + 20)
        ui.talentPane.Points:SetText("Unspent: " .. tostring(points))
        local w = ui.talentPane.Points:GetStringWidth() or 80
        ui.talentPane.PointsOverlay:SetWidth(w + 20)
        ui.talentPane.PointsOverlay:Show()
    end
    ui.spellPane.Points:SetText("")

    if ui.selectedExtra == "glyph" then
        ui.spellPane:Hide()
        ui.talentPane:Hide()
        if ui.talentPane.PointsOverlay then
            ui.talentPane.PointsOverlay:Hide()
        end
        hidePool(ui.spellButtons, 1)
        hidePool(ui.rightSpellButtons, 1)
        hidePool(ui.talentButtons, 1)
        ensureGlyphFrame()
        ui.glyphFrame:Show()
        updateGlyphFrame()
        return
    end

    if ui.glyphFrame then
        ui.glyphFrame:Hide()
    end
    ui.spellPane:Show()

    if ui.selectedGeneral and not ui.selectedExtra then
        ui.spellPane:ClearAllPoints()
        ui.spellPane:SetPoint("TOPLEFT")
        ui.spellPane:SetPoint("BOTTOMLEFT")
        ui.spellPane:SetPoint("TOPRIGHT")
        ui.spellPane:SetPoint("BOTTOMRIGHT")
        ui.talentPane:Hide()

        ui.spellPane.Title:SetText("General")
        setPaneTalentArt(ui.talentPane, nil)
        if ui.talentPane.PointsOverlay then
            ui.talentPane.PointsOverlay:Hide()
        end
        hidePool(ui.talentButtons, 1)
        hidePool(ui.rightSpellButtons, 1)
        local all = {}
        for _, id in ipairs((Catalog and Catalog.generalSpells) or {}) do
            if isKnown(id) then
                all[#all + 1] = id
            end
        end
        renderSpellbook(all, ui.spellPane, ui.spellButtons)
        return
    end

    ui.spellPane:ClearAllPoints()
    ui.spellPane:SetPoint("TOPLEFT")
    ui.spellPane:SetPoint("BOTTOMLEFT")
    ui.spellPane:SetPoint("RIGHT", ui.spellPane:GetParent(), "CENTER", 0, 0)
    ui.talentPane:ClearAllPoints()
    ui.talentPane:SetPoint("TOPRIGHT")
    ui.talentPane:SetPoint("BOTTOMRIGHT")
    ui.talentPane:SetPoint("LEFT", ui.talentPane:GetParent(), "CENTER", 0, 0)
    ui.talentPane:Show()

    if ui.selectedExtra == "pet" then
        ui.spellPane.Title:SetText("Pet abilities")
        ui.talentPane.Title:SetText("Pet talents")
        local petTabs = (Catalog and Catalog.petTabs) or { 409, 410, 411 }
        setPaneTalentArt(ui.talentPane, petTabs[1])
        hidePool(ui.rightSpellButtons, 1)
        renderSpellbook((Catalog and Catalog.petSpells) or {}, ui.spellPane, ui.spellButtons)
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
    local classBit = className ~= "?" and (" " .. className) or ""
    ui.spellPane.Title:SetText(specName .. classBit .. " spells")
    ui.talentPane.Title:SetText(specName .. classBit .. " talents")
    setPaneTalentArt(ui.talentPane, spec and spec.tabId)
    hidePool(ui.rightSpellButtons, 1)
    renderSpellbook(ids, ui.spellPane, ui.spellButtons)
    hidePool(ui.talentButtons, 1)
    local tabId = spec and spec.tabId
    local used, height = renderTalentTree(tabId, 0)
    hidePool(ui.talentButtons, used + 1)
    ui.talentPane.Child:SetWidth(4 * TALENT_GAP + TALENT_OFF_X + 40)
    ui.talentPane.Child:SetHeight(math.max(height, 200))
end

local function selectGeneral()
    ui.selectedGeneral = true
    ui.selectedExtra = nil
    refreshNav()
    refreshPanes()
end

local function selectSpec(classId, index)
    ui.selectedClassId = classId
    ui.selectedSpecIndex = index
    ui.selectedGeneral = false
    ui.selectedExtra = nil
    refreshNav()
    refreshPanes()
end

local function selectExtra(extraId)
    ui.selectedExtra = extraId
    ui.selectedGeneral = false
    refreshNav()
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
        frame:SetMinResize(FRAME_W, FRAME_H)
        frame:SetMaxResize(FRAME_W, FRAME_H)
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

    local close = CreateFrame("Button", "ClasslessUIFrameClose", frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetFrameLevel(frame:GetFrameLevel() + 20)

    local sidebar = CreateFrame("Frame", "ClasslessUISidebar", frame)
    sidebar:SetPoint("TOPRIGHT", -4, -8)
    sidebar:SetPoint("BOTTOMRIGHT", -4, 8)
    sidebar:SetWidth(SIDEBAR_W)
    local nav = CreateFrame("Frame", "ClasslessUINav", sidebar)
    nav:SetAllPoints(sidebar)
    ui.sidebar = sidebar

    local function addWideNav(name, label, onClick, r, g, b)
        local btn = createBannerButton(name, nav, SIDEBAR_W, NAV_ROW_H, r or 0.35, g or 0.35, b or 0.35, label)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    local y = 0
    ui.navGeneral = addWideNav("ClasslessUINavGeneral", "General", selectGeneral, 0.55, 0.45, 0.25)
    ui.navGeneral:SetPoint("TOPLEFT", 0, y)
    y = y - NAV_ROW_H

    ui.navGlyph = addWideNav("ClasslessUINavGlyph", "Glyphs", function()
        selectExtra("glyph")
    end, 0.35, 0.55, 0.35)
    ui.navGlyph:SetPoint("TOPLEFT", 0, y)
    y = y - (NAV_ROW_H + 2)

    local blockH = NAV_ROW_H * 3 + NAV_SPEC_GAP * 2
    local iconSz = blockH
    local bannerW = SIDEBAR_W - iconSz
    local order = Catalog and Catalog.classOrder or {}
    for _, classId in ipairs(order) do
        local info = classInfo(classId)
        local cr, cg, cb = classRGB(classId)
        local block = CreateFrame("Frame", "ClasslessUINavClass" .. classId, nav)
        block:SetSize(SIDEBAR_W, blockH)
        block:SetPoint("TOPLEFT", 0, y)
        local specBtns = {}
        for i = 1, 3 do
            local spec = info and info.specs and info.specs[i]
            local btn = createBannerButton(
                "ClasslessUINavSpec" .. classId .. "_" .. i,
                block,
                bannerW,
                NAV_ROW_H,
                cr, cg, cb,
                spec and (spec.name .. (info and (" " .. info.name) or "")) or tostring(i)
            )
            btn:SetPoint("TOPLEFT", 0, -((i - 1) * (NAV_ROW_H + NAV_SPEC_GAP)))
            local capturedClass, capturedSpec = classId, i
            btn:SetScript("OnClick", function()
                selectSpec(capturedClass, capturedSpec)
            end)
            specBtns[i] = btn
        end
        ui.navSpecButtons[classId] = specBtns
        ui.navClassBlocks[classId] = block
        local icon = block:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSz, iconSz)
        icon:SetPoint("TOPRIGHT", 0, 0)
        if info then
            icon:SetTexture(info.icon)
        end
        block.ClassIcon = icon
        y = y - blockH
    end

    ui.navPet = addWideNav("ClasslessUINavPet", "Pet", function()
        if hasPetOut() then
            selectExtra("pet")
        end
    end, 0.45, 0.3, 0.15)
    ui.navPet:SetPoint("TOPLEFT", 0, y)
    y = y - NAV_ROW_H

    local body = CreateFrame("Frame", "ClasslessUIBody", frame)
    body:SetPoint("TOPLEFT", 8, -8)
    body:SetPoint("BOTTOMLEFT", 8, 8)
    body:SetPoint("RIGHT", sidebar, "LEFT", 0, 0)
    ui.body = body

    ui.spellPane = createScrollPane("ClasslessUISpellPane", body, "Spells")
    ui.spellPane:SetPoint("TOPLEFT")
    ui.spellPane:SetPoint("BOTTOMLEFT")
    ui.spellPane:SetPoint("RIGHT", body, "CENTER", 0, 0)

    ui.talentPane = createScrollPane("ClasslessUITalentPane", body, "Talents")
    ui.talentPane:SetPoint("TOPRIGHT")
    ui.talentPane:SetPoint("BOTTOMRIGHT")
    ui.talentPane:SetPoint("LEFT", body, "CENTER", 0, 0)

    frame:SetScript("OnShow", function()
        AIO.Handle("ClasslessUIServer", "RequestState")
        layoutNav()
        refreshNav()
        refreshPanes()
    end)
    frame:SetScript("OnSizeChanged", function()
        layoutNav()
        if ui.talentPane then
            layoutTalentArt(ui.talentPane)
        end
    end)
    sidebar:SetScript("OnSizeChanged", layoutNav)

    ui.frame = frame
    layoutNav()
    selectSpec(ui.selectedClassId, 1)
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
        local petLearned = {}
        if type(state.petLearned) == "table" then
            for k, v in pairs(state.petLearned) do
                if v then
                    local id = tonumber(k) or k
                    petLearned[id] = true
                end
            end
        end
        local reqLevels = {}
        if type(state.reqLevels) == "table" then
            for k, v in pairs(state.reqLevels) do
                local id = tonumber(k) or k
                reqLevels[id] = tonumber(v)
            end
        end
        ui.state = {
            learned = learned,
            learnable = learnable,
            reqLevels = reqLevels,
            petLearned = petLearned,
            petOut = state.petOut and true or false,
            points = tonumber(state.points) or 0,
            petPoints = tonumber(state.petPoints) or 0,
        }
    end
    if ui.frame and ui.frame:IsShown() then
        refreshNav()
        refreshPanes()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("UNIT_PET")
local lastStateReq = 0
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_PET" and unit ~= "player" then
        return
    end
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
