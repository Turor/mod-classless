local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

-- Classless energy/rage/mana/runic HUD. Textures stay in patch-n.mpq under
-- Interface\AddOns\ClasslessUIAddons\textures (no loadable addon toc).
if ClasslessResourceFrame then
    return
end

local ResourceBar = AIO.AddHandlers("ClasslessResourceBar", {})
local pendingRuneCds
local moduleEnabled = true

function ResourceBar.SetEnabled(_, enabled)
    moduleEnabled = enabled == true or enabled == 1
    if ClasslessResourceFrame then
        if moduleEnabled then
            ClasslessResourceFrame:Show()
        else
            ClasslessResourceFrame:Hide()
        end
    end
end

local function applyRuneCooldownMs(i, remMs)
    local btn = ClasslessRunes and ClasslessRunes[i]
    if not btn or not btn.cooldown then
        return
    end
    remMs = tonumber(remMs) or 0
    if remMs > 50 then
        local rem = remMs / 1000
        local total = math.max(10, rem)
        btn.cooldown:SetCooldown(GetTime() - (total - rem), total)
        btn.cooldown:Show()
        if btn.cdCircle then
            btn.cdCircle:Show()
        end
    else
        btn.cooldown:Hide()
        if btn.cdCircle then
            btn.cdCircle:Hide()
        end
    end
end

local function applyPendingRuneCds()
    if type(pendingRuneCds) ~= "table" then
        return
    end
    for i = 1, 6 do
        applyRuneCooldownMs(i, pendingRuneCds[i] or pendingRuneCds[tostring(i)])
    end
end

function ResourceBar.ApplyRuneCooldowns(player, cds)
    if not moduleEnabled then
        return
    end
    pendingRuneCds = cds
    applyPendingRuneCds()
end

AIO.AddSavedVarChar("Energy_Textures")
AIO.AddSavedVarChar("Energy_ShowText")
AIO.AddSavedVarChar("Rage_Textures")
AIO.AddSavedVarChar("Rage_ShowText")
AIO.AddSavedVarChar("Mana_Textures")
AIO.AddSavedVarChar("Mana_ShowText")
AIO.AddSavedVarChar("Runic_Textures")
AIO.AddSavedVarChar("Runic_ShowText")
AIO.AddSavedVarChar("ConfigFrame_varis")


local FirstTime = true;
local CLASSLESS_RUNETYPE_BLOOD = 1;
local CLASSLESS_RUNETYPE_UNHOLY = 2;
local CLASSLESS_RUNETYPE_FROST = 3;
local CLASSLESS_RUNETYPE_DEATH = 4;

local classlessRuneIconTextures = {};
classlessRuneIconTextures[CLASSLESS_RUNETYPE_BLOOD] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood";
classlessRuneIconTextures[CLASSLESS_RUNETYPE_UNHOLY] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy";
classlessRuneIconTextures[CLASSLESS_RUNETYPE_FROST] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost";
classlessRuneIconTextures[CLASSLESS_RUNETYPE_DEATH] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death";

local classlessRuneTextures = {
	[CLASSLESS_RUNETYPE_BLOOD] = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-Blood-Off.tga",
	[CLASSLESS_RUNETYPE_UNHOLY] = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-Death-Off.tga",
	[CLASSLESS_RUNETYPE_FROST] = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-Frost-Off.tga",
	[CLASSLESS_RUNETYPE_DEATH] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Chromatic-Off.tga",
}

local classlessRuneColors = {
	[CLASSLESS_RUNETYPE_BLOOD] = {1, 0, 0},
	[CLASSLESS_RUNETYPE_UNHOLY] = {0, 0.5, 0},
	[CLASSLESS_RUNETYPE_FROST] = {0, 1, 1},
	[CLASSLESS_RUNETYPE_DEATH] = {0.8, 0.1, 1},
}
local classlessRuneMapping = {
	[1] = "BLOOD",
	[2] = "UNHOLY",
	[3] = "FROST",
	[4] = "DEATH",
}


function ClasslessCooldownFrame_SetTimer(self, start, duration, enable)
	if not self then
		return
	end
	start = tonumber(start) or 0
	duration = tonumber(duration) or 0
	enable = tonumber(enable) or 0
	if ( start > 0 and duration > 0 and enable > 0) then
		self:SetCooldown(start, duration);
		self:Show();
	else
		self:Hide();
	end
end

function ClasslessRuneButton_OnLoad (self)
	ClasslessRuneButton_Update(self);
end

function ClasslessRuneButton_OnUpdate (self, elapsed)
	-- Server-pushed remaining ms is the classless source of truth (every class).
	if pendingRuneCds then
		self:SetScript("OnUpdate", nil);
		return
	end
	local cooldown = self.cooldown or _G[self:GetName().."Cooldown"];
	if not GetRuneCooldown then
		self:SetScript("OnUpdate", nil);
		return
	end
	local start, duration, runeReady = GetRuneCooldown(self:GetID());
	start = tonumber(start) or 0
	duration = tonumber(duration) or 0
	local displayCooldown = (runeReady and 0) or 1;
	if start > 0 and duration > 0 and displayCooldown > 0 then
		if CooldownFrame_SetTimer then
			CooldownFrame_SetTimer(cooldown, start, duration, displayCooldown);
		else
			ClasslessCooldownFrame_SetTimer(cooldown, start, duration, displayCooldown);
		end
	elseif runeReady then
		if CooldownFrame_SetTimer then
			CooldownFrame_SetTimer(cooldown, 0, 0, 0);
		else
			ClasslessCooldownFrame_SetTimer(cooldown, 0, 0, 0);
		end
		self:SetScript("OnUpdate", nil);
	end
end

function ClasslessRuneButton_Update (self, classlessRuneType, dontFlash)
	local runeType = self.runeType

	if ( (not dontFlash) and (classlessRuneType) and (classlessRuneType ~= self.runeType)) then
		if self.shine and self.shine.shineTex then
			self.shine.shineTex:SetVertexColor(unpack(classlessRuneColors[runeType] or classlessRuneColors[1]));
			ClasslessRuneButton_ShineFadeIn(self.shine)
		end
	end

	if (classlessRuneType) then
		self.runeTex:SetTexture(classlessRuneIconTextures[classlessRuneType]);
		-- self.fill:SetTexture(iconTextures[classlessRuneType]);
		self.runeTex:Show();
		-- self.fill:Show();
	else
		self.runeTex:Hide();
		-- self.fill:Hide();
		self.tooltipText = nil;
	end

end

