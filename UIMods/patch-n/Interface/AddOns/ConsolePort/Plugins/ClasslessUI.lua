-- ConsolePortLK: ClasslessUI (AIO) takes the place of the stock spellbook
-- and talent frames. Cursor support stays on ClasslessUIFrame.
-- Do not register IsSpellNode: that path PickupSpell()s stock book slots.
-- Confirm click runs the button OnClick (AIO CastSpell / LearnTalent).
local FRAME_NAME = "ClasslessUIFrame"

local function tryToggleClassless()
	if type(_G.ClasslessUI_Toggle) == "function" then
		_G.ClasslessUI_Toggle()
		return true
	end
	local frame = _G[FRAME_NAME]
	if frame then
		if frame:IsShown() then
			frame:Hide()
		else
			frame:Show()
		end
		return true
	end
	if SlashCmdList and SlashCmdList.CLASSLESSUI then
		SlashCmdList.CLASSLESSUI()
		return true
	end
	return false
end

local function tryShowClassless()
	if type(_G.ClasslessUI_Show) == "function" then
		_G.ClasslessUI_Show()
		return true
	end
	local frame = _G[FRAME_NAME]
	if frame then
		frame:Show()
		return true
	end
	return tryToggleClassless()
end

local talentProxy = CreateFrame("Button", "ClasslessUITalentMicroProxy", UIParent)
talentProxy:SetScript("OnClick", function()
	tryToggleClassless()
end)

local spellbookProxy = CreateFrame("Button", "ClasslessUISpellbookMicroProxy", UIParent)
spellbookProxy:SetScript("OnClick", function()
	tryToggleClassless()
end)

local function installToggleHooks()
	if _G.ClasslessUI_CPToggleHooks then
		return
	end
	_G.ClasslessUI_CPToggleHooks = true
	if not _G.ClasslessUI_OrigToggleSpellBook then
		_G.ClasslessUI_OrigToggleSpellBook = ToggleSpellBook
	end
	if not _G.ClasslessUI_OrigToggleTalentFrame then
		_G.ClasslessUI_OrigToggleTalentFrame = ToggleTalentFrame
	end
	function ToggleSpellBook(bookType, ...)
		if tryToggleClassless() then
			return
		end
		local orig = _G.ClasslessUI_OrigToggleSpellBook
		if orig then
			return orig(bookType, ...)
		end
	end
	function ToggleTalentFrame(...)
		if tryToggleClassless() then
			return
		end
		local orig = _G.ClasslessUI_OrigToggleTalentFrame
		if orig then
			return orig(...)
		end
	end
end

local function hookStockFrame(frame)
	if not frame or frame.ClasslessUIRedirected then
		return
	end
	frame.ClasslessUIRedirected = true
	frame:HookScript("OnShow", function(self)
		if not (_G.ClasslessUI_Show or _G[FRAME_NAME]) then
			return
		end
		if HideUIPanel then
			HideUIPanel(self)
		else
			self:Hide()
		end
		tryShowClassless()
	end)
end

installToggleHooks()
hookStockFrame(_G.SpellBookFrame)
if type(TalentFrame_LoadUI) == "function" then
	hooksecurefunc("TalentFrame_LoadUI", function()
		hookStockFrame(_G.PlayerTalentFrame)
		hookStockFrame(_G.GlyphFrame)
	end)
end
hookStockFrame(_G.PlayerTalentFrame)
hookStockFrame(_G.GlyphFrame)

local function flagStaticNodes()
	local resize = _G.ClasslessUIFrameResize
	if resize then
		resize.ignoreNode = true
	end
	local close = _G.ClasslessUIFrameClose
	if close then
		close.ignoreMenu = true
	end
	for _, name in pairs({
		"ClasslessUISpellPaneScroll",
		"ClasslessUITalentPaneScroll",
	}) do
		local scroll = _G[name]
		if scroll then
			scroll.ignoreScroll = nil
		end
	end
end

local function attach(self)
	self:AddFrame(FRAME_NAME)
	flagStaticNodes()
	if self.UpdateFrames then
		self:UpdateFrames(true)
	end
end

ConsolePort:AddPlugin("ClasslessUI", function(self)
	installToggleHooks()
	attach(self)

	local watcher = CreateFrame("Frame")
	watcher.elapsed = 0
	watcher:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed < 0.5 then
			return
		end
		frame.elapsed = 0
		installToggleHooks()
		hookStockFrame(_G.SpellBookFrame)
		hookStockFrame(_G.PlayerTalentFrame)
		if _G[FRAME_NAME] then
			attach(self)
			frame:SetScript("OnUpdate", nil)
		end
	end)
end, true)
