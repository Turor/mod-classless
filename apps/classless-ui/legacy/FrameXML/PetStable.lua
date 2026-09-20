NUM_PET_STABLE_SLOTS = 4;

local isHunterPet = {
    ["Bat"] = true,
    ["Bear"] = true,
    ["Bird of Prey"] = true,
    ["Boar"] = true,
    ["Carrion Bird"] = true,
    ["Cat"] = true,
    ["Chimaera"] = true,
    ["Core Hound"] = true,

    ["Crab"] = true,
    ["Crocolisk"] = true,
    ["Devilsaur"] = true,
    ["Dragonhawk"] = true,
    ["Gorilla"] = true,
    ["Hyena"] = true,
    ["Moth"] = true,
    ["Nether Ray"] = true,

    ["Raptor"] = true,
    ["Ravager"] = true,
    ["Rhino"] = true,
    ["Scorpid"] = true,
    ["Serpent"] = true,
    ["Silithid"] = true,
    ["Spider"] = true,
    ["Spirit Beast"] = true,

    ["Sporebat"] = true,
    ["Tallstrider"] = true,
    ["Turtle"] = true,
    ["Warp Stalker"] = true,
    ["Wasp"] = true,
    ["Wind Serpent"] = true,
    ["Wolf"] = true,
    ["Worm"] = true,
}

local isNotHunterPet = {
    ["Doomguard"] = true,
    ["Felguard"] = true,
    ["Felhunter"] = true,
    ["Ghoul"] = true,
    ["Imp"] = true,
    ["Remote Control"] = true,
    ["Succubus"] = true,
    ["Voidwalker"] = true,
}

-- Return if pet exists, then if the pet is a hunterPet, then if pet is a permanent pet (always true for hunter pets)s
function ClasslessHasPetUI()
    local family = UnitCreatureFamily("pet")
    if family then
        if isHunterPet[family] then
            return true, true, true
        elseif isNotHunterPet[family] then
            return true, false, true
        else
            return true, false, false
        end
    end
    return false, false, false
end

function PetStable_OnLoad(self)
	self:RegisterEvent("PET_STABLE_SHOW");
	self:RegisterEvent("PET_STABLE_UPDATE");
	self:RegisterEvent("PET_STABLE_UPDATE_PAPERDOLL");
	self:RegisterEvent("PET_STABLE_CLOSED");
	self:RegisterEvent("UNIT_PET");
	self:RegisterEvent("UNIT_NAME_UPDATE");
end

function PetStable_OnEvent(self, event, ...)
	local arg1 = ...;
	if ( event == "PET_STABLE_SHOW" ) then
		ShowUIPanel(self);
		if ( not self:IsShown() ) then
			ClosePetStables();
			return;
		end

		PetStable_Update();
	elseif ( event == "PET_STABLE_UPDATE" or
	         (event == "UNIT_PET" and arg1 == "player") or
			 (event == "UNIT_NAME_UPDATE" and arg1 == "pet") ) then
		PetStable_Update();
	elseif ( event == "PET_STABLE_UPDATE_PAPERDOLL" ) then
		-- So warlock pets don't show
		local petExists, isHunterPet, isPermanent = ClasslessHasPetUI();
		if ( petExists and not isHunterPet ) then
			PetStable_NoPetsAllowed();
			return;
		end
		SetPetStablePaperdoll(PetStableModel);
	elseif ( event == "PET_STABLE_CLOSED" ) then
		HideUIPanel(self);
		StaticPopup_Hide("CONFIRM_BUY_STABLE_SLOT");
	end
end