function ClasslessRuneButton_OnEnter(self)
	if ( self.tooltipText ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(self.tooltipText);
		GameTooltip:Show();
	end
end

function ClasslessRuneButton_OnLeave(self)
	GameTooltip:Hide();
end

local function syncClasslessRuneCooldowns(runeFrame)
	runeFrame = runeFrame or ClasslessRuneFrame
	if not runeFrame or not runeFrame.runes then
		return
	end
	for i = 1, #(runeFrame.runes) do
		local btn = runeFrame.runes[i]
		if btn then
			btn:SetScript("OnUpdate", ClasslessRuneButton_OnUpdate)
			ClasslessRuneButton_OnUpdate(btn, 0)
		end
	end
end

function ClasslessRuneFrame_OnEvent (self, event, ...)
	if ( event == "RUNE_POWER_UPDATE" ) then
		local rune = ...;
		if ( rune and self.runes[rune] ) then
			local btn = self.runes[rune]
			btn:SetScript("OnUpdate", ClasslessRuneButton_OnUpdate)
			ClasslessRuneButton_OnUpdate(btn, 0)
			local _, _, ready = GetRuneCooldown and GetRuneCooldown(btn:GetID())
			if ready and btn.shine and btn.shine.shineTex then
				btn.shine.shineTex:SetVertexColor(1, 1, 1);
				ClasslessRuneButton_ShineFadeIn(btn.shine)
			end
		else
			syncClasslessRuneCooldowns(self)
		end
	elseif ( event == "RUNE_TYPE_UPDATE" ) then
        local rune = ...;
        if ( rune and self.runes[rune] ) then
            local t = GetRuneType and GetRuneType(rune)
            ClasslessRuneButton_Update(self.runes[rune], t or self.runes[rune].runeType);
        end
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        for i = 1, #(self.runes or {}) do
            local t = GetRuneType and GetRuneType(i)
            ClasslessRuneButton_Update(self.runes[i], t or self.runes[i].runeType, true);
        end
        syncClasslessRuneCooldowns(self)
    end
end

function ClasslessRuneFrame_AddRune (runeFrame, rune)
	tinsert(runeFrame.runes, rune);
end

function ClasslessRuneButton_ShineFadeIn(self)
	if self.shining then
		return
	end
	local fadeInfo={
	mode = "IN",
	timeToFade = 0.5,
	finishedFunc = RuneButton_ShineFadeOut,
	finishedArg1 = self,
	}
	self.shining=true;
	UIFrameFade(self, fadeInfo);
end

function ClasslessRuneButton_ShineFadeOut(self)
	self.shining=false;
	UIFrameFadeOut(self, 0.5);
end

local function GetRuneGridPosition(index)
    local row = math.floor((index - 1) / 2) + 1   -- 1..3
    local col = ((index - 1) % 2) + 1              -- 1..2
    return row, col
end

local function GetRuneTypeForIndex(index)
    if index == 1 or index == 2 then
        return 1
    elseif index == 3 or index == 4 then
        return 2
    elseif index == 5 or index == 6 then
        return 3
    else
        return 4
    end
end


local ClasslessResourceFrame = CreateFrame("Frame","ClasslessResourceFrame",UIParent,nil)
ClasslessResourceFrame:SetSize(100,80)
ClasslessResourceFrame:SetPoint("TOPLEFT", 258, -25)
ClasslessResourceFrame:SetMovable(true)
ClasslessResourceFrame:EnableMouse(true)
ClasslessResourceFrame:RegisterForDrag("LeftButton")
ClasslessResourceFrame:SetClampedToScreen(true)
--ClasslessResourceFrame:SetUserPlaced(true)
local ClasslessResourceFrameTexture = ClasslessResourceFrame:CreateTexture()
ClasslessResourceFrameTexture:SetAllPoints(ClasslessResourceFrame)
ClasslessResourceFrameTexture:SetTexture(.1,.1,.1,1)
ClasslessResourceFrame:SetScript("OnDragStart", ClasslessResourceFrame.StartMoving)
ClasslessResourceFrame:SetScript("OnHide", ClasslessResourceFrame.StopMovingOrSizing)
ClasslessResourceFrame:SetScript("OnDragStop", ClasslessResourceFrame.StopMovingOrSizing)
	
ClasslessResourceFrame:Show()



-- Parent frame
local ClasslessRuneFrame = CreateFrame("Frame", "ClasslessRuneFrame", ClasslessResourceFrame)
ClasslessRuneFrame:SetSize(32, 80)
ClasslessRuneFrame:SetPoint("TOPLEFT", ClasslessResourceFrame, "TOPLEFT", -52, 0)

ClasslessRuneFrame.runes = {};

-- Constants
local RUNE_COUNT = 6
local RUNE_SIZE = 24
local COL_SPACING = 3
local ROW_SPACING = 3

-- Storage table (preferred over raw globals)
ClasslessRunes = {}

for i = 1, RUNE_COUNT do
    -- Button
    local rune = CreateFrame(
        "Button",
        "ClasslessRune" .. i,
        ClasslessRuneFrame,
        nil
    )
    rune:SetSize(RUNE_SIZE, RUNE_SIZE)

    local row, col = GetRuneGridPosition(i)
    rune:ClearAllPoints()

    local xOffset = (col - 1) * (RUNE_SIZE + COL_SPACING)
    local yOffset = -((row - 1) * (RUNE_SIZE + ROW_SPACING))

    rune:SetPoint("TOPLEFT", ClasslessRuneFrame, "TOPLEFT", xOffset, yOffset)


    local runeType = GetRuneTypeForIndex(i)
    rune.runeType = runeType
    rune.gridRow  = row
    rune.gridCol  = col

    -- ============================================================
    -- Rune Texture (ARTWORK)
    -- ============================================================

    local runeTex = rune:CreateTexture(
        "ClasslessRune" .. i .. "Icon",
        "ARTWORK"
    )
    runeTex:SetSize(RUNE_SIZE, RUNE_SIZE)
    runeTex:SetPoint("CENTER", rune, "CENTER", 0, 0)
    runeTex:SetTexture(classlessRuneIconTextures[runeType])

    -- Ring sits above the cooldown so the swipe reads as a circle.
    local border = CreateFrame(
        "Frame",
        "ClasslessRune" .. i .. "Border",
        rune
    )
    border:SetSize(RUNE_SIZE, RUNE_SIZE)
    border:SetPoint("CENTER", rune, "CENTER", 0, 0)

    local borderTex = border:CreateTexture(
        "ClasslessRune" .. i .. "BorderTexture",
        "OVERLAY"
    )
    borderTex:SetAllPoints(border)
    borderTex:SetTexture("Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Ring")
    borderTex:SetVertexColor(0.6, 0.6, 0.6, 1)
    border.borderTex = borderTex

    -- ============================================================
    -- Shine Frame (hidden by default)
    -- ============================================================
    local shine = CreateFrame(
        "Frame",
        "ClasslessRune" .. i .. "Shine",
        rune
    )
    shine:SetAllPoints(rune)
    shine:SetFrameStrata("MEDIUM")
    shine:Hide()

    local shineTex = shine:CreateTexture(
        "ClasslessRune" .. i .. "ShineTexture",
        "OVERLAY"
    )
    shineTex:SetTexture("Interface\\ComboFrame\\ComboPoint")
    shineTex:SetBlendMode("ADD")
    shineTex:SetSize(60, 35)
    shineTex:SetPoint("CENTER", shine, "CENTER", 0, 0)
    shineTex:SetTexCoord(0.5625, 1, 0, 1)
    shine.shineTex = shineTex

    -- Circular cooldown overlay: diameter = RUNE_SIZE (radius size/2), on top
    -- of the rune art. A portrait mask crops the square swipe to a circle.
    local cd = CreateFrame(
        "Cooldown",
        "ClasslessRune" .. i .. "Cooldown",
        rune
    )
    cd:ClearAllPoints()
    cd:SetSize(RUNE_SIZE, RUNE_SIZE)
    cd:SetPoint("CENTER", rune, "CENTER", 0, 0)
    if cd.SetDrawEdge then
        cd:SetDrawEdge(true)
    end
    cd:SetFrameLevel(rune:GetFrameLevel() + 4)
    cd:Hide()

    local crop = cd:CreateTexture("ClasslessRune" .. i .. "Crop", "OVERLAY")
    crop:SetSize(RUNE_SIZE, RUNE_SIZE)
    crop:SetPoint("CENTER", cd, "CENTER", 0, 0)
    crop:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    crop:SetBlendMode("MOD")
    cd.crop = crop

    -- Explicit circular dimmer on top of the rune (radius = size/2).
    local circle = rune:CreateTexture("ClasslessRune" .. i .. "CdCircle", "OVERLAY")
    circle:SetSize(RUNE_SIZE, RUNE_SIZE)
    circle:SetPoint("CENTER", rune, "CENTER", 0, 0)
    circle:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    circle:SetVertexColor(0, 0, 0, 0.55)
    circle:Hide()
    rune.cdCircle = circle

    border:SetFrameLevel(cd:GetFrameLevel() + 1)


    -- ============================================================
    -- Scripts
    -- ============================================================
    rune:SetScript("OnLoad", ClasslessRuneButton_OnLoad)
    rune:SetScript("OnEnter", ClasslessRuneButton_OnEnter)
    rune:SetScript("OnLeave", ClasslessRuneButton_OnLeave)

    -- Store references
    rune.cooldown = cd
    rune.runeTex = runeTex
    rune.border = border
    rune.shine = shine

    if runeType == 1 then
        rune.tooltipText = _G["COMBAT_TEXT_RUNE_BLOOD"]
    elseif runeType == 2 then
        rune.tooltipText = _G["COMBAT_TEXT_RUNE_UNHOLY"]
    elseif runeType == 3 then
        rune.tooltipText = _G["COMBAT_TEXT_RUNE_FROST"]
    else
        rune.tooltipText = _G["COMBAT_TEXT_RUNE_DEATH"]
    end

    rune.runeTex:Show()
    rune.border:Show()
    rune:SetID(i)
    rune:Show()

    ClasslessRunes[i] = rune
    _G["ClasslessRune" .. i] = rune -- optional global for legacy access
    ClasslessRuneFrame_AddRune(ClasslessRuneFrame,rune)
end

for i = 1, RUNE_COUNT do
ClasslessRuneButton_Update(ClasslessRunes[i], ClasslessRunes[i].runeType, true)
end

ClasslessRuneFrame:RegisterEvent("RUNE_POWER_UPDATE");
ClasslessRuneFrame:RegisterEvent("RUNE_TYPE_UPDATE");
ClasslessRuneFrame:RegisterEvent("PLAYER_ENTERING_WORLD");

ClasslessRuneFrame:SetScript("OnEvent", ClasslessRuneFrame_OnEvent);
ClasslessRuneFrame:Show();
syncClasslessRuneCooldowns(ClasslessRuneFrame)
applyPendingRuneCds()
AIO.Handle("ClasslessResourceBarServer", "RequestRuneCooldowns")




current_energy = UnitPower("player", 3)
max_energy = UnitPowerMax("player", 3)

local EnergyFrame = CreateFrame("Frame","EnergyFrame",ClasslessResourceFrame,nil)
EnergyFrame:SetSize(100,20)


local EnergyStatusBar = CreateFrame("StatusBar", nil, EnergyFrame)
EnergyStatusBar:SetPoint("TOPLEFT")
EnergyStatusBar:SetPoint("TOPRIGHT",0,0)
EnergyStatusBar:SetMinMaxValues(0, 100)


local EnergyFont = EnergyStatusBar:CreateFontString("EnergyF")
EnergyFont:SetFont("Fonts\\FRIZQT__.TTF", 11)
EnergyFont:SetShadowOffset(1, -1)
EnergyFont:SetPoint("CENTER")
EnergyFont:SetText(current_energy.."/"..max_energy)

EnergyFrame:RegisterEvent("UNIT_ENERGY")
EnergyFrame:RegisterEvent("UNIT_RAGE")
EnergyFrame:RegisterEvent("UNIT_MANA")
EnergyFrame:RegisterEvent("UNIT_HEALTH")
EnergyFrame:RegisterEvent("UNIT_POWER")
EnergyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

EnergyFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) EnergyFrame:onUpdate(sinceLastUpdate); end);


