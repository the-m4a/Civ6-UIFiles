-- Copyright 2017-2018 (c) Firaxis Games

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local RULESET_TYPE		:string = "RULESET_EXPANSION_1";
local OPTIONS_SEEN_KEY	:string = "HasSeenXP1FeaturesScreen";
local OPTIONS_HIDE_KEY	:string = "HideXP1FeaturesScreen";

local MIN_TUTORIAL_LEVEL = TutorialLevel.LEVEL_NEW_TO_XP1;

local INTRO_ILLUSTRATIONS:table = {
	"XP1Intro_Diagram_1",
	"XP1Intro_Diagram_2",
	"XP1Intro_Diagram_3",
	"XP1Intro_Diagram_4",
	"XP1Intro_Diagram_5",
	"XP1Intro_Diagram_6",
	"XP1Intro_Diagram_7",
	"XP1Intro_Diagram_8",
	"XP1Intro_Diagram_9",
};

local NUM_PAGES = #INTRO_ILLUSTRATIONS;

local INTRO_DESCRIPTIONS:table = {
	"LOC_TUTORIAL_XP1_INTRO_WELCOME",
	"LOC_TUTORIAL_XP1_INTRO_ERAS",
	"LOC_TUTORIAL_XP1_INTRO_AGES",
	"LOC_TUTORIAL_XP1_INTRO_LOYALTY",
	"LOC_TUTORIAL_XP1_INTRO_GOVERNORS",
	"LOC_TUTORIAL_XP1_INTRO_ALLIANCES",
	"LOC_TUTORIAL_XP1_INTRO_EMERGENCIES",
	"LOC_TUTORIAL_XP1_INTRO_CITYBANNER",
	"LOC_TUTORIAL_XP1_INTRO_END",
};

local INTRO_DESCRIPTIONS_DETAILS:table = {
	"",
	"",--"LOC_TUTORIAL_XP1_INTRO_ERAS_DETAILS_1",
	"",--"LOC_TUTORIAL_XP1_INTRO_AGES_DETAILS",
	"",--"LOC_TUTORIAL_XP1_INTRO_LOYALTY_DETAILS",
	"",--"LOC_TUTORIAL_XP1_INTRO_GOVERNORS_DETAILS",
	"",--"LOC_TUTORIAL_XP1_INTRO_EMERGENCIES_DETAILS", --This key was incorrectly named, it actually gives details for Alliances. We cannot rename it currently due to text lock.
	"",
	"",
	"LOC_TUTORIAL_XP1_INTRO_END_DETAILS_1",
};

local NEXT_BUTTON_TEXT = Locale.Lookup("LOC_XP1_INTRO_NEXT");
local CONTINUE_BUTTON_TEXT = Locale.Lookup("LOC_XP1_INTRO_CONTINUE");

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_PageIndex:number = 1;



-- ===========================================================================
function Realize()
	Controls.Illustration:SetTexture(INTRO_ILLUSTRATIONS[m_PageIndex]);
	Controls.Description:SetText(Locale.Lookup(INTRO_DESCRIPTIONS[m_PageIndex]));

	-- Show detail screens or hide box if we don't have any for this page
	if INTRO_DESCRIPTIONS_DETAILS[m_PageIndex] ~= "" then
		Controls.FrameDeco:SetHide(false);
		Controls.Description2:SetText(Locale.Lookup(INTRO_DESCRIPTIONS_DETAILS[m_PageIndex]));
	else
		Controls.FrameDeco:SetHide(true);
	end

	Controls.Next:SetText(m_PageIndex == NUM_PAGES and CONTINUE_BUTTON_TEXT or NEXT_BUTTON_TEXT);
	Controls.Previous:SetHide(m_PageIndex == 1);
	Controls.ButtonStack:CalculateSize();
end

-- ===========================================================================
function OnShow()
	m_PageIndex = 1;
	Realize();
	UIManager:QueuePopup(ContextPtr, PopupPriority.TutorialHigh);
end

-- ===========================================================================
function OnShowFromMenu()
	m_PageIndex = 1;
	Realize();
	UIManager:QueuePopup(ContextPtr, PopupPriority.Current);
end

-- ===========================================================================
function OnClose()
	UIManager:DequeuePopup(ContextPtr);	
end

-- ===========================================================================
function OnNext()
	if m_PageIndex >= NUM_PAGES then
		OnClose();
	else
		m_PageIndex = math.min(m_PageIndex + 1, NUM_PAGES);
		Realize();
	end
end

-- ===========================================================================
function OnPrevious()
	m_PageIndex = math.max(1, m_PageIndex - 1);
	Realize();
end

-- ===========================================================================
function OnLoadGameViewStateDone()

	local isRuleSet		:boolean = GameConfiguration.GetRuleSet() == RULESET_TYPE;
	local isAutoPlayMode:boolean = (Game.GetLocalPlayer() == -1);
	local hasSeenScreen	:boolean = Options.GetUserOption("Tutorial", OPTIONS_SEEN_KEY) == 1;
	local hideScreen	:boolean =  Options.GetUserOption("Tutorial", OPTIONS_HIDE_KEY) == 1;
	local showScreen	:boolean = isRuleSet
						and not GameConfiguration.IsNetworkMultiplayer()
						and not isAutoPlayMode
						and (not hasSeenScreen or UserConfiguration.TutorialLevel() <= MIN_TUTORIAL_LEVEL ) 
						and not hideScreen;

	if showScreen and Game.GetCurrentGameTurn() == GameConfiguration.GetStartTurn() then
		Options.SetUserOption("Tutorial", OPTIONS_SEEN_KEY, 1);
		Options.SaveOptions();
		OnShow();
	end
end

-- ===========================================================================
function OnInput( pInputStruct:table )
	local key = pInputStruct:GetKey();
	local type = pInputStruct:GetMessageType();
	if type == KeyEvents.KeyUp and key == Keys.VK_ESCAPE then 
		HideIfVisible();
	end
	return true; -- consume all input
end

-- ===========================================================================
function HideIfVisible()
	if ContextPtr:IsVisible() then
		OnClose();
	end
end


-- ===========================================================================
function Initialize()
	ContextPtr:SetInputHandler( OnInput, true );

	Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
	Controls.Next:RegisterCallback(Mouse.eLClick, OnNext);
	Controls.Previous:RegisterCallback(Mouse.eLClick, OnPrevious);

	Controls.Close:RegisterCallback(Mouse.eMouseEnter, function()
		UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.Next:RegisterCallback(Mouse.eMouseEnter, function()
		UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.Previous:RegisterCallback(Mouse.eMouseEnter, function()
		UI.PlaySound("Main_Menu_Mouse_Over"); end);

	local hideScreen =  Options.GetUserOption("Tutorial", OPTIONS_HIDE_KEY) == 1
	Controls.DontShowAgain:SetCheck(hideScreen);
	Controls.DontShowAgain:RegisterCheckHandler(function(bCheck)
		local value = bCheck and 1 or 0;
		Options.SetUserOption("Tutorial", OPTIONS_HIDE_KEY, value);
		Options.SaveOptions();
	end);

	Events.LoadGameViewStateDone.Add( OnLoadGameViewStateDone );

	LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add( OnShowFromMenu );
	LuaEvents.DiplomacyActionView_HideIngameUI.Add( HideIfVisible );
end
Initialize();