function PetStable_Update()
	-- Set stablemaster portrait
	SetPortraitTexture(PetStableFramePortrait, "player");

	-- So warlock pets don't show
	local petExists, isHunterPet, isPermanent = ClasslessHasPetUI();
	if ( petExists and not isHunterPet) then
		PetStable_NoPetsAllowed();
		PetStableCurrentPet:Disable();
		return;
	else
		PetStableCurrentPet:Enable();
	end

	-- If no selected pet try to set one
	local selectedPet = GetSelectedStablePet();
	if ( selectedPet == -1 ) then
		if ( GetPetIcon() ) then
			selectedPet = 0;
			ClickStablePet(0);
		else
			for i=0, NUM_PET_STABLE_SLOTS do
				if ( GetStablePetInfo(i) ) then
					selectedPet = i;
					ClickStablePet(i);
					break;
				end
			end
		end
	end

	-- Set slot cost
	MoneyFrame_Update("PetStableCostMoneyFrame", GetNextStableSlotCost());

	-- Set slot statuseses
	local numSlots = GetNumStableSlots();
	local numPets = GetNumStablePets();

	local button, buttonName;
	local background;
	local icon, name, level, family, talent;
	for i=1, NUM_PET_STABLE_SLOTS do
		buttonName = "PetStableStabledPet"..i;
		button = _G[buttonName];
		background = _G[buttonName.."Background"];
		icon, name, level, family, talent = GetStablePetInfo(i);
		SetItemButtonTexture(button, icon);
		if ( i <= GetNumStableSlots() ) then
			background:SetVertexColor(1.0,1.0,1.0);
			button:Enable();
			if ( icon ) then
				button.tooltip = name;
				button.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent);
			else
				button.tooltip = EMPTY_STABLE_SLOT;
				button.tooltipSubtext = "";
			end
			if ( i == selectedPet ) then
				if ( icon ) then
					button:SetChecked(1);
					PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent);
					SetPetStablePaperdoll(PetStableModel);
					PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetStablePetFoodTypes(i)));
					if ( not PetStableModel:IsShown() ) then
						PetStableModel:Show();
					end
				else
					button:SetChecked(nil);
					PetStableLevelText:SetText("");
					PetStableModel:Hide();
				end

			else
				button:SetChecked(nil);
			end
			if ( GameTooltip:IsOwned(button) ) then
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
				GameTooltip:SetText(button.tooltip);
				GameTooltip:AddLine(button.tooltipSubtext, 1.0, 1.0, 1.0);
				GameTooltip:Show();
			end
		else
			background:SetVertexColor(1.0, 0.1, 0.1);
			button:Disable();
		end
	end

	-- Current pet slot
	if ( selectedPet == 0 ) then
        local petExists, isHunterPet, isPermanent = ClasslessHasPetUI();
		if ( petExists and isPermanent ) then
			PetStableCurrentPet:SetChecked(1);
			name = UnitName("pet") or "";
			level = UnitLevel("pet");
			family = UnitCreatureFamily("pet") or "";
			talent = GetPetTalentTree() or "";
			PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent);
			SetPetStablePaperdoll(PetStableModel);
			if ( not PetStableModel:IsShown() ) then
				PetStableModel:Show();
			end
			if ( GetPetFoodTypes() ) then
				PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetPetFoodTypes()));
			end
		elseif ( GetStablePetInfo(0) ) then
			-- If pet doesn't exist it might be dismissed, so check stable slot 0 for current pet info
			PetStableCurrentPet:SetChecked(1);
			icon, name, level, family, talent = GetStablePetInfo(0);
			PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent);
			SetPetStablePaperdoll(PetStableModel);
			if ( not PetStableModel:IsShown() ) then
				PetStableModel:Show();
			end
			if ( GetStablePetFoodTypes(0) ) then
				PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetStablePetFoodTypes(0)));
			end
		else
			PetStableCurrentPet:SetChecked(nil);
			PetStableLevelText:SetText("");
			PetStableModel:Hide();
		end
	else
		PetStableCurrentPet:SetChecked(nil);
	end

	-- Set tooltip and icon info
	if ( GetPetIcon() and UnitCreatureFamily("pet") ) then
		SetItemButtonTexture(PetStableCurrentPet, GetPetIcon());
		name = UnitName("pet") or "";
		level = UnitLevel("pet");
		family = UnitCreatureFamily("pet") or "";
		talent = GetPetTalentTree() or "";
		PetStableCurrentPet.tooltip = name;
		PetStableCurrentPet.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent);
	elseif ( GetStablePetInfo(0) ) then
		icon, name, level, family, talent = GetStablePetInfo(0);
		SetItemButtonTexture(PetStableCurrentPet, icon);
		PetStableCurrentPet.tooltip = name;
		PetStableCurrentPet.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent);
	else
		SetItemButtonTexture(PetStableCurrentPet, "");
		PetStableCurrentPet.tooltip = EMPTY_STABLE_SLOT;
		PetStableCurrentPet.tooltipSubtext = "";
		PetStableCurrentPet:SetChecked(nil);
	end
	if ( GameTooltip:IsOwned(PetStableCurrentPet) ) then
		GameTooltip:SetOwner(PetStableCurrentPet, "ANCHOR_RIGHT");
		GameTooltip:SetText(PetStableCurrentPet.tooltip);
		GameTooltip:AddLine(PetStableCurrentPet.tooltipSubtext, 1.0, 1.0, 1.0);
		GameTooltip:Show();
	end

	-- If no selected pet clear everything out
 	if ( selectedPet == -1 ) then
 		-- no pet
 		PetStableModel:Hide();
 		PetStableLevelText:SetText("");
 	end

	-- Enable, disable, or hide purchase button
	PetStablePurchaseButton:Show();
	if ( GetNumStableSlots() == NUM_PET_STABLE_SLOTS or (not IsAtStableMaster())) then
		PetStablePurchaseButton:Hide();
		PetStableCostLabel:Hide();
		PetStableCostMoneyFrame:Hide();
		PetStableSlotText:Hide();
	elseif ( GetMoney() >= GetNextStableSlotCost() ) then
		PetStablePurchaseButton:Show();
		PetStablePurchaseButton:Enable();
		PetStableCostLabel:Show();
		PetStableCostMoneyFrame:Show();
		PetStableSlotText:Show();
		SetMoneyFrameColor("PetStableCostMoneyFrame", "white");
	else
		PetStablePurchaseButton:Show();
		PetStablePurchaseButton:Disable();
		PetStableCostLabel:Show();
		PetStableCostMoneyFrame:Show();
		PetStableSlotText:Show();
		SetMoneyFrameColor("PetStableCostMoneyFrame", "red");
	end
end

function PetStable_NoPetsAllowed()
	local button;
	for i=1, NUM_PET_STABLE_SLOTS do
		button = _G["PetStableStabledPet"..i];
		button.tooltip = EMPTY_STABLE_SLOT;
		button:SetChecked(nil);
	end

	PetStableCurrentPet:SetChecked(nil);
	PetStableLevelText:SetText("");
	PetStableModel:Hide();
	SetItemButtonTexture(PetStableCurrentPet, "");
	PetStableCurrentPet.tooltip = EMPTY_STABLE_SLOT;
	PetStableCurrentPet:SetChecked(nil);
	PetStablePurchaseButton:Hide();
	PetStableCostLabel:Hide();
	PetStableCostMoneyFrame:Hide();
	PetStableSlotText:Hide();
end