function EnergyFrame:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if ( self.sinceLastUpdate >= .1 ) then -- in seconds
		EnergyFrame_eventHandler()
		self.sinceLastUpdate = 0;
	end
end

function EnergyFrame_eventHandler(self, event, ...)
	current_energy = UnitPower("player",3)
	max_energy = UnitPowerMax("player",3)
	
	if current_energy == 0 then
		current_energy_percent = 1
	else
        current_energy_percent = current_energy / max_energy * 100
    end
	
	EnergyStatusBar:SetValue(current_energy_percent)
	if Energy_ShowText == true then
		EnergyFont:SetText(current_energy.."/"..max_energy)
	else
		EnergyFont:SetText("")
	end
	
end





current_rage = UnitPower("player",1)
max_rage = UnitPowerMax("player",1)

local RageFrame = CreateFrame("Frame","RageFrame",ClasslessResourceFrame,nil)
RageFrame:SetSize(100,20)


local RageStatusBar = CreateFrame("StatusBar", nil, RageFrame)
RageStatusBar:SetPoint("BOTTOMLEFT")
RageStatusBar:SetPoint("BOTTOMRIGHT",0,0)
RageStatusBar:SetMinMaxValues(0, 100)
RageStatusBar:SetStatusBarColor(1,0,0)

local RageFont = RageStatusBar:CreateFontString("RageF")
RageFont:SetFont("Fonts\\FRIZQT__.TTF", 11)
RageFont:SetShadowOffset(1, -1)
RageFont:SetPoint("CENTER")

RageFrame:RegisterEvent("UNIT_RAGE")
RageFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

RageFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) RageFrame:onUpdate(sinceLastUpdate); end);


function RageFrame:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if ( self.sinceLastUpdate >= .1 ) then -- in seconds
		RageFrame_eventHandler()
		self.sinceLastUpdate = 0;
	end
end




function RageFrame_eventHandler(self, event, ...)
	current_rage = UnitPower("player",1)
	max_rage = UnitPowerMax("player",1)
	
	current_rage_percent = current_rage / max_rage * 100
	
	if current_rage == 0 then
		current_rage_percent = 1
	end
	
	RageStatusBar:SetValue(current_rage_percent)
	if Rage_ShowText == true then
		RageFont:SetText(current_rage.."/"..max_rage)
	else
		RageFont:SetText("")
	end
end

local RunicFrame = CreateFrame("Frame", "RunicFrame", ClasslessResourceFrame, nil)
RunicFrame:SetSize(100, 20)

RunicStatusBar = CreateFrame("StatusBar", nil, RunicFrame)
RunicStatusBar:SetPoint("LEFT")
RunicStatusBar:SetPoint("RIGHT", 0, 0)
RunicStatusBar:SetHeight(20)
RunicStatusBar:SetMinMaxValues(0, 100)
RunicStatusBar:SetStatusBarColor(0, 0.82, 1) -- Standard Runic Power Cyan

local RunicBG = RunicStatusBar:CreateTexture(nil, "BACKGROUND")
RunicBG:SetAllPoints(RunicStatusBar)
RunicBG:SetTexture(0.2, 0.2, 0.2, 1.0) -- Gray with 50% transparency

local RunicFont = RunicStatusBar:CreateFontString("RunicF")
RunicFont:SetFont("Fonts\\FRIZQT__.TTF", 11)
RunicFont:SetShadowOffset(1, -1)
RunicFont:SetPoint("CENTER")

function RunicFrame_eventHandler(self, event, ...)
    local current_runic = UnitPower("player", 6)
    local max_runic = UnitPowerMax("player", 6)

    local current_runic_percent = 1
    if max_runic > 0 then
        current_runic_percent = (current_runic / max_runic) * 100
    end

    RunicStatusBar:SetValue(current_runic_percent)
    if Runic_ShowText == true then
        RunicFont:SetText(current_runic.."/"..max_runic)
    else
        RunicFont:SetText("")
    end
end

RunicFrame:RegisterEvent("UNIT_RUNIC_POWER")
RunicFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
RunicFrame:SetScript("OnEvent", RunicFrame_eventHandler)

-- Update the main frame update loop to include Runic
RunicFrame:SetScript("OnUpdate", function(self, sinceLastUpdate)
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate
    if (self.sinceLastUpdate >= .1) then
        RunicFrame_eventHandler()
        self.sinceLastUpdate = 0
    end
end)




current_mana = UnitPower("player",0)
max_mana = UnitPowerMax("player",0)

local ManaFrame = CreateFrame("Frame","ManaFrame",ClasslessResourceFrame,nil)
ManaFrame:SetSize(100,20)


local ManaStatusBar = CreateFrame("StatusBar", nil, ManaFrame)
ManaStatusBar:SetPoint("LEFT")
ManaStatusBar:SetPoint("RIGHT",0,0)
ManaStatusBar:SetMinMaxValues(0, 100)
ManaStatusBar:SetStatusBarColor(0,0,1)

local ManaFont = ManaStatusBar:CreateFontString("ManaF")
ManaFont:SetFont("Fonts\\FRIZQT__.TTF", 11)
ManaFont:SetShadowOffset(1, -1)
ManaFont:SetPoint("CENTER")

ManaFrame:RegisterEvent("UNIT_MANA")
ManaFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

ManaFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) ManaFrame:onUpdate(sinceLastUpdate); end);


function ManaFrame:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if ( self.sinceLastUpdate >= .1 ) then -- in seconds
		ManaFrame_eventHandler()
		self.sinceLastUpdate = 0;
	end
end




function ManaFrame_eventHandler(self, event, ...)
	current_mana = UnitPower("player",0)
	max_mana = UnitPowerMax("player",0)
	
	current_mana_percent = current_mana / max_mana * 100
	
	if current_mana == 0 then
		current_mana_percent = 1
	end
	
	ManaStatusBar:SetValue(current_mana_percent)
	if Mana_ShowText == true then
		ManaFont:SetText(current_mana.."/"..max_mana)
	else
		ManaFont:SetText("")
	end
end






-- below is used for displaying the drop down menu on right click

local DropDownMenu = CreateFrame("Frame","ClasslessResourceDropDown")
DropDownMenu.displayMode = "MENU"

local info = {}
DropDownMenu.initialize = function(self, level)
	if not level then return end
	wipe(info)
	if level == 1 then
		-- Create the title of the menu
		info.isTitle = 1
		info.text = "Energy/Rage/Mana Options"
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)
		
		info.disabled = nil
		info.isTitle = nil
		info.notCheckable = nil
		
		info.text = "Energy Config"
		info.func = function()
			EnergyConfigFrame:Show()
			end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Rage Config"
		info.func = function()
			RageConfigFrame:Show()
			end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Mana Config"
		info.func = function()
			ManaConfigFrame:Show()
			end
		UIDropDownMenu_AddButton(info, level)

		info.text = "Runic Config"
        info.func = function()
            RunicConfigFrame:Show()
            end
        UIDropDownMenu_AddButton(info, level)
		
		info.text = "All Bars Config"
		info.func = function()
			ConfigFrame:Show()
			end
		UIDropDownMenu_AddButton(info, level)
	end
end

