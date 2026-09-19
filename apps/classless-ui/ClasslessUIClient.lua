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
    state = { learned = {}, talents = {}, points = 0 },
}

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

local function createScrollPane(name, parent, title)
    local pane = CreateFrame("Frame", name, parent)
    pane:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    pane:SetBackdropColor(0, 0, 0, 0.6)

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
    return pane
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

local function refreshPanes()
    local info = classInfo(ui.selectedClassId)
    local className = info and info.name or "?"
    if ui.selectedExtra == "glyph" then
        ui.spellPane.Title:SetText(className .. " glyphs")
        ui.talentPane.Title:SetText("Glyph slots")
        return
    end
    if ui.selectedExtra == "pet" then
        ui.spellPane.Title:SetText("Pet spells")
        ui.talentPane.Title:SetText("Pet talents")
        return
    end
    local spec = info and info.specs and info.specs[ui.selectedSpecIndex]
    local specName = spec and spec.name or "?"
    ui.spellPane.Title:SetText(specName .. " spells")
    ui.talentPane.Title:SetText(specName .. " talents")
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
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    tinsert(UISpecialFrames, "ClasslessUIFrame")

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
    local startX = math.max((FRAME_W - 40 - totalW) / 2, 0)

    for i, classId in ipairs(order) do
        local info = classInfo(classId)
        local btn = createIconButton("ClasslessUIClass" .. classId, classRow, btnW, 80, 56)
        btn:SetPoint("TOPLEFT", startX + (i - 1) * (btnW + gap), 0)
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

    ui.frame = frame
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
        ui.state = state
    end
    if ui.frame and ui.frame:IsShown() then
        refreshPanes()
    end
end

SLASH_CLASSLESSUI1 = "/classless"
SlashCmdList["CLASSLESSUI"] = function()
    local frame = buildFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        Handlers.ShowUI()
    end
end
