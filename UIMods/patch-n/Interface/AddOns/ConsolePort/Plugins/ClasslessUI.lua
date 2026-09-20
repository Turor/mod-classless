-- ConsolePortLK cursor support for Turoran ClasslessUI (AIO, not a loadable addon).
-- Do not register IsSpellNode: that path PickupSpell()s stock book slots.
-- Confirm click runs the button OnClick (AIO CastSpell / LearnTalent).
local FRAME_NAME = "ClasslessUIFrame"

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
	attach(self)

	local watcher = CreateFrame("Frame")
	watcher.elapsed = 0
	watcher:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed < 0.5 then
			return
		end
		frame.elapsed = 0
		if _G[FRAME_NAME] then
			attach(self)
			frame:SetScript("OnUpdate", nil)
		end
	end)
end, true)