function OnMouseDown_ClasslessResourceFrame(self, button)

	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, DropDownMenu, self:GetName(), 0, 0)
	end

end

ClasslessResourceFrame:SetScript("OnMouseDown", OnMouseDown_ClasslessResourceFrame)

-- below is the config frames

RunicConfigFrame = CreateFrame("Frame","RunicConfigFrame",UIParent,nil)
RunicConfigFrame:SetSize(250,200)
RunicConfigFrame:SetPoint("CENTER")
RunicConfigFrame:EnableMouse(true)
RunicConfigFrame:SetMovable(true)
RunicConfigFrame:RegisterForDrag("LeftButton")
RunicConfigFrame:SetBackdrop({
	bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	edgeSize = 15,
})
RunicConfigFrame:SetScript("OnDragStart", RunicConfigFrame.StartMoving)
RunicConfigFrame:SetScript("OnHide", RunicConfigFrame.StopMovingOrSizing)
RunicConfigFrame:SetScript("OnDragStop", RunicConfigFrame.StopMovingOrSizing)

RunicConfigFrame_CloseButton = CreateFrame("Button", "RunicConfigFrame_CloseButton", RunicConfigFrame, "UIPanelCloseButton")
		RunicConfigFrame_CloseButton:SetPoint("TOPRIGHT", -5, -5)
		RunicConfigFrame_CloseButton:EnableMouse(true)
		RunicConfigFrame_CloseButton:SetSize(27, 27)
RunicConfigFrame:Hide()

local RunicConfigFrame_TitleBar = CreateFrame("Frame", "RunicConfigFrame_TitleBar", RunicConfigFrame, nil)
        RunicConfigFrame_TitleBar:SetSize(100, 25)
        RunicConfigFrame_TitleBar:SetBackdrop({
            bgFile = "Interface/CHARACTERFRAME/UI-Party-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            edgeSize = 15,
            tileSize = 15,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
		RunicConfigFrame_TitleBar:SetPoint("TOP", 20, 9)
		local RunicConfigFrame_TitleText = RunicConfigFrame_TitleBar:CreateFontString("RunicConfigFrame_TitleText")
        RunicConfigFrame_TitleText:SetFont("Fonts\\FRIZQT__.TTF", 13)
        RunicConfigFrame_TitleText:SetSize(225, 5)
        RunicConfigFrame_TitleText:SetPoint("CENTER", 0, 0)
        RunicConfigFrame_TitleText:SetText("|cffFFC125Runic Power|r")

RunicConfigFrame_SubmitButton = CreateFrame("Button","RunicConfigFrame_SubmitButton",RunicConfigFrame,nil)
RunicConfigFrame_SubmitButton:SetSize(50,20)
RunicConfigFrame_SubmitButton:SetPoint("BOTTOM", 20, 5)
RunicConfigFrame_SubmitButton_Text = RunicConfigFrame_SubmitButton:CreateFontString("RunicConfigFrame_SubmitButton_FS")
RunicConfigFrame_SubmitButton_Text:SetFont("Fonts\\FRIZQT__.TTF", 11)
RunicConfigFrame_SubmitButton_Text:SetShadowOffset(1, -1)
RunicConfigFrame_SubmitButton_Text:SetPoint("Center")
RunicConfigFrame_SubmitButton:SetFontString(RunicConfigFrame_SubmitButton_Text)
RunicConfigFrame_SubmitButton:SetText("Apply")
RunicConfigFrame_SubmitButton_Texture = RunicConfigFrame_SubmitButton:CreateTexture("RunicConfigFrame_SubmitButton_texture")
RunicConfigFrame_SubmitButton_Texture:SetTexture(.9,.2,0,.8)
RunicConfigFrame_SubmitButton_Texture:SetAllPoints(RunicConfigFrame_SubmitButton)
RunicConfigFrame_SubmitButton:SetNormalTexture(RunicConfigFrame_SubmitButton_Texture)

local function apply_runic_changes(self, button)
	Runic_Textures[1] = RunicRSlider:GetValue() / 100
	Runic_Textures[2] = RunicGSlider:GetValue() / 100
	Runic_Textures[3] = RunicBSlider:GetValue() / 100
	if RunicTextChecker:GetChecked() == 1 then
		Runic_ShowText = true
	else
		Runic_ShowText = false
	end
	init_loadUp()
end
RunicConfigFrame_SubmitButton:SetScript("OnMouseDown", apply_runic_changes)

-- Runic Sliders (R, G, B)
local RunicRSlider = CreateFrame("Slider", "RunicRSlider", RunicConfigFrame, "OptionsSliderTemplate")
RunicRSlider:SetPoint("CENTER", 20, 50)
RunicRSlider:SetMinMaxValues(0, 100)
RunicRSlider:SetScript("OnValueChanged", function(self) _G[self:GetName() .."Text"]:SetText("Red: "..self:GetValue()) end)

local RunicGSlider = CreateFrame("Slider", "RunicGSlider", RunicConfigFrame, "OptionsSliderTemplate")
RunicGSlider:SetPoint("CENTER", 20, 15)
RunicGSlider:SetMinMaxValues(0, 100)
RunicGSlider:SetScript("OnValueChanged", function(self) _G[self:GetName() .."Text"]:SetText("Green: "..self:GetValue()) end)

local RunicBSlider = CreateFrame("Slider", "RunicBSlider", RunicConfigFrame, "OptionsSliderTemplate")
RunicBSlider:SetPoint("CENTER", 20, -20)
RunicBSlider:SetMinMaxValues(0, 100)
RunicBSlider:SetScript("OnValueChanged", function(self) _G[self:GetName() .."Text"]:SetText("Blue: "..self:GetValue()) end)

local RunicTextChecker = CreateFrame("CheckButton","RunicTextChecker",RunicConfigFrame, "ChatConfigCheckButtonTemplate")
RunicTextChecker:SetPoint("CENTER", -20, -50)
_G[RunicTextChecker:GetName().."Text"]:SetText("Show Text")

EnergyConfigFrame = CreateFrame("Frame","EnergyConfigFrame",UIParent,nil)
EnergyConfigFrame:SetSize(250,200)
EnergyConfigFrame:SetPoint("CENTER")
EnergyConfigFrame:EnableMouse(true)
EnergyConfigFrame:SetMovable(true)
EnergyConfigFrame:RegisterForDrag("LeftButton")
EnergyConfigFrame:SetBackdrop({
	bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	edgeSize = 15,
})
EnergyConfigFrame:SetScript("OnDragStart", EnergyConfigFrame.StartMoving)
EnergyConfigFrame:SetScript("OnHide", EnergyConfigFrame.StopMovingOrSizing)
EnergyConfigFrame:SetScript("OnDragStop", EnergyConfigFrame.StopMovingOrSizing)

EnergyConfigFrame_CloseButton = CreateFrame("Button", "EnergyConfigFrame_CloseButton", EnergyConfigFrame, "UIPanelCloseButton")
		EnergyConfigFrame_CloseButton:SetPoint("TOPRIGHT", -5, -5)
		EnergyConfigFrame_CloseButton:EnableMouse(true)
		EnergyConfigFrame_CloseButton:SetSize(27, 27)
EnergyConfigFrame:Hide()

local EnergyConfigFrame_TitleBar = CreateFrame("Frame", "EnergyConfigFrame_TitleBar", EnergyConfigFrame, nil)
        EnergyConfigFrame_TitleBar:SetSize(100, 25)
        EnergyConfigFrame_TitleBar:SetBackdrop({
            bgFile = "Interface/CHARACTERFRAME/UI-Party-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            edgeSize = 15,
            tileSize = 15,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
		EnergyConfigFrame_TitleBar:SetPoint("TOP", 20, 9)
		local EnergyConfigFrame_TitleText = EnergyConfigFrame_TitleBar:CreateFontString("EnergyConfigFrame_TitleText")
        EnergyConfigFrame_TitleText:SetFont("Fonts\\FRIZQT__.TTF", 13)
        EnergyConfigFrame_TitleText:SetSize(225, 5)
        EnergyConfigFrame_TitleText:SetPoint("CENTER", 0, 0)
        EnergyConfigFrame_TitleText:SetText("|cffFFC125Energy Bar|r")


EnergyConfigFrame_SubmitButton = CreateFrame("Button","EnergyConfigFrame_SubmitButton",EnergyConfigFrame,nil)
EnergyConfigFrame_SubmitButton:SetSize(50,20)
EnergyConfigFrame_SubmitButton:SetPoint("BOTTOM", 20, 5)
EnergyConfigFrame_SubmitButton_Text = EnergyConfigFrame_SubmitButton:CreateFontString("EnergyConfigFrame_SubmitButton_FS")
EnergyConfigFrame_SubmitButton_Text:SetFont("Fonts\\FRIZQT__.TTF", 11)
EnergyConfigFrame_SubmitButton_Text:SetShadowOffset(1, -1)
EnergyConfigFrame_SubmitButton_Text:SetPoint("Center")
EnergyConfigFrame_SubmitButton:SetFontString(EnergyConfigFrame_SubmitButton_Text)
EnergyConfigFrame_SubmitButton:SetText("Apply")
EnergyConfigFrame_SubmitButton_Texture = EnergyConfigFrame_SubmitButton:CreateTexture("EnergyConfigFrame_SubmitButton_texture")
EnergyConfigFrame_SubmitButton_Texture:SetTexture(.9,.2,0,.8)
EnergyConfigFrame_SubmitButton_Texture:SetAllPoints(EnergyConfigFrame_SubmitButton)
EnergyConfigFrame_SubmitButton:SetNormalTexture(EnergyConfigFrame_SubmitButton_Texture)

function init_loadUp()

	if ConfigFrame_varis[4] == 1 then
		EnergyStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\normTex.tga")
		RageStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\normTex.tga")
		ManaStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\normTex.tga")
	elseif ConfigFrame_varis[4] == 2 then
		EnergyStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\Minimalist.tga")
		RageStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\Minimalist.tga")
		ManaStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\Minimalist.tga")
	end

	EnergyStatusBar:SetStatusBarColor(Energy_Textures[1],Energy_Textures[2],Energy_Textures[3])
	EnergyRSlider:SetValue(Energy_Textures[1] * 100)
	EnergyGSlider:SetValue(Energy_Textures[2] * 100)
	EnergyBSlider:SetValue(Energy_Textures[3] * 100)

	RageStatusBar:SetStatusBarColor(Rage_Textures[1],Rage_Textures[2],Rage_Textures[3])
	RageRSlider:SetValue(Rage_Textures[1] * 100)
	RageGSlider:SetValue(Rage_Textures[2] * 100)
	RageBSlider:SetValue(Rage_Textures[3] * 100)

	ManaStatusBar:SetStatusBarColor(Mana_Textures[1],Mana_Textures[2],Mana_Textures[3])
	ManaRSlider:SetValue(Mana_Textures[1] * 100)
	ManaGSlider:SetValue(Mana_Textures[2] * 100)
	ManaBSlider:SetValue(Mana_Textures[3] * 100)

	RunicStatusBar:SetStatusBarColor(Runic_Textures[1], Runic_Textures[2], Runic_Textures[3])
    RunicRSlider:SetValue(Runic_Textures[1] * 100)
    RunicGSlider:SetValue(Runic_Textures[2] * 100)
    RunicBSlider:SetValue(Runic_Textures[3] * 100)

	ClasslessResourceFrame:SetSize(ConfigFrame_varis[2],ConfigFrame_varis[3] * 4 + 2)
	EnergyFrame:SetSize(ConfigFrame_varis[2],ConfigFrame_varis[3])
	EnergyStatusBar:SetHeight(ConfigFrame_varis[3])
	RageFrame:SetSize(ConfigFrame_varis[2],ConfigFrame_varis[3])
	RageStatusBar:SetHeight(ConfigFrame_varis[3])
	ManaFrame:SetSize(ConfigFrame_varis[2],ConfigFrame_varis[3])
	ManaStatusBar:SetHeight(ConfigFrame_varis[3])
	RunicFrame:SetSize(ConfigFrame_varis[2], ConfigFrame_varis[3])
    RunicStatusBar:SetHeight(ConfigFrame_varis[3])
    RunicStatusBar:SetStatusBarTexture("Interface\\AddOns\\ClasslessUIAddons\\textures\\normTex.tga")

    -- Position Runic below Rage (assuming default stack)



	WidthSlider:SetValue(ConfigFrame_varis[2])
	HeightSlider:SetValue(ConfigFrame_varis[3])
	TextureChoseSlider:SetValue(ConfigFrame_varis[4])


	if ConfigFrame_varis[1] == true then
		EnergyFrame:SetPoint("TOP", 0, 0)
		ManaFrame:SetPoint("TOP", 0, -20)
		RageFrame:SetPoint("TOP", 0, -40)
		RunicFrame:SetPoint("TOP", 0, -60)
	else
		EnergyFrame:SetPoint("BOTTOM",0,0)
		ManaFrame:SetPoint("BOTTOM",0,20)
		RageFrame:SetPoint("BOTTOM",0,40)
		RunicFrame:SetPoint("BOTTOM",0,60)
	end
end

local function apply_energy_changes(self, button)
	Energy_Textures[1] = EnergyRSlider:GetValue() / 100
	Energy_Textures[2] = EnergyGSlider:GetValue() / 100
	Energy_Textures[3] = EnergyBSlider:GetValue() / 100
	if EnergyTextChecker:GetChecked() == 1 then
		Energy_ShowText = true
	else
		Energy_ShowText = false
	end
	init_loadUp()
end
EnergyConfigFrame_SubmitButton:SetScript("OnMouseDown", apply_energy_changes)

local EnergyRedFontString = EnergyConfigFrame:CreateFontString("EnergyRedFontString")
EnergyRedFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
EnergyRedFontString:SetShadowOffset(1, -1)
EnergyRedFontString:SetPoint("Center",-55,52)
EnergyRedFontString:SetText("Red:")

local EnergyRSlider = CreateFrame("Slider", "EnergyRSlider", EnergyConfigFrame, "OptionsSliderTemplate")
EnergyRSlider:SetSize(100, 17)
EnergyRSlider:SetPoint("CENTER", EnergyConfigFrame, "CENTER", 20, 50)
EnergyRSlider:SetValueStep(0.5)
EnergyRSlider:SetMinMaxValues(0, 100)
EnergyRSlider.tooltipText = 'Percentage of red'
_G[EnergyRSlider:GetName() .."Text"]:SetText(50)
EnergyRSlider:SetScript("OnValueChanged", function(self) _G[EnergyRSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[EnergyRSlider:GetName().."High"]:Hide()
_G[EnergyRSlider:GetName().."Low"]:Hide()
EnergyRSlider:Show()


local EnergyGreenFontString = EnergyConfigFrame:CreateFontString("EnergyGreenFontString")
EnergyGreenFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
EnergyGreenFontString:SetShadowOffset(1, -1)
EnergyGreenFontString:SetPoint("Center",-62,17)
EnergyGreenFontString:SetText("Green:")

local EnergyGSlider = CreateFrame("Slider", "EnergyGSlider", EnergyConfigFrame, "OptionsSliderTemplate")
EnergyGSlider:SetSize(100, 17)
EnergyGSlider:SetPoint("CENTER", EnergyConfigFrame, "CENTER", 20, 15)
EnergyGSlider:SetValueStep(0.5)
EnergyGSlider:SetMinMaxValues(0, 100)
EnergyGSlider.tooltipText = 'Percentage of green'
_G[EnergyGSlider:GetName() .."Text"]:SetText(50)
EnergyGSlider:SetScript("OnValueChanged", function(self) _G[EnergyGSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[EnergyGSlider:GetName().."High"]:Hide()
_G[EnergyGSlider:GetName().."Low"]:Hide()
EnergyGSlider:Show()


local EnergyBlueFontString = EnergyConfigFrame:CreateFontString("EnergyBlueFontString")
EnergyBlueFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
EnergyBlueFontString:SetShadowOffset(1, -1)
EnergyBlueFontString:SetPoint("Center",-56,-18)
EnergyBlueFontString:SetText("Blue:")


local EnergyBSlider = CreateFrame("Slider", "EnergyBSlider", EnergyConfigFrame, "OptionsSliderTemplate")
EnergyBSlider:SetSize(100, 17)
EnergyBSlider:SetPoint("CENTER", EnergyConfigFrame, "CENTER", 20, -20)
EnergyBSlider:SetValueStep(0.5)
EnergyBSlider:SetMinMaxValues(0, 100)
EnergyBSlider.tooltipText = 'Percentage of blue'
_G[EnergyBSlider:GetName() .."Text"]:SetText(50)
EnergyBSlider:SetScript("OnValueChanged", function(self) _G[EnergyBSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[EnergyBSlider:GetName().."High"]:Hide()
_G[EnergyBSlider:GetName().."Low"]:Hide()
EnergyBSlider:Show()


local EnergyTextFontString = EnergyConfigFrame:CreateFontString("EnergyTextFontString")
EnergyTextFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
EnergyTextFontString:SetShadowOffset(1, -1)
EnergyTextFontString:SetPoint("Center",-77,-48)
EnergyTextFontString:SetText("Show Text:")

local EnergyTextChecker = CreateFrame("CheckButton","EnergyTextChecker",EnergyConfigFrame, "ChatConfigCheckButtonTemplate")
EnergyTextChecker:SetPoint("CENTER", -20, -50)
EnergyTextChecker.tooltip = "Show text over resource"




RageConfigFrame = CreateFrame("Frame","RageConfigFrame",UIParent,nil)
RageConfigFrame:SetSize(250,200)
RageConfigFrame:SetPoint("CENTER")
RageConfigFrame:EnableMouse(true)
RageConfigFrame:SetMovable(true)
RageConfigFrame:RegisterForDrag("LeftButton")
RageConfigFrame:SetBackdrop({
	bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	edgeSize = 15,
})
RageConfigFrame:SetScript("OnDragStart", RageConfigFrame.StartMoving)
RageConfigFrame:SetScript("OnHide", RageConfigFrame.StopMovingOrSizing)
RageConfigFrame:SetScript("OnDragStop", RageConfigFrame.StopMovingOrSizing)

RageConfigFrame_CloseButton = CreateFrame("Button", "RageConfigFrame_CloseButton", RageConfigFrame, "UIPanelCloseButton")
		RageConfigFrame_CloseButton:SetPoint("TOPRIGHT", -5, -5)
		RageConfigFrame_CloseButton:EnableMouse(true)
		RageConfigFrame_CloseButton:SetSize(27, 27)
RageConfigFrame:Hide()


local RageConfigFrame_TitleBar = CreateFrame("Frame", "RageConfigFrame_TitleBar", RageConfigFrame, nil)
        RageConfigFrame_TitleBar:SetSize(100, 25)
        RageConfigFrame_TitleBar:SetBackdrop({
            bgFile = "Interface/CHARACTERFRAME/UI-Party-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            edgeSize = 15,
            tileSize = 15,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
		RageConfigFrame_TitleBar:SetPoint("TOP", 20, 9)
		local RageConfigFrame_TitleText = RageConfigFrame_TitleBar:CreateFontString("RageConfigFrame_TitleText")
        RageConfigFrame_TitleText:SetFont("Fonts\\FRIZQT__.TTF", 13)
        RageConfigFrame_TitleText:SetSize(225, 5)
        RageConfigFrame_TitleText:SetPoint("CENTER", 0, 0)
        RageConfigFrame_TitleText:SetText("|cffFFC125Rage Bar|r")


RageConfigFrame_SubmitButton = CreateFrame("Button","RageConfigFrame_SubmitButton",RageConfigFrame,nil)
RageConfigFrame_SubmitButton:SetSize(50,20)
RageConfigFrame_SubmitButton:SetPoint("BOTTOM", 20, 5)
RageConfigFrame_SubmitButton_Text = RageConfigFrame_SubmitButton:CreateFontString("RageConfigFrame_SubmitButton_FS")
RageConfigFrame_SubmitButton_Text:SetFont("Fonts\\FRIZQT__.TTF", 11)
RageConfigFrame_SubmitButton_Text:SetShadowOffset(1, -1)
RageConfigFrame_SubmitButton_Text:SetPoint("Center")
RageConfigFrame_SubmitButton:SetFontString(RageConfigFrame_SubmitButton_Text)
RageConfigFrame_SubmitButton:SetText("Apply")
RageConfigFrame_SubmitButton_Texture = RageConfigFrame_SubmitButton:CreateTexture("RageConfigFrame_SubmitButton_texture")
RageConfigFrame_SubmitButton_Texture:SetTexture(.9,.2,0,.8)
RageConfigFrame_SubmitButton_Texture:SetAllPoints(RageConfigFrame_SubmitButton)
RageConfigFrame_SubmitButton:SetNormalTexture(RageConfigFrame_SubmitButton_Texture)

local function apply_rage_changes(self, button)
	Rage_Textures[1] = RageRSlider:GetValue() / 100
	Rage_Textures[2] = RageGSlider:GetValue() / 100
	Rage_Textures[3] = RageBSlider:GetValue() / 100
	if RageTextChecker:GetChecked() == 1 then
		Rage_ShowText = true
	else
		Rage_ShowText = false
	end
	init_loadUp()
end
RageConfigFrame_SubmitButton:SetScript("OnMouseDown", apply_rage_changes)

local RageRedFontString = RageConfigFrame:CreateFontString("RageRedFontString")
RageRedFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
RageRedFontString:SetShadowOffset(1, -1)
RageRedFontString:SetPoint("Center",-55,52)
RageRedFontString:SetText("Red:")

local RageRSlider = CreateFrame("Slider", "RageRSlider", RageConfigFrame, "OptionsSliderTemplate")
RageRSlider:SetSize(100, 17)
RageRSlider:SetPoint("CENTER", RageConfigFrame, "CENTER", 20, 50)
RageRSlider:SetValueStep(0.5)
RageRSlider:SetMinMaxValues(0, 100)
RageRSlider.tooltipText = 'Percentage of red'
_G[RageRSlider:GetName() .."Text"]:SetText(50)
RageRSlider:SetScript("OnValueChanged", function(self) _G[RageRSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[RageRSlider:GetName().."High"]:Hide()
_G[RageRSlider:GetName().."Low"]:Hide()
RageRSlider:Show()


local RageGreenFontString = RageConfigFrame:CreateFontString("RageGreenFontString")
RageGreenFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
RageGreenFontString:SetShadowOffset(1, -1)
RageGreenFontString:SetPoint("Center",-62,17)
RageGreenFontString:SetText("Green:")

local RageGSlider = CreateFrame("Slider", "RageGSlider", RageConfigFrame, "OptionsSliderTemplate")
RageGSlider:SetSize(100, 17)
RageGSlider:SetPoint("CENTER", RageConfigFrame, "CENTER", 20, 15)
RageGSlider:SetValueStep(0.5)
RageGSlider:SetMinMaxValues(0, 100)
RageGSlider.tooltipText = 'Percentage of green'
_G[RageGSlider:GetName() .."Text"]:SetText(50)
RageGSlider:SetScript("OnValueChanged", function(self) _G[RageGSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[RageGSlider:GetName().."High"]:Hide()
_G[RageGSlider:GetName().."Low"]:Hide()
RageGSlider:Show()


local RageBlueFontString = RageConfigFrame:CreateFontString("RageBlueFontString")
RageBlueFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
RageBlueFontString:SetShadowOffset(1, -1)
RageBlueFontString:SetPoint("Center",-56,-18)
RageBlueFontString:SetText("Blue:")


local RageBSlider = CreateFrame("Slider", "RageBSlider", RageConfigFrame, "OptionsSliderTemplate")
RageBSlider:SetSize(100, 17)
RageBSlider:SetPoint("CENTER", RageConfigFrame, "CENTER", 20, -20)
RageBSlider:SetValueStep(0.5)
RageBSlider:SetMinMaxValues(0, 100)
RageBSlider.tooltipText = 'Percentage of blue'
_G[RageBSlider:GetName() .."Text"]:SetText(50)
RageBSlider:SetScript("OnValueChanged", function(self) _G[RageBSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[RageBSlider:GetName().."High"]:Hide()
_G[RageBSlider:GetName().."Low"]:Hide()
RageBSlider:Show()


local RageTextFontString = RageConfigFrame:CreateFontString("RageTextFontString")
RageTextFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
RageTextFontString:SetShadowOffset(1, -1)
RageTextFontString:SetPoint("Center",-77,-48)
RageTextFontString:SetText("Show Text:")

local RageTextChecker = CreateFrame("CheckButton","RageTextChecker",RageConfigFrame, "ChatConfigCheckButtonTemplate")
RageTextChecker:SetPoint("CENTER", -20, -50)
RageTextChecker.tooltip = "Show text over resource"

-- Begin Mana Frame

ManaConfigFrame = CreateFrame("Frame","ManaConfigFrame",UIParent,nil)
ManaConfigFrame:SetSize(250,200)
ManaConfigFrame:SetPoint("CENTER")
ManaConfigFrame:EnableMouse(true)
ManaConfigFrame:SetMovable(true)
ManaConfigFrame:RegisterForDrag("LeftButton")
ManaConfigFrame:SetBackdrop({
	bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	edgeSize = 15,
})
ManaConfigFrame:SetScript("OnDragStart", ManaConfigFrame.StartMoving)
ManaConfigFrame:SetScript("OnHide", ManaConfigFrame.StopMovingOrSizing)
ManaConfigFrame:SetScript("OnDragStop", ManaConfigFrame.StopMovingOrSizing)

ManaConfigFrame_CloseButton = CreateFrame("Button", "ManaConfigFrame_CloseButton", ManaConfigFrame, "UIPanelCloseButton")
		ManaConfigFrame_CloseButton:SetPoint("TOPRIGHT", -5, -5)
		ManaConfigFrame_CloseButton:EnableMouse(true)
		ManaConfigFrame_CloseButton:SetSize(27, 27)
ManaConfigFrame:Hide()


local ManaConfigFrame_TitleBar = CreateFrame("Frame", "ManaConfigFrame_TitleBar", ManaConfigFrame, nil)
        ManaConfigFrame_TitleBar:SetSize(100, 25)
        ManaConfigFrame_TitleBar:SetBackdrop({
            bgFile = "Interface/CHARACTERFRAME/UI-Party-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            edgeSize = 15,
            tileSize = 15,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
		ManaConfigFrame_TitleBar:SetPoint("TOP", 20, 9)
		local ManaConfigFrame_TitleText = ManaConfigFrame_TitleBar:CreateFontString("ManaConfigFrame_TitleText")
        ManaConfigFrame_TitleText:SetFont("Fonts\\FRIZQT__.TTF", 13)
        ManaConfigFrame_TitleText:SetSize(225, 5)
        ManaConfigFrame_TitleText:SetPoint("CENTER", 0, 0)
        ManaConfigFrame_TitleText:SetText("|cffFFC125Mana Bar|r")


ManaConfigFrame_SubmitButton = CreateFrame("Button","ManaConfigFrame_SubmitButton",ManaConfigFrame,nil)
ManaConfigFrame_SubmitButton:SetSize(50,20)
ManaConfigFrame_SubmitButton:SetPoint("BOTTOM", 20, 5)
ManaConfigFrame_SubmitButton_Text = ManaConfigFrame_SubmitButton:CreateFontString("ManaConfigFrame_SubmitButton_FS")
ManaConfigFrame_SubmitButton_Text:SetFont("Fonts\\FRIZQT__.TTF", 11)
ManaConfigFrame_SubmitButton_Text:SetShadowOffset(1, -1)
ManaConfigFrame_SubmitButton_Text:SetPoint("Center")
ManaConfigFrame_SubmitButton:SetFontString(ManaConfigFrame_SubmitButton_Text)
ManaConfigFrame_SubmitButton:SetText("Apply")
ManaConfigFrame_SubmitButton_Texture = ManaConfigFrame_SubmitButton:CreateTexture("ManaConfigFrame_SubmitButton_texture")
ManaConfigFrame_SubmitButton_Texture:SetTexture(.9,.2,0,.8)
ManaConfigFrame_SubmitButton_Texture:SetAllPoints(ManaConfigFrame_SubmitButton)
ManaConfigFrame_SubmitButton:SetNormalTexture(ManaConfigFrame_SubmitButton_Texture)

local function apply_Mana_changes(self, button)
	Mana_Textures[1] = ManaRSlider:GetValue() / 100
	Mana_Textures[2] = ManaGSlider:GetValue() / 100
	Mana_Textures[3] = ManaBSlider:GetValue() / 100
	if ManaTextChecker:GetChecked() == 1 then
		Mana_ShowText = true
	else
		Mana_ShowText = false
	end
	init_loadUp()
end
ManaConfigFrame_SubmitButton:SetScript("OnMouseDown", apply_Mana_changes)

local ManaRedFontString = ManaConfigFrame:CreateFontString("ManaRedFontString")
ManaRedFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
ManaRedFontString:SetShadowOffset(1, -1)
ManaRedFontString:SetPoint("Center",-55,52)
ManaRedFontString:SetText("Red:")

local ManaRSlider = CreateFrame("Slider", "ManaRSlider", ManaConfigFrame, "OptionsSliderTemplate")
ManaRSlider:SetSize(100, 17)
ManaRSlider:SetPoint("CENTER", ManaConfigFrame, "CENTER", 20, 50)
ManaRSlider:SetValueStep(0.5)
ManaRSlider:SetMinMaxValues(0, 100)
ManaRSlider.tooltipText = 'Percentage of red'
_G[ManaRSlider:GetName() .."Text"]:SetText(50)
ManaRSlider:SetScript("OnValueChanged", function(self) _G[ManaRSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[ManaRSlider:GetName().."High"]:Hide()
_G[ManaRSlider:GetName().."Low"]:Hide()
ManaRSlider:Show()


local ManaGreenFontString = ManaConfigFrame:CreateFontString("ManaGreenFontString")
ManaGreenFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
ManaGreenFontString:SetShadowOffset(1, -1)
ManaGreenFontString:SetPoint("Center",-62,17)
ManaGreenFontString:SetText("Green:")

local ManaGSlider = CreateFrame("Slider", "ManaGSlider", ManaConfigFrame, "OptionsSliderTemplate")
ManaGSlider:SetSize(100, 17)
ManaGSlider:SetPoint("CENTER", ManaConfigFrame, "CENTER", 20, 15)
ManaGSlider:SetValueStep(0.5)
ManaGSlider:SetMinMaxValues(0, 100)
ManaGSlider.tooltipText = 'Percentage of green'
_G[ManaGSlider:GetName() .."Text"]:SetText(50)
ManaGSlider:SetScript("OnValueChanged", function(self) _G[ManaGSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[ManaGSlider:GetName().."High"]:Hide()
_G[ManaGSlider:GetName().."Low"]:Hide()
ManaGSlider:Show()


local ManaBlueFontString = ManaConfigFrame:CreateFontString("ManaBlueFontString")
ManaBlueFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
ManaBlueFontString:SetShadowOffset(1, -1)
ManaBlueFontString:SetPoint("Center",-56,-18)
ManaBlueFontString:SetText("Blue:")


local ManaBSlider = CreateFrame("Slider", "ManaBSlider", ManaConfigFrame, "OptionsSliderTemplate")
ManaBSlider:SetSize(100, 17)
ManaBSlider:SetPoint("CENTER", ManaConfigFrame, "CENTER", 20, -20)
ManaBSlider:SetValueStep(0.5)
ManaBSlider:SetMinMaxValues(0, 100)
ManaBSlider.tooltipText = 'Percentage of blue'
_G[ManaBSlider:GetName() .."Text"]:SetText(50)
ManaBSlider:SetScript("OnValueChanged", function(self) _G[ManaBSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[ManaBSlider:GetName().."High"]:Hide()
_G[ManaBSlider:GetName().."Low"]:Hide()
ManaBSlider:Show()


local ManaTextFontString = ManaConfigFrame:CreateFontString("ManaTextFontString")
ManaTextFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
ManaTextFontString:SetShadowOffset(1, -1)
ManaTextFontString:SetPoint("Center",-77,-48)
ManaTextFontString:SetText("Show Text:")

local ManaTextChecker = CreateFrame("CheckButton","ManaTextChecker",ManaConfigFrame, "ChatConfigCheckButtonTemplate")
ManaTextChecker:SetPoint("CENTER", -20, -50)
ManaTextChecker.tooltip = "Show text over resource"

-- End Mana Frame


ConfigFrame = CreateFrame("Frame","ConfigFrame",UIParent,nil)
ConfigFrame:SetSize(250,200)
ConfigFrame:SetPoint("CENTER")
ConfigFrame:EnableMouse(true)
ConfigFrame:SetMovable(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetBackdrop({
	bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	edgeSize = 15,
})
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnHide", ConfigFrame.StopMovingOrSizing)
ConfigFrame:SetScript("OnDragStop", ConfigFrame.StopMovingOrSizing)

ConfigFrame_CloseButton = CreateFrame("Button", "ConfigFrame_CloseButton", ConfigFrame, "UIPanelCloseButton")
		ConfigFrame_CloseButton:SetPoint("TOPRIGHT", -5, -5)
		ConfigFrame_CloseButton:EnableMouse(true)
		ConfigFrame_CloseButton:SetSize(27, 27)
ConfigFrame:Hide()

local ConfigFrame_TitleBar = CreateFrame("Frame", "ConfigFrame_TitleBar", ConfigFrame, nil)
        ConfigFrame_TitleBar:SetSize(100, 25)
        ConfigFrame_TitleBar:SetBackdrop({
            bgFile = "Interface/CHARACTERFRAME/UI-Party-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            edgeSize = 15,
            tileSize = 15,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
		ConfigFrame_TitleBar:SetPoint("TOP", 20, 9)
		local ConfigFrame_TitleText = ConfigFrame_TitleBar:CreateFontString("ConfigFrame_TitleText")
        ConfigFrame_TitleText:SetFont("Fonts\\FRIZQT__.TTF", 13)
        ConfigFrame_TitleText:SetSize(225, 5)
        ConfigFrame_TitleText:SetPoint("CENTER", 0, 0)
        ConfigFrame_TitleText:SetText("|cffFFC125All Bars|r")


ConfigFrame_SubmitButton = CreateFrame("Button","ConfigFrame_SubmitButton",ConfigFrame,nil)
ConfigFrame_SubmitButton:SetSize(50,20)
ConfigFrame_SubmitButton:SetPoint("BOTTOM", 20, 5)
ConfigFrame_SubmitButton_Text = ConfigFrame_SubmitButton:CreateFontString("ConfigFrame_SubmitButton_FS")
ConfigFrame_SubmitButton_Text:SetFont("Fonts\\FRIZQT__.TTF", 11)
ConfigFrame_SubmitButton_Text:SetShadowOffset(1, -1)
ConfigFrame_SubmitButton_Text:SetPoint("Center")
ConfigFrame_SubmitButton:SetFontString(ConfigFrame_SubmitButton_Text)
ConfigFrame_SubmitButton:SetText("Apply")
ConfigFrame_SubmitButton_Texture = ConfigFrame_SubmitButton:CreateTexture("ConfigFrame_SubmitButton_texture")
ConfigFrame_SubmitButton_Texture:SetTexture(.9,.2,0,.8)
ConfigFrame_SubmitButton_Texture:SetAllPoints(ConfigFrame_SubmitButton)
ConfigFrame_SubmitButton:SetNormalTexture(ConfigFrame_SubmitButton_Texture)


local function apply_all_changes(self, button)

	ConfigFrame_varis[2] = WidthSlider:GetValue()
	ConfigFrame_varis[3] = HeightSlider:GetValue()
	ConfigFrame_varis[4] = TextureChoseSlider:GetValue()

	if FirstTextChecker:GetChecked() == 1 then
		ConfigFrame_varis[1] = true
	elseif FirstTextChecker:GetChecked() == nil then
		ConfigFrame_varis[1] = false
	end

	init_loadUp()
end
ConfigFrame_SubmitButton:SetScript("OnMouseDown", apply_all_changes)


local TextureChoseFontString = ConfigFrame:CreateFontString("TextureChoseFontString")
TextureChoseFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
TextureChoseFontString:SetShadowOffset(1, -1)
TextureChoseFontString:SetPoint("Center",-55,52)
TextureChoseFontString:SetText("Texture:")

local TextureChoseSlider = CreateFrame("Slider", "TextureChoseSlider", ConfigFrame, "OptionsSliderTemplate")
TextureChoseSlider:SetSize(100, 17)
TextureChoseSlider:SetPoint("CENTER", RageConfigFrame, "CENTER", 20, 50)
TextureChoseSlider:SetValueStep(1)
TextureChoseSlider:SetMinMaxValues(1, 2)
TextureChoseSlider.tooltipText = 'Texture to use.'
_G[TextureChoseSlider:GetName() .."Text"]:SetText(50)
TextureChoseSlider:SetScript("OnValueChanged", function(self) _G[TextureChoseSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[TextureChoseSlider:GetName().."High"]:Hide()
_G[TextureChoseSlider:GetName().."Low"]:Hide()
TextureChoseSlider:Show()


local HeightFontString = ConfigFrame:CreateFontString("HeightFontString")
HeightFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
HeightFontString:SetShadowOffset(1, -1)
HeightFontString:SetPoint("Center",-56,17)
HeightFontString:SetText("Height:")


local HeightSlider = CreateFrame("Slider", "HeightSlider", ConfigFrame, "OptionsSliderTemplate")
HeightSlider:SetSize(100, 17)
HeightSlider:SetPoint("CENTER", ConfigFrame, "CENTER", 20, 15)
HeightSlider:SetValueStep(3)
HeightSlider:SetMinMaxValues(10, 100)
HeightSlider.tooltipText = 'Height of bars.\nMay Require a reload.'
_G[HeightSlider:GetName() .."Text"]:SetText(50)
HeightSlider:SetScript("OnValueChanged", function(self) _G[HeightSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[HeightSlider:GetName().."High"]:Hide()
_G[HeightSlider:GetName().."Low"]:Hide()
HeightSlider:Show()


local WidthFontString = ConfigFrame:CreateFontString("WidthFontString")
WidthFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
WidthFontString:SetShadowOffset(1, -1)
WidthFontString:SetPoint("Center",-56,-18)
WidthFontString:SetText("Width:")


local WidthSlider = CreateFrame("Slider", "WidthSlider", ConfigFrame, "OptionsSliderTemplate")
WidthSlider:SetSize(100, 17)
WidthSlider:SetPoint("CENTER", ConfigFrame, "CENTER", 20, -20)
WidthSlider:SetValueStep(5)
WidthSlider:SetMinMaxValues(10, 300)
WidthSlider.tooltipText = 'Width of bars.\nMay Require a reload.'
_G[WidthSlider:GetName() .."Text"]:SetText(50)
WidthSlider:SetScript("OnValueChanged", function(self) _G[WidthSlider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[WidthSlider:GetName().."High"]:Hide()
_G[WidthSlider:GetName().."Low"]:Hide()
WidthSlider:Show()


local FirstTextFontString = ConfigFrame:CreateFontString("FirstTextFontString")
FirstTextFontString:SetFont("Fonts\\FRIZQT__.TTF", 14)
FirstTextFontString:SetShadowOffset(1, -1)
FirstTextFontString:SetPoint("Center",-77,-48)
FirstTextFontString:SetText("Energy First:")

local FirstTextChecker = CreateFrame("CheckButton","FirstTextChecker",ConfigFrame, "ChatConfigCheckButtonTemplate")
FirstTextChecker:SetPoint("CENTER", -20, -50)
FirstTextChecker.tooltip = "Whether energy is first or not.\nmay require reload"

local function loadResourceBarSettings()
	do
		if Energy_Textures == nil then
			Energy_Textures = {1,1,0}
		end
		if Energy_ShowText == nil then
			Energy_ShowText = true
			EnergyTextChecker:SetChecked(true)
		else
			if Energy_ShowText == true then
				EnergyTextChecker:SetChecked(true)
			else
				EnergyTextChecker:SetChecked(false)
			end
		end

		if Rage_Textures == nil then
			Rage_Textures = {1,0,0}
		end
		if Rage_ShowText == nil then
			Rage_ShowText = true
			RageTextChecker:SetChecked(true)
		else
			if Rage_ShowText == true then
				RageTextChecker:SetChecked(true)
			else
				RageTextChecker:SetChecked(false)
			end
		end

		if Mana_Textures == nil then
			Mana_Textures = {0,0,1}
		end
		if Mana_ShowText == nil then
			Mana_ShowText = true
			ManaTextChecker:SetChecked(true)
		else
			if Mana_ShowText == true then
				ManaTextChecker:SetChecked(true)
			else
				ManaTextChecker:SetChecked(false)
			end
		end

        if Runic_Textures == nil then
                Runic_Textures = {0, 0.82, 1}
        end
        if Runic_ShowText == nil then
            Runic_ShowText = true
            RunicTextChecker:SetChecked(true)
        else
            RunicTextChecker:SetChecked(Runic_ShowText)
        end

		if ConfigFrame_varis == nil then
			ConfigFrame_varis = {}
			ConfigFrame_varis[1] = true
			ConfigFrame_varis[2] = 100
			ConfigFrame_varis[3] = 20
			ConfigFrame_varis[4] = 1
			FirstTextChecker:SetChecked(true)
			WidthSlider:SetValue(ConfigFrame_varis[2])
			HeightSlider:SetValue(ConfigFrame_varis[3])
			TextureChoseSlider:SetValue(ConfigFrame_varis[4])
		elseif ConfigFrame_varis[1] == nil or ConfigFrame_varis[2] == nil or ConfigFrame_varis[3] == nil or ConfigFrame_varis[4] == nil then
			ConfigFrame_varis = {}
			ConfigFrame_varis[1] = true
			ConfigFrame_varis[2] = 100
			ConfigFrame_varis[3] = 20
			ConfigFrame_varis[4] = 1
			FirstTextChecker:SetChecked(true)
			WidthSlider:SetValue(ConfigFrame_varis[2])
			HeightSlider:SetValue(ConfigFrame_varis[3])
			TextureChoseSlider:SetValue(ConfigFrame_varis[4])
		elseif ConfigFrame_varis[1] == true then
			FirstTextChecker:SetChecked(true)
		end
	init_loadUp()
	end
end

loadResourceBarSettings()

ManaFrame:SetScript("OnEvent", ManaFrame_eventHandler)
RageFrame:SetScript("OnEvent", RageFrame_eventHandler)
EnergyFrame:SetScript("OnEvent", EnergyFrame_eventHandler)